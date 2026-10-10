#!/usr/bin/env bash
set -euo pipefail

readonly sdk_version='3.13.4'
readonly install_root='.dart-sdk'
readonly archive_url="https://storage.googleapis.com/dart-archive/channels/stable/release/${sdk_version}/sdk/dartsdk-linux-x64-release.zip"

if [[ "$(uname -s)" != 'Linux' || "$(uname -m)" != 'x86_64' ]]; then
  echo 'This installer currently supports Linux x86_64 only.' >&2
  exit 1
fi

if [[ -x "${install_root}/bin/dart" ]] &&
  "${install_root}/bin/dart" --version 2>&1 | grep -q "Dart SDK version: ${sdk_version}"; then
  echo "Dart SDK ${sdk_version} is already installed."
  exit 0
fi

readonly temporary_directory="$(mktemp -d "${TMPDIR:-/tmp}/dart-sdk.XXXXXX")"
trap 'rm -rf -- "$temporary_directory"' EXIT

curl --fail --location --silent --show-error \
  "$archive_url" \
  --output "${temporary_directory}/dart-sdk.zip"
unzip -q "${temporary_directory}/dart-sdk.zip" -d "$temporary_directory"

rm -rf -- "$install_root"
mv "${temporary_directory}/dart-sdk" "$install_root"
"${install_root}/bin/dart" --version
