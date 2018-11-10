
#!/bin/sh
# git pull all
#
# Quick and dirty script for executing 'git pull' on all sub-directories (not recursive because duh!!)
#
# Author: Lame Hacker (https://github.com/thelamehacker)
#
# License: GNU General Public License v3.0
# Release date: 10 November 2018
# Last updated: 10 November 2018
# Version: 0.1a
# -----------------------------------------------------------------------------

for d in *; do
  if [ -d "$d" ]; then
    ( cd "$d" && git pull )
  fi
done

# TODO
# Add error handling for directories that are not repositories
# Maybe introduce a simple menu for git pull, push, commit, status etc?