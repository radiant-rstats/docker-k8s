# Contents

- [Installing the RSM-MSBA-K8S-INTEL computing environment on Linux](#installing-the-rsm-msba-k8s-intel-computing-environment-on-linux)
- [Updating the RSM-MSBA-K8S-INTEL computing environment on Linux](#updating-the-rsm-msba-k8s-intel-computing-environment-on-linux)
- [Using VS Code](#using-vs-code)
- [Installing Python and R packages locally](#installing-python-and-r-packages-locally)
- [Committing changes to the computing environment](#committing-changes-to-the-computing-environment)
- [Cleanup](#cleanup)
- [Getting help](#getting-help)
- [Trouble shooting](#trouble-shooting)

## Installing the RSM-MSBA-K8S--INTEL computing environment on Linux (Ubuntu 24.04)

Please follow the instructions below to install the rsm-msba-k8s-intel computing environment. It has Python, R, Radiant, Postgres, Spark and various required packages pre-installed. The computing environment will be consistent across all students and faculty, easy to update, and also easy to remove if desired (i.e., there will *not* be dozens of pieces of software littered all over your computer).

**Step 1**: Install docker on Ubuntu 24.04

Run the following code in a terminal and provide your (sudo) password when requested:

```bash
sudo apt install curl;
source <(curl -s https://raw.githubusercontent.com/radiant-rstats/docker-k8s/main/install/install-docker.sh);
```

Detailed discussion of the steps involved is available at the link below:

https://docs.docker.com/engine/install/ubuntu/

Once docker is installed, make sure it is running. You can can check this by using the following command. If this produces some output and no errors you are set to continue with the next steps. If you see any "permission" errors you may need to restart your system.

```bash
docker ps;
```

![docker](figures/docker-icon.png)

Optional: If you are interested, the linked video gives a brief intro to what Docker is: https://www.youtube.com/watch?v=YFl2mCHdv24

**Step 2**: Open a terminal and copy-and-paste the code below

```bash
git clone https://github.com/radiant-rstats/docker-k8s.git ~/git/docker;
cp -p ~/git/docker-k8s/launch-rsm-msba-k8s-intel.sh ~/Desktop;
~/Desktop/launch-rsm-msba-k8s-intel.sh;
```

This step will clone and start up a script that will finalize the installation of the computing environment. The first time you run this script it will download the latest version of the computing environment which can take some time. Wait for the container to download and follow any prompts. Once the download is complete you should see a menu as in the screen shot below.

<img src="figures/rsm-msba-menu-linux.png" width="500px">

The code above also creates a copy of the file `launch-rsm-msba-k8s-intel.sh` on your Desktop that you can use to start the container again in the future.

Run the command below to start the launch script from the command line.

```bash
~/git/docker-k8s/launch-rsm-msba-k8s-intel.sh -v ~;
```

**Step 3**: Check that you can launch Radiant

You will know that the installation was successful if you can start Radiant. If you press 2 (+ Enter) Radiant should start up in your default web browser.

> Important: Always use q (+ Enter) to shutdown the computing environment

<img src="figures/radiant-data-manage.png" width="500px">

To finalize the setup, open a terminal inside the docker container press `1` and `Enter` in the launch menu and then run the command below:

```bash
setup;
exit;
```

## Updating the RSM-MSBA-K8S-INTEL computing environment on Linux

To update the container press 4 (+ Enter) in the launch manu. To update the launch script itself, press 5 (+ Enter).

<img src="figures/rsm-msba-menu-linux.png" width="500px">

If for some reason you are having trouble updating either the container or the launch script open a terminal and copy-and-paste the code below. These commands will update the docker container, replace the old docker related scripts, and copy the latest version of the launch script to your Desktop.

```bash
docker pull vnijs/rsm-msba-k8s-intel;
rm -rf ~/git/docker*;
git clone https://github.com/radiant-rstats/docker-k8s.git ~/git/docker-k8s;
cp -p ~/git/docker-k8s/launch-rsm-msba-k8s-intel.sh ~/Desktop;
```

## Using VS Code

Microsoft's open-source integrated development environment (IDE), VS Code or Visual Studio Code, was the most popular development environment according to a [Stack Overflow developer survey](https://survey.stackoverflow.co/2022#section-most-popular-technologies-integrated-development-environment). VS Code is widely used by Google developers and is the [default development environment at Facebook](https://www.zdnet.com/article/facebook-microsofts-visual-studio-code-is-now-our-default-development-platform/).

VS Code can be installed from the link below and is an excellent, and very popular, editor for Python, R, and many other programming languages.

<a href="https://code.visualstudio.com/download" target="_blank">https://code.visualstudio.com/download</a>

Run the code below from a terminal after installing VS Code to install relevant extensions:

```bash
cd ~/git/docker-k8s/vscode;
./extension-install.sh;
cd -;
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

- <a href="https://code.visualstudio.com/docs/copilot/overview" target="_blank">VS Code Copilot</a>

## Installing Python and R packages locally

To install the latest version of R-packages you need, add the lines of code shown below to `~/.Rprofile`. You can edit the file by running `code ~/.Rprofile` in a VS Code terminal.

```r
if (Sys.info()["sysname"] == "Linux") {
  options(repos = c(
    RSPM = "https://packagemanager.posit.co/cran/__linux__/noble/latest",
    CRAN = "https://cloud.r-project.org"
  ))
} else {
  options(repos = c(CRAN = "https://cloud.r-project.org"))
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

To save (or commit) these changes so they *will* be present after a (container) restart type, for example, `c myimage` (+ Enter). This creates a new docker image with your changes and also a new launch script on your Desktop with the name `launch-rsm-msba-k8s-arm-myimage.sh` that you can use to launch your customized environment in the future.

If you want to share your customized version of the container with others (e.g., team members) you can push it is to Docker Hub <a href="https://hub.docker.com" target="_blank">https://hub.docker.com</a> by following the menu dialog after typing, e.g., `c myimage` (+ Enter). To create an account on Docker Hub go to <a href="https://hub.docker.com/signup" target="_blank">https://hub.docker.com/signup</a>.

If you want to remove specific images from your computer run the commands below from a (bash) terminal. The first command generates a list of the images you have available.

`docker image ls;`

Select the IMAGE ID for the image you want to remove, e.g., `42b88eb6adf8`, and then run the following command with the correct image id:

`docker rmi 42b88eb6adf8;`

For additional resources on developing docker images see the links below:

- <https://colinfay.me/docker-r-reproducibility>
- <https://www.fullstackpython.com/docker.html>

## Cleanup

To remove any locally installed R-packages, press 6 (+ Enter) in the launch menu. To remove locally installed Python modules press 7 (+ Enter) in the launch menu.

> Note: It is also possible initiate the process of removing locally installed packages and settings from within the container. Open a terminal in VS Code, connected to the docker container, and type `clean`. Then follow the prompts to indicate what needs to be removed.

You should always stop the `rsm-msba-k8s-intel` docker container using `q` (+ Enter) in the launch menu. If you want a full cleanup and reset of the computational environment on your system, however, execute the following commands from a (bash) terminal to (1) remove prior R(studio) and Python packages, (2) remove all docker images, networks, and (data) volumes, and (3) 'pull' only the docker image you need (e.g., rsm-msba-k8s-intel):

```bash
rm -rf ~/.rsm-msba;
docker system prune --all --volumes --force;
docker pull vnijs/rsm-msba-k8s-intel;
```

## Getting help

Please bookmark this page in your browser for easy access in the future. You can also access the documentation page for your OS by typing h (+ Enter) in the launch menu. Note that the launch script can also be started from the command line (i.e., a bash terminal) and has several important arguments:

* `launch -t 3.0.0` ensures a specific version of the docker container is used. Suppose you used version 3.0.0 for a project. Running the launch script with `-t 3.0.0` from the command line will ensure your code still runs, without modification, years after you last touched it!
* `launch -v ~/rsm-msba` will treat the `~/rsm-msba` directory on the host system (i.e., your Linux computer) as the home directory in the docker container. This can be useful if you want to setup a particular directory that will house multiple projects
* `launch -d ~/project_1` will treat the `project_1` directory on the host system (i.e., your Linux computer) as the project home directory in the docker container. This is an additional level of isolation that can help ensure your work is reproducible in the future. This can be particularly useful in combination with the `-t` option as this will make a copy of the launch script with the appropriate `tag` or `version` already set. Simply double-click the script in the `project_1` directory and you will be back in the development environment you used when you completed the project
* `launch -s` show additional output in the terminal that can be useful to debug any problems
* `launch -h` prints the help shown in the screenshot below

<img src="figures/docker-help.png" width="500px">

## Trouble shooting

The only issues we have seen on Linux so far can be "fixed" by restarting docker and/or rebooting. To restart the docker service use:

```bash
sudo service docker stop
sudo service docker start
```

## Optional

If you want to make your terminal look nicer and add syntax highlighting, auto-completion, etc. consider following the install instructions linked below:

<https://github.com/radiant-rstats/docker-k8s/blob/main/install/setup-ohmyzsh.md>

<img src="figures/ohmyzsh-powerlevel10k.png" width="500px">