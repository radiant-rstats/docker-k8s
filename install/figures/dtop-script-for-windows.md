DESKTOP_PATH=$(powershell.exe '[Environment]::GetFolderPath("Desktop")' | tr -d '\r')
DESKTOP_WSL=$(wslpath "$DESKTOP_PATH")
echo "wt.exe wsl.exe ~/git/docker-k8s/launch-rsm-msba-k8s-intel.sh -v ~" > "$DESKTOP_WSL/launch-rsm-msba.bat"
chmod 755 "$DESKTOP_WSL/launch-rsm-msba.bat"
ln -s "$DESKTOP_WSL" ~/Desktop 2>/dev/null
"$DESKTOP_WSL/launch-rsm-msba.bat"
