/********************************************************************************
 * Copyright (c) 2019-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.ui.taskhandler;

import static com.google.common.base.Preconditions.checkArgument;

import java.io.File;
import java.io.IOException;
import java.util.List;
import java.util.logging.Logger;

import org.eclipse.core.resources.IFile;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator;
import hu.bme.mit.gamma.genmodel.model.AbstractCodeGeneration;
import hu.bme.mit.gamma.genmodel.model.AdaptiveContractTestGeneration;
import hu.bme.mit.gamma.genmodel.model.CodeGeneration;
import hu.bme.mit.gamma.genmodel.model.GenmodelModelFactory;
import hu.bme.mit.gamma.genmodel.model.Task;
import hu.bme.mit.gamma.genmodel.model.TestGeneration;
import hu.bme.mit.gamma.genmodel.model.TraceGeneration;
import hu.bme.mit.gamma.genmodel.model.Verification;
import hu.bme.mit.gamma.property.language.ui.serializer.PropertyLanguageSerializer;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.property.util.PropertyUtil;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.language.ui.serializer.StatechartLanguageSerializer;
import hu.bme.mit.gamma.trace.language.ui.serializer.TraceLanguageSerializer;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.transformation.util.GammaFileNamer;
import hu.bme.mit.gamma.util.FileUtil;
import hu.bme.mit.gamma.util.GammaEcoreUtil;
import hu.bme.mit.gamma.util.JavaUtil;

public abstract class TaskHandler {
	
	protected final IFile file;
	
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected final JavaUtil javaUtil = JavaUtil.INSTANCE;
	protected final FileUtil fileUtil = FileUtil.INSTANCE;
	protected final PropertyUtil propertyUtil = PropertyUtil.INSTANCE;
	protected final ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE;
	
	protected final GammaFileNamer fileNamer = GammaFileNamer.INSTANCE;
	
	protected final ModelSerializer serializer = ModelSerializer.INSTANCE;
	
	protected final Logger logger = Logger.getLogger("GammaLogger");
	
	protected String projectLocation;
	protected String targetFolderUri;

	protected final ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE;
	protected final GenmodelModelFactory factory = GenmodelModelFactory.eINSTANCE;
	
	//
	
	public TaskHandler(IFile file) {
		this.file = file;
		// E.g., C:/Users/...
		this.projectLocation = file.getProject().getLocation().toString(); 
	}
	
	public void setTargetFolder(Task task) {
		List<String> targetFolders = task.getTargetFolder();
		checkArgument(targetFolders.size() <= 1);
		
		if (targetFolders.isEmpty()) {
			String targetFolder = null;
			if (task instanceof TraceGeneration) {
				String path = file.getParent().getFullPath().toString();
				String path2 = path.substring(path.indexOf("/") + 1);
				targetFolder = path2.substring(path2.indexOf("/") + 1);
			} else if (task instanceof Verification || task instanceof AdaptiveContractTestGeneration) {
				targetFolder = "trace";
			}
			else if (task instanceof CodeGeneration) {
				targetFolder = "src-gen";
			}
			else if (task instanceof TestGeneration) {
				targetFolder = "test-gen";
			}
			else {
				Resource resource = task.eResource();
				if (resource != null) { 
					URI relativeUri = resource.getURI();
					URI parentUri = relativeUri.trimSegments(1);
					String platformUri = parentUri.toPlatformString(true);
					if (platformUri == null) {
						// If there is a '/' at the beginning of the URI in the ggen-include...
						platformUri = parentUri.toString();
					}
					targetFolder = platformUri.substring(
						(File.separator + file.getProject().getName() + File.separator).length());
				}
				else {
					String relativeFolder = file.getParent().getLocation().toString();
					targetFolder = relativeFolder.substring(projectLocation.length() + 1); // Counting the separator
				}
			}
			targetFolders.add(targetFolder);
		}
		// Setting the attribute, the target folder is a RELATIVE path now from the project
		targetFolderUri = URI.decode(
				projectLocation + File.separator + targetFolders.get(0));
	}
	
	protected void setFileRelativePaths(Task task) {
		Resource resource = task.eResource();
		File file = (resource != null) ?
				ecoreUtil.getFile(resource).getParentFile() : // If task is contained in a resource
					fileUtil.toFile(this.file).getParentFile(); // If task is created in Java
		// Setting the file paths
		task.getFileName().replaceAll(it -> fileUtil.exploreRelativeFile(file, it).toString());
	}
	
	protected String getNameWithoutExtension(String fileName) {
		return fileName.substring(0, fileName.lastIndexOf("."));
	}
	
	protected String getContainingFileName(EObject object) {
		return object.eResource().getURI().lastSegment();
	}
	
	public String getTargetFolderUri() {
		return targetFolderUri;
	}
	
	public String getBinUri() {
		return projectLocation + File.separator + "bin";
	}
	
	public void setProjectLocation(AbstractCodeGeneration codeGeneration) {
		List<String> projectNames = codeGeneration.getProjectName();
		
		if (projectNames.isEmpty()) {
			return;
		}
		
		checkArgument(projectNames.size() <= 1);
		
		String projectName = javaUtil.getOnlyElement(projectNames);
		String root = ecoreUtil.getProjectFile(codeGeneration).getParent();
		
		String newProjectLocation = root + File.separator + projectName;
		File newProjectFile = new File(newProjectLocation);
		if (newProjectFile.exists()) { // First, we try with the root location of the project
			setProjectLocation(newProjectLocation);
		}
		else { // Not in root location of the project; we try the workspace location
			String workspaceRoot = ecoreUtil.getWorkspace().toString();
			newProjectLocation = workspaceRoot + File.separator + projectName;
			setProjectLocation(newProjectLocation);
		}
		// TODO experiment with the Workspace object - maybe it can find the contained projects
	}
	
	public void setProjectLocation(String projectLocation) {
		this.projectLocation = projectLocation;
	}
	
	public File exporeRelativeFile(Task task, String relativePath) {
		Resource resource = task.eResource();
		File file = (resource != null) ?
			ecoreUtil.getFile(resource).getParentFile() : // If task is contained in a resource
				fileUtil.toFile(this.file).getParentFile(); // If task is created in Java
		// Setting the file paths
		return fileUtil.exploreRelativeFile(file, relativePath);
	}
	
	public static class ModelSerializer {
		//
		public static final ModelSerializer INSTANCE = new ModelSerializer();
		protected ModelSerializer() {}
		//
		protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
		
		/**
		 * Responsible for saving the given element into a resource file.
		 */
		public void saveModel(EObject rootElem, String parentFolder, String fileName) throws IOException {
			// A Gamma statechart model
			try {
				// Trying to serialize the model
				if (rootElem instanceof Package) {
					serializeStatechart(rootElem, parentFolder, fileName);
					return;
				}
				else if (rootElem instanceof ExecutionTrace) { 
					serializeTrace(rootElem, parentFolder, fileName);
					return;
				}
				else if (rootElem instanceof PropertyPackage) { 
					serializeProperty(rootElem, parentFolder, fileName);
					return;
				}
			} catch (RuntimeException e) {
				throw e;
//				DialogUtil.showErrorWithStackTrace("Model cannot be serialized", e);
			}
			new File(parentFolder + File.separator + fileName).delete();
			// Saving like an EMF model - not working: for this, we would need the corresponding file extension
			ecoreUtil.normalSave(rootElem, parentFolder, fileName);
		}
		
		private void serializeStatechart(EObject rootElem, String parentFolder, String fileName) throws IOException {
			StatechartLanguageSerializer serializer = new StatechartLanguageSerializer();
			serializer.serialize(rootElem, parentFolder, fileName);
		}
		
		private void serializeTrace(EObject rootElem, String parentFolder, String fileName) throws IOException {
			TraceLanguageSerializer serializer = new TraceLanguageSerializer();
			serializer.serialize(rootElem, parentFolder, fileName);
		}
		
		private void serializeProperty(EObject rootElem, String parentFolder, String fileName) throws IOException {
			PropertyLanguageSerializer serializer = new PropertyLanguageSerializer();
			serializer.serialize(rootElem, parentFolder, fileName);
		}
	
	}
	
}