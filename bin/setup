#!/usr/bin/env bash
set -e

root=$(pwd)

gemfileLock="$root/Gemfile.lock"
bundleDir="$root/.bundle"
vendorDir="$root/vendor"
outDir="$root/_site"
cacheDir="$root/.jekyll-cache"

sleep_ms() {
  # Sleep for given milliseconds
  local ms=$1
  sleep $(echo "$ms / 1000" | bc -l)
}

runCommand() {
  # Run a command and print it
  echo "+ $*"
  "$@"
}

init() {
  echo "Cleaning old lock files and directories..."
  rm -f "$gemfileLock"
  rm -rf "$bundleDir"
  rm -rf "$vendorDir"
  rm -rf "$outDir"
  rm -rf "$cacheDir"

  sleep_ms 1000

  echo "Configuring bundler path..."
  runCommand bundle config set --local path "vendor/bundle"
  echo "Configuring bundler system gems..."
  runCommand bundle config set --local system_gems false

  echo "Running bundle install..."
  runCommand bundle install

  echo "Init setup completed successfully!"
}

if ! init; then
  echo "An unexpected error occurred." >&2
  exit 1
fi
