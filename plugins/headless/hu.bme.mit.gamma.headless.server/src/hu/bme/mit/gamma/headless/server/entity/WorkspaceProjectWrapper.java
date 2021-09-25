package hu.bme.mit.gamma.headless.server.entity;

// Object that gets written to the wrapperList.json file, to keep track of workspaces and projects under them
public class WorkspaceProjectWrapper {
	String workspace;
	String projectName;

	public WorkspaceProjectWrapper(String workspace, String projectName) {
		this.workspace = workspace;
		this.projectName = projectName;
	}

	public String getWorkspace() {
		return workspace;
	}

	public void setWorkspace(String workspace) {
		this.workspace = workspace;
	}

	public String getProjectName() {
		return projectName;
	}

	public void setProjectName(String projectName) {
		this.projectName = projectName;
	}

}
