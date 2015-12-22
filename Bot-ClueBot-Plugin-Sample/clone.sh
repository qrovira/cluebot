#!/bin/bash

PLUGIN_NAME=$1

if [[ "x$1" == "x" ]]; then
    echo Need to provide a plugin name
    exit 1
fi

echo "Going to mangle current dir to clone Sample plugin into $PLUGIN_NAME."
echo "Press any key to proceed."
read
rm -rf .git clone.sh
mv lib/Bot/ClueBot/Plugin/Sample.pm lib/Bot/ClueBot/Plugin/${PLUGIN_NAME}.pm
find -type f | xargs sed -i "s#Sample#$PLUGIN_NAME#g"
