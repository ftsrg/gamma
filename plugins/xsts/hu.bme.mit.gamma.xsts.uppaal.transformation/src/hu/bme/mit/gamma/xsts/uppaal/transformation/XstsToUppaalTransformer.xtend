/********************************************************************************
 * Copyright (c) 2018-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.uppaal.transformation

import hu.bme.mit.gamma.uppaal.util.ClockExpressionHandler
import hu.bme.mit.gamma.uppaal.util.NtaBuilder
import hu.bme.mit.gamma.uppaal.util.NtaOptimizer
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.HavocAction
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.XSTS
import java.util.logging.Level
import java.util.logging.Logger
import uppaal.templates.LocationKind

import static hu.bme.mit.gamma.uppaal.util.XstsNamings.*

import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class XstsToUppaalTransformer {
	
	protected final XSTS xSts
	protected final Traceability traceability
	
	// Auxiliary
	protected final extension NtaBuilder ntaBuilder
	protected final extension CfaActionTransformer actionTransformer
	protected final extension FunctionActionTransformer functionctionTransformer
	protected final extension VariableTransformer variableTransformer
	protected final extension NtaOptimizer ntaOptimizer
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ClockExpressionHandler clockExpressionHandler = ClockExpressionHandler.INSTANCE
	
	protected final Logger logger = Logger.getLogger("GammaLogger")
	
	new(XSTS xSts) {
		this.xSts = xSts
		this.ntaBuilder = new NtaBuilder(xSts.name, false)
		this.traceability = new Traceability(xSts, ntaBuilder.nta)
		this.actionTransformer = new CfaActionTransformer(ntaBuilder, traceability)
		this.functionctionTransformer = new FunctionActionTransformer(ntaBuilder, traceability)
		this.variableTransformer = new VariableTransformer(ntaBuilder, traceability)
		this.ntaOptimizer = new NtaOptimizer(ntaBuilder)
	}
	
	def execute() {
		// If the XSTS transformation extracts guards into local variables:
		// if the guard contains clock variables (referencing native clocks), they should be reinlined
		
		resetCommittedLocationName
		val initialLocation = templateName.createTemplateWithInitLoc(initialLocationName)
		initialLocation.locationTimeKind = LocationKind.COMMITED
		val template = initialLocation.parentTemplate
		
		val initializingAction = xSts.initializingAction
		val environmentalAction = xSts.environmentalAction
		val mergedAction = xSts.mergedAction
		
		xSts.transformVariables
		
		val stableLocation = initializingAction.transformAction(initialLocation)
		stableLocation.name = stableLocationName
		stableLocation.locationTimeKind = LocationKind.NORMAL
		
		val environmentFinishLocation = template.createLocation
		environmentFinishLocation.name = environmentFinishLocationName
		// Location kind is Normal, so optimization does not delete it
		environmentalAction.transformIntoCfa(stableLocation, environmentFinishLocation)
		
		if (mergedAction.isOrContainsTypes(#[NonDeterministicAction, HavocAction]) ||
				xSts.hasClockVariable || xSts.hasInvariants) {
			// For nondeterministic cases, UPPAAL functions cannot be used
			mergedAction.transformIntoCfa(environmentFinishLocation, stableLocation)
		}
		else {
			// Deterministic behavior, creating a function
			mergedAction.transformIntoFunction(environmentFinishLocation, stableLocation)
		}
		
		// Optimizing edges from these location
		initialLocation.optimizeSubsequentEdges
		stableLocation.optimizeSubsequentEdges
		environmentFinishLocation.optimizeSubsequentEdges
		
		if (environmentFinishLocation !== stableLocation) {
			// Model checking is faster if the environment finish location is committed
			environmentFinishLocation.locationTimeKind = LocationKind.COMMITED
		}
		
		logger.log(Level.INFO, "Basic NTA transformation has finished")
		
		//
		optimizelIntegerCodomains
		//
		val nta = ntaBuilder.nta
		nta.transformClockExpressions
		//
		
		ntaBuilder.instantiateTemplates
		
		return nta
	}
	
}