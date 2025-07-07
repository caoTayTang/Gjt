#! /bin/bash

INSTALLED_PATH=/usr/local/bin/bku


install() {
    echo "Checking dependencies..."

    REQUIRED_PACKAGES=("diffutils" "patch" "cron")
    MISSING_PACKAGES=()

    for pkg in "${REQUIRED_PACKAGES[@]}"; do
        if ! dpkg -s "$pkg" &> /dev/null; then
            MISSING_PACKAGES+=("$pkg")
        fi
    done

    if [ ${#MISSING_PACKAGES[@]} -eq 0 ]; then
        echo "All dependencies installed."
    else
        echo "Installing missing dependencies: ${MISSING_PACKAGES[*]}"
        sudo apt update -qq
        if sudo apt install -y "${MISSING_PACKAGES[@]}"; then
            echo "Dependencies installed successfully."
        else
            echo "Error: Failed to install required packages: ${MISSING_PACKAGES[*]}"
            exit 1
        fi
    fi

    chmod +x ./bku.sh
    sudo cp ./bku.sh "$INSTALLED_PATH"
    echo "BKU installed to $INSTALLED_PATH"
}

#!INFO: 
# 1. Remove bku from system PATH
# 2. Delete any scheduled cron jobs
# 3. Optionally clean-up residual files?

uninstall() {
    echo "Checking BKU installation..."

    if [ ! -f $INSTALLED_PATH ]; then
        echo "Error: BKU is not installed in $INSTALLED_PATH. Nothing to uninstall."
        exit 1
    fi

    echo "Removing BKU from $INSTALLED_PATH..."
    sudo rm "$INSTALLED_PATH"
    echo "Removing scheduled backups..."

    crontab -l 2>/dev/null | grep -v "./bku.sh" | crontab - 2>/dev/null || true
    crontab -l 2>/dev/null | grep -v "bku" | crontab - 2>/dev/null || true

    echo "BKU successfully uninstalled."
}

case "$1" in
    --install) install ;;
    --uninstall) uninstall ;;
    *) 
        echo "Invalid argument" 
        exit 1
        ;;
esac
