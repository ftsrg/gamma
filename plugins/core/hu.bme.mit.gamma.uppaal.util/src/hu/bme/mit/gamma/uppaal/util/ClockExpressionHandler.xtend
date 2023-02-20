/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.uppaal.util

import hu.bme.mit.gamma.util.GammaEcoreUtil
import uppaal.NTA
import uppaal.expressions.Expression
import uppaal.expressions.IdentifierExpression
import uppaal.expressions.LogicalExpression
import uppaal.expressions.LogicalOperator
import uppaal.templates.Edge
import uppaal.templates.LocationKind
import uppaal.templates.Template
import uppaal.templates.TemplatesFactory

import static com.google.common.base.Preconditions.checkState

import static extension de.uni_paderborn.uppaal.derivedfeatures.UppaalModelDerivedFeatures.*

class ClockExpressionHandler {
	// Singleton
	public static final ClockExpressionHandler INSTANCE =  new ClockExpressionHandler
	protected new() {}
	//
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	// UPPAAL factories
	protected final extension TemplatesFactory templatesFactory = TemplatesFactory.eINSTANCE
	
	def transformClockExpressions(NTA nta) {
		val edges = nta.getAllContentsOfType(Edge)
		val guards = edges.map[it.guard].filterNull
		
		val clockGuards = guards
			.filter[it.containsClockReferencesInOr] // clock
//			.map[it.eContainer] // clock <= 1000
		
		val clockEdges = clockGuards.map[it.getContainerOfType(Edge)]
		for (clockEdge : clockEdges) {
			val guard = clockEdge.guard
			guard.transformClockExpression
		}
	}
	
	//
	
	protected def containsClockReferencesInOr(Expression expression) {
		return expression !== null &&
			expression.getSelfAndAllContentsOfType(LogicalExpression)
				.filter[it.operator == LogicalOperator.OR]
				.exists[it.firstExpr.containsClockReference &&
						it.secondExpr.containsClockReference]
	}
	
	private def containsClockReference(Expression expression) {
		return expression !== null &&
			!expression.getSelfAndAllContentsOfType(IdentifierExpression)
				.filter[it.identifier.clock]
				.isEmpty
	}
	
	//
	
	def dispatch void transformClockExpression(Expression expression) {
		throw new IllegalArgumentException("Not known expression: " + expression)
	}
	
//	def dispatch void transformClockExpression(IdentifierExpression expression) {
//		checkArgument(expression.identifier.clock, "Identifier is not a clock")
//	}
//	
//	def dispatch void transformClockExpression(BinaryExpression expression) {
//		val first = expression.firstExpr
//		val second = expression.secondExpr
//		
//		if (first.containsClockReference) {
//			first.transformClockExpression
//		}
//		if (second.containsClockReference) {
//			second.transformClockExpression
//		}
		// All potential binary expressions have side effects - cannot be used as guards
//	}
	
	def dispatch void transformClockExpression(LogicalExpression expression) {
		val edge = expression.getContainerOfType(Edge)
		val template = edge.eContainer as Template
		
		val first = expression.firstExpr
		val operator = expression.operator
		val second = expression.secondExpr
		
		var needRecursion = false // To avoid code duplication
		switch (operator) {
			case AND: {
				if (expression.containsClockReferencesInOr) {
					val firstClonedEdge = edge.clone
					template.edge += firstClonedEdge
					firstClonedEdge.guard = first //
					firstClonedEdge.update.clear
					
					val location = createLocation => [
						it.name = "_clock_" + firstClonedEdge.hashCode.toString.replaceAll("-", "_")
						it.locationTimeKind = LocationKind.COMMITED
					]
					template.location += location
					firstClonedEdge.target = location
					
					val secondClonedEdge = edge.clone
					template.edge += secondClonedEdge
					secondClonedEdge.selection.clear
					secondClonedEdge.synchronization = null
					secondClonedEdge.guard = second //
					secondClonedEdge.source = location
					
					needRecursion = true
				}
			}
			case OR: {
				if (expression.containsClockReferencesInOr) {
					val firstClonedEdge = edge.clone
					template.edge += firstClonedEdge
					firstClonedEdge.guard = first //
					
					val secondClonedEdge = edge.clone
					template.edge += secondClonedEdge
					secondClonedEdge.guard = second //
					
					needRecursion = true
				}
			}
			default:
				throw new IllegalArgumentException("Not known operator: " + operator)
		}
		
		if (needRecursion) {
			if (first.containsClockReferencesInOr) {
				first.transformClockExpression
			}
			if (second.containsClockReferencesInOr) {
				second.transformClockExpression
			}
			
			checkState(expression.eContainer instanceof Edge)
			edge.remove
		}
	}
	
}