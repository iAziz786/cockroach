#!/usr/bin/env bash

set -euo pipefail

# Avoid adding new exclusions unless necessary.
STRINGER_EXCLUSIONS="
pkg/kv/kvserver/closedts/sidetransport/cantclosereason_string.go
pkg/sql/sem/tree/statementtype_string.go
"

git grep 'go:generate stringer' pkg | while read LINE; do
    dir=$(dirname $(echo $LINE | cut -d: -f1))
    type=$(echo $LINE | grep -o -- '-type[= ][^ ]*' | sed 's/-type[= ]//g' | awk '{print tolower($0)}')
    if [[ "$STRINGER_EXCLUSIONS" == *"$dir/${type}_string.go"* ]]; then
        # This file is missing.
        continue
    fi
    build_out=$(bazel query --output=build "//$dir:${type}_string.go")
    if [[ -z "$build_out" ]]; then
        echo 'Detected an autogenerated file that is not built inside the Bazel sandbox: '
        echo "  $dir/${type}_string.go, generated by: $LINE"
        echo 'EITHER generate this file using the Bazel sandbox (see the utilities in build/STRINGER.bzl);'
        echo 'OR, add this file to the list of STRINGER_EXCLUSIONS in build/bazelutil/check-genfiles.sh'
        exit 1
    fi
done
