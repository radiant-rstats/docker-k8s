#!/bin/bash

# Interactive script to call usethis with user-provided arguments

echo "=== Interactive usethis downloader ==="
echo

# Get the name of the file/folder
read -p "Enter the name for the extracted file or folder: " name
while [[ -z "$name" ]]; do
    echo "Name cannot be empty!"
    read -p "Enter the name for the extracted file or folder: " name
done

# Get the destination folder (with default)
current_dir=$(pwd)
read -p "Enter destination folder (default: $current_dir): " dest
if [[ -z "$dest" ]]; then
    dest="$current_dir"
fi

# Expand tilde to home directory and check if destination exists
dest=$(eval echo "$dest")
if [[ ! -d "$dest" ]]; then
    echo "Error: Destination folder '$dest' does not exist!"
    echo "Please create the folder first or choose an existing directory."
    exit 1
fi

# Get the URL
read -p "Enter the URL of the ZIP file to download: " url
while [[ -z "$url" ]]; do
    echo "URL cannot be empty!"
    read -p "Enter the URL of the ZIP file to download: " url
done

# Strip quotes from URL if provided
url=$(echo "$url" | sed 's/^["'\'']*//; s/["'\'']*$//')

echo
echo "=== Summary ==="
echo "Name: $name"
echo "Destination: $dest"
echo "URL: $url"
echo "COMMAND: usethis --name \"$name\" --dest \"$dest\" --url \"$url\""

# Confirm before proceeding
read -p "Proceed with download? (y/N): " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
    echo
    echo "Calling usethis..."

    # Get the directory where this script is located to find usethis
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    usethis_path="$script_dir/usethis"

    # Check if usethis exists in the same directory
    if [[ -f "$usethis_path" ]]; then
        if "$usethis_path" --name "$name" --dest "$dest" --url "$url"; then
            echo "Download completed successfully!"

            # Determine what to open in VS Code
            extracted_path="$dest/$name"
            if [[ -d "$extracted_path" ]]; then
                echo "Opening VS Code to folder: $extracted_path"
                code "$extracted_path"
            elif [[ -f "$extracted_path" ]]; then
                echo "Opening VS Code to file: $extracted_path"
                code "$extracted_path"
            else
                echo "Warning: Could not find extracted content at $extracted_path"
                echo "Opening VS Code to destination folder: $dest"
                code "$dest"
            fi
        else
            echo "Download failed!"
            exit 1
        fi
    else
        # Try to call usethis assuming it's in PATH or the current directory
        if command -v usethis >/dev/null 2>&1; then
            if usethis --name "$name" --dest "$dest" --url "$url"; then
                echo "Download completed successfully!"

                # Determine what to open in VS Code
                extracted_path="$dest/$name"
                if [[ -d "$extracted_path" ]]; then
                    echo "Opening VS Code to folder: $extracted_path"
                    code "$extracted_path"
                elif [[ -f "$extracted_path" ]]; then
                    echo "Opening VS Code to file: $extracted_path"
                    code "$extracted_path"
                else
                    echo "Warning: Could not find extracted content at $extracted_path"
                    echo "Opening VS Code to destination folder: $dest"
                    code "$dest"
                fi
            else
                echo "Download failed!"
                exit 1
            fi
        elif [[ -f "./usethis" ]]; then
            if ./usethis --name "$name" --dest "$dest" --url "$url"; then
                echo "Download completed successfully!"

                # Determine what to open in VS Code
                extracted_path="$dest/$name"
                if [[ -d "$extracted_path" ]]; then
                    echo "Opening VS Code to folder: $extracted_path"
                    code "$extracted_path"
                elif [[ -f "$extracted_path" ]]; then
                    echo "Opening VS Code to file: $extracted_path"
                    code "$extracted_path"
                else
                    echo "Warning: Could not find extracted content at $extracted_path"
                    echo "Opening VS Code to destination folder: $dest"
                    code "$dest"
                fi
            else
                echo "Download failed!"
                exit 1
            fi
        else
            echo "Error: Could not find usethis script!"
            echo "Please ensure usethis is in the same directory as this script or in your PATH."
            exit 1
        fi
    fi
else
    echo "Download cancelled."
fi
