package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.statechart.model.CompositeElement
import hu.bme.mit.gamma.statechart.model.Region
import hu.bme.mit.gamma.statechart.model.SchedulingOrder
import hu.bme.mit.gamma.statechart.model.StatechartDefinition
import hu.bme.mit.gamma.statechart.model.TimeSpecification
import hu.bme.mit.gamma.statechart.model.composite.AbstractSynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.CascadeCompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponent
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.model.composite.SynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.model.interface_.EventDirection
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.InputInstanceEvents
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.InstanceRegions
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.QueueSwapInstancesOfComposite
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.SimpleInstances
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.SimpleWrapperInstances
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.TimeoutValues
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.TopSyncSystemOutEvents
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.TopUnwrappedSyncComponents
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.TopWrapperComponents
import hu.bme.mit.gamma.uppaal.transformation.traceability.TraceabilityPackage
import java.util.Collection
import java.util.Collections
import java.util.List
import java.util.NoSuchElementException
import java.util.Optional
import java.util.logging.Level
import java.util.logging.Logger
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.transformation.runtime.emf.modelmanipulation.IModelManipulations
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRule
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRuleFactory
import uppaal.declarations.ChannelVariableDeclaration
import uppaal.declarations.ClockVariableDeclaration
import uppaal.declarations.DataVariableDeclaration
import uppaal.declarations.DeclarationsPackage
import uppaal.declarations.Function
import uppaal.declarations.FunctionDeclaration
import uppaal.expressions.ExpressionsFactory
import uppaal.expressions.LogicalOperator
import uppaal.statements.Block
import uppaal.statements.ExpressionStatement
import uppaal.statements.StatementsPackage
import uppaal.templates.Edge
import uppaal.templates.LocationKind
import uppaal.templates.SynchronizationKind
import uppaal.templates.Template
import uppaal.templates.TemplatesPackage
import uppaal.types.TypeReference
import uppaal.types.TypesFactory
import uppaal.types.TypesPackage

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*

class OrchestratorCreator {
	// Transformation rule-related extensions
	protected extension BatchTransformationRuleFactory = new BatchTransformationRuleFactory
	protected final extension IModelManipulations manipulation
	// Trace
	protected final extension Trace modelTrace
	// Engine
	protected final extension ViatraQueryEngine engine
	// Gamma package
	protected final extension TraceabilityPackage trPackage = TraceabilityPackage.eINSTANCE
	// UPPAAL packages
	protected final extension DeclarationsPackage declPackage = DeclarationsPackage.eINSTANCE
	protected final extension TypesPackage typPackage = TypesPackage.eINSTANCE
	protected final extension TemplatesPackage temPackage = TemplatesPackage.eINSTANCE
	protected final extension StatementsPackage stmPackage = StatementsPackage.eINSTANCE
	// UPPAAL factories
	protected final extension ExpressionsFactory expFact = ExpressionsFactory.eINSTANCE
	protected final extension TypesFactory typesFact = TypesFactory.eINSTANCE
	// Id
	var id = 0
	protected final DataVariableDeclaration isStableVar
	protected final DataVariableDeclaration transitionIdVar
	// Orchestrating period for top sync components
	protected final TimeSpecification minimalOrchestratingPeriod
	protected final TimeSpecification maximalOrchestratingPeriod
	// Auxiliary objects
    protected final extension InPlaceExpressionTransformer inPlaceExpressionTransformer = new InPlaceExpressionTransformer
	protected final extension EventHandler eventHandler = new EventHandler
	protected final extension Cloner cloner = new Cloner
	protected final extension NtaBuilder ntaBuilder
	protected final extension ExpressionEvaluator expressionEvaluator
	protected final extension AssignmentExpressionCreator assignmentExpressionCreator
	protected final extension CompareExpressionCreator compareExpressionCreator
	// Rules
	protected BatchTransformationRule<TopUnwrappedSyncComponents.Match, TopUnwrappedSyncComponents.Matcher> topSyncOrchestratorRule
	protected BatchTransformationRule<TopWrapperComponents.Match, TopWrapperComponents.Matcher> topWrappedSyncOrchestratorRule
	protected BatchTransformationRule<SimpleWrapperInstances.Match, SimpleWrapperInstances.Matcher> instanceWrapperSyncOrchestratorRule
	
	new(NtaBuilder ntaBuilder, ViatraQueryEngine engine, IModelManipulations manipulation,
			AssignmentExpressionCreator assignmentExpressionCreator, CompareExpressionCreator compareExpressionCreator,
			TimeSpecification minimalOrchestratingPeriod, TimeSpecification maximalOrchestratingPeriod,
			Trace modelTrace, DataVariableDeclaration transitionIdVar, DataVariableDeclaration isStableVar) {
		this.ntaBuilder = ntaBuilder
		this.manipulation = manipulation
		this.engine = engine
		this.minimalOrchestratingPeriod = minimalOrchestratingPeriod
		this.maximalOrchestratingPeriod = maximalOrchestratingPeriod
		this.modelTrace = modelTrace
		this.transitionIdVar = transitionIdVar
		this.isStableVar = isStableVar
		this.expressionEvaluator = new ExpressionEvaluator(this.engine)
		this.assignmentExpressionCreator = assignmentExpressionCreator
		this.compareExpressionCreator = compareExpressionCreator
	}
	
	/**
	 * Responsible for creating a scheduler template for TOP synchronous composite components.
	 * Note that it only fires if there are TOP synchronous composite components.
	 * Depends on all statechart mapping rules.
	 */
	 def getTopSyncOrchestratorRule() {
		if (topSyncOrchestratorRule === null) {
			topSyncOrchestratorRule = createRule(TopUnwrappedSyncComponents.instance).action [		
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
				// Reset transition id variable to reduce state space
				firstEdge.resetTransitionIdVariableIfNeeded
			].build
		}
	}
	
	/**
	 * Responsible for creating a scheduler template for a single synchronous composite component wrapped by a Wrapper.
	 * Note that it only fires if there are top wrappers.
	 * Depends on topWrapperSyncChannelRule and all statechart mapping rules.
	 */
	def getTopWrappedSyncOrchestratorRule() {
		if (topWrappedSyncOrchestratorRule === null) {
			topWrappedSyncOrchestratorRule = createRule(TopWrapperComponents.instance).action [		
				val lastEdge = it.composite.createSchedulerTemplate(it.wrapper.syncSchedulerChannel)
				lastEdge.setSynchronization(it.wrapper.syncSchedulerChannel.variable.head, SynchronizationKind.SEND)
			].build
		}
	}
	
	 /**
	 * Responsible for creating a scheduler template for all synchronous composite components wrapped by wrapper instances.
	 * Note that it only fires if there are wrapper instances.
	 * Depends on allWrapperSyncChannelRule and all statechart mapping rules.
	 */
	def getInstanceWrapperSyncOrchestratorRule() {
		if (instanceWrapperSyncOrchestratorRule === null) {
			instanceWrapperSyncOrchestratorRule = createRule(SimpleWrapperInstances.instance).action [		
				val lastEdge = it.component.createSchedulerTemplate(it.instance.syncSchedulerChannel)
				lastEdge.setSynchronization(it.instance.syncSchedulerChannel.variable.head, SynchronizationKind.SEND)
				val orchestratorTemplate = lastEdge.parentTemplate
				addToTrace(it.instance, #{orchestratorTemplate}, instanceTrace)
			].build
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
		clockVar.createTypeAndVariable(nta.clock, "timerOrchestrator" + (id++))
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
	
	private def resetTransitionIdVariableIfNeeded(Edge edge) {
		if (transitionIdVar !== null) {
			edge.createAssignmentExpression(edge_Update, transitionIdVar,
				createLiteralExpression => [it.text = "0"]
			)
		}
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
		val finalLoc = schedulerTemplate.createLocation => [
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
		val trueInitialLocation = schedulerTemplate.createLocation => [
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
	 * Creates the function that copies the state of the toRaise flags to the isRaised flags, and clears the toRaise flags.
	 */
	private def createClearFunction(SynchronousComponent component) {
		nta.globalDeclarations.createChild(declarations_Declaration, functionDeclaration) as FunctionDeclaration => [
			it.createChild(functionDeclaration_Function, declPackage.function) as Function => [
				it.createChild(function_ReturnType, typeReference) as TypeReference => [
					it.referredType = nta.void
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
	 * Creates the scheduling of the whole network of automata starting out from the given composite component
	 */
	private def scheduleTopComposite(SynchronousComponent component, Edge previousLastEdge) {
		checkState(component instanceof AbstractSynchronousCompositeComponent ||
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
		val swapLocation = lastEdge.parentTemplate.createLocation => [
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
		// Syncing the templates with run cycles
		val schedulingOrder = statechart.schedulingOrder
			// Scheduling either top-down or bottom-up
		var List<Region> regionsToBeScheduled
		switch (schedulingOrder) {
			case TOP_DOWN: {
				regionsToBeScheduled = statechart.regionsTopDown
			}
			case BOTTOM_UP: {
				regionsToBeScheduled = statechart.regionsBottomUp
			}
			default: {
				throw new IllegalArgumentException("Not known scheduling order: " + schedulingOrder)
			}
		}
		for (region: regionsToBeScheduled) {
			lastEdges = region.createRunCycleEdge(lastEdges, schedulingOrder, instance)
		}
		val lastEdge = createEdgeCommittedTarget(lastEdges.head.target, "finalizing" + id++ + instance.name)
		for (runCycleEdge : lastEdges) {
			runCycleEdge.target = lastEdge.source
		}
		// If the instance is cascade, the in events have to be cleared
		if (instance.isCascade) {
			for (match : InputInstanceEvents.Matcher.on(engine).getAllMatches(instance, null, null)) {
				lastEdge.createAssignmentExpression(edge_Update, match.event.getIsRaisedVariable(match.port, match.instance), false)
			}
		}
		return lastEdge
	}
	
	private def List<Region> getRegionsTopDown(CompositeElement compositeElement) {
		val regions = newArrayList
		for (region : compositeElement.regions) {
			regions += region
			for (substate : region.states.filter[it.composite]) {
				regions += substate.regionsTopDown
			}
		}
		return regions
	}
	
	private def List<Region> getRegionsBottomUp(CompositeElement compositeElement) {
		val regions = newArrayList
		for (region : compositeElement.regions) {
			for (substate : region.states.filter[it.composite]) {
				regions += substate.regionsBottomUp
			}
			regions += region
		}
		return regions
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
		regionsToExamine += region // If the actual region has not been scheduled yet (it can happen via composite state entries)
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
	
}
