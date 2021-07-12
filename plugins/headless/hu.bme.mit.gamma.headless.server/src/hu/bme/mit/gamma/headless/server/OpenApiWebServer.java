package hu.bme.mit.gamma.headless.server;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.FileHandler;
import java.util.logging.Handler;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.logging.SimpleFormatter;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.apache.commons.lang3.StringUtils;

import hu.bme.mit.gamma.headless.server.entity.WorkspaceProjectWrapper;
import hu.bme.mit.gamma.headless.server.service.ProcessBuilderCli;
import hu.bme.mit.gamma.headless.server.service.Provider;
import hu.bme.mit.gamma.headless.server.service.Validator;
import hu.bme.mit.gamma.headless.server.util.FileHandlerUtil;
import io.vertx.core.AbstractVerticle;
import io.vertx.core.Future;
import io.vertx.core.Promise;
import io.vertx.core.Vertx;
import io.vertx.core.http.HttpHeaders;
import io.vertx.core.http.HttpServer;
import io.vertx.core.http.HttpServerOptions;
import io.vertx.core.json.Json;
import io.vertx.core.json.JsonArray;
import io.vertx.core.json.JsonObject;
import io.vertx.ext.web.FileUpload;
import io.vertx.ext.web.Router;
import io.vertx.ext.web.RoutingContext;
import io.vertx.ext.web.handler.SessionHandler;
import io.vertx.ext.web.openapi.RouterBuilder;
import io.vertx.ext.web.sstore.LocalSessionStore;
import io.vertx.ext.web.validation.RequestParameters;

public class OpenApiWebServer extends AbstractVerticle {

	// These strings serve as static arguments
	private static final String APPLICATION_JSON = "application/json";
	private static final String MESSAGE = "message";
	private static final String WORKSPACE = "workspace";
	private static final String PARSED_PARAMETERS = "parsedParameters";
	private static final String PROJECT_NAME = "project";
	HttpServer server;
	private static final String DIRECTORY_OF_WORKSPACES_PROPERTY_NAME = "root.of.workspaces.path";
	private static final String DIRECTORY_OF_LOGGER_OUTPUT_FILE = "logger.output.directory";
	// Coloring for the messages on consoles. Doesn't work in the Eclipse console.
	private static final String ANSI_RESET = "\u001B[0m";
	private static final String ANSI_GREEN = "\u001B[32m";
	private static final String ANSI_RED = "\u001B[31m";
	private static final String ANSI_YELLOW = "\u001B[33m";

	private static boolean loggingToFile = false;

	protected static Logger logger = Logger.getLogger("GammaLogger");

	@Override
	public void start(Promise<Void> future) {
		// The web server creates the API using the gamma-wrapper.yaml found in the
		// "resources" folder
		// To create a new request, it has to be written here, and added to the
		// gamma-wrapper.yaml
		RouterBuilder.create(this.vertx, "gamma-wrapper.yaml", ar -> {
			SessionHandler sessionHandler = SessionHandler.create(LocalSessionStore.create(vertx));

			RouterBuilder routerFactory;
			if (ar.succeeded()) {
				routerFactory = ar.result();
				routerFactory.createRouter().route().handler(sessionHandler);

				// Runs a .ggen file
				routerFactory.operation("runOperation").handler(routingContext -> {

					logger.log(Level.INFO, ANSI_YELLOW + "Operation \"runOperation\" has started." + ANSI_RESET);

					ErrorHandlerPOJO errorHandlerPOJO = null;
					// Getting parameters from path and request body
					RequestParameters params = routingContext.get(PARSED_PARAMETERS);
					String projectName = params.pathParameter(PROJECT_NAME).getString();
					String workspace = params.pathParameter(WORKSPACE).getString();
					String filePath = routingContext.request().formAttributes().get("ggenPath");
					boolean success = false;
					try {
						errorHandlerPOJO = getErrorObject(workspace, projectName);
						if (errorHandlerPOJO.getErrorObject() == null) {
							success = true;
							// Passing the parameters to the CLI, so the operation can be started
							ProcessBuilderCli.runGammaOperations(projectName, workspace, filePath);
							logger.log(Level.INFO,
									ANSI_YELLOW + "Operation \"runOperation\": parameters passed to CLI." + ANSI_RESET);
						}
					} catch (IOException e) {
						e.printStackTrace();
					}
					if (success) {
						// If it succeeds, the response is 200
						routingContext.response().setStatusCode(200)
								.putHeader(HttpHeaders.CONTENT_TYPE, APPLICATION_JSON).end();
					} else {
						sendErrorResponse(routingContext, errorHandlerPOJO);
					}
				});

				// Gets files from a project
				routerFactory.operation("getResult").handler(routingContext -> {
					logger.log(Level.INFO, ANSI_YELLOW + "Operation \"getResult\" has started." + ANSI_RESET);

					ErrorHandlerPOJO errorHandlerPOJO = null;
					String zipPath = null;
					// Getting parameters from path and request body
					RequestParameters params = routingContext.get(PARSED_PARAMETERS);
					String projectName = params.pathParameter(PROJECT_NAME).getString();
					String workspace = params.pathParameter(WORKSPACE).getString();
					JsonObject json = routingContext.getBodyAsJson();
					JsonArray jsonArray = json.getJsonArray("files");

					boolean success = false;
					try {
						errorHandlerPOJO = getErrorObject(workspace, projectName);
						if (errorHandlerPOJO.getErrorObject() == null) {
							success = true;
							// Passing it to the provider, which creates a zip file
							zipPath = Provider.getResultZipFilePath(jsonArray, FileHandlerUtil
									.getProperty(DIRECTORY_OF_WORKSPACES_PROPERTY_NAME).concat(workspace), projectName);
							logger.log(Level.INFO,
									ANSI_YELLOW + "Operation \"getResult\": results zipped successfully." + ANSI_RESET);
						}
					} catch (IOException e) {
						e.printStackTrace();
					}
					if (success && zipPath != null) {
						// Sending that zip file back as response
						routingContext.response().setStatusCode(200)
								.putHeader(HttpHeaders.CONTENT_TYPE, "application/zip").sendFile(zipPath);
					} else {
						sendErrorResponse(routingContext, errorHandlerPOJO);
					}
				});

				// Gets the log file from a workspace
				routerFactory.operation("getLogs").handler(routingContext -> {

					logger.log(Level.INFO, ANSI_YELLOW + "Operation \"getLogs\" has started." + ANSI_RESET);

					// Getting parameters from path
					RequestParameters params = routingContext.get(PARSED_PARAMETERS);
					String workspace = params.pathParameter(WORKSPACE).getString();
					// Path of the log file
					String logPath = FileHandlerUtil.getProperty(DIRECTORY_OF_WORKSPACES_PROPERTY_NAME) + File.separator
							+ workspace + File.separator + ".metadata" + File.separator + ".log";
					boolean success = false;
					if (!loggingToFile) {
						try {
							// Getting the log file
							FileInputStream inputLog = new FileInputStream(logPath);
							inputLog.close();
							success = true;
						} catch (IOException e) {
							e.printStackTrace();
						}
					} else {
						JsonObject errorObject = new JsonObject().put("code", 403).put(MESSAGE,
								"Please disable logging to file before requesting the log.");
						routingContext.response().setStatusCode(403)
								.putHeader(HttpHeaders.CONTENT_TYPE, APPLICATION_JSON).end(errorObject.encode());
					}

					if (success) {
						// Sending the log file back as response
						routingContext.response().setStatusCode(200).putHeader(HttpHeaders.CONTENT_TYPE, "text/plain")
								.sendFile(logPath);
					} else {
						JsonObject errorObject = new JsonObject().put("code", 404).put(MESSAGE,
								"The log file requested does not exist.");
						routingContext.response().setStatusCode(404)
								.putHeader(HttpHeaders.CONTENT_TYPE, APPLICATION_JSON).end(errorObject.encode());
					}

				});

				// Adds a project to a workspace, which is uploaded as a zip in the form body
				routerFactory.operation("addProject").handler(routingContext -> {

					logger.log(Level.INFO, ANSI_YELLOW + "Operation \"addProject\" has started." + ANSI_RESET);
					// Getting parameters from path
					RequestParameters params = routingContext.get(PARSED_PARAMETERS);
					String workspace = params.pathParameter(WORKSPACE).getString();
					boolean success = true;
					for (FileUpload f : routingContext.fileUploads()) {
						try {
							// Checks whether the project already exists in the workspace or not
							if (!Validator.checkIfWorkspaceExists(workspace) || f.size() == 0
									|| Validator.checkIfProjectAlreadyExistsUnderWorkspace(workspace,
											f.fileName().substring(0, f.fileName().lastIndexOf(".")))) {
								success = false;
							} else {
								// Moves the uploaded zip to the workspace, and unzips it
								Files.move(Paths.get(f.uploadedFileName()),
										Paths.get(FileHandlerUtil.getProperty(DIRECTORY_OF_WORKSPACES_PROPERTY_NAME)
												+ workspace + File.separator + f.fileName()));
								String projectName = f.fileName().substring(0, f.fileName().lastIndexOf("."));
								// Creates an Eclipse project based on the uploaded file
								ProcessBuilderCli.createEclipseProject(projectName, workspace);
								logger.log(Level.INFO, ANSI_YELLOW
										+ "Operation \"addProject\": parameters passed to CLI." + ANSI_RESET);
							}
						} catch (IOException | InterruptedException e) {
							e.printStackTrace();
						}
					}
					if (success) {
						routingContext.response().end();
					} else {
						JsonObject errorObject = new JsonObject().put("code", 400).put(MESSAGE,
								"Project already exists under this workspace, delete it and resend this request or did not provide a valid workspace");
						routingContext.response().setStatusCode(400)
								.putHeader(HttpHeaders.CONTENT_TYPE, APPLICATION_JSON).end(errorObject.encode());
					}
				});

				// Creates a workspace, returns its unique ID
				routerFactory.operation("addWorkspace").handler(routingContext -> {

					logger.log(Level.INFO, ANSI_YELLOW + "Operation \"addWorkspace\" has started." + ANSI_RESET);

					String workspaceUUID = "";
					try {
						// Creates the workspace
						workspaceUUID = ProcessBuilderCli.createWorkspaceForUser();
						logger.log(Level.INFO,
								ANSI_YELLOW + "Operation \"addWorkspace\": parameters passed to CLI." + ANSI_RESET);
					} catch (IOException | InterruptedException e) {
						e.printStackTrace();
					}
					if (StringUtils.isEmpty(workspaceUUID)) {
						routingContext.response().setStatusCode(500).end();
					} else {
						// Returns the workspace ID as response
						routingContext.response().setStatusCode(200)
								.putHeader(HttpHeaders.CONTENT_TYPE, APPLICATION_JSON).end(Json.encode(workspaceUUID));
					}
				});

				// Stops an active operation in a workspace + project pair
				routerFactory.operation("stopOperation").handler(routingContext -> {

					logger.log(Level.INFO, ANSI_YELLOW + "Operation \"stopOperation\" has started." + ANSI_RESET);

					ErrorHandlerPOJO errorHandlerPOJO = null;
					// Getting parameters from path
					RequestParameters params = routingContext.get(PARSED_PARAMETERS);
					String workspace = params.pathParameter(WORKSPACE).getString();
					String projectName = params.pathParameter(PROJECT_NAME).getString();
					boolean success = false;
					try {
						errorHandlerPOJO = getErrorObject(workspace, projectName);
						if (errorHandlerPOJO.getStatusCode() == 503) {
							// Passes the workspace + project pair to the CLI, which stops the process
							ProcessBuilderCli.stopOperation(projectName, workspace);
							logger.log(Level.INFO, ANSI_YELLOW
									+ "Operation \"stopOperation\": parameters passed to CLI." + ANSI_RESET);
							success = true;
						}
					} catch (IOException e) {
						e.printStackTrace();
					}
					if (success) {
						routingContext.response().setStatusCode(200)
								.putHeader(HttpHeaders.CONTENT_TYPE, APPLICATION_JSON).end();
					} else {
						sendErrorResponse(routingContext, errorHandlerPOJO);
					}
				});

				// Deletes a project from a given workspace
				routerFactory.operation("deleteProject").handler(routingContext -> {

					logger.log(Level.INFO, ANSI_YELLOW + "Operation \"deleteProject\" has started." + ANSI_RESET);

					ErrorHandlerPOJO errorHandlerPOJO = null;
					// Getting parameters from path
					RequestParameters params = routingContext.get(PARSED_PARAMETERS);
					String projectName = params.pathParameter(PROJECT_NAME).getString();
					String workspace = params.pathParameter(WORKSPACE).getString();

					boolean success = false;
					try {
						errorHandlerPOJO = getErrorObject(workspace, projectName);
						if (errorHandlerPOJO.getErrorObject() == null) {
							success = true;
							// Passes the parameters to the provider, which deletes the project
							Provider.deleteProject(workspace, projectName);
						}
					} catch (IOException e) {
						e.printStackTrace();
					}
					if (success) {
						routingContext.response().setStatusCode(200)
								.putHeader(HttpHeaders.CONTENT_TYPE, APPLICATION_JSON).end();
					} else {
						sendErrorResponse(routingContext, errorHandlerPOJO);
					}
				});

				// Deletes a workspace, if its empty
				routerFactory.operation("deleteWorkspace").handler(routingContext -> {

					logger.log(Level.INFO, ANSI_YELLOW + "Operation \"deleteWorkspace\" has started." + ANSI_RESET);
					// Getting parameters from path
					RequestParameters params = routingContext.get(PARSED_PARAMETERS);
					String workspace = params.pathParameter(WORKSPACE).getString();
					// If the workspace can be deleted, it is deleted, and the result is stored in
					// the "success" variable
					boolean success = Provider.deleteWorkspace(workspace);

					if (success) {
						routingContext.response().setStatusCode(200)
								.putHeader(HttpHeaders.CONTENT_TYPE, APPLICATION_JSON).end();
					} else {
						JsonObject errorObject = new JsonObject().put("code", 400).put(MESSAGE,
								"Workspace can't be deleted. Make sure that the workspace exists, and that it is empty.");
						routingContext.response().setStatusCode(400)
								.putHeader(HttpHeaders.CONTENT_TYPE, APPLICATION_JSON).end(errorObject.encode());
					}
				});

				// Gets the status of a workspace + project pair
				routerFactory.operation("getStatus").handler(routingContext -> {

					logger.log(Level.INFO, ANSI_YELLOW + "Operation \"getStatus\" has started." + ANSI_RESET);

					// Getting parameters from path
					RequestParameters params = routingContext.get(PARSED_PARAMETERS);
					String projectName = params.pathParameter(PROJECT_NAME).getString();
					String workspace = params.pathParameter(WORKSPACE).getString();
					StatusResponsePOJO returnedResult = null;
					try {
						// Checks if the project is under load in the given workspace

						if (Validator.checkIfProjectHasRunIntoError(workspace, projectName)) {
							returnedResult = new StatusResponsePOJO(Status.Failure);
						} else {
							if (Validator.checkIfProjectIsUnderLoad(workspace, projectName)) {
								returnedResult = new StatusResponsePOJO(Status.Running);
							} else {
								returnedResult = new StatusResponsePOJO(Status.Done);
							}
						}

					} catch (IOException e) {
						e.printStackTrace();
					}
					JsonObject returnedJson = JsonObject.mapFrom(returnedResult);
					routingContext.response().setStatusCode(200).putHeader(HttpHeaders.CONTENT_TYPE, "application/json")
							.end(Json.encode(returnedJson));
				});

				// Adds a project to a workspace and executes a command
				// TODO: this request currently doesn't work
//				routerFactory.operation("addAndRun").handler(routingContext -> {
//
//					logger.log(Level.INFO, ANSI_YELLOW + "Operation \"addAndRun\" has started." + ANSI_RESET);
//
//					ErrorHandlerPOJO errorHandlerPOJO = null;
//					// Getting parameters from path and request body
//					RequestParameters params = routingContext.get(PARSED_PARAMETERS);
//					String ggenPath = routingContext.request().formAttributes().get("ggenPath");
//					String workspace = params.pathParameter(WORKSPACE).getString();
//					String fileName = "";
//					boolean successUpload = true;
//					boolean successGgen = false;
//					for (FileUpload f : routingContext.fileUploads()) {
//						fileName = f.fileName().replace(".zip", "");
//						try {
//							// Checking if the project exists in the workspace, and whether the workspace
//							// exists or not
//							if (!Validator.checkIfWorkspaceExists(workspace) || f.size() == 0
//									|| Validator.checkIfProjectAlreadyExistsUnderWorkspace(workspace,
//											f.fileName().substring(0, f.fileName().lastIndexOf(".")))) {
//								successUpload = false;
//							} else {
//								// Moves the uploaded file to the workspace and unzips it
//								Files.move(Paths.get(f.uploadedFileName()),
//										Paths.get(FileHandlerUtil.getProperty(DIRECTORY_OF_WORKSPACES_PROPERTY_NAME)
//												+ workspace + File.separator + f.fileName()));
//								String projectName = f.fileName().substring(0, f.fileName().lastIndexOf("."));
//								// Creates an Eclipse project based on the uploaded file
//								ProcessBuilderCli.createEclipseProject(projectName, workspace);
//
//								logger.log(Level.INFO, ANSI_YELLOW
//										+ "Operation \"addAndRun\": parameters passed to CLI, importing project. "
//										+ ANSI_RESET);
//							}
//						} catch (IOException | InterruptedException e) {
//							e.printStackTrace();
//						}
//					}
//
//					try {
//						errorHandlerPOJO = getErrorObject(workspace, fileName);
//						if (errorHandlerPOJO.getErrorObject() == null) {
//							successGgen = true;
//							// Passes the .ggen file path to the CLI, which starts the operation
//							ProcessBuilderCli.runGammaOperations(fileName, workspace,
//									ggenPath.replace("/", File.separator));
//							logger.log(Level.INFO, ANSI_YELLOW
//									+ "Operation \"addAndRund\": parameters passed to CLI, running ggen." + ANSI_RESET);
//						}
//					} catch (IOException e) {
//						e.printStackTrace();
//					}
//
//					if (successGgen && successUpload) {
//						routingContext.response().setStatusCode(200)
//								.putHeader(HttpHeaders.CONTENT_TYPE, APPLICATION_JSON).end();
//					} else {
//						JsonObject errorObject = new JsonObject().put("code", 400).put(MESSAGE,
//								"Project already exists under this workspace, delete it and resend this request or did not provide a valid workspace");
//						routingContext.response().setStatusCode(400)
//								.putHeader(HttpHeaders.CONTENT_TYPE, APPLICATION_JSON).end(errorObject.encode());
//					}
//				});

				// Lists all files found in a workspace + project pair
				routerFactory.operation("list").handler(routingContext -> {

					logger.log(Level.INFO, ANSI_YELLOW + "Operation \"list\" has started." + ANSI_RESET);

					ErrorHandlerPOJO errorHandlerPOJO = null;
					RequestParameters params = routingContext.get(PARSED_PARAMETERS);
					String projectName = params.pathParameter(PROJECT_NAME).getString();
					String workspace = params.pathParameter(WORKSPACE).getString();
					List<String> result = new ArrayList<String>();
					String returnedResult = "";
					boolean success = false;
					try {
						errorHandlerPOJO = getErrorObject(workspace, projectName);
						if (errorHandlerPOJO.getErrorObject() == null) {
							success = true;
							try (Stream<Path> walk = Files
									.walk(Paths.get(FileHandlerUtil.getProperty(DIRECTORY_OF_WORKSPACES_PROPERTY_NAME)
											+ workspace + File.separator + projectName))) {
								// We want to find only regular files
								result = walk.filter(Files::isRegularFile).map(x -> x.toString())
										.collect(Collectors.toList());
								for (int i = 0; i < result.size(); i++) {
									returnedResult = returnedResult + result.get(i) + "\n";
								}
							} catch (IOException e) {
								success = false;
								e.printStackTrace();
							}
						}
					} catch (IOException e) {
						e.printStackTrace();
					}

					if (success) {
						routingContext.response().setStatusCode(200)
								.putHeader(HttpHeaders.CONTENT_TYPE, APPLICATION_JSON).end(returnedResult);
					} else {
						sendErrorResponse(routingContext, errorHandlerPOJO);
					}
				});

				// Sets the log level for both the web server and the Headless Gamma
				routerFactory.operation("setLogLevel").handler(routingContext -> {

					logger.log(Level.INFO, ANSI_YELLOW + "Operation \"setLogLevel\" has started." + ANSI_RESET);

					RequestParameters params = routingContext.get(PARSED_PARAMETERS);
					String logLevel = routingContext.request().formAttributes().get("level");

					switch (logLevel.toLowerCase()) {
					case "info":
						logger.setLevel(Level.INFO);
						ProcessBuilderCli.setProcessCliLogLevel(logLevel);
						break;
					case "warning":
						logger.setLevel(Level.WARNING);
						ProcessBuilderCli.setProcessCliLogLevel(logLevel);
						break;
					case "severe":
						logger.setLevel(Level.SEVERE);
						ProcessBuilderCli.setProcessCliLogLevel(logLevel);
						break;
					case "off":
						logger.setLevel(Level.OFF);
						ProcessBuilderCli.setProcessCliLogLevel(logLevel);
						break;
					default:
						JsonObject errorObject = new JsonObject().put("code", 400).put(MESSAGE,
								"The provided log level was incorrect. The following levels are accepted: \"info\", \"warning\", \"severe\" and \"off\". ");
						routingContext.response().setStatusCode(400)
								.putHeader(HttpHeaders.CONTENT_TYPE, APPLICATION_JSON).end(errorObject.encode());
						return;
					}
					routingContext.response().setStatusCode(200).putHeader(HttpHeaders.CONTENT_TYPE, APPLICATION_JSON)
							.end("Logger level successfully set to: " + logLevel);

				});

				routerFactory.operation("logToFile").handler(routingContext -> {

					logger.log(Level.INFO, ANSI_YELLOW + "Operation \"logToFile\" has started." + ANSI_RESET);

					if (!loggingToFile) {
						loggingToFile = true;

						FileHandler fileHandler = null;
						try {
							fileHandler = new FileHandler(FileHandlerUtil.getProperty(DIRECTORY_OF_LOGGER_OUTPUT_FILE));
						} catch (SecurityException | IOException e1) {
							e1.printStackTrace();
						}

						logger.addHandler(fileHandler);
						SimpleFormatter simpleFormatter = new SimpleFormatter();
						fileHandler.setFormatter(simpleFormatter);

						routingContext.response().setStatusCode(200)
								.putHeader(HttpHeaders.CONTENT_TYPE, APPLICATION_JSON).end("Logging to file enabled.");
						return;
					}
					if (loggingToFile) {
						loggingToFile = false;
						for (Handler handler : logger.getHandlers()) {
							handler.close();
							logger.removeHandler(handler);
						}
						routingContext.response().setStatusCode(200)
								.putHeader(HttpHeaders.CONTENT_TYPE, APPLICATION_JSON).end("Logging to file disabled.");
						return;
					}

				});

				routerFactory.operation("getHeadlessLogs").handler(routingContext -> {

					logger.log(Level.INFO, ANSI_YELLOW + "Operation \"getHeadlessLogs\" has started." + ANSI_RESET);

					// Path of the headless console output log file
					String logPath = FileHandlerUtil.getProperty(DIRECTORY_OF_LOGGER_OUTPUT_FILE);
					boolean success = false;
					try {
						// Getting the log file
						FileInputStream inputLog = new FileInputStream(logPath);
						inputLog.close();
						success = true;
					} catch (IOException e) {
						e.printStackTrace();
					}

					if (success) {
						// Sending the log file back as response
						routingContext.response().setStatusCode(200).putHeader(HttpHeaders.CONTENT_TYPE, "text/plain")
								.sendFile(logPath);
					} else {
						JsonObject errorObject = new JsonObject().put("code", 404).put(MESSAGE,
								"The log file requested does not exist.");
						routingContext.response().setStatusCode(404)
								.putHeader(HttpHeaders.CONTENT_TYPE, APPLICATION_JSON).end(errorObject.encode());
					}

				});

				Router router = routerFactory.createRouter();

				router.errorHandler(404, routingContext -> {
					JsonObject errorObject = new JsonObject().put("code", 404).put(MESSAGE,
							(routingContext.failure() != null) ? routingContext.failure().getMessage() : "Not Found");
					routingContext.response().setStatusCode(404).putHeader(HttpHeaders.CONTENT_TYPE, APPLICATION_JSON)
							.end(errorObject.encode());
				});

				server = vertx.createHttpServer(new HttpServerOptions().setPort(8080).setHost("localhost"));
				server.exceptionHandler(exp -> {
					logger.log(Level.SEVERE, "Unexpected error in Headless Gamma Webserver");
					router.errorHandler(500, x -> {
						x.response().setStatusCode(500).putHeader(HttpHeaders.CONTENT_TYPE, APPLICATION_JSON)
								.end("Unexpected error in Headless Gamma Webserver");
					});
				});
				server.requestHandler(x -> {
					router.handle(x);
				}).listen(8080);

				future.complete();
			} else {
				future.fail(ar.cause());
			}
		});
	}

	// Creates and error response for more common errors related to workspaces and
	// projects
	private ErrorHandlerPOJO getErrorObject(String workspace, String projectName) throws IOException {
		ErrorHandlerPOJO errorHandlerPOJO = new ErrorHandlerPOJO(null, 0);
		JsonObject errorObject;

		if (!Validator.checkIfProjectAlreadyExistsUnderWorkspace(workspace, projectName)) { // Sent if the project
																							// already exists under the
																							// workspace
			errorObject = new JsonObject().put("code", 404).put(MESSAGE,
					"Project " + projectName + " does not exists under this workspace!");
			errorHandlerPOJO.setStatusCode(404);
			errorHandlerPOJO.setErrorObject(errorObject);
		} else if (Validator.checkIfProjectIsUnderLoad(workspace, projectName)) { // Sent if the project is undergoing
																					// an operation
			errorObject = new JsonObject().put("code", 503).put(MESSAGE,
					"There is an in progress operation on this project, try again later!");
			errorHandlerPOJO.setStatusCode(503);
			errorHandlerPOJO.setErrorObject(errorObject);
		}
		return errorHandlerPOJO;
	}

	// Sends a given error response
	private void sendErrorResponse(RoutingContext routingContext, ErrorHandlerPOJO errorHandlerPOJO) {
		routingContext.response().setStatusCode(errorHandlerPOJO.getStatusCode())
				.putHeader(HttpHeaders.CONTENT_TYPE, APPLICATION_JSON).end(errorHandlerPOJO.getErrorObject().encode());
	}

	// Used to periodically list workspaces and projects that are undergoing an
	// operation
	private static void listWorkspacesAndProjects() throws IOException {
		if (FileHandlerUtil.getWrapperListFromJson() != null) {
			List<WorkspaceProjectWrapper> yourList = FileHandlerUtil.getWrapperListFromJson();
			logger.log(Level.INFO, System.lineSeparator() + "Currently ongoing operations: ");
			boolean noOp = true;
			for (int i = 0; i < yourList.size(); i++) {
				if (yourList.get(i).getProjectName() != null) {
					if (Validator.checkIfProjectIsUnderLoad(yourList.get(i).getWorkspace(),
							yourList.get(i).getProjectName())) {
						if (noOp) {
							noOp = false;
						}
						logger.log(Level.INFO, '\t' + "Workspace: " + yourList.get(i).getWorkspace() + " Project: "
								+ yourList.get(i).getProjectName());
					}
				}
			}
			if (noOp) {
				logger.log(Level.INFO, '\t' + "none");
			}
		} else {
			logger.log(Level.INFO, "No workspaces are present.");
		}
	}

	@Override
	public void stop() {
		this.server.close();
	}

	// Starts the server and the periodic listing of projects and workspaces
	// undergoing operation
	public static void main(String[] args) {
		Vertx vertx = Vertx.vertx();
		vertx.setPeriodic(10000, aLong -> {
			try {
				listWorkspacesAndProjects();
			} catch (IOException e) {
				e.printStackTrace();
			}
		});
		vertx.deployVerticle(new OpenApiWebServer(), ar -> {
			if (ar.succeeded()) {
				logger.log(Level.INFO, ANSI_GREEN + "Headless Gamma OpenAPI server is running." + ANSI_RESET);

			} else {
				logger.log(Level.INFO, ANSI_RED + "Headless Gamma OpenAPI server failed to start." + ANSI_RESET);
				Future.failedFuture(ar.cause());
			}
		});
	}

	// Error handler object that gets sent as response
	public class ErrorHandlerPOJO {
		int statusCode;
		JsonObject errorObject;

		public ErrorHandlerPOJO(JsonObject errorObject, int statusCode) {
			this.errorObject = errorObject;
			this.statusCode = statusCode;
		}

		public JsonObject getErrorObject() {
			return errorObject;
		}

		public void setErrorObject(JsonObject errorObject) {
			this.errorObject = errorObject;
		}

		public int getStatusCode() {
			return statusCode;
		}

		public void setStatusCode(int statusCode) {
			this.statusCode = statusCode;
		}

	}

	enum Status {
		Done, Running, Failure
	}

	public class StatusResponsePOJO {
		Status operationStatus;

		public StatusResponsePOJO(Status operationStatus) {
			this.operationStatus = operationStatus;
		}

		public Status getStatus() {
			return operationStatus;
		}

		public void setStatus(Status operationStatus) {
			this.operationStatus = operationStatus;
		}
	}

}
