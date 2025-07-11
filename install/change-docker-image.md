# Committing changes to the computing environment

As mentioned in the main install instruction documents, re-starting the RSM-MSBA computing environment will remove any changes you made **inside** the container. This allows you to experiment freely, without having to worry about "breaking" things. However, there are times when you might want to make changes to the underlying docker image so they are always available when you restart the container.

You can install Python packages locally rather than in the container. These packages will still be available after a container restart. However, suppose you need to install binary packages for Ubuntu Linux, e.g., to work with the Tesseract OCR library. You could use the command below to do this. These packages will be installed inside the docker container and would normally not be available after a restart.

The following two Linux packages would need to be installed from a terminal in the container as follows:

```bash
sudo apt update;
sudo apt-get install tesseract-ocr tesseract-ocr-eng;
cd /opt/base-uv;
uv add pytesseract;
cd -;
```

To save (or commit) these changes so they *will* be present after a (container) restart type, for example, `c myimage` (+ Enter). This creates a new docker image with your changes and also a new launch script on your Desktop with the name `launch-rsm-msba-myimage.command` that you can use to launch your customized environment in the future.

If you want to share your customized version of the container with others (e.g., team members), you can push it to Docker Hub <a href="https://hub.docker.com" target="_blank">https://hub.docker.com</a> by following the menu dialog after typing, e.g., `c myimage` (+ Enter). To create an account on Docker Hub, go to <a href="https://hub.docker.com/signup" target="_blank">https://hub.docker.com/signup</a>.

If you want to remove specific images from your computer, run the commands below from a (bash) terminal. The first command generates a list of the images you have available.

`docker image ls;`

Select the IMAGE ID for the image you want to remove, e.g., `42b88eb6adf8`, and then run the following command with the correct image ID:

`docker rmi 42b88eb6adf8;`
