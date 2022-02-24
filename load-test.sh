#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail -o posix

max="$1"
date
echo "url: $2
rate: $max calls / second"

function get() {
  curl -s -f -e -L "$1" | jq -r '.Hostname + " " + .GCPZone'
}

while true; do
  for i in `seq 1 $max`; do
    get $2 &
  done
done