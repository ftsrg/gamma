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

import hu.bme.mit.gamma.uppaal.composition.transformation.queries.DistinctWrapperInEvents
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.EdgesWithClock
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.EventsIntoMessageQueues
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.InputInstanceEvents
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.InstanceMessageQueues
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.InstanceRegions
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.InstanceVariables
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.ParameteredEvents
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.QueuePriorities
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.QueueSwapInstancesOfComposite
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.QueuesOfClocks
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.QueuesOfEvents
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.RaiseInstanceEventOfTransitions
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.RaiseInstanceEventStateEntryActions
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.RaiseInstanceEventStateExitActions
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.RaiseSystemEventStateExitActions
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.RaiseTopSystemEventOfTransitions
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.RaiseTopSystemEventStateEntryActions
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.RaiseTopSystemEventStateExitActions
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.RegionToSubregion
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.RunOnceClockControl
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.RunOnceEventControl
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.SimpleInstances
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.SimpleWrapperInstances
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.StatechartRegions
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.SyncSystemInEvents
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
import hu.bme.mit.gamma.constraint.model.BooleanTypeDefinition
import hu.bme.mit.gamma.constraint.model.ConstantDeclaration
import hu.bme.mit.gamma.constraint.model.ConstraintModelFactory
import hu.bme.mit.gamma.constraint.model.Declaration
import hu.bme.mit.gamma.constraint.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.constraint.model.Expression
import hu.bme.mit.gamma.constraint.model.FalseExpression
import hu.bme.mit.gamma.constraint.model.IntegerLiteralExpression
import hu.bme.mit.gamma.constraint.model.IntegerTypeDefinition
import hu.bme.mit.gamma.constraint.model.TrueExpression
import hu.bme.mit.gamma.constraint.model.Type
import hu.bme.mit.gamma.statechart.model.AnyPortEventReference
import hu.bme.mit.gamma.statechart.model.AnyTrigger
import hu.bme.mit.gamma.statechart.model.AssignmentAction
import hu.bme.mit.gamma.statechart.model.BinaryTrigger
import hu.bme.mit.gamma.statechart.model.Clock
import hu.bme.mit.gamma.statechart.model.Component
import hu.bme.mit.gamma.statechart.model.EntryState
import hu.bme.mit.gamma.statechart.model.EventTrigger
import hu.bme.mit.gamma.statechart.model.Package
import hu.bme.mit.gamma.statechart.model.Port
import hu.bme.mit.gamma.statechart.model.PortEventReference
import hu.bme.mit.gamma.statechart.model.RaiseEventAction
import hu.bme.mit.gamma.statechart.model.RealizationMode
import hu.bme.mit.gamma.statechart.model.Region
import hu.bme.mit.gamma.statechart.model.State
import hu.bme.mit.gamma.statechart.model.StateNode
import hu.bme.mit.gamma.statechart.model.StatechartDefinition
import hu.bme.mit.gamma.statechart.model.TimeSpecification
import hu.bme.mit.gamma.statechart.model.TimeUnit
import hu.bme.mit.gamma.statechart.model.TimeoutEventReference
import hu.bme.mit.gamma.statechart.model.Transition
import hu.bme.mit.gamma.statechart.model.UnaryTrigger
import hu.bme.mit.gamma.statechart.model.composite.AbstractSynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousComponent
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousComponentInstance
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.CascadeCompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.model.composite.MessageQueue
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponentWrapper
import hu.bme.mit.gamma.statechart.model.composite.SynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.model.interface_.Event
import hu.bme.mit.gamma.statechart.model.interface_.EventDirection
import hu.bme.mit.gamma.statechart.model.interface_.Interface
import hu.bme.mit.gamma.uppaal.transformation.queries.AllSubregionsOfCompositeStates
import hu.bme.mit.gamma.uppaal.transformation.queries.Choices
import hu.bme.mit.gamma.uppaal.transformation.queries.ClockRepresentations
import hu.bme.mit.gamma.uppaal.transformation.queries.CompositeStates
import hu.bme.mit.gamma.uppaal.transformation.queries.ConstantDeclarations
import hu.bme.mit.gamma.uppaal.transformation.queries.DeclarationInitializations
import hu.bme.mit.gamma.uppaal.transformation.queries.DefaultTransitionsOfChoices
import hu.bme.mit.gamma.uppaal.transformation.queries.EliminatableChoices
import hu.bme.mit.gamma.uppaal.transformation.queries.Entries
import hu.bme.mit.gamma.uppaal.transformation.queries.EntryAssignmentsOfStates
import hu.bme.mit.gamma.uppaal.transformation.queries.EntryRaisingActionsOfStates
import hu.bme.mit.gamma.uppaal.transformation.queries.EntryTimeoutActionsOfStates
import hu.bme.mit.gamma.uppaal.transformation.queries.EventRepresentations
import hu.bme.mit.gamma.uppaal.transformation.queries.EventTriggersOfTransitions
import hu.bme.mit.gamma.uppaal.transformation.queries.ExitAssignmentsOfStates
import hu.bme.mit.gamma.uppaal.transformation.queries.ExitAssignmentsOfStatesWithTransitions
import hu.bme.mit.gamma.uppaal.transformation.queries.ExitRaisingActionsOfStatesWithTransitions
import hu.bme.mit.gamma.uppaal.transformation.queries.GuardsOfTransitions
import hu.bme.mit.gamma.uppaal.transformation.queries.InstanceTraces
import hu.bme.mit.gamma.uppaal.transformation.queries.OutgoingTransitionsOfCompositeStates
import hu.bme.mit.gamma.uppaal.transformation.queries.RaisingActionsOfTransitions
import hu.bme.mit.gamma.uppaal.transformation.queries.RegionsWithDeepHistory
import hu.bme.mit.gamma.uppaal.transformation.queries.RegionsWithShallowHistory
import hu.bme.mit.gamma.uppaal.transformation.queries.SameRegionTransitions
import hu.bme.mit.gamma.uppaal.transformation.queries.SimpleStates
import hu.bme.mit.gamma.uppaal.transformation.queries.States
import hu.bme.mit.gamma.uppaal.transformation.queries.Subregions
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
import uppaal.declarations.Declarations
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
import uppaal.templates.Synchronization
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
import hu.bme.mit.gamma.uppaal.transformation.queries.TopRegions

class CompositeToUppaalTransformer {
    // Transformation-related extensions
    protected extension BatchTransformation transformation
    protected extension BatchTransformationStatements statements
    
    // Transformation rule-related extensions
    protected extension BatchTransformationRuleFactory = new BatchTransformationRuleFactory
    protected extension IModelManipulations manipulation
	
	// Logger
	protected extension Logger logger = Logger.getLogger("GammaLogger")
	
	// Engine on the gamma resource 
    protected ViatraQueryEngine engine
     // Engine on the trace resource 
    protected ViatraQueryEngine traceEngine
        
    protected ResourceSet resources
    // The gamma composite system to be transformed
    protected Component component
    // The gamma statechart that contains all ComponentDeclarations with the required instances
    protected Package sourceRoot
    // Root element containing the traces
	protected G2UTrace traceRoot
	// The root element of the Uppaal automaton
	protected NTA target
	// isActive variable
	protected DataVariableDeclaration isStableVar
	
	// Message struct tpyes
	protected DeclaredType messageStructType
	protected StructTypeSpecification messageStructTypeDef
	protected DataVariableDeclaration messageEvent
	protected DataVariableDeclaration messageValue
	
	// Gamma factory for the millisecond multiplication
	protected ConstraintModelFactory constrFactory = ConstraintModelFactory.eINSTANCE
	// UPPAAL packages
    protected extension TraceabilityPackage trPackage = TraceabilityPackage.eINSTANCE
    protected extension UppaalPackage upPackage = UppaalPackage.eINSTANCE
    protected extension DeclarationsPackage declPackage = DeclarationsPackage.eINSTANCE
    protected extension TypesPackage typPackage = TypesPackage.eINSTANCE
    protected extension TemplatesPackage temPackage = TemplatesPackage.eINSTANCE
    protected extension ExpressionsPackage expPackage = ExpressionsPackage.eINSTANCE
    protected extension StatementsPackage stmPackage = StatementsPackage.eINSTANCE
    protected extension SystemPackage sysPackage = SystemPackage.eINSTANCE
    
    protected extension ExpressionsFactory expFact = ExpressionsFactory.eINSTANCE
    protected extension TypesFactory typesFact = TypesFactory.eINSTANCE
	
    // For the generation of pseudo locations
    protected int id = 0
    // For the async event queue constants
    protected int constantVal = 1 // Starting from 1, as 0 means empty
        
    protected extension ExpressionTransformer expTransf
    protected extension ExpressionCopier expCop
    protected extension ExpressionEvaluator expEval

    new(ResourceSet resourceSet, Component component) { 
        this.resources = resourceSet
		this.sourceRoot = component.eContainer as Package
        this.component = component
        this.target = UppaalFactory.eINSTANCE.createNTA
        // Connecting the two models in trace
        this.traceRoot = TraceabilityFactory.eINSTANCE.createG2UTrace => [
        	it.gammaPackage = this.sourceRoot
        	it.nta = this.target
        ]
        // Create EMF scope and EMF IncQuery engine based on the gamma resource
        val scope = new EMFScope(resourceSet)
        engine = ViatraQueryEngine.on(scope);      
        // Create EMF scope and EMF IncQuery engine based on created root element of traces
        val traceScope = new EMFScope(traceRoot)
        traceEngine = ViatraQueryEngine.on(traceScope);   
        createTransformation 
    }
    
    def execute() {
    	initNta
    	createMessageStructType
    	createFinalizeSyncVar
    	createIsStableVar
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
		guardsRule.fireAllCurrent
		// Guards placed onto the time "trigger edge"
		swapGuardsOfTimeTriggerTransitions
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
		defultChoiceTransitionsRule.fireAllCurrent
		isActiveRule.fireAllCurrent
		// Creating urgent locations in front of composite states, so entry is not immediate
		compositeStateEntryCompletion
		// Creating a same level process list, note that it is before the orchestrator template: UPPAAL does not work correctly with priorities
//		instantiateUninstantiatedTemplates
		// New entries to traces, previous adding would cause trouble
		extendTrace
		// Firing the rules for async components 
		eventConstantsRule.fireAllCurrent[component instanceof AsynchronousComponent /*Needed only for async models*/]
		clockConstantsRule.fireAllCurrent[component instanceof AsynchronousComponent /*Needed only for async models*/]
		{topWrapperSyncChannelRule.fireAllCurrent
		instanceWrapperSyncChannelRule.fireAllCurrent}
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
		createNoInnerEventsFunction
		cleanUp
		// The created EMF models are returned
		return new SimpleEntry<NTA, G2UTrace>(target, traceRoot)
    }

    private def createTransformation() {
        //Create VIATRA model manipulations
        this.manipulation = new SimpleModelManipulations(engine)
        //Create VIATRA Batch transformation
        transformation = BatchTransformation.forEngine(engine).build
        //Initialize batch transformation statements
        statements = transformation.transformationStatements
        expTransf = new ExpressionTransformer(this.manipulation, this.traceRoot, this.traceEngine)
        expCop = new ExpressionCopier(this.manipulation, this.traceRoot, this.traceEngine, expTransf) 
        expEval = new ExpressionEvaluator
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
     * Returns whether the given instance is inside a cascade composite component.
     */
    private def isCascade(ComponentInstance instance) {
    	if (instance.derivedType instanceof StatechartDefinition) {
    		// Statecharts are cascade if contained by cascade composite components
    		return instance.eContainer instanceof CascadeCompositeComponent
   		}
   		return instance.derivedType instanceof CascadeCompositeComponent
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
     * Creates a bool variable that shows whether a cycle is in progress or a cycle ended.
     */
    private def createIsStableVar() {		
    	isStableVar = target.globalDeclarations.createVariable(DataVariablePrefix.NONE, target.bool, "isStable")
    	isStableVar.initVar(true)
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
						it.createChild(returnStatement_ReturnExpression, negationExpression) as NegationExpression => [
							it.createChild(negationExpression_NegatedExpression, identifierExpression) as IdentifierExpression => [							
								it.identifier = returnVal.variable.head							
							]
						]
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
	val syncEnvironmentRule = createRule.name("SyncEnvironmentRule").precondition(TopUnwrappedSyncComponents.instance).action [
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
	    		for (expression : expressions) {
	    			val isRaisedVar = match.event.getIsRaisedVariable(match.port, match.instance)	
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
			val oldGuard = edge.guard as uppaal.expressions.Expression
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
    private def addGuard(Edge edge, uppaal.expressions.Expression guard, LogicalOperator operator) {
    	if (edge.guard !== null) {
			// Getting the old reference
			val oldGuard = edge.guard as uppaal.expressions.Expression
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
    				DataVariableDeclaration isRaisedVar, ComponentInstance owner, Expression expression) {
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
    private def hasValue(Set<BigInteger> hasValue, Expression expression) {
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
    
    val eventConstantsRule = createRule.name("EventConstantsRule").precondition(WrapperInEvents.instance).action [
    	it.event.createConstRepresentation(it.port, it.wrapper)
    ].build
    
    val clockConstantsRule = createRule.name("ClockConstantsRule").precondition(QueuesOfClocks.instance).action [
    	it.clock.createConstRepresentation(it.wrapper)
    ].build
    
	val topMessageQueuesRule = createRule.name("TopMessageQueuesRule").precondition(TopMessageQueues.instance).action [
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
	
	val instanceMessageQueuesRule = createRule.name("InstanceMessageQueuesRule").precondition(InstanceMessageQueues.instance).action [
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
	
    val topWrapperEnvironmentRule = createRule.name("TopWrapperEnvironmentRule").precondition(TopWrapperComponents.instance).action [
		// Creating the template
		val initLoc = createTemplateWithInitLoc(it.wrapper.name + "Environment" + id++, "InitLoc")
    	val containedComposite = wrapper.wrappedComponent as AbstractSynchronousCompositeComponent
    	for (match : SyncSystemInEvents.Matcher.on(engine).getAllMatches(containedComposite, null, null, null, null)) {
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
	
	val instanceWrapperEnvironmentRule = createRule.name("InstanceWrapperEnvironmentRule").precondition(TopAsyncCompositeComponents.instance).action [
		// Creating the template
		val initLoc = createTemplateWithInitLoc(it.asyncComposite.name + "Environment" + id++, "InitLoc")
    	// Creating in events
		for (match : TopAsyncSystemInEvents.Matcher.on(engine).getAllMatches(it.asyncComposite, null, null, null, null)) {
			val wrapper = match.instance.type as SynchronousComponentWrapper
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
	
    val topWrapperClocksRule = createRule.name("TopWrapperClocksRule").precondition(TopWrapperComponents.instance).action [
		// Creating the template
		val initLoc = createTemplateWithInitLoc(it.wrapper.name + "Clock" + id++, "InitLoc")
    	// Creating clock events
		wrapper.createClockEvents(initLoc, null /*no owner in this case*/)
	].build
	
    val instanceWrapperClocksRule = createRule.name("InstanceWrapperClockRule").precondition(TopAsyncCompositeComponents.instance).action [
		// Creating the template
		val initLoc = createTemplateWithInitLoc(it.asyncComposite.name + "Clock" + id++, "InitLoc")
    	// Creating clock events
    	for (match : SimpleWrapperInstances.Matcher.on(engine).allMatches) {
			match.wrapper.createClockEvents(initLoc, match.instance)
		}
	].build
	
	protected def createClockEvents(SynchronousComponentWrapper wrapper, Location initLoc, AsynchronousComponentInstance owner) {
    	val clockTemplate = initLoc.parentTemplate
    	for (match : QueuesOfClocks.Matcher.on(engine).getAllMatches(wrapper, null, null)) {
    		val messageQueueTrace = match.queue.getTrace(owner) // Getting the queue trace with respect to the owner
    		// Creating the loop edge
    		val clockEdge = initLoc.createEdge(initLoc)
    		// It can be fired only if the queue is not full
    		clockEdge.addGuard(createNegationExpression => [
    			it.createChild(negationExpression_NegatedExpression, functionCallExpression) as FunctionCallExpression => [
    				it.function = messageQueueTrace.isFullFunction.function
    			]
    		], LogicalOperator.AND)
    		// It can be fired only if template is stable
    		clockEdge.addGuard(isStableVar, LogicalOperator.AND)		
    		// Only if the wrapper/instance is initialized
    		clockEdge.addInitializedGuards
    		// Creating an Uppaal clock var
			val clockVar = clockTemplate.declarations.createChild(declarations_Declaration, clockVariableDeclaration) as ClockVariableDeclaration
			clockVar.createTypeAndVariable(target.clock, match.clock.name + owner.postfix)
			// Creating the trace
			addToTrace(match.clock, #{clockVar}, trace)
			// push....
			clockEdge.createChild(edge_Update, functionCallExpression) as FunctionCallExpression => [
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
			// Transforiming S to MS
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
	
	private def addInitializedGuards(Edge edge) {
		if (component instanceof SynchronousComponentWrapper) {
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
		Expression timeExpression, uppaal.expressions.Expression originalExpression, LogicalOperator logOp) {
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
		ClockVariableDeclaration clockVar, Expression timeExpression) {		
		container.createChild(reference, compareExpression) as CompareExpression => [
			it.operator = compOp	
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = clockVar.variable.head // Always one variable in the container
			]
			it.transform(binaryExpression_SecondExpr, timeExpression, null)		
		]
	}
	
	protected def createEnvironmentEdge(Edge edge, MessageQueueTrace messageQueueTrace,
		DataVariableDeclaration representation, Expression expression, SynchronousComponentInstance instance) {
		// !isFull...
		val isNotFull = createNegationExpression => [
			it.createChild(negationExpression_NegatedExpression, functionCallExpression) as FunctionCallExpression => [
				it.function = messageQueueTrace.isFullFunction.function
			]
		 ]
		edge.addGuard(isNotFull, LogicalOperator.AND)
		// push....
		edge.addPushFunctionUpdate(messageQueueTrace, representation, expression, instance)
	}
	
	protected def FunctionCallExpression addPushFunctionUpdate(Edge edge, MessageQueueTrace messageQueueTrace,
		DataVariableDeclaration representation, Expression expression, SynchronousComponentInstance instance) {
		edge.createChild(edge_Update, functionCallExpression) as FunctionCallExpression => [
			it.function = messageQueueTrace.pushFunction.function
			   	it.createChild(functionCallExpression_Argument, identifierExpression) as IdentifierExpression => [
			   		it.identifier = representation.variable.head
			   	]
			it.transform(functionCallExpression_Argument, expression, instance)
		]
	}
	
	protected def createEnvironmentEdge(Edge edge, MessageQueueTrace messageQueueTrace,
		DataVariableDeclaration representation, uppaal.expressions.Expression expression) {
		// !isFull...
		val isNotFull = createNegationExpression => [
			it.createChild(negationExpression_NegatedExpression, functionCallExpression) as FunctionCallExpression => [
	   			it.function = messageQueueTrace.isFullFunction.function
			]
		 ]
		edge.addGuard(isNotFull, LogicalOperator.AND)
		// push....
		edge.addPushFunctionUpdate(messageQueueTrace, representation, expression)
	}
	
	protected def FunctionCallExpression addPushFunctionUpdate(Edge edge, MessageQueueTrace messageQueueTrace, DataVariableDeclaration representation, uppaal.expressions.Expression expression) {
		edge.createChild(edge_Update, functionCallExpression) as FunctionCallExpression => [
			it.function = messageQueueTrace.pushFunction.function
			it.createChild(functionCallExpression_Argument, identifierExpression) as IdentifierExpression => [
				it.identifier = representation.variable.head
			]
			it.argument += expression
		]
	}
	
	val topWrapperSyncChannelRule = createRule.name("TopWrapperSyncChannelRule").precondition(TopWrapperComponents.instance).action [
		val asyncChannel = target.globalDeclarations.createSynchronization(false, false, it.wrapper.asyncSchedulerChannelName)
		val syncChannel = target.globalDeclarations.createSynchronization(false, false, it.wrapper.syncSchedulerChannelName)
		val isInitializedVar = target.globalDeclarations.createVariable(DataVariablePrefix.NONE, target.bool,  it.wrapper.initializedVariableName)
		addToTrace(it.wrapper, #{asyncChannel, syncChannel, isInitializedVar}, trace)
	].build
	
	val instanceWrapperSyncChannelRule = createRule.name("InstanceWrapperSyncChannelRule").precondition(SimpleWrapperInstances.instance).action [
		val asyncChannel = target.globalDeclarations.createSynchronization(false, false, it.instance.asyncSchedulerChannelName)
		val syncChannel = target.globalDeclarations.createSynchronization(false, false, it.instance.syncSchedulerChannelName)
		val isInitializedVar = target.globalDeclarations.createVariable(DataVariablePrefix.NONE, target.bool,  it.instance.initializedVariableName)
		addToTrace(it.instance, #{asyncChannel, syncChannel, isInitializedVar}, trace) // No instanceTrace as it would be harder to retrieve the elements
	].build
	 
    val topWrapperSchedulerRule = createRule.name("TopWrapperSchedulerRule").precondition(TopWrapperComponents.instance).action [
		val initLoc = createTemplateWithInitLoc(it.wrapper.name + "Scheduler" + id++, "InitLoc")
    	val loopEdge = initLoc.createEdge(initLoc)
    	val asyncSchedulerChannel = wrapper.asyncSchedulerChannel
    	loopEdge.setSynchronization(asyncSchedulerChannel.variable.head, SynchronizationKind.SEND)
		// Adding isStable  guard
		loopEdge.addGuard(isStableVar, LogicalOperator.AND)
    	loopEdge.addInitializedGuards // Only if the wrapper is initialized
	].build
	
	val instanceWrapperSchedulerRule = createRule.name("InstanceWrapperSchedulerRule").precondition(TopAsyncCompositeComponents.instance).action [
		val initLoc = createTemplateWithInitLoc(it.asyncComposite.name + "Scheduler" + id++, "InitLoc")
    	var Edge lastEdge = null
    	for (instance : SimpleWrapperInstances.Matcher.on(engine).allValuesOfinstance) {
//    		lastEdge = lastEdge.createFairScheduler(initLoc, instance)
    		lastEdge = initLoc.createRandomScheduler(instance)
    	}
	].build
    
    private def createFairScheduler(Edge edge, Location initLoc, AsynchronousComponentInstance instance) {
   		// TODO in case of a bad scheduling a deadlock may appear. Maybe the channels should be broadcast in this case?
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

    private def createRandomScheduler(Location initLoc, AsynchronousComponentInstance instance) {
    	val syncVariable = instance.asyncSchedulerChannel.variable.head
    	// Creating the loop edge
    	val loopEdge = initLoc.createEdge(initLoc)
    	loopEdge.setSynchronization(syncVariable, SynchronizationKind.SEND)
    	loopEdge.addInitializedGuards // Only if the instance is initialized
    	return loopEdge
    }
    
    /**
	 * Responsible for creating a wrapper-sync connector template for a single synchronous composite component wrapped by a Wrapper.
	 * Note that it only fires if there are top wrappers.
	 * Depends on no rules.
	 */
	val topWrapperConnectorRule = createRule.name("TopWrapperConnectorRule").precondition(TopWrapperComponents.instance).action [		
		// Creating the template
		val initLoc = createTemplateWithInitLoc(it.wrapper.name + "Connector" + id++, "DefaultLoc")
		val connectorTemplate = initLoc.parentTemplate
    	val asyncChannel = wrapper.asyncSchedulerChannel // The wrapper is scheduled with this channel
    	val syncChannel = wrapper.syncSchedulerChannel // The wrapped sync component is scheduled with this channel
    	val initializedVar = wrapper.initializedVariable // This variable marks the wether the wrapper has been initialized
    	val relayLoc = wrapper.createConnectorEdges(initLoc, asyncChannel, syncChannel, initializedVar, null /*no owner in this case*/)
		// Needed so the entry events and event transmissions are transmitted to the proper queues 
		connectorTemplate.init = relayLoc
	].build
	
	 /**
	 * Responsible for creating a scheduler template for all synchronous composite components wrapped by wrapper instances.
	 * Note that it only fires if there are wrapper instances.
	 * Depends on no rules.
	 */
	val instanceWrapperConnectorRule = createRule.name("AllWrapperConnectorRule").precondition(SimpleWrapperInstances.instance).action [		
		// Creating the template
		val initLoc = createTemplateWithInitLoc(it.wrapper.name + "Connector" + id++, "DefaultLoc")
		val connectorTemplate = initLoc.parentTemplate
    	val asyncChannel = it.instance.asyncSchedulerChannel // The wrapper is scheduled with this channel
    	val syncChannel = it.instance.syncSchedulerChannel // The wrapped sync component is scheduled with this channel
    	val initializedVar = it.instance.initializedVariable // This variable marks the wether the wrapper has been initialized
		val relayLoc = it.wrapper.createConnectorEdges(initLoc, asyncChannel, syncChannel, initializedVar, it.instance)
		// Needed so the entry events and event transmissions are transmitted to the proper queues 
		connectorTemplate.init = relayLoc
	].build
	
	protected def createConnectorEdges(SynchronousComponentWrapper wrapper, Location initLoc, ChannelVariableDeclaration asyncChannel,
			ChannelVariableDeclaration syncChannel, DataVariableDeclaration initializedVar, AsynchronousComponentInstance owner) {
    	val containedComposite = wrapper.wrappedComponent as AbstractSynchronousCompositeComponent
    	val relayLocPair = initLoc.createRelayEdges(containedComposite, syncChannel, initializedVar)
    	val waitingForRelayLoc = relayLocPair.key
    	val relayLoc = relayLocPair.value
    	// Sync composite in events
    	for (match : SyncSystemInEvents.Matcher.on(engine).getAllMatches(containedComposite, null, null, null, null)) {
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
    			.filter[!SyncSystemInEvents.Matcher.on(engine).hasMatch(it.wrapper.wrappedComponent as AbstractSynchronousCompositeComponent, it.port, null, null, it.event)]) {
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
		    edge.createChild(edge_Update, functionCallExpression) as FunctionCallExpression => [
    			it.function = messageQueueTrace.shiftFunction.function
    		]
			// Adding isStable  guard
			edge.addGuard(isStableVar, LogicalOperator.AND)
    	}
    	return relayLoc
	}
	
	protected def void createConnectorEdge(Edge edge, ChannelVariableDeclaration asyncChannel, SynchronousComponentWrapper wrapper,
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
		edge.createChild(edge_Update, functionCallExpression) as FunctionCallExpression => [
		    it.function = messageQueueTrace.shiftFunction.function
		]
	}
	
	protected def createRelayEdges(Location initLoc, AbstractSynchronousCompositeComponent syncComposite,
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
		val originalGuards = new HashSet<uppaal.expressions.Expression>
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
		createCompareExpression => [
			it.firstExpr = messageQueueTrace.peekFunction.messageValueScopeExp(messageEvent.variable.head)
			it.operator = CompareOperator.EQUAL
			it.createChild(binaryExpression_SecondExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = clock.getConstRepresentation().variable.head
			]	
		]
	}
	
	private def messageValueScopeExp(FunctionDeclaration peekFunction, Variable variable) {
		return createScopedIdentifierExpression => [
			it.createChild(scopedIdentifierExpression_Scope, functionCallExpression) as FunctionCallExpression => [
				it.function = peekFunction.function
			]	
		    it.createChild(scopedIdentifierExpression_Identifier, identifierExpression) as IdentifierExpression => [
				it.identifier = variable
			]
	    ]
	}
	
	private def addPriorityGuard(Edge edge, SynchronousComponentWrapper wrapper, MessageQueue higherPirorityQueue, ComponentInstance owner) {
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
	
	private def createDefaultExpression(Edge edge, Collection<? extends uppaal.expressions.Expression> expressions) {
		for (exp : expressions) {
			val negatedExp = createNegationExpression as NegationExpression => [
				it.negatedExpression = exp.clone(true, true)
			]
			edge.addGuard(negatedExp, LogicalOperator.AND)
		}
	}
	
	private def getPostfix(ComponentInstance instance) {
		if (instance === null) {
			return ""
		}
		return "Of" + instance.name
	}
	
	private def getContainerMessageQueue(SynchronousComponentWrapper wrapper, Port port, Event event) {
		val queues = QueuesOfEvents.Matcher.on(engine).getAllValuesOfqueue(wrapper, port, event)
		if (queues.size > 1) {
			log(Level.WARNING, "Warning: more than one message queue " + wrapper.name + "." + port.name + "_" + event.name + ":" + queues)			
		}
		return queues.head
	}
	
	private def getAsyncSchedulerChannelName(SynchronousComponentWrapper wrapper) {
		return "async" + wrapper.name
	}
	
	private def getSyncSchedulerChannelName(SynchronousComponentWrapper wrapper) {
		return "sync" + wrapper.name
	}
	
	private def getInitializedVariableName(SynchronousComponentWrapper wrapper) {
		return "is"  + wrapper.name.toFirstUpper  + "Initialized"
	}
	
	private def getAsyncSchedulerChannelName(AsynchronousComponentInstance instance) {
		return "async" + instance.name
	}
	
	private def getSyncSchedulerChannelName(AsynchronousComponentInstance instance) {
		return "sync" + instance.name
	}
	
	private def getInitializedVariableName(AsynchronousComponentInstance instance) {
		return "is" + instance.name.toFirstUpper + "Initialized"
	}
	
	private def getAsyncSchedulerChannel(SynchronousComponentWrapper wrapper) {
		wrapper.allValuesOfTo.filter(ChannelVariableDeclaration).filter[it.variable.head.name.startsWith(wrapper.asyncSchedulerChannelName)].head
	}
	
	private def getSyncSchedulerChannel(SynchronousComponentWrapper wrapper) {
		wrapper.allValuesOfTo.filter(ChannelVariableDeclaration).filter[it.variable.head.name.startsWith(wrapper.syncSchedulerChannelName)].head		
	}
	
	private def getInitializedVariable(SynchronousComponentWrapper wrapper) {
		wrapper.allValuesOfTo.filter(DataVariableDeclaration).filter[it.variable.head.name.startsWith(wrapper.initializedVariableName)].head		
	}
	
	private def getAsyncSchedulerChannel(AsynchronousComponentInstance instance) {
		instance.allValuesOfTo.filter(ChannelVariableDeclaration).filter[it.variable.head.name.startsWith(instance.asyncSchedulerChannelName)].head
	}
	
	private def getSyncSchedulerChannel(AsynchronousComponentInstance instance) {
		instance.allValuesOfTo.filter(ChannelVariableDeclaration).filter[it.variable.head.name.startsWith(instance.syncSchedulerChannelName)].head		
	}
	
	private def getInitializedVariable(AsynchronousComponentInstance instance) {
		instance.allValuesOfTo.filter(DataVariableDeclaration).filter[it.variable.head.name.startsWith(instance.initializedVariableName)].head		
	}
	
    /**
	 * Responsible for creating a scheduler template for TOP synchronous composite components.
	 * Note that it only fires if there are TOP synchronous composite components.
	 * Depends on all statechart mapping rules.
	 */
	val topSyncOrchestratorRule = createRule.name("TopSyncSchedulerRule").precondition(TopUnwrappedSyncComponents.instance).action [		
		val lastEdge = it.syncComposite.createSchedulerTemplate(null)
		// Creating timing for the orchestrator template
		val initLoc = lastEdge.target
		val maxTimeoutValue = getMaxTimeout
		if (maxTimeoutValue != -1) {
			// Setting the timing in the orchestrator template
			lastEdge.setOrchestratorTiming(maxTimeoutValue.intValue)
		}
		else {
			// If there is no timing, we set the loc to urgent
			initLoc.locationTimeKind = LocationKind.URGENT
		}
	].build
	
	/**
	 * Responsible for creating a scheduler template for a single synchronous composite component wrapped by a Wrapper.
	 * Note that it only fires if there are top wrappers.
	 * Depends on topWrapperSyncChannelRule and all statechart mapping rules.
	 */
	val topWrappedSyncOrchestratorRule = createRule.name("TopWrappedSyncSchedulerRule").precondition(TopWrapperComponents.instance).action [		
		val lastEdge = it.composite.createSchedulerTemplate(it.wrapper.syncSchedulerChannel)
		lastEdge.setSynchronization(it.wrapper.syncSchedulerChannel.variable.head, SynchronizationKind.SEND)
	].build
	
	 /**
	 * Responsible for creating a scheduler template for all synchronous composite components wrapped by wrapper instances.
	 * Note that it only fires if there are wrapper instances.
	 * Depends on allWrapperSyncChannelRule and all statechart mapping rules.
	 */
	val instanceWrapperSyncOrchestratorRule = createRule.name("AllWrappedSyncSchedulerRule").precondition(SimpleWrapperInstances.instance).action [		
		val lastEdge = it.composite.createSchedulerTemplate(it.instance.syncSchedulerChannel)
		lastEdge.setSynchronization(it.instance.syncSchedulerChannel.variable.head, SynchronizationKind.SEND)
		val orchestratorTemplate = lastEdge.parentTemplate
		addToTrace(it.instance, #{orchestratorTemplate}, instanceTrace)
	].build
    
    /**
     * Responsible for creating the scheduler template that schedules the run of the automata.
     * (A series edges with runCycle synchronizations and variable swapping on them.) 
     */
    private def Edge createSchedulerTemplate(AbstractSynchronousCompositeComponent compositeComponent, ChannelVariableDeclaration chan) {
		val initLoc = createTemplateWithInitLoc(compositeComponent.name + "Orchestrator" + id++, "InitLoc")
		val schedulerTemplate = initLoc.parentTemplate
    	val firstEdge = initLoc.createEdge(initLoc)
    	// If a channel has been passed for async-sync synchronoization
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
    	firstEdge.createChild(edge_Update, functionCallExpression) as FunctionCallExpression => [
    		it.function = createClearFunction(compositeComponent).function
    	]
    	firstEdge.createAssignmentExpression(edge_Update, isStableVar, false)
    	lastEdge.createAssignmentExpression(edge_Update, isStableVar, true)
    	return lastEdge
    }
    
    /**
     * Returns the maximum timeout value (specified as an integer literal) in the model.
     */
    private def getMaxTimeout() {
		val defaultValue = -1
		try {
	    	val maxValue = TimeoutValues.Matcher.on(engine).allMatches.map[
	    		if (it.unit == TimeUnit.MILLISECOND) {
		    		it.valueExp.evaluate
		    	} else {
		    		it.valueExp.evaluate * 1000
		    	}    	
	    	].max
    		return maxValue 
    	} catch (NoSuchElementException e) {
    		return defaultValue
    	}
    }
    
    /**
     * Creates a clock for the template of the given edge, sets the clock to "0" on the given edge,
     *  and places an invariant on the target of the edge.
     */
    private def setOrchestratorTiming(Edge lastEdge, int timeout) {
    	val initLoc = lastEdge.target
		val template = lastEdge.parentTemplate
		// Creating the clock
		val clockVar = template.declarations.createChild(declarations_Declaration, clockVariableDeclaration) as ClockVariableDeclaration
		clockVar.createTypeAndVariable(target.clock, "orchestratorTimer" + (id++))
		// Creating the location invariant
		initLoc.createChild(location_Invariant, compareExpression) as CompareExpression => [
			it.operator = CompareOperator.LESS_OR_EQUAL	
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = clockVar.variable.head // Always one variable in the container
			]
			it.createChild(binaryExpression_SecondExpr, literalExpression) as LiteralExpression => [
				it.text = timeout.toString
			]		
		]
		// Creating the clock reset
		lastEdge.createAssignmentExpression(edge_Update, clockVar, createLiteralExpression => [it.text = "0"])
    }
    
    /**
     * Creates the scheduling of the whole network of automata starting out from the given composite component
     */
    private def scheduleTopComposite(AbstractSynchronousCompositeComponent topComposite, Edge previousLastEdge) {
    	var Edge lastEdge = previousLastEdge
    	if (topComposite instanceof SynchronousCompositeComponent) {
			// Creating a new location is needed so the queue swap can be done after finalization of previous template
    		lastEdge = topComposite.swapQueuesOfContainedSimpleInstances(lastEdge)
    	}
    	for (instance : topComposite.instancesToBeScheduled /*Cascades are scheduled in accordance with the execution list*/) {
    		lastEdge = instance.scheduleInstance(lastEdge)
    	}
    	return lastEdge
    }
    
    /**
     * Returns the instances (in order) that should be scheduled in the given AbstractSynchronousCompositeComponent.
     * Note that in casacade commposite an instance might be scheduled multiple times.
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
     * Creates the scheduling of the given staetchart instance, that is, the runCycle sync and 
     * the reset of event queue in case of cascade instances.
     */
    private def Edge scheduleStatechart(SynchronousComponentInstance instance, Edge previousLastEdge) {
    	var Edge lastEdge = previousLastEdge
    	val statechart = instance.type as StatechartDefinition
    	val finalizeSyncVar = instance.finalizeSyncVar
    	// Syncing the templates with run cycles
    	for (topRegion : TopRegions.Matcher.on(engine).getAllValuesOftopRegion(null, statechart, null)) {
    		lastEdge = topRegion.createRunCycleEdges(new ArrayList<Region>, lastEdge, instance)
    	} 
    	// When all templates of an instance is synced, a finalize edge is put in the sequence
    	val finalizeEdge = createCommittedSyncTarget(lastEdge.target, finalizeSyncVar.variable.head, "finalize" + instance.name + id++)
    	finalizeEdge.source.locationTimeKind = LocationKind.URGENT
    	lastEdge.target = finalizeEdge.source
    	lastEdge = finalizeEdge
    	// If the instance is cascade, the in events have to be cleared
    	if (instance.isCascade) {
    		for (match : InputInstanceEvents.Matcher.on(engine).getAllMatches(instance, null, null)) {
    			lastEdge.createAssignmentExpression(edge_Update, match.event.getIsRaisedVariable(match.port, match.instance), false)
    		}
    	}
    	return lastEdge
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
     * Inserts a runCycle edge in the Scheduler template for the template of the the given region, between the given last runCycle edge and the init location.
     */
    private def Edge createRunCycleEdges(Region region, List<Region> nextRegions, Edge lastEdge, ComponentInstance owner) {
    	nextRegions.remove(region)
    	val template = region.allValuesOfTo.filter(Template).filter[it.owner == owner].head
    	val syncVar = template.allValuesOfTo.filter(ChannelVariableDeclaration).head
    	val runCycleEdge = createCommittedSyncTarget(lastEdge.target, syncVar.variable.head, "Run" + template.name.toFirstUpper + id++)
    	runCycleEdge.source.locationTimeKind = LocationKind.URGENT
    	lastEdge.target = runCycleEdge.source
    	var Edge lastLevelEdge = runCycleEdge
    	for (subregion : RegionToSubregion.Matcher.on(engine).getAllValuesOfsubregion(region)) {
    		nextRegions.add(subregion)
    	}    	
    	try {
    		return nextRegions.get(0).createRunCycleEdges(nextRegions, runCycleEdge, owner) 
    	}
    	catch (IndexOutOfBoundsException e) {
    		return lastLevelEdge
    	}     		
    }
    
    /**
     * Creates the function that copies the state of the toRaise flags to the isRaised flags, and clears the toRaise flags.
     */
    protected def createClearFunction(AbstractSynchronousCompositeComponent composite) {
    	target.globalDeclarations.createChild(declarations_Declaration, functionDeclaration) as FunctionDeclaration => [
    		it.createChild(functionDeclaration_Function, declPackage.function) as Function => [
    			it.createChild(function_ReturnType, typeReference) as TypeReference => [
					it.referredType = target.void
				]
				it.name = "clearOutEvents" + id++
				it.createChild(function_Block, stmPackage.block) as Block => [
					// Reseting system out-signals
					for (match : TopSyncSystemOutEvents.Matcher.on(engine).getAllMatches(composite, null, null, null, null)) {
						it.createChild(block_Statement, stmPackage.expressionStatement) as ExpressionStatement => [	
							// out-signal = false
							it.createAssignmentExpression(expressionStatement_Expression, match.event.getToRaiseVariable(match.port, match.instance), false)										
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
	val inputEventsRule = createRule.name("SignalsRule").precondition(InputInstanceEvents.instance).action [
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
	 * Returns all events of the given ports that go in the given direction through the ports.
	 */
	protected def getSemanticEvents(Collection<? extends Port> ports, EventDirection direction) {
   		val events =  new HashSet<Event>
   		for (anInterface : ports.filter[it.interfaceRealization.realizationMode == RealizationMode.PROVIDED].map[it.interfaceRealization.interface]) {
			events.addAll(anInterface.getAllEvents(direction.oppositeDirection))
   		}
   		for (anInterface : ports.filter[it.interfaceRealization.realizationMode == RealizationMode.REQUIRED].map[it.interfaceRealization.interface]) {
			events.addAll(anInterface.getAllEvents(direction))
   		}
   		return events
   	}
   	
   	/**
   	 * Converts IN directions to OUT and vice versa.
   	 */
   	protected def getOppositeDirection(EventDirection direction) {
   		switch (direction) {
   			case EventDirection.IN:
   				return EventDirection.OUT
   			case EventDirection.OUT:
   				return EventDirection.IN
   			default:
   				throw new IllegalArgumentException("Not known direction: " + direction)
   		} 
   	}
   	
   	/** 
   	 * Returns all events of a given interface whose direction is not oppositeDirection.
   	 * The parent interfaces are taken into considerations as well.
   	 */ 
   	 protected def Set<Event> getAllEvents(Interface anInterface, EventDirection oppositeDirection) {
   		if (anInterface === null) {
   			return Collections.EMPTY_SET
   		}
   		val eventSet = new HashSet<Event>
   		for (parentInterface : anInterface.parents) {
   			eventSet.addAll(parentInterface.getAllEvents(oppositeDirection))
   		}
   		for (event : anInterface.events.filter[it.direction != oppositeDirection].map[it.event]) {
   			eventSet.add(event)
   		}
   		return eventSet
   	}
	
	 /**
     * This rule is responsible for transforming the output signals led out to the system interface.
     * It depends on initNTA.
     */
	val syncSystemOutputEventsRule = createRule.name("SignalsRule").precondition(TopSyncSystemOutEvents.instance).action [
		val boolFlag = target.globalDeclarations.createVariable(DataVariablePrefix.NONE, target.bool, it.event.getOutEventName(it.port, it.instance))
		addToTrace(it.event, #{boolFlag}, trace)
		log(Level.INFO, "Information: System out event: " + it.instance.name + "." + boolFlag.variable.head.name)
		// Maybe the owner setting is not needed?
		val instance = it.instance
		addToTrace(instance, #{boolFlag}, instanceTrace)
		// Saving the port
		addToTrace(it.port, #{boolFlag}, portTrace)
	].build
	
	protected def getOutEventName(Event event, Port port, ComponentInstance owner) {
		return port.name + "_" + event.name + "Of" + owner.name
	}
	
	/**
	 * Returns the name of the toRaise boolean flag of the given event of the given port.
	 */
	protected def toRaiseName(Event event, Port port, ComponentInstance instance) {
		if (!Collections.singletonList(port).getSemanticEvents(EventDirection.IN).contains(event)) {
			throw new IllegalArgumentException("This event is not an in event: " + instance + "." + port.name + ". Port: " + event.name)
		}
		return "toRaise_" + port.name + "_" + event.name + "Of" + instance.name
	}
	
	/**
	 * Returns the name of the isRaised boolean flag of the given event of the given port.
	 */
	protected def isRaisedName(Event event, Port port, ComponentInstance instance) {
		if (!Collections.singletonList(port).getSemanticEvents(EventDirection.IN).contains(event)) {
			throw new IllegalArgumentException("This event is not an in event: " + event.name + ". Port: " + port.name + ". Owner: " + instance + ".")
		}
		return "isRaised_" + port.name + "_" + event.name + "Of" + instance.name
	}
	
	protected def getValueOfName(Variable variable) {
    	if (variable.name.startsWith("toRaise_")) {
    		return variable.name.substring("toRaise_".length) + "Value"
    	}
    	else if (variable.name.startsWith("isRaised_")) {
    		return variable.name.substring("isRaised_".length) + "Value"
    	}
    	else {
    		return variable.name + "Value"
    	}
    }
	
	/**
     * This rule is responsible for connecting the parameters of actions and triggers to the parameters of events.
     * It depends on initNTA.
     */
	val eventParametersRule = createRule.name("EventParametersRule").precondition(ParameteredEvents.instance).action [
		if (it.event.parameterDeclarations.size != 1) {
			throw new IllegalArgumentException("The event has more than one parameters." + it.event)
		}
		// We deal with already transformed instance events
		val uppaalEvents = it.event.allValuesOfTo.filter(DataVariableDeclaration)
							.filter[!it.variable.head.name.startsWith("toRaise")] // So we give one parameter to in events and out events too
		for (uppaalEvent : uppaalEvents) {
			val owner = uppaalEvent.owner
			val port = uppaalEvent.port
			val eventValue = it.param.transformVariable(it.param.type, uppaalEvent.variable.head.valueOfName)
			// Parameter is now not connected to the Event
			addToTrace(it.param, #{eventValue}, trace) // Connected to the port through name (getValueOfName - bad convention)
			addToTrace(owner, #{eventValue}, instanceTrace)
			addToTrace(port, #{eventValue}, portTrace)
		}
	].build
    
    
    // Method getValueOfName has been merged into ExpressionTransformer
    
    /**
     * This rule is responsible for transforming the variables.
     * It depends on initNTA.
     */
	val variablesRule = createRule.name("VariablesRule").precondition(InstanceVariables.instance).action [
		val variable = it.variable.transformVariable(it.variable.type, it.variable.name + "Of" + instance.name)
		addToTrace(it.instance, #{variable}, instanceTrace)		
		// Traces are created in the transformVariable method
	].build
	
	/**
     * This rule is responsible for transforming the constants.
     * It depends on initNTA.
     */
	val constantsRule = createRule.name("ConstantsRule").precondition(ConstantDeclarations.instance).action [
		it.constant.transformVariable(it.type, it.constant.name + "Of" + (it.constant.eContainer as Package).name)
		// Traces are created in the createVariable method
	].build	
	
	private def dispatch VariableDeclaration transformVariable(Declaration variable, EnumerationTypeDefinition type, String name) {
		val uppaalVar = target.globalDeclarations.createChild(declarations_Declaration, dataVariableDeclaration) as DataVariableDeclaration
		uppaalVar.createIntTypeWithRangeAndVariable(
			createLiteralExpression => [it.text = "0"],
			createLiteralExpression => [it.text = (type.literals.size - 1).toString],
			name
		)
		// Creating the trace
		addToTrace(variable, #{uppaalVar}, trace)
		return uppaalVar	
	}
	
	private def dispatch VariableDeclaration transformVariable(Declaration variable,
			hu.bme.mit.gamma.constraint.model.TypeDeclaration type, String name) {
		val declaredType = type.type
		return variable.transformVariable(declaredType, name)	
	}
	
	private def dispatch VariableDeclaration transformVariable(Declaration variable,
			hu.bme.mit.gamma.constraint.model.TypeReference type, String name) {
		val referredType = type.reference
		return variable.transformVariable(referredType, name)	
	}
	
	private def dispatch VariableDeclaration transformVariable(Declaration variable, IntegerTypeDefinition type, String name) {
		val uppaalVar = createVariable(target.globalDeclarations, DataVariablePrefix.NONE, target.int, name)
		// Creating the trace
		addToTrace(variable, #{uppaalVar}, trace)
		return uppaalVar	
	}
	
	private def dispatch VariableDeclaration transformVariable(Declaration variable, BooleanTypeDefinition type, String name) {
		val uppaalVar = createVariable(target.globalDeclarations, DataVariablePrefix.NONE, target.bool, name)
		// Creating the trace
		addToTrace(variable, #{uppaalVar}, trace)
		return uppaalVar
	}
	
	private def dispatch VariableDeclaration transformVariable(ConstantDeclaration variable, IntegerTypeDefinition type, String name) {
		val uppaalVar = createVariable(target.globalDeclarations, DataVariablePrefix.CONST, target.int, name)
		// Creating the trace
		addToTrace(variable, #{uppaalVar}, trace)	
		return uppaalVar	 
	}
	
	private def dispatch VariableDeclaration transformVariable(ConstantDeclaration variable, BooleanTypeDefinition type, String name) {
		val uppaalVar = createVariable(target.globalDeclarations, DataVariablePrefix.CONST, target.bool, name)
		// Creating the trace
		addToTrace(variable, #{uppaalVar}, trace)
		return uppaalVar
	}
	
	private def dispatch VariableDeclaration transformVariable(Declaration variable, Type type, String name) {
		throw new IllegalArgumentException("Not transformable variable type: " + type + "!")
	}
	
	/**
	 * This method is responsible for creating the variables in the resource depending on the received parameters.
	 * It also creates the traces.
	 */
	private def DataVariableDeclaration createVariable(Declarations decl, DataVariablePrefix prefix, PredefinedType type, String name) {
		val varContainer = decl.createChild(declarations_Declaration, dataVariableDeclaration) as DataVariableDeclaration => [
			it.prefix = prefix
		]
		varContainer.createTypeAndVariable(type, name)		
		return varContainer
	}
	
	/**
	 * This method is responsible for creating the variables in the resource depending on the received parameters.
	 * It also creates the traces.
	 */
	private def ChannelVariableDeclaration createSynchronization(Declarations decl, boolean isBroadcast, boolean isUrgent, String name) {
		val syncContainer = decl.createChild(declarations_Declaration, channelVariableDeclaration) as ChannelVariableDeclaration => [
			it.broadcast = isBroadcast
			it.urgent = isUrgent
		]
		syncContainer.createTypeAndVariable(target.chan, name)
		return syncContainer
	}
	
	/**
	 * This method creates the variables of the given containers based on the given predefined type and name.
	 */
	private def createTypeAndVariable(VariableContainer container, PredefinedType type, String name) {		
		container.createChild(variableContainer_TypeDefinition, typeReference) as TypeReference => [
			it.referredType = type
		]
		// Creating variables for all statechart instances
		container.createChild(variableContainer_Variable, declPackage.variable) as Variable => [
			it.container = container
			it.name = name
		]
	}
	
	private def createIntTypeWithRangeAndVariable(VariableContainer container, uppaal.expressions.Expression lowerBound,
			uppaal.expressions.Expression upperBound, String name) {		
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
	val declarationInitRule = createRule.name("DeclarationInitRule").precondition(DeclarationInitializations.instance).action [
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
	
	/**
     * This rule is responsible for transforming all regions to templates. (Top regions and subregions.)
     * It depends on initNTA.
     */
	val regionsRule = createRule.name("RegionRule").precondition(InstanceRegions.instance).action [
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
		// Creating the trace
		addToTrace(it.region, #{template}, trace)
		addToTrace(instance, #{template}, instanceTrace)
	].build
	
	private def boolean isSubregion(Region region) {
		return Subregions.Matcher.on(engine).countMatches(region, null) > 0
	}
	
	/**
     * This rule is responsible for transforming the entry states to committed locations.
     * If the parent regions is a subregion, a new init location is generated as well.
     * It depends on regionsRule.
     */
	val entriesRule = createRule.name("EntriesRule").precondition(Entries.instance).action [
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
	val statesRule = createRule.name("StatesRule").precondition(States.instance).action [
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
	 * Returns the name of the committed entry location of the given composite state.
	 */
	private def String getEntryLocationNameOfState(State state) {
		return "entryOf" + state.name.replaceAll(" ", "")
	}
	
	/**
	 * Returns the name of the committed exit location of the given composite state.
	 */
	private def String getExitLocationNameOfCompositeState(State state) {
		if (!state.compositeState) {
			throw new IllegalAccessException("State is not composite: " + state)
		}
		return ("exitOf" + state.name + id++).replaceAll(" ", "")
	}
	
	/**
     * This rule is responsible for transforming all choices to committed locations.
     * It depends on regionsRule.
     */
	val choicesRule = createRule.name("ChoicesRule").precondition(Choices.instance).action [
		for (template : it.region.getAllValuesOfTo.filter(Template)) {
			val owner = template.owner
			val choiceLocation = template.createChild(template_Location, location) as Location => [
				it.name = "Choice" + id++
				it.locationTimeKind = LocationKind.COMMITED	
				it.comment = "Choice"
			]
			// Creating the trace
			addToTrace(it.choice, #{choiceLocation}, trace)
			addToTrace(owner, #{choiceLocation}, instanceTrace)		
		}
	].build
	
	/**
     * This rule is responsible for transforming all same region transitions (whose sources and targets are in the same region) to edges.
     * It depends on all the rules that create nodes.
     */
	val sameRegionTransitionsRule = createRule.name("SameRegionTransitiosRule").precondition(SameRegionTransitions.instance).action [
		for (template : it.region.allValuesOfTo.filter(Template)) {
			val owner = template.owner
			val source = getEdgeSource(it.source).filter(Location).filter[it.parentTemplate == template].head
			val target = getEdgeTarget(it.target).filter(Location).filter[it.parentTemplate == template].head
			val edge = source.createEdge(target)
			// Creating the trace
			addToTrace(it.transition, #{edge}, trace)			
			addToTrace(owner, #{edge}, instanceTrace)			
		}
	].build	
	
	/**
	 * This rule is repsonsible for transforming transitions whose targets are in a lower abstraction level (lower region)
	 * than its source.
	 */
	val toLowerRegionTransitionsRule = createRule.name("LowerRegionTransitiosRule").precondition(ToLowerInstanceTransitions.instance).action [		
		val syncVar = target.globalDeclarations.createSynchronization(true, false, "AcrReg" + id++)
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
			addToTrace(transition, #{toLowerEdge}, trace)
			addToTrace(owner, #{toLowerEdge}, instanceTrace)
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
				if (ttarget.isCompositeState) {			
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
	val toLowerRegionEntryEventTransitionsRule = createRule.name("LowerRegionEntryEventTransitiosRule").precondition(ToLowerInstanceTransitions.instance).action [		
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
		for (assignmentAction : EntryAssignmentsOfStates.Matcher.on(engine).getAllValuesOfassignmentAction(state)) {
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
	val toHigherRegionTransitionsRule = createRule.name("HigherRegionTransitiosRule").precondition(ToHigherInstanceTransitions.instance).action [		
		val syncVar = target.globalDeclarations.createSynchronization(true, false, "AcrReg" + id++)
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
			val sourceLoc = tsource.allValuesOfTo.filter(Location).filter[it.locationTimeKind == LocationKind.NORMAL].filter[it.owner == owner].head {		
				// Creating a the transition equivalent edge
				val toHigherEdge = sourceLoc.createEdge(sourceLoc)
				addToTrace(transition, #{toHigherEdge}, trace)
				addToTrace(owner, #{toHigherEdge}, instanceTrace)
				// This plus sync edge will contain the deactivation (so triggers can be put onto the original one)
				val syncEdge = createCommittedSyncTarget(sourceLoc, syncVar.variable.head, "AcrossEntry" + id++)
				toHigherEdge.target = syncEdge.source			
				syncEdge.setTemplateActivation(region, false)
				// No need to set the exit events, since exitAssignmentActionsOfStatesRule and exitEventRaisingActionsOfStatesRule do that
				transition.toHigherTransitionRule(tsource.eContainer.eContainer as State, ttarget, visitedRegions, syncVar, lastLevel, owner)			
			}
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
			for (assignment : transition.effects.filter(AssignmentAction)) {
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
	 * Responsible for creating a synchronization edge from the given source to target with the given sync channel and snyc kind.
	 */
	private def Edge createEdgeWithSync(Location sourceLoc, Location targetLoc, Variable syncVar, SynchronizationKind syncKind) {
		val loopEdge = sourceLoc.createEdge(targetLoc)
		loopEdge.setSynchronization(syncVar, syncKind)	
		return loopEdge
	}
	
	/**
	 * Responsible for creating an edge in the given template with the given source and target.
	 */
	private def Edge createEdge(Location source, Location target) {
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
	
	// These dispatch methods are for getting the proper source and target location
	// of a simple edge based on the type of the source/target TTMC state node.
	
	private def dispatch List<Location> getEdgeSource(EntryState entry) {
		return entry.getAllValuesOfTo.filter(Location).filter[it.locationTimeKind == LocationKind.COMMITED].toList	
	}
	
	private def dispatch List<Location> getEdgeSource(State state) {
		return state.getAllValuesOfTo.filter(Location).filter[it.locationTimeKind == LocationKind.NORMAL].toList
	}
	
	private def dispatch List<Location> getEdgeSource(StateNode stateNode) {
		return stateNode.getAllValuesOfTo.filter(Location).toList
	}
	
	private def dispatch List<Location> getEdgeTarget(State state) {
		return state.getAllValuesOfTo.filter(Location).filter[it.locationTimeKind == LocationKind.COMMITED].toList
	}
	
	private def dispatch List<Location> getEdgeTarget(EntryState entry) {
		return entry.getAllValuesOfTo.filter(Location).filter[it.locationTimeKind == LocationKind.COMMITED].toList
	}
	
	private def dispatch List<Location> getEdgeTarget(StateNode stateNode) {
		return stateNode.getAllValuesOfTo.filter(Location).toList
	}
	
	/**
	 * Returns whether the given state node is a composite state.
	 */
	private def boolean isCompositeState(StateNode state) {
		if (!(state instanceof State)) {
			return false
		}
		return CompositeStates.Matcher.on(engine).countMatches(state as State, null, null) != 0
	}

	/**
     * This rule is responsible for creating synchronizations in the subregions of composite states
     * to make sure they get to the proper state at each entry.
     * It depends on all the rules that create nodes (including timeTriggersRule).
     */
	val compositeStateEntryRule = createRule.name("CompositeStateEntryRule").precondition(CompositeStates.instance).action [
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
	 * Returns the name of the committed entry location of the given composite state.
	 */
	private def String getEntrySyncNameOfCompositeState(State state) {
		if (!state.compositeState) {
			throw new IllegalAccessException("State is not composite: " + state)
		}
		return ("entryChanOf" + state.name + (id++)).replaceAll(" ", "")
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
		// In case of exit, the target is always the source
		else {
			target = source
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
	
	/**
	 * Places the exit actions of the given state onto the given edge. If the given state has no exit action, nothing happens.
	 */
	private def setExitEvents(Edge edge, State state, SynchronousComponentInstance owner) {
		if (state !== null) {
			// Assignment actions
			for (action : ExitAssignmentsOfStates.Matcher.on(engine).getAllValuesOfassignmentAction(state)) {
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
	 * Responsible for placing a synchronization onto the given edge: "channel?/channel!".
	 */
	private def setSynchronization(Edge edge, Variable syncVar, SynchronizationKind syncType) {
		edge.createChild(edge_Synchronization, temPackage.synchronization) as Synchronization => [
			it.kind = syncType
			it.createChild(synchronization_ChannelExpression, identifierExpression) as IdentifierExpression => [
				it.identifier = syncVar
			]
		]	
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
	val eventTriggersRule = createRule.name("EventTriggersRule").precondition(EventTriggersOfTransitions.instance).action [
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
	
	private def dispatch uppaal.expressions.Expression transformTrigger(AnyTrigger trigger, ComponentInstance owner) {
		return owner.derivedType.ports.createLogicalExpressionOfPortInEvents(LogicalOperator.OR, owner)			
	}
	
	private def uppaal.expressions.Expression createLogicalExpressionOfPortInEvents(Collection<Port> ports,
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
	
	private def createLogicalExpression(uppaal.expressions.Expression lhs, LogicalOperator operator,
			uppaal.expressions.Expression rhs) {
		return createLogicalExpression => [
			it.firstExpr = lhs
			it.operator = operator
			it.secondExpr = rhs
		]
	}
	
	private def dispatch uppaal.expressions.Expression transformTrigger(EventTrigger trigger, ComponentInstance owner) {
		return trigger.eventReference.transformEventTrigger(owner)
	}
	
	private def dispatch uppaal.expressions.Expression transformTrigger(BinaryTrigger trigger, ComponentInstance owner) {
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
	
	private def dispatch uppaal.expressions.Expression transformTrigger(UnaryTrigger trigger, ComponentInstance owner) {
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

	private def dispatch uppaal.expressions.Expression transformEventTrigger(PortEventReference reference, ComponentInstance owner) {
		val port = reference.port
		val event = reference.event
		return createIdentifierExpression => [
			it.identifier = event.getIsRaisedVariable(port, owner).variable.head
		]
	}

	private def dispatch uppaal.expressions.Expression transformEventTrigger(AnyPortEventReference reference, ComponentInstance owner) {
		val port = #[reference.getPort]
		return port.createLogicalExpressionOfPortInEvents(LogicalOperator.OR, owner)
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
	
	protected def getConstRepresentationName(Event event, Port port) {
		return port.name + "_" + event.name
	}
	
	protected def getConstRepresentationName(Clock clock) {
		return clock.name + "Of" + (clock.eContainer as SynchronousComponentWrapper).name
	}
	
	/**
	 * Returns the Uppaal const representing the given signal.
	 */
	protected def getConstRepresentation(Event event, Port port) {		
		var variables = EventRepresentations.Matcher.on(traceEngine).getAllValuesOfrepresentation(port, event)
		// If the size is 0, it may be because it is a statechart level event and must be transferred to system level: see old code
		if (variables.size != 1) {
			throw new IllegalArgumentException("This event has not one const representations: " + event.name + " Port: " + port.name + " " + variables)
		}
		return variables.head
	}
	
	protected def getConstRepresentation(Clock clock) {
		val variables = ClockRepresentations.Matcher.on(traceEngine).getAllValuesOfrepresentation(clock)
		if (variables.size > 1) {
			throw new IllegalArgumentException("This clock has more than one const representations: " + clock + " " + variables)
		}
		return variables.head
	}
	
	/**
	 * Creates the Uppaal const representing the given signal.
	 */
	protected def createConstRepresentation(Event event, Port port, SynchronousComponentWrapper wrapper) {
			val name = event.getConstRepresentationName(port)
			event.createConstRepresentation(port, wrapper, name, constantVal++)
	}
	
	protected def createConstRepresentation(Clock clock, SynchronousComponentWrapper wrapper) {
			val name = clock.getConstRepresentationName
			clock.createConstRepresentation(wrapper, name, constantVal++)
	}
	
	protected def createConstRepresentation(Event event, Port port, SynchronousComponentWrapper wrapper, String name, int value) {
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
	
	protected def createConstRepresentation(Clock clock, SynchronousComponentWrapper wrapper, String name, int value) {
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
	 * Returns the Uppaal toRaise boolean flag of a gamma typed-signal.
	 */
	protected def getToRaiseVariable(Event event, Port port, ComponentInstance instance) {
		var DataVariableDeclaration variable 
		val variables = event.allValuesOfTo.filter(DataVariableDeclaration)
				.filter[it.prefix == DataVariablePrefix.NONE && it.owner == instance]
		if (Collections.singletonList(port).getSemanticEvents(EventDirection.OUT).contains(event)) {
			// This is an out event
			variable = variables.filter[it.variable.head.name.equals(event.getOutEventName(port, instance))].head
		}		
		else {		
			// Else, this is an in event
			if (instance.isCascade) {
				// Cascade components have no toRaise variables, therefore the isRaised is returned
				variable = event.getIsRaisedVariable(port, instance)
			}
			else {
				variable = variables.filter[it.variable.head.name.equals(event.toRaiseName(port, instance))].head
			}	
		}
		if (variable === null) {
			throw new IllegalArgumentException("This event has no toRaiseEvent: " + event.name + " Port: " + port.name + " Instance: " + instance.name)
		}
		return variable
	}	
	
	/**
	 * Returns the Uppaal isRaised boolean flag of a gamma typed-signal.
	 */
	protected def getIsRaisedVariable(Event event, Port port, ComponentInstance instance) {
		val variable = event.allValuesOfTo.filter(DataVariableDeclaration).filter[it.prefix == DataVariablePrefix.NONE
			&& it.owner == instance && it.variable.head.name.equals(event.isRaisedName(port, instance))].head
		if (variable === null) {
			throw new IllegalArgumentException("This event has no isRaisedEvent: " + event.name + " Port: " + port.name + " Instance: " + instance.name)
		}
		return variable
	}
	
	/**
	 * Returns the Uppaal out-event boolean flag of a gamma typed-signal.
	 */
	protected def getOutVariable(Event event, Port port, ComponentInstance instance) {
		val variable = event.allValuesOfTo.filter(DataVariableDeclaration).filter[it.prefix == DataVariablePrefix.NONE
			&& it.owner == instance && it.variable.head.name.equals(event.getOutEventName(port, instance))].head
		if (variable === null) {
			throw new IllegalArgumentException("This event has no isRaisedEvent: " + event.name + " Port: " + port.name + " Instance: " + instance.name)
		}
		return variable
	}
	
	 // Method getValueOfName has been merged into ExpressionTransformer
	
	/**
     * This rule is responsible for transforming the timeout event triggers.
     * It depends on sameRegionTransitionsRule, toLowerTransitionsRule, ToHigherTransitionsRule and triggersRule.
     */
	val timeTriggersRule = createRule.name("TimeTriggersRule").precondition(TimeTriggersOfTransitions.instance).action [
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
			val clockVar = template.declarations.createChild(declarations_Declaration, clockVariableDeclaration) as ClockVariableDeclaration
			clockVar.createTypeAndVariable(target.clock, "timer" + (id++))
			// Creating the trace
			addToTrace(it.timeoutDeclaration, #{clockVar}, trace)
			addToTrace(owner, #{clockVar}, instanceTrace)		
			val location = cloneEdge.source
			val locInvariant = location.invariant
			val newLoc = template.createChild(template_Location, getLocation) as Location => [
				it.name = "timer" + (id++)
			]
			// Creating the trace; this is why this rule depends on toLowerTransitionsRule and ToHigherTransitionsRule
			addToTrace(it.state, #{newLoc}, trace)
			addToTrace(owner, #{newLoc}, instanceTrace)			
			val newEdge = location.createEdge(newLoc)
			cloneEdge.source = newLoc
			cloneEdge.setRunCycle
			// Creating the owner trace for the clock edge (the isStable and isActive guards are set in swapGuardsOfTimeTriggerTransitions)
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
		}	
	].build
	
	protected def convertToMs(TimeSpecification time) {
		switch (time.unit) {
			case SECOND: {
				val newValue = time.value.multiplyExpression(1000)
				// Maybe strange changing the S to MS in the View model 
				// New expression needs to be contained in a resource because of the epxpression trace mechanism) 
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
	 * Transforms gamma expression "100" into "100 * value" or "timeValue" into "timeValue * value"
	 */
	protected def multiplyExpression(Expression base, long value) {
		val multiplyExp = constrFactory.createMultiplyExpression => [
			it.operands += base
			it.operands += constrFactory.createIntegerLiteralExpression => [
				it.value = BigInteger.valueOf(value)
			]
		]
		return multiplyExp
	}
	
	/**
	 * Places the guards of the extended edges onto the corresponding clock edges.
	 */
	protected def swapGuardsOfTimeTriggerTransitions() {
		val matches = EdgesWithClock.Matcher.on(ViatraQueryEngine.on(new EMFScope(target))).allMatches
		for (match : matches) {
			val clockEdge = match.edge
			val extendedEdge = clockEdge.otherEdgeOfClockEdge
			if (extendedEdge.guard !== null) {
				clockEdge.addGuard(extendedEdge.guard, LogicalOperator.AND)
				extendedEdge.guard = null			
			}
			// Adding isStable and isActive guards
			clockEdge.addGuard(isStableVar, LogicalOperator.AND)
			// TODO no isActive guard, as clocks stuck in inactive templates can freeze ALL clocks -> deadlock
			// clockEdge.createIsActiveGuard
		}
	}
	
	/**
	 * Returns the extended edges of the given clock edge.
	 */
	private def getOtherEdgeOfClockEdge(Edge edge) {
		val target = edge.target
		val template = edge.parentTemplate
		val edges = template.edge.filter[it.source == target]
		if (edges.size != 1) {
			throw new IllegalArgumentException("The clock edge has more than one extension edge!" + edge.source.name + "->" + edge.target.name)
		}
		return edges.head
	}
	
	/**
	 * Responsible for creating an AND logical expression containing an already existing expression and a clock expression.
	 */
	private def insertLogicalExpression(EObject container, EReference reference, CompareOperator compOp, ClockVariableDeclaration clockVar,
		Expression timeExpression, uppaal.expressions.Expression originalExpression, TimeoutEventReference timeoutEventReference, LogicalOperator logOp) {
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
		ClockVariableDeclaration clockVar, Expression timeExpression, TimeoutEventReference timeoutEventReference) {		
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
	val guardsRule = createRule.name("GuardsRule").precondition(GuardsOfTransitions.instance).action [
		for (edge : it.transition.allValuesOfTo.filter(Edge)) {
			edge.transformGuard(it.guard)		
		}
		// The trace is created by the ExpressionTransformer
	].build
	
	/**
	 * Responsible for placing the ttmcExpressions onto the given edge. It is needed to ensure that "isActive"
	 * variables are handled correctly (if they are present).
	 */
	private def transformGuard(Edge edge, Expression guard) {
		// If the reference is not null there are "triggers" on it
		if (edge.guard !== null) {
			// Getting the old reference
			val oldGuard = edge.guard as uppaal.expressions.Expression
			// Creating the new andExpression that will contain the same reference and the regular guard expression
			val andExpression = edge.createChild(edge_Guard, logicalExpression) as LogicalExpression => [
				it.operator = LogicalOperator.AND
				it.secondExpr = oldGuard
			]		
			// This is the transformation of the regular TTMC guard
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
	val assignmentActionsRule = createRule.name("AssignmentActionsRule").precondition(UpdatesOfTransitions.instance).action [
		// No update on ToHigher transitions, it is done in ToHigherTransitionRule
		for (edge : it.transition.allValuesOfTo.filter(Edge)) {
			edge.transformAssignmentAction(edge_Update, it.assignmentAction, edge.owner)		
		}
		// The trace is created by the ExpressionTransformer
	].build
	
	/**
     * This rule is responsible for transforming the entry event updates of states.
     * It depends on sameRegionTransitionsRule, ExpressionTransformer and all the rules that create nodes.
     */
	val entryAssignmentActionsOfStatesRule = createRule.name("EntryAssignmentActionsOfStatesRule").precondition(EntryAssignmentsOfStates.instance).action [
		for (edge : it.state.allValuesOfTo.filter(Edge)) {
			edge.transformAssignmentAction(edge_Update, it.assignmentAction, edge.owner)
			// The trace is created by the ExpressionTransformer
		}
	].build
	
	/**
     * This rule is responsible for transforming the entry event timeout actions of states. 
     * (Initializing the timer to 0 on entering a state.)
     * It depends on sameRegionTransitionsRule, ExpressionTransformer and all the rules that create nodes.
     */
	val entryTimeoutActionsOfStatesRule = createRule.name("EntryTimeoutActionsOfStatesRule").precondition(EntryTimeoutActionsOfStates.instance).action [
		for (edge : it.state.allValuesOfTo.filter(Edge)) {
			edge.transformTimeoutAction(edge_Update, it.setTimeoutAction, edge.owner)
			// The trace is created by the ExpressionTransformer
		}
	].build
	
	/**
     * This rule is responsible for transforming the exit event updates of states.
     * It depends on sameRegionTransitionsRule, ExpressionTransformer and all the rules that create nodes.
     */
	val exitAssignmentActionsOfStatesRule = createRule.name("ExitAssignmentActionsOfStatesRule").precondition(ExitAssignmentsOfStatesWithTransitions.instance).action [
		for (edge : it.outgoingTransition.allValuesOfTo.filter(Edge)) {
			edge.transformAssignmentAction(edge_Update, it.assignmentAction, edge.owner)
		}
		// The trace is created by the ExpressionTransformer
		// The loop synchronization edges already have the exit actions
	].build
	
	/**
     * This rule is responsible for transforming the raise event actions (raising events) of transitions. (No system out-events.)
     * It depends on sameRegionTransitionsRule and eventsRule.
     */
	val eventRaisingActionsRule = createRule.name("EventRaisingActionsRule").precondition(RaisingActionsOfTransitions.instance).action [
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
	val syncSystemEventRaisingActionsRule = createRule.name("SystemEventRaisingActionsRule").precondition(RaiseTopSystemEventOfTransitions.instance).action [
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
	val entryEventRaisingActionsRule = createRule.name("EntryEventRaisingActionsRule").precondition(EntryRaisingActionsOfStates.instance).action [
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
	val syncSystemEventRaisingOfEntryActionsRule = createRule.name("EntryInterfaceEventRaisingActionsRule").precondition(RaiseTopSystemEventStateEntryActions.instance).action [
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
	val exitEventRaisingActionsOfStatesRule = createRule.name("ExitRaisingEventActionsOfStatesRule").precondition(ExitRaisingActionsOfStatesWithTransitions.instance).action [
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
	val exitSystemEventRaisingActionsOfStatesRule = createRule.name("ExitSystemEventRaisingActionsOfStatesRule").precondition(ExitRaisingActionsOfStatesWithTransitions.instance).action [
		for (edge : it.outgoingTransition.allValuesOfTo.filter(Edge)) {
			val owner = edge.owner  as SynchronousComponentInstance
			for (match : RaiseSystemEventStateExitActions.Matcher.on(engine).getAllMatches(null, it.state,
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
		val exps = eventAction.parameters
		if (!exps.empty) {
	    	for (expression : exps) {
//	    		val parameter = toRaiseEvent.parameterDeclarations.head
		    	val assignment = edge.createAssignmentExpression(edge_Update, toRaiseEvent.getValueOfVariable(port, inInstance), expression, inInstance)
		    	addToTrace(eventAction, #{assignment}, expressionTrace)
		    }    		
    	}
	}
	
	/**
	 * Places a message insert in a queue equivalent update on the given edge.
	 */
	private def createQueueInsertion(Edge edge, Port systemPort, Event toRaiseEvent, ComponentInstance inInstance, DataVariableDeclaration variable) {
		val wrapper = inInstance.derivedType as SynchronousComponentWrapper
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
	val isActiveRule = createRule.name("IsActiveRule").precondition(Transitions.instance).action [
		for (edge : it.transition.allValuesOfTo.filter(Edge)) {
			if (it.region.subregion) {
				edge.createIsActiveGuard
			}
		}
	].build
	
	/**
	 * Places guards (conjunction of the negated expressions of adjacent edges) for the default edges of choices. 
	 */
	val defultChoiceTransitionsRule = createRule.name("DefultChoiceTransitionsRule").precondition(DefaultTransitionsOfChoices.instance).action [
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
	
	val compositeStateEntryRuleCompletion = createRule.name("CompositeStateEntryRuleCompletion").precondition(CompositeStates.instance).action [
		for (commLoc : it.compositeState.allValuesOfTo.filter(Location).filter[it.locationTimeKind == LocationKind.COMMITED]) {
			// Solving the problem: the finalize should take into the deepest state at once
			// From the entry node (an loop edge-history) finalize location should be skipped
			val template = commLoc.parentTemplate
			val finalizeEdge = template.createFinalizeEdge("FinalizeBefore" + it.name.toFirstUpper.replaceAll(" ", ""), commLoc)			
			val incomingEdges = new HashSet<Edge>(template.edge.filter[it.target == commLoc && it != finalizeEdge].toSet)
			for (incomingEdge : incomingEdges) {
				val ttmcSource = incomingEdge.source.allValuesOfFrom.head
				// If not an entry edge: normal entry, history entry
				if (!(ttmcSource instanceof EntryState || ttmcSource == it.compositeState)) {
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
	
	val toLowerRegionTransitionCompletion = createRule.name("LowerRegionTransitiosRule").precondition(ToLowerInstanceTransitions.instance).action [
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
	
	private def finalizeSyncVarName() {
		return "finalize"
	}
	
	/**
	 * Places the negated form of the given expression onto the given edge.
	 */
	private def addNegatedExpression(Edge edge, uppaal.expressions.Expression expression) {
		val negatedExp = createNegationExpression
		negatedExp.copy(negationExpression_NegatedExpression, expression)
		edge.addGuard(negatedExp, LogicalOperator.AND)
	}
	
	/**
	 * Responsible for creating an assignment expression with the given variable reference and the given expression.
	 */
	private def AssignmentExpression createAssignmentExpression(EObject container, EReference reference, VariableContainer variable, Expression rhs, ComponentInstance owner) {
		val assignmentExpression = container.createChild(reference, assignmentExpression) as AssignmentExpression => [
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = variable.variable.head // Only one variable is expected
			]
			it.operator = AssignmentOperator.EQUAL
			it.transform(binaryExpression_SecondExpr, rhs, owner)
		]
		return assignmentExpression
	}
	private def AssignmentExpression createAssignmentExpression(EObject container, EReference reference, VariableContainer variable, uppaal.expressions.Expression rhs) {
		val assignmentExpression = container.createChild(reference, assignmentExpression) as AssignmentExpression => [
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = variable.variable.head // Only one variable is expected
			]
			it.operator = AssignmentOperator.EQUAL
			it.secondExpr = rhs
		]
		return assignmentExpression
	}
	
	/**
	 * Responsible for creating a ! synchronization on an edge and a committed location as the source of the edge.
	 * The target of the synchronized edge will be the given "target" location.
	 */
	private def Edge createCommittedSyncTarget(Location target, Variable syncVar, String name) {
		val template = target.parentTemplate
		val syncLocation = template.createChild(template_Location, location) as Location => [
			it.name = name
			it.locationTimeKind = LocationKind.COMMITED
			it.comment = "Synchronization location."
		]
		val syncEdge = syncLocation.createEdge(target)
		syncEdge.comment = "Synchronization edge."
		syncEdge.setSynchronization(syncVar, SynchronizationKind.SEND)
		return syncEdge		
	}
	
	/**
	 * Returns the name of the committed entry location of the given composite state.
	 */
	private def String getExitSyncNameOfCompositeState(State state) {
		if (!state.compositeState) {
			throw new IllegalAccessException("State is not composite: " + state)
		}
		return ("exitChanOf" + state.name + (id++)).replaceAll(" ", "")
	}
	
    
    private def boolean isTopRegion(Region region) {
    	return TopRegions.Matcher.on(engine).countMatches(null, null, region, null) > 0
    }
    
    /**
     * Returns whether the given region has deep history in one of its ancestor regions.
     */
    private def boolean hasHistoryAbove(Region region) {
    	if (region.isTopRegion) {
    		return false
    	}
    	val regionAbove = region.eContainer.eContainer as Region
    	return RegionsWithDeepHistory.Matcher.on(engine).countMatches(regionAbove) > 0 || regionAbove.hasHistoryAbove
    	
    }
    
    /**
     * Returns whether the region has history or not. (This determines where the synchronization edges have to be targeted.)
     */
    private def boolean hasHistory(Region region) {
    	return (region.hasHistoryAbove || 
    	RegionsWithShallowHistory.Matcher.on(engine).countMatches(region) > 0 ||
    	RegionsWithDeepHistory.Matcher.on(engine).countMatches(region) > 0)
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
    	deleteChoices
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
    			for (inEdge : inEdges) {
    				for (outEdge : outEdges) {
    					for (aTrace : Traces.Matcher.on(traceEngine).getAllValuesOftrace(null, outEdge)) {
               				aTrace.remove(trace_To, outEdge)
              				aTrace.addTo(trace_To, aMap.get(outEdge))
               			}
               			for (aTrace : InstanceTraces.Matcher.on(traceEngine).getAllValuesOftrace(null, inEdge)) {
               				aTrace.remove(instanceTrace_Element, outEdge)
               			}
               			outEdge.delete
    				}
    				for (aTrace : Traces.Matcher.on(traceEngine).getAllValuesOftrace(null, inEdge)) {
               			aTrace.remove(trace_To, inEdge)
              			aTrace.addTo(trace_To, aMap.get(inEdge))
               		}
               		for (aTrace : InstanceTraces.Matcher.on(traceEngine).getAllValuesOftrace(null, inEdge)) {
               			aTrace.remove(instanceTrace_Element, inEdge)
               		}
               		inEdge.delete
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
    
    val clockLocationTraceRule = createRule.name("ClockLocationTraceRule").precondition(EdgesWithClock.instance).action [
    	val source = it.edge.source
    	val target = it.edge.target
    	val state = source.allValuesOfFrom.head
    	addToTrace(state, #{target}, trace)
    ].build
   
     /**
     * Deletes and edge from its template and the trace model.
     */
    private def delete(Edge edge) {
    	edge.parentTemplate.edge.remove(edge)
    	edge.removeTrace 
    }
    
    /**
     * Copies the synchronization, guard and all the updates from the from edge to the to edge.
     */
    private def copyTo (Edge from, Edge to) {
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
    	for (statechartRegionMatch : StatechartRegions.Matcher.on(engine).allMatches) {
			for (instance : SimpleInstances.Matcher.on(engine).getAllValuesOfinstance(statechartRegionMatch.statechart)) {
				var array = new ArrayList<String>
				for (state : States.Matcher.on(engine).getAllValuesOfstate(statechartRegionMatch.region, null)) {
					array.add(state.locationName)
				}
				templateLocationMap.put(statechartRegionMatch.region.regionName + "Of" + instance.name, array)
			}
		}
    	return templateLocationMap
    }
    
    /**
     * Returns the location name of a state.
     */
    private def String getLocationName(State state) {
    	return state.name.replaceAll(" ","")
    } 
    
    /**
     * Returns the template name of a region.
     */
    private def String getRegionName(Region region) {
    	var String templateName
    	if (region.isSubregion) {
			templateName = (region.name + "Of" + (region.eContainer as State).name)
		}
		else {			
			templateName = (region.name + "OfStatechart")
		}
		return templateName.replaceAll(" ","")
	}
	
	/**
	 * Disposes of the transformer.
	 */
    def dispose() {
        if (transformation !== null) {
            transformation.dispose
        }
        traceEngine = null
        transformation = null
        return
    }
    
}
