/********************************************************************************
 * Copyright (c) 2018 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.action.model.AssignmentStatement
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.FalseExpression
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.expression.model.TrueExpression
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.statechart.model.AnyPortEventReference
import hu.bme.mit.gamma.statechart.model.AnyTrigger
import hu.bme.mit.gamma.statechart.model.BinaryTrigger
import hu.bme.mit.gamma.statechart.model.Clock
import hu.bme.mit.gamma.statechart.model.CompositeElement
import hu.bme.mit.gamma.statechart.model.EntryState
import hu.bme.mit.gamma.statechart.model.EventTrigger
import hu.bme.mit.gamma.statechart.model.Package
import hu.bme.mit.gamma.statechart.model.Port
import hu.bme.mit.gamma.statechart.model.PortEventReference
import hu.bme.mit.gamma.statechart.model.PseudoState
import hu.bme.mit.gamma.statechart.model.RaiseEventAction
import hu.bme.mit.gamma.statechart.model.Region
import hu.bme.mit.gamma.statechart.model.SchedulingOrder
import hu.bme.mit.gamma.statechart.model.State
import hu.bme.mit.gamma.statechart.model.StateNode
import hu.bme.mit.gamma.statechart.model.StatechartDefinition
import hu.bme.mit.gamma.statechart.model.TimeSpecification
import hu.bme.mit.gamma.statechart.model.TimeUnit
import hu.bme.mit.gamma.statechart.model.TimeoutEventReference
import hu.bme.mit.gamma.statechart.model.Transition
import hu.bme.mit.gamma.statechart.model.TransitionPriority
import hu.bme.mit.gamma.statechart.model.UnaryTrigger
import hu.bme.mit.gamma.statechart.model.composite.AbstractSynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousComponent
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousComponentInstance
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.CascadeCompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.Component
import hu.bme.mit.gamma.statechart.model.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.model.composite.MessageQueue
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponent
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.model.composite.SynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.model.interface_.Event
import hu.bme.mit.gamma.statechart.model.interface_.EventDirection
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.DistinctWrapperInEvents
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.EdgesWithClock
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.EventsIntoMessageQueues
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.InputInstanceEvents
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.InstanceMessageQueues
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.InstanceRegions
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.InstanceVariables
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.ParameteredEvents
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.ParameterizedInstances
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.QueuePriorities
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.QueueSwapInstancesOfComposite
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.QueuesOfClocks
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.QueuesOfEvents
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.RaiseInstanceEventOfTransitions
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.RaiseInstanceEventStateEntryActions
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.RaiseInstanceEventStateExitActions
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.RaiseTopSystemEventOfTransitions
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.RaiseTopSystemEventStateEntryActions
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.RaiseTopSystemEventStateExitActions
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.RunOnceClockControl
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.RunOnceEventControl
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.SimpleInstances
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.SimpleWrapperInstances
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.TimeoutValues
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.ToHigherInstanceTransitions
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.ToLowerInstanceTransitions
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.TopAsyncCompositeComponents
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.TopAsyncSystemInEvents
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.TopMessageQueues
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.TopSyncSystemInEvents
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.TopSyncSystemOutEvents
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.TopUnwrappedSyncComponents
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.TopWrapperComponents
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.UnusedWrapperEvents
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.WrapperInEvents
import hu.bme.mit.gamma.uppaal.transformation.queries.AllSubregionsOfCompositeStates
import hu.bme.mit.gamma.uppaal.transformation.queries.ChoicesAndMerges
import hu.bme.mit.gamma.uppaal.transformation.queries.CompositeStates
import hu.bme.mit.gamma.uppaal.transformation.queries.ConstantDeclarations
import hu.bme.mit.gamma.uppaal.transformation.queries.DeclarationInitializations
import hu.bme.mit.gamma.uppaal.transformation.queries.DefaultTransitionsOfChoices
import hu.bme.mit.gamma.uppaal.transformation.queries.EliminatableChoices
import hu.bme.mit.gamma.uppaal.transformation.queries.Entries
import hu.bme.mit.gamma.uppaal.transformation.queries.EntryAssignmentsOfStates
import hu.bme.mit.gamma.uppaal.transformation.queries.EntryRaisingActionsOfStates
import hu.bme.mit.gamma.uppaal.transformation.queries.EntryTimeoutActionsOfStates
import hu.bme.mit.gamma.uppaal.transformation.queries.EventTriggersOfTransitions
import hu.bme.mit.gamma.uppaal.transformation.queries.ExitAssignmentsOfStatesWithTransitions
import hu.bme.mit.gamma.uppaal.transformation.queries.ExitRaisingActionsOfStatesWithTransitions
import hu.bme.mit.gamma.uppaal.transformation.queries.GuardsOfTransitions
import hu.bme.mit.gamma.uppaal.transformation.queries.InstanceTraces
import hu.bme.mit.gamma.uppaal.transformation.queries.OutgoingTransitionsOfCompositeStates
import hu.bme.mit.gamma.uppaal.transformation.queries.RaisingActionsOfTransitions
import hu.bme.mit.gamma.uppaal.transformation.queries.SameRegionTransitions
import hu.bme.mit.gamma.uppaal.transformation.queries.SimpleStates
import hu.bme.mit.gamma.uppaal.transformation.queries.States
import hu.bme.mit.gamma.uppaal.transformation.queries.TimeTriggersOfTransitions
import hu.bme.mit.gamma.uppaal.transformation.queries.ToHigherTransitions
import hu.bme.mit.gamma.uppaal.transformation.queries.Traces
import hu.bme.mit.gamma.uppaal.transformation.queries.Transitions
import hu.bme.mit.gamma.uppaal.transformation.queries.UpdatesOfTransitions
import hu.bme.mit.gamma.uppaal.transformation.queries.ValuesOfEventParameters
import hu.bme.mit.gamma.uppaal.transformation.traceability.ClockRepresentation
import hu.bme.mit.gamma.uppaal.transformation.traceability.EventRepresentation
import hu.bme.mit.gamma.uppaal.transformation.traceability.G2UTrace
import hu.bme.mit.gamma.uppaal.transformation.traceability.MessageQueueTrace
import hu.bme.mit.gamma.uppaal.transformation.traceability.TraceabilityFactory
import hu.bme.mit.gamma.uppaal.transformation.traceability.TraceabilityPackage
import java.math.BigInteger
import java.util.AbstractMap.SimpleEntry
import java.util.ArrayList
import java.util.Collection
import java.util.Collections
import java.util.HashMap
import java.util.HashSet
import java.util.List
import java.util.Map
import java.util.NoSuchElementException
import java.util.Optional
import java.util.Set
import java.util.logging.Level
import java.util.logging.Logger
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.emf.EMFScope
import org.eclipse.viatra.transformation.runtime.emf.modelmanipulation.IModelManipulations
import org.eclipse.viatra.transformation.runtime.emf.modelmanipulation.SimpleModelManipulations
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRuleFactory
import org.eclipse.viatra.transformation.runtime.emf.transformation.batch.BatchTransformation
import org.eclipse.viatra.transformation.runtime.emf.transformation.batch.BatchTransformationStatements
import uppaal.NTA
import uppaal.UppaalFactory
import uppaal.UppaalPackage
import uppaal.declarations.ChannelVariableDeclaration
import uppaal.declarations.ClockVariableDeclaration
import uppaal.declarations.DataVariableDeclaration
import uppaal.declarations.DataVariablePrefix
import uppaal.declarations.DeclarationsFactory
import uppaal.declarations.DeclarationsPackage
import uppaal.declarations.ExpressionInitializer
import uppaal.declarations.Function
import uppaal.declarations.FunctionDeclaration
import uppaal.declarations.LocalDeclarations
import uppaal.declarations.Parameter
import uppaal.declarations.SystemDeclarations
import uppaal.declarations.TypeDeclaration
import uppaal.declarations.ValueIndex
import uppaal.declarations.Variable
import uppaal.declarations.VariableContainer
import uppaal.declarations.VariableDeclaration
import uppaal.declarations.system.InstantiationList
import uppaal.declarations.system.SystemPackage
import uppaal.expressions.ArithmeticExpression
import uppaal.expressions.ArithmeticOperator
import uppaal.expressions.AssignmentExpression
import uppaal.expressions.AssignmentOperator
import uppaal.expressions.CompareExpression
import uppaal.expressions.CompareOperator
import uppaal.expressions.Expression
import uppaal.expressions.ExpressionsFactory
import uppaal.expressions.ExpressionsPackage
import uppaal.expressions.FunctionCallExpression
import uppaal.expressions.IdentifierExpression
import uppaal.expressions.IncrementDecrementExpression
import uppaal.expressions.IncrementDecrementOperator
import uppaal.expressions.LiteralExpression
import uppaal.expressions.LogicalExpression
import uppaal.expressions.LogicalOperator
import uppaal.expressions.NegationExpression
import uppaal.expressions.ScopedIdentifierExpression
import uppaal.statements.Block
import uppaal.statements.ExpressionStatement
import uppaal.statements.ForLoop
import uppaal.statements.IfStatement
import uppaal.statements.ReturnStatement
import uppaal.statements.StatementsPackage
import uppaal.templates.Edge
import uppaal.templates.Location
import uppaal.templates.LocationKind
import uppaal.templates.SynchronizationKind
import uppaal.templates.Template
import uppaal.templates.TemplatesPackage
import uppaal.types.BuiltInType
import uppaal.types.DeclaredType
import uppaal.types.IntegerBounds
import uppaal.types.PredefinedType
import uppaal.types.RangeTypeSpecification
import uppaal.types.StructTypeSpecification
import uppaal.types.TypeReference
import uppaal.types.TypesFactory
import uppaal.types.TypesPackage

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.uppaal.composition.transformation.Namings.*

class CompositeToUppaalTransformer {
	// Transformation-related extensions
	protected extension BatchTransformation transformation
	protected extension BatchTransformationStatements statements
	// Transformation rule-related extensions
	protected extension BatchTransformationRuleFactory = new BatchTransformationRuleFactory
	protected extension IModelManipulations manipulation
	// Logger
	protected extension Logger logger = Logger.getLogger("GammaLogger")
	// Arguments for the top level component
	protected List<hu.bme.mit.gamma.expression.model.Expression> topComponentArguments = new ArrayList<hu.bme.mit.gamma.expression.model.Expression>
	// Engine on the Gamma resource 
	protected ViatraQueryEngine engine
	protected final ResourceSet resources
	// The Gamma composite system to be transformed
	protected final Component component
	// The Gamma statechart that contains all ComponentDeclarations with the required instances
	protected final Package sourceRoot
	// Root element containing the traces
	protected final G2UTrace traceRoot
	// The root element of the Uppaal automaton
	protected NTA target
	// Message struct types
	protected DeclaredType messageStructType
	protected StructTypeSpecification messageStructTypeDef
	protected DataVariableDeclaration messageEvent
	protected DataVariableDeclaration messageValue
	// Gamma factory for the millisecond multiplication
	protected final ExpressionModelFactory constrFactory = ExpressionModelFactory.eINSTANCE
	// UPPAAL packages
	protected final extension TraceabilityPackage trPackage = TraceabilityPackage.eINSTANCE
	protected final extension UppaalPackage upPackage = UppaalPackage.eINSTANCE
	protected final extension DeclarationsPackage declPackage = DeclarationsPackage.eINSTANCE
	protected final extension TypesPackage typPackage = TypesPackage.eINSTANCE
	protected final extension TemplatesPackage temPackage = TemplatesPackage.eINSTANCE
	protected final extension ExpressionsPackage expPackage = ExpressionsPackage.eINSTANCE
	protected final extension StatementsPackage stmPackage = StatementsPackage.eINSTANCE
	protected final extension SystemPackage sysPackage = SystemPackage.eINSTANCE
	// UPPAAL factories
	protected final extension DeclarationsFactory declFact = DeclarationsFactory.eINSTANCE
	protected final extension ExpressionsFactory expFact = ExpressionsFactory.eINSTANCE
	protected final extension TypesFactory typesFact = TypesFactory.eINSTANCE
	// isStable variable
	protected DataVariableDeclaration isStableVar
	// Async scheduler
	protected Scheduler asyncScheduler = Scheduler.RANDOM
	// Orchestrating period for top sync components
	protected TimeSpecification minimalOrchestratingPeriod
	protected TimeSpecification maximalOrchestratingPeriod
	// Minimal element set: no functions
	protected boolean isMinimalElementSet = false
	// For the generation of pseudo locations
	protected int id = 0
	// For the async event queue constants
	protected int constantVal = 1 // Starting from 1, as 0 means empty
	// Transition ids
	protected final Set<SynchronousComponentInstance> testedComponentsForStates = newHashSet
	protected final Set<SynchronousComponentInstance> testedComponentsForTransitions = newHashSet
	protected DataVariableDeclaration transitionIdVar
	protected int transitionId = 0
	// Auxiliary transformer objects
	protected extension NtaBuilder ntaBuilder
	protected final extension SynchronousChannelCreatorOfAsynchronousInstances synchronousChannelCreatorOfAsynchronousInstances
	// Auxiliary objects
	protected extension ExpressionTransformer expTransf
	protected extension ExpressionCopier expCop
	protected extension ExpressionEvaluator expEval
	protected final extension SimpleInstanceHandler simpInstHandl = new SimpleInstanceHandler
	protected final extension EventHandler eventHandler = new EventHandler
	// Trace
	protected extension Trace traceModel

	new(ResourceSet resourceSet, Component component, Scheduler asyncScheduler,
			List<SynchronousComponentInstance> testedComponentsForStates,
			List<SynchronousComponentInstance> testedComponentsForTransitions) { 
		this.resources = resourceSet // sourceRoot.eResource.resourceSet does not work
		this.sourceRoot = component.eContainer as Package
		this.component = component
		this.asyncScheduler = asyncScheduler
		this.testedComponentsForStates += testedComponentsForStates // Only simple instances
		this.testedComponentsForTransitions += testedComponentsForTransitions // Only simple instances
		this.target = UppaalFactory.eINSTANCE.createNTA
		// Connecting the two models in trace
		this.traceRoot = TraceabilityFactory.eINSTANCE.createG2UTrace => [
			it.gammaPackage = this.sourceRoot
			it.nta = this.target
		]
		// Create VIATRA engine based on the Gamma resource
		this.engine = ViatraQueryEngine.on(new EMFScope(this.resources));	  
		// Create VIATRA auxiliary objects
		this.manipulation = new SimpleModelManipulations(engine)
		this.transformation = BatchTransformation.forEngine(engine).build
		this.statements = transformation.transformationStatements
		// Trace
		this.traceModel = new Trace(this.manipulation, this.traceRoot)
		// Auxiliary objects
		this.expTransf = new ExpressionTransformer(this.manipulation, this.traceModel)
		this.expCop = new ExpressionCopier(this.manipulation, this.traceModel) 
		this.expEval = new ExpressionEvaluator(this.engine)
		// Auxiliary transformation objects
		this.ntaBuilder = new NtaBuilder(this.target, this.manipulation)
		this.synchronousChannelCreatorOfAsynchronousInstances = new SynchronousChannelCreatorOfAsynchronousInstances(this.ntaBuilder, this.traceModel) 
	}
	
	new(ResourceSet resourceSet, Component component,
			List<hu.bme.mit.gamma.expression.model.Expression> topComponentArguments,
			Scheduler asyncScheduler,
			TimeSpecification minimalOrchestratingPeriod,
			TimeSpecification maximalOrchestratingPeriod,
			boolean isMinimalElementSet,
			List<SynchronousComponentInstance> testedComponentsForStates,
			List<SynchronousComponentInstance> testedComponentsForTransitions) { 
		this(resourceSet, component, asyncScheduler, testedComponentsForStates, testedComponentsForTransitions)
		this.minimalOrchestratingPeriod = minimalOrchestratingPeriod
		this.maximalOrchestratingPeriod = maximalOrchestratingPeriod
		this.isMinimalElementSet = isMinimalElementSet
		this.topComponentArguments.addAll(topComponentArguments)
	}
	
	def execute() {
		initNta
		createMessageStructType
		createFinalizeSyncVar
		createIsStableVar
		if (!testedComponentsForTransitions.empty) {
			createTransitionIdVar
		}
		transformTopComponentArguments
		while (!areAllParametersTransformed) {
			parametersRule.fireAllCurrent[!it.instance.areAllArgumentsTransformed]
		}
		constantsRule.fireAllCurrent
		variablesRule.fireAllCurrent
		declarationInitRule.fireAllCurrent
		inputEventsRule.fireAllCurrent
		syncSystemOutputEventsRule.fireAllCurrent
		eventParametersRule.fireAllCurrent
		regionsRule.fireAllCurrent
		entriesRule.fireAllCurrent
		statesRule.fireAllCurrent
		choicesRule.fireAllCurrent
		sameRegionTransitionsRule.fireAllCurrent
		toLowerRegionTransitionsRule.fireAllCurrent
		toHigherRegionTransitionsRule.fireAllCurrent		
	 	{eventTriggersRule.fireAllCurrent
		timeTriggersRule.fireAllCurrent} // Should come right after eventTriggersRule		
		{guardsRule.fireAllCurrent
		defultChoiceTransitionsRule.fireAllCurrent
		transitionPriorityRule.fireAllCurrent
		transitionTimedTransitionPriorityRule.fireAllCurrent}
		// Executed here, so locations created by timeTriggersRule have initialization edges (templates do not stick in timer locations)
		// Must be executed after swapGuardsOfTimeTriggerTransitions, otherwise an exception is thrown
		compositeStateEntryRule.fireAllCurrent 
		entryAssignmentActionsOfStatesRule.fireAllCurrent
		exitAssignmentActionsOfStatesRule.fireAllCurrent
		exitEventRaisingActionsOfStatesRule.fireAllCurrent
		exitSystemEventRaisingActionsOfStatesRule.fireAllCurrent
		assignmentActionsRule.fireAllCurrent[
			!ToHigherTransitions.Matcher.on(engine).allValuesOftransition.contains(it.transition)
		]	
		// Across region entry events are set here so they are situated after the exit events and regular transition assignments
		toLowerRegionEntryEventTransitionsRule.fireAllCurrent
		eventRaisingActionsRule.fireAllCurrent[
			!ToHigherTransitions.Matcher.on(engine).allValuesOftransition.contains(it.transition)
		]
		syncSystemEventRaisingActionsRule.fireAllCurrent
		entryEventRaisingActionsRule.fireAllCurrent
		syncSystemEventRaisingOfEntryActionsRule.fireAllCurrent
		compositeStateExitRule
		entryTimeoutActionsOfStatesRule.fireAllCurrent
		isActiveRule.fireAllCurrent
		// Creating urgent locations in front of composite states, so entry is not immediate
		compositeStateEntryCompletion
		// Extend timed locations with outgoing edges from the original location
		extendTimedLocations
		// Creating a same level process list, note that it is before the orchestrator template: UPPAAL does not work correctly with priorities
//		instantiateUninstantiatedTemplates
		// New entries to traces, previous adding would cause trouble
		extendTrace
		// Firing the rules for async components 
		eventConstantsRule.fireAllCurrent[component instanceof AsynchronousComponent /*Needed only for async models*/]
		clockConstantsRule.fireAllCurrent[component instanceof AsynchronousComponent /*Needed only for async models*/]
		{getTopWrapperSyncChannelRule.fireAllCurrent
		getInstanceWrapperSyncChannelRule.fireAllCurrent}
		// Creating the sync schedulers: here the scheduler template and the priorities are set
		{topSyncOrchestratorRule.fireAllCurrent
		topWrappedSyncOrchestratorRule.fireAllCurrent
		instanceWrapperSyncOrchestratorRule.fireAllCurrent}
		// Sync/async rules
		{topMessageQueuesRule.fireAllCurrent
		instanceMessageQueuesRule.fireAllCurrent}
		// "Environment" rules
		{syncEnvironmentRule.fireAllCurrent // sync environment
		topWrapperEnvironmentRule.fireAllCurrent
		instanceWrapperEnvironmentRule.fireAllCurrent}
		{topWrapperClocksRule.fireAllCurrent
		instanceWrapperClocksRule.fireAllCurrent}
		{topWrapperSchedulerRule.fireAllCurrent
		instanceWrapperSchedulerRule.fireAllCurrent}
		{topWrapperConnectorRule.fireAllCurrent
		instanceWrapperConnectorRule.fireAllCurrent}
		// Creating a same level process list
		instantiateUninstantiatedTemplates
		if (!isMinimalElementSet) {
			createNoInnerEventsFunction
		}
		cleanUp
		// The created EMF models are returned
		return new SimpleEntry<NTA, G2UTrace>(target, traceRoot)
	}
	
	/**
	 * This method is responsible for the initialization of the NTA.
	 * It creates the global and system declaration collections and the predefined types.
	 */
	private def initNta() {
		target.createChild(getNTA_GlobalDeclarations, globalDeclarations)
		target.createChild(getNTA_SystemDeclarations, systemDeclarations) as SystemDeclarations => [
			it.createChild(systemDeclarations_System, sysPackage.system)
		]
		target.createChild(getNTA_Int, predefinedType) as PredefinedType => [
			it.name = "integer"
			it.type = BuiltInType.INT
		]
		target.createChild(getNTA_Bool, predefinedType) as PredefinedType => [
			it.name = "boolean"
			it.type = BuiltInType.BOOL
		]
		target.createChild(getNTA_Void, predefinedType) as PredefinedType => [
			it.name = "void"
			it.type = BuiltInType.VOID
		]
		target.createChild(getNTA_Clock, predefinedType) as PredefinedType => [
			it.name = "clock"
			it.type = BuiltInType.CLOCK
		]
		target.createChild(getNTA_Chan, predefinedType) as PredefinedType => [
			it.name = "channel"
			it.type = BuiltInType.CHAN
		]
	}
	
	private def createMessageStructType() {
		if (component instanceof AsynchronousComponent) {
			val messageTypeDecl = target.globalDeclarations.createChild(declarations_Declaration, typeDeclaration) as TypeDeclaration
			messageStructType = messageTypeDecl.createChild(typeDeclaration_Type, declaredType) as DeclaredType => [
				it.name = "Message"
				it.typeDeclaration = messageTypeDecl
			]
			messageStructTypeDef =	messageTypeDecl.createChild(typeDeclaration_TypeDefinition, structTypeSpecification) as StructTypeSpecification
			messageEvent = messageStructTypeDef.createChild(structTypeSpecification_Declaration, dataVariableDeclaration) as DataVariableDeclaration
			messageEvent.createTypeAndVariable(target.int, "event")
			messageValue = messageStructTypeDef.createChild(structTypeSpecification_Declaration, dataVariableDeclaration) as DataVariableDeclaration
			messageValue.createTypeAndVariable(target.int, "value")
		}
	}
	
	/**
	 * Creates a broadcast channel that will be responsible for finalizing an instance.
	 * That is when all composite state entries are finalized.
	 */
	private def createFinalizeSyncVar() {		
		val finalizeVar = target.globalDeclarations.createSynchronization(true, false, finalizeSyncVarName)
		for (instance : SimpleInstances.Matcher.on(engine).allValuesOfinstance) {
			// Maybe strange solution,  composite state entry rules use it
			addToTrace(instance, #{finalizeVar}, trace)
		}
	}
	
	/**
	 * Creates a boolean variable that shows whether a cycle is in progress or a cycle ended.
	 */
	private def createIsStableVar() {		
		isStableVar = target.globalDeclarations.createVariable(DataVariablePrefix.NONE, target.bool, isStableVariableName)
		isStableVar.initVar(false)
	}
	
	/**
	 * Creates an integer variable that stores the id of a particular transition.
	 */
	private def createTransitionIdVar() {		
		transitionIdVar = target.globalDeclarations.createVariable(DataVariablePrefix.NONE, target.int, transitionIdVariableName)
		transitionIdVar.variable.head.createChild(variable_Initializer, expressionInitializer) as ExpressionInitializer => [
			it.createChild(expressionInitializer_Expression, literalExpression) as LiteralExpression => [
				it.text = "-1"
			]
		]
	}
	
	/**
	 * Initializes a bool variable with the given boolean value.
	 */
	private def initVar(DataVariableDeclaration variable, boolean isTrue) {		
		variable.variable.head.createChild(variable_Initializer, expressionInitializer) as ExpressionInitializer => [
			it.createChild(expressionInitializer_Expression, literalExpression) as LiteralExpression => [
				it.text = isTrue.toString
			]
		]
	}
	
	/**
	 * Creates a template with the given name and an initial location called InitLoc.
	 */
	protected def createTemplateWithInitLoc(String templateName, String locationName) {
		val template = target.createChild(getNTA_Template, template) as Template => [
			it.name = templateName
			it.createChild(template_Declarations, localDeclarations)
		]
		val initLoc = template.createChild(template_Location, location) as Location => [
			it.name = locationName
		]
		template.init = initLoc
		return initLoc
	}
	
	/**
	 * Creates a bool noInnerEvents function that shows whether there are unprocessed events in the queues of the automata.
	 */
	private def createNoInnerEventsFunction() {		
		target.globalDeclarations.createChild(declarations_Declaration, functionDeclaration) as FunctionDeclaration => [
			it.createChild(functionDeclaration_Function, declPackage.function) as Function => [
				it.createChild(function_ReturnType, typeReference) as TypeReference => [
					it.referredType = target.bool
				]
				it.name = "noInnerEvents"
				it.createChild(function_Block, stmPackage.block) as Block => [
					var tempId = 0
					// The declaration is a unique object, it has to be initialized
					it.createChild(block_Declarations, localDeclarations)
					var isFirst = true
					var DataVariableDeclaration lastTempVal
					for (match : InputInstanceEvents.Matcher.on(engine).getAllMatches(null, null, null)) {								
						if (isFirst) {
							val tempVar = it.declarations.createVariable(DataVariablePrefix.NONE, target.bool, "tempVar" + tempId++)
							it.createChild(block_Statement, expressionStatement) as ExpressionStatement => [
								it.createAssignmentExpression(expressionStatement_Expression, tempVar, match.event.getToRaiseVariable(match.port, match.instance))
							]
							lastTempVal = tempVar
							isFirst = false
						}
						//tempVarN = tempVar(N-1) || nextSignalFlag 
						else {
							val lhs = lastTempVal
							val tempVar = it.declarations.createVariable(DataVariablePrefix.NONE, target.bool,  "tempVar" + tempId++)
							it.createChild(block_Statement, expressionStatement) as ExpressionStatement => [
								it.createAssignmentLogicalExpression(expressionStatement_Expression, tempVar, lhs, match.event.getToRaiseVariable(match.port, match.instance))
							]
							lastTempVal = tempVar
						}
					}
					// Return statement
					val returnVal = lastTempVal
					it.createChild(block_Statement, stmPackage.returnStatement) as ReturnStatement => [
						if (returnVal  === null) {
							it.createChild(returnStatement_ReturnExpression, literalExpression) as LiteralExpression => [
								it.text = "true"
							]
						}
						else {
							it.createChild(returnStatement_ReturnExpression, negationExpression) as NegationExpression => [
								it.createChild(negationExpression_NegatedExpression, identifierExpression) as IdentifierExpression => [
									it.identifier = returnVal.variable.head
								]
							]
						}
					]
				]
			]
		]
	}
	
	
	/**
	 * Puts an assignment expression onto the given container. The left side is the first given variable, the right side is the second given variable in disjunction with the third variable. E.g.: myFirstVariable = mySecondVariable || myThirdVariable.
	 */
	private def void createAssignmentLogicalExpression(EObject container, EReference reference, DataVariableDeclaration lhs, DataVariableDeclaration rhsl, DataVariableDeclaration rhsr) {
   		container.createChild(reference, assignmentExpression) as AssignmentExpression => [
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = lhs.variable.head // Only one variable is expected
			]
			it.operator = AssignmentOperator.EQUAL
			it.createChild(binaryExpression_SecondExpr, logicalExpression) as LogicalExpression => [
				it.operator = LogicalOperator.OR
				it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
					it.identifier = rhsl.variable.head // Only one variable is expected
				]
				it.createChild(binaryExpression_SecondExpr, identifierExpression) as IdentifierExpression => [
					it.identifier = rhsr.variable.head // Only one variable is expected
				]
			]
		]
	}
	
	/**
	 * Responsible for creating the control template that enables the user to fire events.
	 */
	val syncEnvironmentRule = createRule(TopUnwrappedSyncComponents.instance).action [
		val initLoc = createTemplateWithInitLoc("Environment", "InitLoc")
		for (match : TopSyncSystemInEvents.Matcher.on(engine).getAllMatches(it.syncComposite, null, null, null, null)) {
			val toRaiseVar = match.event.getToRaiseVariable(match.port, match.instance) 
			log(Level.INFO, "Information: System in event: " + match.instance.name + "." + match.port.name + "_" + match.event.name)			
			val expressions = ValuesOfEventParameters.Matcher.on(engine).getAllValuesOfexpression(match.port, match.event)
			var Edge loopEdge
			if (!expressions.empty) {
				var boolean hasTrue = false
				var boolean hasFalse = false
				val hasValue = new HashSet<BigInteger>
				val isRaisedVar = match.event.getIsRaisedVariable(match.port, match.instance)	
				for (expression : expressions) {
					if (!hasTrue && (expression instanceof TrueExpression)) {
						hasTrue = true
		   				loopEdge = initLoc.createValueOfLoopEdge(match.port, match.event, toRaiseVar, isRaisedVar, match.instance, expression)
					}
					else if (!hasFalse && (expression instanceof FalseExpression)) {
						hasFalse = true
		   				loopEdge = initLoc.createValueOfLoopEdge(match.port, match.event, toRaiseVar, isRaisedVar, match.instance, expression)			
					}
					else if (!hasValue(hasValue, expression) && !(expression instanceof TrueExpression) && !(expression instanceof FalseExpression)) {
						loopEdge = initLoc.createValueOfLoopEdge(match.port, match.event, toRaiseVar, isRaisedVar, match.instance, expression)		
					}
					loopEdge.addGuard(isStableVar, LogicalOperator.AND) // isStable is needed on all parameter value loop edge	
				}
				// Adding a different value if the type is an integer
				if (!hasValue.empty) {
					val maxValue = hasValue.max
					val biggerThanMax = constrFactory.createIntegerLiteralExpression => [it.value = maxValue.add(BigInteger.ONE)]
					loopEdge = initLoc.createValueOfLoopEdge(match.port, match.event, toRaiseVar, isRaisedVar, match.instance, biggerThanMax)		
					biggerThanMax.removeGammaElementFromTrace
				}
			}
			else {
				loopEdge = initLoc.createLoopEdgeWithGuardedBoolAssignment(toRaiseVar)
				loopEdge.addGuard(isStableVar, LogicalOperator.AND)
			}
		}	
	].build   
	
	/**
	 * Appends a variable declaration as a guard to the guard of the given edge. The operator between the old and the new guard can be given too.
	 */
	private def addGuard(Edge edge, DataVariableDeclaration guard, LogicalOperator operator) {
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
	private def addGuard(Edge edge, Expression guard, LogicalOperator operator) {
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
	
	/**
	 * Creates a loop edge onto the given location that sets the toRaise flag of the give signal to isTrue.
	 */
	private def createLoopEdgeWithBoolAssignment(Location location, DataVariableDeclaration variable, boolean isTrue) {
		val loopEdge = location.createEdge(location)
		// variable = isTrue
		loopEdge.createAssignmentExpression(edge_Update, variable, isTrue)
		return loopEdge
	}
	
	/**
	 * Creates a loop edge onto the given location that sets the toRaise flag of the give signal to true and puts a guard on it too,
	 * so the edge is only fireable if the variable-to-be-set is false.
	 */
	private def createLoopEdgeWithGuardedBoolAssignment(Location location, DataVariableDeclaration variable) {
		val loopEdge = location.createLoopEdgeWithBoolAssignment(variable, true)
		val negationExpression = createNegationExpression as NegationExpression => [
			it.createChild(negationExpression_NegatedExpression, identifierExpression) as IdentifierExpression => [
				it.identifier = variable.variable.head
			]
		]
		// Only fireable if the bool variable is not already set
		loopEdge.addGuard(negationExpression, LogicalOperator.AND)
		return loopEdge
	}
	
	/**
	 * Creates a loop edge onto the given location that sets the toRaise flag of the give signal to true and sets the valueof variable
	 * according to the given Expression. 
	 */
	protected def createValueOfLoopEdge(Location location, Port port, Event event, DataVariableDeclaration toRaiseVar,
			DataVariableDeclaration isRaisedVar, ComponentInstance owner, hu.bme.mit.gamma.expression.model.Expression expression) {
		val loopEdge = location.createLoopEdgeWithGuardedBoolAssignment(toRaiseVar)
		val valueOfVars = event.parameterDeclarations.head.allValuesOfTo.filter(DataVariableDeclaration)
							.filter[it.owner == owner && it.port == port]
		if (valueOfVars.size != 1) {
			throw new IllegalArgumentException("Not one valueOfVar: " + valueOfVars)
		}
		val valueOfVar = valueOfVars.head
		loopEdge.createAssignmentExpression(edge_Update, valueOfVar, expression, owner)
		return loopEdge
	}
	
	/**
	 * Returns whether the given set contains an IntegerLiteralExpression identical to the given Expression.
	 */
	private def hasValue(Set<BigInteger> hasValue, hu.bme.mit.gamma.expression.model.Expression expression) {
		if (!(expression instanceof IntegerLiteralExpression)) {
			return false
		}
		val anInt = expression as IntegerLiteralExpression
		for (exp : hasValue) {
			if (exp.equals(anInt.value)) {				
				return true
			}
		}
		hasValue.add(anInt.value)
		return false
	}
	
	/**
	 * Puts an assignment expression onto the given container. The left side is the given variable, the right is side either true or false". E.g.: myVariable = true.
	 */
	protected def void createAssignmentExpression(EObject container, EReference reference, DataVariableDeclaration variable, boolean isTrue) {
		container.createChild(reference, assignmentExpression) as AssignmentExpression => [
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = variable.variable.head // Only one variable is expected
			]
			it.operator = AssignmentOperator.EQUAL
			it.createChild(binaryExpression_SecondExpr, literalExpression) as LiteralExpression => [
				it.text = isTrue.toString
			]
		]
	}
	
	/**
	 * Puts an assignment expression onto the given container. The left side is the first given variable, the right side is the second given variable". E.g.: myFirstVariable = mySecondVariable.
	 */
	protected def void createAssignmentExpression(EObject container, EReference reference, DataVariableDeclaration lhs, DataVariableDeclaration rhs) {
   		container.createChild(reference, assignmentExpression) as AssignmentExpression => [
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = lhs.variable.head // Only one variable is expected
			]
			it.operator = AssignmentOperator.EQUAL
			it.createChild(binaryExpression_SecondExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = rhs.variable.head // Only one variable is expected
			]
		]
	}
	
	val eventConstantsRule = createRule(WrapperInEvents.instance).action [
		it.event.createConstRepresentation(it.port, it.wrapper)
	].build
	
	val clockConstantsRule = createRule(QueuesOfClocks.instance).action [
		it.clock.createConstRepresentation(it.wrapper)
	].build
	
	val topMessageQueuesRule = createRule(TopMessageQueues.instance).action [
		val queue = it.queue
		// Creating the size const
		val capacityConst = queue.createCapacityConst(false, null)
		// Creating the capacity var
		val sizeVar = queue.createSizeVar(null)
		// Creating the Message array variable
		val messageArray = queue.createMessageArray(capacityConst, null)
		val messageVariableContainer = messageArray.container as DataVariableDeclaration
		// Creating peek function
		val peekFunction = queue.createPeekFunction(messageArray, null)
		// Creating shift function
		val shiftFunction = queue.createShiftFunction(messageArray, sizeVar, null)
		// Creating the push function
		val pushFunction = queue.createPushFunction(messageArray, sizeVar, capacityConst, null)
		// Creating isFull function
		val isFullFunction = queue.createIsFullFunction(sizeVar, capacityConst, null)
		// The trace cannot be done with "addToTrace", so it is done here
		queue.addQueueTrace(capacityConst, sizeVar, peekFunction, shiftFunction, pushFunction, isFullFunction, messageVariableContainer)
	].build
	
	val instanceMessageQueuesRule = createRule(InstanceMessageQueues.instance).action [
		val queue = it.queue
		// Checking whether the message needs regular size
		val hasIncomingQueueMessage = EventsIntoMessageQueues.Matcher.on(engine).hasMatch(null, null, null, it.instance, null, queue)
		// Creating the size const
		val capacityConst = queue.createCapacityConst(hasIncomingQueueMessage, it.instance)
		// Creating the capacity var
		val sizeVar = queue.createSizeVar(it.instance)
		// Creating the Message array variable
		val messageArray = queue.createMessageArray(capacityConst, it.instance)
		val messageVariableContainer = messageArray.container as DataVariableDeclaration
		// Creating peek function
		val peekFunction = queue.createPeekFunction(messageArray, it.instance)
		// Creating shift function
		val shiftFunction = queue.createShiftFunction(messageArray, sizeVar, it.instance)
		// Creating the push function
		val pushFunction = queue.createPushFunction(messageArray, sizeVar, capacityConst, it.instance)
		// Creating isFull function
		val isFullFunction = queue.createIsFullFunction(sizeVar, capacityConst, it.instance)
		// The trace cannot be done with "addToTrace", so it is done here
		queue.addQueueTrace(capacityConst, sizeVar, peekFunction, shiftFunction, pushFunction, isFullFunction, messageVariableContainer)
		addToTrace(instance, #{queue, capacityConst, sizeVar, peekFunction, shiftFunction, pushFunction, isFullFunction, messageVariableContainer}, instanceTrace)
	].build
	
	protected def createCapacityConst(MessageQueue queue, boolean hasEventsFromOtherComponents, ComponentInstance owner) {
		val sizeConst = createVariable(target.globalDeclarations, DataVariablePrefix.CONST, target.int,
			queue.name.toUpperCase + "_CAPACITY" + owner.postfix)
		if (hasEventsFromOtherComponents) {
			// Normal size
			sizeConst.variable.head.createChild(variable_Initializer, expressionInitializer) as ExpressionInitializer => [
				it.transform(expressionInitializer_Expression, queue.capacity, null)
			]
		}
		else {
			// For control queues size is 1
			sizeConst.variable.head.createChild(variable_Initializer, expressionInitializer) as ExpressionInitializer => [
				it.createChild(expressionInitializer_Expression, literalExpression) as LiteralExpression => [
		   			it.text = "1"
		   		]
			]
		}
		return sizeConst
	}
	
	protected def createSizeVar(MessageQueue queue, ComponentInstance owner) {
		val capacityVar = createVariable(target.globalDeclarations, DataVariablePrefix.NONE, target.int,
			queue.name + "Size" + owner.postfix)
		capacityVar.variable.head.createChild(variable_Initializer, expressionInitializer) as ExpressionInitializer => [
			it.createChild(expressionInitializer_Expression, literalExpression) as LiteralExpression => [
		   		it.text = "0"
		   	]
		]
		return capacityVar
	}
	
	protected def createMessageArray(MessageQueue queue, DataVariableDeclaration sizeConst, ComponentInstance owner) {
		val messageVariableContainer = target.globalDeclarations.createChild(declarations_Declaration, dataVariableDeclaration) as DataVariableDeclaration => [
			it.createChild(variableContainer_TypeDefinition, typeReference) as TypeReference => [
					it.referredType = messageStructType // Only one variable is expected
			]			
		]
		val messageArray = messageVariableContainer.createChild(variableContainer_Variable, declPackage.variable) as Variable => [
			it.container = messageVariableContainer
			it.name = queue.name + owner.postfix
			// Creating the array size
			it.createChild(variable_Index, valueIndex) as ValueIndex => [
				it.createChild(valueIndex_SizeExpression, identifierExpression) as IdentifierExpression => [
					it.identifier = sizeConst.variable.head // Only one variable is expected
				]
			]
		]
		return messageArray
	}
	
	protected def createPeekFunction(MessageQueue queue, Variable messageArray, ComponentInstance owner) {
		val peekFunction = target.globalDeclarations.createChild(declarations_Declaration, functionDeclaration) as FunctionDeclaration => [
			it.createChild(functionDeclaration_Function, declPackage.function) as Function => [
				it.createChild(function_ReturnType, typeReference) as TypeReference => [
					it.referredType = messageStructType
				]
				it.name = "peek" + queue.name + owner.postfix
				it.createChild(function_Block, stmPackage.block) as Block => [
					it.createChild(block_Statement, stmPackage.returnStatement) as ReturnStatement => [
						it.createChild(returnStatement_ReturnExpression, identifierExpression) as IdentifierExpression => [							
							it.identifier = messageArray
							it.createChild(identifierExpression_Index, literalExpression) as LiteralExpression => [
								it.text = "0"
							]
						]
					]
				]			
			]	
		]
		return peekFunction	
	}
	
	protected def createShiftFunction(MessageQueue queue, Variable messageArray, DataVariableDeclaration capacityVar, ComponentInstance owner) {
		val shiftFunction = target.globalDeclarations.createChild(declarations_Declaration, functionDeclaration) as FunctionDeclaration => [
			it.createChild(functionDeclaration_Function, declPackage.function) as Function => [
				it.createChild(function_ReturnType, typeReference) as TypeReference => [
					it.referredType = target.void
				]
				it.name = "shift" + queue.name + owner.postfix
				it.createChild(function_Block, stmPackage.block) as Block => [					
					// The declaration is a unique object, it has to be initialized
					it.createChild(block_Declarations, localDeclarations)
					// Message emptyMessage;
					val emptyMessageVar = it.declarations.createChild(declarations_Declaration, dataVariableDeclaration) as DataVariableDeclaration => [
						it.createChild(variableContainer_TypeDefinition, typeReference) as TypeReference => [
							it.referredType = messageStructType // Only one variable is expected
						]
					]
					emptyMessageVar.createChild(variableContainer_Variable, declPackage.variable) as Variable => [
						it.container = emptyMessageVar
						it.name = "emptyMessage"
					]
					// int i
					val i = it.declarations.createVariable(DataVariablePrefix.NONE, target.int, "i")
					// if (..capacity == 0)
					it.createChild(block_Statement, ifStatement) as IfStatement => [
						it.createChild(ifStatement_IfExpression, compareExpression) as CompareExpression => [
							it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
								it.identifier = capacityVar.variable.head
							]
							it.createChild(binaryExpression_SecondExpr, literalExpression) as LiteralExpression => [
								it.text = "0"
							] 	
						]
						// return;
						it.createChild(ifStatement_ThenStatement, returnStatement) as ReturnStatement
					]
					
					// for (i = 0; i < executionMessagesSize - 1; i++) {
					it.createChild(block_Statement, forLoop) as ForLoop => [
						// i = 0
						it.createChild(forLoop_Initialization, assignmentExpression) as AssignmentExpression => [							
							it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
								it.identifier = i.variable.head
							]
							it.createChild(binaryExpression_SecondExpr, literalExpression) as LiteralExpression => [
								it.text = "0"
							] 					
						]
						// i < executionMessagesSize - 1
						it.createChild(forLoop_Condition, compareExpression) as CompareExpression => [							
							it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
								it.identifier = i.variable.head
							]
							it.operator = CompareOperator.LESS
							it.createChild(binaryExpression_SecondExpr, arithmeticExpression) as ArithmeticExpression => [
								it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
									it.identifier = capacityVar.variable.head
								]
								it.operator = ArithmeticOperator.SUBTRACT
								it.createChild(binaryExpression_SecondExpr, literalExpression) as LiteralExpression => [
									it.text = "1"
								] 	
							]			
						]
						// i++ (default values are okay)
						it.createChild(forLoop_Iteration, incrementDecrementExpression) as IncrementDecrementExpression => [							
							it.createChild(incrementDecrementExpression_Expression, identifierExpression) as IdentifierExpression => [
								it.identifier = i.variable.head
							]	
						]
						// executionMessages[i] = executionMessages[i + 1];
						it.createChild(forLoop_Statement, expressionStatement) as ExpressionStatement => [							
							it.createChild(expressionStatement_Expression, assignmentExpression) as AssignmentExpression => [
								it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
									it.identifier = messageArray
									it.createChild(identifierExpression_Index, identifierExpression) as IdentifierExpression => [
										it.identifier = i.variable.head
									]
								]
								it.createChild(binaryExpression_SecondExpr, identifierExpression) as IdentifierExpression => [
									it.identifier = messageArray
									it.createChild(identifierExpression_Index, arithmeticExpression) as ArithmeticExpression => [
										it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
											it.identifier = i.variable.head
										]
										it.operator = ArithmeticOperator.ADD
										it.createChild(binaryExpression_SecondExpr, literalExpression) as LiteralExpression => [
											it.text = "1"
										] 	
									]		
								]
							]	
						]
					]
					// executionMessages[executionMessagesSize - 1] = emptyMessage;
					it.createChild(block_Statement, expressionStatement) as ExpressionStatement => [
						it.createChild(expressionStatement_Expression, assignmentExpression) as AssignmentExpression => [
							it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
								it.identifier = messageArray
								it.createChild(identifierExpression_Index, arithmeticExpression) as ArithmeticExpression => [
									it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
										it.identifier = capacityVar.variable.head
									]
									it.operator = ArithmeticOperator.SUBTRACT
									it.createChild(binaryExpression_SecondExpr, literalExpression) as LiteralExpression => [
										it.text = "1"
									] 	
								]		
							]
							it.createChild(binaryExpression_SecondExpr, identifierExpression) as IdentifierExpression => [
								it.identifier = emptyMessageVar.variable.head
							]
						]
					]
					// ...MessagesCapacity--;
					it.createChild(block_Statement, expressionStatement) as ExpressionStatement => [
						it.createChild(expressionStatement_Expression, incrementDecrementExpression) as IncrementDecrementExpression => [	
							it.operator = IncrementDecrementOperator.DECREMENT
							it.createChild(incrementDecrementExpression_Expression, identifierExpression) as IdentifierExpression => [
								it.identifier = capacityVar.variable.head
							]
						]
					]
				]		
			]	
		]
		return shiftFunction	
	}
	
	protected def createPushFunction(MessageQueue queue, Variable messageArray, DataVariableDeclaration capacityVar,
		DataVariableDeclaration sizeConst, ComponentInstance owner) {
		val pushFunction = target.globalDeclarations.createChild(declarations_Declaration, functionDeclaration) as FunctionDeclaration => [
			it.createChild(functionDeclaration_Function, declPackage.function) as Function => [
				it.createChild(function_ReturnType, typeReference) as TypeReference => [
					it.referredType = target.void
				]
				it.name = "push" + queue.name + owner.postfix
				val eventParameter = it.createChild(function_Parameter, declPackage.parameter) as Parameter
				val eventVarContainer = eventParameter.createChild(parameter_VariableDeclaration, dataVariableDeclaration) as DataVariableDeclaration
				val eventVar = eventVarContainer.createTypeAndVariable(target.int, "event")
				val valueParameter = it.createChild(function_Parameter, declPackage.parameter) as Parameter
				val valueVarContainer = valueParameter.createChild(parameter_VariableDeclaration, dataVariableDeclaration) as DataVariableDeclaration
				val valueVar = valueVarContainer.createTypeAndVariable(target.int, "value")
				it.createChild(function_Block, stmPackage.block) as Block => [					
					// The declaration is a unique object, it has to be initialized
					it.createChild(block_Declarations, localDeclarations)
					// Message emptyMessage;
					val newMessageVar = it.declarations.createChild(declarations_Declaration, dataVariableDeclaration) as DataVariableDeclaration => [
						it.createChild(variableContainer_TypeDefinition, typeReference) as TypeReference => [
							it.referredType = messageStructType // Only one variable is expected
						]
					]
					val newMessageVariable = newMessageVar.createChild(variableContainer_Variable, declPackage.variable) as Variable => [
						it.container = newMessageVar
						it.name = "message"
					]
					
					// if (...MessagesCapacity < ..._SIZE) {
					it.createChild(block_Statement, ifStatement) as IfStatement => [
						// (...MessagesCapacity < ..._SIZE)
						it.createChild(ifStatement_IfExpression, compareExpression) as CompareExpression => [
							it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
								it.identifier = capacityVar.variable.head
							]
							it.operator = CompareOperator.LESS
							it.createChild(binaryExpression_SecondExpr, identifierExpression) as IdentifierExpression => [
								it.identifier = sizeConst.variable.head
							]
						]
						it.createChild(ifStatement_ThenStatement, block) as Block => [
							// message.event = event;
							it.createChild(block_Statement, expressionStatement) as ExpressionStatement => [
								it.createChild(expressionStatement_Expression, assignmentExpression) as AssignmentExpression => [
									it.createChild(binaryExpression_FirstExpr, scopedIdentifierExpression) as ScopedIdentifierExpression => [
										it.createChild(scopedIdentifierExpression_Scope, identifierExpression) as IdentifierExpression => [
											it.identifier = newMessageVariable
										]
										it.createChild(scopedIdentifierExpression_Identifier, identifierExpression) as IdentifierExpression => [
											it.identifier = messageEvent.variable.head
										]										
									]
									it.createChild(binaryExpression_SecondExpr, identifierExpression) as IdentifierExpression => [
										it.identifier = eventVar									
									]
								]
							]
							// message.value = value;
							it.createChild(block_Statement, expressionStatement) as ExpressionStatement => [
								it.createChild(expressionStatement_Expression, assignmentExpression) as AssignmentExpression => [
									it.createChild(binaryExpression_FirstExpr, scopedIdentifierExpression) as ScopedIdentifierExpression => [
										it.createChild(scopedIdentifierExpression_Scope, identifierExpression) as IdentifierExpression => [
											it.identifier = newMessageVariable
										]
										it.createChild(scopedIdentifierExpression_Identifier, identifierExpression) as IdentifierExpression => [
											it.identifier = messageValue.variable.head
										]										
									]
									it.createChild(binaryExpression_SecondExpr, identifierExpression) as IdentifierExpression => [
										it.identifier = valueVar								
									]
								]
							]
							// ...Messages[...MessagesCapacity] = message;
							it.createChild(block_Statement, expressionStatement) as ExpressionStatement => [
								it.createChild(expressionStatement_Expression, assignmentExpression) as AssignmentExpression => [
									it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
										it.identifier = messageArray
										it.createChild(identifierExpression_Index, identifierExpression) as IdentifierExpression => [
											it.identifier = capacityVar.variable.head
										]		
									]
									it.createChild(binaryExpression_SecondExpr, identifierExpression) as IdentifierExpression => [
										it.identifier = newMessageVariable
									]
								]
							]
							// ...MessagesCapacity++;
							it.createChild(block_Statement, expressionStatement) as ExpressionStatement => [
								it.createChild(expressionStatement_Expression, incrementDecrementExpression) as IncrementDecrementExpression => [	
									it.operator = IncrementDecrementOperator.INCREMENT
									it.createChild(incrementDecrementExpression_Expression, identifierExpression) as IdentifierExpression => [
										it.identifier = capacityVar.variable.head
									]	
								]
							]
						]
					]
				]
			]
		]
		return pushFunction
	}
	
	protected def createIsFullFunction(MessageQueue queue, DataVariableDeclaration capacityVar, DataVariableDeclaration sizeConst, ComponentInstance owner) {
		val isFullFunction = target.globalDeclarations.createChild(declarations_Declaration, functionDeclaration) as FunctionDeclaration => [
			it.createChild(functionDeclaration_Function, declPackage.function) as Function => [
				it.createChild(function_ReturnType, typeReference) as TypeReference => [
					it.referredType = target.int
				]
				it.name = "is" + queue.name + "Full" + owner.postfix
				it.createChild(function_Block, stmPackage.block) as Block => [
					it.createChild(block_Statement, stmPackage.returnStatement) as ReturnStatement => [
						// ...SIZE == ...MessagesCapacity;
						it.createChild(returnStatement_ReturnExpression, compareExpression) as CompareExpression => [	
							it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [							
								it.identifier = sizeConst.variable.head				
							]
							it.operator = CompareOperator.EQUAL
							it.createChild(binaryExpression_SecondExpr, identifierExpression) as IdentifierExpression => [							
								it.identifier = capacityVar.variable.head				
							]
						]
					]
				]			
			]	
		]
		return isFullFunction
	}
	
	val topWrapperEnvironmentRule = createRule(TopWrapperComponents.instance).action [
		// Creating the template
		val initLoc = createTemplateWithInitLoc(it.wrapper.name + "Environment" + id++, "InitLoc")
		val component = wrapper.wrappedComponent.type
		for (match : TopSyncSystemInEvents.Matcher.on(engine).getAllMatches(component, null, null, null, null)) {
			val queue = wrapper.getContainerMessageQueue(match.systemPort /*Wrapper port*/, match.event) // In what message queue this event is stored
			val messageQueueTrace = queue.getTrace(null) // Getting the owner
			// Creating the loop edge (or edges in case of parametered events)
			initLoc.createEnvironmentLoopEdges(messageQueueTrace, match.systemPort, match.event, match.instance /*Sync owner*/)		
		}
		for (match : DistinctWrapperInEvents.Matcher.on(engine).getAllMatches(wrapper, null, null)) {
			val queue = wrapper.getContainerMessageQueue(match.port, match.event) // In what message queue this event is stored
			val messageQueueTrace = queue.getTrace(null) // Getting the owner
			// Creating the loop edge (or edges in case of parametered events)
			initLoc.createEnvironmentLoopEdges(messageQueueTrace, match.port, match.event, null)		
		}
	].build
	
	val instanceWrapperEnvironmentRule = createRule(TopAsyncCompositeComponents.instance).action [
		// Creating the template
		val initLoc = createTemplateWithInitLoc(it.asyncComposite.name + "Environment" + id++, "InitLoc")
		// Creating in events
		for (match : TopAsyncSystemInEvents.Matcher.on(engine).getAllMatches(it.asyncComposite, null, null, null, null)) {
			val wrapper = match.instance.type as AsynchronousAdapter
			val queue = wrapper.getContainerMessageQueue(match.port /*Wrapper port, this is the instance port*/, match.event) // In what message queue this event is stored
			val messageQueueTrace = queue.getTrace(match.instance) // Getting the owner
			// Creating the loop edge (or edges in case of parametered events)
			initLoc.createEnvironmentLoopEdges(messageQueueTrace, match.port, match.event, null /*no sync owner*/)
		}
	].build
	
	protected def void createEnvironmentLoopEdges(Location initLoc, MessageQueueTrace messageQueueTrace, Port port, Event event, SynchronousComponentInstance owner) {
		// Checking the parameters
		val expressions = ValuesOfEventParameters.Matcher.on(engine).getAllValuesOfexpression(port, event)
		for (expression : expressions) {
			// New edge is needed in every iteration!
			val loopEdge = initLoc.createEdge(initLoc)
			loopEdge.createEnvironmentEdge(messageQueueTrace, event.getConstRepresentation(port), expression, owner)
			loopEdge.addGuard(isStableVar, LogicalOperator.AND) // For the cutting of the state space
			loopEdge.addInitializedGuards
		}
		if (expressions.empty) {
			val loopEdge = initLoc.createEdge(initLoc)
			loopEdge.createEnvironmentEdge(messageQueueTrace, event.getConstRepresentation(port), createLiteralExpression => [it.text = "0"])
			loopEdge.addGuard(isStableVar, LogicalOperator.AND) // For the cutting of the state space
			loopEdge.addInitializedGuards
		}
	}
	
	val topWrapperClocksRule = createRule(TopWrapperComponents.instance).action [
		if (!it.wrapper.clocks.empty) {
			// Creating the template
			val initLoc = createTemplateWithInitLoc(it.wrapper.name + "Clock" + id++, "InitLoc")
			// Creating clock events
			wrapper.createClockEvents(initLoc, null /*no owner in this case*/)
		}
	].build
	
	val instanceWrapperClocksRule = createRule(TopAsyncCompositeComponents.instance).action [
		// Creating the template
		val initLoc = createTemplateWithInitLoc(it.asyncComposite.name + "Clock" + id++, "InitLoc")
		// Creating clock events
		for (match : SimpleWrapperInstances.Matcher.on(engine).allMatches) {
			match.wrapper.createClockEvents(initLoc, match.instance)
		}
	].build
	
	protected def createClockEvents(AsynchronousAdapter wrapper, Location initLoc, AsynchronousComponentInstance owner) {
		val clockTemplate = initLoc.parentTemplate
		for (match : QueuesOfClocks.Matcher.on(engine).getAllMatches(wrapper, null, null)) {
			val messageQueueTrace = match.queue.getTrace(owner) // Getting the queue trace with respect to the owner
			// Creating the loop edge
			val clockEdge = initLoc.createEdge(initLoc)
			// It can be fired even when the queue is full to avoid DEADLOCKS (the function handles this)
			// It can be fired only if the template is stable
			clockEdge.addGuard(isStableVar, LogicalOperator.AND)		
			// Only if the wrapper/instance is initialized
			clockEdge.addInitializedGuards
			// Creating an Uppaal clock var
			val clockVar = clockTemplate.declarations.createChild(declarations_Declaration, clockVariableDeclaration) as ClockVariableDeclaration
			clockVar.createTypeAndVariable(target.clock, clockNamePrefix + match.clock.name + owner.postfix)
			// Creating the trace
			addToTrace(match.clock, #{clockVar}, trace)
			// push....
			clockEdge.createChild(edge_Update, functionCallExpression) as FunctionCallExpression => [
		   		// No addFunctionCall method as there are arguments
		   		it.function = messageQueueTrace.pushFunction.function
		   		it.createChild(functionCallExpression_Argument, identifierExpression) as IdentifierExpression => [
		   			it.identifier = match.clock.constRepresentation.variable.head
		   		]
		   		it.createChild(functionCallExpression_Argument, literalExpression) as LiteralExpression => [
		   			it.text = "0"
		   		]
		   	]
		   	// clock = 0
		   	clockEdge.createChild(edge_Update, assignmentExpression) as AssignmentExpression => [
		   		it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
		   			it.identifier = clockVar.variable.head
		   		]
		   		it.createChild(binaryExpression_SecondExpr, literalExpression) as LiteralExpression => [
		   			it.text = "0"
		   		]
		   	]
			// Transforming S to MS
			val timeSpec = match.clock.timeSpecification
			val timeValue = timeSpec.convertToMs
			val locInvariant = initLoc.invariant
			// Putting the clock expression onto the location as invariant
			if (locInvariant !== null) {
				initLoc.insertLogicalExpression(location_Invariant, CompareOperator.LESS_OR_EQUAL, clockVar, timeValue, locInvariant, LogicalOperator.AND)
			} 
			else {
				initLoc.insertCompareExpression(location_Invariant, CompareOperator.LESS_OR_EQUAL, clockVar, timeValue)
			}
			// Putting the clock expression onto the location as guard
			clockEdge.addGuard(createCompareExpression as CompareExpression => [
				it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
					it.identifier = clockVar.variable.head // Always one variable in the container
				]
				it.operator = CompareOperator.GREATER_OR_EQUAL	
				it.transform(binaryExpression_SecondExpr, timeValue, null)		
			], LogicalOperator.AND)
		}
	}
	
	private def addFunctionCall(EObject container, EReference reference, Function function) {
		if (isMinimalElementSet && function.isInlinable) {
			log(Level.INFO, "Inlining " + function.name)
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
	
	private def addInitializedGuards(Edge edge) {
		if (component instanceof AsynchronousAdapter) {
			val isInitializedVar = component.initializedVariable
			edge.addGuard(isInitializedVar, LogicalOperator.AND)
		}
		if (component instanceof AsynchronousCompositeComponent) {
			for (instance : SimpleWrapperInstances.Matcher.on(engine).allValuesOfinstance) {
				val isInitializedVar = instance.initializedVariable
				edge.addGuard(isInitializedVar, LogicalOperator.AND)
			}
		}
	}
	
	/**
	 * Responsible for creating an AND logical expression containing an already existing expression and a clock expression.
	 */
	private def insertLogicalExpression(EObject container, EReference reference, CompareOperator compOp, ClockVariableDeclaration clockVar,
		hu.bme.mit.gamma.expression.model.Expression timeExpression, Expression originalExpression, LogicalOperator logOp) {
		val andExpression = container.createChild(reference, logicalExpression) as LogicalExpression => [
			it.operator = logOp
			it.secondExpr = originalExpression
		]
		andExpression.insertCompareExpression(binaryExpression_FirstExpr, compOp, clockVar, timeExpression)
	}
	
	/**
	 * Responsible for creating a compare expression that compares the given clock variable to the given expression.
	 */
	private def insertCompareExpression(EObject container, EReference reference, CompareOperator compOp,
			ClockVariableDeclaration clockVar, hu.bme.mit.gamma.expression.model.Expression timeExpression) {
		container.createChild(reference, compareExpression) as CompareExpression => [
			it.operator = compOp	
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = clockVar.variable.head // Always one variable in the container
			]
			it.transform(binaryExpression_SecondExpr, timeExpression, null)		
		]
	}
	
	private def insertLogicalExpression(EObject container, EReference reference, CompareOperator compOp, ClockVariableDeclaration clockVar,
			Expression timeExpression, Expression originalExpression, LogicalOperator logOp) {
		val andExpression = container.createChild(reference, logicalExpression) as LogicalExpression => [
				it.operator = logOp
				it.secondExpr = originalExpression
		]
		andExpression.insertCompareExpression(binaryExpression_FirstExpr, compOp, clockVar, timeExpression)
	}
	
	private def insertCompareExpression(EObject container, EReference reference, CompareOperator compOp,
			ClockVariableDeclaration clockVar, Expression timeExpression) {
		container.createChild(reference, compareExpression) as CompareExpression => [
			it.operator = compOp
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = clockVar.variable.head // Always one variable in the container
			]
			it.secondExpr = timeExpression
		]
	}
	
	protected def createEnvironmentEdge(Edge edge, MessageQueueTrace messageQueueTrace,
			DataVariableDeclaration representation, hu.bme.mit.gamma.expression.model.Expression expression, SynchronousComponentInstance instance) {
		// !isFull...
		val isNotFull = createNegationExpression => [
			it.addFunctionCall(negationExpression_NegatedExpression, messageQueueTrace.isFullFunction.function)
		 ]
		edge.addGuard(isNotFull, LogicalOperator.AND)
		// push....
		edge.addPushFunctionUpdate(messageQueueTrace, representation, expression, instance)
	}
	
	protected def FunctionCallExpression addPushFunctionUpdate(Edge edge, MessageQueueTrace messageQueueTrace,
			DataVariableDeclaration representation, hu.bme.mit.gamma.expression.model.Expression expression, SynchronousComponentInstance instance) {
		// No addFunctionCall method as there are arguments
		edge.createChild(edge_Update, functionCallExpression) as FunctionCallExpression => [
			it.function = messageQueueTrace.pushFunction.function
			   	it.createChild(functionCallExpression_Argument, identifierExpression) as IdentifierExpression => [
			   		it.identifier = representation.variable.head
			   	]
			it.transform(functionCallExpression_Argument, expression, instance)
		]
	}
	
	protected def createEnvironmentEdge(Edge edge, MessageQueueTrace messageQueueTrace,
			DataVariableDeclaration representation, Expression expression) {
		// !isFull...
		val isNotFull = createNegationExpression => [
			it.addFunctionCall(negationExpression_NegatedExpression, messageQueueTrace.isFullFunction.function)
		 ]
		edge.addGuard(isNotFull, LogicalOperator.AND)
		// push....
		edge.addPushFunctionUpdate(messageQueueTrace, representation, expression)
	}
	
	protected def FunctionCallExpression addPushFunctionUpdate(Edge edge, MessageQueueTrace messageQueueTrace, DataVariableDeclaration representation, Expression expression) {
		// No addFunctionCall method as there are arguments
		edge.createChild(edge_Update, functionCallExpression) as FunctionCallExpression => [
			it.function = messageQueueTrace.pushFunction.function
			it.createChild(functionCallExpression_Argument, identifierExpression) as IdentifierExpression => [
				it.identifier = representation.variable.head
			]
			it.argument += expression
		]
	}
	
	val topWrapperSchedulerRule = createRule(TopWrapperComponents.instance).action [
		val initLoc = createTemplateWithInitLoc(it.wrapper.name + "Scheduler" + id++, "InitLoc")
		val asyncSchedulerChannelVariable = wrapper.asyncSchedulerChannel.variable.head
		initLoc.createRandomScheduler(asyncSchedulerChannelVariable)
	].build
	
	val instanceWrapperSchedulerRule = createRule(TopAsyncCompositeComponents.instance).action [
		val initLoc = createTemplateWithInitLoc(it.asyncComposite.name + "Scheduler" + id++, "InitLoc")
		var Edge lastEdge = null
		for (instance : SimpleWrapperInstances.Matcher.on(engine).allValuesOfinstance) {
			switch (asyncScheduler) {
				case FAIR: {
					lastEdge = lastEdge.createFairScheduler(initLoc, instance)
				}
				default: {
					val asyncSchedulerChannelVariable = instance.asyncSchedulerChannel.variable.head
					lastEdge = initLoc.createRandomScheduler(asyncSchedulerChannelVariable)
				}
			}
		}
	].build
	
	private def createFairScheduler(Edge edge, Location initLoc, AsynchronousComponentInstance instance) {
   		var lastEdge = edge
   		val syncVariable = instance.asyncSchedulerChannel.variable.head
		if (lastEdge === null) {
			// Creating first edge
			lastEdge = initLoc.createEdge(initLoc)
			lastEdge.setSynchronization(syncVariable, SynchronizationKind.SEND)
			lastEdge.addInitializedGuards // Only if the instance is initialized
		}
		else {
			// Creating scheduling edges for all instances
			val schedulingEdge = createCommittedSyncTarget(lastEdge.target, syncVariable, "schedule" + instance.name)
			schedulingEdge.source.locationTimeKind = LocationKind.URGENT
			lastEdge.target = schedulingEdge.source
			lastEdge = schedulingEdge
		}
		return lastEdge
	}

	private def createRandomScheduler(Location initLoc, Variable asyncSchedulerChannelVariable) {
		// Creating the loop edge
		val loopEdge = initLoc.createEdge(initLoc)
		loopEdge.setSynchronization(asyncSchedulerChannelVariable, SynchronizationKind.SEND)
		// Adding isStable guard
		loopEdge.addGuard(isStableVar, LogicalOperator.AND)
		loopEdge.addInitializedGuards // Only if the instance is initialized
		// Checking scheduler constraints
		val minTimeoutValue = if (minimalOrchestratingPeriod === null) {
			Optional.ofNullable(null)
		} else {
			Optional.ofNullable(minimalOrchestratingPeriod.convertToMs.evaluate)
		}
		val maxTimeoutValue = if (maximalOrchestratingPeriod === null) {
			Optional.ofNullable(null)
		} else {
			Optional.ofNullable(maximalOrchestratingPeriod.convertToMs.evaluate)
		}
		if (minTimeoutValue.present || maxTimeoutValue.present) {
			val parentTemplate = initLoc.parentTemplate
			// Creating an Uppaal clock var
			val clockVar = parentTemplate.declarations.createChild(declarations_Declaration, clockVariableDeclaration) as ClockVariableDeclaration
			clockVar.createTypeAndVariable(target.clock, clockNamePrefix + asyncSchedulerChannelVariable.name + id++)
			// Creating the guard
			if (minTimeoutValue.present) {
				loopEdge.createMinTimeGuard(clockVar, minTimeoutValue.get)
			}
			// Creating the location invariant
			if (maxTimeoutValue.present) {
				initLoc.createMaxTimeInvariant(clockVar, maxTimeoutValue.get)
			}
			// Creating the clock reset
			loopEdge.createAssignmentExpression(edge_Update, clockVar, createLiteralExpression => [it.text = "0"])
		}
		return loopEdge
	}
	
	/**
	 * Responsible for creating a wrapper-sync connector template for a single synchronous composite component wrapped by a Wrapper.
	 * Note that it only fires if there are top wrappers.
	 * Depends on no rules.
	 */
	val topWrapperConnectorRule = createRule(TopWrapperComponents.instance).action [		
		// Creating the template
		val initLoc = createTemplateWithInitLoc(it.wrapper.name + "Connector" + id++, "DefaultLoc")
		val connectorTemplate = initLoc.parentTemplate
		val asyncChannel = wrapper.asyncSchedulerChannel // The wrapper is scheduled with this channel
		val syncChannel = wrapper.syncSchedulerChannel // The wrapped sync component is scheduled with this channel
		val initializedVar = wrapper.initializedVariable // This variable marks the whether the wrapper has been initialized
		val relayLoc = wrapper.createConnectorEdges(initLoc, asyncChannel, syncChannel, initializedVar, null /*no owner in this case*/)
		relayLoc.locationTimeKind = LocationKind.COMMITED
		// A new entry is needed so the entry events and event transmissions are transmitted to the proper queues 
		val initEdge = relayLoc.createEdgeCommittedTarget("ConnectorEntry" + id++)
		initEdge.source.locationTimeKind = LocationKind.URGENT
		connectorTemplate.init = initEdge.source
	].build
	
	 /**
	 * Responsible for creating a scheduler template for all synchronous composite components wrapped by wrapper instances.
	 * Note that it only fires if there are wrapper instances.
	 * Depends on no rules.
	 */
	val instanceWrapperConnectorRule = createRule(SimpleWrapperInstances.instance).action [		
		// Creating the template
		val initLoc = createTemplateWithInitLoc(it.wrapper.name + "Connector" + id++, "DefaultLoc")
		val connectorTemplate = initLoc.parentTemplate
		val asyncChannel = it.instance.asyncSchedulerChannel // The wrapper is scheduled with this channel
		val syncChannel = it.instance.syncSchedulerChannel // The wrapped sync component is scheduled with this channel
		val initializedVar = it.instance.initializedVariable // This variable marks the whether the wrapper has been initialized
		val relayLoc = it.wrapper.createConnectorEdges(initLoc, asyncChannel, syncChannel, initializedVar, it.instance)
		relayLoc.locationTimeKind = LocationKind.COMMITED
		// A new entry is needed so the entry events and event transmissions are transmitted to the proper queues 
		val initEdge = relayLoc.createEdgeCommittedTarget("ConnectorEntry" + id++)
		initEdge.source.locationTimeKind = LocationKind.URGENT
		connectorTemplate.init = initEdge.source
	].build
	
	protected def createConnectorEdges(AsynchronousAdapter wrapper, Location initLoc, ChannelVariableDeclaration asyncChannel,
			ChannelVariableDeclaration syncChannel, DataVariableDeclaration initializedVar, AsynchronousComponentInstance owner) {
		checkState(wrapper.controlSpecifications.map[it.trigger].filter(AnyTrigger).empty, "Any triggers are not supported in formal verification.")
		val synchronousComponent = wrapper.wrappedComponent.type
		val relayLocPair = initLoc.createRelayEdges(synchronousComponent, syncChannel, initializedVar)
		val waitingForRelayLoc = relayLocPair.key
		val relayLoc = relayLocPair.value
		// Sync composite in events
		for (match : TopSyncSystemInEvents.Matcher.on(engine).getAllMatches(synchronousComponent, null, null, null, null)) {
			val toRaiseVar = match.event.getToRaiseVariable(match.port, match.instance) // The event that needs to be raised
			val queue = wrapper.getContainerMessageQueue(match.systemPort, match.event) // In what message queue this event is stored
			val messageQueueTrace = queue.getTrace(owner) // Getting the queue trace in accordance with onwer
			
			// Creating the loop edge with the toRaise = true
			val loopEdge = initLoc.createLoopEdgeWithBoolAssignment(toRaiseVar, true)
			// Creating the ...Value = ...Messages().value
			val expressions = ValuesOfEventParameters.Matcher.on(engine).getAllValuesOfexpression(match.port, match.event)
			if (!expressions.empty) {
				val valueOfVars = match.event.parameterDeclarations.head.allValuesOfTo.filter(DataVariableDeclaration).filter[it.owner == match.instance]
				if (valueOfVars.size != 1) {
					throw new IllegalArgumentException("Not one valueOfVar: " + valueOfVars)
				}	
				val valueOfVar = valueOfVars.head
				// Creating the ...Messages().value expression
				val scopedIdentifierExp = messageQueueTrace.peekFunction.messageValueScopeExp(messageValue.variable.head)
				// Creating the ...Value = ...Messages().value
				loopEdge.createAssignmentExpression(edge_Update, valueOfVar, scopedIdentifierExp)
			}
			// "Basic" loop edge
			loopEdge.createConnectorEdge(asyncChannel, wrapper, messageQueueTrace, match.systemPort, match.event, owner)
			// If this event is in a control spec, the wrapped syn component needs to be scheduled
			if (RunOnceEventControl.Matcher.on(engine).hasMatch(wrapper, match.systemPort, match.event)) {
				// Scheduling the sync
				val syncEdge = waitingForRelayLoc.createCommittedSyncTarget(syncChannel.variable.head, "schedule" + id++)
				loopEdge.target = syncEdge.source
			}
		}
		// Creating edges for control events of wrapper
		for (match : RunOnceEventControl.Matcher.on(engine).getAllMatches(wrapper, null, null)
				.filter[!TopSyncSystemInEvents.Matcher.on(engine).hasMatch(it.wrapper.wrappedComponent.type, it.port, null, null, it.event)]) {
			// No events of the wrapped component
			val queue = wrapper.getContainerMessageQueue(match.port, match.event) // In what message queue this event is stored
			val messageQueueTrace = queue.getTrace(owner) // Getting the queue trace in accordance with onwer
			// Creating the loop edge
			val edge = initLoc.createEdge(initLoc)
			edge.createConnectorEdge(asyncChannel, wrapper, messageQueueTrace, match.port, match.event, owner)
			val syncEdge = waitingForRelayLoc.createCommittedSyncTarget(syncChannel.variable.head, "schedule" + id++)
			edge.target = syncEdge.source
		}
		// Creating edges for unused events of wrapper
		for (match : UnusedWrapperEvents.Matcher.on(engine).getAllMatches(wrapper, null, null)) {
			val queue = wrapper.getContainerMessageQueue(match.port, match.event) // In what message queue this event is stored
			val messageQueueTrace = queue.getTrace(owner) // Getting the queue trace in accordance with onwer
			// Creating the loop edge
			val edge = initLoc.createEdge(initLoc)
			edge.createConnectorEdge(asyncChannel, wrapper, messageQueueTrace, match.port, match.event, owner)
		}
		// Creating the loop edges for clock triggers
		for (match : RunOnceClockControl.Matcher.on(engine).getAllMatches(wrapper, null, null)) {
			val messageQueueTrace = match.queue.getTrace(owner)
			// Creating the scheduler sync edge
			val syncEdge = waitingForRelayLoc.createCommittedSyncTarget(syncChannel.variable.head, "schedule" + id++)
			// Creating the edge checking for the events in the queue
			val edge = initLoc.createEdge(syncEdge.source)
			edge.setSynchronization(asyncChannel.variable.head, SynchronizationKind.RECEIVE) // Setting the sync
			// Guards checking higher priority queues
			for (higherPirorityQueue : QueuePriorities.Matcher.on(engine).getAllValuesOfhigherPriotityQueue(wrapper, match.queue)) {
				edge.addPriorityGuard(wrapper, higherPirorityQueue, owner)
			}
			// ...Messages().event == clocksignal
			val valueCompareExpression = createPeekClockCompare(messageQueueTrace, match.clock)
			edge.addGuard(valueCompareExpression, LogicalOperator.AND)
			// Shifting the message queue
			edge.addFunctionCall(edge_Update, messageQueueTrace.shiftFunction.function)
			// Adding isStable  guard
			edge.addGuard(isStableVar, LogicalOperator.AND)
		}
		return relayLoc
	}
	
	protected def void createConnectorEdge(Edge edge, ChannelVariableDeclaration asyncChannel, AsynchronousAdapter wrapper,
			MessageQueueTrace messageQueueTrace, Port port, Event event, ComponentInstance owner) {
		// Putting the ? async channel to the loop edge
		edge.setSynchronization(asyncChannel.variable.head, SynchronizationKind.RECEIVE)
		// The event must be on the guard
		// ...Messages().event == Port_event
		val valueCompareExpression = createPeekValueCompare(messageQueueTrace, port, event)
		edge.addGuard(valueCompareExpression, LogicalOperator.AND)
		// The priority needs to be on the guard
		for (higherPirorityQueue : QueuePriorities.Matcher.on(engine).getAllValuesOfhigherPriotityQueue(wrapper, messageQueueTrace.queue)) {
			edge.addPriorityGuard(wrapper, higherPirorityQueue, owner)
		}
		// Adding isStable  guard
		edge.addGuard(isStableVar, LogicalOperator.AND)
		// Shifting the message queue
		edge.addFunctionCall(edge_Update, messageQueueTrace.shiftFunction.function)
	}
	
	protected def createRelayEdges(Location initLoc, SynchronousComponent syncComposite,
			ChannelVariableDeclaration syncChan, DataVariableDeclaration initializedVar) {
		val parentTemplate = initLoc.parentTemplate
		val relayLoc = parentTemplate.createChild(template_Location, location) as Location => [
			it.name = "RelayLoc"
		]
		val finishRelayEdge = relayLoc.createEdge(initLoc)
		val waitingForRelayLoc = parentTemplate.createChild(template_Location, location) as Location => [
			it.name = "WaitingRelayLoc"
		]
		val waitingRelaySyncEdge = waitingForRelayLoc.createEdge(relayLoc)
		waitingRelaySyncEdge.setSynchronization(syncChan.variable.head, SynchronizationKind.RECEIVE)
		// Creating relay edges
		val originalGuards = new HashSet<Expression>
		for (outEventMatch : TopSyncSystemOutEvents.Matcher.on(engine).getAllMatches(syncComposite, null, null, null, null)) {
			val relayEdge = relayLoc.createEdge(relayLoc)
			val outVariable = outEventMatch.event.getOutVariable(outEventMatch.port, outEventMatch.instance)
			// Adding out-event guard
			val guard = relayEdge.addGuard(outVariable, LogicalOperator.AND)
			originalGuards += guard
			// Resetting the out-event variable
			relayEdge.createAssignmentExpression(edge_Update, outVariable, false)
			for (queueMatch : EventsIntoMessageQueues.Matcher.on(engine).getAllMatches(null, outEventMatch.systemPort, outEventMatch.event, null, null, null)) {
				var DataVariableDeclaration valueOfVar = null
				if (!outEventMatch.event.parameterDeclarations.empty) {
					valueOfVar = outEventMatch.event.getValueOfVariable(outEventMatch.port/* Not sure if correct port*/, outEventMatch.instance)
				}
				relayEdge.createQueueInsertion(queueMatch.inPort, queueMatch.raisedEvent, queueMatch.inInstance, valueOfVar)
			}
		}
		// Putting "default" guard on the finish relay edge
		finishRelayEdge.createDefaultExpression(originalGuards)
		// Setting the isStable = true, needed after the initialization 
		finishRelayEdge.createAssignmentExpression(edge_Update, initializedVar, true)
		return new Pair<Location, Location>(waitingForRelayLoc, relayLoc)
	}
	
	protected def CompareExpression createPeekValueCompare(MessageQueueTrace messageQueueTrace, Port port, Event event) {
		createCompareExpression => [
			it.firstExpr = messageQueueTrace.peekFunction.messageValueScopeExp(messageEvent.variable.head)
			it.operator = CompareOperator.EQUAL
			it.createChild(binaryExpression_SecondExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = event.getConstRepresentation(port).variable.head
			]	
		]
	}
	
	protected def CompareExpression createPeekClockCompare(MessageQueueTrace messageQueueTrace, Clock clock) {
		return createCompareExpression => [
			it.firstExpr = messageQueueTrace.peekFunction.messageValueScopeExp(messageEvent.variable.head)
			it.operator = CompareOperator.EQUAL
			it.createChild(binaryExpression_SecondExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = clock.getConstRepresentation().variable.head
			]	
		]
	}
	
	private def messageValueScopeExp(FunctionDeclaration peekFunction, Variable variable) {
		return createScopedIdentifierExpression => [
			it.addFunctionCall(scopedIdentifierExpression_Scope, peekFunction.function)
			it.createChild(scopedIdentifierExpression_Identifier, identifierExpression) as IdentifierExpression => [
				it.identifier = variable
			]
		]
	}
	
	private def addPriorityGuard(Edge edge, AsynchronousAdapter wrapper, MessageQueue higherPirorityQueue, ComponentInstance owner) {
		val higherPriorityQueueTrace = higherPirorityQueue.getTrace(owner) // No owner in this case
		// ...MessagesSize == 0
		val sizeCompareExpression = createCompareExpression => [
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = higherPriorityQueueTrace.capacityVar.variable.head
			]	
			it.operator = CompareOperator.EQUAL
			it.createChild(binaryExpression_SecondExpr, literalExpression) as LiteralExpression => [
				it.text = "0"
			]	
		]
		edge.addGuard(sizeCompareExpression, LogicalOperator.AND)		
	}
	
	private def createDefaultExpression(Edge edge, Collection<? extends Expression> expressions) {
		for (exp : expressions) {
			val negatedExp = createNegationExpression as NegationExpression => [
				it.negatedExpression = exp.clone(true, true)
			]
			edge.addGuard(negatedExp, LogicalOperator.AND)
		}
	}
	
	private def getContainerMessageQueue(AsynchronousAdapter wrapper, Port port, Event event) {
		val queues = QueuesOfEvents.Matcher.on(engine).getAllValuesOfqueue(wrapper, port, event)
		if (queues.size > 1) {
			log(Level.WARNING, "Warning: more than one message queue " + wrapper.name + "." + port.name + "_" + event.name + ":" + queues)			
		}
		return queues.head
	}
	
	/**
	 * Responsible for creating a scheduler template for TOP synchronous composite components.
	 * Note that it only fires if there are TOP synchronous composite components.
	 * Depends on all statechart mapping rules.
	 */
	val topSyncOrchestratorRule = createRule(TopUnwrappedSyncComponents.instance).action [		
		val lastEdge = it.syncComposite.createSchedulerTemplate(null)
		// Creating timing for the orchestrator template
		val initLoc = lastEdge.target
		val firstEdges = initLoc.parentTemplate.edge.filter[it.source === initLoc]
		checkState(firstEdges.size == 1)
		val firstEdge = firstEdges.head
		val minTimeoutValue = if (minimalOrchestratingPeriod === null) {
			Optional.ofNullable(null)
		} else {
			Optional.ofNullable(minimalOrchestratingPeriod.convertToMs.evaluate)
		}
		val maxTimeoutValue = if (maximalOrchestratingPeriod === null) {
			Optional.ofNullable(maxTimeout)
		} else {
			Optional.ofNullable(maximalOrchestratingPeriod.convertToMs.evaluate)
		}
		// Setting the timing in the orchestrator template
		firstEdge.setOrchestratorTiming(minTimeoutValue, lastEdge, maxTimeoutValue)
		if (!minTimeoutValue.present && !maxTimeoutValue.present) {
			// If there is no timing, we set the loc to urgent
			initLoc.locationTimeKind = LocationKind.URGENT
		}
	].build
	
	/**
	 * Responsible for creating a scheduler template for a single synchronous composite component wrapped by a Wrapper.
	 * Note that it only fires if there are top wrappers.
	 * Depends on topWrapperSyncChannelRule and all statechart mapping rules.
	 */
	val topWrappedSyncOrchestratorRule = createRule(TopWrapperComponents.instance).action [		
		val lastEdge = it.composite.createSchedulerTemplate(it.wrapper.syncSchedulerChannel)
		lastEdge.setSynchronization(it.wrapper.syncSchedulerChannel.variable.head, SynchronizationKind.SEND)
	].build
	
	 /**
	 * Responsible for creating a scheduler template for all synchronous composite components wrapped by wrapper instances.
	 * Note that it only fires if there are wrapper instances.
	 * Depends on allWrapperSyncChannelRule and all statechart mapping rules.
	 */
	val instanceWrapperSyncOrchestratorRule = createRule(SimpleWrapperInstances.instance).action [		
		val lastEdge = it.component.createSchedulerTemplate(it.instance.syncSchedulerChannel)
		lastEdge.setSynchronization(it.instance.syncSchedulerChannel.variable.head, SynchronizationKind.SEND)
		val orchestratorTemplate = lastEdge.parentTemplate
		addToTrace(it.instance, #{orchestratorTemplate}, instanceTrace)
	].build
	
	/**
	 * Responsible for creating the scheduler template that schedules the run of the automata.
	 * (A series edges with runCycle synchronizations and variable swapping on them.) 
	 */
	private def Edge createSchedulerTemplate(SynchronousComponent compositeComponent, ChannelVariableDeclaration chan) {
		val initLoc = createTemplateWithInitLoc(compositeComponent.name + "Orchestrator" + id++, "InitLoc")
		val schedulerTemplate = initLoc.parentTemplate
		val firstEdge = initLoc.createEdge(initLoc)
		// If a channel has been passed for async-sync synchronization
		if (chan !== null) {
			firstEdge.setSynchronization(chan.variable.head, SynchronizationKind.RECEIVE)
		}
		var lastEdge = firstEdge
		// Creating the scheduler of the whole system
		lastEdge = compositeComponent.scheduleTopComposite(lastEdge)
		// A final edge is needed to let all edges of committed locations to fire
		val finalLoc = schedulerTemplate.createChild(template_Location, location) as Location => [
			it.name = "final"
			it.locationTimeKind = LocationKind.URGENT
			it.comment = "To ensure all synchronizations to take place before an isStable state."
		]
		lastEdge.target = finalLoc
		val beforeIsStableEdge = finalLoc.createEdge(initLoc)
		lastEdge = beforeIsStableEdge
		// Clearing raised out events on scheduling turn
		firstEdge.addFunctionCall(edge_Update, createClearFunction(compositeComponent).function)
		firstEdge.createAssignmentExpression(edge_Update, isStableVar, false)
		lastEdge.createAssignmentExpression(edge_Update, isStableVar, true)
		// Setting isScheduled variables
		for (region : InstanceRegions.Matcher.on(engine).allValuesOfregion) {
			val isScheduledVar = region.allValuesOfTo.filter(Template).head
									.allValuesOfTo.filter(DataVariableDeclaration).head
			firstEdge.createAssignmentExpression(edge_Update, isScheduledVar, false)
		}
		// Creating a separate initial location so that the NTA can be initialized in !isStable
		val trueInitialLocation = schedulerTemplate.createChild(template_Location, location) as Location => [
			it.name = "notIsStable"
			it.locationTimeKind = LocationKind.URGENT
		]
		schedulerTemplate.init = trueInitialLocation
		trueInitialLocation.createEdge(initLoc) => [
			it.createAssignmentExpression(edge_Update, isStableVar, true)
		]
		// Returning last edge
		return lastEdge
	}
	
	/**
	 * Returns the maximum timeout value (specified as an integer literal) in the model.
	 */
	private def getMaxTimeout() {
		try {
			val maxValue = TimeoutValues.Matcher.on(engine).allValuesOftimeSpec
				.map[it.convertToMs.evaluate]
				.max
			return maxValue
		} catch (NoSuchElementException e) {
			return null
		}
	}
	
	/**
	 * Creates a clock for the template of the given edge, sets the clock to "0" on the given edge,
	 *  and places an invariant on the target of the edge.
	 */
	private def setOrchestratorTiming(Edge firstEdge, Optional<Integer> minTime, Edge lastEdge, Optional<Integer> maxTime) {
		checkState(firstEdge.source === lastEdge.target)
		if (!minTime.present && !maxTime.present) {
			return
		}
		val initLoc = lastEdge.target
		val template = lastEdge.parentTemplate
		// Creating the clock
		val clockVar = template.declarations.createChild(declarations_Declaration, clockVariableDeclaration) as ClockVariableDeclaration
		clockVar.createTypeAndVariable(target.clock, "timerOrchestrator" + (id++))
		// Creating the guard
		if (minTime.present) {
			firstEdge.createMinTimeGuard(clockVar, minTime.get)
		}
		// Creating the location invariant
		if (maxTime.present) {
			initLoc.createMaxTimeInvariant(clockVar, maxTime.get)
		}
		// Creating the clock reset
		lastEdge.createAssignmentExpression(edge_Update, clockVar, createLiteralExpression => [it.text = "0"])
	}
	
	private def createMinTimeGuard(Edge clockEdge, ClockVariableDeclaration clockVar, Integer minTime) {
		clockEdge.addGuard(createCompareExpression => [
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = clockVar.variable.head // Always one variable in the container
			]
			it.operator = CompareOperator.GREATER_OR_EQUAL
			it.secondExpr = createLiteralExpression => [
				it.text = minTime.toString
			] 
		], LogicalOperator.AND)
	}
	
	private def createMaxTimeInvariant(Location clockLocation, ClockVariableDeclaration clockVar, Integer maxTime) {
		val locInvariant = clockLocation.invariant
		val maxTimeExpression = createLiteralExpression => [
			it.text = maxTime.toString
		]
		if (locInvariant !== null) {
			clockLocation.insertLogicalExpression(location_Invariant, CompareOperator.LESS_OR_EQUAL, clockVar, maxTimeExpression, locInvariant, LogicalOperator.AND)
		} 
		else {
			clockLocation.insertCompareExpression(location_Invariant, CompareOperator.LESS_OR_EQUAL, clockVar, maxTimeExpression)
		}
	}
	
	/**
	 * Creates the scheduling of the whole network of automata starting out from the given composite component
	 */
	private def scheduleTopComposite(SynchronousComponent component, Edge previousLastEdge) {
		checkState (component instanceof AbstractSynchronousCompositeComponent ||
			component instanceof StatechartDefinition
		)
		var Edge lastEdge = previousLastEdge
		if (component instanceof SynchronousCompositeComponent) {
			// Creating a new location is needed so the queue swap can be done after finalization of previous template
			lastEdge = component.swapQueuesOfContainedSimpleInstances(lastEdge)
		}
		if (component instanceof AbstractSynchronousCompositeComponent) {
			for (instance : component.instancesToBeScheduled /*Cascades are scheduled in accordance with the execution list*/) {
				lastEdge = instance.scheduleInstance(lastEdge)
			}
		}
		else if (component instanceof StatechartDefinition) {
			val instances = SimpleInstances.Matcher.on(engine).getAllValuesOfinstance(component)
			checkState(instances.size == 1, instances)
			val instance = instances.head
			val swapEdge = lastEdge.target.createEdgeCommittedTarget("swapLocation" + id++) => [
				it.source.locationTimeKind = LocationKind.URGENT
			]
			lastEdge.target = swapEdge.source
			lastEdge = swapEdge
			lastEdge.createQueueSwap(instance)
			lastEdge = instance.scheduleInstance(lastEdge)		
		}
		return lastEdge
	}
	
	/**
	 * Returns the instances (in order) that should be scheduled in the given AbstractSynchronousCompositeComponent.
	 * Note that in cascade composite an instance might be scheduled multiple times.
	 */
	private dispatch def getInstancesToBeScheduled(AbstractSynchronousCompositeComponent component) {
		return component.components
	}
	
	private dispatch def getInstancesToBeScheduled(CascadeCompositeComponent component) {
		if (component.executionList.empty) {
			return component.components
		}
		return component.executionList
	}
	
	/**
	 * Puts the queue swapping updates (isRaised = toRaised...) of all instances contained by the given topComposite onto the given edge.
	 */
	private def Edge swapQueuesOfContainedSimpleInstances(SynchronousCompositeComponent topComposite, Edge previousLastEdge) {
		var Edge lastEdge = previousLastEdge
		val swapLocation = lastEdge.parentTemplate.createChild(template_Location, location) as Location => [
			it.name = "swapLocation" + id++
			it.locationTimeKind = LocationKind.URGENT
		]
		val swapEdge = swapLocation.createEdge(lastEdge.target)
		lastEdge.target = swapEdge.source
		lastEdge = swapEdge
		val sameQueueSwapInstances = topComposite.simpleInstancesInSameQueueSwap
		Logger.getLogger("GammaLogger").log(Level.INFO, "Instances with the same swap schedule in " + topComposite.name + ": " +sameQueueSwapInstances)
		// Swapping queues of instances whose queues have not yet been swapped
		for (queueSwapInstance : sameQueueSwapInstances) {
			// Creating updates of a single instance
			lastEdge.createQueueSwap(queueSwapInstance)
		}
		return lastEdge
	}
	
	/**
	 * Creates the scheduling (runCycle synchronizations and queue swapping updates) starting the given instance.
	 */
	private def Edge scheduleInstance(SynchronousComponentInstance instance, Edge previousLastEdge) {
		var Edge lastEdge = previousLastEdge
		val instanceType = instance.type
		val parentComposite = instance.eContainer
		if (instanceType instanceof SynchronousCompositeComponent && parentComposite instanceof CascadeCompositeComponent) {
			val synchronousInstanceType = instanceType as SynchronousCompositeComponent
			lastEdge = synchronousInstanceType.swapQueuesOfContainedSimpleInstances(lastEdge)
		}
		if (instanceType instanceof AbstractSynchronousCompositeComponent) {
			for (containedInstance : instanceType.instancesToBeScheduled) {
				lastEdge = containedInstance.scheduleInstance(lastEdge)
			}
		}
		else if (instanceType instanceof StatechartDefinition) {
			return instance.scheduleStatechart(lastEdge)
		}
		return lastEdge
	}
	
	/**
	 * Creates the scheduling of the given statechart instance, that is, the runCycle sync and 
	 * the reset of event queue in case of cascade instances.
	 */
	private def Edge scheduleStatechart(SynchronousComponentInstance instance, Edge previousLastEdge) {
		var Collection<Edge> lastEdges = #[previousLastEdge]
		val statechart = instance.type as StatechartDefinition
		val finalizeSyncVar = instance.finalizeSyncVar
		// Syncing the templates with run cycles
		val schedulingOrder = statechart.schedulingOrder
			// Scheduling either top-down or bottom-up
		val levelRegionAssociation = statechart.calculateSubregionLevels
		var List<Integer> regionLevels
		switch (schedulingOrder) {
			case TOP_DOWN: {
				regionLevels = levelRegionAssociation.keySet.sort
			}
			case BOTTOM_UP: {
				regionLevels = levelRegionAssociation.keySet.sort.reverseView
			}
			default: {
				throw new IllegalArgumentException("Not known scheduling order: " + schedulingOrder)
			}
		}
		for (level : regionLevels) {
			for (region: levelRegionAssociation.get(level)) {
				lastEdges = region.createRunCycleEdge(lastEdges, schedulingOrder, instance)
			}
		}
		// When all templates of an instance is synced, a finalize edge is put in the sequence
		val finalizeEdge = createCommittedSyncTarget(lastEdges.head.target,
			finalizeSyncVar.variable.head, "finalize" + instance.name + id++)
		finalizeEdge.source.locationTimeKind = LocationKind.URGENT
		for (lastEdge : lastEdges) {
			lastEdge.target = finalizeEdge.source
		}
		val lastEdge = finalizeEdge
		// If the instance is cascade, the in events have to be cleared
		if (instance.isCascade) {
			for (match : InputInstanceEvents.Matcher.on(engine).getAllMatches(instance, null, null)) {
				lastEdge.createAssignmentExpression(edge_Update, match.event.getIsRaisedVariable(match.port, match.instance), false)
			}
		}
		return lastEdge
	}
	
	private def Map<Integer, List<Region>> calculateSubregionLevels(CompositeElement compositeElement) {
		val levelRegionMap = new HashMap<Integer, List<Region>>
		val levelRegionList = new ArrayList<Region>
		val containedRegion = compositeElement.regions.head
		if (containedRegion === null) {
			return levelRegionMap
		}
		val level = containedRegion.stateNodes.head.levelOfStateNode
		levelRegionMap.put(level, levelRegionList)
		for (region : compositeElement.regions) {
			levelRegionList += region
			for (state : region.stateNodes.filter(State)) {
				val levelRegionSubmap = state.calculateSubregionLevels
				for (key : levelRegionSubmap.keySet) {
					val regionList = levelRegionMap.get(key)
					if (regionList === null) {
						levelRegionMap.put(key, levelRegionSubmap.get(key))
					}
					else {
						regionList += levelRegionSubmap.get(key)
					}
				}
			}
		}
		return levelRegionMap
	}
	
	/**
	 * Returns the instances whose event variables should be swapped at the same time starting from the given composite.
	 */
	private def getSimpleInstancesInSameQueueSwap(SynchronousCompositeComponent composite) {
		return QueueSwapInstancesOfComposite.Matcher.on(engine).getAllValuesOfinstance(composite)
	}
	
	/**
	 * Places the variable swap updates of the given instance to the given edge.
	 */
	private def createQueueSwap(Edge edge, SynchronousComponentInstance instance) {
		for (match : InputInstanceEvents.Matcher.on(engine).getAllMatches(instance, null, null)) {
			// isRaised = toRaise
			edge.createAssignmentExpression(edge_Update, match.event.getIsRaisedVariable(match.port, match.instance),
				 match.event.getToRaiseVariable(match.port, match.instance))			
			// toRaise = false
			edge.createAssignmentExpression(edge_Update, match.event.getToRaiseVariable(match.port, match.instance), false)										
		}
	 }
	
	/**
	 * Inserts a runCycle edge in the Scheduler template for the template of the the given region,
	 * between the given last runCycle edge and the init location.
	 */
	private def Collection<Edge> createRunCycleEdge(Region region, Collection<Edge> lastEdges,
			SchedulingOrder schedulingOrder, ComponentInstance owner) {
		val template = region.allValuesOfTo.filter(Template).filter[it.owner == owner].head
		val syncVar = template.allValuesOfTo.filter(ChannelVariableDeclaration).head
		val runCycleEdge = createCommittedSyncTarget(lastEdges.head.target,
			syncVar.variable.head, "Run" + template.name.toFirstUpper + id++)
		runCycleEdge.source.locationTimeKind = LocationKind.URGENT
		for (lastEdge : lastEdges) {
			lastEdge.target = runCycleEdge.source
		}
		var Collection<Region> regionsToExamine
		switch (schedulingOrder) {
			case TOP_DOWN: {
				regionsToExamine = region.parentRegions
			}
			case BOTTOM_UP: {
				regionsToExamine = region.subregions
			}
			default: {
				throw new IllegalArgumentException("Not known scheduling order: " + schedulingOrder)
			}
		}
		if (!regionsToExamine.empty) {
			val isScheduledVars = regionsToExamine.map[it.allValuesOfTo.filter(Template).head]
									.map[it.allValuesOfTo.filter(DataVariableDeclaration).head]
			val isNotSchedulableGuard = createLogicalExpression(LogicalOperator.OR, 
					isScheduledVars.map[variable | createIdentifierExpression => [
						it.identifier = variable.variable.head
					]
				].toList
			)
			val isSchedulableGuard = createNegationExpression => [
				it.negatedExpression = isNotSchedulableGuard.clone(true, true)
			]
			runCycleEdge.addGuard(isSchedulableGuard, LogicalOperator.AND)
			// If the region is not schedulable
			val elseEdge = runCycleEdge.source.createEdge(runCycleEdge.target) => [
				it.guard = isNotSchedulableGuard
			]
			return #[runCycleEdge, elseEdge]
		}
		else {
			return #[runCycleEdge]
		}		
	}
	
	private def createLogicalExpression(LogicalOperator operator,
			Collection<? extends Expression> expressions) {
		checkState(!expressions.empty)
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
				val oldExpression = logicalExpression.secondExpr
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
	
	/**
	 * Creates the function that copies the state of the toRaise flags to the isRaised flags, and clears the toRaise flags.
	 */
	protected def createClearFunction(SynchronousComponent component) {
		target.globalDeclarations.createChild(declarations_Declaration, functionDeclaration) as FunctionDeclaration => [
			it.createChild(functionDeclaration_Function, declPackage.function) as Function => [
				it.createChild(function_ReturnType, typeReference) as TypeReference => [
					it.referredType = target.void
				]
				it.name = "clearOutEvents" + id++
				it.createChild(function_Block, stmPackage.block) as Block => [
					// Reseting system out-signals
					if (component instanceof AbstractSynchronousCompositeComponent) {
						for (match : TopSyncSystemOutEvents.Matcher.on(engine).getAllMatches(component, null, null, null, null)) {
							it.createChild(block_Statement, stmPackage.expressionStatement) as ExpressionStatement => [	
								// out-signal = false
								it.createAssignmentExpression(expressionStatement_Expression, match.event.getToRaiseVariable(match.port, match.instance), false)										
							]
						} 
					}
					else if (component instanceof StatechartDefinition) {
						it.createChild(block_Statement, stmPackage.expressionStatement) as ExpressionStatement => [	
							for (port : component.ports) {
								for (event : Collections.singletonList(port).getSemanticEvents(EventDirection.OUT)) {
									val instances = SimpleInstances.Matcher.on(engine).getAllValuesOfinstance(component)
									checkState(instances.size == 1, instances)
									val variable = event.getToRaiseVariable(port, instances.head)
									it.createAssignmentExpression(expressionStatement_Expression, variable, false)										
								}
							}
						]
					}
				]
			]
		]
	}
	
	/**
	 * This rule is responsible for transforming the input signals.
	 * It depends on initNTA.
	 */
	val inputEventsRule = createRule(InputInstanceEvents.instance).action [
		if (!it.instance.isCascade) {
			// Cascade components do not have a double event queue
			val toRaise = target.globalDeclarations.createVariable(DataVariablePrefix.NONE, target.bool, it.event.toRaiseName(it.port, it.instance))
			addToTrace(it.event, #{toRaise}, trace)
			addToTrace(it.instance, #{toRaise}, instanceTrace)
			addToTrace(it.port, #{toRaise}, portTrace)
		}
		val isRaised = target.globalDeclarations.createVariable(DataVariablePrefix.NONE, target.bool, it.event.isRaisedName(it.port, it.instance))
		addToTrace(it.event, #{isRaised}, trace)
		// Saving the owner
		addToTrace(it.instance, #{isRaised}, instanceTrace)
		// Saving the port
		addToTrace(it.port, #{isRaised}, portTrace)
	].build	
	
	 /**
	 * This rule is responsible for transforming the output signals led out to the system interface.
	 * It depends on initNTA.
	 */
	val syncSystemOutputEventsRule = createRule(TopSyncSystemOutEvents.instance).action [
		val boolFlag = target.globalDeclarations.createVariable(DataVariablePrefix.NONE, target.bool, it.event.getOutEventName(it.port, it.instance))
		addToTrace(it.event, #{boolFlag}, trace)
		log(Level.INFO, "Information: System out event: " + it.instance.name + "." + boolFlag.variable.head.name)
		// Maybe the owner setting is not needed?
		val instance = it.instance
		addToTrace(instance, #{boolFlag}, instanceTrace)
		// Saving the port
		addToTrace(it.port, #{boolFlag}, portTrace)
	].build
	
	/**
	 * This rule is responsible for connecting the parameters of actions and triggers to the parameters of events.
	 * It depends on initNTA.
	 */
	val eventParametersRule = createRule(ParameteredEvents.instance).action [
		if (it.event.parameterDeclarations.size != 1) {
			throw new IllegalArgumentException("The event has more than one parameters." + it.event)
		}
		// We deal with already transformed instance events
		val uppaalEvents = it.event.allValuesOfTo.filter(DataVariableDeclaration)
							.filter[!it.variable.head.name.startsWith("toRaise")] // So we give one parameter to in events and out events too
		for (uppaalEvent : uppaalEvents) {
			val owner = uppaalEvent.owner
			val port = uppaalEvent.port
			val eventValue = it.param.transformVariable(it.param.type, DataVariablePrefix.NONE,
				uppaalEvent.variable.head.valueOfName)
			// Parameter is now not connected to the Event
			addToTrace(it.param, #{eventValue}, trace) // Connected to the port through name (getValueOfName - bad convention)
			addToTrace(owner, #{eventValue}, instanceTrace)
			addToTrace(port, #{eventValue}, portTrace)
		}
	].build
	
	
	/**
	 * This rule is responsible for transforming the variables.
	 * It depends on initNTA.
	 */
	val variablesRule = createRule(InstanceVariables.instance).action [
		val variable = it.variable.transformVariable(it.variable.type, DataVariablePrefix.NONE,
			it.variable.name + "Of" + instance.name)
		addToTrace(it.instance, #{variable}, instanceTrace)		
		// Traces are created in the transformVariable method
	].build
	
	/**
	 * This rule is responsible for transforming the constants.
	 * It depends on initNTA.
	 */
	val constantsRule = createRule(ConstantDeclarations.instance).action [
		it.constant.transformVariable(it.type, DataVariablePrefix.CONST, 
			it.constant.name + "Of" + (it.constant.eContainer as Package).name)
		// Traces are created in the createVariable method
	].build
	
	// Type references, such as enums
	private def dispatch DataVariableDeclaration transformVariable(Declaration variable,
			hu.bme.mit.gamma.expression.model.TypeDeclaration type, DataVariablePrefix prefix, String name) {
		val declaredType = type.type
		return variable.transformVariable(declaredType, prefix, name)	
	}
	
	private def dispatch DataVariableDeclaration transformVariable(Declaration variable,
			hu.bme.mit.gamma.expression.model.TypeReference type, DataVariablePrefix prefix, String name) {
		val referredType = type.reference
		return variable.transformVariable(referredType, prefix, name)	
	}
	
	private def dispatch DataVariableDeclaration transformVariable(Declaration variable,
			EnumerationTypeDefinition type, DataVariablePrefix prefix, String name) {
		val uppaalVar = target.globalDeclarations.createChild(declarations_Declaration, dataVariableDeclaration) as DataVariableDeclaration  => [
			it.prefix = prefix
		]
		uppaalVar.createIntTypeWithRangeAndVariable(
			createLiteralExpression => [it.text = "0"],
			createLiteralExpression => [it.text = (type.literals.size - 1).toString],
			name
		)
		// Creating the trace
		addToTrace(variable, #{uppaalVar}, trace)
		return uppaalVar	
	}
	
	// Constant, variable and parameter declarations
	private def dispatch DataVariableDeclaration transformVariable(Declaration variable, IntegerTypeDefinition type,
			DataVariablePrefix prefix, String name) {
		val uppaalVar = createVariable(target.globalDeclarations, prefix, target.int, name)
		addToTrace(variable, #{uppaalVar}, trace)	
		return uppaalVar	 
	}
	
	private def dispatch DataVariableDeclaration transformVariable(Declaration variable, BooleanTypeDefinition type,
			DataVariablePrefix prefix, String name) {
		val uppaalVar = createVariable(target.globalDeclarations, prefix, target.bool, name)
		addToTrace(variable, #{uppaalVar}, trace)
		return uppaalVar
	}
	
	private def dispatch DataVariableDeclaration transformVariable(Declaration variable, Type type,
			DataVariablePrefix prefix, String name) {
		throw new IllegalArgumentException("Not transformable variable type: " + type + "!")
	}
	
	private def createIntTypeWithRangeAndVariable(VariableContainer container, Expression lowerBound,
			Expression upperBound, String name) {		
		container.createChild(variableContainer_TypeDefinition, rangeTypeSpecification) as RangeTypeSpecification => [
			it.createChild(rangeTypeSpecification_Bounds, integerBounds) as IntegerBounds => [
				it.lowerBound = lowerBound
				it.upperBound = upperBound
			]
		]
		// Creating variables for all statechart instances
		container.createChild(variableContainer_Variable, declPackage.variable) as Variable => [
			it.container = container
			it.name = name
		]
	}
	
	/**
	 * This rule is responsible for transforming the initializations of declarations.
	 * It depends on variablesRule and constantsRule.
	 */
	val declarationInitRule = createRule(DeclarationInitializations.instance).action [
		val initExpression = it.initValue
		for (uDeclaration : it.declaration.allValuesOfTo.filter(DataVariableDeclaration)) {
			var ComponentInstance owner = null
			if (uDeclaration.prefix != DataVariablePrefix.CONST) {
				owner = uDeclaration.owner
			}
			val finalOwner = owner 
			uDeclaration.variable.head.createChild(variable_Initializer, expressionInitializer) as ExpressionInitializer => [
				it.transform(expressionInitializer_Expression, initExpression, finalOwner)
			]		
		}
		// Traces are created in the transformVariable method
	].build
	
	private def transformTopComponentArguments() {
		for (var i = 0; i < topComponentArguments.size; i++) {
			val parameter = component.parameterDeclarations.get(i)
			val argument = topComponentArguments.get(i)
			val initializer = createExpressionInitializer => [
				it.transform(expressionInitializer_Expression, argument, null /*No instance associated*/)
			]
			// The initialization is created, variable has to be created
			val uppaalVariable = parameter.transformVariable(parameter.type, DataVariablePrefix.CONST,
				parameter.name + "Of" + component.name)
			uppaalVariable.variable.head.initializer = initializer
			// Traces are created in the createVariable method
		}
	}
	
	/**
	 * This rule is responsible for transforming the bound parameters.
	 * It depends on initNTA.
	 */
	val parametersRule = createRule(ParameterizedInstances.instance).action [
		val instance = it.instance
		val parameters = instance.derivedType.parameterDeclarations
		val arguments = instance.arguments
		checkState(parameters.size == arguments.size)
		for (var i = 0; i < parameters.size; i++) {
			val parameter = parameters.get(i)
			val argument = arguments.get(i)
			try {
				/* Trying to create the initialization based on the argument
					(succeeds if all referred parameters are already mapped) */
				val initializer = createExpressionInitializer => [
					it.transform(expressionInitializer_Expression, argument, instance)
				]
				// The initialization is created, variable has to be created
				val uppaalVariable = parameter.transformVariable(parameter.type, DataVariablePrefix.CONST,
					parameter.name + "Of" + instance.name)
				uppaalVariable.variable.head.initializer = initializer
			} catch (Exception exception) {
				// An argument refers to a not yet mapped parameter
				// Waiting for next turn
			}
		}
		// Traces are created in the createVariable method
	].build
	
	private def areAllParametersTransformed() {
		return ParameterizedInstances.Matcher.on(engine).allMatches
				.forall[it.instance.areAllArgumentsTransformed]
	}

	private def areAllArgumentsTransformed(ComponentInstance instance) {
		return instance.derivedType.parameterDeclarations.forall[it.traced]
	}
	
	/**
	 * This rule is responsible for transforming all regions to templates. (Top regions and subregions.)
	 * It depends on initNTA.
	 */
	val regionsRule = createRule(InstanceRegions.instance).action [
		val instance = it.instance
		val name = it.region.regionName
		val template = target.createChild(getNTA_Template, template) as Template => [
			it.name = name + "Of" + instance.name
		]
		// Creating the local declaration container of the template
		val localDeclaration = template.createChild(template_Declarations, localDeclarations) as LocalDeclarations
		if (it.region.subregion) {
			val isActiveVar = localDeclaration.createVariable(DataVariablePrefix.NONE, target.bool, "isActive")
			addToTrace(it.region, #{isActiveVar}, trace)
			addToTrace(instance, #{isActiveVar}, instanceTrace)
		}
		// Creating the runCycle sync var
		val runCycleVar = target.globalDeclarations.createSynchronization(true, false, "runCycle" + template.name.toFirstUpper)
		addToTrace(template, #{runCycleVar}, trace)
		addToTrace(instance, #{runCycleVar}, instanceTrace)
		// Creating the isScheduled sync var
		val isScheduledVar = target.globalDeclarations.createVariable(DataVariablePrefix.NONE, target.bool, "isScheduled" + name + "Of" + instance.name)
		addToTrace(template, #{isScheduledVar}, trace)
		addToTrace(instance, #{isScheduledVar}, instanceTrace)
		// Creating the trace
		addToTrace(it.region, #{template}, trace)
		addToTrace(instance, #{template}, instanceTrace)
	].build
	
	private def List<Region> getParentRegions(Region region) {
		if (region.topRegion) {
			return #[]
		}
		val parentRegion = region.parentRegion
		return (#[parentRegion] + parentRegion.parentRegions).toList
	}
	
	private def List<Region> getSubregions(Region region) {
		val subregions = new ArrayList<Region>
		for (subregion : region.stateNodes.filter(State).map[it.regions].flatten) {
			subregions += subregion
			subregions += subregion.subregions
		}
		return subregions
	}
	
	/**
	 * This rule is responsible for transforming the entry states to committed locations.
	 * If the parent regions is a subregion, a new init location is generated as well.
	 * It depends on regionsRule.
	 */
	val entriesRule = createRule(Entries.instance).action [
		for (template : it.region.getAllValuesOfTo.filter(Template)) {
			val owner = template.owner
			val initLocation = template.createChild(template_Location, location) as Location => [
				it.name = "EntryLocation" + id++
				it.locationTimeKind = LocationKind.COMMITED			
				it.comment = "Entry Location"
			]
			// If it is a subregion, a new location is generated and set initial
			if (it.region.subregion) {
				val generatedInitLocation = template.createChild(template_Location, location) as Location => [
					it.name = "GenInitLocation" + id++
					it.comment = "Generated for the synchronization of subregions."
				]	
				template.init = generatedInitLocation			
				// Putting the generated init next to the committed
				addToTrace(it.entry, #{generatedInitLocation}, trace)				
				addToTrace(owner, #{generatedInitLocation}, instanceTrace)
			}
			else {
				template.init = initLocation
			}
			// Creating the trace
			addToTrace(it.entry, #{initLocation}, trace)
			addToTrace(owner, #{initLocation}, instanceTrace)
		}
	].build
	
	/**
	 * This rule is responsible for transforming all states to committed location -> edge -> locations.
	 * (The edge is there for the subregion synchronization and entry event assignment.)
	 * It depends on regionsRule.
	 */
	val statesRule = createRule(States.instance).action [
		val gammaState = it.state
		for (template : it.region.getAllValuesOfTo.filter(Template)) {
			val owner = template.owner
			val stateLocation = template.createChild(template_Location, location) as Location => [
				it.name = gammaState.locationName
			]		
			val entryLocation = template.createChild(template_Location, location) as Location => [
				it.name = gammaState.entryLocationNameOfState 
				it.locationTimeKind = LocationKind.COMMITED	
				it.comment = "Pseudo state for subregion synchronization"
			]
			val entryEdge = entryLocation.createEdge(stateLocation)
			entryEdge.comment = "Edge for subregion synchronization"
			// Creating the trace
			addToTrace(gammaState, #{entryLocation, entryEdge, stateLocation}, trace)
			addToTrace(owner, #{entryLocation, entryEdge, stateLocation}, instanceTrace)
		}
	].build
	
	/**
	 * This rule is responsible for transforming all choices to committed locations.
	 * It depends on regionsRule.
	 */
	val choicesRule = createRule(ChoicesAndMerges.instance).action [
		for (template : it.region.getAllValuesOfTo.filter(Template)) {
			val owner = template.owner
			val choiceLocation = template.createChild(template_Location, location) as Location => [
				it.name = "Choice" + id++
				it.locationTimeKind = LocationKind.COMMITED	
				it.comment = "Choice"
			]
			// Creating the trace
			addToTrace(it.pseudoState, #{choiceLocation}, trace)
			addToTrace(owner, #{choiceLocation}, instanceTrace)		
		}
	].build
	
	/**
	 * This rule is responsible for transforming all same region transitions (whose sources and targets are in the same region) to edges.
	 * It depends on all the rules that create nodes.
	 */
	val sameRegionTransitionsRule = createRule(SameRegionTransitions.instance).action [
		for (template : it.region.allValuesOfTo.filter(Template)) {
			val owner = template.owner
			val source = getEdgeSource(it.source).filter(Location).filter[it.parentTemplate == template].head
			val target = getEdgeTarget(it.target).filter(Location).filter[it.parentTemplate == template].head
			val edge = source.createEdge(target)
			// Updating the scheduling variable
			val isScheduledVar = template.allValuesOfTo.filter(DataVariableDeclaration).head
			edge.createAssignmentExpression(edge_Update, isScheduledVar, true)
			// Creating the trace
			addToTrace(it.transition, #{edge}, trace)		
			addToTrace(owner, #{edge}, instanceTrace)		
			// For test generation (after adding owner)
			edge.generateTransitionId
		}
	].build
	
	private def generateTransitionId(Edge edge) {
		val owner = edge.owner as SynchronousComponentInstance
		// testedComponentsForTransitions stores the instances to which tests need to be generated
		if (testedComponentsForTransitions.exists[it.contains(owner)]) {
			edge.createAssignmentExpression(edge_Update, transitionIdVar,
				createLiteralExpression => [it.text = (transitionId++).toString]
			)
		}
	}
	
	/**
	 * This rule is responsible for transforming transitions whose targets are in a lower abstraction level (lower region)
	 * than its source.
	 */
	val toLowerRegionTransitionsRule = createRule(ToLowerInstanceTransitions.instance).action [		
		val syncVar = target.globalDeclarations.createSynchronization(true, false, acrossRegionSyncNamePrefix + id++)
		it.transition.toLowerTransitionRule(it.source, it.target, new HashSet<Region>(), syncVar, it.target.levelOfStateNode, it.instance)		
	].build
	
	/**
	 * Responsible for transforming a transition whose target is in a lower abstraction level (lower region)
	 * than its source.
	 */
	private def void toLowerTransitionRule(Transition transition, StateNode tsource, StateNode ttarget, Set<Region> visitedRegions, 
			ChannelVariableDeclaration syncVar, int lastLevel, SynchronousComponentInstance owner) {
		// Going back to top level
		if (tsource.eContainer != ttarget.eContainer) {
			visitedRegions.add(ttarget.eContainer as Region)
			transition.toLowerTransitionRule(tsource, ttarget.eContainer.eContainer as StateNode, visitedRegions, syncVar, lastLevel, owner)
		}
		// On top level
		if (tsource.eContainer == ttarget.eContainer) {
			val targetLoc = ttarget.allValuesOfTo.filter(Location).filter[it.locationTimeKind == LocationKind.NORMAL].filter[it.owner == owner].head 
			val sourceLoc = tsource.allValuesOfTo.filter(Location).filter[it.locationTimeKind == LocationKind.NORMAL].filter[it.owner == owner].head
			val toLowerEdge = sourceLoc.createEdge(targetLoc)		
			// Updating the scheduling variable upon firing
			val isScheduledVar = toLowerEdge.parentTemplate.allValuesOfTo.filter(DataVariableDeclaration).head
			toLowerEdge.createAssignmentExpression(edge_Update, isScheduledVar, true)
			addToTrace(transition, #{toLowerEdge}, trace)
			addToTrace(owner, #{toLowerEdge}, instanceTrace)
			// For test generation (after adding owner)
			toLowerEdge.generateTransitionId
			// Creating the sync edge
			val syncEdge = createCommittedSyncTarget(targetLoc, syncVar.variable.head, "AcrossEntry" + id++)
			toLowerEdge.setTarget(syncEdge.source)
			// Entry events must NOT be done here as they have to be after exit events and regular assignments!	
			// All the orthogonal regions except for the visited one have to be set to the right state
			(ttarget as State).regions.setSubregions(visitedRegions, syncVar, true, owner)			
		}
		else {
			val region = ttarget.eContainer as Region
			var Location targetLoc 
			// If it is an intermediate region, the normal location is the target
			if (lastLevel != ttarget.levelOfStateNode) {
				targetLoc = ttarget.allValuesOfTo.filter(Location).filter[it.locationTimeKind == LocationKind.NORMAL].filter[it.owner == owner].head
				// The orthogonal regions of the composite states have to be activated
				if (ttarget.composite) {			
					(ttarget as State).regions.setSubregions(visitedRegions, syncVar, true, owner)
				}
			}
			// On the last level the ordinary target location of the state is the target
			else {
				targetLoc = ttarget.edgeTarget.filter[it.owner == owner].head
			}
			val template = ttarget.eContainer.allValuesOfTo.filter(Template).filter[it.owner == owner].head		
			val locations = new HashSet<Location>(template.location) // To avoid ConcurrentModification
			for (location : locations.filter[it.locationTimeKind != LocationKind.COMMITED]) {				
				// Creating a sync edge and placing a synchronization onto it
				val activationEdge = location.createEdgeWithSync(targetLoc, syncVar.variable.head, SynchronizationKind.RECEIVE)
				// Creating an update so it activates the template
				activationEdge.setTemplateActivation(region, true)
				// If this is not the last level, all the entry events have to be created
				if (lastLevel != ttarget.levelOfStateNode) {
					activationEdge.setEntryEvents(ttarget as State, owner)
				}
			}
		}
	}
	
	/**
	 * Responsible for placing entry events onto edges that go lower templates.
	 * Depends on assignmentActionsRule.
	 */
	val toLowerRegionEntryEventTransitionsRule = createRule(ToLowerInstanceTransitions.instance).action [		
		transition.toLowerTransitionRuleEntryEvent(it.source, it.target, it.instance)
	].build
	
	private def void toLowerTransitionRuleEntryEvent(Transition transition, StateNode tsource, StateNode ttarget, SynchronousComponentInstance owner) {
		// Going back to top level
		if (tsource.eContainer != ttarget.eContainer) {
			transition.toLowerTransitionRuleEntryEvent(tsource, ttarget.eContainer.eContainer as StateNode, owner)
		}
		// On top level
		if (tsource.eContainer == ttarget.eContainer) {
			for (toLowerEdge : transition.allValuesOfTo.filter(Edge).filter[it.owner == owner]) {
				toLowerEdge.setEntryEvents(ttarget as State, owner)	
			}					
		}		
	}
	
	/**
	 * Responsible for putting all the entry updates and signal raising of a given state onto the given edge.
	 */
	private def setEntryEvents(Edge edge, State state, SynchronousComponentInstance owner) {
		// Entry event updates
		for (assignmentAction : state.entryActions.filter(AssignmentStatement)) {
			edge.transformAssignmentAction(edge_Update, assignmentAction, owner)
		}
		// Entry event event raising
		for (match : RaiseInstanceEventStateEntryActions.Matcher.on(engine).getAllMatches(state, null, owner, null, null, null, null)) {
			edge.createEventRaising(match.inPort, match.raisedEvent, match.inInstance, match.entryAction)
		}
		for (match : RaiseTopSystemEventStateEntryActions.Matcher.on(engine).getAllMatches(null, state, owner, null, null, null)) {
			edge.createEventRaising(match.outPort, match.raisedEvent, match.instance, match.entryAction)
		}
	}
	
	/**
	 * Responsible for enabling/disabling the regions of the given state except for the regions given in visitedRegions.
	 */
	private def setSubregions(Collection<Region> regions, Set<Region> visitedRegions, ChannelVariableDeclaration syncVar, boolean enter, SynchronousComponentInstance owner) {
		val regionsToSet = new HashSet<Region>(regions)
		regionsToSet.removeAll(visitedRegions)
		regionsToSet.forEach[it.synchronizeSubregion(syncVar, enter, owner)]	
	}
	
	/**
	 * Returns the number of parent regions of a stateNode.
	 */
	private def int getLevelOfStateNode(StateNode stateNode) {
		if ((stateNode.eContainer as Region).isTopRegion) {
			return 1
		}
		else {
			getLevelOfStateNode(stateNode.eContainer.eContainer as State) + 1
		}
	}
	
	/**
	 * This rule is responsible for transforming transitions whose targets are in a higher abstraction level (higher region)
	 * than its source.
	 */
	val toHigherRegionTransitionsRule = createRule(ToHigherInstanceTransitions.instance).action [		
		val syncVar = target.globalDeclarations.createSynchronization(true, false, acrossRegionSyncNamePrefix + id++)
		it.transition.toHigherTransitionRule(it.source, it.target, new HashSet<Region>(), syncVar, it.source.levelOfStateNode, it.instance)
	].build
	
	/**
	 * This rule is responsible for transforming a transition whose targets are in a higher abstraction level (higher region)
	 * than its source.
	 */
	private def void toHigherTransitionRule(Transition transition, StateNode tsource, StateNode ttarget, Set<Region> visitedRegions, ChannelVariableDeclaration syncVar, int lastLevel, SynchronousComponentInstance owner) {
		// Lowest level
		if (tsource.levelOfStateNode == lastLevel) {
			val region = tsource.eContainer as Region
			visitedRegions.add(region)
			val sourceLoc = tsource.allValuesOfTo.filter(Location).filter[it.locationTimeKind == LocationKind.NORMAL].filter[it.owner == owner].head	
			// Creating a the transition equivalent edge
			val toHigherEdge = sourceLoc.createEdge(sourceLoc)		
			// Setting isScheduled variable to true upon firing 
			val isScheduledVar = toHigherEdge.parentTemplate.allValuesOfTo.filter(DataVariableDeclaration).head
			toHigherEdge.createAssignmentExpression(edge_Update, isScheduledVar, true)
			addToTrace(transition, #{toHigherEdge}, trace)
			addToTrace(owner, #{toHigherEdge}, instanceTrace)
			// For test generation (after adding owner)
			toHigherEdge.generateTransitionId
			// Getting the target of the deactivating edge
			val targetLoc = region.getDeactivatingEdgeTarget(sourceLoc)
			// This plus sync edge will contain the deactivation (so triggers can be put onto the original one)
			val syncEdge = createCommittedSyncTarget(targetLoc, syncVar.variable.head, "AcrossEntry" + id++)
			toHigherEdge.target = syncEdge.source			
			syncEdge.setTemplateActivation(region, false)
			// No need to set the exit events, since exitAssignmentActionsOfStatesRule and exitEventRaisingActionsOfStatesRule do that
			transition.toHigherTransitionRule(tsource.eContainer.eContainer as State, ttarget, visitedRegions, syncVar, lastLevel, owner)			
		}
		// Highest level
		else if (tsource.levelOfStateNode == ttarget.levelOfStateNode) {
			visitedRegions.add(tsource.eContainer as Region)
			val sourceLoc = tsource.allValuesOfTo.filter(Location).filter[it.locationTimeKind == LocationKind.NORMAL].filter[it.owner == owner].head
			val targetLoc = getEdgeTarget(ttarget).filter[it.owner == owner].head
			// Sync edge on the highest level with exit events
			val syncEdge = createEdgeWithSync(sourceLoc, targetLoc, syncVar.variable.head, SynchronizationKind.RECEIVE)			
			syncEdge.setExitEvents(tsource as State, owner)
			// Setting the regular assignments of the transition, so it takes place after the exit events
			for (assignment : transition.effects.filter(AssignmentStatement)) {
				syncEdge.transformAssignmentAction(edge_Update, assignment, owner)				
			}	
			// The event raising of the transition is done here, though the order of event raising does not really matter in this transformer
			for (raiseEventAction : transition.effects.filter(RaiseEventAction)) {
				for (match : RaiseInstanceEventOfTransitions.Matcher.on(engine).getAllMatches(transition, raiseEventAction, owner, raiseEventAction.port, null, null, null)) {
					syncEdge.createEventRaising(match.inPort, match.raisedEvent, match.inInstance, match.eventRaiseAction)
				}
			}		
			val allSubRegions = AllSubregionsOfCompositeStates.Matcher.on(engine).getAllValuesOfregion(tsource as State)
			allSubRegions.setSubregions(visitedRegions, syncVar, false, owner)
			// This template is not deactivated since it is the highest level			
		}
		// Intermediate levels
		else {	
			visitedRegions.add(tsource.eContainer as Region)		
			val sourceLoc = tsource.allValuesOfTo.filter(Location).filter[it.locationTimeKind == LocationKind.NORMAL].filter[it.owner == owner].head
			// Loop edge with exit events and deactivation
			val loopEdge = createEdgeWithSync(sourceLoc, sourceLoc, syncVar.variable.head, SynchronizationKind.RECEIVE)
			loopEdge.setExitEvents(tsource as State, owner)
			loopEdge.setTemplateActivation(tsource.eContainer as Region, false)
			transition.toHigherTransitionRule(tsource.eContainer.eContainer as State, ttarget, visitedRegions, syncVar, lastLevel, owner)
		}
	}
	
	/**
	 * Places an "isActive" guard onto the given edge based on the given variable.
	 */
	private def createIsActiveGuard(Edge edge) {
		val parentTemplate = edge.parentTemplate		
		val region = parentTemplate.allValuesOfFrom.filter(Region).head
		// If the region is a top region, no isActive guard is needed
		if (region.isTopRegion) {
			return
		}
		val owner = edge.owner
		val isActiveVar = region.allValuesOfTo.filter(DataVariableDeclaration)
								.filter[it.localVariableToTemplate == edge.parentTemplate && it.owner == owner].head
		edge.addGuard(isActiveVar, LogicalOperator.AND)
	}
	
	/**
	 * This rule is responsible for creating synchronizations in the subregions of composite states
	 * to make sure they get to the proper state at each entry.
	 * It depends on all the rules that create nodes (including timeTriggersRule).
	 */
	val compositeStateEntryRule = createRule(CompositeStates.instance).action [
		for (entryEdge : it.compositeState.allValuesOfTo.filter(Edge)) {
			val owner = entryEdge.owner as SynchronousComponentInstance
			// Creating the synchronization variable
			val syncVar = target.globalDeclarations.createSynchronization(true, false, it.compositeState.entrySyncNameOfCompositeState)			
			addToTrace(owner, #{syncVar}, instanceTrace)	
			// Placing it on the synchronization entry edge
			entryEdge.setSynchronization(syncVar.variable.head, SynchronizationKind.SEND)
			// Synchronizing each template equivalent of the regions of the composite state
			for (subregion : it.compositeState.regions) {
				subregion.synchronizeSubregion(syncVar, true, owner)
			}
			// Creating the trace
			addToTrace(it.compositeState, #{syncVar}, trace)
		}
	].build
	
	/**
	 * Responsible for synchronizing the given subregion (? sync, edges from normal locations to the init/self location).
	 */
	private def synchronizeSubregion(Region subregion, ChannelVariableDeclaration syncVar, boolean enter, SynchronousComponentInstance owner) {
		for (template : subregion.getAllValuesOfTo.filter(Template).filter[it.owner == owner]) {
			// There must be an edge from each location to the entry (no history) or to itself (history)
			val normalLocations = new HashSet<Location>(template.location) // Against concurrentModException			
			for (location : normalLocations.filter[it.locationTimeKind != LocationKind.COMMITED]) {
				createSynchronizationEdge(subregion, location, owner, syncVar, enter)				
			}		
		}
	}
	
	/**
	 * Responsible for creating a synchronization edge that sets the template to the proper state (location and isActive variable).
	 */
	private def createSynchronizationEdge(Region subregion, Location source, SynchronousComponentInstance owner, ChannelVariableDeclaration syncVar, boolean enter) {
		// If the subregion has a history, the target must be different
		var Location target
		// Target depends on entry/exit and if and entry, has history or not
		if (enter) {
			if (subregion.hasHistory) {
				// Target is determined by a dispatch method (because a mapping might have more "outputs")
				target = getEdgeTarget(source.allValuesOfFrom.filter(StateNode).head)
								.filter(Location).filter[it.parentTemplate == source.parentTemplate].head
			}
			// Target is the committed location of the template
			else {
				target = Entries.Matcher.on(engine).getAllValuesOfentry(subregion).filter(EntryState).head.allValuesOfTo
							.filter(Location).filter[it.locationTimeKind == LocationKind.COMMITED].filter[it.parentTemplate == source.parentTemplate].head
			}
		}
		// In case of exit
		else {
			target = subregion.getDeactivatingEdgeTarget(source)
		}
		val realTarget = target
		// Creating an edge with a ? synchronization and an "isActive" update
		val activationEdge = source.createEdge(realTarget)
		// If the state has exit event, it has to placed onto the edge
		if (!enter) {
			if (owner === null) {
				throw new Exception("The given location has no owner: " + location)
			}
			activationEdge.setExitEvents(source.allValuesOfFrom.filter(State).head, owner)
		}
		// Placing a synchronization onto the edge
		activationEdge.setSynchronization(syncVar.variable.head, SynchronizationKind.RECEIVE)
		// Creating an update so it activates/deactivates the template
		activationEdge.setTemplateActivation(subregion, enter)
	}
	
	private def getDeactivatingEdgeTarget(Region region, Location source) {
		// If the region ha history, the target is the source (remembering last active state)
		if (region.hasHistory) {
			return source
		}
		// The target is the inactive location to reduce state space
		else {
			return source.parentTemplate.init
		}
	}
	
	/**
	 * Places the exit actions of the given state onto the given edge. If the given state has no exit action, nothing happens.
	 */
	private def setExitEvents(Edge edge, State state, SynchronousComponentInstance owner) {
		if (state !== null) {
			// Assignment actions
			for (action : state.exitActions.filter(AssignmentStatement)) {
				edge.transformAssignmentAction(edge_Update, action, owner)			
			}		
			// Signal raising actions
			for (match : RaiseInstanceEventStateExitActions.Matcher.on(engine).getAllMatches(state, null, owner, null, null, null, null)) {
				edge.createEventRaising(match.inPort, match.raisedEvent, match.inInstance, match.exitAction)
			}
			for (match : RaiseTopSystemEventStateExitActions.Matcher.on(engine).getAllMatches(null, state, owner, null, null, null)) {
				edge.createEventRaising(match.outPort, match.raisedEvent, match.instance, match.exitAction)
			}
		}
	}
	
	/**
	 * Responsible for placing an activation assignment onto the given edge: "isActive = true/false".
	 */
	private def setTemplateActivation(Edge edge, Region subregion, boolean enter) {
		edge.createChild(edge_Update, assignmentExpression) as AssignmentExpression => [
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = subregion.allValuesOfTo.filter(VariableDeclaration).filter[it.localVariableToTemplate == edge.parentTemplate].head.variable.head // Using only one variable in each declaration
			]
			it.operator = AssignmentOperator.EQUAL
			it.createChild(binaryExpression_SecondExpr, literalExpression) as LiteralExpression => [
				it.text = enter.toString
			]
		]
	}	
	
	/**
	 * Returns the template that contains the given variable.
	 */
	private def Template localVariableToTemplate(VariableDeclaration variable) {
		return variable.eContainer.eContainer as Template
	}
	
	/**
	 * This rule is responsible for creating synchronizations in the subregions of composite states and exit transitions
	 * to make sure templates are deactivated at each exit.
	 * It depends on all the rules that create nodes and edges.
	 */
	private def compositeStateExitRule() {
		for (compositeState : OutgoingTransitionsOfCompositeStates.Matcher.on(engine).allValuesOfcompositeState) {
			// Iterating through all the instances that have the mapping of this particular composite state (compositeState)
			// A state may be mapped to more NORMAL locations thanks to timing (timer_id locations), so a set of owners is needed
			for (owner : compositeState.allValuesOfTo.filter(Location).filter[it.locationTimeKind == LocationKind.NORMAL].map[it.owner].toSet) {
				// Creating the synchronization variable
				val syncVar = target.globalDeclarations.createSynchronization(true, false, compositeState.exitSyncNameOfCompositeState) 
				// Synchronizing each template equivalent of the regions of the composite state
				for (subregion : AllSubregionsOfCompositeStates.Matcher.on(engine).getAllValuesOfregion(compositeState)) {
					val template = subregion.getAllValuesOfTo.filter(Template).filter[it.owner == owner].head
					// There must be an edge from each location to itself
					val normalLocations = new HashSet<Location>(template.location)
					for (location : normalLocations.filter[it.locationTimeKind != LocationKind.COMMITED]) {
						createSynchronizationEdge(subregion, location, owner as SynchronousComponentInstance, syncVar, false) 				
					}	
				}
				for (outgoingTransition : OutgoingTransitionsOfCompositeStates.Matcher.on(engine).getAllValuesOfoutgoingTransition(compositeState, null)
																					.filter[it.sourceState.eContainer == it.targetState.eContainer]) {
					val originalExitEdge = outgoingTransition.allValuesOfTo.filter(Edge).filter[it.owner == owner].head
					// Only same region transitions are handled this way
					val originalTarget = originalExitEdge.target
					// Creating a new sync edge with the syncVar above
					val newSyncEdge = originalTarget.createCommittedSyncTarget(syncVar.variable.head, compositeState.exitLocationNameOfCompositeState)
					// Setting the target of the original edge to the recently created committed location
					originalExitEdge.target = newSyncEdge.source
					// Resetting the exit events so these events are executed after the exit events of child states
					if (!compositeState.exitActions.empty) {
						val newExitEventEdge = originalTarget.createEdgeCommittedTarget("NewExitEventUpdateOf" + compositeState.name) => [
							it.update += originalExitEdge.update
						]
						newSyncEdge.target = newExitEventEdge.source
					}
				}
				// Creating the trace
				addToTrace(compositeState, #{syncVar}, trace)
				addToTrace(owner, #{syncVar}, instanceTrace)			
			}
		}			
	}	
	
	/**
	 * This rule is responsible for transforming the event triggers.
	 * It depends on eventsRule and sameRegionTransitionsRule.
	 */
	val eventTriggersRule = createRule(EventTriggersOfTransitions.instance).action [
		for (edge : it.transition.allValuesOfTo.filter(Edge)) {
			checkState(edge.guard === null) // Must this assert be true at all times?
			val owner = edge.owner
			val triggerGuard = it.trigger.transformTrigger(owner)
			if (edge.guard === null) {
				edge.guard = triggerGuard
			}
//			else {
//				edge.guard = channelVar.createLogicalExpression(LogicalOperator.OR, edge.guard)
//			}
			edge.setRunCycle
			// Creating the trace
			addToTrace(it.trigger, #{triggerGuard}, trace)		
		}
	].build
	
	private def dispatch Expression transformTrigger(AnyTrigger trigger, ComponentInstance owner) {
		return owner.derivedType.ports.createLogicalExpressionOfPortInEvents(LogicalOperator.OR, owner)			
	}
	
	private def Expression createLogicalExpressionOfPortInEvents(Collection<Port> ports,
			LogicalOperator operator, ComponentInstance owner) {
		val events = ports.map[#[it].getSemanticEvents(EventDirection.IN)].flatten
		val eventCount = events.size
		if (eventCount == 0) {
			return createLiteralExpression => [
				it.text = "false"
			]
		}
		if (eventCount == 1) {
			val port = ports.head
			val event = events.head
			return createIdentifierExpression => [
				it.identifier = event.getIsRaisedVariable(port, owner).variable.head
			]
		}
		var i = 0
		var orExpression = createLogicalExpression => [
			it.operator = operator
		]
		for (port : ports) {
			for (event : #[port].getSemanticEvents(EventDirection.IN)) {
				if (i == 0) {
					orExpression.firstExpr = createIdentifierExpression => [
						it.identifier = event.getIsRaisedVariable(port, owner).variable.head
					]
				}
				else if (i == 1) {
					orExpression.secondExpr = createIdentifierExpression => [
						it.identifier = event.getIsRaisedVariable(port, owner).variable.head
					]
				}
				else {
					orExpression = orExpression.createLogicalExpression(
						LogicalOperator.OR,
						createIdentifierExpression => [
							it.identifier = event.getIsRaisedVariable(port, owner).variable.head
						]
					)
				}
			}
		}
		return orExpression
	}
	
	private def createLogicalExpression(Expression lhs, LogicalOperator operator,
			Expression rhs) {
		return createLogicalExpression => [
			it.firstExpr = lhs
			it.operator = operator
			it.secondExpr = rhs
		]
	}
	
	private def dispatch Expression transformTrigger(EventTrigger trigger, ComponentInstance owner) {
		return trigger.eventReference.transformEventTrigger(owner)
	}
	
	private def dispatch Expression transformTrigger(BinaryTrigger trigger, ComponentInstance owner) {
		switch (trigger.type) {
			case AND: {
				return createLogicalExpression => [
					it.firstExpr = trigger.leftOperand.transformTrigger(owner)
					it.operator = LogicalOperator.AND
					it.secondExpr = trigger.rightOperand.transformTrigger(owner)
				]
			}
			case EQUAL: {
				return createCompareExpression => [
					it.firstExpr = trigger.leftOperand.transformTrigger(owner)
					it.operator = CompareOperator.EQUAL
					it.secondExpr = trigger.rightOperand.transformTrigger(owner)
				]
			}
			case IMPLY: {
				return createLogicalExpression => [
					it.firstExpr = trigger.leftOperand.transformTrigger(owner)
					it.operator = LogicalOperator.IMPLY
					it.secondExpr = trigger.rightOperand.transformTrigger(owner)
				]
			}
			case OR: {
				return createLogicalExpression => [
					it.firstExpr = trigger.leftOperand.transformTrigger(owner)
					it.operator = LogicalOperator.OR
					it.secondExpr = trigger.rightOperand.transformTrigger(owner)
				]
			}
			case XOR: {
				return createLogicalExpression => [
					it.firstExpr = trigger.leftOperand.transformTrigger(owner)
					it.operator = LogicalOperator.XOR
					it.secondExpr = trigger.rightOperand.transformTrigger(owner)
				]
			}
			default: {
				throw new IllegalArgumentException
			}
		}
	}
	
	private def dispatch Expression transformTrigger(UnaryTrigger trigger, ComponentInstance owner) {
		switch (trigger.getType) {
			case NOT: {
				return createNegationExpression => [
					it.negatedExpression = trigger.operand.transformTrigger(owner)
				]
			}
			default: {
				throw new IllegalArgumentException
			}
		}
	}

	private def dispatch Expression transformEventTrigger(PortEventReference reference, ComponentInstance owner) {
		val port = reference.port
		val event = reference.event
		return createIdentifierExpression => [
			it.identifier = event.getIsRaisedVariable(port, owner).variable.head
		]
	}

	private def dispatch Expression transformEventTrigger(AnyPortEventReference reference, ComponentInstance owner) {
		val port = #[reference.getPort]
		return port.createLogicalExpressionOfPortInEvents(LogicalOperator.OR, owner)
	}
	
	private def dispatch Expression transformEventTrigger(TimeoutEventReference reference, ComponentInstance owner) {
		throw new UnsupportedOperationException("Timeout triggers are not supported in complex triggers, as the
			actual clock value is not known in this context.")
	}

	/**
	 * Places a runCycle synchronization onto the given edge.
	 */
	private def void setRunCycle(Edge edge) {
		val parentTemplate = edge.parentTemplate
		val runCycleVar = parentTemplate.allValuesOfTo.filter(ChannelVariableDeclaration).head // Only one channel per instance
		if (edge.synchronization !== null && edge.synchronization.channelExpression.identifier == runCycleVar.variable.head) {
			return
		}
		if (edge.synchronization !== null) {
			throw new IllegalArgumentException("The given edge already contains a synchronization: " + edge.source + "\n" + edge.target)
		}
		edge.setSynchronization(runCycleVar.variable.head, SynchronizationKind.RECEIVE)
	}
	
	/**
	 * Creates the Uppaal const representing the given signal.
	 */
	protected def createConstRepresentation(Event event, Port port, AsynchronousAdapter wrapper) {
			val name = event.getConstRepresentationName(port)
			event.createConstRepresentation(port, wrapper, name, constantVal++)
	}
	
	protected def createConstRepresentation(Clock clock, AsynchronousAdapter wrapper) {
			val name = clock.getConstRepresentationName
			clock.createConstRepresentation(wrapper, name, constantVal++)
	}
	
	protected def createConstRepresentation(Event event, Port port, AsynchronousAdapter wrapper, String name, int value) {
		// Only one constant for the same port-event pairs, hence the filtering
		var DataVariableDeclaration constRepr =	target.globalDeclarations.declaration
			.filter(DataVariableDeclaration).filter[it.prefix == DataVariablePrefix.CONST && it.variable.head.name == name].head
		if (constRepr === null) {
			constRepr = target.globalDeclarations.createVariable(DataVariablePrefix.CONST, target.int, name)
			constRepr.variable.head.createChild(variable_Initializer, expressionInitializer) as ExpressionInitializer => [
				it.createChild(expressionInitializer_Expression, literalExpression) as LiteralExpression => [
					it.text = value.toString
				]
			]		
		}
		val repr = constRepr
		traceRoot.createChild(g2UTrace_Traces, eventRepresentation) as EventRepresentation => [
			it.wrapper = wrapper
			it.port = port
			it.event = event
			it.constantRepresentation = repr			
		]		
	}
	
	protected def createConstRepresentation(Clock clock, AsynchronousAdapter wrapper, String name, int value) {
		// Only one constant for the same port-event pairs, hence the filtering
		var DataVariableDeclaration constRepr =	target.globalDeclarations.declaration
			.filter(DataVariableDeclaration).filter[it.prefix == DataVariablePrefix.CONST && it.variable.head.name == name].head
		if (constRepr === null) {
			constRepr = target.globalDeclarations.createVariable(DataVariablePrefix.CONST, target.int, name)
			constRepr.variable.head.createChild(variable_Initializer, expressionInitializer) as ExpressionInitializer => [
				it.createChild(expressionInitializer_Expression, literalExpression) as LiteralExpression => [
					it.text = value.toString
				]
			]
		}
		val repr = constRepr
		traceRoot.createChild(g2UTrace_Traces, clockRepresentation) as ClockRepresentation => [
			it.wrapper = wrapper
			it.clock = clock
			it.constantRepresentation = repr
		]		
	}
	
	/**
	 * This rule is responsible for transforming the timeout event triggers.
	 * It depends on sameRegionTransitionsRule, toLowerTransitionsRule, ToHigherTransitionsRule and triggersRule.
	 */
	val timeTriggersRule = createRule(TimeTriggersOfTransitions.instance).action [
		for (edge : it.transition.allValuesOfTo.filter(Edge)) {
			val owner = edge.owner
			var Edge cloneEdge
			// This rule comes right after the signal trigger rule
			if (edge.guard !== null) {
				// If it contains a guard, it contains a trigger, and the signals are in an OR relationship
				cloneEdge = edge.clone as Edge
				cloneEdge.guard.removeTrace
				cloneEdge.guard = null
				addToTrace(owner, #{cloneEdge}, instanceTrace)
			}
			else {
				cloneEdge = edge
			}
			val template = cloneEdge.parentTemplate
			var clockVar = it.state.stateClock
			// Creating the trace
			addToTrace(it.timeoutDeclaration, #{clockVar}, trace)
			addToTrace(owner, #{clockVar}, instanceTrace)
			val location = cloneEdge.source
			val locInvariant = location.invariant
			val newLoc = template.createChild(template_Location, getLocation) as Location => [
				it.name = clockNamePrefix + (id++)
			]
			// Creating the trace; this is why this rule depends on toLowerTransitionsRule and ToHigherTransitionsRule
			addToTrace(it.state, #{newLoc}, trace)
			addToTrace(owner, #{newLoc}, instanceTrace)			
			val newEdge = location.createEdge(newLoc)
			cloneEdge.source = newLoc
			cloneEdge.setRunCycle
			// Creating the owner trace for the clock edge
			addToTrace(owner, #{newEdge}, instanceTrace)
			// Converting to milliseconds
			val timeValue = it.time.convertToMs
			// Putting the expression onto the location and edge
			if (locInvariant !== null) {
				location.insertLogicalExpression(location_Invariant, CompareOperator.LESS_OR_EQUAL, clockVar, timeValue, locInvariant, it.timeoutEventReference, LogicalOperator.AND)
			}
			else {
				location.insertCompareExpression(location_Invariant, CompareOperator.LESS_OR_EQUAL, clockVar, timeValue, it.timeoutEventReference)
			}
			val originalGuard = cloneEdge.guard
			if (originalGuard !== null) {
				newEdge.insertLogicalExpression(edge_Guard, CompareOperator.GREATER_OR_EQUAL, clockVar, timeValue, originalGuard, it.timeoutEventReference, LogicalOperator.OR)		
			}
			else {
				newEdge.insertCompareExpression(edge_Guard, CompareOperator.GREATER_OR_EQUAL, clockVar, timeValue, it.timeoutEventReference)		
			}		
			// Trace is created in the insertCompareExpression method
			// Adding isStable guard
			newEdge.addGuard(isStableVar, LogicalOperator.AND)
		}	
	].build
	
	protected def getStateClock(State state) {
		val template = state.allValuesOfTo.filter(Location).head.parentTemplate
		// The idea is that a template needs a single clock if every state has a single timer
		val clocks = template.declarations.declaration.filter(ClockVariableDeclaration)
		var ClockVariableDeclaration clockVar
		if (clocks.empty || TimeTriggersOfTransitions.Matcher.on(engine)
				.getAllValuesOftimeoutDeclaration(state, null, null, null, null).size > 1) {
			// If the template has no clocks OR the state has more than one timer, a NEW clock has to be created
			clockVar = template.declarations.createChild(declarations_Declaration, clockVariableDeclaration) as ClockVariableDeclaration
			clockVar.createTypeAndVariable(target.clock, clockNamePrefix + (id++))
			return clockVar
		}
		// The simple common template clock is enough
		return clocks.head
	}
	
	protected def convertToMs(TimeSpecification time) {
		switch (time.unit) {
			case SECOND: {
				val newValue = time.value.multiplyExpression(1000)
				// Maybe strange changing the S to MS in the View model 
				// New expression needs to be contained in a resource because of the expression trace mechanism) 
				// Somehow the tracing works, in a way that the original (1 s) expression is not changed
				time.value = newValue
				time.unit = TimeUnit.MILLISECOND
				newValue
			}
			case MILLISECOND:
				time.value
			default: 
				throw new IllegalArgumentException("Not known unit: " + time.unit)
		}
	}
	
	/**
	 * Transforms Gamma expression "100" into "100 * value" or "timeValue" into "timeValue * value"
	 */
	protected def multiplyExpression(hu.bme.mit.gamma.expression.model.Expression base, long value) {
		val multiplyExp = constrFactory.createMultiplyExpression => [
			it.operands += base
			it.operands += constrFactory.createIntegerLiteralExpression => [
				it.value = BigInteger.valueOf(value)
			]
		]
		return multiplyExp
	}
	
	protected def extendTimedLocations() {
		val timedEdges = EdgesWithClock.Matcher.on(ViatraQueryEngine.on(new EMFScope(target))).allValuesOfedge
		for (timedEdge : timedEdges) {
			val parentTemplate = timedEdge.parentTemplate
			val timedLocation = timedEdge.source
			val outgoingEdges = newHashSet
			outgoingEdges += parentTemplate.edge.filter[it.source === timedLocation && // Edges going out from the original location
				!timedEdges.contains(it) && // No timed edges
				!(it.synchronization !== null && // No entry and exit synch edges, as they are present in the target too
					(it.synchronization.channelExpression.identifier.name.startsWith(Namings.entrySyncNamePrefix) ||
						it.synchronization.channelExpression.identifier.name.startsWith(Namings.exitSyncNamePrefix)
					)
				)
			]
			val targetLocation = timedEdge.target
			for (outgoingEdge : outgoingEdges) {
				// Cloning all outgoing edges of original location
				val clonedOutgoingEdge = outgoingEdge.clone as Edge
				clonedOutgoingEdge.source = targetLocation
				val targetOutgoingEdges = newHashSet
				targetOutgoingEdges += parentTemplate.edge.filter[it.source === targetLocation && it !== clonedOutgoingEdge]
				var isDuplicate = false
				// Deleting the cloned edge if we find out it is a duplicate (maybe it is not needed anymore)
				for (targetOutgoingEdge : targetOutgoingEdges) {
					if (!isDuplicate && clonedOutgoingEdge.helperEquals(targetOutgoingEdge)) {
						clonedOutgoingEdge.delete
						isDuplicate = true
					}
				}
			}
		}
	}
	
	/**
	 * Responsible for creating an AND logical expression containing an already existing expression and a clock expression.
	 */
	private def insertLogicalExpression(EObject container, EReference reference, CompareOperator compOp, ClockVariableDeclaration clockVar,
		hu.bme.mit.gamma.expression.model.Expression timeExpression, Expression originalExpression, TimeoutEventReference timeoutEventReference, LogicalOperator logOp) {
		val andExpression = container.createChild(reference, logicalExpression) as LogicalExpression => [
			it.operator = logOp
			it.secondExpr = originalExpression
		]
		andExpression.insertCompareExpression(binaryExpression_FirstExpr, compOp, clockVar, timeExpression, timeoutEventReference)
	}
	
	/**
	 * Responsible for creating a compare expression that compares the given clock variable to the given expression.
	 */
	private def insertCompareExpression(EObject container, EReference reference, CompareOperator compOp,
		ClockVariableDeclaration clockVar, hu.bme.mit.gamma.expression.model.Expression timeExpression, TimeoutEventReference timeoutEventReference) {		
		val owner = clockVar.owner
		val compExp = container.createChild(reference, compareExpression) as CompareExpression => [
			it.operator = compOp
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = clockVar.variable.head // Always one variable in the container
			]
			it.transform(binaryExpression_SecondExpr, timeExpression, owner)
		]
		addToTrace(timeoutEventReference, #{compExp}, trace)
		addToTrace(owner, #{clockVar}, instanceTrace)
	}
	
	/**
	 * This rule is responsible for transforming the guards.
	 * It depends on sameRegionTransitionsRule, eventTriggersRule, timeTriggersRule and ExpressionTransformer.
	 */
	val guardsRule = createRule(GuardsOfTransitions.instance).action [
		for (edge : it.transition.allValuesOfTo.filter(Edge)) {
			edge.transformGuard(it.guard)		
		}
		// The trace is created by the ExpressionTransformer
	].build
	
	/**
	 * Responsible for placing the Gamma expressions onto the given edge. It is needed to ensure that "isActive"
	 * variables are handled correctly (if they are present).
	 */
	private def transformGuard(Edge edge, hu.bme.mit.gamma.expression.model.Expression guard) {
		// If the reference is not null there are "triggers" on it
		if (edge.guard !== null) {
			// Getting the old reference
			val oldGuard = edge.guard as Expression
			// Creating the new andExpression that will contain the same reference and the regular guard expression
			val andExpression = edge.createChild(edge_Guard, logicalExpression) as LogicalExpression => [
				it.operator = LogicalOperator.AND
				it.secondExpr = oldGuard
			]		
			// This is the transformation of the regular Gamma guard
			andExpression.transform(binaryExpression_FirstExpr, guard, edge.owner)
		}
		// If there is no "isActive" reference, it is transformed regularly
		else {
			edge.transform(edge_Guard, guard, edge.owner)
		}
	}
	
	/**
	 * This rule is responsible for transforming the updates.
	 * It depends on sameRegionTransitionsRule, exitAssignmentActionsOfStatesRule, exitEventRaisingActionsOfStatesRule and ExpressionTransformer.
	 */
	val assignmentActionsRule = createRule(UpdatesOfTransitions.instance).action [
		// No update on ToHigher transitions, it is done in ToHigherTransitionRule
		for (edge : it.transition.allValuesOfTo.filter(Edge)) {
			for (assignmentStatement : transition.effects.filter(AssignmentStatement)) {
				edge.transformAssignmentAction(edge_Update, assignmentStatement, edge.owner)
			}		
		}
		// The trace is created by the ExpressionTransformer
	].build
	
	/**
	 * This rule is responsible for transforming the entry event updates of states.
	 * It depends on sameRegionTransitionsRule, ExpressionTransformer and all the rules that create nodes.
	 */
	val entryAssignmentActionsOfStatesRule = createRule(EntryAssignmentsOfStates.instance).action [
		for (edge : it.state.allValuesOfTo.filter(Edge)) {
			for (assignmentStatement : state.entryActions.filter(AssignmentStatement)) {
				edge.transformAssignmentAction(edge_Update, assignmentStatement, edge.owner)
			}
			// The trace is created by the ExpressionTransformer
		}
	].build
	
	/**
	 * This rule is responsible for transforming the entry event timeout actions of states. 
	 * (Initializing the timer to 0 on entering a state.)
	 * It depends on sameRegionTransitionsRule, ExpressionTransformer and all the rules that create nodes.
	 */
	val entryTimeoutActionsOfStatesRule = createRule(EntryTimeoutActionsOfStates.instance).action [
		for (edge : it.state.allValuesOfTo.filter(Edge)) {
			edge.transformTimeoutAction(edge_Update, it.setTimeoutAction, edge.owner)
			// The trace is created by the ExpressionTransformer
		}
	].build
	
	/**
	 * This rule is responsible for transforming the exit event updates of states.
	 * It depends on sameRegionTransitionsRule, ExpressionTransformer and all the rules that create nodes.
	 */
	val exitAssignmentActionsOfStatesRule = createRule(ExitAssignmentsOfStatesWithTransitions.instance).action [
		for (edge : it.outgoingTransition.allValuesOfTo.filter(Edge)) {
			for (assignmentStatement : it.state.exitActions.filter(AssignmentStatement)) {
				edge.transformAssignmentAction(edge_Update, assignmentStatement, edge.owner)
			}
		}
		// The trace is created by the ExpressionTransformer
		// The loop synchronization edges already have the exit actions
	].build
	
	/**
	 * This rule is responsible for transforming the raise event actions (raising events) of transitions. (No system out-events.)
	 * It depends on sameRegionTransitionsRule and eventsRule.
	 */
	val eventRaisingActionsRule = createRule(RaisingActionsOfTransitions.instance).action [
		// No event raising on ToHigher transitions, it is done in ToHigherTransitionRule
		for (edge : it.transition.allValuesOfTo.filter(Edge)) {
			val owner = edge.owner  as SynchronousComponentInstance
			for (match : RaiseInstanceEventOfTransitions.Matcher.on(engine).getAllMatches(transition, raiseEventAction, owner, raiseEventAction.port, null, null, null)) {
				edge.createEventRaising(match.inPort, match.raisedEvent, match.inInstance, it.raiseEventAction)
			}
		}
	].build
	
	/**
	 * This rule is responsible for transforming the event actions of transitions that raise signals led out to the system interface.
	 * It depends on sameRegionTransitionsRule, toLowerRegionTransitionsRule, toHigherRegionTransitionsRule and systemOutputSignalsRule.
	 */
	val syncSystemEventRaisingActionsRule = createRule(RaiseTopSystemEventOfTransitions.instance).action [
		// Only if the out event is led out to the main composite system
		val owner = it.instance
		for (edge : it.transition.allValuesOfTo.filter(Edge).filter[it.owner == owner]) {
			edge.createEventRaising(it.outPort, it.raisedEvent, it.instance, it.eventRaiseAction)
		}
	].build
	
	/**
	 * This rule is responsible for transforming the raising event actions (raising events) as entry events. (No out-events.)
	 * It depends on sameRegionTransitionsRule, ExpressionTransformer and all the rules that create nodes.
	 */
	val entryEventRaisingActionsRule = createRule(EntryRaisingActionsOfStates.instance).action [
		for (edge : it.state.allValuesOfTo.filter(Edge)) {
			val owner = edge.owner as SynchronousComponentInstance
			for (match : RaiseInstanceEventStateEntryActions.Matcher.on(engine).getAllMatches(it.state, it.raiseEventAction, owner, it.raiseEventAction.port, it.raiseEventAction.event, null, null)) {
				edge.createEventRaising(match.inPort, match.raisedEvent, match.inInstance, it.raiseEventAction)
			}
		}
	].build
	
	/**
	 * This rule is responsible for transforming the out-event actions (raising event) as entry events.
	 * It depends on sameRegionTransitionsRule, ExpressionTransformer and all the rules that create nodes.
	 */
	val syncSystemEventRaisingOfEntryActionsRule = createRule(RaiseTopSystemEventStateEntryActions.instance).action [
		// Only if the out event is led out to the main composite system
		val owner = it.instance as SynchronousComponentInstance
		for (edge : it.state.allValuesOfTo.filter(Edge).filter[it.owner == owner]) {
			edge.createEventRaising(it.outPort, it.raisedEvent, it.instance, it.entryAction)
		}
	].build
	
	/**
	 * This rule is responsible for transforming the exit event event raisings of states. (No out-events.)
	 * It depends on sameRegionTransitionsRule, ExpressionTransformer and all the rules that create nodes.
	 */
	val exitEventRaisingActionsOfStatesRule = createRule(ExitRaisingActionsOfStatesWithTransitions.instance).action [
		for (edge : it.outgoingTransition.allValuesOfTo.filter(Edge)) {
			val owner = edge.owner as SynchronousComponentInstance
			for (match : RaiseInstanceEventStateExitActions.Matcher.on(engine).getAllMatches(it.state,
					it.raiseEventAction, owner, it.raiseEventAction.port, it.raiseEventAction.event, null, null)) {
				edge.createEventRaising(match.inPort, match.raisedEvent, match.inInstance, it.raiseEventAction)
			}	
		}		
	].build
	
	/**
	 * This rule is responsible for transforming the out-event actions (raising event) as exit events.
	 * It depends on sameRegionTransitionsRule, ExpressionTransformer and all the rules that create nodes.
	 */
	val exitSystemEventRaisingActionsOfStatesRule = createRule(ExitRaisingActionsOfStatesWithTransitions.instance).action [
		for (edge : it.outgoingTransition.allValuesOfTo.filter(Edge)) {
			val owner = edge.owner  as SynchronousComponentInstance
			for (match : RaiseTopSystemEventStateExitActions.Matcher.on(engine).getAllMatches(null, it.state,
					owner, it.raiseEventAction.port, it.raiseEventAction.event, it.raiseEventAction)) {
				edge.createEventRaising(match.outPort, match.raisedEvent, match.instance, match.exitAction)				
			}	
		}		
	].build
	
	/**
	 * Places an event raising equivalent update on the given edge.
	 */
	private def createEventRaising(Edge edge, Port port, Event toRaiseEvent, ComponentInstance inInstance, RaiseEventAction eventAction) {
		val toRaiseVar = toRaiseEvent.getToRaiseVariable(port, inInstance)
		edge.createAssignmentExpression(edge_Update, toRaiseVar, true)
		val exps = eventAction.arguments
		if (!exps.empty) {
			for (expression : exps) {
				val assignment = edge.createAssignmentExpression(edge_Update, toRaiseEvent.getValueOfVariable(port, inInstance), expression, inInstance)
				addToTrace(eventAction, #{assignment}, expressionTrace)
			}			
		}
	}
	
	/**
	 * Places a message insert in a queue equivalent update on the given edge.
	 */
	private def createQueueInsertion(Edge edge, Port systemPort, Event toRaiseEvent, ComponentInstance inInstance, DataVariableDeclaration variable) {
		val wrapper = inInstance.derivedType as AsynchronousAdapter
		val queue = wrapper.getContainerMessageQueue(systemPort, toRaiseEvent) // In what message queue this event is stored
		val messageQueueTrace = queue.getTrace(inInstance) // Getting the owner
		val constRepresentation = toRaiseEvent.getConstRepresentation(systemPort)
		if (variable === null) {  		
			edge.addPushFunctionUpdate(messageQueueTrace, constRepresentation, createLiteralExpression => [it.text = "0"])
		}
		else {
			edge.addPushFunctionUpdate(messageQueueTrace, constRepresentation, createIdentifierExpression => [it.identifier = variable.variable.head])
		}
	}
	
	/**
	 * Places isActive guards on each transition equivalent edge indicating that a transition can only fire when its template is activated.
	 * It depends on sameRegionTransitionRule, toLowerTransitionTule, toHigherTransitionRule.
	 */
	val isActiveRule = createRule(Transitions.instance).action [
		for (edge : it.transition.allValuesOfTo.filter(Edge)) {
			if (it.region.subregion) {
				edge.createIsActiveGuard
			}
		}
	].build
	
	/**
	 * Places guards on edges that specify the priority of transitions of a particular state.
	 * It depends on all rules that place semantical guards on edges.
	 */
	val transitionPriorityRule = createRule(Transitions.instance).action [
		// Note that the order in which the transitions are returned matters, as the guards of
		// already handled edges can be cloned - ugly (same negated expressions might appear),
		// but not a problem in reality
		val containingStatechart = it.transition.containingStatechart
		if (containingStatechart.transitionPriority != TransitionPriority.OFF) {
			val prioritizedTransitions = it.transition.prioritizedTransitions
			for (edge : it.transition.allValuesOfTo.filter(Edge)) {
				val owner = edge.owner
				for (higherPriorityTransition : prioritizedTransitions) {
					val higherPriorityEdges = higherPriorityTransition.allValuesOfTo.filter(Edge).filter[it.owner == owner]
					for (higherPriorityGuard : higherPriorityEdges.map[it.guard].filterNull) {
						edge.addGuard(
							createNegationExpression => [
								it.negatedExpression = higherPriorityGuard.clone(true, true)
							],
							LogicalOperator.AND
						)
					}
				}
			}
		}
	].build
	
	val transitionTimedTransitionPriorityRule = createRule(Transitions.instance).action [
		// Priorities regarding time trigger guards have to be handled separately due to 
		// the timing location mapping style
		val containingStatechart = it.transition.containingStatechart
		if (containingStatechart.transitionPriority != TransitionPriority.OFF) {
			val prioritizedTransitions = it.transition.prioritizedTransitions
			for (edge : it.transition.allValuesOfTo.filter(Edge)) {
				for (higherPriorityTransition : prioritizedTransitions) {
					val timeMatches = TimeTriggersOfTransitions.Matcher.on(engine).getAllMatches(null, higherPriorityTransition, null, null, null, null)
					if (!timeMatches.isEmpty) {
						val originalGuard = edge.guard
						for (timeMatch : timeMatches) {
							val clockVar = timeMatch.timeoutDeclaration.allValuesOfTo.filter(ClockVariableDeclaration).head
							val timeValue = timeMatch.time.convertToMs
							if (originalGuard !== null) {
								// The negation of "greater or equals" is "less"
								edge.insertLogicalExpression(edge_Guard, CompareOperator.LESS, clockVar,
									timeValue, originalGuard, timeMatch.timeoutEventReference, LogicalOperator.AND)
							}
							else {
								edge.insertCompareExpression(edge_Guard, CompareOperator.LESS, clockVar,
									timeValue, timeMatch.timeoutEventReference)
							}
						}
					}
				}
			}
		}
	].build
	
	private def getPrioritizedTransitions(Transition gammaTransition) {
		val gammaStatechart = gammaTransition.containingStatechart
		val transitionPriority = gammaStatechart.transitionPriority
		val gammaOutgoingTransitions = gammaTransition.sourceState.outgoingTransitions
		val prioritizedTransitions = newLinkedList
		switch (transitionPriority) {
			case OFF: {
				// No operation
			}
			case ORDER_BASED : {
				for (gammaOutgoingTransition : gammaOutgoingTransitions) {
					if (gammaOutgoingTransitions.indexOf(gammaOutgoingTransition) < 
							gammaOutgoingTransitions.indexOf(gammaTransition)) {
						prioritizedTransitions += gammaOutgoingTransition
					}
				}
			}
			case VALUE_BASED : {
				for (gammaOutgoingTransition : gammaOutgoingTransitions) {
					if (gammaOutgoingTransition.priority > gammaTransition.priority) {
						prioritizedTransitions += gammaOutgoingTransition
					}
				}
			}
			default: {
				throw new IllegalArgumentException("Not known priority enum literal: " + transitionPriority)
			}
		}
		return prioritizedTransitions
	}
	
	/**
	 * Places guards (conjunction of the negated expressions of adjacent edges) for the default edges of choices. 
	 */
	val defultChoiceTransitionsRule = createRule(DefaultTransitionsOfChoices.instance).action [
		for (edge : it.defaultTransition.allValuesOfTo.filter(Edge)) {
			val owner = edge.owner
			val otherEdge = it.otherTransition.allValuesOfTo.filter(Edge).filter[it.owner == owner].head
			if (otherEdge.guard === null) {
				throw new IllegalArgumentException("A choice has two default outgoing transitions: " + edge + "\n" + otherEdge)
			}
			edge.addNegatedExpression(otherEdge.guard)
		}
	].build
	
	/**
	 * Creates completion locations before composite state entries to make sure the instance behaves correctly in one cycle.
	 */
	private def void compositeStateEntryCompletion() {
		compositeStateEntryRuleCompletion.fireAllCurrent
		toLowerRegionTransitionCompletion.fireAllCurrent
	}
	
	val compositeStateEntryRuleCompletion = createRule(CompositeStates.instance).action [
		for (commLoc : it.compositeState.allValuesOfTo.filter(Location).filter[it.locationTimeKind == LocationKind.COMMITED]) {
			// Solving the problem: the finalize should take into the deepest state at once
			// From the entry node (an loop edge-history) finalize location should be skipped
			val template = commLoc.parentTemplate
			val finalizeEdge = template.createFinalizeEdge("FinalizeBefore" + it.name.toFirstUpper.replaceAll(" ", ""), commLoc)			
			val incomingEdges = new HashSet<Edge>(template.edge.filter[it.target == commLoc && it != finalizeEdge].toSet)
			for (incomingEdge : incomingEdges) {
				val gammaSource = incomingEdge.source.allValuesOfFrom.head as StateNode
				// If not an entry edge: normal entry, history entry
				if (!(gammaSource.isEntryStateReachable || gammaSource == it.compositeState)) {
					incomingEdge.target = finalizeEdge.source
				}
			}
			// If the finalize location has no incoming edges, it is unnecessary
			if (template.edge.filter[it.target == finalizeEdge.source].empty) {
				template.remove(template_Location, finalizeEdge.source)
				template.remove(template_Edge, finalizeEdge)
			}
		}		
	].build
	
	private def boolean isEntryStateReachable(StateNode node) {
		if (node instanceof EntryState) {
			return true
		}
		if (!(node instanceof PseudoState)) {
			return false
		}
		// Imagine that an entry state and a regular are is targeted to the same choice
		// Then the compositeStateEntryRuleCompletion cannot be executed properly
		var reachedEntry = false
		var unreachableEntry = false
		for (incomingTransition: node.incomingTransitions) {
			val source = incomingTransition.sourceState
			if (source.isEntryStateReachable) {
				reachedEntry = true
			}
			else {
				unreachableEntry = true
			}
		}
		if (reachedEntry && unreachableEntry) {
			throw new IllegalStateException("An entry state and a regular state are targeted to the same choice.")
		}
		return reachedEntry
	}
	
	val toLowerRegionTransitionCompletion = createRule(ToLowerInstanceTransitions.instance).action [
		val owner = it.instance
		// The owner filter is needed as ToLowerInstanceTransitionsMatcher returns each transition for each instance
		for (toLowerEdge : it.transition.allValuesOfTo.filter(Edge).filter[it.owner == owner]) {
			val template = toLowerEdge.parentTemplate
			val finalizeEdge = template.createFinalizeEdge("FinalizeBefore" + it.target.name.toFirstUpper.replaceAll(" ", ""), toLowerEdge.target)			
			toLowerEdge.target = finalizeEdge.source
		}
	].build
	
	/**
	 * Creates the finalizing location and edge of the given target.
	 */
	private def Edge createFinalizeEdge(Template template, String locationName, Location target) {
		val owner = template.owner
		val finalizeSyncVar = owner.finalizeSyncVar			
		val finalizeLoc = template.createChild(template_Location, location) as Location 
		finalizeLoc.name = locationName + (id++)
		finalizeLoc.locationTimeKind = LocationKind.URGENT
		val finalizeEdge = finalizeLoc.createEdge(target)
		finalizeEdge.setSynchronization(finalizeSyncVar.variable.head, SynchronizationKind.RECEIVE)
		return finalizeEdge
	}
	
	/**
	 * Returns the finalize broadcast channel of the given instance.
	 */
	private def getFinalizeSyncVar(ComponentInstance instance) {
		val finalizeSyncVars = instance.allValuesOfTo.filter(ChannelVariableDeclaration)
		if (finalizeSyncVars.size != 1) {
			throw new IllegalArgumentException("The number of the finalizeSyncVars of this instance is not 1: " + finalizeSyncVars)
		}
		return finalizeSyncVars.head
	}
	
	/**
	 * Places the negated form of the given expression onto the given edge.
	 */
	private def addNegatedExpression(Edge edge, Expression expression) {
		val negatedExp = createNegationExpression
		negatedExp.copy(negationExpression_NegatedExpression, expression)
		edge.addGuard(negatedExp, LogicalOperator.AND)
	}
	
	/**
	 * Responsible for creating an assignment expression with the given variable reference and the given expression.
	 */
	private def AssignmentExpression createAssignmentExpression(EObject container, EReference reference, VariableContainer variable, hu.bme.mit.gamma.expression.model.Expression rhs, ComponentInstance owner) {
		val assignmentExpression = container.createChild(reference, assignmentExpression) as AssignmentExpression => [
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = variable.variable.head // Only one variable is expected
			]
			it.operator = AssignmentOperator.EQUAL
			it.transform(binaryExpression_SecondExpr, rhs, owner)
		]
		return assignmentExpression
	}
	private def AssignmentExpression createAssignmentExpression(EObject container, EReference reference, VariableContainer variable, Expression rhs) {
		val assignmentExpression = container.createChild(reference, assignmentExpression) as AssignmentExpression => [
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = variable.variable.head // Only one variable is expected
			]
			it.operator = AssignmentOperator.EQUAL
			it.secondExpr = rhs
		]
		return assignmentExpression
	}
	
	private def instantiateTemplates(Collection<Template> templates) {
		val instationList = target.systemDeclarations.system.createChild(system_InstantiationList, instantiationList) as InstantiationList 
		for (template : templates) {
			instationList.template += template
		}
	}
	
	private def instantiateUninstantiatedTemplates() {
		val instantiatedTemplates = target.systemDeclarations.system.instantiationList.map[it.template].flatten.toList
		instantiateTemplates(target.template.filter[!instantiatedTemplates.contains(it)].toList /* Uninstantiated templates */)
	}
	
	/**
	 * Responsible for simplifying the created Uppaal model where it is possible.
	 */
	private def cleanUp() {
		deleteEntryLocations
//		deleteChoices
	}
	
	/**
	 * Deletes entry locations of simple states without entry actions.
	 */
	private def deleteEntryLocations() {
		// Removing the unnecessary committed locations before the simple state locations
		for (simpleState : SimpleStates.Matcher.on(engine).allValuesOfstate) {
			for (entryEdge : simpleState.allValuesOfTo.filter(Edge)) {
				if (entryEdge.plain) {					
					val template = entryEdge.parentTemplate
					// Retargeting the incoming edges to the target location
					for (edge : template.edge.filter[it.target == entryEdge.source]) {
						edge.target = entryEdge.target
					}
					template.location.remove(entryEdge.source)
					// Removing them from the trace
					entryEdge.source.removeTrace
					entryEdge.delete
				}			
			}
		}
	}
	
	/**
	 * Deletes the choices and their in and outgoing edges, and creates new edges containing the necessary expressions. 
	 */
	private def deleteChoices() {
		val aMap = new HashMap<Edge, Edge>
		// Creating the new edges
		for (choice : EliminatableChoices.Matcher.on(engine).allValuesOfchoice) {
			for (choiceLoc : choice.allValuesOfTo.filter(Location)) {
				val template = choiceLoc.parentTemplate
				val inEdges = new HashSet<Edge>(template.edge.filter[it.target == choiceLoc].toSet)
				val outEdges = new HashSet<Edge>(template.edge.filter[it.source == choiceLoc].toSet)
				for (inEdge : inEdges) {
					for (outEdge : outEdges) {
						val newEdge = inEdge.source.createEdge(outEdge.target)
						inEdge.copyTo(newEdge)
						outEdge.copyTo(newEdge)
						aMap.put(inEdge, newEdge)
						aMap.put(outEdge, newEdge)
					}
				}
			}
		}
		// Deleting the choices and their in and outgoing transitions
		for (choice : EliminatableChoices.Matcher.on(engine).allValuesOfchoice) {
			for (choiceLoc : choice.allValuesOfTo.filter(Location)) {
				val template = choiceLoc.parentTemplate
				val inEdges = new HashSet<Edge>(template.edge.filter[it.target == choiceLoc].toSet)
				val outEdges = new HashSet<Edge>(template.edge.filter[it.source == choiceLoc].toSet)
				for (edge : inEdges + outEdges) {
					for (aTrace : Traces.Matcher.on(traceEngine).getAllValuesOftrace(null, edge)) {
			   			aTrace.remove(trace_To, edge)
			  			aTrace.addTo(trace_To, aMap.get(edge))
			   		}
			   		for (aTrace : InstanceTraces.Matcher.on(traceEngine).getAllValuesOftrace(null, edge)) {
			   			aTrace.remove(instanceTrace_Element, edge)
			   		}
			   		edge.delete
				}
				choiceLoc.removeTrace
				choiceLoc.parentTemplate.location.remove(choiceLoc)
			}
		} 
	}
	
	/**
	 * Creates trace entries posteriorly to make it more complete.
	 */
	private def void extendTrace() {
		clockLocationTraceRule.fireAllCurrent
	}
	
	val clockLocationTraceRule = createRule(EdgesWithClock.instance).action [
		val source = it.edge.source
		val target = it.edge.target
		val state = source.allValuesOfFrom.head
		addToTrace(state, #{target}, trace)
	].build
   
	 /**
	 * Deletes and edge from its template and the trace model.
	 */
	private def delete(Edge edge) {
		val parentTemplate = edge.parentTemplate
		parentTemplate.edge.remove(edge)
		edge.removeTrace 
	}
	
	/**
	 * Copies the synchronization, guard and all the updates from the from edge to the to edge.
	 */
	private def copyTo(Edge from, Edge to) {
		if (from.synchronization !== null && to.synchronization !== null) {
			if (from.synchronization.channelExpression != to.synchronization.channelExpression)
			throw new IllegalArgumentException("The target edge has synchronization: " + to)
		}
		if (from.synchronization !== null) {
			to.copySync(edge_Synchronization, from.synchronization)		
		}
		if (from.guard !== null) {
			if (to.guard === null) {
				to.copy(edge_Guard, from.guard)	
			}
			else {
				val toGuard = to.guard
				to.createChild(edge_Guard, logicalExpression) as LogicalExpression => [
					it.firstExpr = toGuard
					it.operator = LogicalOperator.AND
					it.copy(binaryExpression_SecondExpr, from.guard)	
				]
			}		
		}
		for (update : from.update) {
			to.copy(edge_Update, update)
		}
	}
	
	/**
	 * Returns whether the given edge is plain, i.e. it does not contain any synchronization, guard or update.
	 */
	private def boolean isPlain(Edge edge) {
		return (edge.synchronization === null && edge.guard === null && edge.update.empty)
	}
	
	/**
	 * Responsible for returning a map that contains all templates and their location names in a map.
	 */
	def Map<String, String[]> getTemplateLocationsMap() {
		val templateLocationMap = new HashMap<String, String[]>
		// VIATRA matches cannot be used here, as testedComponentsForStates has different pointers for some reason
		for (instance : testedComponentsForStates) {
			val statechart = instance.type as StatechartDefinition
			val Set<Region> regions = newHashSet
			for (topRegion : statechart.regions) {
				regions += topRegion
				regions += topRegion.subregions
			}
			for (statechartRegion : regions) {
					var array = new ArrayList<String>
					for (state : statechartRegion.stateNodes.filter(State)) {
						array.add(state.locationName)
					}
					templateLocationMap.put(statechartRegion.regionName + "Of" + instance.name, array)
			}
		}
		return templateLocationMap
	}
	
	def getTransitionIdVariableValue() {
		return transitionId
	}
	
	/**
	 * Disposes of the transformer.
	 */
	def dispose() {
		if (transformation !== null) {
			transformation.dispose
		}
		transformation = null
		return
	}
	
	enum Scheduler {FAIR, RANDOM}
	
}
