#!/usr/bin/env bash

## script to run from a terminal in the docker container
## to remove locally install R and python packages

#!/bin/bash

echo "Let's set up your Git configuration and GitHub SSH access."
echo

# Git global config
read -p "Enter your full name for Git commits: " git_name
read -p "Enter your email address for Git commits: " git_email

git config --global user.name "$git_name"
git config --global user.email "$git_email"

echo -e "\nGit configuration set:"
echo "Name: $(git config --global user.name)"
echo "Email: $(git config --global user.email)"

# SSH key setup
echo -e "\nNow let's set up your SSH key for GitHub."

# Create .ssh directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Generate SSH key
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -C "rsm-msba-github" -N ""
chmod 600 ~/.ssh/id_ed25519

# Add key to github
echo -e "\nOpen https://github.com/settings/ssh/new"
echo -e "\nCopy your public key to GitHub:\n"
cat ~/.ssh/id_ed25519.pub

echo -e "\nInstructions:"
echo "On GitHub:"
echo "   - Give your key a descriptive title"
echo "   - Paste the key into the 'Key' field"
echo "   - Click 'Add SSH key'"

# Test SSH connection
echo -e "\nTo test your SSH connection, run:"
echo "ssh -T git@github.com"