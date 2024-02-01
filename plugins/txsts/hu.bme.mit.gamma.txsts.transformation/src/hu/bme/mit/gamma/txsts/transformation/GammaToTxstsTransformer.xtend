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
package hu.bme.mit.gamma.txsts.transformation

import hu.bme.mit.gamma.expression.model.ClockVariableDeclarationAnnotation
import hu.bme.mit.gamma.lowlevel.xsts.transformation.TransitionMerging
import hu.bme.mit.gamma.property.model.PropertyPackage
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.transformation.GammaToXstsTransformer
import hu.bme.mit.gamma.xsts.transformation.InitialStateHandler
import hu.bme.mit.gamma.xsts.transformation.InitialStateSetting
import java.util.logging.Level

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class GammaToTxstsTransformer extends GammaToXstsTransformer {
	
	new(Integer minSchedulingConstraint, Integer maxSchedulingConstraint,
			boolean transformOrthogonalActions,	boolean optimize, boolean optimizeArrays,
			boolean optimizeMessageQueues, boolean optimizeEnvironmentalMessageQueues,
			TransitionMerging transitionMerging,
			PropertyPackage initialState, InitialStateSetting initialStateSetting) {
		super(minSchedulingConstraint, maxSchedulingConstraint, transformOrthogonalActions, optimize, optimizeArrays,
			optimizeMessageQueues, optimizeEnvironmentalMessageQueues, transitionMerging, initialState,
			initialStateSetting)
	}
	
	override execute(Package _package) {
		logger.log(Level.INFO, "Starting main execution of Gamma-TXSTS transformation")
		val gammaComponent = _package.firstComponent // Getting the first component
		// "transform", not "execute", as we want to distinguish between statecharts
		val lowlevelPackage = gammaToLowlevelTransformer.transform(_package)
		// Serializing the xSTS
		val xSts = gammaComponent.transform(lowlevelPackage) // Transforming the Gamma component
		// Creating system event groups for traceability purposes
		logger.log(Level.INFO, "Creating system event groups for " + gammaComponent.name)
		xSts.createSystemEventGroups(gammaComponent) // Now synchronous event variables are put in there
		// Removing duplicated types
		xSts.removeDuplicatedTypes
		// Setting clock variable increase
		xSts.setClockVariables
		_package.setSchedulingAnnotation // Needed for back-annotation
		// Remove internal parameter assignments from environment
		xSts.removeInternalParameterAssignment(gammaComponent)
		// Optimizing
		xSts.optimize
		
		if (initialState !== null) {
			logger.log(Level.INFO, "Setting initial state " + gammaComponent.name)
			val initialStateHandler = new InitialStateHandler(xSts, gammaComponent,
				initialState, initialStateSetting)
			initialStateHandler.execute
		}
		
		return xSts
	}
	
	protected override void setClockVariables(XSTS xSts) {
		
		for (xStsClockVariable : xSts.clockVariables) {
			// Denoting variable as scheduled clock variable
			xStsClockVariable.addScheduledClockAnnotation
		}

		// Clearing the clock variables - they are handled like normal ones from now on
		// This way the UPPAAL transformer will not use clock types as variable values 
		xSts.removeVariableDeclarationAnnotations(ClockVariableDeclarationAnnotation)
	}
	
}