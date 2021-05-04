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

import hu.bme.mit.gamma.eventpriority.transformation.EventPriorityTransformer;
import hu.bme.mit.gamma.genmodel.model.EventPriorityTransformation;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;

public class EventPriorityTransformationHandler extends TaskHandler {

	public EventPriorityTransformationHandler(IFile file) {
		super(file);
	}
	
	public void execute(EventPriorityTransformation eventPriorityTransformation) throws IOException {
		// Setting target folder
		setTargetFolder(eventPriorityTransformation);
		///
		setFileName(eventPriorityTransformation);
		StatechartDefinition statechart = eventPriorityTransformation.getStatechart();
		EventPriorityTransformer eventPriorityTransformer = new EventPriorityTransformer(statechart);
		StatechartDefinition prioritizedTransitionsStatechart = eventPriorityTransformer.execute();
		Package prioritizedTransitionsStatechartPackage =
				StatechartModelDerivedFeatures.getContainingPackage(prioritizedTransitionsStatechart);
		serializer.saveModel(prioritizedTransitionsStatechartPackage,
				targetFolderUri, eventPriorityTransformation.getFileName().get(0) + ".gcd");
	}
	
	private void setFileName(EventPriorityTransformation eventPriorityTransformation) {
		String fileName = getNameWithoutExtension(getContainingFileName(eventPriorityTransformation.getStatechart()));
		checkArgument(eventPriorityTransformation.getFileName().size() <= 1);
		if (eventPriorityTransformation.getFileName().isEmpty()) {
			eventPriorityTransformation.getFileName().add(fileName);
		}
	}
	
}
