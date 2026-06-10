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
