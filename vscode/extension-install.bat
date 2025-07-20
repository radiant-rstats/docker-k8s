Invoke-WebRequest -Uri https://raw.githubusercontent.com/radiant-rstats/docker-k8s/main/vscode/extensions.txt -OutFile extensions.txt;
cat extensions.txt |% { code --install-extension $_ --force};
del extensions.txt;
