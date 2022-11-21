#!/bin/bash
# Script to help in bulk editing spec paths in golang codes
# Usage: 
# 1) copy this script to a directory who (or whose child dir) have golang codes that call RunCypressContainer() method. (e.g tests/ dir)
# 2) execute from terminal by: ./cvmh_terratest.sh

find ./ -type f -name *.go | xargs sed -E 's/cypress\/integration\/([a-zA-Z0-9].+)\/([a-zA-Z0-9].+).spec.js/cypress\/e2e\/\1\/\2.cy.js/g'

# add -i to actually edit the files

