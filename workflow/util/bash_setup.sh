#!/usr/bin/env bash

# Set up bash environment.
# Requirements: Bash 3+ (OS X ships with Bash 3)

shopt -s nullglob # Expand globs with zero matches to zero arguments (instead of failing)
shopt -s dotglob # Let globs match dot files
#shopt -s globstar # Not supported in Bash < 4 :'(
