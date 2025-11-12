#!/usr/bin/env bash
# similarity-analyzer.sh
# Calculates similarity between modules/code

set -euo pipefail

# Similarity threshold (0.8 = 80%)
SIMILARITY_THRESHOLD=0.8

###############################################################################
# calculate_similarity
# Calculates similarity score between two modules
# Args:
#   $1 - Module 1 JSON object
#   $2 - Module 2 JSON object
# Returns: Similarity score (0.0-1.0)
###############################################################################
calculate_similarity() {
  local module1="$1"
  local module2="$2"

  # Extract module details
  local name1 name2 type1 type2 sig1 sig2
  name1=$(echo "$module1" | jq -r '.name')
  name2=$(echo "$module2" | jq -r '.name')
  type1=$(echo "$module1" | jq -r '.type')
  type2=$(echo "$module2" | jq -r '.type')
  sig1=$(echo "$module1" | jq -r '.signature')
  sig2=$(echo "$module2" | jq -r '.signature')

  # Weight distribution:
  # Name similarity: 30%
  # Type match: 20%
  # Signature similarity: 30%
  # Props/Params similarity: 20%

  local score=0

  # 1. Name similarity (30%)
  local name_score
  name_score=$(compare_names "$name1" "$name2")
  score=$(echo "scale=2; $score + ($name_score * 0.3)" | bc)

  # 2. Type match (20%)
  if [[ "$type1" == "$type2" ]]; then
    score=$(echo "scale=2; $score + 0.2" | bc)
  fi

  # 3. Signature similarity (30%)
  local sig_score
  sig_score=$(compare_strings "$sig1" "$sig2")
  score=$(echo "scale=2; $score + ($sig_score * 0.3)" | bc)

  # 4. Props/Params similarity (20%)
  # Simplified: check if both have props or both have params
  if [[ "$sig1" == *"interface"* ]] && [[ "$sig2" == *"interface"* ]]; then
    score=$(echo "scale=2; $score + 0.2" | bc)
  elif [[ "$sig1" == *"("* ]] && [[ "$sig2" == *"("* ]]; then
    score=$(echo "scale=2; $score + 0.2" | bc)
  fi

  echo "$score"
}

###############################################################################
# compare_names
# Compares two module names for similarity
# Args:
#   $1 - Name 1
#   $2 - Name 2
# Returns: Similarity score (0.0-1.0)
###############################################################################
compare_names() {
  local name1="$1"
  local name2="$2"

  # Convert to lowercase
  name1=$(echo "$name1" | tr '[:upper:]' '[:lower:]')
  name2=$(echo "$name2" | tr '[:upper:]' '[:lower:]')

  # Exact match
  if [[ "$name1" == "$name2" ]]; then
    echo "1.0"
    return 0
  fi

  # Substring match
  if [[ "$name1" == *"$name2"* ]] || [[ "$name2" == *"$name1"* ]]; then
    echo "0.8"
    return 0
  fi

  # Similar names (common prefix/suffix)
  local prefix_len
  prefix_len=$(compare_prefix "$name1" "$name2")
  local max_len
  max_len=${#name1}
  if [[ ${#name2} -gt $max_len ]]; then
    max_len=${#name2}
  fi

  if [[ $max_len -eq 0 ]]; then
    echo "0.0"
    return 0
  fi

  local similarity
  similarity=$(echo "scale=2; $prefix_len / $max_len" | bc)
  echo "$similarity"
}

###############################################################################
# compare_prefix
# Computes common prefix length
# Args:
#   $1 - String 1
#   $2 - String 2
# Returns: Common prefix length
###############################################################################
compare_prefix() {
  local str1="$1"
  local str2="$2"
  local len=0
  local max_len=${#str1}

  if [[ ${#str2} -lt $max_len ]]; then
    max_len=${#str2}
  fi

  for ((i=0; i<max_len; i++)); do
    if [[ "${str1:$i:1}" == "${str2:$i:1}" ]]; then
      ((len++))
    else
      break
    fi
  done

  echo "$len"
}

###############################################################################
# compare_strings
# Compares two strings for similarity (simplified Levenshtein)
# Args:
#   $1 - String 1
#   $2 - String 2
# Returns: Similarity score (0.0-1.0)
###############################################################################
compare_strings() {
  local str1="$1"
  local str2="$2"

  # Normalize whitespace
  str1=$(echo "$str1" | tr -s ' ' | tr '\n' ' ')
  str2=$(echo "$str2" | tr -s ' ' | tr '\n' ' ')

  # Exact match
  if [[ "$str1" == "$str2" ]]; then
    echo "1.0"
    return 0
  fi

  # Substring match
  if [[ "$str1" == *"$str2"* ]] || [[ "$str2" == *"$str1"* ]]; then
    echo "0.7"
    return 0
  fi

  # Word-level similarity (count common words)
  local words1 words2
  IFS=' ' read -ra words1 <<< "$str1"
  IFS=' ' read -ra words2 <<< "$str2"

  local common=0
  for word1 in "${words1[@]}"; do
    for word2 in "${words2[@]}"; do
      if [[ "$word1" == "$word2" ]]; then
        ((common++))
        break
      fi
    done
  done

  local total=${#words1[@]}
  if [[ ${#words2[@]} -gt $total ]]; then
    total=${#words2[@]}
  fi

  if [[ $total -eq 0 ]]; then
    echo "0.0"
    return 0
  fi

  local similarity
  similarity=$(echo "scale=2; $common / $total" | bc)
  echo "$similarity"
}

###############################################################################
# find_duplicates
# Finds duplicate modules based on similarity threshold
# Args:
#   $1 - Target module JSON object
#   $2 - All modules JSON array
#   $3 - Similarity threshold (optional, default 0.8)
# Returns: JSON array of duplicate modules with scores
###############################################################################
find_duplicates() {
  local target_module="$1"
  local all_modules="$2"
  local threshold="${3:-$SIMILARITY_THRESHOLD}"

  local target_path
  target_path=$(echo "$target_module" | jq -r '.path')

  local duplicates="[]"

  # Iterate through all modules
  local module_count
  module_count=$(echo "$all_modules" | jq 'length')

  for ((i=0; i<module_count; i++)); do
    local other_module
    other_module=$(echo "$all_modules" | jq ".[$i]")

    local other_path
    other_path=$(echo "$other_module" | jq -r '.path')

    # Skip if same file
    if [[ "$other_path" == "$target_path" ]]; then
      continue
    fi

    # Calculate similarity
    local score
    score=$(calculate_similarity "$target_module" "$other_module")

    # Check threshold
    local is_duplicate
    is_duplicate=$(echo "$score >= $threshold" | bc)

    if [[ "$is_duplicate" -eq 1 ]]; then
      # Add to duplicates with score
      local duplicate_obj
      duplicate_obj=$(echo "$other_module" | jq --argjson score "$score" '. + {similarityScore: $score}')
      duplicates=$(echo "$duplicates" | jq --argjson obj "$duplicate_obj" '. += [$obj]')
    fi
  done

  # Sort by similarity score (descending)
  echo "$duplicates" | jq 'sort_by(-.similarityScore)'
}

###############################################################################
# is_duplicate
# Checks if a module is a duplicate (similarity >= threshold)
# Args:
#   $1 - Similarity score
#   $2 - Threshold (optional, default 0.8)
# Returns: 0 if duplicate, 1 if not
###############################################################################
is_duplicate() {
  local score="$1"
  local threshold="${2:-$SIMILARITY_THRESHOLD}"

  local result
  result=$(echo "$score >= $threshold" | bc)

  if [[ "$result" -eq 1 ]]; then
    return 0  # Is duplicate
  else
    return 1  # Not duplicate
  fi
}

###############################################################################
# Main execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "${1:-help}" in
    compare)
      if [[ -z "${2:-}" ]] || [[ -z "${3:-}" ]]; then
        echo "Usage: $0 compare <module1-json> <module2-json>" >&2
        exit 1
      fi
      calculate_similarity "$2" "$3"
      ;;
    compare-names)
      if [[ -z "${2:-}" ]] || [[ -z "${3:-}" ]]; then
        echo "Usage: $0 compare-names <name1> <name2>" >&2
        exit 1
      fi
      compare_names "$2" "$3"
      ;;
    find-duplicates)
      if [[ -z "${2:-}" ]] || [[ -z "${3:-}" ]]; then
        echo "Usage: $0 find-duplicates <target-module-json> <all-modules-json> [threshold]" >&2
        exit 1
      fi
      find_duplicates "$2" "$3" "${4:-$SIMILARITY_THRESHOLD}"
      ;;
    help|*)
      cat <<EOF
Usage: $0 <command> [args]

Commands:
  compare <module1> <module2>                Calculate similarity
  compare-names <name1> <name2>              Compare names only
  find-duplicates <target> <all> [threshold] Find all duplicates
  help                                       Show this help

Examples:
  $0 compare-names Button MyButton
  $0 find-duplicates '\$module' '\$all_modules' 0.8

Similarity Threshold: $SIMILARITY_THRESHOLD (80%)
EOF
      ;;
  esac
fi
