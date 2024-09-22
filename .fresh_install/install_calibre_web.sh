#!/bin/bash

set -eo pipefail

CALIBRE_WEB_DIR="$HOME/calibre-web"
PYTHON_VERSION="3.9.13"  # You can adjust this to your preferred Python version

install_dependencies() {
    echo "Installing dependencies..."
    brew install imagemagick ghostscript
}

setup_python_environment() {
    echo "Setting up Python environment..."
    pyenv install -s $PYTHON_VERSION
    pyenv global $PYTHON_VERSION
    python -m venv "$CALIBRE_WEB_DIR/venv"
    source "$CALIBRE_WEB_DIR/venv/bin/activate"
    pip install --upgrade pip
}

install_calibre_web() {
    echo "Installing Calibre-Web..."
    pip install calibreweb

    # Install optional features
    pip install calibreweb[metadata]
    pip install calibreweb[comics]
    pip install calibreweb[kobo]
}

setup_calibre_web() {
    echo "Setting up Calibre-Web configuration..."
    
    # Prompt for existing Calibre library location
    read -p "Enter the path to your existing Calibre library (or press Enter to create a new one): " CALIBRE_LIBRARY_PATH
    
    if [ -z "$CALIBRE_LIBRARY_PATH" ]; then
        CALIBRE_LIBRARY_PATH="$HOME/calibre-library"
        mkdir -p "$CALIBRE_LIBRARY_PATH"
        echo "Created new Calibre library at $CALIBRE_LIBRARY_PATH"
    else
        if [ ! -d "$CALIBRE_LIBRARY_PATH" ]; then
            echo "The specified directory does not exist. Please check the path and try again."
            exit 1
        fi
        if [ ! -f "$CALIBRE_LIBRARY_PATH/metadata.db" ]; then
            echo "Warning: No metadata.db found in the specified directory. Make sure this is a valid Calibre library."
        fi
    fi
    
    # Start Calibre-Web for initial setup
    cps &
    CPS_PID=$!
    
    echo "Calibre-Web is starting. Please complete the following steps:"
    echo "1. Open http://localhost:8083 in your browser"
    echo "2. Log in with the default credentials (admin/admin123)"
    echo "3. Go to the admin page and set 'Location of Calibre database' to: $CALIBRE_LIBRARY_PATH"
    echo "4. Configure any other settings as needed"
    echo "5. Once done, press any key to continue"
    
    read -n 1 -s
    kill $CPS_PID
}

setup_launchd() {
    PLIST_FILE="$HOME/Library/LaunchAgents/com.calibre-web.plist"
    
    echo "Creating LaunchAgent for Calibre-Web..."
    cat > "$PLIST_FILE" << EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.calibre-web</string>
    <key>ProgramArguments</key>
    <array>
        <string>$CALIBRE_WEB_DIR/venv/bin/cps</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>WorkingDirectory</key>
    <string>$CALIBRE_WEB_DIR</string>
    <key>StandardOutPath</key>
    <string>$HOME/Library/Logs/calibre-web.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/Library/Logs/calibre-web.error.log</string>
</dict>
</plist>
EOL

    launchctl load "$PLIST_FILE"
    echo "LaunchAgent for Calibre-Web has been created and loaded."
}

echo "Starting Calibre-Web installation..."
install_dependencies
setup_python_environment
install_calibre_web
setup_calibre_web
setup_launchd
echo "✅ Calibre-Web installation and setup completed."
echo "Calibre-Web should now be running. Access it at http://localhost:8083"
echo "Please ensure you've set up the correct Calibre library location in the Calibre-Web settings."
