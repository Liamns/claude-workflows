#!/bin/bash

# Claude Workflows - Smart Cache Layer
# Version: 1.0.0
# Bash-based caching system for token optimization

# ════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ════════════════════════════════════════════════════════════════════════════

# Cache root directory
CACHE_ROOT="${CLAUDE_CACHE_ROOT:-.claude/cache}"
CACHE_FILES="$CACHE_ROOT/files"
CACHE_TESTS="$CACHE_ROOT/tests"
CACHE_GIT="$CACHE_ROOT/git"
CACHE_ANALYSIS="$CACHE_ROOT/analysis"
CACHE_META="$CACHE_ROOT/metadata"

# Default TTL values (seconds)
DEFAULT_FILE_TTL=300      # 5 minutes
DEFAULT_TEST_TTL=600      # 10 minutes
DEFAULT_GIT_TTL=60        # 1 minute
DEFAULT_ANALYSIS_TTL=1800 # 30 minutes

# Stats tracking
STATS_FILE="$CACHE_META/stats.json"

# ════════════════════════════════════════════════════════════════════════════
# UTILITY FUNCTIONS
# ════════════════════════════════════════════════════════════════════════════

# Initialize cache directories
cache_init() {
    mkdir -p "$CACHE_FILES" "$CACHE_TESTS" "$CACHE_GIT" "$CACHE_ANALYSIS" "$CACHE_META"

    # Initialize stats file if not exists
    if [[ ! -f "$STATS_FILE" ]]; then
        cat > "$STATS_FILE" <<EOF
{
  "total_requests": 0,
  "cache_hits": 0,
  "cache_misses": 0,
  "tokens_saved_estimate": 0,
  "last_cleanup": $(date +%s)
}
EOF
    fi
}

# Generate MD5 hash for cache key
cache_hash() {
    local input="$1"
    echo -n "$input" | md5sum 2>/dev/null | awk '{print $1}' || echo -n "$input" | md5 | awk '{print $1}'
}

# Update statistics
cache_stat_increment() {
    local field="$1"
    local value="${2:-1}"

    if [[ ! -f "$STATS_FILE" ]]; then
        cache_init
    fi

    # Read current value
    local current=$(jq -r ".${field}" "$STATS_FILE" 2>/dev/null || echo "0")
    local new_value=$((current + value))

    # Update stats file
    local tmp_file=$(mktemp)
    jq ".${field} = ${new_value}" "$STATS_FILE" > "$tmp_file" && mv "$tmp_file" "$STATS_FILE"
}

# ════════════════════════════════════════════════════════════════════════════
# METADATA FUNCTIONS
# ════════════════════════════════════════════════════════════════════════════

# Create cache metadata
cache_metadata_create() {
    local cache_key="$1"
    local ttl="$2"
    local file_path="$3"

    local now=$(date +%s)
    local expire_at=$((now + ttl))

    # Get file modification time (cross-platform)
    local file_mtime=0
    if [[ -f "$file_path" ]]; then
        file_mtime=$(stat -f %m "$file_path" 2>/dev/null || stat -c %Y "$file_path" 2>/dev/null || echo "0")
    fi

    cat > "$CACHE_META/${cache_key}.json" <<EOF
{
  "key": "$cache_key",
  "created_at": $now,
  "expire_at": $expire_at,
  "ttl": $ttl,
  "file_path": "$file_path",
  "file_mtime": $file_mtime
}
EOF
}

# Check if cache is valid
cache_is_valid() {
    local cache_key="$1"
    local meta_file="$CACHE_META/${cache_key}.json"

    # Metadata file must exist
    [[ ! -f "$meta_file" ]] && return 1

    # Check TTL expiration
    local now=$(date +%s)
    local expire_at=$(jq -r '.expire_at' "$meta_file" 2>/dev/null || echo "0")
    [[ $now -gt $expire_at ]] && return 1

    # Check file modification time
    local cached_mtime=$(jq -r '.file_mtime' "$meta_file" 2>/dev/null || echo "0")
    local file_path=$(jq -r '.file_path' "$meta_file" 2>/dev/null)

    if [[ -f "$file_path" ]]; then
        local current_mtime=$(stat -f %m "$file_path" 2>/dev/null || stat -c %Y "$file_path" 2>/dev/null || echo "0")
        [[ "$cached_mtime" != "$current_mtime" ]] && return 1
    fi

    return 0
}

# ════════════════════════════════════════════════════════════════════════════
# FILE CACHE FUNCTIONS
# ════════════════════════════════════════════════════════════════════════════

# Save file to cache
cache_file_save() {
    local file_path="$1"
    local ttl="${2:-$DEFAULT_FILE_TTL}"

    # Validate file exists
    [[ ! -f "$file_path" ]] && return 1

    # Generate cache key
    local cache_key=$(cache_hash "$file_path")
    local cache_file="$CACHE_FILES/${cache_key}.cache"

    # Copy file to cache
    cp "$file_path" "$cache_file" 2>/dev/null || return 1

    # Create metadata
    cache_metadata_create "$cache_key" "$ttl" "$file_path"

    return 0
}

# Get file from cache
cache_file_get() {
    local file_path="$1"
    local cache_key=$(cache_hash "$file_path")
    local cache_file="$CACHE_FILES/${cache_key}.cache"

    # Update total requests
    cache_stat_increment "total_requests"

    # Check if cache is valid
    if cache_is_valid "$cache_key" && [[ -f "$cache_file" ]]; then
        # Cache HIT
        echo "✨ Cache HIT: $file_path" >&2
        cache_stat_increment "cache_hits"
        cache_stat_increment "tokens_saved_estimate" 500  # Estimate 500 tokens per cache hit
        cat "$cache_file"
        return 0
    else
        # Cache MISS
        echo "🔄 Cache MISS: $file_path" >&2
        cache_stat_increment "cache_misses"
        return 1
    fi
}

# ════════════════════════════════════════════════════════════════════════════
# TEST CACHE FUNCTIONS
# ════════════════════════════════════════════════════════════════════════════

# Save test result to cache
cache_test_save() {
    local test_spec="$1"
    local exit_code="$2"
    local output="$3"
    local ttl="${4:-$DEFAULT_TEST_TTL}"

    local cache_key=$(cache_hash "$test_spec")
    local cache_file="$CACHE_TESTS/${cache_key}.json"

    local now=$(date +%s)
    local expire_at=$((now + ttl))

    cat > "$cache_file" <<EOF
{
  "test_spec": "$test_spec",
  "exit_code": $exit_code,
  "output": $(echo "$output" | jq -Rs .),
  "cached_at": $now,
  "expire_at": $expire_at,
  "ttl": $ttl
}
EOF

    return 0
}

# Get test result from cache
cache_test_get() {
    local test_spec="$1"
    local cache_key=$(cache_hash "$test_spec")
    local cache_file="$CACHE_TESTS/${cache_key}.json"

    [[ ! -f "$cache_file" ]] && return 1

    # Check TTL
    local now=$(date +%s)
    local expire_at=$(jq -r '.expire_at' "$cache_file" 2>/dev/null || echo "0")
    [[ $now -gt $expire_at ]] && return 1

    # Cache HIT
    echo "✨ Test Cache HIT: $test_spec" >&2
    cache_stat_increment "cache_hits"
    cache_stat_increment "tokens_saved_estimate" 1000  # Tests save more tokens

    # Return cached result
    cat "$cache_file"
    return 0
}

# ════════════════════════════════════════════════════════════════════════════
# GIT CACHE FUNCTIONS
# ════════════════════════════════════════════════════════════════════════════

# Save git command output
cache_git_save() {
    local git_cmd="$1"
    local output="$2"
    local ttl="${3:-$DEFAULT_GIT_TTL}"

    local cache_key=$(cache_hash "$git_cmd")
    local cache_file="$CACHE_GIT/${cache_key}.txt"

    echo "$output" > "$cache_file"
    cache_metadata_create "$cache_key" "$ttl" "/dev/null"  # No file dependency

    return 0
}

# Get git command output
cache_git_get() {
    local git_cmd="$1"
    local cache_key=$(cache_hash "$git_cmd")
    local cache_file="$CACHE_GIT/${cache_key}.txt"

    if cache_is_valid "$cache_key" && [[ -f "$cache_file" ]]; then
        echo "✨ Git Cache HIT: $git_cmd" >&2
        cache_stat_increment "cache_hits"
        cat "$cache_file"
        return 0
    else
        return 1
    fi
}

# ════════════════════════════════════════════════════════════════════════════
# ANALYSIS CACHE FUNCTIONS
# ════════════════════════════════════════════════════════════════════════════

# Save analysis result
cache_analysis_save() {
    local analysis_key="$1"
    local result="$2"
    local ttl="${3:-$DEFAULT_ANALYSIS_TTL}"

    local cache_key=$(cache_hash "$analysis_key")
    local cache_file="$CACHE_ANALYSIS/${cache_key}.json"

    echo "$result" > "$cache_file"
    cache_metadata_create "$cache_key" "$ttl" "/dev/null"

    return 0
}

# Get analysis result
cache_analysis_get() {
    local analysis_key="$1"
    local cache_key=$(cache_hash "$analysis_key")
    local cache_file="$CACHE_ANALYSIS/${cache_key}.json"

    if cache_is_valid "$cache_key" && [[ -f "$cache_file" ]]; then
        echo "✨ Analysis Cache HIT: $analysis_key" >&2
        cache_stat_increment "cache_hits"
        cache_stat_increment "tokens_saved_estimate" 2000  # Analysis saves a lot
        cat "$cache_file"
        return 0
    else
        return 1
    fi
}

# ════════════════════════════════════════════════════════════════════════════
# CLEANUP & INVALIDATION
# ════════════════════════════════════════════════════════════════════════════

# Clean expired cache entries
cache_cleanup() {
    local now=$(date +%s)
    local cleaned=0

    echo "🧹 Cleaning expired cache entries..."

    for meta_file in "$CACHE_META"/*.json; do
        [[ ! -f "$meta_file" ]] && continue

        local expire_at=$(jq -r '.expire_at' "$meta_file" 2>/dev/null || echo "0")
        if [[ $now -gt $expire_at ]]; then
            local cache_key=$(basename "$meta_file" .json)

            # Remove metadata and cached files
            rm -f "$meta_file"
            rm -f "$CACHE_FILES/${cache_key}.cache"
            rm -f "$CACHE_TESTS/${cache_key}.json"
            rm -f "$CACHE_GIT/${cache_key}.txt"
            rm -f "$CACHE_ANALYSIS/${cache_key}.json"

            ((cleaned++))
        fi
    done

    # Update last cleanup time
    local tmp_file=$(mktemp)
    jq ".last_cleanup = $now" "$STATS_FILE" > "$tmp_file" && mv "$tmp_file" "$STATS_FILE"

    echo "✅ Cleaned $cleaned expired cache entries"
}

# Invalidate all caches
cache_invalidate_all() {
    echo "🗑️  Invalidating all caches..."
    rm -rf "$CACHE_FILES"/* "$CACHE_TESTS"/* "$CACHE_GIT"/* "$CACHE_ANALYSIS"/* "$CACHE_META"/*
    echo "✅ All caches invalidated"
}

# Invalidate on git commit
cache_invalidate_on_commit() {
    echo "🔄 Git commit detected. Invalidating git & test caches..."
    rm -rf "$CACHE_GIT"/* "$CACHE_TESTS"/*
    echo "✅ Git & test caches invalidated"
}

# Invalidate by pattern
cache_invalidate_pattern() {
    local pattern="$1"
    local count=0

    echo "🔄 Invalidating caches matching: $pattern"

    for meta_file in "$CACHE_META"/*.json; do
        [[ ! -f "$meta_file" ]] && continue

        local file_path=$(jq -r '.file_path' "$meta_file" 2>/dev/null)
        if [[ "$file_path" =~ $pattern ]]; then
            local cache_key=$(basename "$meta_file" .json)

            rm -f "$meta_file"
            rm -f "$CACHE_FILES/${cache_key}.cache"
            rm -f "$CACHE_TESTS/${cache_key}.json"
            rm -f "$CACHE_ANALYSIS/${cache_key}.json"

            ((count++))
        fi
    done

    echo "✅ Invalidated $count cache entries"
}

# ════════════════════════════════════════════════════════════════════════════
# STATISTICS & MONITORING
# ════════════════════════════════════════════════════════════════════════════

# Display cache statistics
cache_stats() {
    if [[ ! -f "$STATS_FILE" ]]; then
        cache_init
    fi

    local total_requests=$(jq -r '.total_requests' "$STATS_FILE")
    local cache_hits=$(jq -r '.cache_hits' "$STATS_FILE")
    local cache_misses=$(jq -r '.cache_misses' "$STATS_FILE")
    local tokens_saved=$(jq -r '.tokens_saved_estimate' "$STATS_FILE")

    local hit_rate=0
    if [[ $total_requests -gt 0 ]]; then
        hit_rate=$((cache_hits * 100 / total_requests))
    fi

    # Count cached items
    local cached_files=$(find "$CACHE_FILES" -name "*.cache" 2>/dev/null | wc -l | xargs)
    local cached_tests=$(find "$CACHE_TESTS" -name "*.json" 2>/dev/null | wc -l | xargs)
    local cache_size=$(du -sh "$CACHE_ROOT" 2>/dev/null | awk '{print $1}')

    # Time saved estimate (2 seconds per cache hit)
    local time_saved=$((cache_hits * 2))

    cat <<EOF
╔════════════════════════════════════════════╗
║        Smart Cache Performance             ║
╠════════════════════════════════════════════╣
║ 📊 Cache Statistics                        ║
║   Total Requests: $total_requests
║   Cache Hits: $cache_hits
║   Cache Misses: $cache_misses
║   Hit Rate: ${hit_rate}%
║                                            ║
║ ⚡ Performance Impact                      ║
║   Tokens Saved: ~$tokens_saved
║   Time Saved: ~${time_saved}s
║                                            ║
║ 💾 Storage                                 ║
║   Cache Size: $cache_size
║   Files Cached: $cached_files
║   Tests Cached: $cached_tests
║                                            ║
║ 🎯 Quality Target                          ║
║   Hit Rate Goal: 60%+ $(if [[ $hit_rate -ge 60 ]]; then echo "✅"; else echo "⏳"; fi)
║   Token Savings: 70%+ target              ║
╚════════════════════════════════════════════╝
EOF
}

# Display top cached files
cache_top_files() {
    local count="${1:-5}"

    echo "🔝 Top $count Cached Files:"
    for meta_file in "$CACHE_META"/*.json; do
        [[ ! -f "$meta_file" ]] && continue
        local file_path=$(jq -r '.file_path' "$meta_file" 2>/dev/null)
        echo "   - $file_path"
    done | head -n "$count"
}

# ════════════════════════════════════════════════════════════════════════════
# INITIALIZATION
# ════════════════════════════════════════════════════════════════════════════

# Auto-initialize if jq is available
if command -v jq &> /dev/null; then
    cache_init &> /dev/null
else
    echo "⚠️  Warning: jq not found. Cache system requires jq for JSON processing." >&2
    echo "   Install: brew install jq (macOS) or apt-get install jq (Linux)" >&2
fi

# ════════════════════════════════════════════════════════════════════════════
# END OF FILE
# ════════════════════════════════════════════════════════════════════════════
