#!/bin/sh
cp -r $HELM_PLUGIN_DIR/files/* ./
chmod 777 ./create-updatecli-file.sh
./create-updatecli-file.sh
updatecli apply -c ./updatecli
rm ./create-updatecli-file.sh