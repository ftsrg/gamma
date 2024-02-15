/********************************************************************************
 * Copyright (c) 2018-2023 Contributors to the Gamma project
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
import java.util.List
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import uppaal.NTA
import uppaal.UppaalFactory
import uppaal.core.NamedElement
import uppaal.declarations.DataVariableDeclaration
import uppaal.declarations.DataVariablePrefix
import uppaal.declarations.Declaration
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
import uppaal.statements.Block
import uppaal.statements.ExpressionStatement
import uppaal.statements.Statement
import uppaal.statements.StatementsFactory
import uppaal.templates.Edge
import uppaal.templates.Location
import uppaal.templates.LocationKind
import uppaal.templates.SynchronizationKind
import uppaal.templates.Template
import uppaal.templates.TemplatesFactory
import uppaal.types.BuiltInType
import uppaal.types.PredefinedType
import uppaal.types.Type
import uppaal.types.TypeDefinition
import uppaal.types.TypesFactory

class NtaBuilder {
	// NTA target model
	final NTA nta
	// Is minimal element set (function inlining)
	final boolean isMinimalElementSet
	
	protected final extension AssignmentExpressionCreator assignmentExpressionCreator
	// UPPAAL factories
	protected final extension ExpressionsFactory expFact = ExpressionsFactory.eINSTANCE
	protected final extension TemplatesFactory tempFact = TemplatesFactory.eINSTANCE
	protected final extension UppaalFactory upFact = UppaalFactory.eINSTANCE
	protected final extension DeclarationsFactory declFact = DeclarationsFactory.eINSTANCE
	protected final extension TypesFactory typFact = TypesFactory.eINSTANCE
	protected final extension SystemFactory sysFact = SystemFactory.eINSTANCE
	protected final extension StatementsFactory stmtsFactory = StatementsFactory.eINSTANCE
	// Auxiliary objects
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	new(String ntaName) {
		this(ntaName, false)
	}
	
	new(String ntaName, boolean isMinimalElementSet) {
		this.nta = createNTA => [
			it.name = ntaName
		]
		this.isMinimalElementSet = isMinimalElementSet
		this.assignmentExpressionCreator = new AssignmentExpressionCreator(this)
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
					val expression = statement.expression.clone
					container.add(reference, expression)
				}
			}
		}
		else {
			val functionCallExpression = function.createFunctionCallExpression
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
	
		
	def createIdentifierExpression(VariableContainer variable) {
		return variable.variable.head.createIdentifierExpression
	}
	
	def createIdentifierExpression(NamedElement element) {
		return createIdentifierExpression => [
			it.identifier = element
		]
	}
	
	def addBooleanSelection(Edge edge, String name) {
		val selection = name.createBooleanSelection
		edge.selection += selection
		return selection
	}
	
	def void addIntegerSelection(Edge edge, String name,
			Expression lowerBound, Expression upperBound) {
		edge.selection += name.createIntegerSelection(lowerBound, upperBound)
	}
	
	def createBooleanSelection(String name) {
		val select = createSelection
		select.createRangedIntegerVariable(name, createLiteralExpression => [it.text = "0"],
			createLiteralExpression => [it.text = "1"])
		return select
	}
	
	def createIntegerSelection(String name, Expression lowerBound, Expression upperBound) {
		val select = createSelection
		select.createRangedIntegerVariable(name, lowerBound, upperBound)
		return select
	}
	
	def createRangedIntegerVariable(VariableContainer container, String name,
			Expression lowerBound, Expression upperBound) {
		container.typeDefinition = createRangeTypeSpecification => [
			it.bounds = createIntegerBounds => [
				it.lowerBound = lowerBound
				it.upperBound = upperBound
			]
		]
		container.variable += createVariable => [
			it.container = container
			it.name = name
		]
	}
	
	/**
	 * This method is responsible for creating the variables in the resource depending on the received parameters.
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
	 */
	def createVariable(Declarations declarations, DataVariablePrefix prefix, PredefinedType type, String name) {
		val varContainer = prefix.createVariable(type, name)
		declarations.declaration += varContainer
		return varContainer
	}
	
	def createVariable(DataVariablePrefix prefix, PredefinedType type, String name) {
		val typeReference = type.createTypeReference
		return typeReference.createVariable(name) => [
			it.prefix = prefix
		]
	}
	
	def createVariable(TypeDefinition type, String name) {
		val varContainer = createDataVariableDeclaration
		varContainer.createTypeAndVariable(type, name)		
		return varContainer
	}
	
	def createTypeReference(Type type) {
		return createTypeReference => [
			it.referredType = type
		]
	}
	
	/**
	 * Initializes a variable with the given string value.
	 */
	def initVar(DataVariableDeclaration variable, String value) {
		variable.initVar(
			value.createLiteralExpression)
	}
	
	def initVar(DataVariableDeclaration variable, Expression expression) {
		val firstVariable = variable.variable.head
		firstVariable.initializer = createExpressionInitializer => [
			it.expression = expression
		]
	}
	
	def createLiteralExpression(String literal) {
		return createLiteralExpression => [
			it.text = literal
		]
	}
	
	def createEqualityExpression(VariableContainer variable, Expression rhs) {
		return variable.createIdentifierExpression
				.createCompareExpression(rhs, CompareOperator.EQUAL)
	}
	
	def createLessEqualityExpression(VariableContainer variable, Expression rhs) {
		return variable.createIdentifierExpression
				.createCompareExpression(rhs, CompareOperator.LESS_OR_EQUAL)
	}
	
	def createGreaterExpression(VariableContainer variable, Expression rhs) {
		return variable.createIdentifierExpression
				.createCompareExpression(rhs, CompareOperator.GREATER)
	}
	
	def createCompareExpression(Expression lhs, Expression rhs, CompareOperator operator) {
		return createCompareExpression => [
			it.firstExpr = lhs
			it.operator = operator
			it.secondExpr = rhs
		]
	}
	
	def Expression wrapIntoMultiaryExpression(List<? extends Expression> expressions,
			LogicalOperator operator) {
		if (expressions.empty) {
			return null
		}
		val size = expressions.size
		if (size == 1) {
			return expressions.iterator.next
		}
		val logicalExpression = createLogicalExpression => [
			it.firstExpr = expressions.get(0)
			it.operator = operator
		]
		if (size == 2) {
			return logicalExpression => [
				it.secondExpr = expressions.get(1)
			]
		}
		val remaining = expressions.subList(1, expressions.size)
				.wrapIntoMultiaryExpression(operator)
		return logicalExpression => [
			it.secondExpr = remaining
		]
	}
	
	def wrapIntoOrExpression(List<? extends Expression> expressions) {
		return wrapIntoMultiaryExpression(expressions, LogicalOperator.OR);
	}
	
	/**
	 * This method creates the variables of the given containers based on the given predefined type and name.
	 */
	def createTypeAndVariable(VariableContainer container, PredefinedType type, String name) {		
		val typeReference = type.createTypeReference
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
	
	def Location createLocation(Template template, LocationKind kind, String name) {
		return template.createLocation => [
			it.locationTimeKind = kind
			it.name = name
		]
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
				it.firstExpr = guard.createIdentifierExpression
				it.operator = operator
				it.secondExpr = oldGuard
			]
		}
		// If there is no guard yet
		else {
			edge.guard = guard.createIdentifierExpression
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
					it.firstExpr = guard.createIdentifierExpression
					it.operator = CompareOperator.UNEQUAL
					it.secondExpr = notEqual.clone
				]
				it.operator = operator
				it.secondExpr = oldGuard
			]
		}
		// If there is no guard yet
		else {
			edge.guard = guard.createIdentifierExpression
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
	
	def addGuard(Edge edge, Expression guard) {
		return edge.addGuard(guard, LogicalOperator.AND)
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
	
	def Edge createEdgeCommittedSource(Location source, String name) {
		val template = source.parentTemplate
		val target = template.createLocation => [
			it.name = name
			it.locationTimeKind = LocationKind.COMMITED
		]
		template.location += target
		val edge = source.createEdge(target)
		return edge		
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
	
	def createUpdateEdge(Location source, String nextCommittedLocationName,
			VariableContainer uppaalVariable, Expression uppaalRhs) {
		return source.createUpdateEdge(nextCommittedLocationName,
			uppaalVariable.createIdentifierExpression, uppaalRhs)
	}
	
	def createUpdateEdge(Location source, String nextCommittedLocationName,
			Expression uppaalLhs, Expression uppaalRhs) {
		val edge = source.createEdgeCommittedSource(nextCommittedLocationName)
		if (uppaalRhs !== null) {
			edge.update += uppaalLhs.createAssignmentExpression(uppaalRhs)
		}
		return edge.target
	}
	
	/**
	 * Responsible for placing a synchronization onto the given edge: "channel?/channel!".
	 */
	def void setSynchronization(Edge edge, Variable syncVar, SynchronizationKind syncType) {
		edge.synchronization = createSynchronization => [
			it.kind = syncType
			it.channelExpression = syncVar.createIdentifierExpression
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
	
	def void instantiateTemplates() {
		val system = nta.systemDeclarations.system
		val instantiationLists = system.instantiationList 
		val instantiationList = createInstantiationList
		instantiationLists += instantiationList
		for (template : nta.template) {
			instantiationList.template += template
		}
	}
	
	def createIndex(Expression expression) {
		return createValueIndex => [
			it.sizeExpression = expression
		]
	}
	
	def createBlock(Iterable<? extends Statement> statements) {
		return createBlock => [
			it.statement += statements
		]
	}
	
	def createBlock(Statement statement) {
		if (statement instanceof Block) {
			return statement
		}
		return #[statement].filterNull
			.createBlock
	}
	
	def createStatements(Iterable<? extends Expression> expressions) {
		val statements = newArrayList
		for (expression : expressions) {
			statements += expression.createStatement
		}
		return statements
	}
	
	def createStatement(Expression expression) {
		return createExpressionStatement => [
			it.expression = expression
		]
	}
	
	def createIfStatement(Expression condition, Statement then, Statement ^else) {
		return createIfStatement => [
			it.ifExpression = condition
			it.thenStatement = then
			it.elseStatement = ^else
		]
	}
	
	def createForStatement(VariableContainer parameter, Statement body) {
		return createIteration => [
			it.variable += parameter.variable
			it.typeDefinition = parameter.typeDefinition
			it.statement = body
		]
	}
	
	def createVoidFunction(String name, Block block) {
		return nta.void.createTypeReference
				.createFunction(name, block)
	}
	
	def createFunction(TypeDefinition type, String name, Block block) {
		return createFunction => [
			it.returnType = type
			it.name = name
			it.block = block
		]
	}
	
	def createFunctionDeclaration(Function function) {
		return createFunctionDeclaration => [
			it.function = function
		]
	}
	
	def createFunctionCallExpression(Function function) {
		return createFunctionCallExpression => [
			it.function = function
		]
	}
	
	def createLocalDeclarations(Iterable<? extends Declaration> declarations) {
		return createLocalDeclarations => [
			it.declaration += declarations
		]
	}
	
	def createEmptyStatement() {
		return stmtsFactory.createEmptyStatement
	}
	
	def getNta() {
		return nta
	}
	
}