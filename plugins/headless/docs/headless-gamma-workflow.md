# Headless Gamma service

This document details the usage of the Headless Gamma service, which allows the execution of `.ggen` files using a _webserver_ based on OpenAPI and an _exported headless Eclipse_. The service can be used via Docker. Alternatively, it is possible to manually export the headless Eclipse and start the webserver.

This feature uses two projects:

 - `hu.bme.mit.gamma.headless.api` - this application serves as the headless version of Gamma. It can create Eclipse workspaces, import projects from zip files, and execute .ggen files.
 - `hu.bme.mit.gamma.headless.server` - this webserver forwards requests to the Headless Gamma feature exported from `hu.bme.mit.gamma.headless.api`.

Note that this document serves as a high level description of the workflow.  A more detailed, technical documentation regarding the manual exporting of the features and the creation of Docker images can be found in the `docs` folder of the `hu.bme.mit.gamma.headless.api` project.

## Requirements

As mentioned before, the Headless Gamma service can be used either via Docker or by the manual exporting of the Gamma features.

- To use this feature via Docker, you have to have Docker installed on your computer, and download the image available [here](https://hub.docker.com/repository/docker/ftsrggamma/headless-gamma).

- To manually export Gamma, first create a functioning Eclipse with Gamma by following the process detailed [here](https://github.com/ftsrg/gamma/tree/master/plugins). Note that currently this feature uses the `dev` branch of Gamma.

## Workflow using Docker image

Start a container using the `ftsrggamma/headless-gamma` image. Use the image with the highest version number in the tag.

Upon starting the container, the webserver automatically starts, and requests can be sent. The container listens on port `8080`, so requests should be sent to `localhost:8080`.

Information about starting the Docker image properly can be found in the "docs" folder inside `hu.bme.mit.gamma.headless.api`.

## Workflow using manually exported Eclipse

This is an alternative way to use the Headless Gamma feature. 

To use this feature, Gamma has to be exported using the product file found in `hu.bme.mit.gamma.headless.api`. The whole process is detailed in the `docs` folder.

After exporting, the webserver has to be started. The server can be found in `hu.bme.mit.gamma.headless.server`.  In Eclipse, this can be done by right-clicking on the project, and selecting _Run As > Java Application_. Select `OpenApiWebServer` from the list of applications, and run.

Before running the server, make sure to configure the paths found in `config.properties`. (Note that the you don't have to set these variables if you have followed the instructions written in [Exporting the product](./headless-gamma-eclipse.md#step-4---exporting-the-product)).
- Set `headless.gamma.path` variable to the location of the exported `eclipse.exe` (or equivalent binary on Linux systems), and
- set the `root.of.workspaces.path` variable to the desired location of workspaces.

Alternatively, the server can be started from terminal using Maven commands. Navigate to the folder containing the `pom.xml` file and enter the `mvn package` command. After the process finishes, enter `mvn exec:java`, and the server should start.

Upon receiving a request, the server forwards it to the exported Gamma, which then performs the command. The processes are logged to the console of the server. Requests can be sent to `localhost:8080`.
		
 ## Example: Workflow with Docker
 This section presents the workflow using the Docker image. In this example, `hu.bme.mit.gamma.tests` is used as testing project. 
 
 - First, pull the correct version of the image from the previously mentioned link: `docker pull ftsrggamma/headless-gamma:1.1.0`. _Note: this is just an example version, for the correct functioning, please use the highest version available as tag._
 - Create a container from the image using this command:  `docker run -it -p 8080:8080 --name example_gamma_container ftsrggamma/headless-gamma:1.1.0` _Note: this is just an example version, for the correct functioning, please use the highest version available as tag. Naming the container isn't mandatory. The webserver listens on port 8080, but the host machine can use a different port to communicate._
 - After this, the server should be up in a few seconds. The server is running when the _"Headless Gamma OpenAPI server is running"_ message appears in the console.
 - Use the **addWorkspace** request to create a workspace in the container. The request will return with the ID of the workspace, which is used in other requests.
 - Zip the `hu.bme.mit.gamma.tests` project.
 - Use the **addProject** request to add the zipped `hu.bme.mit.gamma.tests` project to the workspace. Don't forget to add it as a file in the request body. In Postman, this option can be selected in the _Body > form-data_ tab when selecting the request. With cURL, it can be added like this: `--form 'file=@"<path to zip>"'`
 - Use the **runOperation** command to run the specified _.ggen_ file found in the uploaded `hu.bme.mit.gamma.tests` project.
 - Alternatively, the **addAndRun** command can be used to perform the previous two steps in one request  **Currently, due to unknown reasons, the addAndRun request doesn't function properly. Please refrain from using it.**.
 - To get the results, use the **getResult** request. Specify the folders and/or files to be delivered. In Postman, use the `Send and Download` option instead of `Send` when sending the request to download the result zip file.
 - If the process is taking too long or is unnecessary, send a **stopProcess** request to stop the operation on a specific project. *Note that sometimes, errors can occur in projects, causing the process to stop. The server does not always detect these problems, so the status of the project does not change from under operation. When this happens, use the **stopOperation** command, which will fix this.*
