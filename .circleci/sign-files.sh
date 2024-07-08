#!/usr/bin/env bash
# This script is used to sign the release files with the GPG key
set -euo pipefail

readonly BIN="${BIN:-bin}"
readonly RELEASE="${RELEASE:-release}"
readonly NAME="${NAME:-opentofu}"
# Extract version from RC
readonly VERSION=${TAG%-rc*}
readonly TYPE="rpc"

function get_key_id() {
  gpg --list-keys --with-colons | awk -F: '/^pub/{print $5}'
}

function prepare_release_directory() {
  mkdir -p "${RELEASE}"
}

function process_files() {
  cd "${BIN}"
  for file in *; do
    # Extract the OS and ARCH from the file name
    if [[ $file =~ terragrunt-iac-engine-${NAME}_([^_]+)_([^_]+) ]]; then
      OS="${BASH_REMATCH[1]}"
      ARCH="${BASH_REMATCH[2]}"

      # Set the binary and archive names
      BINARY_NAME="terragrunt-iac-engine-${NAME}_${VERSION}"
      mv "${file}" "${BINARY_NAME}"
      ARCHIVE_NAME="terragrunt-iac-engine-${NAME}_${TYPE}_${VERSION}_${OS}_${ARCH}.zip"

      # Create the zip archive
      zip "../${RELEASE}/${ARCHIVE_NAME}" "${BINARY_NAME}"
    fi
  done
  cd ..
}

# Function to create the SHA256SUMS file
function create_shasums_file() {
  cd "${RELEASE}"
  shasum -a 256 *.zip > "terragrunt-iac-engine-${NAME}_${TYPE}_${VERSION}_SHA256SUMS"
}

# Function to sign the SHA256SUMS file
function sign_shasums_file() {
  local -r key_id=$1
  echo "${GW_ENGINE_GPG_KEY_PW}" | gpg --batch --yes --pinentry-mode loopback --passphrase-fd 0 --default-key "${key_id}" --detach-sign "terragrunt-iac-engine-${NAME}_${TYPE}_${VERSION}_SHA256SUMS"
}

# Main function to orchestrate the actions
main() {
  local key_id
  key_id=$(get_key_id)
  prepare_release_directory
  process_files
  create_shasums_file
  sign_shasums_file "$key_id"
}

main "$@"
