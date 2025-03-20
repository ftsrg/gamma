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
package hu.bme.mit.gamma.iml.verification

import hu.bme.mit.gamma.querygenerator.ImlQueryGenerator
import hu.bme.mit.gamma.querygenerator.ThetaQueryGenerator
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.theta.verification.XstsBackAnnotator
import hu.bme.mit.gamma.trace.model.TraceModelFactory
import hu.bme.mit.gamma.trace.util.TraceUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.verification.util.TraceBuilder
import java.util.Scanner
import java.util.logging.Logger

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.expression.model.OpaqueExpression

class ImlExpressionParser {
	//
	public static val preprocessExpressions = #{ "&&" -> "and", "||" -> "or", "<>" -> "!=",
			"+." -> "+", "-." -> "-", "*." -> "*", "/." -> "/" }
	//
	protected final ThetaQueryGenerator imlQueryGenerator
	protected final extension XstsBackAnnotator xStsBackAnnotator
	protected static final Object engineSynchronizationObject = new Object // For the VIATRA engine in the query generator
	
	protected final Package gammaPackage
	protected final Component component
	
	// Auxiliary objects
	protected final extension TraceModelFactory trFact = TraceModelFactory.eINSTANCE
	protected final extension TraceUtil traceUtil = TraceUtil.INSTANCE
	protected final extension TraceBuilder traceBuilder = TraceBuilder.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	protected final Logger logger = Logger.getLogger("GammaLogger")
	//
	
	new(Package gammaPackage, Scanner traceScanner) {
		this(gammaPackage, traceScanner, true)
	}
	
	new(Package gammaPackage, Scanner traceScanner, boolean sortTrace) {
		this.gammaPackage = gammaPackage
		this.component = gammaPackage.firstComponent
		synchronized (engineSynchronizationObject) { // Due to the VIATRA engine
			this.imlQueryGenerator = new ImlQueryGenerator(component)
		}
		this.xStsBackAnnotator = new XstsBackAnnotator(imlQueryGenerator,
				ImlArrayParser.INSTANCE, "_", preprocessExpressions)
	}
	
	def parse(String text) {
		val expression = xStsBackAnnotator.parseExpression(text)
		println(expression)
		
		val equalities = expression.getSelfAndAllContentsOfType(EqualityExpression)
		for (equality : equalities) {
			val lhs = equality.leftOperand
			val rhs = equality.rightOperand
			
			if (lhs instanceof OpaqueExpression) {
				if (rhs instanceof OpaqueExpression) {
					val id = lhs.expression
					val enum = rhs.expression
					
					val potentialState = '''«id» == «enum»'''
					
					if (imlQueryGenerator.isSourceState(potentialState)) {
						val stateInstance = imlQueryGenerator.getSourceState(potentialState)
						val state = stateInstance.key
						val instance = stateInstance.value
						
						val stateExpression = instance.createInstanceReference.createStateReference(state)
						
						stateExpression.replace(equality)
					}
				}
			}
		}
		
		return expression
	}
	
}