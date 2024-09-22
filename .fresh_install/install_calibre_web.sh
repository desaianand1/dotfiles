#!/bin/bash

set -eo pipefail

CALIBRE_WEB_DIR="$HOME/calibre-web"
VENV_DIR="$CALIBRE_WEB_DIR/venv"
PLIST_FILE="$HOME/Library/LaunchAgents/com.calibre-web.plist"

check_dependencies() {
    local missing_deps=()
    
    if ! command -v pyenv &> /dev/null; then
        missing_deps+=("pyenv")
    fi
    
    if ! command -v pip &> /dev/null; then
        missing_deps+=("pip")
    fi
    
    if ! command -v brew &> /dev/null; then
        missing_deps+=("brew")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "Error: The following required dependencies are missing:"
        printf '%s\n' "${missing_deps[@]}"
        echo "Please install these dependencies and run the script again."
        exit 1
    fi
}

check_imagemagick() {
    if ! brew list imagemagick &>/dev/null; then
        echo "Error: ImageMagick is not installed."
        echo "Please install them using Homebrew:"
        echo "brew install imagemagick"
        exit 1
    fi
}

setup_python_environment() {
    if [ ! -d "$VENV_DIR" ]; then
        echo "Setting up Python virtual environment..."
        python -m venv "$VENV_DIR"
    fi
    source "$VENV_DIR/bin/activate"
}

install_calibre_web() {
    if ! pip show calibreweb &>/dev/null; then
        echo "Installing Calibre-Web..."
        pip install calibreweb
        pip install calibreweb[metadata] calibreweb[comics] calibreweb[kobo] calibreweb[goodreads] calibreweb[oauth]
    else
        echo "Calibre-Web is already installed. Checking for updates..."
        pip install --upgrade calibreweb
        pip install --upgrade calibreweb[metadata] calibreweb[comics] calibreweb[kobo] calibreweb[goodreads] calibreweb[oauth]
    fi
}

setup_calibre_web() {
    if [ ! -f "$CALIBRE_WEB_DIR/app.db" ]; then
        echo "Setting up Calibre-Web configuration..."
        
        while true; do
            read -p "Enter the absolute path to your existing Calibre library (or press Enter to create a new one): " CALIBRE_LIBRARY_PATH
            
            if [ -z "$CALIBRE_LIBRARY_PATH" ]; then
                CALIBRE_LIBRARY_PATH="$HOME/calibre-library"
                mkdir -p "$CALIBRE_LIBRARY_PATH"
                echo "Created new Calibre library at $CALIBRE_LIBRARY_PATH"
                break
            else
                # Convert to absolute path if relative
                CALIBRE_LIBRARY_PATH=$(realpath -m "$CALIBRE_LIBRARY_PATH")
                
                if [ ! -d "$CALIBRE_LIBRARY_PATH" ]; then
                    echo "The specified directory does not exist. Please check the path and try again."
                    continue
                fi
                if [ ! -f "$CALIBRE_LIBRARY_PATH/metadata.db" ]; then
                    read -p "Warning: No metadata.db found in the specified directory. Are you sure this is a valid Calibre library? (y/n) " confirm
                    if [[ $confirm != [yY] ]]; then
                        continue
                    fi
                fi
                break
            fi
        done
        
        echo "Using Calibre library at: $CALIBRE_LIBRARY_PATH"
        
        echo "Calibre-Web initial setup:"
        echo "1. Open http://localhost:8083 in your browser"
        echo "2. Log in with the default credentials (admin/admin123)"
        echo "3. Go to the admin page and set 'Location of Calibre database' to: $CALIBRE_LIBRARY_PATH"
        echo "4. Configure any other settings as needed"
        echo "5. Once done, press any key to continue"
        
        cps &
        CPS_PID=$!
        read -n 1 -s
        kill $CPS_PID
    else
        echo "Calibre-Web is already set up. Skipping initial configuration."
    fi
}

setup_launchd() {
    if [ ! -f "$PLIST_FILE" ]; then
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
        <string>$VENV_DIR/bin/cps</string>
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
    else
        echo "LaunchAgent for Calibre-Web already exists. Skipping creation."
    fi
}

echo "Starting Calibre-Web installation..."
check_dependencies
check_imagemagick
setup_python_environment
install_calibre_web
setup_calibre_web
setup_launchd
echo "✅ Calibre-Web installation and setup completed."
echo "Calibre-Web should now be running. Access it at http://localhost:8083"
echo "Please ensure you've set up the correct Calibre library location in the Calibre-Web settings."
