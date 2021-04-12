package hu.bme.mit.gamma.headless.source.generate;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IProjectDescription;
import org.eclipse.core.resources.IWorkspace;
import org.eclipse.core.resources.ResourcesPlugin;
import org.eclipse.core.runtime.IPath;
import org.eclipse.core.runtime.NullProgressMonitor;
import org.eclipse.core.runtime.Path;
import org.eclipse.equinox.app.IApplication;
import org.eclipse.equinox.app.IApplicationContext;
import org.eclipse.ui.dialogs.IOverwriteQuery;
import org.eclipse.ui.wizards.datatransfer.ImportOperation;
import org.eclipse.ui.wizards.datatransfer.ZipFileStructureProvider;

public class Application implements IApplication{

	@Override
	public Object start(IApplicationContext context) throws Exception {
		IWorkspace workspace = ResourcesPlugin.getWorkspace();

		String[] args = (String[]) context.getArguments().get(IApplicationContext.APPLICATION_ARGS);
		if (args.length != 1) {
			System.out.println("Arguments must be given!");
			return null;
		}
		String projectName = args[0];

		IProjectDescription newProjectDescription = workspace.newProjectDescription(projectName);
		IProject newProject = workspace.getRoot().getProject(projectName);
		newProject.create(newProjectDescription, null);
		newProject.open(null);
		//ZipFile srcZipFile = new ZipFile(workspace.getRoot().getLocation() + "/" + projectName + ".zip");
		ZipFile srcZipFile = new ZipFile(workspace.getRoot().getLocation() + "/" + projectName + ".zip");
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

		return null;
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

	@Override
	public void stop() {
		// TODO Auto-generated method stub

	}

}