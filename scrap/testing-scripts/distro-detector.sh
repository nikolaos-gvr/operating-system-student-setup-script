if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$(printf '%s' "$ID" | tr '[:upper:]' '[:lower:]')
else
    echo "Cannot detect distribution."
    exit 1
fi

echo "Detected Distribution $DISTRO"