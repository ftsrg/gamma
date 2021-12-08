package hu.bme.mit.gamma.headless.server.util;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

import org.apache.commons.io.FileUtils;

import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

// Contains functions that are used for file and process handling
public class FileHandlerUtil {
	private static final String DIRECTORY_OF_WORKSPACES_PROPERTY_NAME = "root.of.workspaces.path";
	public static final String PROJECT_DESCRIPTOR_JSON = "projectDescriptor.json";
	protected static Logger logger = Logger.getLogger("GammaLogger");
	
	public static Map<String, Set<String>> getProjectsByWorkspaces(){
		File workspacesFolder = new File(getProperty(DIRECTORY_OF_WORKSPACES_PROPERTY_NAME));
		List<File> workspaces = Arrays.asList(workspacesFolder.listFiles(DirectoryFilter.INSTANCE));
		return workspaces.stream().map(workspace -> {
			Set<String> projects = Arrays.asList(workspace
					.listFiles(EclipseProjectFilter.INSTANCE))
					.stream()
					.map(File::getName)
					.collect(Collectors.toSet());
			return Map.entry(workspace.getName(), projects);
		}).collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));
	}

	// Gets the PID of an undergoing operation
	public static int getPid(String workspace, String projectName) throws IOException {
		File jsonFile = new File(getProperty(DIRECTORY_OF_WORKSPACES_PROPERTY_NAME) + workspace + File.separator
				+ projectName + File.separator + PROJECT_DESCRIPTOR_JSON);
		String jsonString = FileUtils.readFileToString(jsonFile);
		JsonElement jElement = new JsonParser().parse(jsonString);
		JsonObject jObject = jElement.getAsJsonObject();
		return jObject.get("pid").getAsInt();
	}

	public static String getProperty(String propertyName) {
		String path = null;

		try (InputStream input = FileHandlerUtil.class.getClassLoader().getResourceAsStream("config.properties")) {
			path = new File(".").getCanonicalPath();
			Properties prop = new Properties();

			if (input == null) {
				logger.log(Level.INFO, "Sorry, unable to find config.properties");
				return "";
			}
			prop.load(input);
			return path + prop.getProperty(propertyName);
		} catch (IOException ex) {
			ex.printStackTrace();
		}
		return "";

	}
}
