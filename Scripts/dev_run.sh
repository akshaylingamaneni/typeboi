#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

CONFIG=debug "$ROOT_DIR/Scripts/build_app_bundle.sh"
open "$ROOT_DIR/dist/TypeBoi.app"
