/********************************************************************************
 * Copyright (c) 2020-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.composition.xsts.uppaal.transformation

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.lowlevel.xsts.transformation.TransitionMerging
import hu.bme.mit.gamma.property.model.PropertyPackage
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.transformation.util.GammaFileNamer
import hu.bme.mit.gamma.transformation.util.annotations.AnnotatablePreprocessableElements
import hu.bme.mit.gamma.transformation.util.annotations.DataflowCoverageCriterion
import hu.bme.mit.gamma.transformation.util.annotations.InteractionCoverageCriterion
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.transformation.InitialStateSetting
import hu.bme.mit.gamma.xsts.transformation.api.Gamma2XstsTransformerSerializer
import hu.bme.mit.gamma.xsts.uppaal.transformation.api.Xsts2UppaalTransformerSerializer
import java.util.List

class Gamma2XstsUppaalTransformerSerializer {

	protected final Component component
	protected final List<? extends Expression> arguments
	protected final String targetFolderUri
	protected final String fileName
	
	protected final Integer minSchedulingConstraint
	protected final Integer maxSchedulingConstraint
	// Configuration
	protected final boolean optimize
	protected final TransitionMerging transitionMerging
	// Slicing
	protected final PropertyPackage slicingProperties
	// Annotation
	protected final AnnotatablePreprocessableElements annotatableElements
	// Initial state
	protected final PropertyPackage initialState
	protected final InitialStateSetting initialStateSetting
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension GammaFileNamer fileNamer = GammaFileNamer.INSTANCE
	
	new(Component component, String targetFolderUri, String fileName) {
		this(component, #[], targetFolderUri, fileName)
	}

	new(Component component, List<Expression> arguments,
			String targetFolderUri, String fileName) {
		this(component, arguments, targetFolderUri, fileName, null)
	}
	
	new(Component component, List<Expression> arguments,
			String targetFolderUri, String fileName,
			Integer schedulingConstraint) {
		this(component, arguments, targetFolderUri, fileName, schedulingConstraint, schedulingConstraint,
			true, TransitionMerging.HIERARCHICAL,
			null, new AnnotatablePreprocessableElements(
				null, null, null, null, null, null, null, null, null,
				InteractionCoverageCriterion.EVERY_INTERACTION,	InteractionCoverageCriterion.EVERY_INTERACTION,
				null, DataflowCoverageCriterion.ALL_USE,
				null, DataflowCoverageCriterion.ALL_USE
			),
			null, null)
	}
	
	new(Component component, List<? extends Expression> arguments,
			String targetFolderUri, String fileName,
			Integer minSchedulingConstraint, Integer maxSchedulingConstraint,
			boolean optimize,
			TransitionMerging transitionMerging,
			PropertyPackage slicingProperties,
			AnnotatablePreprocessableElements annotatableElements,
			PropertyPackage initialState, InitialStateSetting initialStateSetting) {
		this.component = component
		this.arguments = arguments
		this.targetFolderUri = targetFolderUri
		this.fileName = fileName
		this.minSchedulingConstraint = minSchedulingConstraint
		this.maxSchedulingConstraint = maxSchedulingConstraint
		//
		this.optimize = optimize
		this.transitionMerging = transitionMerging
		//
		this.slicingProperties = slicingProperties
		//
		this.annotatableElements = annotatableElements
		//
		this.initialState = initialState
		this.initialStateSetting = initialStateSetting
	}
	
	def execute() {
		val xStsTransformer = new Gamma2XstsTransformerSerializer(component,
			arguments, targetFolderUri,
			fileName, minSchedulingConstraint, maxSchedulingConstraint,
			optimize, false,
			false, true,
			transitionMerging,
			slicingProperties, annotatableElements,
			initialState, initialStateSetting)
		xStsTransformer.execute
		val xSts = targetFolderUri.normalLoad(fileName.emfXStsFileName) as XSTS
		val uppaalTransformer = new Xsts2UppaalTransformerSerializer(xSts,
			targetFolderUri, fileName)
		uppaalTransformer.execute
	}
	
}