#!/bin/bash

## Add the repository (replace with your own URL if needed)
#helm repo add iits https://charts.iits.tech
#
## Update the repository to fetch the latest chart information
#helm repo update

mkdir -p updatecli

# Get the chart names from the repository
# Path to the values.yaml file
VALUES_FILE="values.yaml"

# Check if the file exists
if [[ ! -f "$VALUES_FILE" ]]; then
  echo "File $VALUES_FILE does not exist."
  exit 1
fi

# Iterate through the chart names
chart_names=""
for chart in $(yq e '.charts | keys | .[]' $VALUES_FILE); do
  # Check if path is set
  path=$(yq e ".charts.$chart.path // \"null\"" $VALUES_FILE)
  if [ "$path" = "null" ]; then
    # Check if overrideChartName is set
    override_name=$(yq e ".charts.$chart.overrideChartName // \"null\"" $VALUES_FILE)
    if [ "$override_name" != "null" ]; then
      chart_names+="$override_name "
    else
      chart_names+="$chart "
    fi
  fi
done

echo "$chart_names"

# Loop through the chart names and create a yaml file for each
for chart_name in $chart_names; do
  # Create a yaml file with the chart name
  cat > updatecli/"$chart_name.yaml" <<EOL
sources:
  latestRelease:
    kind: helmChart
    spec:
      url: "https://charts.iits.tech"
      name: "$chart_name"
      version: "*.*.*"
conditions:
  chartExists:
    name: "iits-consulting $chart_name Helm Chart is used"
    kind: yaml
    disablesourceinput: true
    spec:
      file: "values.yaml"
      key: "charts.$chart_name"
      keyonly: true
targets:
  chartVersion:
    name: Bump iits-consulting $chart_name
    kind: yaml
    spec:
      file: "values.yaml"
      key: "charts.$chart_name.targetRevision"
      versionIncrement: "patch"
EOL
  echo "Created YAML file for $chart_name"
done