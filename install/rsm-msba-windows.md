# Contents

- [Contents](#contents)
  - [Installing the RSM-MSBA-K8S-INTEL computing environment on Windows](#installing-the-rsm-msba-k8s-intel-computing-environment-on-windows)
  - [Updating the RSM-MSBA-K8S-INTEL computing environment on Windows](#updating-the-rsm-msba-k8s-intel-computing-environment-on-windows)
  - [Using VS Code](#using-vs-code)
    - [Trouble shooting](#trouble-shooting)
  - [Installing Python and R packages locally](#installing-python-and-r-packages-locally)
    - [Using pip to install python packages](#using-pip-to-install-python-packages)
    - [Removing locally installed packages](#removing-locally-installed-packages)
  - [Committing changes to the computing environment](#committing-changes-to-the-computing-environment)
  - [Cleanup](#cleanup)
  - [Getting help](#getting-help)
  - [Trouble shooting](#trouble-shooting-1)
  - [Optional](#optional)

## Installing the RSM-MSBA-K8S-INTEL computing environment on Windows

Please follow the instructions below to install the rsm-msba-k8s-intel computing environment. It has Python, Radiant, Postgres, Spark and various required packages pre-installed. The computing environment will be consistent across all students and faculty, easy to update, and also easy to remove if desired (i.e., there will *not* be dozens of pieces of software littered all over your computer).


**Step 1**: Install Windows Subsystem for Linux (WSL2) and Ubuntu 24.04

To install WSL2 and Ubuntu 24.04, open **PowerShell as Administrator** (right-click the Start menu, select "Windows PowerShell (Admin)"). Then run the following command to install WSL and Ubuntu 24.04:

```bash
wsl --install -d Ubuntu-24.04
```


Restart your computer if prompted. When the Ubuntu terminal opens for the first time, you will be asked to create a Linux username and password. **Use your UCSD username** (e.g., `aaa111` if your @ucsd.edu email is `aaa111@ucsd.edu`) and choose a password you can remember (you will not see any characters as you type). Using your UCSD username helps ensure your files and settings are consistent across systems and makes it easier for instructors to help if you run into issues.

To check the installed distributions, i.e., versions of Linux, and the WSL version, run:

```bash
wsl -l -v
```

If Ubuntu 24.04 is not set as the default, set it with:

```bash
wsl --setdefault Ubuntu-24.04
```


You can check your username for Windows and Ubuntu by running `whoami` in both a Windows PowerShell and an Ubuntu terminal. If you see `root` as your username in Ubuntu, follow the troubleshooting steps below to set your username correctly. This is important for file access and to avoid issues later.


**Troubleshooting**

> **Important:** If you see `root` as your username in Ubuntu, you will need to reset your username. If the username in Ubuntu is as expected, you can proceed to **Step 2** below.


From an Ubuntu terminal, run the commands below (replace “your-id” with the username you want to use):

```bash
adduser your-id
sudo usermod -aG sudo your-id
```


Now, open PowerShell as a regular user and run the command below (again, replace "your-id" with your chosen username):

```powershell
ubuntu2404 config --default-user your-id
```

**Step 2**: Install Docker Desktop

If all went well in **Step 1**, you can now install Docker Desktop from the page linked below:

<https://docs.docker.com/desktop/setup/install/windows-install/>{target="_blank"}

You will be using VS Code and Windows Terminal extensively in the Rady MSBA program, so make sure to _pin_ both applications to the taskbar for easy access. Next, logout and back into Windows and then start Docker Desktop by clicking on the Whale icon that was added to your desktop (see image below).

![docker](figures/docker-icon.png)

You will know Docker Desktop is running if you see the icon above in your system tray. If the containers shown in the image are moving up and down, Docker hasn't finished starting up yet. Once the Docker Desktop application is running, click on the Docker icon in the system tray and select "Settings".

Next, click on _Resources > WSL INTEGRATION_ and ensure integration with Ubuntu is enabled as in the screenshot below. This step is required so Docker can work with your Ubuntu environment.

<img src="figures/docker-resources-wsl2-integration.png" width="500px">
> Note: This video gives a brief (100 seconds) introduction to what Docker is: <https://www.youtube.com/watch?v=Gjnup-PuquQ>{target="_blank"}


**Step 3**: Open an Ubuntu terminal to complete RSM-MSBA-K8S-INTEL computing environment setup

> **Summary:** In this step, you will update Ubuntu, clone the course repository, and create a shortcut to launch your computing environment. This ensures you always have the latest scripts and documentation.

If you are using Windows Terminal, you can click on the down-caret at the top of the window to start an Ubuntu terminal as shown in the screenshot below. Alternatively, you can click on the Windows Start icon and type "ubuntu" to start an Ubuntu terminal. Copy-and-paste the code below into the Ubuntu terminal and provide your password when prompted.

<img src="figures/start-ubuntu-terminal.png" width="500px">

```bash
cd ~; sudo -- sh -c 'apt -y update; apt -y upgrade; apt -y install xdg-utils wslu zsh ntpdate locale python-is-python3; ntpdate pool.ntp.org'
```

Now Ubuntu should be up to date and ready to accept commands to clone the docker repo with documentation and launch scripts. Again, provide your password if prompted.

```bash
git clone https://github.com/radiant-rstats/docker-k8s.git ~/git/docker-k8s;
```


After running the commands above, you will be able to start the docker container by typing `~/git/docker-k8s/launch-rsm-msba-k8s-intel.sh -v ~` in an Ubuntu terminal. This will launch the RSM-MSBA computing environment.

**Creating a Desktop Shortcut:**

To make it easy to start the environment in the future, you will create a shortcut (`launch-rsm-msba.bat`) on your Windows Desktop. This shortcut can be double-clicked to launch the container without needing to open a terminal and type commands each time.

First, determine your Windows username by running the code below from an Ubuntu terminal:

```bash
USERNAME=$(powershell.exe '$env:UserName'|tr -d '\r');
echo $USERNAME;
```

In contrast to other operating systems, Windows can have the Desktop folder in a number of different locations making it difficult

The code below will try to determine if you have a Desktop folder that is backed up to OneDrive. If not, it will try to use a Desktop folder in your home directory. If that doesn't work either, then it will create a launch scrip in your home directory.

```bash
if [ -d "/mnt/c/Users/$USERNAME/OneDrive/Desktop/" ]; then
  echo "Using Desktop backed up in OneDrive" >&2
  DTOP="/OneDrive/Desktop";
elif [ -d "/mnt/c/Users/$USERNAME/Desktop/" ]; then
  echo "Using Desktop folder in user home directory" >&2
  DTOP="/Desktop";
else
  DTOP="";
fi
if [ -n "$DTOP" ]; then
  echo "wt.exe wsl.exe ~/git/docker-k8s/launch-rsm-msba-k8s-intel.sh -v ~" > /mnt/c/Users/"$USERNAME$DTOP"/launch-rsm-msba.bat;
  chmod 755 /mnt/c/Users/"$USERNAME$DTOP"/launch-rsm-msba.bat;
  cd ~;
  ln -s /mnt/c/Users/"$USERNAME$DTOP"/ ./Desktop;
  /mnt/c/Users/"$USERNAME$DTOP"/launch-rsm-msba.bat;
else
  echo "Unable to determine location of Desktop folder on your system" >&2
  echo "The .bat file has been added to your home directory in Ubuntu" >&2
  echo "wt.exe wsl.exe ~/git/docker-k8s/launch-rsm-msba-k8s-intel.sh -v ~" > /mnt/c/Users/"$USERNAME"/launch-rsm-msba.bat;
  chmod 755 /mnt/c/Users/"$USERNAME"/launch-rsm-msba.bat;
fi
ln -s /mnt/c/Users/"$USERNAME"/Dropbox ./Dropbox;
ln -s /mnt/c/Users/"$USERNAME"/Downloads ./Downloads;
ln -s "/mnt/c/Users/$USERNAME/Google Drive" "./Google Drive";
ln -s /mnt/c/Users/"$USERNAME"/OneDrive ./OneDrive;
ln -s /mnt/c/Users/"$USERNAME" ./win_home;
```


The created and launched script will finalize the installation of the computing environment. The first time you run this script, it will download the latest version of the computing environment, which can take some time depending on your internet speed. Wait for the image to download and follow any prompts. Once the download is complete, you should see a menu as in the screenshot below.

<img src="figures/rsm-launch-menu-wsl2.png" width="500px">


**Troubleshooting**

If you see `Base dir.: /root` as shown in the image below, there was an issue creating a new user at the beginning of Step 3. Go back to the previous **Troubleshooting** section and continue from there. Having the correct username is important for file access and to avoid issues with saving your work.

<img src="figures/ubuntu-root.png" width="500px">


If you do **not** have a file called `launch-rsm-msba.bat` on your Desktop, you can create one by copy-and-pasting the code below into a text file using Notepad. The "pause" line can be removed later if all works well. Open VS Code or Notepad, copy-and-paste the code below into the editor, and save the file as `launch-rsm-msba.bat`. After saving, double-click the file to start the docker container.

```bash
wt.exe wsl.exe ~/git/docker-k8s/launch-rsm-msba-k8s-intel.sh -v ~
pause
```


**Step 4**: Check that you can launch Radiant

You will know that the installation was successful if you can start Radiant. In the launch menu, press `2` (+ Enter) and Radiant should start up in your default web browser.

> **Important:** Always use `q` (+ Enter) to shut down the computing environment. This ensures your work is saved and the environment is properly closed.

<img src="figures/radiant-data-manage.png" width="500px">

To finalize the setup, open a terminal inside the docker container by pressing `1` (+ Enter) in the launch menu. If you are asked about Z shell configuration, you can press `q` (+ Enter) to skip, then run the command below:

```bash
setup;
exit;
```

## Updating the RSM-MSBA-K8S-INTEL computing environment on Windows

To update the container use the launch script and press 6 (and Enter). To update the launch script itself, press 7 (and Enter).

<img src="figures/rsm-launch-menu-wsl2.png" width="500px">

If for some reason you are having trouble updating either the container or the launch script open an Ubuntu terminal and copy-and-paste the code below. Note: You may have to right-click to get a copy-and-paste menu for the terminal. These commands will update the docker container, replace the old docker related scripts, and copy the latest version of the launch script to your Desktop.

```bash
docker pull vnijs/rsm-msba-k8s-intel;
rm -rf ~/git/docker*;
git clone https://github.com/radiant-rstats/docker-k8s.git ~/git/docker-k8s;
~/git/docker-k8s/launch-rsm-msba-k8s-intel.sh -v ~;
```

## Using VS Code

Microsoft's open-source integrated development environment (IDE), VS Code or Visual Studio Code, was the most popular development environment according to a [Stack Overflow developer survey](https://survey.stackoverflow.co/2022#section-most-popular-technologies-integrated-development-environment). VS Code is widely used by Google developers and is the [default development environment at Facebook](https://www.zdnet.com/article/facebook-microsofts-visual-studio-code-is-now-our-default-development-platform/).

Run the code below from a PowerShell terminal after installing VS Code to install relevant extensions:

```powershell
Invoke-WebRequest -Uri https://raw.githubusercontent.com/radiant-rstats/docker-k8s/master/vscode/extensions.txt -OutFile extensions.txt;
cat extensions.txt |% { code --install-extension $_ --force};
del extensions.txt;
```

To learn more about using VS Code to write python code see the links and comments below.

- <a href="https://code.visualstudio.com/docs/languages/python" target="_blank">Python in VS Code</a>
- <a href="https://code.visualstudio.com/docs/python/python-tutorial#_create-a-python-hello-world-source-code-file" target="_blank">VS Code Python Tutorial</a>

Note that you can use `Shift+Enter` to run the current line in a Python Interactive Window:

- <a href="https://code.visualstudio.com/docs/python/jupyter-support-py" target="_blank">Executing Python Code in VS Code</a>

When writing and editing python code you will have access to tools for auto-completion, etc. Your code will also be auto-formatted every time you save it using the "black" formatter.

- <a href="https://code.visualstudio.com/docs/python/editing" target="_blank">Editing Python in VS Code Python</a>

VS Code also gives you access to a debugger for your python code. For more information see the link below:

- <a href="https://code.visualstudio.com/docs/python/debugging" target="_blank">Debugging Python in VS Code Python</a>

You can even open and run Jupyter Notebooks in VS Code

- <a href="https://code.visualstudio.com/docs/datascience/jupyter-notebooks" target="_blank">Jupyter Notebooks in VS Code</a>

A major new feature in VS Code is the ability to use AI to help you write code. For more information see the links below:

- <a href="https://code.visualstudio.com/blogs/2023/03/30/vscode-copilot" target="_blank">VS Code Copilot</a>
- <a href="https://code.visualstudio.com/docs/editor/artificial-intelligence" target="_blank">VS Code AI</a>

### Trouble shooting

If you see `root` as the username when you type `whoami` in an Ubuntu terminal you will need to reset your username for WSL2. Please review step 4 in the install process for more guidance.

## Installing Python and R packages locally

To install the latest version of R-packages you need, add the lines of code shown below to `~/.Rprofile`. You can edit the file by running `code ~/.Rprofile` in a VS Code terminal.

```r
if (Sys.info()["sysname"] == "Linux") {
  options(repos = c(
    RSPM = "https://packagemanager.posit.co/cran/__linux__/noble/latest",
    CRAN = "https://cloud.r-project.org"
  ))
} else {
  options(repos = c(
    CRAN = "https://cloud.r-project.org"
  ))
}
```

This will be done for you automatically if you run the `setup` command from a terminal inside the docker container. To install R packages that will persist after restarting the docker container, enter code like the below in R and follow any prompts. After doing this once, you can use `install.packages("some-other-package")` to install packages locally in the future.

```r
fs::dir_create(Sys.getenv("R_LIBS_USER"), recurse = TRUE)
install.packages("fortunes", lib = Sys.getenv("R_LIBS_USER"))
```

To install Python modules that will **not** persist after restarting the docker container, enter code like the below from a terminal in VS Code:

```bash
pip install pyasn1
```

After installing a module you will have to restart any running Python kernels to `import` the module in your code.

### Using pip to install python packages

We recommend you use `pip` to install any additional packages you might need. For example, you can use the command below to install a new version of the `pyrsm` package that you will use regularly throughout the Rady MSBA program. Note that adding `--user` is important to ensure the package is still available after you restart the docker container

```bash
pip install --user --upgrade pyrsm
```

### Removing locally installed packages

To remove locally installed R packages press 8 (and Enter) in the launch menu and follow the prompts. To remove Python modules installed locally using `pip` press 9 (and Enter) in the launch menu

## Committing changes to the computing environment

By default re-starting the docker computing environment will remove any changes you made. This allows you to experiment freely, without having to worry about "breaking" things. However, there are times when you might want to keep changes.

As shown in the previous section, you can install R and Python packages locally rather than in the container. These packages will still be available after a container restart.

To install binary R packages for Ubuntu Linux you can use the command below. These packages will *not* be installed locally and would normally not be available after a restart.

```bash
sudo apt update;
sudo apt install r-cran-ada;
```

Similarly, some R-packages have requirements that need to be installed in the container (e.g., the `rgdal` package). The following two linux packages would need to be installed from a terminal in the container as follows:

```bash
sudo apt update;
sudo apt install libgdal-dev libproj-dev;
```

After completing the step above you can install the `rgdal` R-package locally using the following from R:

`install.packages("rgdal", lib = Sys.getenv("R_LIBS_USER"))`

To save (or commit) these changes so they *will* be present after a (container) restart type, for example, `c myimage` (and Enter). This creates a new docker image with your changes and also a new launch script on your Desktop with the name `launch-rsm-msba-myimage.sh` that you can use to launch your customized environment in the future.

If you want to share your customized version of the container with others (e.g., team members) you can push it is to Docker Hub <a href="https://hub.docker.com" target="_blank">https://hub.docker.com</a> by following the menu dialog after typing, e.g., `c myimage` (and Enter). To create an account on Docker Hub go to <a href="https://hub.docker.com/signup" target="_blank">https://hub.docker.com/signup</a>.

If you want to remove specific images from your computer run the commands below from a (bash) terminal. The first command generates a list of the images you have available.

`docker image ls;`

Select the IMAGE ID for the image you want to remove, e.g., `42b88eb6adf8`, and then run the following command with the correct image id:

`docker rmi 42b88eb6adf8;`

For additional resources on developing docker images see the links below:

- <https://colinfay.me/docker-r-reproducibility>
- <https://www.fullstackpython.com/docker.html>

## Cleanup

To remove any locally installed R-packages, press 6 (+ Enter) in the launch menu. To remove locally installed Python modules press 7 (+ Enter) in the launch menu.

> Note: It is also possible initiate the process of removing locally installed packages and settings from within the container. Open a terminal in VS Code and type `clean`. Then follow the prompts to indicate what needs to be removed.

You should always stop the `rsm-msba-k8s-intel` docker container using `q` (+ Enter) in the launch menu. If you want a full cleanup and reset of the computational environment on your system, however, execute the following commands from a (bash) terminal to (1) remove locally installed R and Python packages, (2) remove all docker images, networks, and (data) volumes, and (3) 'pull' only the docker image you need (e.g., rsm-msba-k8s-intel):

```bash
rm -rf ~/.rsm-msba;
docker system prune --all --volumes --force;
docker pull vnijs/rsm-msba-k8s-intel;
```

## Getting help

Please bookmark this page in your browser for easy access in the future. You can also access the documentation page for your OS by typing h (+ Enter) in the launch menu. Note that the launch script can also be started from the command line (i.e., a bash terminal) and has several important arguments:

* `launch -t 3.0.0` ensures a specific version of the docker container is used. Suppose you used version 3.0.0 for a project. Running the launch script with `-t 3.0.0` from the command line will ensure your code still runs, without modification, years after you last touched it!
* `launch -v ~/rsm-msba` will treat the `~/rsm-msba` directory on the host system (i.e., your macOS computer) as the home directory in the docker container. This can be useful if you want to setup a particular directory that will house multiple projects
* `launch -d ~/project_1` will treat the `project_1` directory on the host system (i.e., your Windows computer) as the project home directory in the docker container. This is an additional level of isolation that can help ensure your work is reproducible in the future. This can be particularly useful in combination with the `-t` option as this will make a copy of the launch script with the appropriate `tag` or `version` already set. Simply double-click the script in the `project_1` directory and you will be back in the development environment you used when you completed the project
* `launch -s` show additional output in the terminal that can be useful to debug any problems
* `launch -h` prints the help shown in the screenshot below

<img src="figures/docker-help.png" width="500px">

## Trouble shooting

If there is an error related to the firewall, antivirus, or VPN, try turning them off to check if you can now start up the container. You should not be without a virus checker or firewall however! We recommend using **Windows Defender**. If you are not sure if Windows Defender is correctly configured, please check with IT.

Alternative "fixes" that have worked, are to restart docker by right-clicking on the "whale" icon in the system tray and/or restart your computer. It is best to quit any running process before you restart your computer (i.e., press q and Enter in the launch menu)

## Optional

If you want to make your terminal look nicer and add syntax highlighting, auto-completion, etc. consider following the install instructions linked below:

<https://github.com/radiant-rstats/docker-k8s/blob/main/install/setup-ohmyzsh.md>

<img src="figures/ohmyzsh-powerlevel10k.png" width="500px">
