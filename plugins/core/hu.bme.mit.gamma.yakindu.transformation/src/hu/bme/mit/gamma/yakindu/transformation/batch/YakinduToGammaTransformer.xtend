/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.yakindu.transformation.batch

import hu.bme.mit.gamma.action.model.ActionModelPackage
import hu.bme.mit.gamma.action.model.AssignmentStatement
import hu.bme.mit.gamma.expression.model.AndExpression
import hu.bme.mit.gamma.expression.model.ConstantDeclaration
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.ExpressionModelPackage
import hu.bme.mit.gamma.expression.model.InitializableElement
import hu.bme.mit.gamma.expression.model.NotExpression
import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.genmodel.model.GenModel
import hu.bme.mit.gamma.genmodel.model.StatechartCompilation
import hu.bme.mit.gamma.statechart.interface_.EventTrigger
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelPackage
import hu.bme.mit.gamma.statechart.interface_.InterfaceRealization
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.interface_.TimeSpecification
import hu.bme.mit.gamma.statechart.interface_.Trigger
import hu.bme.mit.gamma.statechart.statechart.BinaryTrigger
import hu.bme.mit.gamma.statechart.statechart.BinaryType
import hu.bme.mit.gamma.statechart.statechart.ChoiceState
import hu.bme.mit.gamma.statechart.statechart.DeepHistoryState
import hu.bme.mit.gamma.statechart.statechart.EntryState
import hu.bme.mit.gamma.statechart.statechart.ForkState
import hu.bme.mit.gamma.statechart.statechart.InitialState
import hu.bme.mit.gamma.statechart.statechart.JoinState
import hu.bme.mit.gamma.statechart.statechart.MergeState
import hu.bme.mit.gamma.statechart.statechart.PortEventReference
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.SchedulingOrder
import hu.bme.mit.gamma.statechart.statechart.SetTimeoutAction
import hu.bme.mit.gamma.statechart.statechart.ShallowHistoryState
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StateNode
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory
import hu.bme.mit.gamma.statechart.statechart.StatechartModelPackage
import hu.bme.mit.gamma.statechart.statechart.TimeoutDeclaration
import hu.bme.mit.gamma.statechart.statechart.TimeoutEventReference
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.statechart.TransitionPriority
import hu.bme.mit.gamma.yakindu.transformation.queries.ActionsOfRegularLocalReactions
import hu.bme.mit.gamma.yakindu.transformation.queries.Choices
import hu.bme.mit.gamma.yakindu.transformation.queries.CompositeStateRegions
import hu.bme.mit.gamma.yakindu.transformation.queries.DefaultTransitionsOfExitNodes
import hu.bme.mit.gamma.yakindu.transformation.queries.Entries
import hu.bme.mit.gamma.yakindu.transformation.queries.Events
import hu.bme.mit.gamma.yakindu.transformation.queries.ExitNodeTransitions
import hu.bme.mit.gamma.yakindu.transformation.queries.FinalStates
import hu.bme.mit.gamma.yakindu.transformation.queries.Forks
import hu.bme.mit.gamma.yakindu.transformation.queries.GuardsOfRegularLocalReactions
import hu.bme.mit.gamma.yakindu.transformation.queries.InterfaceToInterface
import hu.bme.mit.gamma.yakindu.transformation.queries.Interfaces
import hu.bme.mit.gamma.yakindu.transformation.queries.Joins
import hu.bme.mit.gamma.yakindu.transformation.queries.Merges
import hu.bme.mit.gamma.yakindu.transformation.queries.NonEntryNonChoiceTransitions
import hu.bme.mit.gamma.yakindu.transformation.queries.SimpleStates
import hu.bme.mit.gamma.yakindu.transformation.queries.Statecharts
import hu.bme.mit.gamma.yakindu.transformation.queries.StatesWithEntryEvents
import hu.bme.mit.gamma.yakindu.transformation.queries.StatesWithExitEvents
import hu.bme.mit.gamma.yakindu.transformation.queries.StatesWithRegularLocalReactions
import hu.bme.mit.gamma.yakindu.transformation.queries.TopRegions
import hu.bme.mit.gamma.yakindu.transformation.queries.Transitions
import hu.bme.mit.gamma.yakindu.transformation.queries.TransitionsWithAlwaysTriggers
import hu.bme.mit.gamma.yakindu.transformation.queries.TransitionsWithDefaultTriggers
import hu.bme.mit.gamma.yakindu.transformation.queries.TransitionsWithEffect
import hu.bme.mit.gamma.yakindu.transformation.queries.TransitionsWithEventTriggers
import hu.bme.mit.gamma.yakindu.transformation.queries.TransitionsWithGuards
import hu.bme.mit.gamma.yakindu.transformation.queries.TransitionsWithTimeTriggers
import hu.bme.mit.gamma.yakindu.transformation.queries.TriggersOfRegularLocalReactions
import hu.bme.mit.gamma.yakindu.transformation.queries.TriggersOfTimedLocalReactions
import hu.bme.mit.gamma.yakindu.transformation.queries.VariableInits
import hu.bme.mit.gamma.yakindu.transformation.queries.Variables
import hu.bme.mit.gamma.yakindu.transformation.traceability.TraceabilityFactory
import hu.bme.mit.gamma.yakindu.transformation.traceability.TraceabilityPackage
import hu.bme.mit.gamma.yakindu.transformation.traceability.Y2GTrace
import java.util.AbstractMap.SimpleEntry
import java.util.HashSet
import java.util.logging.Level
import java.util.logging.Logger
import org.eclipse.emf.ecore.EObject
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.api.impl.RunOnceQueryEngine
import org.eclipse.viatra.query.runtime.emf.EMFScope
import org.eclipse.viatra.transformation.runtime.emf.modelmanipulation.IModelManipulations
import org.eclipse.viatra.transformation.runtime.emf.modelmanipulation.SimpleModelManipulations
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRuleFactory
import org.eclipse.viatra.transformation.runtime.emf.transformation.batch.BatchTransformation
import org.eclipse.viatra.transformation.runtime.emf.transformation.batch.BatchTransformationStatements
import org.yakindu.base.types.Expression
import org.yakindu.sct.model.sgraph.EntryKind
import org.yakindu.sct.model.sgraph.Statechart
import org.yakindu.sct.model.stext.stext.EventDefinition
import org.yakindu.sct.model.stext.stext.EventSpec
import org.yakindu.sct.model.stext.stext.ReactionEffect
import org.yakindu.sct.model.stext.stext.ReactionTrigger
import org.yakindu.sct.model.stext.stext.TimeEventSpec
import org.yakindu.sct.model.stext.stext.TimeUnit
import org.yakindu.sct.model.stext.stext.VariableDefinition

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class YakinduToGammaTransformer {  
	// Transformation-related extensions
	extension BatchTransformation transformation
	extension BatchTransformationStatements statements
	
	// Transformation rule-related extensions
	extension BatchTransformationRuleFactory = new BatchTransformationRuleFactory
	extension IModelManipulations manipulation

	// Engine on the Yakindu resource 
	protected ViatraQueryEngine engine
	// Engine on the Genmodel resource 
	protected ViatraQueryEngine genmodelEngine
	// Runtime engine that fetches the local reactions (and other derived features)
	protected RunOnceQueryEngine runOnceEngine
	// Engine on the trace resource 
	protected ViatraQueryEngine traceEngine
	// Engine on the target resource (the created model)
	protected ViatraQueryEngine targetEngine
	
	// The Yakindu statechart compilation
	protected StatechartCompilation statechartCompilation
	// The Yakindu statechart to be transformed
	protected Statechart yakinduStatechart
	// Root element containing the traces
	protected Y2GTrace traceRoot
	// The root element of the Gamma statechart 
	protected Package gammaPackage
	// The statechart definition, it contains variables and regions 
	protected StatechartDefinition gammaStatechart
	
	// Packages of the metamodels
	final extension StatechartModelPackage stmPackage = StatechartModelPackage.eINSTANCE
	final extension InterfaceModelPackage ifPackage = InterfaceModelPackage.eINSTANCE
	final extension ActionModelPackage acPackage = ActionModelPackage.eINSTANCE
	final extension ExpressionModelPackage cmPackage = ExpressionModelPackage.eINSTANCE
	final extension TraceabilityPackage trPackage = TraceabilityPackage.eINSTANCE
	
	extension ExpressionTransformer expTransf
	
	var id = 0
	
	new(StatechartCompilation statechartCompilation) {
		val genmodel = statechartCompilation.eContainer as GenModel
		this.statechartCompilation = statechartCompilation
		this.yakinduStatechart = statechartCompilation.statechart
		val statechartName = (statechartCompilation.statechartName.empty) ?
				yakinduStatechart.name : statechartCompilation.statechartName.head
		val packageName = (statechartCompilation.packageName.empty) ?
				yakinduStatechart.name.toLowerCase : statechartCompilation.packageName.head.toLowerCase
		this.gammaStatechart = StatechartModelFactory.eINSTANCE.createSynchronousStatechartDefinition => [
			it.name = statechartName
			it.transitionPriority = TransitionPriority.ORDER_BASED // Yakindu models are always prioritized
		]
		this.gammaPackage = InterfaceModelFactory.eINSTANCE.createPackage => [
			it.name = packageName
			it.components += gammaStatechart
			it.imports += genmodel.packageImports.filter[it.components.empty]
		]
		this.traceRoot = TraceabilityFactory.eINSTANCE.createY2GTrace => [
			it.yakinduStatechart = yakinduStatechart
			it.gammaStatechart = gammaStatechart
		]
		// Create EMF scope and EMF IncQuery engine based on the resource
		val scope = new EMFScope(yakinduStatechart)
		this.engine = ViatraQueryEngine.on(scope)
		val resourceSet = genmodel.eResource.resourceSet
		val genmodelResourceSetScope = new EMFScope(resourceSet)
		this.genmodelEngine = ViatraQueryEngine.on(genmodelResourceSetScope)
		this.runOnceEngine = new RunOnceQueryEngine(yakinduStatechart)
		// Initializing an engine on the Trace resource too
		val traceScope = new EMFScope(traceRoot)
		this.traceEngine = ViatraQueryEngine.on(traceScope)
		val targetScope = new EMFScope(gammaPackage)
		this.targetEngine = ViatraQueryEngine.on(targetScope)
		// Create VIATRA model manipulations
		this.manipulation = new SimpleModelManipulations(engine)
		// Create VIATRA Batch transformation
		this.transformation = BatchTransformation.forEngine(engine).build
		// Initialize batch transformation statements
		this.statements = transformation.transformationStatements
		this.expTransf = new ExpressionTransformer(this.manipulation, this.statechartCompilation,
			this.traceRoot, this.traceEngine, this.genmodelEngine)
	}
	
	/**
	 * The entry point. This method executes the transformation.
	 */
	def execute() {
		statechartRule.fireAllCurrent
		topRegionRule.fireAllCurrent 
		compositeStateRegionRule
		entryNodesRule.fireAllCurrent
		simpleStatesRule.fireAllCurrent
		choicesRule.fireAllCurrent
		mergesRule.fireAllCurrent
		forksRule.fireAllCurrent
		joinsRule.fireAllCurrent
		finalStatesRule.fireAllCurrent
		finalStatesEndVariableRule
		exitNodesRule.fireAllCurrent
		transitionsRule.fireAllCurrent
		variablesRule.fireAllCurrent
		variableInitRule.fireAllCurrent
		// New ports are created here
		interfaceRule.fireAllCurrent
		eventsRule.fireAllCurrent
		localReactionsRule		
		createEndVariableGuards // All transitions have to be created before this call
		transitionEventTriggersRule.fireAllCurrent
		transitionDefaultTriggersRule.fireAllCurrent
		// The always event cannot be transformed, the following rule transforms them to any triggers
		transitionAlwaysTriggersRule.fireAllCurrent
		transitionTimeTriggersRule.fireAllCurrent
		transitionGuardsRule.fireAllCurrent
		transitionEffectsRule.fireAllCurrent
		entryEventsRule
		exitEventsRule
		// Then the triggers, valueof "triggers", guards and effects are transformed
		transformTriggersOfRegularLocalReactions
		transformTimedTriggersOfLocalReactions
		transformGuardsOfRegularLocalReactions
		transformEffectsOfRegularLocalReactions
		// Splitting choices with multiple incoming transitions
		splitChoicesRule.fireAllCurrent[it.choice.incomingTransitions.size > 1]
		// Sorting transitions in accordance with priority
		sortTransitions
		// The created EMF models are returned
		return new SimpleEntry<Package, Y2GTrace>(gammaPackage, traceRoot)
	}
	
	/**
	 * Responsible for mapping the Yakindu statechart to a Gamma statechart definition. 
	 * This rule assumes that the root elements of the EMF models exist.
	 * This rule should be fired first.
	 */
	val statechartRule = createRule(Statecharts.instance).action [
		// Creating the region trace
		for (yakinduAnnotation: yakinduStatechart.annotations) {
			val annotationType = yakinduAnnotation.type
			val annotationName = annotationType.name
			if (annotationName.equals("ChildFirstExecution")) {
				gammaStatechart.schedulingOrder = SchedulingOrder.BOTTOM_UP
			}
			else if (annotationName.equals("ParentFirstExecution")) {
				gammaStatechart.schedulingOrder = SchedulingOrder.TOP_DOWN
			}
		}
		addToTrace(it.statechart, #{yakinduStatechart, gammaStatechart}, trace)
	].build
	
	/**
	 * Responsible for mapping Yakindu top regions to Gamma top regions.
	 * This rule depends on statechartRule.
	 */
	val topRegionRule = createRule(TopRegions.instance).action [
		val yRegion = it.region
		val gammaStatechart = it.statechart.allValuesOfTo.filter(StatechartDefinition).head
		val gammaRegion = gammaStatechart.createChild(compositeElement_Regions, StatechartModelPackage.eINSTANCE.region) as Region
		gammaRegion.name = it.name.replaceAll(" ", "_")  	
		// Creating the region trace
		addToTrace(yRegion, #{gammaRegion}, trace)
	].build
	
	/**
	 * This method is responsible for transforming all the regions that are not top regions.
	 * This is not a VIATRA rule, since the order of the regions is not defined therefore the parent region of a containing state might not be present in the model when it is needed.
	 * This rule depends on the topRegionRule.
	 */
	private def compositeStateRegionRule() {
		val compositeStateRegionMatcher = engine.getMatcher(CompositeStateRegions.instance)
		val untransformedRegions = new HashSet<CompositeStateRegions.Match>(compositeStateRegionMatcher.allMatches)
		while (!untransformedRegions.isEmpty) {
			for (val iter = untransformedRegions.iterator; iter.hasNext; ) {
				val untransformedRegion = iter.next
				// If it is transformable, i.e. its composite state exists
				if (!untransformedRegion.parentRegion.getAllValuesOfTo.isEmpty) {
					// A single Gamma region is expected
					val gammaParentRegion = untransformedRegion.parentRegion.allValuesOfTo.filter(Region).head
					// The composite state is created in the Gamma model if it is not present already
					var State gammaState
					if (untransformedRegion.compositeState.allValuesOfTo.empty) {
						val newgammaState = gammaParentRegion.createChild(region_StateNodes, state) as State
						newgammaState.name = untransformedRegion.compositeStateName.replaceAll(" ", "_")
						// The trace is saved
						addToTrace(untransformedRegion.compositeState, #{newgammaState}, trace)
						// So final variables could be used in the lambda expression above
						gammaState = newgammaState 
					}
					else {
						gammaState = untransformedRegion.compositeState.allValuesOfTo.filter(State).head
					}
					// The subregion is created in the Gamma model
					val gammaSubregion = gammaState.createChild(compositeElement_Regions, region) as Region
					gammaSubregion.name = untransformedRegion.regionName.replaceAll(" ", "_")
					// The trace is saved
					addToTrace(untransformedRegion.subregion, #{gammaSubregion}, trace)
					// Removing the transformed match
					iter.remove
				}
				// If it is not transformable, an other turn is waited for the parent region to be created
			}
		}
	}
	
	/**
	 * This rule is responsible for mapping entry nodes of regions.
	 * It depends on the compositeStateRegionRule.
	 */
	val entryNodesRule = createRule(Entries.instance).action [
		val entry = it.entry
		// Creating the entry nodes in the corresponding Gamma region: only one match is expected
		val gammaRegion = it.parentRegion.getAllValuesOfTo.filter(Region).head
		var EntryState newGammaEntry
		switch (it.kind) {
			case EntryKind.INITIAL: 
				newGammaEntry = gammaRegion.createChild(region_StateNodes, initialState) as InitialState
			case EntryKind.SHALLOW_HISTORY: 
				newGammaEntry = gammaRegion.createChild(region_StateNodes, shallowHistoryState) as ShallowHistoryState
			case EntryKind.DEEP_HISTORY:
				newGammaEntry = gammaRegion.createChild(region_StateNodes, deepHistoryState) as DeepHistoryState
			default:
				throw new IllegalArgumentException("The entry kind is not known: " + it.kind) 
		}
		// The entry must have a name in the Gamma model
		if (entry.name.nullOrEmpty) {
			newGammaEntry.name = "Entry" + id++
		}
		else {
			newGammaEntry.name = entry.name
		}
		// The trace is saved
		addToTrace(entry, #{newGammaEntry}, trace)
	].build
	
	/**
	 * This rule is responsible for mapping simple states (not composite states) of regions.
	 * It depends on the compositeStateRegionRule.
	 */
	val simpleStatesRule = createRule(SimpleStates.instance).action [
		val simpleState = it.simpleState
		// Creating the state in the corresponding Gamma region
		val gammaRegion = it.parentRegion.getAllValuesOfTo.filter(Region).head
		val gammaState = gammaRegion.createChild(region_StateNodes, state) as State
		gammaState.name = it.stateName.replaceAll(" ", "_")
		// The trace is saved
		addToTrace(simpleState, #{gammaState}, trace)
	].build
	
	/**
	 * This rule is responsible for mapping choices of regions.
	 * It depends on the compositeStateRegionRule.
	 */
	val choicesRule = createRule(Choices.instance).action [
		val choice = it.choice
		// Creating the choice in the corresponding Gamma region
		val gammaRegion =  it.parentRegion.getAllValuesOfTo.filter(Region).head
		val gammaChoice = gammaRegion.createChild(region_StateNodes, choiceState) as ChoiceState
		// If the choice has a name, it is mapped
		if (choice.name.nullOrEmpty) {
			gammaChoice.name = "Choice" + id++
		}
		else {
			gammaChoice.name = choice.name
		}
		// The trace is saved 	
		addToTrace(choice, #{gammaChoice}, trace)
	].build
	
	/**
	 * This rule is responsible for splitting Gamma choices that have more than one incoming transitions.
	 * It depends on all rules that create transitions.
	 */
	val splitChoicesRule = createRule(Choices.instance).action [
		val choice = it.choice
		val gammaChoices = choice.allValuesOfTo.filter(ChoiceState)
		checkState(gammaChoices.size == 1)
		val gammaChoice = gammaChoices.head
		val gammaRegion =  gammaChoice.parentRegion
		val gammaMerge = gammaRegion.createChild(region_StateNodes, mergeState) as MergeState => [
			it.name = "Merge" + id++
		]
		// Retargeting incoming transitions
		for (incomingGammaTransition : gammaChoice.incomingTransitions) {
			incomingGammaTransition.targetState = gammaMerge
		}
		// Creating the new transition AFTER the retargeting (would not work otherwise)
		gammaMerge.createTransition(gammaChoice)
		// The trace is saved
		addToTrace(choice, #{gammaMerge}, trace)
	].build
	
	/**
	 * This rule is responsible for mapping merges of regions.
	 * It depends on the compositeStateRegionRule.
	 */
	val mergesRule = createRule(Merges.instance).action [
		val merge = it.merge
		// Creating the choice in the corresponding Gamma region
		val gammaRegion =  it.parentRegion.getAllValuesOfTo.filter(Region).head
		val gammaMerge = gammaRegion.createChild(region_StateNodes, mergeState) as MergeState
		// If the choice has a name, it is mapped
		if (merge.name.nullOrEmpty) {
			gammaMerge.name = "Merge" + id++
		}
		else {
			gammaMerge.name = merge.name
		}
		// The trace is saved 	
		addToTrace(merge, #{gammaMerge}, trace)
	].build
	
	/**
	 * This rule is responsible for mapping forks of regions.
	 * It depends on the compositeStateRegionRule.
	 */
	val forksRule = createRule(Forks.instance).action [
		val fork = it.fork
		// Creating the fork in the corresponding Gamma region
		val gammaRegion =  it.parentRegion.getAllValuesOfTo.filter(Region).head
		val gammaFork = gammaRegion.createChild(region_StateNodes, forkState) as ForkState
		// If the fork has a name, it is mapped
		if (fork.name.nullOrEmpty) {
			gammaFork.name = "Fork" + id++
		}
		else {
			gammaFork.name = fork.name
		}
		// The trace is saved 	
		addToTrace(fork, #{gammaFork}, trace)
	].build
	
	/**
	 * This rule is responsible for mapping joins of regions.
	 * It depends on the compositeStateRegionRule.
	 */
	val joinsRule = createRule(Joins.instance).action [
		val join = it.join
		// Creating the join in the corresponding Gamma region
		val gammaRegion =  it.parentRegion.getAllValuesOfTo.filter(Region).head
		val gammaJoin = gammaRegion.createChild(region_StateNodes, joinState) as JoinState
		// If the join has a name, it is mapped
		if (join.name.nullOrEmpty) {
			gammaJoin.name = "Join" + id++
		}
		else {
			gammaJoin.name = join.name
		}
		// The trace is saved 	
		addToTrace(join, #{gammaJoin}, trace)
	].build
	
	/**
	 * This rule is responsible for mapping final states of regions.
	 * It depends on the compositeStateRegionRule.
	 */
	val finalStatesRule = createRule(FinalStates.instance).action [
		val finalState = it.finalState
		// Creating the final state in the corresponding Gamma region
		val gammaRegion = it.parentRegion.getAllValuesOfTo.filter(Region).head
		val gammaFinalState = gammaRegion.createChild(region_StateNodes, state) as State
		// If the final states has a name, it is mapped
		gammaFinalState.name = "FinalState" + id++
		// The trace is saved
		addToTrace(finalState, #{gammaFinalState}, trace)
	].build
 
	/**
	 * Responsible for creating the "end" boolean variable for each statechart and creating
	 * an entry event of the gammaFinalState where the variable is set to false.
	 * It depends on finalStatesRule.
	 */
	private def finalStatesEndVariableRule() {
		var VariableDeclaration endVariable = null
		for (finalStateTopRegionMatch : engine.getMatcher(FinalStates.instance).allMatches) {
			//  The "end" variable is during for the first iteration
			if (endVariable === null) {
				endVariable = gammaStatechart.createChild(statechartDefinition_VariableDeclarations,
						variableDeclaration) as VariableDeclaration => [
					it.name = "end"
					it.createType("boolean")
				]
			}
			val gammaFinalState = finalStateTopRegionMatch.finalState.getAllValuesOfTo.filter(State).head
			// Creating and entry event of the Gamma final state that sets the "end" variable to false
			val variableDeclaration = endVariable
			gammaFinalState.createChild(state_EntryActions, assignmentStatement) as AssignmentStatement => [
				it.createChild(abstractAssignmentStatement_Lhs, directReferenceExpression) as DirectReferenceExpression => [
					it.declaration = variableDeclaration
				]
				it.createChild(assignmentStatement_Rhs, trueExpression)
			]
			// Now the Yakindu final state is mapped to and "end" variable too in addition to a Gamma State
			addToTrace(finalStateTopRegionMatch.finalState, #{variableDeclaration}, trace)
		}
	}
	
	/**
	 * This rule is responsible for mapping exit nodes of regions.
	 * It depends on all the rules that create nodes.
	 */
	val exitNodesRule = createRule(ExitNodeTransitions.instance).action [
		val incomingTransition = it.incomingTransition
		val exitNode = it.exitNode
		val defaultTransition = it.defaultTransition
		// If the exit node has more than one default transitions an exception is thrown
		if (engine.getMatcher(DefaultTransitionsOfExitNodes.instance)
					.countMatches(it.exitNode, null) !=  1) {
			throw new Exception("The following exit node has more than one default outgoing transition or not at all: " + it.exitNode)
		}
		// Creating the transition from the source to the target (the exit node does not appear in the Gamma model)
		// Getting the source and the target node
		val gammaSource = it.source.getAllValuesOfTo.filter(StateNode).head
		val gammaTarget = it.target.getAllValuesOfTo.filter(StateNode).head
		val gammaExitTransition = gammaSource.createTransition(gammaTarget)
		// The trace is saved : only rule where the multiplicity of "from" > 1
		traceRoot.createChild(y2GTrace_Traces, trace) => [
			addTo(trace_From, incomingTransition)
			addTo(trace_From, exitNode)
			addTo(trace_From, defaultTransition)
			addTo(trace_To, gammaExitTransition)
		]
	].build
	
	/**
	 * This rule is responsible for mapping transitions (apart from transitions of exit nodes).
	 * This rule depends on all the rules that create nodes.
	 */
	val transitionsRule = createRule(Transitions.instance).action [
		val gammaSource = it.source.getAllValuesOfTo.filter(StateNode).head
		val gammaTarget = it.target.getAllValuesOfTo.filter(StateNode).head
		// Creating the new transition
		val gammaTransition = gammaSource.createTransition(gammaTarget)
		// Creating the trace
		addToTrace(it.noExitTransition, #{gammaTransition}, trace)
	].build
	
	/**
	 * Responsible for creating a boolean variable "end" for each statechart that contains a final state.
	 * This rule depends on transitionsRule and localReactionsRule.
	 */
	private def createEndVariableGuards() {
		val finalState = engine.getMatcher(FinalStates.instance).allValuesOffinalState.head
		// If there are no final states in the model, guards are not needed
		if (finalState === null) {
			return
		}
		val endVariable = finalState.getAllValuesOfTo.filter(VariableDeclaration).head
		for (transition : targetEngine.getMatcher(NonEntryNonChoiceTransitions.instance).allValuesOftransition) {
			transition.createChild(transition_Guard, notExpression) as NotExpression => [
				it.createChild(unaryExpression_Operand, directReferenceExpression) as DirectReferenceExpression => [
					it.declaration = endVariable
				]
			]
		}
	}
	
	/**
	 * Responsible for placing the yExpressions onto the given edge. It is needed to ensure that final
	 * state variables are handled correctly (if they are present).
	 */
	private def transformGuard(Transition gammaTransition, Expression guard) {
		// If the reference is not null there is a final state in the statechart so "end" variable has to be referred in the guard
		if (gammaTransition.containsEndReference) {
			// Getting the old reference
			val endVariableReference = gammaTransition.eGet(transition_Guard) as NotExpression
			// Creating the new andExpression that will contain the new reference and the regular guard expression
			val andExpression = gammaTransition.createChild(transition_Guard, andExpression) as AndExpression => [
				it.operands.add(endVariableReference)
			]
			// This is the transformation of the regular Yakindu guard
			andExpression.transform(multiaryExpression_Operands, guard)
		}
		// If there is no final state, it is transformed regularly
		else {
			gammaTransition.transform(transition_Guard, guard)
		}
	}
	
	/**
	 * Returns whether the given edge contains and end variable.
	 */
	private def containsEndReference(Transition transition) {
		val finalState = engine.getMatcher(FinalStates.instance).allValuesOffinalState.head
		if (finalState === null) {
			return false
		}
		if (transition.eGet(transition_Guard) === null) {
			return false
		}
		if (!(transition.eGet(transition_Guard) instanceof NotExpression)) {
			return false
		}
		val notExpression = transition.eGet(transition_Guard) as NotExpression
		if (!(notExpression.operand instanceof ReferenceExpression)) {
			return false
		}
		val referenceExpression = notExpression.operand as DirectReferenceExpression
		val endVar =  finalState.getAllValuesOfTo.filter(VariableDeclaration).head
		if (referenceExpression.declaration != endVar) {
			return false
		}
		return true
	}
	
	/**
	 * This rule is responsible for mapping constants and plain variables.
	 * This rule depends on topRegionRule.
	 */	
	 val variablesRule = createRule(Variables.instance).action [
		var InitializableElement gammaVariable
		// If the Yakindu variable is a constant, a constantDeclaration is created
		if (it.isReadOnly) {
			gammaVariable = gammaPackage.createChild(expressionPackage_ConstantDeclarations, constantDeclaration) as ConstantDeclaration
			setVariable(it.variable, gammaVariable, it.name, it.type.name)
		}
		// Otherwise a plain variableDeclaration is created	in the statechart
		else { 
			val statechartDef = yakinduStatechart.getAllValuesOfTo.filter(StatechartDefinition).head 
			gammaVariable = statechartDef.createChild(statechartDefinition_VariableDeclarations,
					variableDeclaration) as VariableDeclaration
			setVariable(it.variable, gammaVariable, it.name, it.type.name)
		}
	].build
	
	/**
	 * Responsible for initializing the created gammaVariables. Used to avoid code duplication.
	 */
	private def setVariable(VariableDefinition yVariable, InitializableElement gammaVariable, String name, String typeName) {
		gammaVariable.name = name
		// The type is created by the createType method
		gammaVariable.createType(typeName)
		addToTrace(yVariable, #{gammaVariable}, trace)
	}
	
	/**
	 * Creates a Type child of the given container depending on the typeName parameter.
	 */
	private def createType(EObject typeContainer, String typeName) {
		switch (typeName) {
			case "integer": 
				typeContainer.createChild(declaration_Type, integerTypeDefinition)
			case "string":
				typeContainer.createChild(declaration_Type, integerTypeDefinition)
			case "real":
				typeContainer.createChild(declaration_Type, decimalTypeDefinition)
			case "boolean":
				typeContainer.createChild(declaration_Type, booleanTypeDefinition)
		}
	}
	
	 /**
	 * This rule is responsible for initializing the variables with initialization in the Yakindu model.
	 * This rule depends on variablesRule.
	 */ 
	val variableInitRule = createRule(VariableInits.instance).action [
		val yVariable = it.variable
		for (gammaVariable : yVariable.getAllValuesOfTo.filter(InitializableElement)) {
			gammaVariable.transform(initializableElement_Expression, yVariable.initialValue)
			// The trace is created by the Expression Transformer
		}
	].build
	
	/**
	 * This rule is responsible for transforming guard expressions of transitions.
	 * This rule depends on transitionsRule, variablesRule and transitionValueOfTriggersRule.
	 */
	val transitionGuardsRule = createRule(TransitionsWithGuards.instance).action [
		val gammaTransition = it.transition.getAllValuesOfTo.filter(Transition).head
		gammaTransition.transformGuard(it.expression)
		// The trace is created by the ExpressionTransformer
	].build
	
	/**
	 * This rule is responsible for transforming Yakindu interfaces with events to Ports with interfaces and events.
	 * This rule depends on topRegionRule.
	 */
	val interfaceRule = createRule(Interfaces.instance).action [
		val yInterface = it.interface
		val mappingMatches = InterfaceToInterface.Matcher.on(genmodelEngine).getAllMatches(null, yInterface, null, null)
		if (mappingMatches.size == 0) {  
			Logger.getLogger("GammaLogger").log(Level.WARNING, yInterface.name + " is not mapped to any Gamma interfaces. This is acceptable if it does not contain any events. Event count: " + yInterface.events.size + ".")
			return
		}
		// Validation
		if (yInterface.name === null) {
			throw new IllegalArgumentException("The interface must have a name! " + yInterface)
		}
		// Connecting it to the statechart through a port
		if (gammaPackage.components.size != 1) {
			throw new IllegalArgumentException("More than one statechart declarations: " + gammaPackage.components)
		}
		if (mappingMatches.size > 1) {
			throw new IllegalArgumentException("Yakindu interface mapped to more than one Gamma interface: " + mappingMatches.size)
		}
		// Starting the transformation
		val statechartComponent = gammaPackage.components.head
		val port = statechartComponent.createChild(component_Ports, port) as Port => [
			it.name = yInterface.name
		]
		val mappingMatch = mappingMatches.head
		port.createChild(port_InterfaceRealization, interfaceRealization) as InterfaceRealization => [
			it.realizationMode = mappingMatch.realizationMode
			it.interface = mappingMatch.gammaIf
		]
		// Creating the trace
		addToTrace(yInterface, #{port}, trace)
	].build
	
	val eventsRule = createRule(Events.instance).action [
		val gammaEvent = it.event.gammaEvent
		// Creating the trace
		addToTrace(it.event, #{gammaEvent}, trace)
	].build
	
	/**
	 * This rule is responsible for transforming event triggers of transitions.
	 * This rule depends on transitionsRule and eventsRule.
	 */
	val transitionEventTriggersRule = createRule(TransitionsWithEventTriggers.instance).action [
		val yEvent = it.event
		val yTrigger = it.trigger
		val transitions = it.transition.getAllValuesOfTo.filter(Transition)
		if (transitions.size != 1) {
			throw new IllegalArgumentException("More than one transitions!")
		}
		val transition = transitions.head
		transition.transformRegularTrigger(yEvent, yTrigger)
	].build
	
	/**
	 * Transforms Yakindu triggers (regular EventSpecs) to Gamma EventTriggers, places onto the given transition then saves it in a trace.
	 */
	private def void transformRegularTrigger(Transition transition, EventDefinition yEvent, EventSpec yTrigger) {
		val gammaEvent = yEvent.gammaEvent
		// Transforming the trigger, the Yakindu interface that is mapped to Gamma Port is transformed too
		val gPort = yEvent.gammaPort
		// If multiple triggers are on the transition
		val gTrigger = transition.trigger
		var EventTrigger gEventTrigger
		if (gTrigger !== null) {
			// The transition already has a trigger
			val binaryTrigger = transition.createChild(transition_Trigger, binaryTrigger) as BinaryTrigger => [
				it.leftOperand = gTrigger
				it.type = BinaryType.OR
				it.rightOperand = it.createChild(binaryTrigger_RightOperand, eventTrigger) as EventTrigger => [
					it.eventReference = it.createChild(eventTrigger_EventReference, portEventReference) as PortEventReference => [
						it.port = gPort
						it.event = gammaEvent
					]
				]
			]
			gEventTrigger = binaryTrigger.rightOperand as EventTrigger
		}
		else {
			// This is the first trigger of the transition
			gEventTrigger = transition.createChild(transition_Trigger, eventTrigger) as EventTrigger => [
				it.eventReference = it.createChild(eventTrigger_EventReference, portEventReference) as PortEventReference => [
					it.port = gPort
					it.event = gammaEvent
				]
			]
		}
		// Creating the trace
		addToTrace(yTrigger, #{gEventTrigger}, trace)
	}
	
	/**
	 * This rule is responsible for transforming always triggers of transitions.
	 * This rule depends on transitionsRule and eventsRule.
	 */
	val transitionAlwaysTriggersRule = createRule(TransitionsWithAlwaysTriggers.instance).action [
		val yTrigger = it.trigger
		val gammaTransition = it.transition.getAllValuesOfTo.filter(Transition).head
		if (gammaTransition.trigger !== null) {
			throw new IllegalArgumentException("The following transition already has a trigger: " + gammaTransition)
		}
		val onCycleTrigger = gammaTransition.createChild(transition_Trigger, onCycleTrigger)
		// Creating the trace
		addToTrace(yTrigger, #{onCycleTrigger}, trace)
	].build
	
	/**
	 * This rule is responsible for transforming default triggers of transitions.
	 * This rule depends on transitionsRule and eventsRule.
	 */
	val transitionDefaultTriggersRule = createRule(TransitionsWithDefaultTriggers.instance).action [
		val yTrigger = it.trigger
		val gammaTransition = it.transition.getAllValuesOfTo.filter(Transition).head
		if (gammaTransition.trigger !== null && gammaTransition.guard !== null) {
			throw new IllegalArgumentException("The following transition already has a trigger or a guard: " + gammaTransition)
		}
		val elseExpression = gammaTransition.createChild(transition_Guard, elseExpression)
		// Creating the trace
		addToTrace(yTrigger, #{elseExpression}, trace)
	].build

	/**
	 * This rule is responsible for transforming time triggers (after 1 s) of transitions.
	 * This rule depends on transitionsRule.
	 */
	val transitionTimeTriggersRule = createRule(TransitionsWithTimeTriggers.instance).action [
		val gammaTransition = it.transition.getAllValuesOfTo.filter(Transition).head
		val gammaState = it.source.getAllValuesOfTo.filter(State).head
		gammaTransition.transformTimedTrigger(gammaState, it.expression, it.trigger, it.unit)
	].build
	
	/**
	 * Responsible for creating a TimeoutDeclaration in the top region (top ancestor) of the given gammaTransition,
	 * creating an entry event in the given gammaState that sets the timer to the value given in yExpression (it has to be transformed first),
	 * placing a TimeoutEvent onto the given gammaTransition and creating a trace from the given TimeEventSpec to gammaTimeoutVariable, gammaEntryEvent, gammaTimeTrigger.
	 */
	private def transformTimedTrigger(Transition gammaTransition, State gammaState, Expression yExpression, TimeEventSpec yTrigger, TimeUnit timeUnit) {
		// Creating a Gamma TimeoutDeclaration for this particular trigger
		val gammaTimeoutVariable = gammaStatechart.createChild(statechartDefinition_TimeoutDeclarations,
				timeoutDeclaration) as TimeoutDeclaration => [
			it.name = gammaState.name + "Timeout" + id++ // A more special name is needed, hence the id
		]
		// Creating the entry event that initializes the timer
		val gammaEntryEvent = gammaState.createChild(state_EntryActions, setTimeoutAction) as SetTimeoutAction => [
			it.timeoutDeclaration = gammaTimeoutVariable
			it.createChild(setTimeoutAction_Time, timeSpecification) as TimeSpecification => [
				it.transform(timeSpecification_Value, yExpression)
				it.unit = switch (timeUnit) {
					case SECOND:
						hu.bme.mit.gamma.statechart.interface_.TimeUnit.SECOND
					case MILLISECOND:
						hu.bme.mit.gamma.statechart.interface_.TimeUnit.MILLISECOND
					case MICROSECOND:
						hu.bme.mit.gamma.statechart.interface_.TimeUnit.MICROSECOND
					case NANOSECOND:
						hu.bme.mit.gamma.statechart.interface_.TimeUnit.NANOSECOND
					default: 
						throw new IllegalArgumentException("Only second and millisecond are supported!")
				}
			]
		]
		val gammaTrigger = gammaTransition.trigger
		var Trigger gammaTimeTrigger
		if (gammaTrigger !== null) {
			// The transition already has a trigger
			val binaryTrigger = gammaTransition.createChild(transition_Trigger, binaryTrigger) as BinaryTrigger => [
				it.leftOperand = gammaTrigger
				it.type = BinaryType.OR
				it.rightOperand = it.createChild(binaryTrigger_RightOperand, eventTrigger) as EventTrigger => [
					it.createChild(eventTrigger_EventReference, timeoutEventReference) as TimeoutEventReference => [
						it.timeout = gammaTimeoutVariable
					]
				]
			]
			gammaTimeTrigger = binaryTrigger.rightOperand as EventTrigger
		}
		else {
			// This is the first trigger of the transition
			gammaTimeTrigger = gammaTransition.createChild(transition_Trigger, eventTrigger) as EventTrigger => [
				it.createChild(eventTrigger_EventReference, timeoutEventReference) as TimeoutEventReference => [
					it.timeout = gammaTimeoutVariable
				]
			]
		}
		// Creating the trace
		addToTrace(yTrigger, #{gammaTimeoutVariable, gammaEntryEvent, gammaTimeTrigger}, trace)
	}
	
	/**
	 * This rule is responsible for transforming effects (assignment expression and raising expression) of transitions.
	 * This rule depends on transitionsRule, variablesRule and eventsRule
	 */
	val transitionEffectsRule = createRule(TransitionsWithEffect.instance).action [
		val gammaTransition = it.transition.getAllValuesOfTo.filter(Transition).head
		for (action : (it.transition.effect as ReactionEffect).actions) {
			// For loop is needed as VIATRA returns matches (and thus, actions) in a nondeterministic order
			gammaTransition.transform(transition_Effects, action)
		}
		// The trace is created by the ExpressionTransformer
	].build
	
	/**
	 * This rule is responsible for transforming entry events of states.
	 * This rule depends on simpleStatesRule, variablesRule and eventsRule.
	 */
	private def entryEventsRule() {
		for (stateEntryMatch : runOnceEngine.getAllMatches(StatesWithEntryEvents.instance)) {
			val gammaState = stateEntryMatch.state.getAllValuesOfTo.filter(State).head
			for (action : stateEntryMatch.reactionEffect.actions) {
				// For loop is needed as VIATRA returns matches (and thus, actions) in a nondeterministic order
				gammaState.transform(state_EntryActions, action)
				// The trace is created by the ExpressionTransformer
			}
		}
	}
	
	/**
	 * This rule is responsible for transforming exit events of states.
	 * This rule depends on simpleStatesRule, variablesRule and eventsRule.
	 */
	private def exitEventsRule() {
		for (stateExitMatch : runOnceEngine.getAllMatches(StatesWithExitEvents.instance)) {
			val gammaState = stateExitMatch.state.getAllValuesOfTo.filter(State).head
			for (action : stateExitMatch.reactionEffect.actions) {
				// For loop is needed as VIATRA returns matches (and thus, actions) in a nondeterministic order
				gammaState.transform(state_ExitActions, action)
				// The trace is created by the ExpressionTransformer
			}
		}
	}
	
	/**
	 * This rule is responsible for transforming local reactions of states: trigger [guard] / action.
	 * A loop transition transition is created for each non-entry or exit local reaction of a simple state. 
	 * This rule depends on simpleStatesRule, variablesRule and eventsRule.
	 */
	private def localReactionsRule() {
		for (localReaction : runOnceEngine.getAllMatches(StatesWithRegularLocalReactions.instance)) {
			var State localReactionState
			var State localReactionStateTarget
			// If the state with local reaction has entry or exit events or it is a composite state, a new subregion with a state and a loop transition has to be created
//			if (localReaction.state.hasEntryEvent || localReaction.state.hasExitEvent || localReaction.state.composite) {
				val gammaState = localReaction.state.getAllValuesOfTo.filter(State).head
				val localReactionRegion = gammaState.createChild(compositeElement_Regions, region) as Region
				localReactionRegion.name = "localReactionRegion" + id
				val localReactionInit = localReactionRegion.createChild(region_StateNodes, initialState) as InitialState
					localReactionInit.name = "Entry" + id
				localReactionState = localReactionRegion.createChild(region_StateNodes, state) as State
					localReactionState.name = "LocalReactionState" + id
				id++
				// This transition leads to the local reaction state from the initial node
				val localReactionInitTransition = localReactionInit.createTransition(localReactionState)
				addToTrace(localReaction.reaction, #{localReactionRegion, localReactionInit,
					localReactionState, localReactionInitTransition}, trace)
//			}
			/* DEPRECATED: if a state has multiple local reactions, all of them can fire in a single cycle, 
			which contradicts the semantics of transitions where only one of them fires.*/
			// Otherwise a simple loop transition is enough
//			else {
//				localReactionState = localReaction.state.getAllValuesOfTo.filter(State).head
//			}

			localReactionStateTarget = localReactionState // Default
			val localReactionTrigger = localReaction.reaction.trigger
			if (localReactionTrigger instanceof ReactionTrigger) {
				val triggerList = localReactionTrigger.triggers
				checkState(triggerList.size == 1)
				val trigger = triggerList.head
				if (trigger instanceof TimeEventSpec) {
					// If it is an "after N s" trigger, we create another state
					localReactionStateTarget = localReactionRegion.createChild(region_StateNodes, state) as State
					localReactionStateTarget.name = "LocalReactionState" + id++
				}
			}
			
			// This this the loop transition that will contain the (action [guard] / effect) of the local reaction
			val localReactionTransition = localReactionState.createTransition(localReactionStateTarget)
			
			// The most important part of the trace
			addToTrace(localReaction.reaction, #{localReactionTransition}, trace)
		}
	}
	
	/**
	 * Creates a transition with the given source and target.
	 */
	private def Transition createTransition(StateNode source, StateNode target) {
		val transition = gammaStatechart.createChild(statechartDefinition_Transitions, transition) as Transition => [
			it.sourceState = source
			it.targetState = target
		]   
		return transition
	}
	
	/**
	 * Transforms the triggers of regular local reactions.
	 * This rule depends on localReactionsRule.
	 */
	private def transformTriggersOfRegularLocalReactions() {
		for (localReactionTrigger : runOnceEngine.getAllMatches(TriggersOfRegularLocalReactions.instance)) {
			// Filtering is important, so the right edge is fetched from the trace
			val gammaTransition = localReactionTrigger.reaction.getAllValuesOfTo
				.filter(Transition)
				.filter[it.sourceState instanceof State &&
					it.targetState instanceof State]
				.head
			transformRegularTrigger(gammaTransition, localReactionTrigger.event,
				localReactionTrigger.trigger)
			// The trace is created by the transformTimedTrigger
		}
	}
	
	/**
	 * Transforms the timed triggers of regular local reactions.
	 * This rule depends on localReactionsRule.
	 */
	private def transformTimedTriggersOfLocalReactions() {
		for (localReactionTrigger : runOnceEngine.getAllMatches(TriggersOfTimedLocalReactions.instance)) {
			// Filtering is important, so the right edge is fetched from the trace
			val gammaTransition = localReactionTrigger.reaction.getAllValuesOfTo
				.filter(Transition)
				.filter[it.sourceState instanceof State &&
					it.targetState instanceof State]
				.head
			val gammaState = gammaTransition.sourceState as State
			transformTimedTrigger(gammaTransition, gammaState, localReactionTrigger.event,
				localReactionTrigger.timeTrigger, localReactionTrigger.unit)
			// The trace is created by the transformTimedTrigger
		}
	}
	
	/**
	 * Transforms the guards of regular local reactions.
	 * This rule depends on localReactionsRule.
	 */
	private def transformGuardsOfRegularLocalReactions() {
		for (localReactionGuard : runOnceEngine.getAllMatches(GuardsOfRegularLocalReactions.instance)) {
			// Filtering is important, so the right edge is fetched from the trace
			val gammaTransition = localReactionGuard.reaction.getAllValuesOfTo
				.filter(Transition)
				.filter[it.sourceState instanceof State &&
					it.targetState instanceof State]
				.head
			gammaTransition.transformGuard(localReactionGuard.expression)
			// The trace is created by the ExpressionTransformer
		}
	}
	
	/**
	 * Transforms the actions of regular local reactions.
	 * This rule depends on localReactionsRule.
	 */
	private def transformEffectsOfRegularLocalReactions() {
		for (localReactionAction : runOnceEngine.getAllMatches(ActionsOfRegularLocalReactions.instance)) {
			// Filtering is important, so the right edge is fetched from the trace
			val gammaTransition = localReactionAction.reaction.getAllValuesOfTo
				.filter(Transition)
				.filter[it.sourceState instanceof State &&
					it.targetState instanceof State]
				.head
			for (action : localReactionAction.reactionEffect.actions) {
				// For loop is needed as VIATRA returns matches (and thus, actions) in a nondeterministic order
				gammaTransition.transform(transition_Effects, action)
				// The trace is created by the ExpressionTransformer
			}
		}
	}
	
	/**
	 * Sorts the transitions in accordance with 1) their priorities and 2) the names of their sources.
	 */
	protected def sortTransitions() {
		val transitionList = newArrayList
		transitionList += gammaStatechart.transitions
		transitionList.sort[lhs, rhs |
			val lhsYakinduTransition = lhs.allValuesOfFrom.filter(org.yakindu.sct.model.sgraph.Transition).head
			// Check transitions of local reactions (they are not mapped from a transition)
			if (lhsYakinduTransition !== null) {
				val lhsSource = lhsYakinduTransition.source
				val lhsPriority = lhsSource.outgoingTransitions.indexOf(lhsYakinduTransition)
				val rhsYakinduTransition = rhs.allValuesOfFrom.filter(org.yakindu.sct.model.sgraph.Transition).head
				if (rhsYakinduTransition !== null) {
					val rhsSource = rhsYakinduTransition.source
					val rhsPriority = rhsSource.outgoingTransitions.indexOf(rhsYakinduTransition)
					if (lhsSource == rhsSource) {
						// Sorting according to priority
						lhsPriority.compareTo(rhsPriority)
					}
					else {
						// Sorting according to source name
						lhs.sourceState.name.compareTo(rhs.sourceState.name)
					}
				}
			}
		]
		gammaStatechart.transitions.clear
		gammaStatechart.transitions += transitionList
	}
	
	def dispose() {
		if (transformation !== null) {
			transformation.dispose
		}
		genmodelEngine = null
		runOnceEngine = null
		traceEngine = null
		targetEngine = null
		transformation = null
		return
	}
	
}
