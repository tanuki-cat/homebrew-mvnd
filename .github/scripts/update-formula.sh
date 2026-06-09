#!/usr/bin/env bash
#
# Update Formula/mvnd.rb to a given mvnd version.
#
# Rewrites the `version` line and, for each platform, the `url` + following
# `sha256` line (macOS amd64/aarch64 and Linux amd64). Checksums are fetched
# from the official Apache downloads mirror.
#
# Usage: update-formula.sh <version>   e.g. update-formula.sh 1.0.6

set -euo pipefail

VERSION="${1:?usage: update-formula.sh <version>}"
FORMULA="${FORMULA:-Formula/mvnd.rb}"
BASE_URL="https://downloads.apache.org/maven/mvnd/${VERSION}"

[[ -f "$FORMULA" ]] || { echo "Formula not found: $FORMULA" >&2; exit 1; }

fetch_sha() {
  # $1 = platform suffix, e.g. darwin-amd64
  curl -fsSL "${BASE_URL}/maven-mvnd-${VERSION}-${1}.zip.sha256"
}

# Rewrite the url + immediately-following sha256 line for one platform suffix.
# Matched by suffix (not by old version), so platforms pinned to a different
# version are still updated correctly.
update_platform() {
  local suffix="$1" sha="$2"
  perl -0pi -e "
    s{
      url\s+\"https://downloads\.apache\.org/maven/mvnd/[^\"]*/maven-mvnd-[^\"]*-${suffix}\.zip\"\n
      (\s*)sha256\s+\"[0-9a-f]+\"
    }
    {url \"${BASE_URL}/maven-mvnd-${VERSION}-${suffix}.zip\"\n\${1}sha256 \"${sha}\"}gx
  " "$FORMULA"
}

echo "Fetching checksums for mvnd ${VERSION}..."
SHA_DARWIN_AMD64="$(fetch_sha darwin-amd64)"
SHA_DARWIN_AARCH64="$(fetch_sha darwin-aarch64)"
SHA_LINUX_AMD64="$(fetch_sha linux-amd64)"

echo "  darwin-amd64:   ${SHA_DARWIN_AMD64}"
echo "  darwin-aarch64: ${SHA_DARWIN_AARCH64}"
echo "  linux-amd64:    ${SHA_LINUX_AMD64}"

# Bump version line.
perl -pi -e "s/^(\s*version\s+)\"[^\"]*\"/\${1}\"${VERSION}\"/" "$FORMULA"

update_platform "darwin-amd64"   "${SHA_DARWIN_AMD64}"
update_platform "darwin-aarch64" "${SHA_DARWIN_AARCH64}"
update_platform "linux-amd64"    "${SHA_LINUX_AMD64}"

echo "Updated ${FORMULA} to ${VERSION}."
