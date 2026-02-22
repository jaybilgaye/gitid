#!/usr/bin/env bash
# lib/validate.sh — input validation functions

validate_nonempty() {
  local value="$1" field="$2"
  if [[ -z "$value" ]]; then
    ui_error "$field cannot be empty"
    return 1
  fi
}

validate_email() {
  local email="$1"
  if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    ui_error "Invalid email format: $email"
    return 1
  fi
}

validate_alias() {
  local alias="$1"
  if [[ ! "$alias" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    ui_error "Alias must only contain letters, numbers, hyphens, and underscores"
    return 1
  fi
}

validate_ssh_key() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    ui_error "SSH key not found: $path"
    return 1
  fi
}
