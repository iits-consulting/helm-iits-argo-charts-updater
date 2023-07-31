#!/bin/bash

mkdir -p updatecli

# Get the chart names from the repository
# Path to the values.yaml file
VALUES_FILE="values.yaml"

# Check if the file exists
if [[ ! -f "$VALUES_FILE" ]]; then
  echo "File $VALUES_FILE does not exist."
  exit 1
fi

# Iterate through the chart names in each values file
yq e '.charts | keys | .[]' "$VALUES_FILE" | while read -r release_name; do
  path=$(yq e ".charts.$release_name.path // \"null\"" "$VALUES_FILE")
  if [ "$path" = "null" ]; then
    overrideChartName=$(yq e ".charts.$release_name.overrideChartName // \"$release_name\"" "$VALUES_FILE")

    # Create a yaml file with the chart name
    cat > "updatecli/$release_name.yaml" <<EOL
sources:
  latestRelease:
    kind: helmChart
    spec:
      url: "https://charts.iits.tech"
      name: "$overrideChartName"
      version: "*.*.*"
conditions:
  chartExists:
    name: "iits-consulting $release_name Helm Chart is used"
    kind: yaml
    disablesourceinput: true
    spec:
      file: "$VALUES_FILE"
      key: "charts.$release_name"
      keyonly: true
targets:
  chartVersion:
    name: "Bump iits-consulting $release_name"
    kind: yaml
    spec:
      file: "$VALUES_FILE"
      key: "charts.$release_name.targetRevision"
      versionIncrement: "patch"
EOL
    echo "Created YAML file for $release_name in $VALUES_FILE"
  fi
done