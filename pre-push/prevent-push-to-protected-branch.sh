#!/bin/sh
protected_branch='master'  
current_branch=$(git symbolic-ref --quiet --short HEAD)

if [ $protected_branch = $current_branch ]  
then  
    read -p "You're about to push $protected_branch, is that what you intended? [y|n] " -n 1 -r < /dev/tty
    echo
    if echo $REPLY | grep -E '^[Yy]$' > /dev/null
    then
        exit 0 # push will execute
    fi
    exit 1 # push will not execute
else  
    exit 0 # push will execute
fi
