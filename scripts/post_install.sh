#! /bin/bash -xe

# set -e

mkdir -p ../../src/envs && cp envs/index.ts ../../src/envs/index.ts

cd ../../

# Function to detect package manager
detect_package_manager() {
    # Check for yarn.lock
    if [ -f "yarn.lock" ]; then
        echo "yarn"
        return 0
    fi
    
    # Check for pnpm-lock.yaml
    if [ -f "pnpm-lock.yaml" ||  -f "pnpm-workspace.yaml" ]; then
        echo "pnpm"
        return 0
    fi
    
    # Default if non of previous ones are true
        echo "npm"
}

# Function to get dependencies from package.json
get_dependencies() {
    local package_json="$1"
    local deps_type="$2"  # "dependencies" or "devDependencies"
    
    # Extract dependencies using jq (if available) or grep/sed
    if command -v jq >/dev/null 2>&1; then
        jq -r ".${deps_type} | to_entries[] | \"\(.key)@\(.value)\"" "$package_json" 2>/dev/null || echo ""
    else
        # Fallback using grep and sed
        grep -A 100 "\"${deps_type}\"" "$package_json" | grep -B 100 "}" | grep "\".*\":" | sed 's/.*"\([^"]*\)":\s*"\([^"]*\)".*/\1@\2/' 2>/dev/null || echo ""
    fi
}

# Function to check if dependency exists in main package.json
dependency_exists() {
    local dep_name="$1"
    local main_package_json="$2"
    
    if command -v jq >/dev/null 2>&1; then
        jq -e ".dependencies[\"$dep_name\"]" "$main_package_json" >/dev/null 2>&1 || jq -e ".devDependencies[\"$dep_name\"]" "$main_package_json" >/dev/null 2>&1
    else
        # Fallback using grep
        grep -q "\"$dep_name\":" "$main_package_json"
    fi
}

# Get the detected package manager
PACKAGE_MANAGER=$(detect_package_manager)

echo "Detected package manager: $PACKAGE_MANAGER"

# Paths to package.json files
CURRENT_PACKAGE_JSON="node_modules/envs-var-validator/package.json"
MAIN_PACKAGE_JSON="package.json"

# Check if main package.json exists
if [ ! -f "$MAIN_PACKAGE_JSON" ]; then
    echo "Error: Main package.json not found in root directory"
    exit 1
fi

# Check if current package.json exists
if [ ! -f "$CURRENT_PACKAGE_JSON" ]; then
    echo "Error: Current package.json not found at $CURRENT_PACKAGE_JSON"
    exit 1
fi

echo "Reading dependencies from $CURRENT_PACKAGE_JSON"
echo "Comparing with $MAIN_PACKAGE_JSON"

# Get dependencies from current package.json
CURRENT_DEPS=$(get_dependencies "$CURRENT_PACKAGE_JSON" "dependencies")
CURRENT_DEV_DEPS=$(get_dependencies "$CURRENT_PACKAGE_JSON" "devDependencies")

# Combine all dependencies
ALL_DEPS="$CURRENT_DEPS
$CURRENT_DEV_DEPS"

# Filter out empty lines and find missing dependencies
MISSING_DEPS=""
while IFS= read -r dep; do
    if [ -n "$dep" ]; then
        dep_name=$(echo "$dep" | cut -d'@' -f1)
        if ! dependency_exists "$dep_name" "$MAIN_PACKAGE_JSON"; then
            if [ -n "$MISSING_DEPS" ]; then
                MISSING_DEPS="$MISSING_DEPS $dep"
            else
                MISSING_DEPS="$dep"
            fi
            echo "Missing dependency: $dep"
        else
            echo "Dependency already exists: $dep_name"
        fi
    fi
done <<< "$ALL_DEPS"

# Install missing dependencies based on the detected package manager
if [ -n "$MISSING_DEPS" ]; then
    echo "Installing missing dependencies: $MISSING_DEPS"
    
    case $PACKAGE_MANAGER in
        "yarn")
            echo "Installing dependencies with yarn..."
            yarn add $MISSING_DEPS
            ;;
        "pnpm")
            echo "Installing dependencies with pnpm..."
            pnpm add $MISSING_DEPS
            ;;
        "npm")
            echo "Installing dependencies with npm..."
            npm install $MISSING_DEPS
            ;;
        *)
            echo "Unknown package manager: $PACKAGE_MANAGER"
            exit 1
            ;;
    esac
else
    echo "All dependencies are already installed in the main project."
fi
