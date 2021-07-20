package hu.bme.mit.gamma.headless.server.util;

import com.google.gson.Gson;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.google.gson.reflect.TypeToken;

import hu.bme.mit.gamma.headless.server.entity.WorkspaceProjectWrapper;

import org.apache.commons.io.FileUtils;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Type;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.List;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;

// Contains functions that are used for file and process handling
public class FileHandlerUtil {
	private static final String DIRECTORY_OF_WORKSPACES_PROPERTY_NAME = "root.of.workspaces.path";
	private static final String ROOT_WRAPPER_JSON = "wrapperList.json";
	public static final String PROJECT_DESCRIPTOR_JSON = "projectDescriptor.json";
	protected static Logger logger = Logger.getLogger("GammaLogger");

	// Gets the wrapperList.json file
	public static List<WorkspaceProjectWrapper> getWrapperListFromJson() throws IOException {
		File jsonFile = new File(getProperty(DIRECTORY_OF_WORKSPACES_PROPERTY_NAME) + ROOT_WRAPPER_JSON);
		if (!jsonFile.exists()) {
			Files.createFile(Paths.get(jsonFile.getPath()));
		}
		String jsonString = FileUtils.readFileToString(jsonFile);
		JsonElement jElement = new JsonParser().parse(jsonString);
		Type listType = new TypeToken<List<WorkspaceProjectWrapper>>() {
		}.getType();

		return new Gson().fromJson(jElement, listType);
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
