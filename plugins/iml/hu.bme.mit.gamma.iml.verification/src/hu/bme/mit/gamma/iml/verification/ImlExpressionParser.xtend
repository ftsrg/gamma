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

import hu.bme.mit.gamma.expression.model.BinaryExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.OpaqueExpression
import hu.bme.mit.gamma.expression.model.UnaryExpression
import hu.bme.mit.gamma.querygenerator.ImlQueryGenerator
import hu.bme.mit.gamma.querygenerator.ThetaQueryGenerator
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.theta.verification.XstsBackAnnotator
import hu.bme.mit.gamma.trace.model.TraceModelFactory
import hu.bme.mit.gamma.trace.util.TraceUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.util.JavaUtil
import hu.bme.mit.gamma.verification.util.TraceBuilder
import java.util.Scanner
import java.util.logging.Logger

import static hu.bme.mit.gamma.xsts.iml.transformation.util.Namings.*

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class ImlExpressionParser {
	//
	public static val preprocessExpressions = #{ "&&" -> "and", "||" -> "or", "=" -> "==", "<>" -> "!=",
			"+." -> "+", "-." -> "-", "*." -> "*", "/." -> "/", "." + ENUM_LITERAL_PREFIX -> "::" + ENUM_LITERAL_PREFIX /* Only for enums, not records */}
	// TODO arrays?
	protected final ThetaQueryGenerator imlQueryGenerator
	protected final extension XstsBackAnnotator xStsBackAnnotator
	protected static final Object engineSynchronizationObject = new Object // For the VIATRA engine in the query generator
	
	protected final Package gammaPackage
	protected final Component component
	
	protected final Scanner scanner
	
	// Auxiliary objects
	protected final extension TraceModelFactory trFact = TraceModelFactory.eINSTANCE
	protected final extension TraceUtil traceUtil = TraceUtil.INSTANCE
	protected final extension JavaUtil javaUtil = JavaUtil.INSTANCE
	protected final extension TraceBuilder traceBuilder = TraceBuilder.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	protected final Logger logger = Logger.getLogger("GammaLogger")
	//
	
	new(Package gammaPackage, Scanner scanner) {
		this.gammaPackage = gammaPackage
		this.component = gammaPackage.firstComponent
		synchronized (engineSynchronizationObject) { // Due to the VIATRA engine
			this.imlQueryGenerator = new ImlQueryGenerator(component)
		}
		this.xStsBackAnnotator = new XstsBackAnnotator(imlQueryGenerator,
				ImlArrayParser.INSTANCE, "_", preprocessExpressions)
		this.scanner = scanner
	}
	
	//
	
	def execute() {
		val expressions = newArrayList
		
		while (scanner.hasNextLine) {
			val line = scanner.nextLine
			val expression = line.parse
			expressions += expression
		}
		
		val postprocessedExpressions = expressions.postprocess
		
		return postprocessedExpressions
	}
	
	//
	
	protected def parse(String text) {
		val expression = xStsBackAnnotator.parseExpression(text)
		
		return expression
	}
	
	//
	
	protected def postprocess(Iterable<? extends Expression> expressions) {
		val newExpressions = <Expression>newArrayList
		
		for (expression : expressions) {
			var filtered = false
			
			var checkableExpression = expression
			if (expression instanceof UnaryExpression) {
				checkableExpression = expression.operand
			}
			// Note: no 'else'
			if (checkableExpression instanceof BinaryExpression) {
				val left = checkableExpression.leftOperand
				val right = checkableExpression.rightOperand
				if (left.needsFiltering) {
					filtered = true // Intermediate variables
				}
				else if (right instanceof OpaqueExpression) {
					if (right.havoc) {
						right.expression = "Anything"
					}
				}
			}
			
			if (!filtered) {
				newExpressions += xStsBackAnnotator.postprocess(expression)
			}
		}
		
		return newExpressions
	}
	
	protected def needsFiltering(Expression expression) {
		expression.getSelfAndAllContentsOfType(OpaqueExpression)
				.exists[it.expression.matches(".+_[0-9]+")]
	}
	
	protected def isHavoc(Expression expression) {
		if (expression instanceof OpaqueExpression) {
			return expression.needsFiltering // Are more checks needed to identify havocs?
		}
		return false
	}
	
}