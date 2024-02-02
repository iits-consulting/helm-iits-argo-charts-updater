#!/bin/sh
cp -r $HELM_PLUGIN_DIR/files/* ./
chmod 777 ./create-updatecli-file.sh
./create-updatecli-file.sh
updatecli apply -c ./updatecli
rm ./create-updatecli-file.sh

#Add git hooks
IITS_CHART_NAME=$(basename "$PWD")
sed "s/IITS_CHART_NAME/${IITS_CHART_NAME}/g" $HELM_PLUGIN_DIR/git-hooks/template-pre-commit > ./git-hooks/pre-commit
chmod +x ./git-hooks/pre-commit
git config core.hooksPath $IITS_CHART_NAME/git-hooks