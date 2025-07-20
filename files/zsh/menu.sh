#!/bin/bash

# RSM CLI Menu
while true; do
    clear
    echo "================================"
    echo "     RSM-MSBA CLI Menu"
    echo "================================"
    echo "1. Start Radiant (radiant)"
    echo "2. Start PGWeb (pgweb)"
    echo "3. Download from Dropbox (iusethis)"
    echo "4. Setup GitHub (github)"
    echo "5. Setup Container (setup)"
    echo "q. Quit"
    echo "================================"
    echo -n "Enter your choice (1-5 or q): "
    read choice

    case $choice in
        1)
            echo "Starting Radiant..."
            /usr/local/bin/radiant
            echo -e "\nPress Enter to return to menu..."
            read
            ;;
        2)
            echo "Starting PGWeb (CTRL+C to stop)..."
            /usr/local/bin/pgweb_binary --listen=8282 --port=8765 --db="rsm-docker"
            ;;
        3)
            echo "Download from Dropbox..."
            /usr/local/bin/iusethis
            ;;
        4)
            echo "Setting up GitHub..."
            /usr/local/bin/github
            ;;
        5)
            echo "Setting up Container..."
            /usr/local/bin/setup
            ;;
        q)
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            sleep 2
            ;;
    esac
done
