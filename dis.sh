#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    printf "${!1}%s${NC}\n" "$2"
}

# Function to check if script is run as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_color "RED" "Please run this script as root or using sudo."
        exit 1
    fi
}

download_discord_file() {
    local url="https://discord.com/api/download?platform=linux&format=tar.gz"
    local output_file="discord.tar.gz"

    if command -v curl > /dev/null; then
        print_color "RED" "Using curl to download the file from https://discord.com..."
        curl -L -o "$output_file" "$url"
    elif command -v wget > /dev/null; then
        print_color "RED"  "Using wget to download the file from https://discord.com..."
        wget -O "$output_file" "$url"
    else
        print_color "RED"  "Error: Neither curl nor wget is installed."
        return 1
    fi

    print_color "GREEN" "Download completed: $output_file"
    DISCORD_ARCHIVE="$output_file"
}

get_discord_archive() {
    print_color "YELLOW" "Would you like to provide a path to the Discord archive or download it?"
    PS3="Please select an option (1-2): "
    options=("Provide a file path" "Download Discord.tar.gz")
    select opt in "${options[@]}"
    do
        case "$opt" in
            "Provide a file path")
                while true; do
                    if [ -n "$1" ] && [ -f "$1" ]; then
                        DISCORD_ARCHIVE="$1"
                        break
                    else
                        read -p "Enter the path to the Discord archive (e.g., /path/to/discord.tar.gz): " DISCORD_ARCHIVE
                        if [ -f "$DISCORD_ARCHIVE" ]; then
                            break 2
                        else
                            print_color "YELLOW" "File not found. Please try again."
                        fi
                    fi
                done
            ;;
            "Download Discord.tar.gz")
                download_discord_file
                break 2
            ;;

            *)
                print_color "RED" "Invalid option $REPLY"
            ;;
        esac
    done
}

install_discord() {
    print_color "GREEN" "Starting Discord installation..."   
    # Create temporary and installation directories
    print_color "YELLOW" "Creating directories..."
    mkdir -p /opt/discord
    mkdir -p temp_discord
    # Extract Discord to temporary directory
    print_color "YELLOW" "Extracting Discord..."
    tar -xzvf "$DISCORD_ARCHIVE" -C temp_discord || { print_color "RED" "Failed to extract Discord archive."; exit 1; }
    # Move contents to installation directory
    print_color "YELLOW" "Moving files to installation directory..."
    mv temp_discord/Discord/* /opt/discord/ || { print_color "RED" "Failed to move Discord files."; rm -rf temp_discord && exit 1; }    
    # Clean up temporary directory
    rm -rf temp_discord
    # Create symlink
    print_color "YELLOW" "Creating symlink..."
    ln -sf /opt/discord/Discord /usr/bin/discord || { print_color "RED" "Failed to create symlink."; exit 1; }
    # Create desktop entry
    print_color "YELLOW" "Creating desktop entry..."
    cat << EOF > /usr/share/applications/discord.desktop
[Desktop Entry]
Name=Discord
StartupWMClass=discord
Comment=All-in-one voice and text chat for gamers that's free, secure, and works on both your desktop and phone.
GenericName=Internet Messenger
Exec=/opt/discord/Discord
Icon=/opt/discord/discord.png
Type=Application
Categories=Network;InstantMessaging;
Path=/usr/bin
EOF

    print_color "GREEN" "Discord has been installed successfully!"
}

uninstall_discord() {
    print_color "YELLOW" "Uninstalling Discord..."
    # Remove the Discord directory
    rm -rf /opt/discord
    # Remove the symlink
    rm -f /usr/bin/discord
    # Remove the desktop entry
    rm -f /usr/share/applications/discord.desktop
    print_color "GREEN" "Discord has been uninstalled successfully!"
}

update_discord() {
    print_color "YELLOW" "Updating Discord..."    
    # Uninstall the existing version
    uninstall_discord    
    # Install the new version
    install_discord    
    print_color "GREEN" "Discord has been updated successfully!"
}

main() {
    check_root

    print_color "GREEN" "Welcome to the Discord Installer Script! (DIS)"
    print_color "YELLOW" "This script will help you install, uninstall, or update Discord."

    PS3="Please select an option (1-4): "
    options=("Install Discord" "Uninstall Discord" "Update Discord" "Exit")
    select opt in "${options[@]}"
    do
        case $opt in
            "Install Discord")
                get_discord_archive "$2"
                install_discord
                break
                ;;
            "Uninstall Discord")
                uninstall_discord
                break
                ;;
            "Update Discord")
                get_discord_archive "$2"
                update_discord
                break
                ;;
            "Exit")
                print_color "GREEN" "Thank you for using Discord installer Script. Goodbye!"
                exit 0
                ;;
            *) 
                print_color "RED" "Invalid option $REPLY"
                ;;
        esac
    done
}
# Run the main function
main "$@"