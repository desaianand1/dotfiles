#!/bin/bash

# Install Apps from the Mac App Store
# opens app store windows in default browser; doesn't directly install the apps
echo "🌐Opening browser tabs for pending App Store apps..."
echo "✍️Complete the install manually!"
xargs open < .app-store-list
