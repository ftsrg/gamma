## Master Document for Headless Gamma

This document serves as a short introduction to _Headless Gamma_, a service that allows the usage of the _Gamma Statechart Composition Framework_ without an IDE. It consists of the following artifacts.
1. An _exported headless Eclipse_, which executes Gamma commands specified as `ggen` configuration files.
2. The commands are forwarded to the headless Eclipse via a _web server_.
3. Both artifacts are packed in a _Docker container_.​

There other documents found in the `docs` folder that detail the functions and parts of the Headless Gamma:​

 - [This document](docs/headless-gamma-eclipse.md) details how to export the headless Eclipse containing Gamma. It also mentions some notable errors which can occur.
 - [This document](docs/headless-gamma-docker.md)  details how to set up the Docker container on your own. Note that there is an [official Gamma Docker image](https://hub.docker.com/repository/docker/ftsrggamma/headless-gamma), which is recommended to be used.
 - [This document](docs/headless-gamma-webserver.md) presents the API of the Headless Gamma (notedly, the API of the web server via which the service is accessible).
 - [This document](docs/headless-gamma-workflow.md) presents a workflow using the Docker container, containing the assembled Headless Gamma service.
 
Required software for the entire workflow:
	 
 - Docker - a tutorial can be found [here](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-18-04).
 - The following packages can be installed on Ubuntu using the `apt-get install <package>` command:
	 - Java 17 - `openjdk-17-jdk`, `openjdk-17-jre`,
	 - SWT for exporting a headless Gamma - `libswt-gtk*`,
	 - Maven for building the webserver - `maven`.
 - Additionally, Postman or cURL (using the `curl` package) can be installed to test sending requests to the webserver.