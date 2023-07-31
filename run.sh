#!/bin/sh
cp -r $HELM_PLUGIN_DIR/files/* ./
./create-updatecli-file.sh
updatecli apply -c ./updatecli