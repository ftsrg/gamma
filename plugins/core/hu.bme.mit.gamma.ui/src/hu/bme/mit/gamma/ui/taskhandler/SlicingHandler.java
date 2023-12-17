/********************************************************************************
 * Copyright (c) 2020 Contributors to the Gamma project
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

import org.eclipse.core.resources.IFile;
import org.eclipse.emf.common.util.URI;

import hu.bme.mit.gamma.genmodel.model.Slicing;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.transformation.util.ModelSlicer;

public class SlicingHandler extends TaskHandler  {

	public SlicingHandler(IFile file) {
		super(file);
	}
	
	/**
	 * Now it is used only for already UNFOLDED components (package).
	 */
	public void execute(Slicing slicing) throws IOException {
		setFileName(slicing);
		setTargetFolder(slicing);
		
		PropertyPackage propertyPackage = slicing.getPropertyPackage();
		
		ModelSlicer slicer = new ModelSlicer(propertyPackage, true);
		slicer.execute();
		
		// Saving like an EMF model
		Component component = propertyPackage.getComponent();
		Package containingPackage = StatechartModelDerivedFeatures.getContainingPackage(component);
		final String fileName = slicing.getFileName().get(0);
		ecoreUtil.normalSave(containingPackage, targetFolderUri, fileName);
	}
	
	/**
	 * Here the file name is the whole file name of the component with the extension.
	 */
	private void setFileName(Slicing slicing) {
		checkArgument(slicing.getFileName().size() <= 1);
		if (slicing.getFileName().isEmpty()) {
			Component component = slicing.getPropertyPackage().getComponent();
			String fileName = getContainingFileName(component);
			slicing.getFileName().add(fileName);
		}
	}
	
	/**
	 * Original target folder for the component under slicing.
	 */
	private void setTargetFolder(Slicing slicing) {
		List<String> targetFolders = slicing.getTargetFolder();
		checkArgument(targetFolders.size() <= 1);
		if (targetFolders.isEmpty()) {
			Component component = slicing.getPropertyPackage().getComponent();
			URI relativeUri = component.eResource().getURI();
			URI parentUri = relativeUri.trimSegments(1);
			String platformUri = parentUri.toPlatformString(true);
			String targetFolder = platformUri.substring(
				(File.separator + file.getProject().getName() + File.separator).length());
			targetFolders.add(targetFolder);
			// Setting the attribute, the target folder is a RELATIVE path now from the project
			targetFolderUri = URI.decode(projectLocation + File.separator + targetFolders.get(0));
		}
	}
	
}
