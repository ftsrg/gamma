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
package hu.bme.mit.gamma.transformation.util.reducer

import hu.bme.mit.gamma.action.model.AssignmentStatement
import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.Collection
import java.util.logging.Level
import org.eclipse.emf.ecore.EObject
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.AccessExpression

class WrittenOnlyVariableReducer implements Reducer {
	// Any object can be root, e.g., Package or Component...
	protected final EObject root
	protected final Collection<VariableDeclaration> relevantVariables
	//
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	
	new(EObject root) {
		this(root, #[])
	}
	
	new(EObject root, Collection<VariableDeclaration> relevantVariables) {
		this.root = root
		this.relevantVariables = relevantVariables
	}
	
	override execute() {
		val assignments = root.getSelfAndAllContentsOfType(AssignmentStatement)
		val writtenOnlyVariables = root.writtenOnlyVariables
		writtenOnlyVariables += root.onlyIncrementedVariables // a := a + 1 can be deleted too
		val deletableVariables = <Declaration>newHashSet
		deletableVariables += root.unusedVariables
		deletableVariables -= relevantVariables // An unused variable can still be relevant
		for (assignment : assignments) {
			val lhs = assignment.lhs
			if (lhs instanceof DirectReferenceExpression) {
				val declaration = lhs.declaration
				if (writtenOnlyVariables.contains(declaration) &&
					!relevantVariables.contains(declaration)) {
					deletableVariables += declaration
					assignment.remove
				}
			} else if (assignment.lhs instanceof AccessExpression) {
				//TODO
			}
			
		}
		for (deletableVariable : deletableVariables) {
			deletableVariable.delete
			logger.log(Level.INFO, deletableVariable.name + " has been deleted")
		}
	}
	
}