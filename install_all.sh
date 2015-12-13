#!/bin/bash

ALL_REPOS=$( find . -maxdepth 1 -type d | grep ClueBot | cut -d '/' -f 2 | sort )

for REPO in $ALL_REPOS; do
    pushd $REPO >> /dev/null
    echo "Processing ${REPO}..."
    cpanm --installdeps .
    if perl Makefile.PL && make && make test && make install; then
        make clean
        echo 'Done!'
    else
        echo "Failed to install $REPO"
        exit 1
    fi
    popd
    echo "-----------------------------"
done
