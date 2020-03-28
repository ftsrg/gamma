package hu.bme.mit.gamma.uppaal.composition.transformation

import java.util.Collection
import java.util.List
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.viatra.transformation.runtime.emf.modelmanipulation.IModelManipulations
import uppaal.NTA
import uppaal.UppaalPackage
import uppaal.declarations.ChannelVariableDeclaration
import uppaal.declarations.DataVariableDeclaration
import uppaal.declarations.DataVariablePrefix
import uppaal.declarations.Declarations
import uppaal.declarations.DeclarationsPackage
import uppaal.declarations.ExpressionInitializer
import uppaal.declarations.Function
import uppaal.declarations.FunctionDeclaration
import uppaal.declarations.Variable
import uppaal.declarations.VariableContainer
import uppaal.expressions.ArithmeticOperator
import uppaal.expressions.AssignmentExpression
import uppaal.expressions.Expression
import uppaal.expressions.ExpressionsFactory
import uppaal.expressions.ExpressionsPackage
import uppaal.expressions.FunctionCallExpression
import uppaal.expressions.IdentifierExpression
import uppaal.expressions.LiteralExpression
import uppaal.expressions.LogicalExpression
import uppaal.expressions.LogicalOperator
import uppaal.statements.ExpressionStatement
import uppaal.templates.Edge
import uppaal.templates.Location
import uppaal.templates.LocationKind
import uppaal.templates.Synchronization
import uppaal.templates.SynchronizationKind
import uppaal.templates.Template
import uppaal.templates.TemplatesPackage
import uppaal.types.PredefinedType
import uppaal.types.TypeReference
import uppaal.types.TypesPackage

import static com.google.common.base.Preconditions.checkArgument
import static com.google.common.base.Preconditions.checkState

class NtaBuilder {
	// NTA target model
	final NTA nta
	// Model manipulator
	protected final extension IModelManipulations manipulation
	// Is minimal element set (function inlining)
	final boolean isMinimalElementSet
	// UPPAAL packages
	protected final extension UppaalPackage upPackage = UppaalPackage.eINSTANCE
	protected final extension DeclarationsPackage declPackage = DeclarationsPackage.eINSTANCE
	protected final extension TypesPackage typPackage = TypesPackage.eINSTANCE
	protected final extension TemplatesPackage temPackage = TemplatesPackage.eINSTANCE
	protected final extension ExpressionsPackage expPackage = ExpressionsPackage.eINSTANCE
	// UPPAAL factories
	protected final extension ExpressionsFactory expFact = ExpressionsFactory.eINSTANCE
	// Auxiliary objects
	protected final extension Cloner cloner = new Cloner
	
	new(NTA nta, IModelManipulations manipulation, boolean isMinimalElementSet) {
		this.nta = nta
		this.manipulation = manipulation
		this.isMinimalElementSet = isMinimalElementSet
	}
	
	/**
	 * Creates a template with the given name and an initial location called InitLoc.
	 */
	def createTemplateWithInitLoc(String templateName, String locationName) {
		val template = nta.createChild(getNTA_Template, template) as Template => [
			it.name = templateName
			it.createChild(template_Declarations, localDeclarations)
		]
		val initLoc = template.createChild(template_Location, location) as Location => [
			it.name = locationName
		]
		template.init = initLoc
		return initLoc
	}
	
	def addFunctionCall(EObject container, EReference reference, Function function) {
		if (isMinimalElementSet && function.isInlinable) {
			// Deleting the function from the model tree
			val functionContainer = function.eContainer as FunctionDeclaration
			functionContainer.remove
			val block = function.block
			for (statement : block.statement) {
				if (statement instanceof ExpressionStatement) {
					val expression = statement.expression
					val referenceObject = container.eGet(reference, true)
					if (referenceObject instanceof List) {
						referenceObject += expression.clone(true, true)
					}
					else {
						// Then only one element is expected
						checkState(block.statement.size == 1)
						container.eSet(reference, expression)
					}
				}
			}
		}
		else {
			container.createChild(reference, functionCallExpression) as FunctionCallExpression => [
				it.function = function
			]
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
	
	/**
	 * This method is responsible for creating the variables in the resource depending on the received parameters.
	 * It also creates the traces.
	 */
	def createSynchronization(Declarations decl, boolean isBroadcast, boolean isUrgent, String name) {
		val syncContainer = decl.createChild(declarations_Declaration, channelVariableDeclaration) as ChannelVariableDeclaration => [
			it.broadcast = isBroadcast
			it.urgent = isUrgent
		]
		syncContainer.createTypeAndVariable(nta.chan, name)
		return syncContainer
	}
	
	/**
	 * This method is responsible for creating the variables in the resource depending on the received parameters.
	 * It also creates the traces.
	 */
	def createVariable(Declarations decl, DataVariablePrefix prefix, PredefinedType type, String name) {
		val varContainer = decl.createChild(declarations_Declaration, dataVariableDeclaration) as DataVariableDeclaration => [
			it.prefix = prefix
		]
		varContainer.createTypeAndVariable(type, name)		
		return varContainer
	}
	
		
	/**
	 * Initializes a variable with the given string value.
	 */
	def initVar(DataVariableDeclaration variable, String value) {		
		variable.variable.head.createChild(variable_Initializer, expressionInitializer) as ExpressionInitializer => [
			it.createChild(expressionInitializer_Expression, literalExpression) as LiteralExpression => [
				it.text = value
			]
		]
	}
	
	/**
	 * This method creates the variables of the given containers based on the given predefined type and name.
	 */
	def createTypeAndVariable(VariableContainer container, PredefinedType type, String name) {		
		container.createChild(variableContainer_TypeDefinition, typeReference) as TypeReference => [
			it.referredType = type
		]
		// Creating variables for all statechart instances
		container.createChild(variableContainer_Variable, declPackage.variable) as Variable => [
			it.container = container
			it.name = name
		]
	}
	
	def Location createLocation(Template template) {
		return template.createChild(template_Location, location) as Location
	}
	
	/**
	 * Responsible for creating an edge in the given template with the given source and target.
	 */
	def Edge createEdge(Location source, Location target) {
		if (source.parentTemplate != target.parentTemplate) {
			throw new IllegalArgumentException("The source and the target are in different templates." + source + " " + target)
		}
		val template = source.parentTemplate
		template.createChild(template_Edge, edge) as Edge => [
			it.source = source
			it.target = target
		]
	}
	
	/**
	 * Appends a variable declaration as a guard to the guard of the given edge. The operator between the old and the new guard can be given too.
	 */
	def addGuard(Edge edge, DataVariableDeclaration guard, LogicalOperator operator) {
		if (edge.guard !== null) {
			// Getting the old reference
			val oldGuard = edge.guard as Expression
			// Creating the new andExpression that will contain the same reference and the regular guard expression
			edge.createChild(edge_Guard, logicalExpression) as LogicalExpression => [
				it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
					it.identifier = guard.variable.head
				]
				it.operator = operator
				it.secondExpr = oldGuard
			]
		}
		// If there is no guard yet
		else {
			edge.createChild(edge_Guard, identifierExpression) as IdentifierExpression => [
				it.identifier = guard.variable.head
			]
		}
	}
	
	/**
	 * Appends an Uppaal guard to the guard of the given edge. The operator between the old and the new guard can be given too.
	 */
	def addGuard(Edge edge, Expression guard, LogicalOperator operator) {
		if (edge.guard !== null && guard !== null) {
			// Getting the old reference
			val oldGuard = edge.guard as Expression
			// Creating the new andExpression that will contain the same reference and the regular guard expression
			edge.createChild(edge_Guard, logicalExpression) as LogicalExpression => [
				it.firstExpr = guard
				it.operator = operator
				it.secondExpr = oldGuard
			]
		}
		// If there is no guard yet
		else {
			edge.guard = guard
		}
	}
	
	def Edge createEdgeCommittedTarget(Location target, String name) {
		val template = target.parentTemplate
		val syncLocation = template.createChild(template_Location, location) as Location => [
			it.name = name
			it.locationTimeKind = LocationKind.COMMITED
			it.comment = "Synchronization location."
		]
		val syncEdge = syncLocation.createEdge(target)
		return syncEdge		
	}
	
	/**
	 * Responsible for creating a ! synchronization on an edge and a committed location as the source of the edge.
	 * The target of the synchronized edge will be the given "target" location.
	 */
	def Edge createCommittedSyncTarget(Location target, Variable syncVar, String name) {
		val syncEdge = target.createEdgeCommittedTarget(name) => [
			it.comment = "Synchronization edge."
			it.setSynchronization(syncVar, SynchronizationKind.SEND)
		]
		return syncEdge		
	}
	
	/**
	 * Responsible for placing a synchronization onto the given edge: "channel?/channel!".
	 */
	def setSynchronization(Edge edge, Variable syncVar, SynchronizationKind syncType) {
		edge.createChild(edge_Synchronization, temPackage.synchronization) as Synchronization => [
			it.kind = syncType
			it.createChild(synchronization_ChannelExpression, identifierExpression) as IdentifierExpression => [
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
	
	def createLogicalExpression(LogicalOperator operator,
			Collection<? extends Expression> expressions) {
		checkArgument(!expressions.empty)
		if (expressions.size == 1) {
			return expressions.head
		}
		var logicalExpression = createLogicalExpression => [
			it.operator = operator
		]
		var i = 0
		for (expression : expressions) {
			if (i == 0) {
				logicalExpression.firstExpr = expression
			}
			else if (i == 1) {
				logicalExpression.secondExpr = expression
			}
			else {
				val oldExpression = logicalExpression
				logicalExpression = createLogicalExpression => [
					it.operator = operator
					it.firstExpr = oldExpression
					it.secondExpr = expression
				]
			}
			i++
		}
		return logicalExpression
	}
	
	def createArithmeticExpression(ArithmeticOperator operator,
			Collection<? extends Expression> expressions) {
		checkArgument(!expressions.empty)
		if (expressions.size == 1) {
			return expressions.head
		}
		var logicalExpression = createArithmeticExpression => [
			it.operator = operator
		]
		var i = 0
		for (expression : expressions) {
			if (i == 0) {
				logicalExpression.firstExpr = expression
			}
			else if (i == 1) {
				logicalExpression.secondExpr = expression
			}
			else {
				val oldExpression = logicalExpression
				logicalExpression = createArithmeticExpression => [
					it.operator = operator
					it.firstExpr = oldExpression
					it.secondExpr = expression
				]
			}
			i++
		}
		return logicalExpression
	}
	
	def getNta() {
		return nta
	}
	
}