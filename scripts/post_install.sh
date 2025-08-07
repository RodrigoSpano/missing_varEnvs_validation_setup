#! /bin/bash -xe

set -e
# Function to find the project root (where package.json exists, but not inside node_modules)
find_project_root() {
    CURRENT_DIR="$(pwd)"
    while [ "$CURRENT_DIR" != "/" ]; do
        if [ -f "$CURRENT_DIR/package.json" ] && \
           [ -d "$CURRENT_DIR/node_modules" ] && \
           { [ -f "$CURRENT_DIR/yarn.lock" ] || [ -f "$CURRENT_DIR/pnpm-lock.yaml" ] || [ -f "$CURRENT_DIR/package-lock.json" ]; }; then
            cd $CURRENT_DIR
            return 0
        else
            cd ../
        fi
        CURRENT_DIR="$(dirname "$CURRENT_DIR")"
    done
    echo "Project root not found!" >&2
    exit 1
}

# PROJECT_ROOT=$(find_project_root)
# cd "$PROJECT_ROOT"
find_project_root

mkdir -p ./src/envs && cp ./node_modules/envs-var-validator/envs/index.ts ./src/envs/index.ts

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

# Get the detected package manager
PACKAGE_MANAGER=$(detect_package_manager)

echo "Detected package manager: $PACKAGE_MANAGER"

MISSING_DEPS="joi@17.13.3 dotenv@16.5.0"

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

echo "you can start using the package now!"
exit 0