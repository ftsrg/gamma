/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
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

import org.eclipse.core.resources.IFile;

import hu.bme.mit.gamma.genmodel.model.PhaseStatechartGeneration;
import hu.bme.mit.gamma.statechart.model.Package;
import hu.bme.mit.gamma.statechart.model.StatechartDefinition;
import hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.phase.transformation.PhaseStatechartToStatechartTransformer;

public class PhaseGenerationHandler extends TaskHandler {

	public PhaseGenerationHandler(IFile file) {
		super(file);
	}
	
	public void execute(PhaseStatechartGeneration phaseStatechartGeneration) throws IOException {
		setFileName(phaseStatechartGeneration);
		StatechartDefinition statechart = phaseStatechartGeneration.getStatechart();
		PhaseStatechartToStatechartTransformer transformer = new PhaseStatechartToStatechartTransformer();
		StatechartDefinition phaseStatechart = transformer.execute(statechart);
		Package _package = StatechartModelDerivedFeatures.getContainingPackage(phaseStatechart);
		saveModel(_package, targetFolderUri, phaseStatechartGeneration.getFileName().get(0) + ".gcd");
	}
	
	private void setFileName(PhaseStatechartGeneration phaseStatechartGeneration) {
		String fileName = "Phase" + getNameWithoutExtension(getContainingFileName(phaseStatechartGeneration.getStatechart()));
		checkArgument(phaseStatechartGeneration.getFileName().size() <= 1);
		if (phaseStatechartGeneration.getFileName().isEmpty()) {
			phaseStatechartGeneration.getFileName().add(fileName);
		}
	}
	
}
