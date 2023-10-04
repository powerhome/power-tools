#!/usr/bin/env bash

set -e

rubies=("ruby-2.5.9" "ruby-2.6.8" "ruby-2.7.4")
for i in "${rubies[@]}"
do
  echo "====================================================="
  echo "$i: Start Test"
  echo "====================================================="
  rvm $i exec bundle
  rvm $i exec bundle exec rake
  echo "====================================================="
  echo "$i: End Test"
  echo "====================================================="
done
