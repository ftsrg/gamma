package hu.bme.mit.gamma.headless.server.service;

import com.google.gson.Gson;
import hu.bme.mit.gamma.headless.server.entity.WorkspaceProjectWrapper;
import io.vertx.core.json.JsonArray;
import org.apache.commons.io.FileUtils;
import hu.bme.mit.gamma.headless.server.util.FileHandlerUtil;
import hu.bme.mit.gamma.headless.server.util.ZipUtils;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

public class Provider {

    private static final String RESULT_DIR_NAME = "result";
   // private static final String DIRECTORY_OF_WORKSPACES = "E:/Egyetem/GammaWrapper/Workspaces/";
   private static final String DIRECTORY_OF_WORKSPACES_PROPERTY_NAME = "root.of.workspaces.path";

    private static final String ROOT_WRAPPER_JSON = "wrapperList.json";

    private Provider() {
        throw new IllegalStateException("Utility class");
    }
    /**
     * @param requiredDirectories Every artifact path we want to retrieve, if contains {.} we will return the whole project
     *                            example: { resultDirs: ["src-gen", "model/Crossroad.gcd"]}
     * @param workspace Workspace which contains the project
     *                  example: full path of workspace: C:\wf\01234-2314
     * @param projectName Name of the project where we will zip the results
     *                    example: gamma.test.project
     * @return The path to the result.zip file
     */
    public static String getResultZipFilePath(JsonArray requiredDirectories, String workspace, String projectName) throws IOException {
        List<String> resultDirs = convertJsonArrayToStringArray(requiredDirectories);
        String pathPrefix = workspace + "\\" + projectName + "\\"; //on Windows
        //String pathPrefix = workspace + "/" + projectName + "/"; //on Linux
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
            resultDirs.stream()
                    .filter(relativePath -> new File(pathPrefix + relativePath).exists())
                    .forEach(relativePath -> {
                        if (new File(pathPrefix + relativePath) .isDirectory()) {
                            try {
                                copyDirectory(pathPrefix + relativePath, result.getPath() + "\\" + relativePath); //on Windows
                                //copyDirectory(pathPrefix + relativePath, result.getPath() + "/" + relativePath); //on Linux
                            } catch (IOException e) {
                                e.printStackTrace();
                            }
                        } else {
                            try {
                                FileUtils.copyFile(new File(pathPrefix  + relativePath), new File(result.getPath() + "\\" +relativePath)); //on Windows
                                //FileUtils.copyFile(new File(pathPrefix  + relativePath), new File(result.getPath() + "/" +relativePath)); //on Linux
                            } catch (IOException e) {
                                e.printStackTrace();
                            }
                        }


                    });

        } catch (IOException e) {
            e.printStackTrace();
        }
        return ZipUtils.getOutputZipFilePath(workspace, projectName, "\\" + RESULT_DIR_NAME); //on Windows
        //return ZipUtils.getOutputZipFilePath(workspace, projectName, "/" + RESULT_DIR_NAME); //on Linux
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
        Files.delete(Paths.get(directoryToBeDeleted.getPath()));
        return true;
    }

    private static void copyDirectory(String sourceDirectoryLocation, String destinationDirectoryLocation) throws IOException {
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

    public static void deleteProject(String workspace, String projectName) {
        File result = new File(FileHandlerUtil.getProperty(DIRECTORY_OF_WORKSPACES_PROPERTY_NAME) + workspace + "/" + projectName);
        List<WorkspaceProjectWrapper> workspaceProjectWrappers = new ArrayList<>();
        if (result.exists()) {
            try {
                deleteDirectory(result);
                deleteProvisionalFilesFromWorkspace(workspace,projectName);
                workspaceProjectWrappers = FileHandlerUtil.getWrapperListFromJson();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
        if (workspaceProjectWrappers != null && !workspaceProjectWrappers.isEmpty()) {
            List<WorkspaceProjectWrapper> yourList = workspaceProjectWrappers.stream().filter(wrapper -> !projectName.equals(wrapper.getProjectName())).collect(Collectors.toList());
            try {
                FileWriter writer = new FileWriter(FileHandlerUtil.getProperty(DIRECTORY_OF_WORKSPACES_PROPERTY_NAME) + ROOT_WRAPPER_JSON);
                new Gson().toJson(yourList, writer);
                writer.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    private static void deleteProvisionalFilesFromWorkspace(String workspace, String projectName) throws IOException {
        String projectMetadata = "\\.metadata\\.plugins\\org.eclipse.core.resources\\.projects\\"; //on Windows
        //String projectMetadata = "/.metadata/.plugins/org.eclipse.core.resources/.projects/"; //on Linux
        File metadataDirectory = new File(FileHandlerUtil.getProperty(DIRECTORY_OF_WORKSPACES_PROPERTY_NAME)
                + workspace+projectMetadata+projectName);
        if (metadataDirectory.exists()) {
            deleteDirectory(metadataDirectory);
        }
        String snapPath = "\\.metadata\\.plugins\\org.eclipse.core.resources\\0.snap"; //on Windows
        //String snapPath = "/.metadata/.plugins/org.eclipse.core.resources/0.snap"; //on Linux
        File snapFile = new File(FileHandlerUtil.getProperty(DIRECTORY_OF_WORKSPACES_PROPERTY_NAME) + workspace+snapPath);
        if (snapFile.exists()) {
            Files.delete(Paths.get(snapFile.getPath()));
        }
    }

}
