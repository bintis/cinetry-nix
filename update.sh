#!/usr/bin/env bash
# Check the Cinetry GitHub releases for a newer .deb and rewrite cinetry.nix
# in-place if a newer version is available.
#
# Exit codes:
#   0 — success (file may or may not have been updated)
#   1 — error
set -euo pipefail

cd "$(dirname "$0")"

REPO="gstory0404/Cinetry"
API_URL="https://api.github.com/repos/$REPO/releases/latest"

echo ">> querying $API_URL"
if [ -n "${GITHUB_TOKEN:-}" ]; then
  info=$(curl -fsSL -H "Authorization: Bearer $GITHUB_TOKEN" "$API_URL")
else
  info=$(curl -fsSL "$API_URL")
fi

asset_url=$(echo "$info" | jq -r '.assets[] | select(.name | endswith("_linux.deb")) | .browser_download_url')
asset_name=$(echo "$info" | jq -r '.assets[] | select(.name | endswith("_linux.deb")) | .name')
# Asset name is "Cinetry_<version>+<build>_linux.deb"; we pin to the
# "<version>+<build>" string so a build-number bump on the same version
# also triggers an update.
version=$(echo "$asset_name" | sed -nE 's/^Cinetry_([0-9.]+\+[0-9]+)_linux\.deb$/\1/p')

if [ -z "$version" ] || [ -z "$asset_url" ]; then
  echo "!! could not parse release info"
  echo "$info" | head -40
  exit 1
fi

# Current pin from cinetry.nix. The URL has the build number percent-encoded
# (%2B for +), so we grep the version+build directly out of it.
current_version=$(grep -oE 'releases/download/[^/]+/Cinetry_[0-9.]+%2B[0-9]+_linux\.deb' cinetry.nix \
  | head -1 | sed -nE 's|.*Cinetry_([0-9.]+)%2B([0-9]+)_linux\.deb|\1+\2|p')

echo ">> current: ${current_version:-unknown}"
echo ">> latest:  $version"
echo ">> url:     $asset_url"

if [ "$current_version" = "$version" ]; then
  echo ">> already up to date"
  exit 0
fi

echo ">> prefetching to compute sha256..."
hash=$(nix-prefetch-url --type sha256 "$asset_url")
sri=$(nix --extra-experimental-features nix-command hash convert --hash-algo sha256 --to sri "$hash")

echo ">> sha256:  $sri"

# Cinetry's release tag is just the upstream version without the +build
# suffix (e.g. "0.8.1", not "0.8.1+44"). Extract it for the version field.
upstream_version=$(echo "$version" | sed -E 's/\+.*//')

# url uses %2B encoding for the + literal — preserve that.
encoded_url=$(echo "$asset_url" | sed -E 's/\+/%2B/g')

# In-place rewrite. Three independent lines, each unique in cinetry.nix:
#   version = "X.Y.Z";
#   url = "https://github.com/.../releases/download/.../Cinetry_X.Y.Z%2BN_linux.deb";
#   sha256 = "sha256-...";
sed -i -E "s|version = \"[0-9.]+\";|version = \"$upstream_version\";|" cinetry.nix
sed -i -E "s|url = \"https://github.com/gstory0404/Cinetry/releases/download/[^\"]+\";|url = \"$encoded_url\";|" cinetry.nix
sed -i -E "s|sha256 = \"sha256-[^\"]+\";|sha256 = \"$sri\";|" cinetry.nix

echo ">> cinetry.nix updated ${current_version:-unknown} -> $version"
