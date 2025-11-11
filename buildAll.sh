#!/bin/bash
# Sequential build script for MDE4CPP
# This script runs generateAll, compileAll, and buildOCLAll tasks sequentially
# to ensure proper build order and avoid race conditions

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if we're in MDE4CPP_CrossPlatform, if so, go to parent
if [ -d "MDE4CPP_CrossPlatform" ] && [ -f "MDE4CPP_CrossPlatform/application/tools/gradlew" ]; then
    # We're in the main MDE4CPP directory
    MAIN_DIR="$SCRIPT_DIR"
elif [ -f "../MDE4CPP_CrossPlatform/application/tools/gradlew" ] || [ -f "../../MDE4CPP_CrossPlatform/application/tools/gradlew" ]; then
    # Try to find the main directory
    MAIN_DIR="$(cd .. && pwd)"
else
    MAIN_DIR="$SCRIPT_DIR"
fi

# Check if setenv exists and source it if available
# Note: We need to source only the environment variables, not execute the interactive parts
# The setenv file ends with 'bash' which starts an interactive shell - we skip that
SETENV_FILE=""
if [ -f "$MAIN_DIR/setenv" ]; then
    SETENV_FILE="$MAIN_DIR/setenv"
elif [ -f "setenv" ]; then
    SETENV_FILE="setenv"
fi

if [ -n "$SETENV_FILE" ]; then
    echo "Sourcing setenv from $(basename $(dirname $SETENV_FILE))..."
    # Extract only export statements and source them, skipping cd/gradlew/bash commands
    # This prevents the script from hanging on the interactive 'bash' command at the end
    while IFS= read -r line; do
        # Skip comments, empty lines, cd commands, gradlew commands, and bash command
        if [[ "$line" =~ ^[[:space:]]*export ]] && [[ ! "$line" =~ ^[[:space:]]*# ]]; then
            eval "$line" 2>/dev/null || true
        fi
    done < <(sed '/^cd \.\/gradlePlugins$/,$d' "$SETENV_FILE")
    
    # Also publish gradle plugins if needed (this is normally done in setenv)
    if [ -d "$MAIN_DIR/gradlePlugins" ]; then
        echo "Publishing MDE4CPP Gradle plugins..."
        (cd "$MAIN_DIR/gradlePlugins" && "$MAIN_DIR/application/tools/gradlew" publishMDE4CPPPluginsToMavenLocal >/dev/null 2>&1 || true)
    fi
fi

# Get gradlew path - try main directory first
GRADLEW="$MAIN_DIR/application/tools/gradlew"
if [ ! -f "$GRADLEW" ]; then
    GRADLEW="$MAIN_DIR/MDE4CPP_CrossPlatform/application/tools/gradlew"
fi

if [ ! -f "$GRADLEW" ]; then
    echo "Error: gradlew not found. Please ensure you're in the MDE4CPP directory structure."
    echo "Looked for: $GRADLEW"
    exit 1
fi

# Change to main directory for running gradle tasks
cd "$MAIN_DIR"

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

