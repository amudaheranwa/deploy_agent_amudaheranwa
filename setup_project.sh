#!/bin/bash

read -p "Enter a project name suffix: " INPUT

if [ -z "$INPUT" ]; then
    echo "Error: project name cannot be empty."
    exit 1
fi

PROJECT_DIR="attendance_tracker_${INPUT}"
ARCHIVE_NAME="attendance_tracker_${INPUT}_archive"

cleanup() {
    echo ""
    echo "Interrupt detected! Archiving current state and cleaning up..."

    
    if [ -d "$PROJECT_DIR" ]; then
        tar -czf "${ARCHIVE_NAME}.tar.gz" "$PROJECT_DIR"
        echo "Archive saved as: ${ARCHIVE_NAME}.tar.gz"
        rm -rf "$PROJECT_DIR"
        echo "Incomplete directory '$PROJECT_DIR' deleted."
    fi

    echo "Exiting setup."
    exit 1
}


trap cleanup SIGINT

echo "Creating project directory: $PROJECT_DIR"
mkdir -p "$PROJECT_DIR/Helpers"
mkdir -p "$PROJECT_DIR/reports"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

MISSING=false
for f in attendance_checker.py assets.csv config.json reports.log; do
    if [ ! -f "$SCRIPT_DIR/$f" ]; then
        echo "ERROR: Missing source file: $f"
        MISSING=true
    fi
done

if [ "$MISSING" = true ]; then
    echo ""
    echo "Please make sure all 4 source files are in the same folder as setup_project.sh"
    exit 1
fi

cp "$SCRIPT_DIR/attendance_checker.py" "$PROJECT_DIR/"
cp "$SCRIPT_DIR/assets.csv" "$PROJECT_DIR/Helpers/"
cp "$SCRIPT_DIR/config.json" "$PROJECT_DIR/Helpers/"
cp "$SCRIPT_DIR/reports.log" "$PROJECT_DIR/reports/"

echo "Files created successfully."

# Ask the user if they want to change the warning and failure thresholds
read -p "Do you want to update the attendance thresholds? (yes/no): " UPDATE_THRESHOLDS

if [ "$UPDATE_THRESHOLDS" = "yes" ] || [ "$UPDATE_THRESHOLDS" = "y" ]; then

    read -p "Enter new Warning threshold (default 75): " NEW_WARNING
    read -p "Enter new Failure threshold (default 50): " NEW_FAILURE

   
    NEW_WARNING=${NEW_WARNING:-75}
    NEW_FAILURE=${NEW_FAILURE:-50}

   
    if ! [[ "$NEW_WARNING" =~ ^[0-9]+$ ]] || ! [[ "$NEW_FAILURE" =~ ^[0-9]+$ ]]; then
        echo "Invalid input — thresholds must be numbers. Keeping defaults."
    else

        sed -i "s/\"warning\": [0-9]*/\"warning\": $NEW_WARNING/" "$PROJECT_DIR/Helpers/config.json"
        sed -i "s/\"failure\": [0-9]*/\"failure\": $NEW_FAILURE/" "$PROJECT_DIR/Helpers/config.json"
        echo "Thresholds updated — Warning: ${NEW_WARNING}%, Failure: ${NEW_FAILURE}%"
    fi

else
    echo "Keeping default thresholds (Warning: 75%, Failure: 50%)."
fi

# Check if python3 is installed
if python3 --version > /dev/null 2>&1; then
    PYTHON_VERSION=$(python3 --version)
    echo "Python3 is installed: $PYTHON_VERSION"
else
    echo "WARNING: python3 is not installed. The attendance checker will not run."
fi

# Verify that all required files and folders were created successfully
echo "Verifying project structure..."
STRUCTURE_OK=true

check_path() {
    if [ -e "$1" ]; then
        echo "  OK: $1"
    else
        echo "  MISSING: $1"
        STRUCTURE_OK=false
    fi
}

check_path "$PROJECT_DIR/attendance_checker.py"
check_path "$PROJECT_DIR/Helpers/assets.csv"
check_path "$PROJECT_DIR/Helpers/config.json"
check_path "$PROJECT_DIR/reports/reports.log"

if [ "$STRUCTURE_OK" = true ]; then
    echo "All files verified. Structure is correct."
else
    echo "Some files are missing. Please check the setup."
fi

echo ""
echo "Setup complete! Project directory: $PROJECT_DIR"
echo "To run: cd $PROJECT_DIR && python3 attendance_checker.py"

