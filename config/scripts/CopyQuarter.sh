#!/usr/bin/env bash
set -euo pipefail

date +%y-Q%q | tr -d '\n' | xclip -selection clipboard
