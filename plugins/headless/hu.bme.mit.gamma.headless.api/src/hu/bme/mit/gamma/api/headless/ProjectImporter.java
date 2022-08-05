package hu.bme.mit.gamma.api.headless;

import java.io.File;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.logging.Level;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IProjectDescription;
import org.eclipse.core.resources.IWorkspace;
import org.eclipse.core.resources.ResourcesPlugin;
import org.eclipse.core.runtime.IPath;
import org.eclipse.core.runtime.NullProgressMonitor;
import org.eclipse.core.runtime.Path;
import org.eclipse.equinox.app.IApplicationContext;
import org.eclipse.ui.dialogs.IOverwriteQuery;
import org.eclipse.ui.wizards.datatransfer.ImportOperation;
import org.eclipse.ui.wizards.datatransfer.ZipFileStructureProvider;

// Imports projects to a given workspace
public class ProjectImporter extends HeadlessApplicationCommandHandler {

	public ProjectImporter(IApplicationContext context, String[] appArgs, Level level) {
		super(context, appArgs, level);
		logger.setLevel(level);
	}

	@Override
	public void execute() throws Exception {
		IWorkspace workspace = ResourcesPlugin.getWorkspace(); // Workspace will be created where the -data argument
																// specifies it
		// All "-etc" arguments will be handled like regular arguments

		String projectName = appArgs[2];

		IProjectDescription newProjectDescription = workspace.newProjectDescription(projectName);
		IProject newProject = workspace.getRoot().getProject(projectName);
		newProject.create(newProjectDescription, null);
		newProject.open(null);
		ZipFile srcZipFile = new ZipFile(workspace.getRoot().getLocation() + File.separator + projectName + ".zip");
		IOverwriteQuery overwriteQuery = new IOverwriteQuery() {
			public String queryOverwrite(String file) {
				return ALL;
			}
		};

		IPath path = new Path("/");
		ZipFileStructureProvider structureProvider = new ZipFileStructureProvider(srcZipFile);
		List list = prepareFileList(structureProvider, structureProvider.getRoot(), null);
		ImportOperation op = new ImportOperation(path, structureProvider.getRoot(), structureProvider, overwriteQuery,
				list);
		op.run(new NullProgressMonitor());
	}

	private static List prepareFileList(ZipFileStructureProvider structure, ZipEntry entry, List list) {
		if (structure == null || entry == null)
			return null;

		if (list == null) {
			list = new ArrayList();
		}

		List son = structure.getChildren(entry);
		if (son == null)
			return list;
		Iterator it = son.iterator();
		while (it.hasNext()) {
			ZipEntry temp = (ZipEntry) it.next();
			if (temp.isDirectory()) {
				prepareFileList(structure, temp, list);
			} else {
				list.add(temp);
			}
		}

		return list;
	}

}
