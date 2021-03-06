#!/bin/bash

# Defaults...
TAR_ARGS="--ignore-failed-read -cf"

if [[ "$OSTYPE" == "darwin"* ]]; then
  TAR_ARGS="-cf"
fi

function restore() {
  CACHE_PREFIX="${BUILDKITE_PLUGIN_CACHE_TARBALL_PATH}/${BUILDKITE_ORGANIZATION_SLUG}/${BUILDKITE_PIPELINE_SLUG}"
  mkdir -p "${CACHE_PREFIX}/${BUILDKITE_PIPELINE_SLUG}"
  TAR_FILE="${CACHE_PREFIX}/${CACHE_KEY}.tar"

  if [ -f "$TAR_FILE" ]; then
    cache_hit "tar://${TAR_FILE}"
    tar -xf "${TAR_FILE}" -C .
  fi
}

function cache() {
  CACHE_PREFIX="${BUILDKITE_PLUGIN_CACHE_TARBALL_PATH}/${BUILDKITE_ORGANIZATION_SLUG}/${BUILDKITE_PIPELINE_SLUG}"

  mkdir -p "${CACHE_PREFIX}"
  DAYS="${BUILDKITE_PLUGIN_CACHE_TARBALL_MAX:-}"
  if [ -n "$DAYS" ] && [ "$DAYS" -gt 0 ]; then
    echo "🗑️ Deleting backups older than ${DAYS} day(s)..."
    # On Linux, concurrent deletes race and cause a non-zero exit code. -ignore_readdir_race fixes this.
    # macOS handles this flag but it has no effect since bsdfind already returns zero in this case.
    find "${CACHE_PREFIX}" -ignore_readdir_race -type f -mtime +"${DAYS}" -delete
  fi

  if [ "${#paths[@]}" -eq 1 ]; then
    mkdir -p "${CACHE_PREFIX}"
    TAR_FILE="${CACHE_PREFIX}/${CACHE_KEY}.tar"
    if [ ! -f "$TAR_FILE" ]; then
      tar $TAR_ARGS "${TAR_FILE}" "${paths[*]}"
    fi
  elif
    [ "${#paths[@]}" -gt 1 ]
  then
    mkdir -p "${CACHE_PREFIX}"
    TAR_FILE="${CACHE_PREFIX}/${CACHE_KEY}.tar"
    if [ ! -f "$TAR_FILE" ]; then
      TMP_FILE="$(mktemp)"
      tar $TAR_ARGS "${TMP_FILE}" "${paths[@]}"
      mv -f "${TMP_FILE}" "${TAR_FILE}"
    fi
  fi
}
