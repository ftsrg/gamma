## Headless Gamma - Docker Image
This document focuses on the creation and usage of the Headless Gamma Docker image. It also presents how to push and pull the official Headless Gamma Docker image.

## Setting up the Docker container

 Make sure that Docker is installed on the computer in use. The following [tutorial](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-18-04) was used to install Docker on Ubuntu. Note that the tutorial below focuses on the creation of the docker image, and then running a container from that image. For this reason, it ignores the official Headless Gamma image that can be found [here](https://hub.docker.com/repository/docker/ftsrggamma/headless-gamma). It is highly recommended to use the official image. Further information on how to use this image can be found in the Headless Gamma [README](https://github.com/csuvi98/gamma/tree/dev/plugins/headless).

 1. Create a working folder, and copy the Dockerfile inside.
 2. Inside the working folder, create the following folders: `eclipse`,  `server`, `uppaal`, `theta`, `project`.
 3. Export the Headless Gamma inside the working folder, with the `Root directory` set to "eclipse". This way, the exported Headless Gamma will be inside the eclipse folder.
 5. Copy the `pom.xml` found in `hu.bme.mit.gamma.headless.server` inside the `server` folder. After that, create a folder named `src` inside the `server` folder.
 6. Inside the `src` folder, create a `main` folder. Inside the `main` folder, create a `java` and `resources` folder.
 7. Copy the contents of the `src` folder found in `hu.bme.mit.gamma.headless.server` inside the `java` folder.
 8. Copy the contents of the `resources` folder found in `hu.bme.mit.gamma.headless.server` inside the `resources` folder.
 9. Make sure to set the properties correctly inside `config.properties`, which can be found in the `resources` folder. Set the path to the Headless Gamma to `/home/eclipse/eclipse` and the path of the workspace folder to `/home/workspaces/`.
 10. Copy the contents of the UPPAAL folder installed on your computer inside the `uppaal` folder.
 11. Copy the `get-theta.sh` file inside the `theta` folder. This file can be found inside the `gamma/plugins/xsts/theta-bin` folder. 
 12. Open a terminal and build the docker image with the following command: `docker build -t gamma <path to working folder>` (the working folder is the folder created in the first step) . This will create a docker image named "gamma".
 13. In a terminal, run a docker container from the gamma image using the `docker run -it -p 8080:8080 --name gamma_container gamma:latest` command. This command will bind the localhost:8080 address of the host machine to the Docker container, forwarding commands to the webserver running inside. The container is named "gamma_container", and starts in interactive mode, allowing for CLI access. The last parameter is the image, which is `gamma:latest`, which indicates that the latest Gamma image build is used.
 
It is possible to change the port binding if the user wishes, but the webserver listens to port 8080. In the port binding parameter, the part before the ":" stands for the host port, and the one after is the container port. So changing the parameter to "5555:8080" is valid, but "8080:5555" would result in communication failure.  Names of the image and container can also be changed.

## Pulling the Docker image
You can pull the official Headless Gamma image, named `ftsrggamma/headless-gamma` using this command:

    docker pull ftsrggamma/headless-gamma:<tag number>

Always use the latest version number in the `<tag number>` field.

Further information on pulling can be found [here](https://docs.docker.com/engine/reference/commandline/pull/).

## Pushing the docker image
You can push the official Headless Gamma image, named `ftsrggamma/headless-gamma` using this command:

    docker push ftsrggamma/headless-gamma:<tag number>
Keep in mind that in order to push the image, you have to:

 - be logged in
 - have access to the repository

Information on logging in can be found [here](https://docs.docker.com/engine/reference/commandline/login/). You can also read more on pushing [on this link](https://docs.docker.com/engine/reference/commandline/push/).

