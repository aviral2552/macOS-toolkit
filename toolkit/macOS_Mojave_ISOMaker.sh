#!/bin/sh
# macOS Mojave ISO creator
#
# You can visit my GitHub for other useful utilities
# GitHub: https://github.com/thelamehacker
#
# License: GNU General Public License v3.0
# Release date: 28 September 2018
# -----------------------------------------------------------------------------
echo
echo "Welcome to macOS Mojave ISO creator tool"
echo

checkAdmin() {

    # Checking if the user has administrative rights
    if groups $USER | grep -q -w admin
        then
            makeISO
        else
            echo
            echo "User '$USER' doesn't seem to be an administrator! Please run this script with administrator rights."
            echo
    fi

}

makeISO() {
    # Creating a temporary disk image of 6 GB space in /tmp/ and mounting it
    # File system has been set to HFS+ Journaled for maximum compatibility.
    # This can be set to APFS on newer systems, or you can convert your file system to APFS post installation.

    echo
    echo "Creating and mounting a disk image..."
    echo

    hdiutil create -o /tmp/Mojave.cdr -size 6g -layout SPUD -fs HFS+J
    hdiutil attach /tmp/Mojave.cdr.dmg -noverify -mountpoint /Volumes/install_build

    echo
    echo "Copying downloaded files to our disk image and moving it to the Desktop..."
    echo

    # This is where we need those pesky administrative rights. 

    sudo /Applications/Install\ macOS\ Mojave.app/Contents/Resources/createinstallmedia --volume /Volumes/install_build
    mv /tmp/Mojave.cdr.dmg ~/Desktop/InstallSystem.dmg
    hdiutil detach /Volumes/Install\ macOS\ Mojave

    echo
    echo "Converting the disk image to an ISO file and cleaning up..."
    echo

    hdiutil convert ~/Desktop/InstallSystem.dmg -format UDTO -o ~/Desktop/Mojave.iso
    mv ~/Desktop/Mojave.cdr.iso ~/Desktop/Mojave.iso

    echo
    echo "All done now. You should have Mojave.iso on $USER's Desktop now."
    echo
}

# Prompting user to download the installer from app store if not done already
while true; do
    read -p "Have you downloaded the macOS Mojave installer from app store? " yn
    case $yn in
        [Yy]* ) checkAdmin; break;;
        [Nn]* ) echo "Please download macOS Mojave installer from app store and re-run this script. Goodbye."; break;;
        * ) echo "Please answer yes or no.";;
    esac
done
