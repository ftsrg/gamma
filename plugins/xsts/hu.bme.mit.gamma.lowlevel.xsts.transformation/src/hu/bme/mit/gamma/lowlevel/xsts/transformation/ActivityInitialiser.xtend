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
package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.activity.model.ActivityDefinition
import hu.bme.mit.gamma.activity.model.ActivityNode
import hu.bme.mit.gamma.activity.model.Flow
import hu.bme.mit.gamma.activity.model.InitialNode
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.statechart.lowlevel.model.ActivityInstance
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.util.XstsActionUtil

class ActivityInitialiser {
	// Model factories
	protected final extension XSTSModelFactory factory = XSTSModelFactory.eINSTANCE
	protected final extension ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE
	// Action utility
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE

	protected final extension ActivityLiterals activityLiterals = ActivityLiterals.INSTANCE 
	// Trace
	protected final Trace trace
	
	new(Trace trace) {
		this.trace = trace
	}
	def initialiseFlow(Flow flow) {
		val flowVariable = trace.getXStsVariable(flow)
		return createAssignmentAction(flowVariable, createEnumerationLiteralExpression => [
				reference = emptyFlowStateEnumLiteral
			]
		)
	}
	
	dispatch def initialiseNode(InitialNode node) {
		val nodeVariable = trace.getXStsVariable(node)
		return createAssignmentAction(nodeVariable, createEnumerationLiteralExpression => [
				reference = runningNodeStateEnumLiteral
			]
		)
	}
	
	dispatch def initialiseNode(ActivityNode node) {
		val nodeVariable = trace.getXStsVariable(node)
		return createAssignmentAction(nodeVariable, createEnumerationLiteralExpression => [
				reference = idleNodeStateEnumLiteral
			]
		)
	}
	
	def createInitialisationAction(ActivityInstance instance) {
		val definition = instance.activity.definition
		val action = createSequentialAction
		
		if (definition instanceof ActivityDefinition) {
			for (flow : definition.flows) {
				action.actions.add(flow.initialiseFlow)
			}
			for (node : definition.activityNodes) {
				action.actions.add(node.initialiseNode)
			}
		}
		
		return action
	}
	
}