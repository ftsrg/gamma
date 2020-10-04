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

import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.uppaal.util.AssignmentExpressionCreator
import hu.bme.mit.gamma.uppaal.util.NtaBuilder
import hu.bme.mit.gamma.uppaal.util.NtaOptimizer
import hu.bme.mit.gamma.uppaal.util.TypeTransformer
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.XSTS
import uppaal.NTA
import uppaal.templates.Location
import uppaal.templates.LocationKind

import static extension hu.bme.mit.gamma.uppaal.util.XSTSNamings.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XSTSDerivedFeatures.*
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression

class XSTSToUppaalTransformer {
	
	protected final XSTS xSts
	protected final Traceability traceability
	protected final NTA nta
	// Auxiliary
	protected final extension NtaBuilder ntaBuilder
	protected final extension AssignmentExpressionCreator assignmentExpressionCreator
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension TypeTransformer typeTransformer
	protected final extension NtaOptimizer ntaOptimizer
	
	new(XSTS xSts) {
		this.xSts = xSts
		this.ntaBuilder = new NtaBuilder(xSts.name, false)
		this.nta = ntaBuilder.nta
		this.traceability = new Traceability(xSts, nta)
		this.assignmentExpressionCreator = new AssignmentExpressionCreator(ntaBuilder)
		this.expressionTransformer = new ExpressionTransformer(traceability)
		this.typeTransformer = new TypeTransformer(nta)
		this.ntaOptimizer = new NtaOptimizer(ntaBuilder)
	}
	
	def execute() {
		resetCommittedLocationName
		val initialLocation = createTemplateWithInitLoc(templateName, initialLocationName)
		initialLocation.locationTimeKind = LocationKind.COMMITED
		
		val initializingAction = xSts.initializingAction
		val environmentalAction = xSts.environmentalAction
		val mergedAction = xSts.mergedAction
		
		xSts.transformVariables
		
		val stableLocation = initializingAction.transformAction(initialLocation)
		stableLocation.name = stableLocationName
		stableLocation.locationTimeKind = LocationKind.NORMAL
		
		val environmentFinishLocation = environmentalAction.transformAction(stableLocation)
		environmentFinishLocation.name = environmentFinishLocationName
		environmentFinishLocation.locationTimeKind = LocationKind.NORMAL // So optimization does not delete it
		
		val systemFinishLocation = mergedAction.transformAction(environmentFinishLocation)
		
		systemFinishLocation.createEdge(stableLocation)
		
		// Optimizing edges from these location
		initialLocation.optimizeSubsequentEdges
		stableLocation.optimizeSubsequentEdges
		environmentFinishLocation.optimizeSubsequentEdges
		
		// Model checking is faster if the environment finish location is committed
		environmentFinishLocation.locationTimeKind = LocationKind.COMMITED 
		
		ntaBuilder.instantiateTemplates
		
		return ntaBuilder.nta
	}
	
	protected def transformVariables(XSTS xSts) {
		for (xStsVariable : xSts.variableDeclarations) {
			val uppaalVariable = xStsVariable.transformVariable
			nta.globalDeclarations.declaration += uppaalVariable
			traceability.put(xStsVariable, uppaalVariable)
		}
	}
	
	protected def transformVariable(VariableDeclaration variable) {
		val xSts = variable.containingXSTS
		val uppaalType =
		if (xSts.clockVariables.contains(variable)) {
			nta.clock.createTypeReference
		}
		else {
			variable.type.transformType
		}
		val uppaalVariable = uppaalType.createVariable(variable.uppaalId)
		return uppaalVariable
	}
	
	protected def dispatch Location transformAction(AssignmentAction action, Location source) {
		val edge = source.createEdgeCommittedSource(nextCommittedLocationName)
		val xStsDeclaration = (action.lhs as DirectReferenceExpression).declaration
		val xStsVariable = xStsDeclaration as VariableDeclaration
		val uppaalVariable = traceability.get(xStsVariable)
		val uppaalRhs = action.rhs.transform
		edge.update += uppaalVariable.createAssignmentExpression(uppaalRhs)
		return edge.target
	}
	
	protected def dispatch Location transformAction(AssumeAction action, Location source) {
		val edge = source.createEdgeCommittedSource(nextCommittedLocationName)
		val uppaalExpression = action.assumption.transform
		edge.guard = uppaalExpression
		return edge.target
	}
	
	protected def dispatch Location transformAction(SequentialAction action, Location source) {
		val xStsActions = action.actions
		var actualSource = source
		for (xStsAction : xStsActions) {
			actualSource = xStsAction.transformAction(actualSource)
		}
		return actualSource
	}
	
	protected def dispatch Location transformAction(NonDeterministicAction action, Location source) {
		val xStsActions = action.actions
		val targets = newArrayList
		for (xStsAction : xStsActions) {
			targets += xStsAction.transformAction(source)
		}
		val parentTemplate = source.parentTemplate
		val target = parentTemplate.createLocation(LocationKind.COMMITED, nextCommittedLocationName)
		for (choiceTarget : targets) {
			choiceTarget.createEdge(target)
		}
		return target
	}
	
}