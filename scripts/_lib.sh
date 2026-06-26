#!/usr/bin/env bash
# Shared helpers, sourced by the other scripts.  Not executed directly.

# Load .env into the environment (KEY=VALUE; ignores comments/blanks).
load_env() {
  local file="${1:-.env}"
  [ -f "$file" ] || { echo "ERROR: $file not found (cp .env.example .env)"; return 1; }
  set -a
  # shellcheck disable=SC1090
  . "$file"
  set +a
}

# Fail if any named variable is empty. Usage: require_env DOMAIN CF_API_TOKEN ...
require_env() {
  load_env .env || return 1
  local missing=0 var
  for var in "$@"; do
    if [ -z "${!var}" ]; then echo "ERROR: $var is empty in .env"; missing=1; fi
  done
  return $missing
}

# Normalize a flag to literal "true"/"false" for YAML.
yaml_bool() {
  case "$(echo "${1:-}" | tr '[:upper:]' '[:lower:]')" in
    true|1|yes|on) echo "true" ;;
    *)             echo "false" ;;
  esac
}
