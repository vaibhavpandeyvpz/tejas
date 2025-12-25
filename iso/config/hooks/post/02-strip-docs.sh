#!/bin/bash
set -e

PROFILE=$(cat /etc/tejas-profile 2>/dev/null || echo user)

if [ "$PROFILE" = "user" ]; then
  rm -rf /usr/share/doc/*
  rm -rf /usr/share/man/*
  rm -rf /usr/share/info/*
  rm -rf /usr/share/lintian/*
fi
