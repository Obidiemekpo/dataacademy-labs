#!/bin/bash
set -e

# Default values
TAINT_FILE="taint_resources.txt"
WORKING_DIR="./infra"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --file)
      TAINT_FILE="$2"
      shift 2
      ;;
    --dir)
      WORKING_DIR="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo "Using taint file: $TAINT_FILE"
echo "Working directory: $WORKING_DIR"

# Check if the taint file exists
if [ ! -f "$TAINT_FILE" ]; then
  echo "Taint file not found: $TAINT_FILE"
  echo "No resources to taint."
  exit 0
fi

# Change to the working directory
cd "$WORKING_DIR"

# Read the taint file and taint each resource
while IFS= read -r resource || [[ -n "$resource" ]]; do
  # Skip empty lines and comments
  if [[ -z "$resource" || "$resource" =~ ^# ]]; then
    continue
  fi
  
  echo "Tainting resource: $resource"
  terraform taint "$resource"
done < "../$TAINT_FILE"

echo "Resource tainting complete." 