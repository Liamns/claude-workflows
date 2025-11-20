#!/bin/bash
# notion-parser.sh
# Notion template parsing functions
# Compatible with bash 3.2+
#
# Usage: source .claude/lib/notion-parser.sh
#
# Provides:
# - parse_notion_template: Parse entire Notion page template
# - extract_section: Extract specific section from template
# - extract_feature_metadata: Extract page properties metadata
# - validate_template_structure: Validate required sections

# Prevent multiple sourcing
if [[ -n "${CLAUDE_NOTION_PARSER_LOADED:-}" ]]; then
    return 0
fi
CLAUDE_NOTION_PARSER_LOADED=1

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/notion-utils.sh"
source "${SCRIPT_DIR}/notion-config.sh"

# Required template sections (emoji-based headers)
readonly REQUIRED_SECTIONS=(
    "🎯 기능 목적"
    "🔄 비즈니스 로직"
    "📋 체크리스트"
    "🔗 연관 기능"
)

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Template Parsing Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Parse entire Notion page template
# Arguments:
#   $1 - Page ID or URL
# Output:
#   JSON object with parsed template data
#   {
#     "metadata": {...},
#     "sections": {
#       "purpose": "...",
#       "logic": "...",
#       "checklist": "...",
#       "related": "..."
#     },
#     "raw_content": "..."
#   }
# Returns:
#   0 on success, 1 on failure
# Example:
#   parse_notion_template "page-id-123"
parse_notion_template() {
    local page_id="$1"

    if [[ -z "$page_id" ]]; then
        log_error "Page ID cannot be empty" >&2
        return 1
    fi

    log_info "Parsing Notion template: ${page_id}" >&2

    # Fetch page content
    local page_data
    if ! page_data=$(fetch_notion_page "$page_id"); then
        log_error "Failed to fetch Notion page: ${page_id}" >&2
        return 1
    fi

    # Extract metadata
    local metadata
    if ! metadata=$(extract_feature_metadata "$page_data"); then
        log_error "Failed to extract metadata" >&2
        return 1
    fi

    # Extract raw content (Notion-flavored Markdown)
    local raw_content
    raw_content=$(echo "$page_data" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    # Assuming content is in 'content' or 'markdown' field
    content = data.get('content', data.get('markdown', ''))
    print(content)
except Exception as e:
    print('', file=sys.stderr)
    sys.exit(0)
")

    # Extract sections
    local purpose logic checklist related
    purpose=$(extract_section "$raw_content" "🎯 기능 목적" 2>/dev/null || echo "")
    logic=$(extract_section "$raw_content" "🔄 비즈니스 로직" 2>/dev/null || echo "")
    checklist=$(extract_section "$raw_content" "📋 체크리스트" 2>/dev/null || echo "")
    related=$(extract_section "$raw_content" "🔗 연관 기능" 2>/dev/null || echo "")

    # Build JSON result
    local result
    result=$(python3 -c "
import json, sys

# Read sections from shell variables
sections = {
    'purpose': '''${purpose}''',
    'logic': '''${logic}''',
    'checklist': '''${checklist}''',
    'related': '''${related}'''
}

# Read metadata
try:
    metadata = json.loads('''${metadata}''')
except:
    metadata = {}

# Read raw content
raw_content = '''${raw_content}'''

result = {
    'metadata': metadata,
    'sections': sections,
    'raw_content': raw_content
}

print(json.dumps(result, ensure_ascii=False, indent=2))
")

    log_success "Template parsed successfully" >&2
    echo "$result"
    return 0
}

# Extract specific section from Notion template
# Arguments:
#   $1 - Raw content (Notion-flavored Markdown)
#   $2 - Section header (e.g., "🎯 기능 목적")
# Output:
#   Section content (without header)
# Returns:
#   0 on success, 1 if section not found
# Example:
#   extract_section "$content" "🎯 기능 목적"
extract_section() {
    local content="$1"
    local section_header="$2"

    if [[ -z "$content" ]]; then
        log_error "Content cannot be empty" >&2
        return 1
    fi

    if [[ -z "$section_header" ]]; then
        log_error "Section header cannot be empty" >&2
        return 1
    fi

    # Extract section using Python (handles multi-line content better)
    local section_content
    section_content=$(echo "$content" | python3 -c "
import sys
import re

content = sys.stdin.read()
header = '''${section_header}'''

# Escape special regex characters in header
escaped_header = re.escape(header)

# Pattern: Header followed by content until next header or end
# Matches: # Header, ## Header, ### Header
pattern = rf'^#+\s*{escaped_header}\s*$'

lines = content.split('\n')
section_lines = []
in_section = False
section_level = 0

for line in lines:
    # Check if this is a header line
    header_match = re.match(r'^(#+)\s*(.+?)\s*$', line)

    if header_match:
        level = len(header_match.group(1))
        title = header_match.group(2)

        # Check if this is our target section
        if title == header:
            in_section = True
            section_level = level
            continue

        # If we're in a section and hit another header of same or higher level, stop
        if in_section and level <= section_level:
            break

    # Collect section content
    if in_section:
        section_lines.append(line)

# Output section content
print('\n'.join(section_lines).strip())
")

    if [[ -z "$section_content" ]]; then
        log_error "Section not found: ${section_header}" >&2
        return 1
    fi

    echo "$section_content"
    return 0
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Metadata Extraction Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Extract feature metadata from page properties
# Arguments:
#   $1 - Page data JSON (from fetch_notion_page)
# Output:
#   JSON object with metadata
#   {
#     "title": "...",
#     "priority": "...",
#     "group": "...",
#     "status": "...",
#     "assignee": "...",
#     "start_date": "...",
#     "deadline": "..."
#   }
# Returns:
#   0 on success, 1 on failure
# Example:
#   extract_feature_metadata "$page_data"
extract_feature_metadata() {
    local page_data="$1"

    if [[ -z "$page_data" ]]; then
        log_error "Page data cannot be empty" >&2
        return 1
    fi

    # Get column names from config
    local title_col priority_col group_col status_col assignee_col start_date_col deadline_col
    title_col=$(get_column_name "title" 2>/dev/null || echo "기능 설명")
    priority_col=$(get_column_name "priority" 2>/dev/null || echo "우선순위")
    group_col=$(get_column_name "group" 2>/dev/null || echo "기능 그룹")
    status_col=$(get_column_name "status" 2>/dev/null || echo "진행현황")
    assignee_col=$(get_column_name "assignee" 2>/dev/null || echo "담당자")
    start_date_col=$(get_column_name "start_date" 2>/dev/null || echo "시작일")
    deadline_col=$(get_column_name "deadline" 2>/dev/null || echo "마감일")

    # Extract metadata using Python
    local metadata
    metadata=$(echo "$page_data" | python3 -c "
import json, sys

try:
    data = json.load(sys.stdin)
    props = data.get('properties', {})

    # Extract title
    title_obj = props.get('${title_col}', {})
    if title_obj.get('type') == 'title':
        title = ''.join([t.get('plain_text', '') for t in title_obj.get('title', [])])
    else:
        title = ''

    # Extract priority
    priority = props.get('${priority_col}', {}).get('select', {}).get('name', '')

    # Extract group
    group = props.get('${group_col}', {}).get('select', {}).get('name', '')

    # Extract status
    status = props.get('${status_col}', {}).get('status', {}).get('name', '')

    # Extract assignee
    assignee_obj = props.get('${assignee_col}', {}).get('people', [])
    assignee = assignee_obj[0].get('name', '') if assignee_obj else ''

    # Extract dates
    start_date_obj = props.get('${start_date_col}', {}).get('date', {})
    start_date = start_date_obj.get('start', '') if start_date_obj else ''

    deadline_obj = props.get('${deadline_col}', {}).get('date', {})
    deadline = deadline_obj.get('start', '') if deadline_obj else ''

    # Build metadata
    metadata = {
        'title': title,
        'priority': priority,
        'group': group,
        'status': status,
        'assignee': assignee,
        'start_date': start_date,
        'deadline': deadline
    }

    print(json.dumps(metadata, ensure_ascii=False))
except Exception as e:
    print(json.dumps({}), file=sys.stderr)
    sys.exit(1)
")

    if [[ -z "$metadata" ]]; then
        log_error "Failed to extract metadata" >&2
        return 1
    fi

    echo "$metadata"
    return 0
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Validation Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Validate template structure
# Arguments:
#   $1 - Raw content (Notion-flavored Markdown)
# Output:
#   Validation result JSON
#   {
#     "valid": true/false,
#     "missing_sections": ["section1", "section2"],
#     "found_sections": ["section1", "section2"]
#   }
# Returns:
#   0 if valid, 1 if invalid
# Example:
#   validate_template_structure "$content"
validate_template_structure() {
    local content="$1"

    if [[ -z "$content" ]]; then
        log_error "Content cannot be empty" >&2
        return 1
    fi

    log_info "Validating template structure" >&2

    # Check for required sections
    local missing_sections=()
    local found_sections=()

    for section in "${REQUIRED_SECTIONS[@]}"; do
        if echo "$content" | grep -q "^#.*${section}"; then
            found_sections+=("$section")
        else
            missing_sections+=("$section")
        fi
    done

    # Build validation result
    local is_valid="true"
    if [[ ${#missing_sections[@]} -gt 0 ]]; then
        is_valid="false"
    fi

    # Convert arrays to JSON
    local missing_json found_json
    missing_json=$(printf '%s\n' "${missing_sections[@]}" | python3 -c "
import json, sys
lines = [line.strip() for line in sys.stdin if line.strip()]
print(json.dumps(lines, ensure_ascii=False))
" 2>/dev/null || echo "[]")

    found_json=$(printf '%s\n' "${found_sections[@]}" | python3 -c "
import json, sys
lines = [line.strip() for line in sys.stdin if line.strip()]
print(json.dumps(lines, ensure_ascii=False))
" 2>/dev/null || echo "[]")

    # Build result JSON
    local result
    result=$(python3 -c "
import json
result = {
    'valid': ${is_valid},
    'missing_sections': ${missing_json},
    'found_sections': ${found_json}
}
print(json.dumps(result, ensure_ascii=False, indent=2))
")

    if [[ "$is_valid" == "false" ]]; then
        log_error "Template validation failed. Missing sections: ${missing_sections[*]}" >&2
        echo "$result"
        return 1
    fi

    log_success "Template validation passed" >&2
    echo "$result"
    return 0
}

# Export functions
export -f parse_notion_template
export -f extract_section
export -f extract_feature_metadata
export -f validate_template_structure
