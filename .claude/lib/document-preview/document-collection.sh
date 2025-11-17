#!/bin/bash
# document-collection.sh
# 복수 문서 관리 및 컬렉션 처리
#
# 사용법:
#   source document-collection.sh
#   collection=$(create_document_collection)
#   add_document_to_collection "$collection" "/path/to/spec.md"

# Note: set -e 제거 (source될 때 테스트 스크립트에 영향을 주지 않도록)

# 에러 코드 정의
if [ -z "${ERR_COLLECTION_FAILED:-}" ]; then
  readonly ERR_COLLECTION_FAILED=30
  readonly ERR_COLLECTION_INVALID=31
  readonly ERR_DOCUMENT_NOT_FOUND=32
  readonly ERR_DUPLICATE_DOCUMENT=33
fi

# 컬렉션 저장 디렉토리
COLLECTION_BASE_DIR="${COLLECTION_BASE_DIR:-/tmp/document-collections}"

# 로깅 함수
log_collection_error() {
  local error_type="$1"
  local message="$2"
  echo "[COLLECTION ERROR] $error_type: $message" >&2
}

log_collection_info() {
  local message="$1"
  echo "[COLLECTION INFO] $message" >&2
}

# 컬렉션 디렉토리 초기화
init_collection_base() {
  if [ ! -d "$COLLECTION_BASE_DIR" ]; then
    mkdir -p "$COLLECTION_BASE_DIR" 2>/dev/null
    if [ $? -ne 0 ]; then
      log_collection_error "INIT_FAILED" "Failed to create collection base directory: $COLLECTION_BASE_DIR"
      return $ERR_COLLECTION_FAILED
    fi
  fi
  return 0
}

# 빈 컬렉션 생성
create_document_collection() {
  init_collection_base || return $?

  # 고유 컬렉션 ID 생성 (타임스탬프 + 랜덤)
  local collection_id="collection_$(date +%s)_$$"
  local collection_dir="$COLLECTION_BASE_DIR/$collection_id"

  # 컬렉션 디렉토리 생성
  mkdir -p "$collection_dir" 2>/dev/null
  if [ $? -ne 0 ]; then
    log_collection_error "CREATE_FAILED" "Failed to create collection directory: $collection_dir"
    return $ERR_COLLECTION_FAILED
  fi

  # 문서 리스트 파일 초기화
  touch "$collection_dir/documents.list"
  touch "$collection_dir/metadata.txt"

  log_collection_info "Created collection: $collection_id"
  echo "$collection_id"
  return 0
}

# 컬렉션 검증
validate_collection() {
  local collection_id="$1"

  if [ -z "$collection_id" ]; then
    log_collection_error "INVALID_COLLECTION" "Collection ID is required"
    return $ERR_COLLECTION_INVALID
  fi

  local collection_dir="$COLLECTION_BASE_DIR/$collection_id"

  if [ ! -d "$collection_dir" ]; then
    log_collection_error "COLLECTION_NOT_FOUND" "Collection not found: $collection_id"
    return $ERR_COLLECTION_INVALID
  fi

  return 0
}

# 컬렉션에 문서 추가
add_document_to_collection() {
  local collection_id="$1"
  local document_path="$2"

  # 입력 검증
  validate_collection "$collection_id" || return $?

  if [ -z "$document_path" ]; then
    log_collection_error "INVALID_PATH" "Document path is required"
    return $ERR_COLLECTION_INVALID
  fi

  # 절대 경로로 변환
  document_path=$(realpath "$document_path" 2>/dev/null)
  if [ $? -ne 0 ]; then
    log_collection_error "PATH_RESOLUTION_FAILED" "Failed to resolve path: $2"
    return $ERR_COLLECTION_INVALID
  fi

  local collection_dir="$COLLECTION_BASE_DIR/$collection_id"
  local documents_file="$collection_dir/documents.list"

  # 중복 체크
  if grep -Fxq "$document_path" "$documents_file" 2>/dev/null; then
    log_collection_info "Document already in collection: $document_path"
    return 0  # 중복은 에러가 아니라 성공으로 처리
  fi

  # 문서를 리스트에 추가
  echo "$document_path" >> "$documents_file"

  log_collection_info "Added document to collection: $document_path"
  return 0
}

# 컬렉션에서 문서 제거
remove_document_from_collection() {
  local collection_id="$1"
  local document_path="$2"

  # 입력 검증
  validate_collection "$collection_id" || return $?

  if [ -z "$document_path" ]; then
    log_collection_error "INVALID_PATH" "Document path is required"
    return $ERR_COLLECTION_INVALID
  fi

  # 절대 경로로 변환
  document_path=$(realpath "$document_path" 2>/dev/null)
  if [ $? -ne 0 ]; then
    # 경로 해석 실패해도 원본 경로로 시도
    document_path="$2"
  fi

  local collection_dir="$COLLECTION_BASE_DIR/$collection_id"
  local documents_file="$collection_dir/documents.list"

  # 문서 제거 (grep -v로 해당 라인만 제외)
  local temp_file="$collection_dir/documents.list.tmp"
  grep -Fxv "$document_path" "$documents_file" > "$temp_file" 2>/dev/null
  mv "$temp_file" "$documents_file"

  log_collection_info "Removed document from collection: $document_path"
  return 0
}

# 컬렉션 문서 개수 반환
get_document_count() {
  local collection_id="$1"

  # 입력 검증
  validate_collection "$collection_id" || return $?

  local collection_dir="$COLLECTION_BASE_DIR/$collection_id"
  local documents_file="$collection_dir/documents.list"

  # 빈 줄 제외하고 카운트
  local count=$(grep -c . "$documents_file" 2>/dev/null || echo "0")

  echo "$count"
  return 0
}

# 컬렉션 문서 리스트 반환
get_document_list() {
  local collection_id="$1"

  # 입력 검증
  validate_collection "$collection_id" || return $?

  local collection_dir="$COLLECTION_BASE_DIR/$collection_id"
  local documents_file="$collection_dir/documents.list"

  # 문서 리스트 출력
  cat "$documents_file" 2>/dev/null

  return 0
}

# 컬렉션의 모든 문서 존재 여부 검증
validate_collection_documents() {
  local collection_id="$1"

  # 입력 검증
  validate_collection "$collection_id" || return $?

  local collection_dir="$COLLECTION_BASE_DIR/$collection_id"
  local documents_file="$collection_dir/documents.list"

  local all_valid=true
  local missing_count=0

  # 각 문서 존재 여부 확인
  while IFS= read -r document_path; do
    # 빈 줄 건너뛰기
    [ -z "$document_path" ] && continue

    if [ ! -f "$document_path" ]; then
      log_collection_error "DOCUMENT_NOT_FOUND" "Missing document: $document_path"
      all_valid=false
      ((missing_count++))
    fi
  done < "$documents_file"

  if [ "$all_valid" = false ]; then
    log_collection_error "VALIDATION_FAILED" "Collection has $missing_count missing documents"
    return $ERR_DOCUMENT_NOT_FOUND
  fi

  log_collection_info "All documents validated successfully"
  return 0
}

# 컬렉션 비우기
clear_document_collection() {
  local collection_id="$1"

  # 입력 검증
  validate_collection "$collection_id" || return $?

  local collection_dir="$COLLECTION_BASE_DIR/$collection_id"
  local documents_file="$collection_dir/documents.list"

  # 문서 리스트 파일 비우기
  > "$documents_file"

  log_collection_info "Cleared collection: $collection_id"
  return 0
}

# 컬렉션 메타데이터 설정
set_collection_metadata() {
  local collection_id="$1"
  local key="$2"
  local value="$3"

  # 입력 검증
  validate_collection "$collection_id" || return $?

  if [ -z "$key" ]; then
    log_collection_error "INVALID_METADATA" "Metadata key is required"
    return $ERR_COLLECTION_INVALID
  fi

  local collection_dir="$COLLECTION_BASE_DIR/$collection_id"
  local metadata_file="$collection_dir/metadata.txt"

  # 기존 키 제거 후 새 값 추가
  local temp_file="$collection_dir/metadata.txt.tmp"
  grep -v "^$key=" "$metadata_file" 2>/dev/null > "$temp_file"
  echo "$key=$value" >> "$temp_file"
  mv "$temp_file" "$metadata_file"

  log_collection_info "Set metadata: $key=$value"
  return 0
}

# 컬렉션 메타데이터 조회
get_collection_metadata() {
  local collection_id="$1"
  local key="$2"

  # 입력 검증
  validate_collection "$collection_id" || return $?

  if [ -z "$key" ]; then
    log_collection_error "INVALID_METADATA" "Metadata key is required"
    return $ERR_COLLECTION_INVALID
  fi

  local collection_dir="$COLLECTION_BASE_DIR/$collection_id"
  local metadata_file="$collection_dir/metadata.txt"

  # 키에 해당하는 값 추출
  local value=$(grep "^$key=" "$metadata_file" 2>/dev/null | cut -d= -f2-)

  echo "$value"
  return 0
}

# 컬렉션 삭제
delete_document_collection() {
  local collection_id="$1"

  # 입력 검증
  validate_collection "$collection_id" || return $?

  local collection_dir="$COLLECTION_BASE_DIR/$collection_id"

  # 컬렉션 디렉토리 삭제
  rm -rf "$collection_dir"

  log_collection_info "Deleted collection: $collection_id"
  return 0
}

# 문서 경로 정규화 (상대 경로 -> 절대 경로)
normalize_document_path() {
  local document_path="$1"

  if [ -z "$document_path" ]; then
    return 1
  fi

  # realpath가 있으면 사용
  if command -v realpath >/dev/null 2>&1; then
    realpath "$document_path" 2>/dev/null
    return $?
  fi

  # realpath가 없으면 readlink 시도
  if command -v readlink >/dev/null 2>&1; then
    readlink -f "$document_path" 2>/dev/null
    return $?
  fi

  # 둘 다 없으면 원본 경로 반환
  echo "$document_path"
  return 0
}

# 스크립트가 직접 실행된 경우 (테스트용)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Document Collection Manager"
  echo "---"

  # 간단한 사용 예제
  collection=$(create_document_collection)
  echo "Created collection: $collection"

  if [ $# -gt 0 ]; then
    for doc in "$@"; do
      echo "Adding document: $doc"
      add_document_to_collection "$collection" "$doc"
    done

    echo "---"
    echo "Document count: $(get_document_count "$collection")"
    echo "Document list:"
    get_document_list "$collection"

    echo "---"
    echo "Validating documents..."
    validate_collection_documents "$collection"
    echo "Validation complete (exit code: $?)"
  fi
fi
