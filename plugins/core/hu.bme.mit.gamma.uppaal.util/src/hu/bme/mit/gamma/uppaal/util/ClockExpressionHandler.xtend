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
import uppaal.expressions.BinaryExpression
import uppaal.expressions.Expression
import uppaal.expressions.IdentifierExpression
import uppaal.expressions.LogicalExpression
import uppaal.templates.Edge
import uppaal.templates.LocationKind
import uppaal.templates.Template
import uppaal.templates.TemplatesFactory

import static extension de.uni_paderborn.uppaal.derivedfeatures.UppaalModelDerivedFeatures.*


import static com.google.common.base.Preconditions.checkArgument
import static com.google.common.base.Preconditions.checkState

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
			.filter[it.containsClockReference] // clock
//			.map[it.eContainer] // clock <= 1000
		
		val clockEdges = clockGuards.map[it.getContainerOfType(Edge)]
		for (clockEdge : clockEdges) {
			val guard = clockEdge.guard
			guard.transformClockExpression
		}
	}
	
	//
	
	protected def containsClockReference(Expression expression) {
		return expression !== null &&
			!expression.getSelfAndAllContentsOfType(IdentifierExpression)
				.filter[it.identifier.clock]
				.isEmpty
	}
	
	//
	
	def dispatch void transformClockExpression(Expression expression) {
		throw new IllegalArgumentException("Not known expression: " + expression)
	}
	
	def dispatch void transformClockExpression(IdentifierExpression expression) {
		checkArgument(expression.identifier.clock, "Identifier is not a clock")
	}
	
	def dispatch void transformClockExpression(BinaryExpression expression) {
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
	}
	
	def dispatch void transformClockExpression(LogicalExpression expression) {
		val edge = expression.getContainerOfType(Edge)
		val template = edge.eContainer as Template
		
		val first = expression.firstExpr
		val operator = expression.operator
		val second = expression.secondExpr
		
		switch (operator) {
			case AND: {
				if (first.containsClockReference || second.containsClockReference) {
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
					
					checkState(expression.eContainer instanceof Edge)
					edge.remove
				}
			}
			case OR: {
				val firstClonedEdge = edge.clone
				template.edge += firstClonedEdge
				firstClonedEdge.guard = first //
				
				val secondClonedEdge = edge.clone
				template.edge += secondClonedEdge
				secondClonedEdge.guard = second //
				
				checkState(expression.eContainer instanceof Edge)
				edge.remove
			}
			default:
				throw new IllegalArgumentException("Not known operator: " + operator)
		}
		
		if (first.containsClockReference) {
			first.transformClockExpression
		}
		if (second.containsClockReference) {
			second.transformClockExpression
		}
		
	}
	
}