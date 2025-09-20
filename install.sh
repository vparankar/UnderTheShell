#!/bin/bash

# Ensure script is run with sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo:"
  echo "sudo ./install.sh"
  exit 1
fi

echo "Installing UnderTheShell..."

# Make the game executable
chmod +x undertheshell.sh

# Copy to a system-wide PATH directory
cp undertheshell.sh /usr/local/bin/undertheshell

# Set permissions for the global executable
chmod 755 /usr/local/bin/undertheshell

echo "Installation complete!"
echo "You can now run the game by typing 'undertheshell' in your terminal."
