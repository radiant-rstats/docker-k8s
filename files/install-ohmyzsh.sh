#!/bin/bash
set -e

export ZSH="/home/${NB_USER}/.rsm-msba/zsh/.oh-my-zsh"

# oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-completions /home/${NB_USER}/.rsm-msba/zsh/.oh-my-zsh/custom/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-autosuggestions /home/${NB_USER}/.rsm-msba/zsh/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /home/${NB_USER}/.rsm-msba/zsh/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone https://github.com/supercrabtree/k /home/${NB_USER}/.rsm-msba/zsh/.oh-my-zsh/custom/plugins/k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /home/${NB_USER}/.rsm-msba/zsh/.oh-my-zsh/custom/themes/powerlevel10k
cp -R /home/${NB_USER}/.rsm-msba/zsh/.oh-my-zsh /etc/skel/.oh-my-zsh
rm -rf /home/${NB_USER}/.rsm-msba/ /home/${NB_USER}/bin/ /home/${NB_USER}/work/
