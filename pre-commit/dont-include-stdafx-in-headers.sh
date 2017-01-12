#!/bin/bash

# This is a simple git pre-commit hook which checks if "StdAfx" is included in
# any "git add"-ed header files.

declare CHANGED_H=$(git diff --cached --name-only --diff-filter=ACM | grep -E "\.h$")

declare BAD_FILES=$(grep -l -E -i "^#include\s*(\"|\<)StdAfx\.h(\"|\>)" $CHANGED_H)
    
if [[ "$BAD_FILES" != "" ]]
then
    echo "error: one or more header files (.h) include \"StdAfx.h\":"
    for FILENAME in $BAD_FILES; do
        echo "  $FILENAME"
    done
    exit 1
else
    exit 0
fi