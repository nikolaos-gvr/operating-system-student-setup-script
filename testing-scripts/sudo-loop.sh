# 1) Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root."
    echo "Please run: sudo sh $0"
    exit 1
fi

# 3) Optional sudo keep-alive (only useful if script internally calls sudo)
# If already root, this does nothing harmful
echo "enabling sudo loop"
if command -v sudo >/dev/null 2>&1; then
    sudo -v 2>/dev/null

    # Keep sudo alive in background
    (
        while true; do
            sudo -v 2>/dev/null
            echo "looping sudo timestamp"
            sleep 1
        done
    ) &
    SUDO_PID=$!
fi