/********************************************************************************
 * Copyright (c) 2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.api.headless;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.Arrays;
import java.util.logging.Level;

import org.eclipse.core.resources.IContainer;
import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IFolder;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IProjectDescription;
import org.eclipse.core.resources.IWorkspace;
import org.eclipse.core.resources.IWorkspaceRoot;
import org.eclipse.core.resources.ResourcesPlugin;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.core.runtime.IPath;
import org.eclipse.core.runtime.IProgressMonitor;
import org.eclipse.core.runtime.NullProgressMonitor;
import org.eclipse.core.runtime.Path;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.equinox.app.IApplicationContext;
import org.eclipse.xtext.resource.XtextResourceSet;

import com.google.gson.Gson;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.google.inject.Injector;

import hu.bme.mit.gamma.action.language.ActionLanguageStandaloneSetup;
import hu.bme.mit.gamma.expression.language.ExpressionLanguageStandaloneSetup;
import hu.bme.mit.gamma.fei.language.FaultExtensionLanguageStandaloneSetup;
import hu.bme.mit.gamma.genmodel.language.GenModelStandaloneSetup;
import hu.bme.mit.gamma.property.language.PropertyLanguageStandaloneSetup;
import hu.bme.mit.gamma.scenario.language.ScenarioLanguageStandaloneSetup;
import hu.bme.mit.gamma.statechart.language.StatechartLanguageStandaloneSetup;
import hu.bme.mit.gamma.statechart.language.StatechartLanguageStandaloneSetupGenerated;
import hu.bme.mit.gamma.trace.language.TraceLanguageStandaloneSetup;
import hu.bme.mit.gamma.ui.GammaApi;
import hu.bme.mit.gamma.ui.util.ResourceSetCreator;
import hu.bme.mit.gamma.util.FileUtil;

// This is the entry point for the Headless Gamma
public class GammaEntryPoint extends HeadlessApplicationCommandHandler {

	private static final String UNDER_OPERATION_PROPERTY = "underOperation";

	public GammaEntryPoint(IApplicationContext context, String[] appArgs, Level level) {
		super(context, appArgs, level);
		logger.setLevel(level);
	}

	@Override
	public void execute() throws Exception {
		// Necessary setup of Xtext parsers
		ExpressionLanguageStandaloneSetup.doSetup();
		ActionLanguageStandaloneSetup.doSetup();
		StatechartLanguageStandaloneSetup.doSetup();
		TraceLanguageStandaloneSetup.doSetup();
		PropertyLanguageStandaloneSetup.doSetup();
		ScenarioLanguageStandaloneSetup.doSetup();
		FaultExtensionLanguageStandaloneSetup.doSetup();
		GenModelStandaloneSetup.doSetup();
		
		if (appArgs.length >= 1) { // Checking the length of arguments. These are passed by the web server.
			String ggenFilePath = URI.decode(appArgs[2]); // Path of the .ggen file to be executed
			File ggenFile = new File(ggenFilePath);
			String projectDescriptorPath = (appArgs.length >= 4) ? URI.decode(appArgs[3]) : null; // Path of the projectDescriptor.json
			File projectFolder = getContainingProject(ggenFile);
			String projectName = projectFolder.getName();
			String fileWorkspaceRelativePath = ggenFilePath.substring(projectFolder.getParent().length());
			IWorkspace workspace = ResourcesPlugin.getWorkspace();
			IWorkspaceRoot workspaceRoot = workspace.getRoot();
			IPath workspaceLocation = workspaceRoot.getLocation();
			File workspaceFolder = workspaceLocation.toFile();
			IProgressMonitor progressMonitor = new NullProgressMonitor();
			// The file and its containing project is not in the given workspace
			// The project has to be copied into the workspace
			if (!contains(workspaceFolder, ggenFile)) {
				// Note that in this case the ggen cannot refer to models outside of the project
				IProject project = workspaceRoot.getProject(projectName);
				try {
					project.create(progressMonitor);
				} catch (CoreException creationException) {
					// Project with same name exists, trying to open it
					try {
						project.open(progressMonitor);
					} catch (CoreException openException) {
						// Open did not succeed, deleting and creating needed
						project.delete(true, progressMonitor);
						project.create(progressMonitor);
					}
				}
				project.open(progressMonitor);
				IProjectDescription description = project.getDescription();
				//description.setNatureIds(new String[] { XtextProjectHelper.NATURE_ID });
				project.setDescription(description, progressMonitor);
				// Not needed to add project natures like this, maybe copyDirectory does that?
				copyDirectory(projectFolder, project);
				workspace.save(true, progressMonitor);
			}
			// The file and its containing project is in the given workspace
			GammaApi gammaApi = new GammaApi();

			gammaApi.run(fileWorkspaceRelativePath, new ResourceSetCreator() {
				private Injector injector = null;

				private Injector getInjector() {
					if (injector == null) {
						injector = new StatechartLanguageStandaloneSetupGenerated()
								.createInjectorAndDoEMFRegistration();
					}
					return injector;
				}

				public ResourceSet createResourceSet() {
					Injector injector = getInjector();
					XtextResourceSet resourceSet = injector.getInstance(XtextResourceSet.class);
					return resourceSet;
				}
			});
			// Commented due to repeatedly throwing exceptions. The application works without it.
			// workspace.save(true, progressMonitor);

			beforeExitOperation(projectDescriptorPath);
		}

	}

	private boolean contains(File folder, File file) {
		File parentFolder = file.getParentFile();
		if (parentFolder == null) {
			return false;
		}
		if (folder.equals(parentFolder)) {
			return true;
		}
		return contains(folder, parentFolder);
	}

	private void copyDirectory(File sourceFolder, IContainer destinationFolder) throws Exception {
		for (File file : sourceFolder.listFiles()) {
			if (file.isDirectory()) {
				IFolder newFolder = destinationFolder.getFolder(new Path(file.getName()));
				if (newFolder.exists()) {
					// Overwriting old directory
					newFolder.delete(true, null);
				}
				newFolder.create(true, true, null);
				copyDirectory(file, newFolder);
			} else {
				IFile newFile = destinationFolder.getFile(new Path(file.getName()));
				if (newFile.exists()) {
					// Overwriting old file
					newFile.delete(true, null);
				}
				newFile.create(new FileInputStream(file), true, null);
			}
		}
	}

	private File getContainingProject(File file) {
		File parentFolder = file.getParentFile();
		if (Arrays.asList(parentFolder.listFiles()).stream()
				// It is a project folder, if it contains a .project file
				.anyMatch(it -> it.getName().equals(".project"))) {
			return parentFolder;
		}
		return getContainingProject(parentFolder);
	}

	private void beforeExitOperation(String projectDescriptorPath) {
		if (projectDescriptorPath != null) {
			File descriptor = new File(projectDescriptorPath);
			if (descriptor.exists()) {
				try {
					logger.info("Updating project status");
					updateUnderOperationStatus(descriptor.getPath());
				} catch (IOException e) {
					e.printStackTrace();
				}
			}
		}
	}
	// Sets the status of the workspace + project pair to "not under operation"
	private void updateUnderOperationStatus(String projectDescriptorPath) throws IOException {
		File jsonFile = new File(projectDescriptorPath);
		String jsonString;
		try {
			jsonString = FileUtil.INSTANCE.loadString(jsonFile);
			JsonElement jElement = new JsonParser().parse(jsonString);
			JsonObject jObject = jElement.getAsJsonObject();
			jObject.remove(UNDER_OPERATION_PROPERTY);
			jObject.addProperty(UNDER_OPERATION_PROPERTY, false);
			Gson gson = new Gson();
			String resultingJson = gson.toJson(jElement);
			FileUtil.INSTANCE.saveString(jsonFile, resultingJson);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

}
