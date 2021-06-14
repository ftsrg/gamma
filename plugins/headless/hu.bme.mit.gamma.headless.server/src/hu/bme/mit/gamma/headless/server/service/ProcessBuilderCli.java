package hu.bme.mit.gamma.headless.server.service;

import com.google.gson.*;
import hu.bme.mit.gamma.headless.server.entity.WorkspaceProjectWrapper;
import org.apache.commons.io.FileUtils;
import org.apache.commons.lang3.SystemUtils;
import org.joda.time.DateTime;
import org.json.simple.JSONObject;
import hu.bme.mit.gamma.headless.server.util.FileHandlerUtil;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.UUID;
import java.util.logging.Level;

public class ProcessBuilderCli {

	private static final String DIRECTORY_OF_WORKSPACES_PROPERTY_NAME = "root.of.workspaces.path";

	private static final String DIRECTORY_OF_GAMMA_HEADLESS_ECLIPSE_PROPERTY = "headless.gamma.path";
	private static final String CONSTANT_ARGUMENTS = " -consoleLog -data ";
	public static final String PROJECT_DESCRIPTOR_JSON = "projectDescriptor.json";
	private static final String ROOT_WRAPPER_JSON = "wrapperList.json";
	public static final String UNDER_OPERATION_PROPERTY = "underOperation";
	private static final String PID_OPERATION_PROPERTY = "pid";
	private static final String GAMMA_OPERATION = "gamma";
	private static final String IMPORT_OPERATION = "import";
	private static final String WORKSPACE_OPERATION = "workspace";
	
	private static String logLevel = "info";

	public static void runGammaOperations(String projectName, String workspace, String filePath) throws IOException {

		ProcessBuilder pb = new ProcessBuilder(
				FileHandlerUtil.getProperty(DIRECTORY_OF_GAMMA_HEADLESS_ECLIPSE_PROPERTY), "-consoleLog", "-data",
				FileHandlerUtil.getProperty(DIRECTORY_OF_WORKSPACES_PROPERTY_NAME) + workspace, GAMMA_OPERATION, logLevel, 
				getFullFilePath(filePath, workspace, projectName),
				FileHandlerUtil.getProperty(DIRECTORY_OF_WORKSPACES_PROPERTY_NAME) + workspace + File.separator
						+ projectName + File.separator + PROJECT_DESCRIPTOR_JSON);
		pb.redirectErrorStream(true);
		pb.inheritIO();
		updateUnderOperationStatus(projectName, workspace, true, (int) pb.start().pid());
	}

	public static void stopOperation(String projectName, String workspace) throws IOException {
		int pid = FileHandlerUtil.getPid(workspace, projectName);
		if (Validator.isValidPid(pid)) {
			String cmd = "";
			if (SystemUtils.IS_OS_WINDOWS) {
				cmd = "taskkill /F /T /PID " + pid;
			} else {
				cmd = "pkill -P " + pid;
			}
			Runtime.getRuntime().exec(cmd);
		}
		updateUnderOperationStatus(projectName, workspace, false, 0);
	}

	private static String getFullFilePath(String filePath, String workspace, String projectName) {
		return FileHandlerUtil.getProperty(DIRECTORY_OF_WORKSPACES_PROPERTY_NAME) + workspace + File.separator
				+ projectName + File.separator + filePath;
	}

	private static void updateUnderOperationStatus(String projectName, String workspace, Boolean status, int pid)
			throws IOException {
		File jsonFile = new File(FileHandlerUtil.getProperty(DIRECTORY_OF_WORKSPACES_PROPERTY_NAME) + workspace
				+ File.separator + projectName + File.separator + PROJECT_DESCRIPTOR_JSON);
		String jsonString = FileUtils.readFileToString(jsonFile);
		JsonElement jElement = new JsonParser().parse(jsonString);
		JsonObject jObject = jElement.getAsJsonObject();
		jObject.remove(UNDER_OPERATION_PROPERTY);
		jObject.addProperty(UNDER_OPERATION_PROPERTY, status);
		jObject.remove(PID_OPERATION_PROPERTY);
		jObject.addProperty(PID_OPERATION_PROPERTY, pid);
		Gson gson = new Gson();
		String resultingJson = gson.toJson(jElement);
		FileUtils.writeStringToFile(jsonFile, resultingJson);
	}

	private static void createProjectJSONFile(String workspace, String projectName, String ownerContact) {
		JSONObject jsonObject = new JSONObject();
		Date today = new Date();
		DateTime dtOrg = new DateTime(today);
		DateTime expirationDate = dtOrg.plusDays(30);

		jsonObject.put("projectName", projectName);
		jsonObject.put("owner", ownerContact);
		jsonObject.put("creationDate", today.getTime());
		jsonObject.put("expirationDate", expirationDate.toDate().getTime());
		jsonObject.put(PID_OPERATION_PROPERTY, 0);
		jsonObject.put(UNDER_OPERATION_PROPERTY, false);

		try {
			FileWriter file = new FileWriter(FileHandlerUtil.getProperty(DIRECTORY_OF_WORKSPACES_PROPERTY_NAME)
					+ workspace + File.separator + projectName + File.separator + PROJECT_DESCRIPTOR_JSON);
			file.write(jsonObject.toJSONString());
			file.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	public static void createEclipseProject(String projectName, String workspace, String ownerContact)
			throws IOException, InterruptedException {
		String commandToExecute = FileHandlerUtil.getProperty(DIRECTORY_OF_GAMMA_HEADLESS_ECLIPSE_PROPERTY)
				+ CONSTANT_ARGUMENTS + FileHandlerUtil.getProperty(DIRECTORY_OF_WORKSPACES_PROPERTY_NAME) + workspace
				+ " " + IMPORT_OPERATION + " " + logLevel + " " + projectName;
		Runtime rt = Runtime.getRuntime();
		Process pr = rt.exec(commandToExecute);
		pr.waitFor();
		addWorkspaceProjectWrapperToRootJson(projectName, workspace);
		createProjectJSONFile(workspace, projectName, ownerContact);
		deleteSourceZip(workspace, projectName);
	}

	public static String createWorkspaceForUser() throws IOException, InterruptedException {
		String workspace = String.valueOf(UUID.randomUUID());
		String commandToExecute = FileHandlerUtil.getProperty(DIRECTORY_OF_GAMMA_HEADLESS_ECLIPSE_PROPERTY)
				+ CONSTANT_ARGUMENTS + FileHandlerUtil.getProperty(DIRECTORY_OF_WORKSPACES_PROPERTY_NAME) + workspace
				+ " " + WORKSPACE_OPERATION + " " + logLevel;
		Runtime rt = Runtime.getRuntime();
		Process pr = rt.exec(commandToExecute);
		pr.waitFor();
		addWorkspaceProjectWrapperToRootJson(null, workspace);
		return workspace;
	}

	private static void addWorkspaceProjectWrapperToRootJson(String projectName, String workspace) throws IOException {
		List<WorkspaceProjectWrapper> yourList = FileHandlerUtil.getWrapperListFromJson();
		if (yourList == null) {
			yourList = new ArrayList<>();
		}
		yourList.add(new WorkspaceProjectWrapper(workspace, projectName));
		try {
			FileWriter writer = new FileWriter(
					FileHandlerUtil.getProperty(DIRECTORY_OF_WORKSPACES_PROPERTY_NAME) + ROOT_WRAPPER_JSON);
			new Gson().toJson(yourList, writer);
			writer.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	private static void deleteSourceZip(String workspace, String projectName) {
		File sourceZip = new File(FileHandlerUtil.getProperty(DIRECTORY_OF_WORKSPACES_PROPERTY_NAME) + workspace
				+ File.separator + projectName + ".zip");
		if (sourceZip.exists()) {
			try {
				Files.delete(Paths.get(sourceZip.getPath()));
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
	}
	
	public static void setProcessCliLogLevel(Level level) {
		if(level == Level.INFO) {
			logLevel = "info";
		} else if (level == Level.WARNING) {
			logLevel = "warning";
		} else if (level == Level.SEVERE) {
			logLevel = "severe";
		} else if (level == Level.OFF) {
			logLevel = "off";
		}
	}
}
