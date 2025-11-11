#!/bin/bash
# Sequential build script for MDE4CPP
# This script runs generateAll, compileAll, and buildOCLAll tasks sequentially
# to ensure proper build order and avoid race conditions

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if setenv exists and source it if available
if [ -f "setenv" ]; then
    echo "Sourcing setenv..."
    source setenv >/dev/null 2>&1 || true
fi

# Get gradlew path
GRADLEW="./application/tools/gradlew"
if [ ! -f "$GRADLEW" ]; then
    GRADLEW="./MDE4CPP_CrossPlatform/application/tools/gradlew"
fi

if [ ! -f "$GRADLEW" ]; then
    echo "Error: gradlew not found. Please run this script from the MDE4CPP root directory."
    exit 1
fi

echo "=========================================="
echo "MDE4CPP Sequential Build Script"
echo "=========================================="
echo ""

# Step 1: Generate all models
echo "Step 1/3: Running generateAll..."
echo "----------------------------------------"
if ! "$GRADLEW" generateAll; then
    echo ""
    echo "ERROR: generateAll failed!"
    exit 1
fi
echo "✓ generateAll completed successfully"
echo ""

# Step 2: Compile all generated code
echo "Step 2/3: Running compileAll..."
echo "----------------------------------------"
if ! "$GRADLEW" compileAll; then
    echo ""
    echo "ERROR: compileAll failed!"
    exit 1
fi
echo "✓ compileAll completed successfully"
echo ""

# Step 3: Build OCL components
echo "Step 3/3: Running src:buildOCLAll..."
echo "----------------------------------------"
if ! "$GRADLEW" src:buildOCLAll; then
    echo ""
    echo "ERROR: src:buildOCLAll failed!"
    exit 1
fi
echo "✓ src:buildOCLAll completed successfully"
echo ""

echo "=========================================="
echo "BUILD SUCCESSFUL - All tasks completed!"
echo "=========================================="

