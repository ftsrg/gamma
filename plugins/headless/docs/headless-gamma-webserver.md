## Headless Gamma - Web server API

This document presents how to 

 1. start the web server of the Headless Gamma
 2. use the requests and the API

 ## Webserver functioning
 This section details how the webserver functions.

Upon successfully starting the server, a green colored _"Headless Gamma OpenAPI server is running."_  message should appear.

The server periodically checks if there are operations running, and logs the process of requests received.

It is important to note that a workspace can have _only one_ instance of a project with the same name. To import a second version of the same project, it has to be renamed. There can be _only one_ operation running on a particular project at a given time.

## Webserver API

This section details the API used to communicatie with the webserver.

  - **POST**
	- **addProject** `/gamma/workspace/{workspace}/project` - Adds a project to the specified workspace. The request body is a multipart/form-data type body, which has a `file` field, where the zip file containing the project must be provided (examples of this can be found in the _Example: Workflow with Docker_ section). (Alternatively, in Postman, the file can be selected from the file system). The zip file must have the same name as the project. As an example, the `hu.bme.mit.gamma.test` project should be placed in `hu.bme.mit.gamma.test.zip`.
	- **getResult** `/gamma/workspace/{workspace}/project/{project}` - Gets specified files and folders from the project found in the given workspace and zips them. The files and/or folders should be specified as raw data in the request body, specifying the relative paths from the project root, as `files`. Example: `"files":["src-gen","test-gen","trace/ExecutionTrace0.get"]`. If the given file or folder does not exists, it will not appear in the zip file (the request doesn't throw an exception).
	- **addWorkspace** `/gamma/workspace` - Creates a workspace in the location specified in `config.properties`. Returns with the name (ID) of the workspace, which is used in further requests.
	-  **runCommand** `/gamma/workspace/{workspace}/project/{project}/run` - Starts an operation in the specified workspace and project, based on a `.ggen` file. The parameters are the following: 
		- `workspace` specifies the workspace,
		- `project` specifies the project, and
		- `filePath` specifies the path of the `.ggen` file found in the project. Note that `filePath` isn't a path parameter, and it should be specified in the request body, which is a multipart/form-data type body. The path in `filePath` should use  `/`  characters. Example: `model/test/Test.ggen`.
	- **stopProcess** `/gamma/workspace/{workspace}/project/{project}/stop` - Stops the currently ongoing process in the project found in the given workspace.
  - **PUT**
	 - **setLogLevel** `/gamma/loglevel` - Sets the verbosity of the logger for both the webserver and the Headless Gamma. The level should be set in the `level` field of the request body, as multipart/form-data request. The accepted levels are `Info`, `Warning`, `Severe` and `Off`. 
 - **GET**
	- **list** `/gamma/workspace/{workspace}/project/{project}` - Lists all files found in the project in the given workspace.
	- **status** `/gamma/workspace/{workspace}/project/{project}/status` -  Gets the status of the project in the given workspace. It returns with a simple text, indicating the status of the project: `Done`, `Ready` or `Failure`.
	- **getLogs** `/gamma/workspace/{workspace}/logs` - Retrieves the logs of a workspace. This can be saved as a text file.
 - **DELETE**
	- **deleteProject** `/gamma/workspace/{workspace}/project/{project}` Deletes the project from the project in the given workspace.
	- **deleteWorkspace** `/gamma/workspace/{workspace}` - Deletes the given workspace if it exists and is empty.
