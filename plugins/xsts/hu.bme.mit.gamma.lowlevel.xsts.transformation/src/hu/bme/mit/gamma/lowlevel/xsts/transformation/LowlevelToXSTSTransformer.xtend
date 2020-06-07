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
package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.EventParameterComparisons
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.Events
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.FirstChoiceStates
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.FirstForkStates
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.InEvents
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.LastJoinStates
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.LastMergeStates
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.OutEvents
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.PlainVariables
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.ReferredEvents
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.ReferredVariables
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.RegionVariableGroups
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.Regions
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.SimpleTransitionsBetweenStates
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.SimpleTransitionsToEntryStates
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.Statecharts
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.Subregions
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.Timeouts
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.TopRegions
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.TypeDeclarations
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.Variables
import hu.bme.mit.gamma.lowlevel.xsts.transformation.traceability.L2STrace
import hu.bme.mit.gamma.statechart.lowlevel.model.ChoiceState
import hu.bme.mit.gamma.statechart.lowlevel.model.CompositeElement
import hu.bme.mit.gamma.statechart.lowlevel.model.EventDeclaration
import hu.bme.mit.gamma.statechart.lowlevel.model.EventDirection
import hu.bme.mit.gamma.statechart.lowlevel.model.ForkState
import hu.bme.mit.gamma.statechart.lowlevel.model.JoinState
import hu.bme.mit.gamma.statechart.lowlevel.model.MergeState
import hu.bme.mit.gamma.statechart.lowlevel.model.Package
import hu.bme.mit.gamma.statechart.lowlevel.model.Persistency
import hu.bme.mit.gamma.statechart.lowlevel.model.Region
import hu.bme.mit.gamma.statechart.lowlevel.model.State
import hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition
import hu.bme.mit.gamma.xsts.model.model.CompositeAction
import hu.bme.mit.gamma.xsts.model.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.model.VariableGroup
import hu.bme.mit.gamma.xsts.model.model.XSTS
import hu.bme.mit.gamma.xsts.model.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.model.util.XSTSActionUtil
import java.util.AbstractMap.SimpleEntry
import java.util.Set
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.emf.EMFScope
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRule
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRuleFactory
import org.eclipse.viatra.transformation.runtime.emf.transformation.batch.BatchTransformation
import org.eclipse.viatra.transformation.runtime.emf.transformation.batch.BatchTransformationStatements

import static com.google.common.base.Preconditions.checkArgument
import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.lowlevel.model.derivedfeatures.LowlevelStatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*

class LowlevelToXSTSTransformer {
	// Transformation-related extensions
	extension BatchTransformation transformation
	extension BatchTransformationStatements statements
	// Transformation rule-related extensions
	final extension BatchTransformationRuleFactory = new BatchTransformationRuleFactory
	// Auxiliary objects
	protected final extension XSTSActionUtil actionFactory = new XSTSActionUtil
	protected final extension ExpressionUtil expressionUtil = new ExpressionUtil
	protected final extension ReadWrittenVariableLocator variableLocator = new ReadWrittenVariableLocator
	protected final extension ActionOptimizer actionSimplifier = new ActionOptimizer
	protected final extension VariableGroupRetriever variableGroupRetriever = new VariableGroupRetriever
	protected final extension PseudoStateHandler pseudoStateHandler
	protected final extension RegionActivator regionActivator
	protected final extension EntryActionRetriever entryActionRetriever
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension LowlevelTransitionToActionTransformer lowlevelTransitionToActionTransformer
	protected final extension SimpleTransitionToXTransitionTransformer simpleTransitionToActionTransformer
	protected final extension PrecursoryTransitionToXTransitionTransformer precursoryTransitionToXTransitionTransformer
	protected final extension TerminalTransitionToXTransitionTransformer terminalTransitionToXTransitionTransformer
	protected final extension TransitionPreconditionCreator transitionPreconditionCreator
	// Model factories
	protected final extension XSTSModelFactory factory = XSTSModelFactory.eINSTANCE
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	// VIATRA engines
	protected ViatraQueryEngine engine
	protected ViatraQueryEngine targetEngine
	// Trace object for handling the tracing
	protected Trace trace
	// EMF models
	protected final Package _package
	protected final XSTS xSts
	// VIATRA rules
	protected BatchTransformationRule<TypeDeclarations.Match, TypeDeclarations.Matcher> typeDeclarationsRule
	protected BatchTransformationRule<Events.Match, Events.Matcher> eventsRule
	protected BatchTransformationRule<TopRegions.Match, TopRegions.Matcher> topRegionsRule
	protected BatchTransformationRule<Subregions.Match, Subregions.Matcher> subregionsRule
	protected BatchTransformationRule<Statecharts.Match, Statecharts.Matcher> componentParametersRule
	protected BatchTransformationRule<PlainVariables.Match, PlainVariables.Matcher> plainVariablesRule
	protected BatchTransformationRule<Timeouts.Match, Timeouts.Matcher> timeoutsRule
	protected BatchTransformationRule<Variables.Match, Variables.Matcher> variableInitializationsRule
	protected BatchTransformationRule<Statecharts.Match, Statecharts.Matcher> topRegionInitializationRule
	protected BatchTransformationRule<SimpleTransitionsBetweenStates.Match, SimpleTransitionsBetweenStates.Matcher> simpleTransitionBetweenStatesRule
	protected BatchTransformationRule<SimpleTransitionsToEntryStates.Match, SimpleTransitionsToEntryStates.Matcher> simpleTransitionsToHistoryStatesRule
	protected BatchTransformationRule<LastJoinStates.Match, LastJoinStates.Matcher> lastJoinTransitionsRule
	protected BatchTransformationRule<LastMergeStates.Match, LastMergeStates.Matcher> lastMergeTransitionsRule
	protected BatchTransformationRule<FirstForkStates.Match, FirstForkStates.Matcher> firstForkTransitionsRule
	protected BatchTransformationRule<FirstChoiceStates.Match, FirstChoiceStates.Matcher> firstChoiceTransitionsRule
	protected BatchTransformationRule<InEvents.Match, InEvents.Matcher> inEventEnvironmentalActionRule
	protected BatchTransformationRule<OutEvents.Match, OutEvents.Matcher> outEventEnvironmentalActionRule
	// Optimization
	protected boolean optimize
	protected Set<EventDeclaration> referredEvents
	protected Set<VariableDeclaration> referredVariables
	
	
	new(Package _package) {
		this(_package, false)
	}
	
	new(Package _package, boolean optimize) {
		this._package = _package
		// Note: we do not expect cross references to other resources
		this.engine = ViatraQueryEngine.on(new EMFScope(_package))
		this.xSts = createXSTS => [
			it.name = _package.name
		]
		this.targetEngine = ViatraQueryEngine.on(new EMFScope(this.xSts))
		this.trace = new Trace(_package, xSts)
		// The transformers need the trace model for the variable mapping
		this.regionActivator = new RegionActivator(this.engine, this.trace)
		this.entryActionRetriever = new EntryActionRetriever(this.trace)
		this.expressionTransformer = new ExpressionTransformer(this.trace)
		this.pseudoStateHandler = new PseudoStateHandler(this.engine)
		this.lowlevelTransitionToActionTransformer = new LowlevelTransitionToActionTransformer(
			this.engine, this.trace)
		this.simpleTransitionToActionTransformer = new SimpleTransitionToXTransitionTransformer(
			this.engine, this.trace)
		this.precursoryTransitionToXTransitionTransformer = new PrecursoryTransitionToXTransitionTransformer(
			this.engine, this.trace)
		this.terminalTransitionToXTransitionTransformer = new TerminalTransitionToXTransitionTransformer(
			this.engine, this.trace)
		this.transitionPreconditionCreator = new TransitionPreconditionCreator(this.trace)
		this.transformation = BatchTransformation.forEngine(engine).build
		this.statements = transformation.transformationStatements
		this.optimize = optimize
		if (optimize) {
			this.referredEvents = ReferredEvents.Matcher.on(engine).allValuesOfevent
			this.referredVariables = ReferredVariables.Matcher.on(engine).allValuesOfvariable
		}
	}

	def execute() {
		getTypeDeclarationsRule.fireAllCurrent
		getEventsRule.fireAllCurrent
		getTopRegionsRule.fireAllCurrent
		while (!allRegionsTransformed) {
			// Transforming subregions one by one in accordance with containment hierarchy
			getSubregionsRule.fireAllCurrent[!trace.isTraced(it.region) && trace.isTraced(it.parentRegion)]
		}
		getComponentParametersRule.fireAllCurrent
		getTimeoutsRule.fireAllCurrent
		// Event variables, parameters and timeouts are transformed already
		getPlainVariablesRule.fireAllCurrent
		/* By now all variables must be transformed so the expressions and actions can be transformed
		 * correctly with the trace model */
		getVariableInitializationsRule.fireAllCurrent
		initializeVariableInitializingAction // After getVariableInitializationsRule, but before getTopRegionsInitializationRule
		getTopRegionsInitializationRule.fireAllCurrent // Setting the top region (variables) into their initial states
		getSimpleTransitionsBetweenStatesRule.fireAllCurrent
		getSimpleTransitionsToHistoryStatesRule.fireAllCurrent
		getLastJoinTransitionsRule.fireAllCurrent
		getLastMergeTransitionsRule.fireAllCurrent
		getFirstForkTransitionsRule.fireAllCurrent
		getFirstChoiceTransitionsRule.fireAllCurrent
		getInEventEnvironmentalActionRule.fireAllCurrent
		getOutEventEnvironmentalActionRule.fireAllCurrent
		mergeTransitions
		optimizeActions
		// The created EMF models are returned
		return new SimpleEntry<XSTS, L2STrace>(xSts, trace.getTrace)
	}
	
	protected def isNotOptimizable(EventDeclaration lowlevelEvent) {
		return !optimize || referredEvents.contains(lowlevelEvent)
	}
	
	protected def isNotOptimizable(VariableDeclaration lowlevelVariable) {
		return !optimize || referredVariables.contains(lowlevelVariable)
	}
		
	protected def getVariableInitializingAction() {
		if (xSts.variableInitializingAction === null) {
			xSts.variableInitializingAction = createSequentialAction
		}
		return xSts.variableInitializingAction
	}
	
	protected def getConfigurationInitializingAction() {
		if (xSts.configurationInitializingAction === null) {
			xSts.configurationInitializingAction = createSequentialAction
		}
		return xSts.configurationInitializingAction
	}
	
	protected def getEntryEventAction() {
		if (xSts.entryEventAction === null) {
			xSts.entryEventAction = createSequentialAction
		}
		return xSts.entryEventAction
	}
	
	protected def getInEventAction() {
		if (xSts.inEventAction === null) {
			xSts.inEventAction = createSequentialAction
		}
		return xSts.inEventAction
	}
	
	protected def getOutEventAction() {
		if (xSts.outEventAction === null) {
			xSts.outEventAction = createSequentialAction
		}
		return xSts.outEventAction
	}

	protected def getTypeDeclarationsRule() {
		if (typeDeclarationsRule === null) {
			typeDeclarationsRule = createRule(TypeDeclarations.instance).action [
				val lowlevelTypeDeclaration = it.typeDeclaration
				val xStsTypeDeclaration = lowlevelTypeDeclaration.clone
				xSts.typeDeclarations += xStsTypeDeclaration
				xSts.publicTypeDeclarations += xStsTypeDeclaration
				trace.put(lowlevelTypeDeclaration, xStsTypeDeclaration)
			].build
		}
		return typeDeclarationsRule
	}

	/**
	 * For the transformation of all subregions.
	 */
	protected def boolean allRegionsTransformed() {
		return Regions.Matcher.on(engine).allValuesOfregion.forall[trace.isTraced(it)]
	}

	protected def getEventsRule() {
		if (eventsRule === null) {
			eventsRule = createRule(Events.instance).action [
				val lowlevelEvent = it.event
				if (lowlevelEvent.notOptimizable) {
					val xStsEventVariable = createVariableDeclaration => [
						it.name = lowlevelEvent.name.eventName
						it.type = createBooleanTypeDefinition // isRaised bool variable
					]
					xSts.variableDeclarations += xStsEventVariable // Target model modification
					val eventVariableGroup = if (lowlevelEvent.direction == EventDirection.IN) {
						xSts.inEventVariableGroup
					} else {
						xSts.outEventVariableGroup
					}
					eventVariableGroup.variables += xStsEventVariable // Variable group modification
					trace.put(lowlevelEvent, xStsEventVariable) // Tracing event
					trace.put(lowlevelEvent.isRaised, xStsEventVariable) // Tracing the contained isRaisedVariable
					// Parameters 
					for (lowlevelEventParameter : lowlevelEvent.parameters) {
						val xStsParam = createVariableDeclaration => [
							it.name = lowlevelEventParameter.name.variableName
							it.type = lowlevelEventParameter.type.transformType
						]
						val eventParameterVariableGroup = if (lowlevelEvent.direction == EventDirection.IN) {
							xSts.inEventParameterVariableGroup
						} else {
							xSts.outEventParameterVariableGroup
						}
						xSts.variableDeclarations += xStsParam // Target model modification
						if (lowlevelEvent.persistency == Persistency.TRANSIENT) {
							// If event is transient, than its parameters are marked transient variables
							xSts.transientVariables += xStsParam
						}
						eventParameterVariableGroup.variables += xStsParam
						trace.put(lowlevelEventParameter, xStsParam) // Tracing
					}
				}
			].build
		}
		return eventsRule
	}

	protected def getTopRegionsRule() {
		if (topRegionsRule === null) {
			topRegionsRule = createRule(TopRegions.instance).action [
				val lowlevelRegion = it.region
				lowlevelRegion.createRegionMapping
			].build
		}
		return topRegionsRule
	}

	protected def getTopRegionsInitializationRule() {
		if (topRegionInitializationRule === null) {
			topRegionInitializationRule = createRule(Statecharts.instance).action [
				val lowlevelStatechart = it.statechart
				val regionInitializingAction = createParallelAction // Each region at the same time
				configurationInitializingAction as CompositeAction => [
					it.actions += regionInitializingAction
				]
				for (lowlevelTopRegion : lowlevelStatechart.regions) {
					regionInitializingAction.actions += lowlevelTopRegion.createRecursiveXStsRegionAndSubregionActivatingAction
				}
				val entryEventInitializingAction = createParallelAction // Each region at the same time
				entryEventAction as CompositeAction => [
					it.actions += entryEventInitializingAction
				]
				for (lowlevelTopRegion : lowlevelStatechart.regions) {
					entryEventInitializingAction.actions += lowlevelTopRegion.createRecursiveXStsRegionAndSubregionEntryActions
				}
			].build
		}
		return topRegionInitializationRule
	}

	/**
	 * Maps a lowlevel region to an enum variable.
	 */
	protected def createRegionMapping(Region lowlevelRegion) {
		val lowlevelInactiveEnumLiteral = createEnumerationLiteralDefinition => [
			it.name = Namings.INACTIVE_ENUM_LITERAL
		]
		val enumType = createEnumerationTypeDefinition => [
			// The __Inactive__ literal is needed
			it.literals += lowlevelInactiveEnumLiteral
		]
		// Enum literals are based on states
		for (lowlevelState : lowlevelRegion.stateNodes.filter(State)) {
			val xStsEnumLiteral = createEnumerationLiteralDefinition => [
				it.name = lowlevelState.name.stateEnumLiteralName
			]
			enumType.literals += xStsEnumLiteral
			trace.put(lowlevelState, xStsEnumLiteral) // Tracing
		}
		// Creating type declaration from the enum type definition
		val enumTypeDeclaration = createTypeDeclaration => [
			it.type = enumType
			it.name = lowlevelRegion.name.regionTypeName // Uppercase first character
		]
		val xStsRegionVariable = createVariableDeclaration => [
			it.name = lowlevelRegion.name.regionVariableName // Lowercase first character
			it.type = createTypeReference => [
				it.reference = enumTypeDeclaration
			] // Enum variable
		]
		xStsRegionVariable.expression = createEnumerationLiteralExpression => [
			it.reference = lowlevelInactiveEnumLiteral
		]
		xSts.typeDeclarations += enumTypeDeclaration
		xSts.variableDeclarations += xStsRegionVariable // Target model modification
		xSts.controlVariables += xStsRegionVariable // Putting it in the control location variable list
		trace.put(lowlevelRegion, xStsRegionVariable) // Tracing
		// Creating top region variable group
		xStsRegionVariable.getCorrespondingVariableGroup => [
			it.variables += xStsRegionVariable
		]
	}

	/**
	 * Returns the variable group an xSTS region variable should be contained in.
	 */
	protected def VariableGroup getCorrespondingVariableGroup(VariableDeclaration xStsRegionVariable) {
		checkArgument(xStsRegionVariable !== null)
		val lowlevelRegion = trace.getLowlevelRegion(xStsRegionVariable)
		checkState(lowlevelRegion !== null)
		val regionVariableGroups = RegionVariableGroups.Matcher.on(targetEngine).
			getAllValuesOfregionVariableGroup(xStsRegionVariable)
		checkState(regionVariableGroups.size <= 1)
		if (regionVariableGroups.size == 1) {
			return regionVariableGroups.head
		}
		if (regionVariableGroups.empty) {
			// Checking variable group of orthogonal regions
			for (lowlevelOrthogonalRegion : lowlevelRegion.orthogonalRegions) {
				if (trace.isTraced(lowlevelOrthogonalRegion)) {
					val siblingXStsRegionVariable = trace.getXStsVariable(lowlevelOrthogonalRegion)
					val siblingVariableGroup = RegionVariableGroups.Matcher.on(targetEngine).
						getAllValuesOfregionVariableGroup(siblingXStsRegionVariable)
					checkState(siblingVariableGroup.size <= 1)
					if (!siblingVariableGroup.empty) {
						// There is a variable group on this region level
						return siblingVariableGroup.head
					}
				}
			}
			// No variable group on this region level, it has to be created
			val regionVariableGroup = createVariableGroup => [
				it.annotation = createRegionGroup
			]
			xSts.variableGroups += regionVariableGroup
			// Putting it in the hierarchy
			if (!lowlevelRegion.topRegion) {
				val parentRegion = lowlevelRegion.parentRegion
				val parentRegionVariable = trace.getXStsVariable(parentRegion)
				parentRegionVariable.correspondingVariableGroup => [
					it.containedGroups += regionVariableGroup
				]
			}
			return regionVariableGroup
		}
	}

	protected def getSubregionsRule() {
		if (subregionsRule === null) {
			subregionsRule = createRule(Subregions.instance).action [
				// Only activated if parent is already traced
				val lowlevelRegion = it.region
				lowlevelRegion.createRegionMapping
			].build
		}
		return subregionsRule
	}

	protected def getComponentParametersRule() {
		if (componentParametersRule === null) {
			componentParametersRule = createRule(Statecharts.instance).action [
				// Rule-based transformation is not applicable as the order of parameters is essential
				for (lowlevelVariable : it.statechart.parameterDeclarations) {
					val xStsVariable = createVariableDeclaration => [
						it.name = lowlevelVariable.name.variableName
						it.type = lowlevelVariable.type.transformType
					]
					xSts.variableDeclarations += xStsVariable // Target model modification
					trace.put(lowlevelVariable, xStsVariable) // Tracing
					xSts.componentParameterGroup.variables += xStsVariable // Variable group modification
				}
			].build
		}
		return componentParametersRule
	}

	protected def getPlainVariablesRule() {
		if (plainVariablesRule === null) {
			plainVariablesRule = createRule(PlainVariables.instance).action [
				val lowlevelVariable = it.variable
				if (lowlevelVariable.notOptimizable) {
					val xStsVariable = createVariableDeclaration => [
						it.name = lowlevelVariable.name.variableName
						it.type = lowlevelVariable.type.transformType
					]
					xSts.variableDeclarations += xStsVariable // Target model modification
					trace.put(lowlevelVariable, xStsVariable) // Tracing
					xSts.plainVariableGroup.variables += xStsVariable // Variable group modification
				}
			].build
		}
		return plainVariablesRule
	}

	protected def getTimeoutsRule() {
		if (timeoutsRule === null) {
			timeoutsRule = createRule(Timeouts.instance).action [
				val lowlevelTimeoutVariable = it.timeout
				if (lowlevelTimeoutVariable.notOptimizable) {
					val xStsVariable = createVariableDeclaration => [
						it.name = lowlevelTimeoutVariable.name.variableName
						it.type = lowlevelTimeoutVariable.type.transformType
						it.expression = lowlevelTimeoutVariable.expression.clone // Timeouts are initially true
					]
					xSts.variableDeclarations += xStsVariable // Target model modification
					trace.put(lowlevelTimeoutVariable, xStsVariable) // Tracing
					xSts.clockVariables += xStsVariable // Putting it in the clock variable list
					xSts.getTimeoutGroup.variables += trace.getXStsVariable(lowlevelTimeoutVariable)
				}
			].build
		}
		return timeoutsRule
	}

	protected def getVariableInitializationsRule() {
		if (variableInitializationsRule === null) {
			variableInitializationsRule = createRule(Variables.instance).action [
				val lowlevelVariable = it.variable
				if (lowlevelVariable.notOptimizable) {
					val xStsVariable = trace.getXStsVariable(lowlevelVariable)
					// By now all variables must be traced because of such initializations: var a = b
					xStsVariable.expression = lowlevelVariable.initialValue
				}
			].build
		}
		return variableInitializationsRule
	}
	
	protected def initializeVariableInitializingAction() {
		val xStsVariables = newLinkedList
		// Cycle on the original declarations, as their order is important due to 'var a = b'-like assignments
		for (lowlevelStatechart : _package.components.filter(StatechartDefinition)) {
			for (lowlevelVariable : lowlevelStatechart.variableDeclarations) {
				if (lowlevelVariable.notOptimizable) {
					xStsVariables += trace.getXStsVariable(lowlevelVariable)
				}
			}
		}
		// Parameters must not be given initial value
		xStsVariables -= xSts.componentParameterGroup.variables
		// The region variables must be set to __Inactive__
		xStsVariables += xSts.regionGroups.map[it.variables].flatten
		// Initial value to the events, their order is not interesting
		xStsVariables += xSts.inEventVariableGroup.variables + xSts.outEventVariableGroup.variables
		// Note that optimization is NOT needed here, as these are already XSTS variables
		for (xStsVariable : xStsVariables) {
			// variableInitializingAction as it must be set before setting the configuration
			variableInitializingAction as SequentialAction => [
				it.actions += createAssignmentAction => [
					it.lhs = createReferenceExpression => [it.declaration = xStsVariable]
					it.rhs = xStsVariable.initialValue
				]
			]
		}
	}

	/**
	 * Simple transitions between any states, composite states are not differentiated.
	 */
	protected def getSimpleTransitionsBetweenStatesRule() {
		if (simpleTransitionBetweenStatesRule === null) {
			simpleTransitionBetweenStatesRule = createRule(SimpleTransitionsBetweenStates.instance).action [
				val lowlevelSimpleTransition = it.transition
				val xStsTransition = lowlevelSimpleTransition.transform
				// Tracing is done in the transformation part
				xSts.transitions += xStsTransition
			].build
		}
		return simpleTransitionBetweenStatesRule
	}

	/**
	 * Simple transitions to lower history states, shallow and deep are not differentiated.
	 */
	protected def getSimpleTransitionsToHistoryStatesRule() {
		if (simpleTransitionsToHistoryStatesRule === null) {
			simpleTransitionsToHistoryStatesRule = createRule(SimpleTransitionsToEntryStates.instance).action [
				val lowlevelSimpleTransition = it.transition
				val lowlevelTargetAncestor = it.targetAncestor
				val xStsTransition = lowlevelSimpleTransition.transform(lowlevelTargetAncestor)
				// Tracing is done in the transformation part
				xSts.transitions += xStsTransition
			].build
		}
		return simpleTransitionsToHistoryStatesRule
	}

	protected def getLastJoinTransitionsRule() {
		if (lastJoinTransitionsRule === null) {
			lastJoinTransitionsRule = createRule(LastJoinStates.instance).action [
				val lowlevelLastJoinTransition = it.joinState
				val xStsComplexTransition = lowlevelLastJoinTransition.transform
				xSts.transitions += xStsComplexTransition
			].build
		}
		return lastJoinTransitionsRule
	}

	protected def getLastMergeTransitionsRule() {
		if (lastMergeTransitionsRule === null) {
			lastMergeTransitionsRule = createRule(LastMergeStates.instance).action [
				val lowlevelLastMergeTransition = it.mergeState
				val xStsComplexTransition = lowlevelLastMergeTransition.transform
				xSts.transitions += xStsComplexTransition
			].build
		}
		return lastMergeTransitionsRule
	}

	protected def getFirstForkTransitionsRule() {
		if (firstForkTransitionsRule === null) {
			firstForkTransitionsRule = createRule(FirstForkStates.instance).action [
				val lowlevelFirstForkTransition = it.forkState
				val xStsComplexTransition = lowlevelFirstForkTransition.transform
				xSts.transitions += xStsComplexTransition
			].build
		}
		return firstForkTransitionsRule
	}

	protected def getFirstChoiceTransitionsRule() {
		if (firstChoiceTransitionsRule === null) {
			firstChoiceTransitionsRule = createRule(FirstChoiceStates.instance).action [
				val lowlevelFirstChoiceTransition = it.choiceState
				val xStsComplexTransition = lowlevelFirstChoiceTransition.transform
				xSts.transitions += xStsComplexTransition
			].build
		}
		return firstChoiceTransitionsRule
	}

	protected def getInEventEnvironmentalActionRule() {
		if (inEventEnvironmentalActionRule === null) {
			inEventEnvironmentalActionRule = createRule(InEvents.instance).action [
				val lowlevelEvent = it.event
				if (lowlevelEvent.notOptimizable) {
					val lowlevelEnvironmentalAction = inEventAction as SequentialAction
					val xStsEventVariable = trace.getXStsVariable(lowlevelEvent)
					lowlevelEnvironmentalAction.actions += createNonDeterministicAction => [
						// Event is raised
						it.actions += createAssignmentAction => [
							it.lhs = createReferenceExpression => [
								it.declaration = xStsEventVariable
							]
							it.rhs = createTrueExpression
						]
						// Event is not raised
						it.actions += createAssignmentAction => [
							it.lhs = createReferenceExpression => [
								it.declaration = xStsEventVariable
							]
							it.rhs = createFalseExpression
						]
					]
					for (lowlevelParameterDeclaration : it.event.parameters) {
						val xStsAllPossibleParameterValues = newHashSet
						// Initial value
						val type = lowlevelParameterDeclaration.type
						xStsAllPossibleParameterValues += type.initialValueOfType
						for (lowlevelValue : EventParameterComparisons.Matcher.on(engine).getAllValuesOfvalue(lowlevelParameterDeclaration)) {
							xStsAllPossibleParameterValues += lowlevelValue.clone // Cloning is important
						}
						val xStsPossibleParameterValues = xStsAllPossibleParameterValues.removeDuplicatedExpressions
						if (type instanceof TypeReference) {
							// Mapping back to enum literals if necessary
							val typeDeclaration = type.reference
							val typeDefinition = typeDeclaration.type
							if (typeDefinition instanceof EnumerationTypeDefinition) {
								val enumLiterals = typeDefinition.mapToEnumerationLiterals(xStsPossibleParameterValues)
								xStsPossibleParameterValues.clear
								xStsPossibleParameterValues += enumLiterals
							}
						}
						val xStsParameterVariable = trace.getXStsVariable(lowlevelParameterDeclaration)
						lowlevelEnvironmentalAction.actions += createIfAction(
							// Only if the event is raised
							createEqualityExpression => [
								it.leftOperand = createReferenceExpression => [
									it.declaration = xStsEventVariable
								]
								it.rightOperand = createTrueExpression
							],
							createNonDeterministicAction => [
								for (xStsPossibleParameterValue : xStsPossibleParameterValues) {
									it.actions += createAssignmentAction => [
										it.lhs = createReferenceExpression => [
											it.declaration = xStsParameterVariable
										]
										it.rhs = xStsPossibleParameterValue
									]
								}
							]
						)
					}
				}
			].build
		}
		return inEventEnvironmentalActionRule
	}
	
	protected def getOutEventEnvironmentalActionRule() {
		if (outEventEnvironmentalActionRule === null) {
			outEventEnvironmentalActionRule = createRule(OutEvents.instance).action [
				val lowlevelEvent = it.event
				if (lowlevelEvent.notOptimizable) {
					val lowlevelEnvironmentalAction = outEventAction as SequentialAction
					val xStsEventVariable = trace.getXStsVariable(lowlevelEvent)
					lowlevelEnvironmentalAction.actions += createAssignmentAction => [
						it.lhs = createReferenceExpression => [
							it.declaration = xStsEventVariable
						]
						it.rhs = createFalseExpression
					]
					if (event.persistency == Persistency.TRANSIENT) {
						// Resetting parameter for out event
						for (lowlevelParameterDeclaration : it.event.parameters) {
							val xStsParameterVariable = trace.getXStsVariable(lowlevelParameterDeclaration)
							lowlevelEnvironmentalAction.actions += createAssignmentAction => [
								it.lhs = createReferenceExpression => [
									it.declaration = xStsParameterVariable
								]
								it.rhs = xStsParameterVariable.initialValue
							]
						}
					}
				}
			].build
		}
		return outEventEnvironmentalActionRule
	}

	protected def mergeTransitions() {
		val statecharts = Statecharts.Matcher.on(engine).allValuesOfstatechart
		checkState(statecharts.size == 1)
		val statechart = statecharts.head
		val xStsMergedAction = createNonDeterministicAction
		statechart.mergeTransitions(xStsMergedAction)
		// Putting it in the XSTS model
		xSts.mergedAction = xStsMergedAction
		// Adding default else branch: if "region" cannot fire
		xStsMergedAction.extendChoiceWithDefaultBranch(createEmptyAction)
		// For this to work, each assume action has to be at index 0 of the containing composite action
	}

	protected def void mergeTransitions(CompositeElement lowlevelComposite, NonDeterministicAction xStsAction) {
		val lowlevelRegions = lowlevelComposite.regions
		if (lowlevelRegions.size > 1) {
			val xStsParallelAction = createParallelAction
			xStsAction.actions += xStsParallelAction
			for (lowlevelRegion : lowlevelRegions) {
				val xStsSubchoiceAction = createNonDeterministicAction
				xStsParallelAction.actions += xStsSubchoiceAction
				lowlevelRegion.mergeTransitionsOfRegion(xStsSubchoiceAction)
				// Adding default else branch: if "region" cannot fire
				xStsSubchoiceAction.extendChoiceWithDefaultBranch(createEmptyAction)
				// For this to work, each assume action has to be at index 0 of the containing composite action
			}
		} else if (lowlevelRegions.size == 1) {
			lowlevelRegions.head.mergeTransitionsOfRegion(xStsAction)
		}
	}

	protected def void mergeTransitionsOfRegion(Region lowlevelRegion, NonDeterministicAction xStsAction) {
		val xStsTransitions = newHashSet
		val lowlevelStates = lowlevelRegion.stateNodes.filter(State)
		// Simple outgoing transitions
		for (lowlevelState : lowlevelStates) {
			for (lowlevelOutgoingTransition : lowlevelState.outgoingTransitions
					.filter[trace.isTraced(it)] /* Simple transitions */ ) {
				xStsTransitions += trace.getXStsTransition(lowlevelOutgoingTransition)
			}
			if (lowlevelState.isComposite) {
				// Recursion
				lowlevelState.mergeTransitions(xStsAction)
			}
		}
		// Complex transitions
		for (lastJoinState : lowlevelRegion.stateNodes.filter(JoinState).filter[it.isLastJoinState]) {
			xStsTransitions += trace.getXStsTransition(lastJoinState)
		}
		for (lastMergeState : lowlevelRegion.stateNodes.filter(MergeState).filter[it.isLastMergeState]) {
			xStsTransitions += trace.getXStsTransition(lastMergeState)
		}
		for (lastForkState : lowlevelRegion.stateNodes.filter(ForkState).filter[it.isFirstForkState]) {
			xStsTransitions += trace.getXStsTransition(lastForkState)
		}
		for (lastChoiceState : lowlevelRegion.stateNodes.filter(ChoiceState).filter[it.isFirstChoiceState]) {
			xStsTransitions += trace.getXStsTransition(lastChoiceState)
		}
		for (xStsTransition : xStsTransitions) {
			xStsAction.actions += xStsTransition.action.clone // Cloning is important
		}
	}

	protected def optimizeActions() {
		xSts.variableInitializingAction = xSts.variableInitializingAction.optimize
		xSts.configurationInitializingAction = xSts.configurationInitializingAction.optimize
		xSts.entryEventAction = xSts.entryEventAction.optimize
		xSts.mergedAction = xSts.mergedAction.optimize
		xSts.inEventAction = xSts.inEventAction.optimize
		xSts.outEventAction = xSts.outEventAction.optimize
		/* Note: no optimization on the list of transitions as the
		 deletion of actions would mean the breaking of the trace. */
	}
	
	def dispose() {
		if (transformation !== null) {
			transformation.ruleEngine.dispose
		}
		transformation = null
		targetEngine = null
		trace = null
		return
	}
}
