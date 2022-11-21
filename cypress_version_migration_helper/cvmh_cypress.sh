#!/bin/bash
# Script to help in bulk renaming while migrating from cypress 7.7.x to 11.0.x
# Usage: 
# 1) copy this script to a directory who (or whose child dir) have cypress spec files. (e.g integration/ dir)
# 2) execute from terminal by: ./cvmh_cypress.sh
files=$(find . -name "*.spec.js")
for file in $files; do 
    mv -- "$file" "${file%.spec.js}.cy.js"
done
