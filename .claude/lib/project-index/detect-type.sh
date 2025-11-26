#!/usr/bin/env bash
# File type detection logic
# Epic 006 - Feature 004: Project Indexing and Caching
# Task: T006 - Detect file type based on path and extension

# Detect file type from path
# Arguments: $1 = file path (relative to project root)
# Returns: file type string
detect_file_type() {
    local file_path="$1"
    local basename=$(basename "$file_path")
    local dirname=$(dirname "$file_path")

    # Test files
    if [[ "$file_path" == *"__tests__"* ]] || [[ "$file_path" == *".test."* ]] || [[ "$file_path" == *".spec."* ]]; then
        echo "test"
        return
    fi

    # Script files
    if [[ "$basename" == *.sh ]]; then
        echo "script"
        return
    fi

    # Documentation
    if [[ "$basename" == *.md ]]; then
        if [[ "$basename" == "README.md" ]]; then
            echo "readme"
        else
            echo "doc"
        fi
        return
    fi

    # TypeScript/JavaScript by path patterns
    case "$dirname" in
        */ui|*/components)
            echo "component"
            ;;
        */api|*/services)
            echo "service"
            ;;
        */lib|*/utils)
            echo "util"
            ;;
        */hooks)
            echo "hook"
            ;;
        */model|*/models|*/types)
            echo "model"
            ;;
        */config)
            echo "config"
            ;;
        */entities/*)
            echo "entity"
            ;;
        */features/*)
            echo "feature"
            ;;
        */widgets/*)
            echo "widget"
            ;;
        */pages/*)
            echo "page"
            ;;
        *)
            # Fallback to extension
            if [[ "$basename" == *.tsx ]] || [[ "$basename" == *.jsx ]]; then
                echo "component"
            elif [[ "$basename" == *.ts ]] || [[ "$basename" == *.js ]]; then
                echo "module"
            else
                echo "unknown"
            fi
            ;;
    esac
}

# Export function
export -f detect_file_type
