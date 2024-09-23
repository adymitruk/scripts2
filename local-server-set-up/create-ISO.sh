#!/bin/bash

# Initialize debug flag
CREATE_ISO_CACHE_DIR="$HOME/.cache/create-iso"
UNIQUE_TITLES_CACHE_FILE="$CREATE_ISO_CACHE_DIR/unique_titles.txt"
DEBUG=0
RELEASES_URL="releases.ubuntu.com"
RELEASE_LINK_REGEX='<a href="\K[^/"]+(?=/")'    
# regex to extract the release page links is of the form <img src="/icons/folder.gif" alt="[DIR]"> <a href="noble/">noble/</a>                  2024-08-29 16:14    -   Ubuntu 24.04.1 LTS (Noble Numbat)

if [[ "$1" == "-d" || "$1" == "--debug" ]]; then DEBUG=1; fi
debug_echo() { if [[ $DEBUG -eq 1 ]]; then echo "DEBUG: $1"; fi }
not_debug_echo() { if [[ $DEBUG -eq 0 ]]; then echo "$@"; fi }

# function to download paage of ubuntu releases
download_ubuntu_releases() { wget -q -O- "$RELEASES_URL"; }


# store a lookup table of unique release titles and their links
declare -A unique_titles
declare -A unique_isos
refresh_titles="true"
# create cache directory
debug_echo "Current user: $USER"
debug_echo "Current home directory: $HOME"

debug_echo "Creating cache directory: $CREATE_ISO_CACHE_DIR"
mkdir -pv "$CREATE_ISO_CACHE_DIR"
#check that the cache directory is writable
if [[ ! -w "$CREATE_ISO_CACHE_DIR" ]]; then
    echo "Cache directory is not writable. Please check permissions."
    exit 1
fi  

# check if cache of unique titles exists
if [[  -f "$UNIQUE_TITLES_CACHE_FILE" ]]; then
    debug_echo "Cache exists"
    # check if cache is older than 30 seconds 
    if [[ $(( $(date +%s) - $(stat -c %Y "$UNIQUE_TITLES_CACHE_FILE") )) -gt 1800 ]]; then
        debug_echo "Cache is older than 30 seconds"
    else
        debug_echo "Cache is newer than 30 seconds"
        refresh_titles="false"
    fi
fi

if [[ "$refresh_titles" == "true" ]]; then
    not_debug_echo -n "Getting ubuntu releases"
    debug_echo "Downloading Ubuntu releases page..."
    releases_page=$(download_ubuntu_releases)

    debug_echo "Releases page downloaded here is the content:"
    debug_echo "$releases_page"

    # extract the links to the pages of each ubuntu release
    release_links=$(echo "$releases_page" | grep -oP '<a href="\K[^/"]+(?=/")')

    debug_echo "Release links:"
    debug_echo "$release_links"

    debug_echo "Available Ubuntu Releases:"
    for link in $release_links; do debug_echo "$link"; done
    # go to each release page and show the title
    # it's stored like this <h1 class="u-no-margin--bottom">Ubuntu 23.10.1 (Mantic Minotaur)</h1>
    # some pages may not be found. They will have <h1>Not Found</h1>    
    for release in $release_links; do
        not_debug_echo -n "."
        link="$RELEASES_URL/$release"
        debug_echo "URL: $link"
        release_page=$(wget -q -O- "$link")
        h1_title=$(echo "$release_page" | grep -oP '<h1 class="u-no-margin--bottom">\K[^<]+')
        if [[ "$h1_title" == "" ]]; then
            debug_echo "Page not found: $link"
            continue
        fi
        checksum_link="$link/SHA256SUMS"
        # Find the iso lines
        # example line: <tr><td valign="top"><img src="../cdicons/iso.png" alt="[   ]" width="22" height="22"></td><td><a href="ubuntu-24.04.1-live-server-amd64.iso">ubuntu-24.04.1-live-server-amd64.iso</a></td><td align="right">2024-08-27 15:40  </td><td align="right">2.6G</td><td>Server install image for 64-bit PC (AMD64) computers (standard download)</td></tr>
        iso_lines=$(echo "$release_page" | grep -oP '<tr>.*?cdicons.*?href="ubuntu.*?iso".*?</tr>')
        debug_echo "ISO lines:"
        debug_echo "$iso_lines" 
        #get checksums for each iso file
        iso_checksums=$(wget -q -O- "$checksum_link")
        
        while IFS= read -r iso_line; do
            # Extract individual components
            iso_name=$(echo "$iso_line" | grep -oP '(?<=<a href=")[^"]+(?=")')
            iso_date=$(echo "$iso_line" | grep -oP '(?<=<td align="right">)[^<]+(?=</td>)' | head -n 1 | xargs)
            iso_size=$(echo "$iso_line" | grep -oP '(?<=<td align="right">)[^<]+(?=</td>)' | tail -n 1)
            iso_description=$(echo "$iso_line" | grep -oP '(?<=<td>)[^<]+(?=</td></tr>$)')
            iso_checksum=$(echo "$iso_checksums" | grep "$iso_name" | awk '{print $1}')
            iso_link="$link/$iso_name"
            # Debug echo the ISO info
            debug_echo "iso line: $iso_line"
            debug_echo "ISO: $iso_name"
            debug_echo "Date: $iso_date"
            debug_echo "Size: $iso_size"
            debug_echo "Description: $iso_description"
            debug_echo "Checksum: $iso_checksum"
            debug_echo "Link: $iso_link"
            unique_isos["$iso_name $iso_size $iso_date $h1_title, $iso_description"]="$iso_name;$iso_date;$iso_size;$iso_description;$iso_checksum;$iso_link"
        done <<< "$iso_lines"
        
        debug_echo "Title: $h1_title"
        unique_titles["$h1_title"]="$link"
    done
    # write cache
    # delete cache if it exists
    if [[ -f "$UNIQUE_TITLES_CACHE_FILE" ]]; then
        rm "$UNIQUE_TITLES_CACHE_FILE"
    fi  
    for iso in "${!unique_isos[@]}"; do
        echo -e "$iso\t${unique_isos[$iso]}" >> "$UNIQUE_TITLES_CACHE_FILE"
    done
    not_debug_echo
fi

# read the cache file into a variable
cache_content=$(cat "$UNIQUE_TITLES_CACHE_FILE")
# sort the cache content
sorted_cache_content=$(echo "$cache_content" | sort)
debug_echo "Sorted cache content:"
debug_echo "$sorted_cache_content"


# read cache
while IFS=$'\t' read -r iso info; do
    debug_echo "ISO: $iso"
    debug_echo "Info: $info"    
    unique_isos["$iso"]="$info"
done <<< "$sorted_cache_content"

echo "Available Ubuntu Releases:"
PS3="Select an Ubuntu release (enter the number): "
IFS=$'\n'
select title in $(echo "$sorted_cache_content" | cut -f1); do
    if [[ -n "$title" ]]; then
        IFS=';' read -r selected_iso selected_date selected_size selected_description selected_checksum selected_link <<< "${unique_isos[$title]}"
        break
    else
        echo "Invalid selection. Please try again."
    fi
done
unset IFS

echo "You selected: $title"
echo "ISO: $selected_iso"
echo "ISO link: $selected_link"
echo "Date: $selected_date"
echo "Size: $selected_size"
echo "Description: $selected_description"
echo "Checksum: $selected_checksum"

while true; do
    #check if file for iso already downloaded to current directory
    if [[ -f "$selected_iso" ]]; then
        echo "ISO downloaded"
    else
        echo "Downloading ISO..."
        wget -O "$selected_iso" "$selected_link"
    fi

    #check if iso is downloaded correctly by checksum
    echo "Checking ISO checksum..."
    calculated_checksum=$(sha256sum "$selected_iso" | awk '{print $1}')
    if [[ $calculated_checksum != "$selected_checksum" ]]; then
        echo "ISO checksum does not match"
        echo "ISO name: $selected_iso"
        echo "Full path: $(realpath "$selected_iso")"
        echo "Calculated checksum: $calculated_checksum"
        echo "Expected checksum:   $selected_checksum"
        read -p "Do you want to download the ISO again? (y/n): " answer
        if [[ $answer == "y" ]]; then
            rm "$selected_iso"
            echo "Downloading ISO again"
            continue
        else
            echo "Keeping the current ISO file despite checksum mismatch"
            break
        fi
    else
        echo "ISO checksum matches"
        break
    fi
done

#alter the iso so that it can be installed without a keyboard or mouse by specifying the preseed file
#the preseed file is a text file that contains the answers to all the questions that the installer would ask


# check if xorriso is installed
if ! command -v xorriso &> /dev/null; then
    echo "xorriso could not be found. Do you want to install it? (y/n): "
    read answer
    if [[ $answer == "y" ]]; then
        sudo apt-get install -y xorriso
    else
        echo "xorriso is required to create the ISO. Exiting."
        exit 1
    fi
fi

preseed_file="preseed.cfg"



echo "d-i debian-installer/locale string en_US" > "$preseed_file"
echo "d-i keyboard-configuration/layoutcode string us" >> "$preseed_file"
echo "d-i netcfg/choose_interface select auto" >> "$preseed_file"
echo "d-i netcfg/dhcp_timeout string 60" >> "$preseed_file"
echo "d-i clock-setup/utc boolean true" >> "$preseed_file"
echo "d-i clock-setup/ntp boolean true" >> "$preseed_file"
echo "d-i preseed/late_command string \
    in-target apt-get update; \
    in-target apt-get install -y openssh-server; \
    in-target systemctl enable ssh" >> "$preseed_file"
echo "d-i passwd/root-password password your_root_password" >> "$preseed_file"
echo "d-i passwd/root-password-again password your_root_password" >> "$preseed_file"


# Function to create a new ISO with the preseed file
create_new_iso_with_preseed() {
    local source_iso="$1"
    local preseed_file="$2"
    local output_iso="$3"
    local temp_dir=$(mktemp -d)

    echo "Extracting ISO contents..."
    xorriso -osirrox on -indev "$source_iso" -extract / "$temp_dir"

    echo "Extracted ISO contents:"
    ls -R "$temp_dir"

    echo "Adding preseed file..."
    cp "$preseed_file" "$temp_dir/preseed.cfg"
    # Also copy to potential alternative locations
    mkdir -p "$temp_dir/preseed"
    cp "$preseed_file" "$temp_dir/preseed/ubuntu.seed"
    cp "$preseed_file" "$temp_dir/preseed.cfg"

    echo "Updating boot configurations..."

    # Check for grub directory
    if [ -f "$temp_dir/boot/grub/grub.cfg" ]; then
        sed -i 's/timeout=30/timeout=1/' "$temp_dir/boot/grub/grub.cfg"
        sed -i '/menuentry "Try or Install Ubuntu Server" {/,/}/c\menuentry "Automatic Install" {\n    set gfxpayload=keep\n    linux   /casper/vmlinuz file=/cdrom/preseed/ubuntu.seed auto=true priority=critical preseed/file=/cdrom/preseed.cfg quiet ---\n    initrd  /casper/initrd\n}' "$temp_dir/boot/grub/grub.cfg"
    else
        echo "Warning: grub.cfg not found"
    fi

    # Check for isolinux directory (might not exist in newer versions)
    if [ -d "$temp_dir/isolinux" ]; then
        if [ -f "$temp_dir/isolinux/isolinux.cfg" ]; then
            sed -i 's/timeout 0/timeout 1/' "$temp_dir/isolinux/isolinux.cfg"
        fi
        
        if [ -f "$temp_dir/isolinux/txt.cfg" ]; then
            sed -i 's/^default.*/default auto/' "$temp_dir/isolinux/txt.cfg"
            echo "label auto" >> "$temp_dir/isolinux/txt.cfg"
            echo "  menu label ^Automatic Install" >> "$temp_dir/isolinux/txt.cfg"
            echo "  kernel /casper/vmlinuz" >> "$temp_dir/isolinux/txt.cfg"
            echo "  append file=/cdrom/preseed/ubuntu.seed auto=true priority=critical preseed/file=/cdrom/preseed.cfg quiet ---" >> "$temp_dir/isolinux/txt.cfg"
        fi
    else
        echo "Note: isolinux directory not found (this is normal for newer Ubuntu versions)"
    fi

    # create the new iso in the current directory
    echo "Creating new ISO..."
    echo "current directory: $(pwd)"

    # Check for the existence of efi.img
    efi_img=$(find "$temp_dir" -name "efi.img")

    if [ -n "$efi_img" ]; then
        efi_img_path=$(realpath --relative-to="$temp_dir" "$efi_img")
        xorriso -as mkisofs -r \
            -V "Ubuntu-Server-Custom" \
            -o "$output_iso" \
            -J -l \
            -e "$efi_img_path" -no-emul-boot \
            -isohybrid-gpt-basdat \
            "$temp_dir"
    else
        echo "Warning: efi.img not found. Creating ISO without EFI boot support."
        xorriso -as mkisofs -r \
            -V "Ubuntu-Server-Custom" \
            -o "$output_iso" \
            -J -l \
            "$temp_dir"
    fi

    echo "Cleaning up..."
    sudo rm -rf "$temp_dir"
}

# Create the new ISO with the preseed file
output_iso="${selected_iso%.iso}-preseeded.iso"
create_new_iso_with_preseed "$selected_iso" "$preseed_file" "$output_iso"

echo "New preseeded ISO created: $output_iso"
