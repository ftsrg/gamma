/********************************************************************************
 * Copyright (c) 2019-2020 Contributors to the Gamma project
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
import java.util.logging.Logger;

import org.eclipse.core.resources.IFile;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;

import hu.bme.mit.gamma.dialog.DialogUtil;
import hu.bme.mit.gamma.genmodel.model.AdaptiveContractTestGeneration;
import hu.bme.mit.gamma.genmodel.model.CodeGeneration;
import hu.bme.mit.gamma.genmodel.model.GenmodelModelFactory;
import hu.bme.mit.gamma.genmodel.model.Task;
import hu.bme.mit.gamma.genmodel.model.TestGeneration;
import hu.bme.mit.gamma.genmodel.model.Verification;
import hu.bme.mit.gamma.property.language.ui.serializer.PropertyLanguageSerializer;
import hu.bme.mit.gamma.property.model.PropertyPackage;
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
	
	protected final GammaFileNamer fileNamer = GammaFileNamer.INSTANCE;
	
	protected final ModelSerializer serializer = ModelSerializer.INSTANCE;
	
	protected final Logger logger = Logger.getLogger("GammaLogger");
	
	protected final String projectLocation;
	protected String targetFolderUri;
	
	protected final GenmodelModelFactory factory = GenmodelModelFactory.eINSTANCE;
	
	public TaskHandler(IFile file) {
		this.file = file;
		// E.g., C:/Users/...
		this.projectLocation = file.getProject().getLocation().toString(); 
	}

	public void setTargetFolder(Task task) {
		checkArgument(task.getTargetFolder().size() <= 1);
		if (task.getTargetFolder().isEmpty()) {
			String targetFolder = null;
			if (task instanceof Verification || task instanceof AdaptiveContractTestGeneration) {
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
					targetFolder = platformUri.substring(
						(File.separator + file.getProject().getName() + File.separator).length());
				}
				else {
					String relativeFolder = file.getParent().getLocation().toString();
					targetFolder = relativeFolder.substring(projectLocation.length() + 1); // Counting the sperator
				}
			}
			task.getTargetFolder().add(targetFolder);
		}
		// Setting the attribute, the target folder is a RELATIVE path now from the project
		targetFolderUri = URI.decode(projectLocation + File.separator + task.getTargetFolder().get(0));
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
			} catch (Exception e) {
				e.printStackTrace();
				DialogUtil.showErrorWithStackTrace("Model cannot be serialized.", e);
			}
			new File(parentFolder + File.separator + fileName).delete();
			// Saving like an EMF model
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