/********************************************************************************
 * Copyright (c) 2020-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution) and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.uppaal.util

import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.Set
import java.util.logging.Level
import java.util.logging.Logger
import org.eclipse.emf.ecore.EObject
import uppaal.declarations.DataVariableDeclaration
import uppaal.expressions.AssignmentExpression
import uppaal.expressions.IdentifierExpression
import uppaal.expressions.LiteralExpression
import uppaal.expressions.LogicalOperator
import uppaal.statements.ExpressionStatement
import uppaal.templates.Edge
import uppaal.templates.Location
import uppaal.templates.LocationKind
import uppaal.types.RangeTypeSpecification
import uppaal.types.TypesFactory

import static extension de.uni_paderborn.uppaal.derivedfeatures.UppaalModelDerivedFeatures.*

class NtaOptimizer {
	
	protected extension final NtaBuilder ntaBuilder
	protected extension final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	//
	protected final extension TypesFactory typFact = TypesFactory.eINSTANCE
	// Logger
	protected final Logger logger = Logger.getLogger("GammaLogger")
	//
	new(NtaBuilder ntaBuilder) {
		this.ntaBuilder = ntaBuilder
	}
	
	def void optimizeSubsequentEdges(Location location) {
		val outgoingEdges = newHashSet
		outgoingEdges += location.outgoingEdges
		outgoingEdges.optimizeSubsequentEdges(newHashSet)
	}
	
	def void optimizeSubsequentEdges(Set<Edge> edges, Set<Edge> visitedEdges) {
		while (!edges.empty) {
			val firstEdge = edges.head
			visitedEdges += firstEdge
			edges -= firstEdge
			val source = firstEdge.source
			val target = firstEdge.target
			val targetIncomingEdges = target.incomingEdges
			targetIncomingEdges -= firstEdge
			val targetOutgoingEdges = target.outgoingEdges
			if (firstEdge.isEmpty) {
				// Everything is empty, the edge is unnecessary
				if (source.locationTimeKind == LocationKind.COMMITED) {
					// Only if the source is committed
					val sourceIncomingEdges = source.incomingEdges
					val sourceOutgoingEdges = source.outgoingEdges
					if (sourceOutgoingEdges.size == 1) {
						for (incomingEdge : sourceIncomingEdges) {
							incomingEdge.target = target
						}
						firstEdge.remove // Delete does not work due to unsupported basicGetTypeDefinition
						source.remove
					}
				}
			}
			else if (target.locationTimeKind == LocationKind.COMMITED) {
				// Only if the target is committed (we cannot go through normal locations)
				if (targetIncomingEdges.empty && firstEdge.hasOnlyGuard) {
					// Only guard
					val guard = firstEdge.guard
					if (targetOutgoingEdges.forall[it.hasOnlyGuard]) {
						for (outgoingEdge : targetOutgoingEdges) {
							outgoingEdge.addGuard(guard.clone, LogicalOperator.AND)
							outgoingEdge.source = source
						}
						firstEdge.remove // Delete does not work due to unsupported basicGetTypeDefinition
						target.remove
					}
				}
				else if (targetIncomingEdges.empty && firstEdge.hasOnlyUpdate) {
					// Only updates
					val updates = firstEdge.update
					if (targetOutgoingEdges.forall[it.hasOnlyUpdate]) {
						for (outgoingEdge : targetOutgoingEdges) {
							outgoingEdge.update.addAll(0, updates.map[it.clone])
							outgoingEdge.source = source
						}
						firstEdge.remove // Delete does not work due to unsupported basicGetTypeDefinition
						target.remove
					}
				}
			}
			// Recursion
			for (outgoingEdge : targetOutgoingEdges.reject[visitedEdges.contains(it)]) {
				edges += outgoingEdge
			}
		}
	}
	
	//
	
	def optimizelIntegerCodomains() {
		val nta = ntaBuilder.nta
		val integerVariableCodomains = nta.integerVariableCodomains
		
		for (integerVariable : integerVariableCodomains.keySet) {
			val codomain = integerVariableCodomains.get(integerVariable)
			
			val min = codomain.key
			val max = codomain.value
			
			// Limiting or extending the codomain of the integer variable
			integerVariable.typeDefinition = typFact.createRangeTypeSpecification => [
				it.bounds = createIntegerBounds => [
					it.lowerBound = min.toString.createLiteralExpression
					it.upperBound = max.toString.createLiteralExpression
				]
			]
		}
		
		// Optimization for trivial codomains
		val tirivialCodomainIntegerVariables = nta.getAllContentsOfType(DataVariableDeclaration)
				.map[it.typeDefinition]
				.filter(RangeTypeSpecification)
				.map[it.bounds]
				.filter[it.lowerBound instanceof LiteralExpression &&
					it.upperBound instanceof LiteralExpression &&
						(it.lowerBound as LiteralExpression).toInteger ==
							(it.upperBound as LiteralExpression).toInteger]
				.map[it.getContainerOfType(DataVariableDeclaration)]
				.toSet
		val identifiers = nta.getAllContentsOfType(IdentifierExpression)
		for (integerVariable : tirivialCodomainIntegerVariables) {
			val type = integerVariable.typeDefinition as RangeTypeSpecification
			val literalExpression = type.bounds.lowerBound // Or upper (LiteralExpression)
			// Deleting variables
			val variable = integerVariable.variable.head
			for (relevantIdentifier : identifiers
					.filter[it.identifier === variable].toSet) {
				val literal = literalExpression.clone
				
				val container = relevantIdentifier.eContainer
				if (container instanceof AssignmentExpression &&
						(container as AssignmentExpression)
								.firstExpr === relevantIdentifier) {
					// Lhs - replacing assignment to the value
					literal.replace(container)
				}
				else {
					// Changing the reference to a literal value
					literal.replace(relevantIdentifier)
				}
				// Mild optimization
				identifiers -= relevantIdentifier
			}
			
			// Not deleting global declarations to avoid messing up out events
			if (integerVariable.global) {
				integerVariable.variable.head.initializer = null
			}
			else {
				logger.log(Level.INFO, "Deleting trivial local variable: " + variable.name)
				integerVariable.remove
			}
		}
		
		// Removing '0;' like statements
		val literalExpressions = nta.getAllContentsOfType(LiteralExpression)
		
		val removableLiteralStatements = <EObject>newArrayList
		removableLiteralStatements += literalExpressions
				.map[it.eContainer]
				.filter(ExpressionStatement)
		removableLiteralStatements += literalExpressions
				.filter[it.eContainer instanceof Edge &&
					(it.eContainer as Edge).update.contains(it)]
		
		for (removableLiteralStatement : removableLiteralStatements) {
			if (removableLiteralStatement.isContainedByList) {
				removableLiteralStatement.remove
			}
			else {
				createEmptyStatement.replace(removableLiteralStatement) // To avoid nullptr
			}
		}
	}
	
}