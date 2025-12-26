#!/bin/bash
set -e

echo "[set-default-locale] Setting default locale to en_IN"

update-locale LANG=en_IN.UTF-8
