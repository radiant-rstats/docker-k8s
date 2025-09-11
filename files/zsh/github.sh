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
git config --global init.defaultBranch main

user_name=$(git config --global user.name)

echo -e "\nGit configuration set:"
echo "Name: $user_name"
echo "Email: $(git config --global user.email)"
echo "Rebase: $(git config --global pull.rebase)"

# SSH key setup
echo -e "\nNow let's set up your SSH key for GitHub."

# Create .ssh directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Generate SSH key
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -C "rsm-msba-github" -N ""
chmod 600 ~/.ssh/id_ed25519

# Add key to github
echo -e "\nCopy your public key into the clipboard:\n"
cat ~/.ssh/id_ed25519.pub

url="https://github.com/settings/ssh/new"
echo -e "\nOpen the URL below in your default browser."
echo -e "\n$url"

echo -e "\nGitHub instructions:"
echo "   - Provide a 'Title' (e.g., 'rsm-msba laptop key')"
echo "   - 'Key type' should be 'Authentication key'"
echo "   - Paste the key into the 'Key' field"
echo -e "   - Click the 'Add SSH key' button\n"

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
echo -e "ssh -T git@github.com\n"

ssh_output=$(ssh -T git@github.com 2>&1)
if echo "$ssh_output" | grep -q "successfully authenticated"; then
  echo "✅ SSH connection to GitHub was successful! You are ready to use GitHub via SSH."
  echo -e "\nVisit: https://github.com/$user_name?tab=repositories to see your repositories."
  echo -e "\nIf you see a 404 page on GitHub you may have used an incorrect username."
  echo -e "Your GitHub username for the Rady MSBA program should be 'rsm-aaa111'"
  echo -e "where 'aaa111' is replaced by the first part of your @ucsd.edu email address\n"
else
  echo -e "❌ SSH connection to GitHub failed. Please connect with your instructor or TA.\n"
fi

echo "Press any key to continue"
read continue
