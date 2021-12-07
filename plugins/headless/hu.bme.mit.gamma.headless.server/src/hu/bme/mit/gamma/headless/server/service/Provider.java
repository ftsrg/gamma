package hu.bme.mit.gamma.headless.server.service;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.apache.commons.io.FileUtils;

import hu.bme.mit.gamma.headless.server.util.FileHandlerUtil;
import hu.bme.mit.gamma.headless.server.util.ZipUtils;
import io.vertx.core.json.JsonArray;

// The Provider class handles files. This includes deleting projects and workspaces, and zipping files to send them as results
public class Provider {

	private static final String RESULT_DIR_NAME = "result";

	private static final String DIRECTORY_OF_WORKSPACES_PROPERTY_NAME = "root.of.workspaces.path";

	private Provider() {
		throw new IllegalStateException("Utility class");
	}

	/**
	 * @param requiredDirectories Every artifact path we want to retrieve, if
	 *                            contains {.} we will return the whole project
	 *                            example: { resultDirs: ["src-gen",
	 *                            "model/Crossroad.gcd"]}
	 * @param workspace           Workspace which contains the project example: full
	 *                            path of workspace: C:\wf\01234-2314
	 * @param projectName         Name of the project where we will zip the results
	 *                            example: gamma.test.project
	 * @return The path to the result.zip file
	 */
	public static String getResultZipFilePath(JsonArray requiredDirectories, String workspace, String projectName)
			throws IOException {
		List<String> resultDirs = convertJsonArrayToStringArray(requiredDirectories);
		String pathPrefix = workspace + File.separator + projectName + File.separator;
		deletePreviousResultZip(pathPrefix);
		if (resultDirs.contains(".")) {
			return ZipUtils.getOutputZipFilePath(workspace, projectName, "");
		}

		try {
			File result = new File(pathPrefix + RESULT_DIR_NAME);
			if (result.exists()) {
				deleteDirectory(result);
			}
			Files.createDirectories(Paths.get(pathPrefix + RESULT_DIR_NAME));
			resultDirs.stream().filter(relativePath -> new File(pathPrefix + relativePath).exists())
					.forEach(relativePath -> {
						if (new File(pathPrefix + relativePath).isDirectory()) {
							try {
								copyDirectory(pathPrefix + relativePath,
										result.getPath() + File.separator + relativePath);
							} catch (IOException e) {
								e.printStackTrace();
							}
						} else {
							try {
								FileUtils.copyFile(new File(pathPrefix + relativePath),
										new File(result.getPath() + File.separator + relativePath));
							} catch (IOException e) {
								e.printStackTrace();
							}
						}

					});

		} catch (IOException e) {
			e.printStackTrace();
		}
		return ZipUtils.getOutputZipFilePath(workspace, projectName, File.separator + RESULT_DIR_NAME);
	}

	private static List<String> convertJsonArrayToStringArray(JsonArray requiredDirectories) {
		ArrayList<String> paths = new ArrayList<>();
		if (requiredDirectories != null) {
			for (int i = 0; i < requiredDirectories.size(); i++) {
				paths.add(requiredDirectories.getString(i));
			}
		}
		return paths;
	}

	private static boolean deleteDirectory(File directoryToBeDeleted) throws IOException {
		File[] allContents = directoryToBeDeleted.listFiles();
		if (allContents != null) {
			for (File file : allContents) {
				deleteDirectory(file);
			}
		}
		Files.delete(directoryToBeDeleted.toPath());
		return true;
	}

	private static void copyDirectory(String sourceDirectoryLocation, String destinationDirectoryLocation)
			throws IOException {
		File sourceDirectory = new File(sourceDirectoryLocation);
		File destinationDirectory = new File(destinationDirectoryLocation);
		FileUtils.copyDirectory(sourceDirectory, destinationDirectory);
	}

	private static void deletePreviousResultZip(String pathPrefix) throws IOException {
		File zip = new File(pathPrefix + RESULT_DIR_NAME + ".zip");
		if (zip.exists()) {
			Files.delete(Paths.get(zip.getPath()));
		}
	}

	// Deletes a project with all of its contents
	public static void deleteProject(String workspace, String projectName) {
		File result = new File(FileHandlerUtil.getProperty(DIRECTORY_OF_WORKSPACES_PROPERTY_NAME) + workspace
				+ File.separator + projectName);
		if (result.exists()) {
			try {
				// Deletes the directory and provisional files of the project
				deleteDirectory(result);
				deleteProvisionalFilesFromWorkspace(workspace, projectName);
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
	}
	
	// Deletes a workspace, if its empty
	public static boolean deleteWorkspace(String workspace) {
		File result = new File(FileHandlerUtil.getProperty(DIRECTORY_OF_WORKSPACES_PROPERTY_NAME) + workspace);
		if (result.exists()) {
			try {
				// Getting the list of workspaces and projects inside them
				Map<String, Set<String>> projectsByWorkspaces = FileHandlerUtil.getProjectsByWorkspaces();
				Set<String> projects = projectsByWorkspaces.getOrDefault(workspace, Collections.emptySet());
				if (projects.isEmpty()) { 
					return deleteDirectory(result); // If workspace is, then it can't be deleted
				}
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
		return false;
	}

	private static void deleteProvisionalFilesFromWorkspace(String workspace, String projectName) throws IOException {
		String projectMetadata = File.separator + ".metadata" + File.separator + ".plugins" + File.separator
				+ "org.eclipse.core.resources" + File.separator + ".projects" + File.separator;
		File metadataDirectory = new File(FileHandlerUtil.getProperty(DIRECTORY_OF_WORKSPACES_PROPERTY_NAME) + workspace
				+ projectMetadata + projectName);
		if (metadataDirectory.exists()) {
			deleteDirectory(metadataDirectory);
		}
		String snapPath = File.separator + ".metadata" + File.separator + ".plugins" + File.separator
				+ "org.eclipse.core.resources" + File.separator + "0.snap";
		File snapFile = new File(
				FileHandlerUtil.getProperty(DIRECTORY_OF_WORKSPACES_PROPERTY_NAME) + workspace + snapPath);
		if (snapFile.exists()) {
			Files.delete(Paths.get(snapFile.getPath()));
		}
	}

}
