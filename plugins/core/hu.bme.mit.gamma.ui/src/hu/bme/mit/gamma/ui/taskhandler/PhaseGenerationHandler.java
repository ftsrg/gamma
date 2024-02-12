/********************************************************************************
 * Copyright (c) 2018-2022 Contributors to the Gamma project
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

import java.io.IOException;
import java.util.List;

import org.eclipse.core.resources.IFile;

import hu.bme.mit.gamma.genmodel.model.PhaseStatechartGeneration;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.phase.transformation.PhaseStatechartTransformer;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;

public class PhaseGenerationHandler extends TaskHandler {

	public PhaseGenerationHandler(IFile file) {
		super(file);
	}
	
	public void execute(PhaseStatechartGeneration phaseStatechartGeneration) throws IOException {
		// Setting target folder
		setTargetFolder(phaseStatechartGeneration);
		//
		setFileName(phaseStatechartGeneration);
		StatechartDefinition statechart = phaseStatechartGeneration.getStatechart();
		PhaseStatechartTransformer transformer = new PhaseStatechartTransformer(statechart);
		StatechartDefinition phaseStatechart = transformer.execute();
		Package _package = StatechartModelDerivedFeatures.getContainingPackage(phaseStatechart);
		serializer.saveModel(_package, targetFolderUri,
				phaseStatechartGeneration.getFileName().get(0) + ".gcd");
	}
	
	private void setFileName(PhaseStatechartGeneration phaseStatechartGeneration) {
		String fileName = "Phase" + getNameWithoutExtension(
				getContainingFileName(
						phaseStatechartGeneration.getStatechart()));
		List<String> fileNames = phaseStatechartGeneration.getFileName();
		checkArgument(fileNames.size() <= 1);
		if (fileNames.isEmpty()) {
			fileNames.add(fileName);
		}
	}
	
}
