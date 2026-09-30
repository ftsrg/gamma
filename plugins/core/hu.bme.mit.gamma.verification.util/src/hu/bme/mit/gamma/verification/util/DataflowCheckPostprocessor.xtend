/********************************************************************************
 * Copyright (c) 2026 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.verification.util

import hu.bme.mit.gamma.action.model.AssignmentStatement
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class DataflowCheckPostprocessor extends AbstractDataflowCheckPostprocessor {
	
	new(Component originalTopComponent) {
		super(originalTopComponent)
	}
	
	protected override filterDefAction(StatechartDefinition statechart, Expression useRhs, Expression id) {
		val actions = statechart.allEffects
		val assignmentStatements = actions.map[it.getSelfAndAllContentsOfType(AssignmentStatement)]
				.flatten.toSet
		return assignmentStatements
				.filter[it.lhs.helperEquals(useRhs) && it.rhs.helperEquals(id)]
				.head
	}
	
	protected override createDeclarationReference(ComponentInstanceReferenceExpression originalInstance,
			StatechartDefinition statechart, String useVariableName) {
		val lastI = javaUtil.lastBeforeLastIndexOf(useVariableName, INJECTED_VAR_END)
		val variableName = useVariableName.substring(USE_DATAFLOW_VAR_BEGINNING.length, lastI)
		val variable = statechart.variableDeclarations.findFirst[it.name == variableName]
		
		val originalVariable = originalInstance.getOriginalVariable(variable)
		
		return originalInstance.createVariableReference(originalVariable)
	}
	
}