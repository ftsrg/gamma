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
package hu.bme.mit.gamma.xsts.uppaal.transformation

import hu.bme.mit.gamma.uppaal.util.AssignmentExpressionCreator
import hu.bme.mit.gamma.uppaal.util.NtaBuilder
import hu.bme.mit.gamma.uppaal.util.NtaOptimizer
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.XSTS
import java.util.Set
import uppaal.declarations.VariableContainer
import uppaal.templates.Edge
import uppaal.templates.LocationKind

import static hu.bme.mit.gamma.uppaal.util.XstsNamings.*

import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class XstsToUppaalTransformer {
	
	protected final XSTS xSts
	protected final Traceability traceability
	// Local variables
	protected final Set<VariableContainer> transientVariables = newHashSet
	// Auxiliary
	protected final extension NtaBuilder ntaBuilder
	protected final extension AssignmentExpressionCreator assignmentExpressionCreator
	protected final extension CfaActionTransformer actionTransformer
	protected final extension FunctionActionTransformer functionctionTransformer
	protected final extension VariableTransformer variableTransformer
	protected final extension NtaOptimizer ntaOptimizer
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	new(XSTS xSts) {
		this.xSts = xSts
		this.ntaBuilder = new NtaBuilder(xSts.name, false)
		this.traceability = new Traceability(xSts, ntaBuilder.nta)
		this.assignmentExpressionCreator = new AssignmentExpressionCreator(ntaBuilder)
		this.actionTransformer = new CfaActionTransformer(
			ntaBuilder, traceability, transientVariables)
		this.functionctionTransformer = new FunctionActionTransformer(
			ntaBuilder, traceability)
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
		
		var environmentFinishLocation = environmentalAction.transformAction(stableLocation)
		// If there is no environmental action, we create an environmentFinishLocation (needed for back-annotation)
		if (environmentFinishLocation === stableLocation) {
			environmentFinishLocation = template.createLocation
			stableLocation.createEdge(environmentFinishLocation)
		}
		environmentFinishLocation.name = environmentFinishLocationName
		environmentFinishLocation.locationTimeKind = LocationKind.NORMAL // So optimization does not delete it
		
		if (mergedAction.isOrContainsType(NonDeterministicAction)) {
			val systemFinishLocation = mergedAction.transformAction(environmentFinishLocation)
			
			// If there is no merged action, the loop edge is unnecessary
			if (systemFinishLocation !== stableLocation) {
				val lastEdge = systemFinishLocation.createEdge(stableLocation)
				lastEdge.resetTransientVariables(transientVariables) // TODO include in the class
			}
		}
		else {
			// Deterministic behavior, creating a function
			val mergedActionFunction = mergedAction.transformIntoFunction
			nta.globalDeclarations.declaration += mergedActionFunction.createFunctionDeclaration
			
			val lastEdge = environmentFinishLocation.createEdge(stableLocation)
			lastEdge.update += mergedActionFunction.createFunctionCallExpression
		}
		
		// Optimizing edges from these location
		initialLocation.optimizeSubsequentEdges
		stableLocation.optimizeSubsequentEdges
		environmentFinishLocation.optimizeSubsequentEdges
		
		if (environmentFinishLocation !== stableLocation) {
			// Model checking is faster if the environment finish location is committed
			environmentFinishLocation.locationTimeKind = LocationKind.COMMITED
		}
		
		ntaBuilder.instantiateTemplates
		
		return ntaBuilder.nta
	}
	
	// Resetting
	
	protected def resetTransientVariables(Edge edge, Set<VariableContainer> transientVariables) {
		for (transientVariable : transientVariables) {
			edge.update += transientVariable.createResetingAssignmentExpression
		}
	}
	
}