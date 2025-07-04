# Contents

- [Contents](#contents)
  - [Installing the RSM-MSBA-K8S-ARM computing environment on macOS systems with an ARM chip (e.g., M3 or M4)](#installing-the-rsm-msba-k8s-arm-computing-environment-on-macos-systems-with-an-arm-chip-eg-m3-or-m4)
  - [Updating the RSM-MSBA-K8S-ARM computing environment on macOS systems with an ARM chip](#updating-the-rsm-msba-k8s-arm-computing-environment-on-macos-systems-with-an-arm-chip)
  - [Using VS Code](#using-vs-code)
  - [Installing Python packages locally](#installing-python-packages-locally)
    - [Using pip to install python packages](#using-pip-to-install-python-packages)
    - [Removing locally installed packages](#removing-locally-installed-packages)
  - [Committing changes to the computing environment](#committing-changes-to-the-computing-environment)
  - [Cleanup](#cleanup)
  - [Getting help](#getting-help)
  - [Trouble shooting](#trouble-shooting)
  - [Optional](#optional)

## Installing the RSM-MSBA-K8S-ARM computing environment on macOS systems with an ARM chip (e.g., M3 or M4)

Please follow the instructions below to install the rsm-msba-k8s-arm computing environment. It has Python, Radiant, Postgres, Spark and various required packages pre-installed. The computing environment will be consistent across all students and faculty, easy to update, and also easy to remove if desired (i.e., there will *not* be dozens of pieces of software littered all over your computer).

**Step 1**: Install docker from the link below and make sure it is running. You will know it is running if you see the icon below at the top-right of your screen. If the containers in the image are moving up and down docker hasn't finished starting up yet.

![docker](figures/docker-icon.png)

[download and install docker for macOS with an ARM chip (e.g., M3 or M4)](https://desktop.docker.com/mac/stable/arm64/Docker.dmg)

You should change the (maximum) resources docker is allowed to use on your system. We recommend you set this to approximately 50% of the maximum available on your system.

<img src="figures/docker-resources-macos.png" width="500px">

You should also go to the "Advanced" tab and configure the installation of the Command Line Interface (CLI). Set it to "System" as shown in the screenshot below and click on the "Apply & Restart".

<img src="figures/docker-system-mac.png" width="500px">

> Note: This video gives a brief (100 seconds) introduction to what Docker is: <https://www.youtube.com/watch?v=Gjnup-PuquQ>{target="_blank"}

**Step 2**: Open a terminal and copy-and-paste the code below

Get [iTerm2](https://iterm2.com/downloads.html){target="_blank"} and install it.

You will need the macOS command line developer tools for the next steps. Open an iTerm2 terminal, run the code below, and follow the prompts until the software is installed.

```bash
xcode-select --install;
```

**Step 3**: Setup RSM-MSBA computing environment by copy-and-pasting the code below into an iTerm2 terminal.

```bash
mkdir ~/git;
git clone https://github.com/radiant-rstats/docker-k8s.git ~/git/docker-k8s;
cp -p ~/git/docker-k8s/launch-rsm-msba-k8s-arm.sh ~/Desktop/launch-rsm-msba.command;
~/Desktop/launch-rsm-msba.command;
```

This step will clone and start up a script that will finalize the installation of the computing environment. The first time you run this script it will download the latest version of the computing environment which can take some time. Wait for the container to download and follow any prompts. Once the download is complete you should see the launch menu shown in the screenshot below.

<img src="figures/rsm-launch-menu-macos-arm.png" width="500px">

The code above also copies the file `launch-rsm-msba-k8s-arm.sh` to `launch-rsm-msba.command` on your Desktop. You will be able to double-click this file to start the container again in the future.

Alternatively, you can run the command below to launch the docker container from a terminal (i.e., iTerm2).

```bash
~/git/docker-k8s/launch-rsm-msba-k8s-arm.sh -v ~;
```

**Step 4**: Check that you can launch Radiant

You will know that the installation was successful if you can start Radiant. If you press 2 (+ Enter) in the launch menu, Radiant should start up in your default web browser.

<img src="figures/radiant-data-manage.png" width="500px">

> Important: Always use q (+ Enter) to shutdown the computing environment

To finalize the setup, open a terminal inside the docker container by pressing 1 (+ Enter) in the launch menu. If you are asked about "Z shell configuration, press q + Enter and then run the command below:

```bash
setup;
```

When the setup process is done, type `exit` (+ Enter) to return to the launch menu.

## Updating the RSM-MSBA-K8S-ARM computing environment on macOS systems with an ARM chip

To update the container press 3 (+ Enter) in the launch menu. To update the launch script itself, press 4 (+ Enter) in the launch menu.

<img src="figures/rsm-launch-menu-macos-arm.png" width="500px">

If for some reason you are having trouble updating either the container or the launch script, open a terminal and copy-and-paste the code below. These commands will update the docker container, replace the old docker related scripts, and copy the latest version of the launch script to your Desktop.

```bash
docker pull vnijs/rsm-msba-k8s-arm;
rm -rf ~/git/docker*;
git clone https://github.com/radiant-rstats/docker-k8s.git ~/git/docker-k8s;
cp -p ~/git/docker-k8s/launch-rsm-msba-k8s-arm.sh ~/Desktop/launch-rsm-msba.command;
```

## Using VS Code

Microsoft's open-source Integrated Development Environment (IDE), VS Code or Visual Studio Code, is the most popular development environment according to a [Stack Overflow developer survey](https://survey.stackoverflow.co/2024/technology#most-popular-technologies-webframe). VS Code is widely used by Google developers and is the [default development environment at Facebook](https://www.zdnet.com/article/facebook-microsofts-visual-studio-code-is-now-our-default-development-platform/).

VS Code can be installed from the link below and is an excellent editor for Python, SQL, Javascript, R, and many other programming languages.

<a href="https://code.visualstudio.com/download" target="_blank">https://code.visualstudio.com/download</a>

Run the code below from a terminal on macOS after installing VS Code to install relevant extensions:

```bash
cd ~/git/docker-k8s/vscode;
./extension-install.sh;
cd -;
```

If you get a "code: command not found" error when trying to launch VS Code from a terminal, follow the instructions below to add VS Code to your path:

<https://code.visualstudio.com/docs/setup/mac#_launching-from-the-command-line>

To learn more about using VS Code to write python code see the links and comments below.

- <a href="https://code.visualstudio.com/docs/languages/python" target="_blank">Python in VS Code</a>
- <a href="https://code.visualstudio.com/docs/python/python-tutorial#_create-a-python-hello-world-source-code-file" target="_blank">VS Code Python Tutorial</a>

You can even create and run Jupyter Notebooks in VS Code:

- <a href="https://code.visualstudio.com/docs/datascience/jupyter-notebooks" target="_blank">Jupyter Notebooks in VS Code</a>

A major new feature in VS Code is the ability to use AI to help you write code. For more information see the links below:

- <a href="https://code.visualstudio.com/docs/copilot/overview" target="_blank">VS Code Copilot</a>

## Installing Python packages locally

The RSM-MSBA docker image uses UV for all python package management, virtual environments, and different python version. To learn more about UV click [here](https://docs.astral.sh/uv/).

To install Python packages that will **not** persist after restarting the docker container, enter code like the below from a terminal in VS Code:

```bash
cd /opt/base-uv/;
uv add mlxtend;
```

After installing a package you may need to restart any running Python kernels so you can `import` the new package in a Jypyter notebook.

### Using UV to create a virtual environment

Use UV to install any additional packages you might need. For example, you can use the sequence of commands below to install create a virtual (python) environment in a project folder and then install, for example, a specific version of the `polars` package.

First create a new directory for your project

```bash
rm -rf ~/my_project; # for cleanup if you want to try this multiple times
mkdir ~/my_project;
cd ~/my_project;
```

Make sure no other virtual environment is active for the project folder, initialize the project, create a virtual python environment, and `activate` it.

```bash
deactivate;
uv init .;
uv venv --python 3.12;
source .venv/bin/activate;
```

Now we are ready to `add` python packages to the environment. In this case, we will install a specific version of polars and we will double check that this version was indeed installed.

```bash
uv add polars==1.1.0;
python -c "import polars as pl; print(pl.__version__)";
```

> Note: The `-c` argument in the code block above allows a python program to be passed in as string. Use `python --help` to see all the python options.

### Removing a virtual environment created using UV

To remove a virtual environment from a project directory you can use the following code:

```bash
cd ~/my_project;
rm -rf .venv
rm README.md main.py pyproject.toml uv.lock
rm -rf .git .gitignore .python-version
```

You could, of course, also delete the entire project folder using `rm -rf ~/my_project` is you don't need it anymore.

## Committing changes to the computing environment

By default re-starting the RSM-MSBA computing environment will remove any changes you made inside the container. This allows you to experiment freely, without having to worry about "breaking" things. However, there are times when you might want to keep changes.

As shown in the previous section, you can install python packages locally rather than in the container. These packages will still be available after a container restart.

Suppose you need to install binary packages for Ubuntu Linux, e.g., to work with the tesseract OCR library.  You could use the command below to do this. These packages will be installed inside the docker container and would normally not be available after a restart.

The following two linux packages would need to be installed from a terminal in the container as follows:

```bash
sudo apt update;
sudo apt-get install tesseract-ocr tesseract-ocr-eng;
cd /opt/base-uv;
uv add pytesseract;
cd -;
```

To save (or commit) these changes so they *will* be present after a (container) restart type, for example, `c myimage` (+ Enter). This creates a new docker image with your changes and also a new launch script on your Desktop with the name `launch-rsm-msba-myimage.command` that you can use to launch your customized environment in the future.

If you want to share your customized version of the container with others (e.g., team members) you can push it is to Docker Hub <a href="https://hub.docker.com" target="_blank">https://hub.docker.com</a> by following the menu dialog after typing, e.g., `c myimage` (+ Enter). To create an account on Docker Hub go to <a href="https://hub.docker.com/signup" target="_blank">https://hub.docker.com/signup</a>.

If you want to remove specific images from your computer run the commands below from a (bash) terminal. The first command generates a list of the images you have available.

`docker image ls;`

Select the IMAGE ID for the image you want to remove, e.g., `42b88eb6adf8`, and then run the following command with the correct image id:

`docker rmi 42b88eb6adf8;`

For additional resources on developing docker images see the links below:

- <https://colinfay.me/docker-r-reproducibility>
- <https://www.fullstackpython.com/docker.html>

## Cleanup

You should always stop the `rsm-msba-k8s-arm` docker container using `q` (+ Enter) in the launch menu. If you want a full cleanup and reset of the computational environment on your system, however, execute the following commands from a (bash) terminal to remove all docker images, networks, and (data) volumes, and 'pull' only the docker image you need (e.g., rsm-msba-k8s-arm):

```bash
rm -rf ~/.rsm-msba;
docker system prune --all --volumes --force;
docker pull vnijs/rsm-msba-k8s-arm;
```

## Getting help

Please bookmark this page in your browser for easy access in the future. You can also access the documentation page for your OS by typing h (+ Enter) in the launch menu. Note that the launch script can also be started from the command line (i.e., a bash terminal) and has several important arguments:

* `launch -t 1.3.0` ensures a specific version of the docker container is used. Suppose you used version 1.3.0 for a project. Running the launch script with `-t 1.3.0` from the command line will ensure your code still runs, without modification, years after you last touched it!
* `launch -v ~/rsm-msba` will treat the `~/rsm-msba` directory on the host system (i.e., your macOS computer) as the home directory in the docker container. This can be useful if you want to setup a particular directory that will house multiple projects
* `launch -s` show additional output in the terminal that can be useful to debug any problems
* `launch -h` prints the help shown in the screenshot below

<img src="figures/docker-help.png" width="500px">

## Trouble shooting

The only issues we have seen on macOS so far can be addressed by restarting docker and/or restarting your computer

## Optional

If you want to make your terminal look nicer and add syntax highlighting, auto-completion, etc. follow the install instructions linked below:

<https://github.com/radiant-rstats/docker-k8s/blob/main/install/setup-ohmyzsh.md>

<img src="figures/ohmyzsh-powerlevel10k-iterm.png" width="500px">
