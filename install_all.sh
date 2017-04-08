#!/bin/bash

ALL_REPOS=$( cat <<EOD
Bot-ClueBot
Bot-ClueBot-Plugin-WebTokens
Bot-ClueBot-Plugin-HTTPD
Bot-ClueBot-Plugin-WebSocket
Bot-ClueBot-Plugin-Run
Bot-ClueBot-Plugin-Git
EOD
)

if ! command -v cpanm; then
    echo "You seem to be missing cpanm on the path"
    exit 1
fi

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
