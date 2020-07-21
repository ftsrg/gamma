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
package hu.bme.mit.gamma.uppaal.util

import hu.bme.mit.gamma.util.GammaEcoreUtil
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import uppaal.NTA
import uppaal.UppaalFactory
import uppaal.declarations.DataVariableDeclaration
import uppaal.declarations.DataVariablePrefix
import uppaal.declarations.Declarations
import uppaal.declarations.DeclarationsFactory
import uppaal.declarations.Function
import uppaal.declarations.Variable
import uppaal.declarations.VariableContainer
import uppaal.declarations.system.SystemFactory
import uppaal.expressions.AssignmentExpression
import uppaal.expressions.CompareOperator
import uppaal.expressions.Expression
import uppaal.expressions.ExpressionsFactory
import uppaal.expressions.LogicalOperator
import uppaal.statements.ExpressionStatement
import uppaal.templates.Edge
import uppaal.templates.Location
import uppaal.templates.LocationKind
import uppaal.templates.Selection
import uppaal.templates.SynchronizationKind
import uppaal.templates.Template
import uppaal.templates.TemplatesFactory
import uppaal.types.BuiltInType
import uppaal.types.PredefinedType
import uppaal.types.TypeDefinition
import uppaal.types.TypesFactory

class NtaBuilder {
	// NTA target model
	final NTA nta
	// Is minimal element set (function inlining)
	final boolean isMinimalElementSet
	// UPPAAL factories
	protected final extension ExpressionsFactory expFact = ExpressionsFactory.eINSTANCE
	protected final extension TemplatesFactory tempFact = TemplatesFactory.eINSTANCE
	protected final extension UppaalFactory upFact = UppaalFactory.eINSTANCE
	protected final extension DeclarationsFactory declFact= DeclarationsFactory.eINSTANCE
	protected final extension TypesFactory typFact= TypesFactory.eINSTANCE
	protected final extension SystemFactory sysFact= SystemFactory.eINSTANCE
	// Auxiliary objects
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	new(String ntaName, boolean isMinimalElementSet) {
		this.nta = createNTA => [
			it.name = ntaName
		]
		this.isMinimalElementSet = isMinimalElementSet
		this.initNta
	}
	
	/**
	 * This method is responsible for the initialization of the NTA.
	 * It creates the global and system declaration collections and the predefined types.
	 */
	private def initNta() {
		nta.globalDeclarations = createGlobalDeclarations
		nta.systemDeclarations = createSystemDeclarations => [
			it.system = createSystem
		]
		nta.int = createPredefinedType => [
			it.name = "integer"
			it.type = BuiltInType.INT
		]
		nta.bool = createPredefinedType => [
			it.name = "boolean"
			it.type = BuiltInType.BOOL
		]
		nta.void = createPredefinedType => [
			it.name = "void"
			it.type = BuiltInType.VOID
		]
		nta.clock = createPredefinedType => [
			it.name = "clock"
			it.type = BuiltInType.CLOCK
		]
		nta.chan = createPredefinedType => [
			it.name = "channel"
			it.type = BuiltInType.CHAN
		]
	}
	
	/**
	 * Creates a template with the given name and an initial location called InitLoc.
	 */
	def createTemplateWithInitLoc(String templateName, String locationName) {
		val template = createTemplate => [
			it.name = templateName
			it.declarations = createLocalDeclarations
		]
		nta.template += template
		val initLoc = createLocation => [
			it.name = locationName
		]
		template.location += initLoc
		template.init = initLoc
		return initLoc
	}
	
	def addFunctionCall(EObject container, EReference reference, Function function) {
		if (isMinimalElementSet && function.isInlinable) {
			// Deleting the function from the model tree
			val functionContainer = function.eContainer
			functionContainer.delete
			val block = function.block
			for (statement : block.statement) {
				if (statement instanceof ExpressionStatement) {
					val expression = statement.expression.clone(true, true)
					container.add(reference, expression)
				}
			}
		}
		else {
			val functionCallExpression = createFunctionCallExpression => [
				it.function = function
			]
			container.add(reference, functionCallExpression)
		}
	}
	
	private def boolean isInlinable(Function function) {
		val statements = function.block.statement
		if (statements.forall[it instanceof ExpressionStatement]) {
			// Block of assignments or a single expression
			return (statements.filter(ExpressionStatement)
				.map[it.expression]
				.forall[it instanceof AssignmentExpression]) ||
				(statements.size == 1)
		}
		return false
	}
	
	def Selection addBooleanSelection(Edge edge, String name) {
		val select = createSelection
		select.createIntTypeWithRangeAndVariable(
			createLiteralExpression => [it.text = "0"],
			createLiteralExpression => [it.text = "1"],
			name
		)
		edge.selection += select
		return select
	}
	
	def createIntTypeWithRangeAndVariable(VariableContainer container, Expression lowerBound,
			Expression upperBound, String name) {		
		container.typeDefinition = createRangeTypeSpecification => [
			it.bounds = createIntegerBounds => [
				it.lowerBound = lowerBound
				it.upperBound = upperBound
			]
		]
		// Creating variables for all statechart instances
		container.variable += createVariable => [
			it.container = container
			it.name = name
		]
	}
	
	/**
	 * This method is responsible for creating the variables in the resource depending on the received parameters.
	 * It also creates the traces.
	 */
	def createSynchronization(Declarations declarations, boolean isBroadcast, boolean isUrgent, String name) {
		val syncContainer = createChannelVariableDeclaration => [
			it.broadcast = isBroadcast
			it.urgent = isUrgent
		]
		declarations.declaration += syncContainer
		syncContainer.createTypeAndVariable(nta.chan, name)
		return syncContainer
	}
	
	/**
	 * This method is responsible for creating the variables in the resource depending on the received parameters.
	 * It also creates the traces.
	 */
	def createVariable(Declarations declarations, DataVariablePrefix prefix, PredefinedType type, String name) {
		val varContainer = createDataVariableDeclaration => [
			it.prefix = prefix
		]
		declarations.declaration += varContainer
		varContainer.createTypeAndVariable(type, name)		
		return varContainer
	}
	
	/**
	 * Initializes a variable with the given string value.
	 */
	def initVar(DataVariableDeclaration variable, String value) {		
		val firstVariable = variable.variable.head
		firstVariable.initializer = createExpressionInitializer => [
			it.expression = createLiteralExpression => [
				it.text = value
			]
		]
	}
	
	/**
	 * This method creates the variables of the given containers based on the given predefined type and name.
	 */
	def createTypeAndVariable(VariableContainer container, PredefinedType type, String name) {		
		val typeReference = createTypeReference => [
			it.referredType = type
		]
		return container.createTypeAndVariable(typeReference, name)
	}
	
	def createTypeAndVariable(VariableContainer container, TypeDefinition type, String name) {		
		container.typeDefinition = type
		return container.createVariable(name)
	}
	
	def createVariable(VariableContainer container, String name) {
		val variable = createVariable => [
			it.container = container
			it.name = name
		]
		container.variable += variable
		return variable
	}
	
	def Location createLocation(Template template) {
		val location = createLocation
		template.location += location
		return location
	}
	
	/**
	 * Responsible for creating an edge in the given template with the given source and target.
	 */
	def Edge createEdge(Location source, Location target) {
		if (source.parentTemplate != target.parentTemplate) {
			throw new IllegalArgumentException("The source and the target are in different templates." + source + " " + target)
		}
		val template = source.parentTemplate
		val edge = createEdge => [
			it.source = source
			it.target = target
		]
		template.edge += edge
		return edge
	}
	
	/**
	 * Appends a variable declaration as a guard to the guard of the given edge. The operator between the old and the new guard can be given too.
	 */
	def addGuard(Edge edge, DataVariableDeclaration guard, LogicalOperator operator) {
		if (edge.guard !== null) {
			// Getting the old reference
			val oldGuard = edge.guard as Expression
			// Creating the new andExpression that will contain the same reference and the regular guard expression
			edge.guard = createLogicalExpression => [
				it.firstExpr = createIdentifierExpression => [
					it.identifier = guard.variable.head
				]
				it.operator = operator
				it.secondExpr = oldGuard
			]
		}
		// If there is no guard yet
		else {
			edge.guard = createIdentifierExpression => [
				it.identifier = guard.variable.head
			]
		}
		return edge.guard
	}
	
	def addGuard(Edge edge, DataVariableDeclaration guard, Expression notEqual, LogicalOperator operator) {
		if (edge.guard !== null) {
			// Getting the old reference
			val oldGuard = edge.guard as Expression
			// Creating the new andExpression that will contain the same reference and the regular guard expression
			edge.guard = createLogicalExpression => [
				it.firstExpr = createCompareExpression => [
					it.firstExpr = createIdentifierExpression => [
						it.identifier = guard.variable.head
					]
					it.operator = CompareOperator.UNEQUAL
					it.secondExpr = notEqual.clone(true, true)
				]
				it.operator = operator
				it.secondExpr = oldGuard
			]
		}
		// If there is no guard yet
		else {
			edge.guard = createIdentifierExpression => [
				it.identifier = guard.variable.head
			]
		}
		return edge.guard
	}
	
	/**
	 * Appends an UPPAAL guard to the guard of the given edge. The operator between the old and the new guard can be given too.
	 */
	def addGuard(Edge edge, Expression guard, LogicalOperator operator) {
		if (edge.guard !== null && guard !== null) {
			// Getting the old reference
			val oldGuard = edge.guard as Expression
			// Creating the new andExpression that will contain the same reference and the regular guard expression
			edge.guard = createLogicalExpression => [
				it.firstExpr = guard
				it.operator = operator
				it.secondExpr = oldGuard
			]
		}
		// If there is no guard yet
		else {
			edge.guard = guard
		}
		return edge.guard
	}
	
	def Edge createEdgeCommittedTarget(Location target, String name) {
		val template = target.parentTemplate
		val syncLocation = template.createLocation => [
			it.name = name
			it.locationTimeKind = LocationKind.COMMITED
		]
		template.location += syncLocation
		val syncEdge = syncLocation.createEdge(target)
		return syncEdge		
	}
	
	/**
	 * Responsible for creating a ! synchronization on an edge and a committed location as the source of the edge.
	 * The target of the synchronized edge will be the given "target" location.
	 */
	def Edge createCommittedSyncTarget(Location target, Variable syncVar, String name) {
		val syncEdge = target.createEdgeCommittedTarget(name) => [
			it.setSynchronization(syncVar, SynchronizationKind.SEND)
		]
		return syncEdge		
	}
	
	/**
	 * Responsible for placing a synchronization onto the given edge: "channel?/channel!".
	 */
	def void setSynchronization(Edge edge, Variable syncVar, SynchronizationKind syncType) {
		edge.synchronization = createSynchronization => [
			it.kind = syncType
			it.channelExpression = createIdentifierExpression => [
				it.identifier = syncVar
			]
		]	
	}
	
	/**
	 * Responsible for creating a synchronization edge from the given source to target with the given sync channel and snyc kind.
	 */
	def Edge createEdgeWithSync(Location sourceLoc, Location targetLoc, Variable syncVar, SynchronizationKind syncKind) {
		val loopEdge = sourceLoc.createEdge(targetLoc)
		loopEdge.setSynchronization(syncVar, syncKind)	
		return loopEdge
	}
	
	def getNta() {
		return nta
	}
	
}