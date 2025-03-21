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

import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.OpaqueExpression
import hu.bme.mit.gamma.querygenerator.ImlQueryGenerator
import hu.bme.mit.gamma.querygenerator.ThetaQueryGenerator
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceEventParameterReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceEventReferenceExpression
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

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class ImlExpressionParser {
	//
	public static val preprocessExpressions = #{ "&&" -> "and", "||" -> "or", "=" -> "==", "<>" -> "!=",
			"+." -> "+", "-." -> "-", "*." -> "*", "/." -> "/", "." -> "::" }
	//
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
		
		if (expression instanceof OpaqueExpression) {
			val opaque = expression.expression.deparenthesize.trim
			
			val potentialStateString = opaque.replace("::", ".") // Preprocessed IML '.' to Gamma '::' in enums
			if (imlQueryGenerator.isSourceState(potentialStateString)) {
				val stateInstance = imlQueryGenerator.getSourceState(potentialStateString)
				val state = stateInstance.key
				val instance = stateInstance.value
				
				val stateExpression = instance.createInstanceReference.createStateReference(state)
				
				return stateExpression
			}
		}
		
		return expression
	}
	
	//
	
	protected def postprocess(Iterable<? extends Expression> expressions) {
		val newExpressions = <Expression>newArrayList
		
		for (expression : expressions) {
			var filtered = false
			
			if (expression instanceof EqualityExpression) {
				val left = expression.leftOperand
				val right = expression.rightOperand
				if (left instanceof OpaqueExpression) {
					filtered = true // Intermediate variables
				}
				else if (right instanceof OpaqueExpression) {
					right.expression = "Anything" // Are more checks needed to identify havocs?
				}
			}
			
			if (!filtered) {
				newExpressions += expression.postprocess
			}
		}
		
		return newExpressions
	}
	
	protected def Expression postprocess(Expression expression) {
		if (expression instanceof ComponentInstanceEventReferenceExpression) {
			val port = expression.port
			val systemPort = port.boundTopComponentPort
			
			return systemPort.createRaiseEventAct(expression.event)
		}
		else if (expression instanceof ComponentInstanceEventParameterReferenceExpression) {
			val port = expression.port
			val systemPort = port.boundTopComponentPort
			
			return systemPort.createEventParameterReference(expression.parameterDeclaration)
		}
		
		val subexpressions = expression.getAllContentsOfType(Expression)
		for (subexpression : subexpressions) {
			val newSubexpression = subexpression.postprocess
			newSubexpression.replace(subexpression)
		}
		
		return expression
	}
	
}