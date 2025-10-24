# Student Guide: Connecting to Your Container via VS Code

This guide will help you set up VS Code to connect to your personal development container on the server.

## What You Get

- Your own isolated Docker container with all course software pre-installed
- Access to your home directory (`/home/your-userid`)
- 16GB RAM and 2 CPU cores
- Automatic start/stop (starts when you connect, stops after 24h of inactivity)
- Full VS Code integration (extensions, terminal, debugging, etc.)

## Prerequisites

1. **SSH Access:** You must be able to SSH to the server
2. **VS Code:** Install [Visual Studio Code](https://code.visualstudio.com/)
3. **Remote-SSH Extension:** Install the "Remote - SSH" extension in VS Code
   - Open VS Code
   - Go to Extensions (Ctrl+Shift+X or Cmd+Shift+X)
   - Search for "Remote - SSH"
   - Click Install

## One-Time Setup

### Step 1: Test SSH Connection

First, verify you can SSH to the server from your laptop/desktop:

```bash
ssh your-userid@sc2.yourdomain.edu
```

If this works, you're ready for the next step. If not, contact your instructor.

### Step 2: Generate Your SSH Configuration

While connected to the server via SSH, run:

```bash
/opt/docker-containers/get-ssh-config.sh
```

This will output a configuration block that looks like this:

```
Host rsm-msba
    HostName sc2.yourdomain.edu
    User your-userid
    ProxyCommand ssh %r@%h "/opt/docker-containers/start-container.sh && nc localhost 20XXX"
    ServerAliveInterval 60
    ServerAliveCountMax 3
    StrictHostKeyChecking accept-new
```

**Copy this entire block** (select and copy from your terminal).

### Step 3: Add Configuration to Your Local SSH Config

**On your laptop/desktop** (NOT on the server), edit your SSH config file:

**Windows:**
- Location: `C:\Users\YourName\.ssh\config`
- Create the `.ssh` folder if it doesn't exist
- Create the `config` file (no extension) if it doesn't exist

**Mac/Linux:**
- Location: `~/.ssh/config`
- Create if it doesn't exist: `touch ~/.ssh/config`

Open the file in a text editor and paste the configuration block you copied in Step 2 at the end of the file.

Save and close the file.

### Step 4: Connect via VS Code

1. Open VS Code
2. Click the green button in the bottom-left corner (looks like "><")
3. Select **"Connect to Host..."**
4. Choose **"rsm-msba"** from the list
5. Wait for the connection to establish

**First connection may take 30-60 seconds** as your container is being created.

### Step 5: Verify Connection

Once connected, you should see:
- Green badge in bottom-left showing "SSH: rsm-msba"
- Your home directory files in the Explorer panel
- Terminal access to your container

Open a terminal in VS Code (Terminal → New Terminal) and verify:

```bash
whoami
# Should show: jovyan

pwd
# Should show: /home/jovyan

ls
# Should show your home directory files
```

## Daily Usage

### Connecting

Just repeat Step 4 above:
1. Open VS Code
2. Click green button (bottom-left)
3. "Connect to Host" → "rsm-msba"

Your container will start automatically if it's not already running.

### Disconnecting

Simply close VS Code or click the green button and select "Close Remote Connection".

Your work is automatically saved to your home directory and persists across sessions.

### Container Lifecycle

- **Auto-start:** Container starts automatically when you connect
- **Stays running:** Container remains active while you're working
- **Auto-stop:** After 24 hours of no activity, container stops to free resources
- **Your data is safe:** All work in `/home/jovyan` (your home directory) is preserved

## Using GPU Containers

If your course requires GPU access, use the GPU container instead:

1. When running the config generation script, add `--gpu`:
   ```bash
   /opt/docker-containers/get-ssh-config.sh --gpu
   ```

2. This creates a config with `Host rsm-msba-gpu`

3. Connect to "rsm-msba-gpu" in VS Code

## Troubleshooting

### Connection Takes Very Long

**First connection:** May take 30-60 seconds to create your container. Be patient.

**Subsequent connections:** Should be faster (5-10 seconds).

**After idle timeout:** May take 10-15 seconds to restart your container.

### "Could not establish connection"

1. **Verify SSH works:**
   ```bash
   ssh your-userid@sc2.yourdomain.edu
   ```

2. **Check your SSH config:** Make sure you pasted it correctly in `~/.ssh/config`

3. **Try manual connection:**
   ```bash
   ssh rsm-msba
   ```
   If this fails, check the error message.

4. **Contact support** if the issue persists

### "Permission denied"

- Make sure your SSH keys are set up correctly
- Verify you can SSH to the server normally
- Contact your instructor for account issues

### "Port already in use"

This shouldn't happen (ports are assigned uniquely). Contact support if you see this.

### Container Seems Slow

- Check if you're running resource-intensive tasks
- Close unused applications in the container
- Your container has 16GB RAM and 2 CPUs - if you need more, contact your instructor

### Lost Work / Files Missing

Your home directory (`/home/jovyan`) is **permanently mounted** from the server. Your files should never disappear.

If files are missing:
1. Check you're in the right directory: `pwd`
2. List files: `ls -la`
3. Contact support immediately if files are actually missing

### Container Won't Start

1. Wait 1-2 minutes and try again
2. Check with other students - if many have issues, it may be a server problem
3. Contact support

## Best Practices

### Save Your Work

- Files in `/home/jovyan` are automatically saved to the server
- Use Git for version control
- For important work, push to GitHub regularly

### Resource Usage

- Close browser tabs and heavy applications when not in use
- Don't run infinite loops or background processes
- Stop long-running tasks when stepping away

### Python Environments

If you're using Python virtual environments or conda:

```bash
# Your environments persist in your home directory
# Example with venv:
python3 -m venv ~/myenv
source ~/myenv/bin/activate

# Example with conda:
conda create -n myenv python=3.11
conda activate myenv
```

### Installing Software

You can install Python packages, R packages, etc., in your container:

```bash
# Python
pip install package-name

# R (in R console)
install.packages("package-name")
```

**Note:** Installations persist in your home directory but not in the container itself. If you install system packages (via apt), they'll be lost when the container restarts. For permanent system changes, contact your instructor.

## Tips & Tricks

### Multiple VS Code Windows

You can open multiple VS Code windows to the same container - they all connect to the same instance.

### Extensions

Install VS Code extensions while connected - they'll be installed in the container and persist.

Recommended extensions:
- Python
- Jupyter
- R (if using R)
- GitLens

### Terminal

Open multiple terminals: Terminal → New Terminal

Use split terminals: Click the split icon in the terminal panel

### File Transfer

**Small files:** Use VS Code's file explorer (drag & drop works!)

**Large files:** Use `scp` from your laptop:
```bash
scp large-file.zip your-userid@sc2.yourdomain.edu:~/
```

### Jupyter Notebooks

Your container has Jupyter installed. You can:
1. Use VS Code's built-in Jupyter support (recommended)
2. Or start Jupyter manually:
   ```bash
   jupyter notebook --no-browser --port=8888
   ```
   Then use VS Code's port forwarding to access it

## Getting Help

### Common Issues

Check this guide first - most issues are covered above.

### Support Channels

1. **Check with classmates:** They might have faced the same issue
2. **Course forum/Slack:** Post your question
3. **Office hours:** Bring specific error messages
4. **Email instructor:** For account or access issues

### What to Include When Asking for Help

- Your userid
- What you were trying to do
- Exact error message (screenshot or copy-paste)
- What you've already tried

## FAQ

**Q: Can I use multiple containers?**
A: You have one regular container and optionally one GPU container. You can't run both simultaneously.

**Q: Can I share files with other students?**
A: Not directly through containers. Use shared directories on the server or Git repositories.

**Q: What happens if I exceed 16GB RAM?**
A: Your container may be killed/restarted. Save your work frequently and use resource-efficient code.

**Q: Can I access the container from multiple devices?**
A: Yes! Set up the SSH config on each device (laptop, desktop, etc.) and you can connect from any of them (but not simultaneously).

**Q: What software is pre-installed?**
A: Check your course documentation or run `dpkg -l` (Ubuntu packages) or `pip list` (Python packages) in your container.

**Q: Can I request additional software?**
A: Yes, contact your instructor. They can update the Docker image for everyone.

**Q: Does the 24-hour timeout mean I lose my work?**
A: No! Only the container stops. All your files in `/home/jovyan` are safe and persist. Just reconnect to restart the container.

---

**Welcome to your development environment! Happy coding!**
