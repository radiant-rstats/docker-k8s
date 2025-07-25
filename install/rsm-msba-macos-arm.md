# RSM-MSBA on macOS (ARM)

- [RSM-MSBA on macOS (ARM)](#rsm-msba-on-macos-arm)
  - [Installing the RSM-MSBA computing environment](#installing-the-rsm-msba-computing-environment)
  - [Updating the RSM-MSBA computing environment](#updating-the-rsm-msba-computing-environment)
  - [Using VS Code](#using-vs-code)
  - [Using UV](#using-uv)
    - [Creating a virtual environment](#creating-a-virtual-environment)
    - [Removing a virtual environment](#removing-a-virtual-environment)
  - [Cleanup](#cleanup)
  - [Getting help](#getting-help)
  - [Troubleshooting](#troubleshooting)
  - [Optional](#optional)

## Installing the RSM-MSBA computing environment

Please follow the instructions below to install the RSM-MSBA computing environment. It has Python, Radiant, Postgres, Spark and various required packages pre-installed. The computing environment will be consistent across all students and faculty, easy to update, and also easy to remove if desired (i.e., there will _not_ be dozens of pieces of software littered all over your computer).

**Step 1**: Install Docker Desktop from the link below and make sure it is running. You will know it is running if you see the icon below at the top-right of your screen. If the containers in the image are moving up and down docker hasn't finished starting up yet.

![docker](figures/docker-icon.png)

[download and install Docker Desktop for macOS with an ARM chip (e.g., M3 or M4)](https://desktop.docker.com/mac/stable/arm64/Docker.dmg)

You should change the (maximum) resources Docker Desktop is allowed to use on your system. We recommend you set this to approximately 50% of the maximum available on your system (see screenshot below).

<img src="figures/docker-resources-macos.png" width="500px">

You should also go to the "Advanced" tab in _Docker Desktop > Settings_ and configure the installation of the Command Line Interface (CLI). Set it to "System" as shown in the screenshot below and click on the "Apply & Restart".

<img src="figures/docker-system-mac.png" width="500px">

> Note: This video gives a brief (100 seconds) introduction to what Docker is: [https://www.youtube.com/watch?v=Gjnup-PuquQ](https://www.youtube.com/watch?v=Gjnup-PuquQ){target="\_blank"}

**Step 2**: Get iTerm2 and open a terminal and copy-and-paste the code below

Download the stable release of [iTerm2](https://iterm2.com/downloads.html){target="\_blank"}. To install the software, unzip the file you downloaded and move **iTerm.app** to your Applications folder.

**Step 3**: Install macOS command line developer tools

You will need the macOS command line developer tools for the next steps. Open an iTerm2 terminal, run the code below, and follow the prompts until the software is installed.

```bash
xcode-select --install;
```

**Step 4**: Set up RSM-MSBA computing environment by copy-and-pasting the code below into an iTerm2 terminal.

```bash
mkdir ~/git;
git clone https://github.com/radiant-rstats/docker-k8s.git ~/git/docker-k8s;
cp -p ~/git/docker-k8s/launch-rsm-msba-k8s.sh ~/Desktop/launch-rsm-msba.command;
~/Desktop/launch-rsm-msba.command;
```

The launch script will finalize the installation of the computing environment. The first time you run this script, it will download the latest version of the computing environment, which can take some time depending on the speed of your internet connection. Wait for the image to download and follow any prompts. Once the download is complete, you should see a menu as in the screenshot below.

<img src="figures/rsm-launch-menu-macos-arm.png" width="500px">

The code above also copies `launch-rsm-msba-k8s.sh` to `launch-rsm-msba.command` to your Desktop. You can double-click this file to start the container again in the future. Alternatively, you can run the command below to launch the docker container from an iTerm2 terminal.

```bash
~/git/docker-k8s/launch-rsm-msba-k8s.sh -v ~;
```

**Step 5**: Check that you can launch Radiant-for-R

You will know that the installation was successful if you can start Radiant. If you press 2 (+ Enter) in the launch menu, Radiant should start up in your default web browser.

<img src="figures/radiant-data-manage.png" width="500px">

> Important: Always use q (+ Enter) to shutdown the computing environment

To finalize the setup, open a terminal inside the docker container by pressing 1 (+ Enter) in the launch menu. If you are asked about "Z shell configuration," press q + Enter and then run the command below:

```bash
setup;
```

When the setup process is done, type `exit` (+ Enter) to return to the launch menu.

## Updating the RSM-MSBA computing environment

To update the container press 3 (+ Enter) in the launch menu. To update the launch script itself, press 4 (+ Enter) in the launch menu.

<img src="figures/rsm-launch-menu-macos-arm.png" width="500px">

If for some reason you are having trouble updating either the container or the launch script, open an iTerm2 terminal and copy-and-paste the code below. These commands will update the docker container, replace the old docker related scripts, and copy the latest version of the launch script to your Desktop.

```bash
docker pull vnijs/rsm-msba-k8s;
rm -rf ~/git/docker*;
git clone https://github.com/radiant-rstats/docker-k8s.git ~/git/docker-k8s;
cp -p ~/git/docker-k8s/launch-rsm-msba-k8s.sh ~/Desktop/launch-rsm-msba.command;
```

## Using VS Code

Microsoft's open-source Integrated Development Environment (IDE), VS Code or Visual Studio Code, is the most popular development environment according to a [Stack Overflow developer survey](https://survey.stackoverflow.co/2024/technology#most-popular-technologies-webframe). VS Code is widely used by Google developers and is the [default development environment at Facebook](https://www.zdnet.com/article/facebook-microsofts-visual-studio-code-is-now-our-default-development-platform/).

VS Code can be installed from the link below and is an excellent editor for Python, SQL, JavaScript, R, and many other programming languages.

<a href="https://code.visualstudio.com/docs/?dv=darwinarm64" target="_blank">https://code.visualstudio.com/docs/?dv=darwinarm64</a>

Run the code below from a terminal on macOS after installing VS Code to install relevant extensions:

```bash
cd ~/git/docker-k8s/vscode;
./extension-install.sh;
cd -;
```

If you get a "code: command not found" error when trying to launch VS Code from a terminal, follow the instructions below to add VS Code to your path:

[https://code.visualstudio.com/docs/setup/mac#\_launching-from-the-command-line](https://code.visualstudio.com/docs/setup/mac#_launching-from-the-command-line)

To learn more about using VS Code to write Python code, see the links and comments below.

- <a href="https://code.visualstudio.com/docs/languages/python" target="_blank">Python in VS Code</a>
- <a href="https://code.visualstudio.com/docs/python/python-tutorial#_create-a-python-hello-world-source-code-file" target="_blank">VS Code Python Tutorial</a>

You can even create and run Jupyter Notebooks in VS Code:

- <a href="https://code.visualstudio.com/docs/datascience/jupyter-notebooks" target="_blank">Jupyter Notebooks in VS Code</a>

A major feature in VS Code is the ability to use AI to help you write code. For more information see the link below:

<a href="https://code.visualstudio.com/docs/copilot/overview" target="_blank">VS Code Copilot</a>

## Using UV

The RSM-MSBA docker image uses UV for Python package management, virtual environments, and installing different versions of Python. To learn more about UV see <a href="https://docs.astral.sh/uv/" target="_blank">https://docs.astral.sh/uv/</a>.
It is important to realize that the RSM-MSBA docker container will reset itself completely when it is restarted (i.e., it always starts from the same docker image). This means that we can install Python packages that will **not** persist after restarting the docker container, which can be convenient if we want to experiment without worrying about "breaking" anything. To add to the main Python environment inside the docker container, we can enter code like the below from a terminal in VS Code:

```bash
cd /opt/base-uv/;
source .venv/bin/activate
uv add mlxtend;
```

> Note: After installing a package you may need to restart any running Python kernels so you can `import` the new package in a Jupyter Notebook, for example.

### Creating a virtual environment

You can also use UV to install packages you might need for a specific project or class in a way that **will** persist even if you restart the docker container. For example, you can use the sequence of commands below to create a virtual (Python) environment in a project folder and install a specific version of the `polars` package.

First create a new directory for your project

```bash
# rm -rf ~/my_project; # for cleanup if you want to try this multiple times
mkdir ~/my_project;
cd ~/my_project;
```

Make sure no other virtual environment is active in the project folder, then initialize the project folder, create a virtual Python environment, and `activate` it.

```bash
deactivate;
uv init .;
uv venv --python 3.12;
source .venv/bin/activate;
```

Now we are ready to `add` Python packages to the environment that are needed for the project or class. In this case, we will install a specific version of polars and we will double-check that this version was indeed installed.

```bash
uv add polars==1.1.0;
python -c "import polars as pl; print(pl.__version__)";
```

> Note: The `-c` argument in the code block above allows a (small) Python program to be passed in as a string. Use `python --help` to see all the Python options.

### Removing a virtual environment

To remove a virtual environment from a project directory you can use the following code:

```bash
cd ~/my_project;
rm -rf .venv
rm README.md main.py pyproject.toml uv.lock
rm -rf .git .gitignore .python-version
```

You could, of course, also delete the entire project folder using `rm -rf ~/my_project` if you don't need it anymore.

## Cleanup

You should always stop the docker container using `q` (+ Enter) in the launch menu. If you want a full cleanup and reset of the computational environment on your system, however, execute the following commands from a (bash) terminal to remove all Docker images, networks, and (data) volumes, and _pull_ only the specific Docker image you need:

```bash
rm -rf ~/.rsm-msba;
docker system prune --all --volumes --force;
docker pull vnijs/rsm-msba-k8s;
```

## Getting help

Please bookmark this page in your browser for easy access in the future. You can also access the documentation page for your OS by typing h (+ Enter) in the launch menu. Note that the launch script can also be started from the command line (i.e., a bash terminal) and has several important arguments:

- `launch -t 1.3.0` ensures a specific version of the docker container is used. Suppose you used version 1.3.0 for a project. Running the launch script with `-t 1.3.0` from the command line will ensure your code still runs, without modification, years after you last touched it!
- `launch -v ~/rsm-msba` will treat the `~/rsm-msba` directory on the host system (i.e., your macOS computer) as the home directory in the docker container. This can be useful if you want to set up a particular directory that will house multiple projects
- `launch -s` show additional output in the terminal that can be useful to debug any problems
- `launch -h` prints the help shown in the screenshot below

<img src="figures/docker-help.png" width="500px">

## Troubleshooting

The only issues we have seen on macOS so far can be addressed by restarting Docker and/or restarting your computer.

## Optional

If you want to make your terminal look nicer and add syntax highlighting, auto-completion, etc. follow the install instructions linked below:

<a href="https://github.com/radiant-rstats/docker-k8s/blob/main/install/setup-ohmyzsh.md" target="_blank">https://github.com/radiant-rstats/docker-k8s/blob/main/install/setup-ohmyzsh.md</a>

<img src="figures/ohmyzsh-powerlevel10k-iterm.png" width="500px">

If you want to make changes to the docker image, follow the instructions linked below:

<a href="https://github.com/radiant-rstats/docker-k8s/blob/main/install/change-docker-image.md" target="_blank">https://github.com/radiant-rstats/docker-k8s/blob/main/install/change-docker-image.md</a>
