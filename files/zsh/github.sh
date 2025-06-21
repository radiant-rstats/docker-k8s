#!/usr/bin/env bash

## script to run from a terminal in the docker container
## to set up Git configuration and GitHub SSH access
echo "Let's set up your Git configuration and GitHub SSH access."
echo

# Git global config
read -p "Enter your @ucsd.edu email address for Git commits: " git_email

git config --global user.email "$git_email"
git config --global user.name "rsm-${git_email%@ucsd.edu}"
git config --global pull.rebase false

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
url="https://github.com/settings/ssh/new"
echo -e "\nOpen $url"

# Try to open in browser (works on macOS and some Linux/WSL2 setups)
if command -v xdg-open > /dev/null; then
  xdg-open "$url"
elif command -v open > /dev/null; then
  open "$url"
elif command -v start > /dev/null; then
  start "$url"
else
  echo "Please open the above URL in your default browser."
fi

echo -e "\nCopy your public key to GitHub:\n"
cat ~/.ssh/id_ed25519.pub

echo -e "\nInstructions:"
echo "On GitHub:"
echo "   - Give your key a descriptive title (e.g., 'rsm-msba-laptop')"
echo "   - Paste the key into the 'Key' field"
echo "   - Click 'Add SSH key'"
echo

while true; do
  read -p "Have you copied the SSH key to GitHub? (y/n): " yn
  case $yn in
    [Yy]* ) break;;
    [Nn]* ) echo "Please copy the SSH key to GitHub before continuing."; exit 1;;
    * ) echo "Please answer y or n.";;
  esac
 done

# Test SSH connection
echo -e "\nTo test your SSH connection we wil run:"
echo "ssh -T git@github.com"
echo

ssh_output=$(ssh -T git@github.com 2>&1)
if echo "$ssh_output" | grep -q "successfully authenticated"; then
  echo "✅ SSH connection to GitHub was successful! You are ready to use GitHub via SSH."
else
  echo "❌ SSH connection to GitHub failed. Please connect with your instructor or TA."
fi