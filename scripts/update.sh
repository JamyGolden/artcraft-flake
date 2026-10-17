#!/usr/bin/env nix-shell
#! nix-shell -i bash -p curl jq
# Pins each app's latest GitHub release in releases.json, with hashes from upstream's SHA256SUMS.txt.
#
# Usage: ./scripts/update.sh [app...]    (default: every app in apps.nix)
set -euo pipefail
cd "$(dirname "$0")/.."

# {"<app>": {"repo": "<repo>", "cli": <bool>}}, from apps.nix.
repos=$(nix eval --json --file apps.nix --apply 'builtins.mapAttrs (name: app: {repo = app.repo or name; cli = app.cli or true;})')
[ $# -gt 0 ] || set -- $(jq -r 'keys[]' <<<"$repos")
[ -f releases.json ] || echo '{}' >releases.json

# The SRI hash of file $1 in $sums, or nothing if the release doesn't have that file.
sri() {
  local hex
  hex=$(awk -v f="$1" '$2 == f { print $1 }' <<<"$sums")
  [ -z "$hex" ] || nix hash convert --hash-algo sha256 --to sri "$hex"
}

for name in "$@"; do
  repo=$(jq -er --arg n "$name" '.[$n].repo' <<<"$repos") || { echo "unknown app: $name" >&2; exit 1; }

  # /releases/latest/download/ redirects to the latest tag, so this needs no API token.
  sums=$(curl -fsSL "https://github.com/storytold/$repo/releases/latest/download/SHA256SUMS.txt")
  version=$(sed -nE "s/^[0-9a-f]{64}  $name-([0-9][^-]*)-linux-x86_64\.tar\.gz$/\1/p" <<<"$sums")
  [ -n "$version" ] || { echo "$name: no linux-x86_64 tarball in the latest release" >&2; exit 1; }

  hashes=$(jq -n \
    --arg x86_64-linux "$(sri "$name-$version-linux-x86_64.tar.gz")" \
    --arg aarch64-linux "$(sri "$name-$version-linux-aarch64.tar.gz")" \
    --arg macos-dmg "$(sri "$name-$version-macos-universal.dmg")" \
    --arg macos-cli-zip "$(sri "$name-cli-$version-macos-universal.zip")" \
    '$ARGS.named | with_entries(select(.value != ""))')

  # flake.nix needs a hash for every platform (and the macOS CLI, if the app has one); a release
  # still uploading its assets, or one that skipped a platform, would otherwise break evaluation.
  required='["x86_64-linux", "aarch64-linux", "macos-dmg"]'
  if jq -e --arg n "$name" '.[$n].cli' <<<"$repos" >/dev/null; then
    required='["x86_64-linux", "aarch64-linux", "macos-dmg", "macos-cli-zip"]'
  fi
  missing=$(jq -r --argjson r "$required" '$r - keys | join(", ")' <<<"$hashes")
  [ -z "$missing" ] || { echo "$name $version: SHA256SUMS.txt has no $missing" >&2; exit 1; }

  old=$(jq -r --arg n "$name" '.[$n].version // "none"' releases.json)
  jq -S --arg n "$name" --arg v "$version" --argjson h "$hashes" '.[$n] = {version: $v, hashes: $h}' \
    releases.json >releases.json.tmp
  mv releases.json.tmp releases.json
  if [ "$old" = "$version" ]; then echo "$name: $version"; else echo "$name: $old -> $version"; fi
done
