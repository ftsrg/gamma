/********************************************************************************
 * Copyright (c) 2025 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/

package hu.bme.mit.gamma.scxml.transformation.parse;

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.scxml.transformation.StatechartTraceability
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import java.util.List
import java.util.function.Function
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.nodemodel.ILeafNode

class ScxmlGammaExpressionLanguageLinker {

	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected final extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE

	def Function<ILeafNode, EObject> getLinker(StatechartTraceability traceability) {
		return new Function<ILeafNode, EObject> {
			List<String> tokenList = newArrayList

// TODO Goal: set references
// TODO Resolve with reflective API, EObject, EClass
// Get eStructuralFeature name from CrossReference
// Get eStructuralFeature from EClass
// semanticElement.setEStructuralFeature(object)

// TODO ILeafNode parameter
// Get type (gamma type), id (text, scxml id)
// scxml elements with this id
// filter gamma type matches
// OR: filter by type, then filter by id
// 0 elements -> IllegalArgumentException, user scxml model error
// 1 element -> OK, return EObject
// 2+ element -> random selection from options: throw exception
// or post prcessing step after full model transformation: resolve scoping globally
// heuristic: getLevel in tree -> select safer options: global"er" reference
// 	or properly implement scoping (direct reference expressions)
			override apply(ILeafNode node) {
				val id = node.text
				val grammarElement = node.getGrammarElement
				val reference = node.getSemanticElement

				tokenList += id

				// statechart parameter reference
				if (traceability.containsParameter(id)) {
					val parameterDeclaration = traceability.getParameter(id)
					return statechartUtil.createReferenceExpression(parameterDeclaration)
				}

				// variable reference
				if (traceability.containsVariable(id)) {
					val variableDeclaration = traceability.getVariable(id)
					return statechartUtil.createReferenceExpression(variableDeclaration)
				}

				// port
				if (traceability.containsPort(id)) {
					val port = traceability.getPort(id)
					return port
				}

				// event
				if (traceability.containsEvent(id)) {
					val event = traceability.getEvent(id)
					return event
				}

				// event parameter
				if (traceability.containsEventParameter(id)) {
					val eventParameter = traceability.getEventParameter(id)
					return eventParameter
				}

				/* TODO? Alternative resolution method: get port event parameter reference by token list
				 *
				 * if (traceability.containsPort(tokenList.get(0))) {
				 * 	val port = traceability.getPort(tokenList.get(0))
				 * 	val interface = port.interfaceRealization.interface
				 * 	if (interface !== null && tokenList.length >= 2) {
				 * 		val event = interface.events.findFirst[it.event.name == tokenList.get(1)].event
				 * 		if (event !== null && tokenList.length >= 3) {
				 * 			val parameter = event.parameterDeclarations.findFirst[it.name == tokenList.get(2)]
				 * 			if (parameter !== null) {
				 * 				return createEventParameterReference(port, parameter) 
				 * 			}
				 * 		}
				 * 	}
				 }*/

				return null
			}
		}
	}

}
