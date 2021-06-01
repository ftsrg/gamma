package hu.bme.mit.gamma.headless.server.service;

import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import hu.bme.mit.gamma.headless.server.entity.WorkspaceProjectWrapper;
import hu.bme.mit.gamma.headless.server.util.FileHandlerUtil;

import org.apache.commons.io.FileUtils;

import java.io.File;
import java.io.IOException;
import java.util.List;
import java.util.Optional;

public class Validator {

   private static final String DIRECTORY_OF_WORKSPACES_PROPERTY_NAME = "root.of.workspaces.path";

    public static final String PROJECT_DESCRIPTOR_JSON = "projectDescriptor.json";
    public static final String UNDER_OPERATION_PROPERTY = "underOperation";

    public static boolean checkIfWorkspaceExists(String workspace) throws IOException {
        List<WorkspaceProjectWrapper> wrapperList = FileHandlerUtil.getWrapperListFromJson();
        if (wrapperList == null) {
            return false;
        }
        return wrapperList.stream().anyMatch(w -> w.getWorkspace().equals(workspace));
    }

    public static boolean checkIfProjectAlreadyExistsUnderWorkspace(String workspace, String projectName) throws IOException {
        List<WorkspaceProjectWrapper> wrapperList = FileHandlerUtil.getWrapperListFromJson();
        if (wrapperList == null) {
            return false;
        }
       return wrapperList.stream().anyMatch(w -> w.getWorkspace().equals(workspace) && projectName.equals(w.getProjectName()));
    }

    public static boolean checkIfProjectIsUnderLoad(String workspace, String projectName) throws IOException {
        File jsonFile = new File(FileHandlerUtil.getProperty(DIRECTORY_OF_WORKSPACES_PROPERTY_NAME) + workspace + "\\" + projectName + "\\" + PROJECT_DESCRIPTOR_JSON); //on Windows
        //File jsonFile = new File(FileHandlerUtil.getProperty(DIRECTORY_OF_WORKSPACES_PROPERTY_NAME) + workspace + "/" + projectName + "/" + PROJECT_DESCRIPTOR_JSON); //on Linux
        String jsonString = FileUtils.readFileToString(jsonFile);
        JsonElement jElement = new JsonParser().parse(jsonString);
        JsonObject jObject = jElement.getAsJsonObject();
        return jObject.get(UNDER_OPERATION_PROPERTY) != null && jObject.get(UNDER_OPERATION_PROPERTY).getAsBoolean();

    }

    public static boolean isValidPid(int pid) {
        return ProcessHandle.allProcesses().anyMatch(process -> text(process.info().command()).contains("eclipse.exe") && process.pid() == pid); //on Windows
        //return ProcessHandle.allProcesses().anyMatch(process -> text(process.info().command()).contains("eclipse") && process.pid() == pid); //on Linux
    }
    private static String text(Optional<?> optional) {
        return optional.map(Object::toString).orElse("-");
    }

}
