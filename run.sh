#!/bin/sh
cp -r $HELM_PLUGIN_DIR/files/* ./
sh ./create-updatecli-file.sh
updatecli apply -c ./updatecli