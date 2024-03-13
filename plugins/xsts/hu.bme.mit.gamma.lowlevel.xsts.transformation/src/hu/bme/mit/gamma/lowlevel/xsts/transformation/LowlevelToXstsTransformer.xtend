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
package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.lowlevel.xsts.transformation.optimizer.RemovableVariableRemover
import hu.bme.mit.gamma.lowlevel.xsts.transformation.optimizer.XstsOptimizer
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.Events
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.FirstChoiceStates
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.FirstForkStates
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.GlobalVariables
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
import hu.bme.mit.gamma.lowlevel.xsts.transformation.traceability.L2STrace
import hu.bme.mit.gamma.statechart.lowlevel.model.EventDeclaration
import hu.bme.mit.gamma.statechart.lowlevel.model.EventDirection
import hu.bme.mit.gamma.statechart.lowlevel.model.Package
import hu.bme.mit.gamma.statechart.lowlevel.model.Persistency
import hu.bme.mit.gamma.statechart.lowlevel.model.Region
import hu.bme.mit.gamma.statechart.lowlevel.model.RunUponExternalEventAnnotation
import hu.bme.mit.gamma.statechart.lowlevel.model.RunUponExternalEventOrInternalTimeoutAnnotation
import hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.VariableGroup
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.transformation.util.UnorderedActionTransformer
import hu.bme.mit.gamma.xsts.transformation.util.VariableGroupRetriever
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
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

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.lowlevel.derivedfeatures.LowlevelStatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.XstsNamings.*

class LowlevelToXstsTransformer {
	// Transformation-related extensions
	extension BatchTransformation transformation
	final extension BatchTransformationStatements statements
	// Transformation rule-related extensions
	final extension BatchTransformationRuleFactory = new BatchTransformationRuleFactory
	// Auxiliary objects
	protected final extension RegionActivator regionActivator
	protected final extension EntryActionRetriever entryActionRetriever
	protected final extension StateAssumptionCreator stateAssumptionCreator
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension VariableDeclarationTransformer variableDeclarationTransformer
	protected final extension LowlevelTransitionToActionTransformer lowlevelTransitionToActionTransformer
	protected final extension SimpleTransitionToXTransitionTransformer simpleTransitionToActionTransformer
	protected final extension PrecursoryTransitionToXTransitionTransformer precursoryTransitionToXTransitionTransformer
	protected final extension TerminalTransitionToXTransitionTransformer terminalTransitionToXTransitionTransformer
	protected final extension AbstractTransitionMerger transitionMerger
	
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension UnorderedActionTransformer unorderedActionTransformer = UnorderedActionTransformer.INSTANCE
	protected final extension XstsOptimizer optimizer = XstsOptimizer.INSTANCE
	protected final extension RemovableVariableRemover variableRemover = RemovableVariableRemover.INSTANCE
	protected final extension VariableGroupRetriever variableGroupRetriever = VariableGroupRetriever.INSTANCE
	// Model factories
	protected final extension XSTSModelFactory factory = XSTSModelFactory.eINSTANCE
	protected final extension ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE
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
	protected BatchTransformationRule<GlobalVariables.Match, GlobalVariables.Matcher> variableInitializationsRule
	protected BatchTransformationRule<Statecharts.Match, Statecharts.Matcher> topRegionInitializationRule
	protected BatchTransformationRule<SimpleTransitionsBetweenStates.Match,
				SimpleTransitionsBetweenStates.Matcher> simpleTransitionBetweenStatesRule
	protected BatchTransformationRule<SimpleTransitionsToEntryStates.Match,
				SimpleTransitionsToEntryStates.Matcher> simpleTransitionsToHistoryStatesRule
	protected BatchTransformationRule<LastJoinStates.Match, LastJoinStates.Matcher> lastJoinTransitionsRule
	protected BatchTransformationRule<LastMergeStates.Match, LastMergeStates.Matcher> lastMergeTransitionsRule
	protected BatchTransformationRule<FirstForkStates.Match, FirstForkStates.Matcher> firstForkTransitionsRule
	protected BatchTransformationRule<FirstChoiceStates.Match, FirstChoiceStates.Matcher> firstChoiceTransitionsRule
	protected BatchTransformationRule<InEvents.Match, InEvents.Matcher> inEventEnvironmentalActionRule
	protected BatchTransformationRule<OutEvents.Match, OutEvents.Matcher> outEventEnvironmentalActionRule
	// Optimization
	protected final boolean optimize
	protected Set<EventDeclaration> referredEvents
	protected Set<VariableDeclaration> referredVariables
	
	new(Package _package) {
		this(_package, false)
	}
	
	new(Package _package, boolean optimize) {
		this (_package, optimize, TransitionMerging.HIERARCHICAL)
	}
	
	new(Package _package, boolean optimize, TransitionMerging transitionMerging) {
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
		this.stateAssumptionCreator = regionActivator.stateAssumptionCreator
		this.expressionTransformer = new ExpressionTransformer(this.trace)
		this.variableDeclarationTransformer = new VariableDeclarationTransformer(this.trace)
		this.lowlevelTransitionToActionTransformer =
				new LowlevelTransitionToActionTransformer(this.engine, this.trace)
		this.simpleTransitionToActionTransformer =
				new SimpleTransitionToXTransitionTransformer(this.engine, this.trace)
		this.precursoryTransitionToXTransitionTransformer =
				new PrecursoryTransitionToXTransitionTransformer(this.engine, this.trace)
		this.terminalTransitionToXTransitionTransformer =
				new TerminalTransitionToXTransitionTransformer(this.engine, this.trace)
		this.transitionMerger = switch (transitionMerging) {
			case HIERARCHICAL: new HierarchicalTransitionMerger(this.engine, this.trace)
//			case FLAT: new FlatTransitionMerger(this.engine, this.trace)
			default: throw new IllegalArgumentException("Not known merging enum: " + transitionMerging)
		}
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
		getPlainVariablesRule.fireAllCurrent
		// Now component parameters come as plain variables (from constants), so TimeoutsRule must follow PlainVariablesRule
		// Timeouts can refer to constants
		getTimeoutsRule.fireAllCurrent
		// Event variables, parameters, variables and timeouts are transformed already
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
		
		xSts.transformUnorderedActions // Transforming here, so optimizeXSts needn't be extended
		
		xSts.fillNullTransitions
		xSts.optimizeXSts // Needed to simplify the actions
		if (optimize) {
			xSts.removeReadOnlyVariables(true) // Affects parameter and input variables, too
			// Not internal variables at this point because they are handled later (internal events)
		}
		
		handleStateInvariants
		handleStatechartInvariants
		handleEnvironmentalInvariants
		
		handleTransientAndResettableVariableAnnotations
		handleRunUponExternalEventAnnotation
		// The created EMF models are returned
		return new SimpleEntry<XSTS, L2STrace>(xSts, trace.getTrace)
	}
	
	protected def isNotOptimizable(EventDeclaration lowlevelEvent) {
		return !optimize || referredEvents.contains(lowlevelEvent)
	}
	
	protected def isNotOptimizable(VariableDeclaration lowlevelVariable) {
		return (!optimize || referredVariables.contains(lowlevelVariable)) &&
			!lowlevelVariable.final // Constants are never transformed
	}
		
	protected def getVariableInitializingAction() {
		if (xSts.variableInitializingTransition === null) {
			xSts.variableInitializingTransition = createSequentialAction.wrap
		}
		return xSts.variableInitializingTransition.action
	}
	
	protected def getConfigurationInitializingAction() {
		if (xSts.configurationInitializingTransition === null) {
			xSts.configurationInitializingTransition = createSequentialAction.wrap
		}
		return xSts.configurationInitializingTransition.action
	}
	
	protected def getEntryEventAction() {
		if (xSts.entryEventTransition === null) {
			xSts.entryEventTransition = createSequentialAction.wrap
		}
		return xSts.entryEventTransition.action
	}
	
	protected def getInEventAction() {
		if (xSts.inEventTransition === null) {
			xSts.inEventTransition = createSequentialAction.wrap
		}
		return xSts.inEventTransition.action
	}
	
	protected def getOutEventAction() {
		if (xSts.outEventTransition === null) {
			xSts.outEventTransition = createSequentialAction.wrap
		}
		return xSts.outEventTransition.action
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
					if (lowlevelEvent.isRaised.internal) {
						xStsEventVariable.addInternalAnnotation
					}
					xSts.variableDeclarations += xStsEventVariable // Target model modification
					
					val eventVariableGroup = (lowlevelEvent.direction == EventDirection.IN) ?
							xSts.inEventVariableGroup : xSts.outEventVariableGroup
					eventVariableGroup.variables += xStsEventVariable // Variable group modification
					
					trace.put(lowlevelEvent, xStsEventVariable) // Tracing event
					trace.put(lowlevelEvent.isRaised, xStsEventVariable) // Tracing the contained isRaisedVariable
					// Parameters 
					val xStsEventParameterVariables = newArrayList
					for (lowlevelEventParameter : lowlevelEvent.parameters) {
						val xStsEventParameterVariable = createVariableDeclaration => [
							it.name = lowlevelEventParameter.name.variableName
							it.type = lowlevelEventParameter.type.transformType
						]
						xSts.variableDeclarations += xStsEventParameterVariable // Target model modification
						xStsEventParameterVariables += xStsEventParameterVariable
						
						val eventParameterVariableGroup = (lowlevelEvent.direction == EventDirection.IN) ?
								xSts.inEventParameterVariableGroup : xSts.outEventParameterVariableGroup
						eventParameterVariableGroup.variables += xStsEventParameterVariable
						if (lowlevelEvent.persistency == Persistency.TRANSIENT) {
							// Event is transient, its parameters are marked environment-resettable variables
							xStsEventParameterVariable.addEnvironmentResettableAnnotation
						}
						if (lowlevelEventParameter.internal) {
							// Variable (parameter) must not be set from the environment, only other components
							xStsEventParameterVariable.addInternalAnnotation
						}
						trace.put(lowlevelEventParameter, xStsEventParameterVariable) // Tracing
					}
					// In-XSTS-model tracing
					xStsEventVariable.addDeclarationReferenceAnnotations(xStsEventParameterVariables)
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
				val regionInitializingAction = createRegionAction // Each region at the same time
				configurationInitializingAction as SequentialAction => [
					it.actions += regionInitializingAction
				]
				for (lowlevelTopRegion : lowlevelStatechart.regions) {
					regionInitializingAction.actions +=
						lowlevelTopRegion.createRecursiveXStsRegionAndSubregionActivatingAction
				}
				val entryEventInitializingAction = createRegionAction // Each region at the same time
				entryEventAction as SequentialAction => [
					it.actions += entryEventInitializingAction
				]
				for (lowlevelTopRegion : lowlevelStatechart.regions) {
					entryEventInitializingAction.actions +=
						lowlevelTopRegion.createRecursiveXStsRegionAndSubregionEntryActions
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
		for (lowlevelState : lowlevelRegion.states) {
			val xStsEnumLiteral = createEnumerationLiteralDefinition => [
				it.name = lowlevelState.name.stateEnumLiteralName
			]
			enumType.literals += xStsEnumLiteral
			
			trace.put(lowlevelState, xStsEnumLiteral) // Tracing
		}
		// History literals
		if (lowlevelRegion.hasHistory) {
			for (lowlevelState : lowlevelRegion.states) {
				val xStsHistoryEnumLiteral = createEnumerationLiteralDefinition => [
					it.name = lowlevelState.name.stateInactiveHistoryEnumLiteralName
				]
				enumType.literals += xStsHistoryEnumLiteral
				
				trace.putInactiveHistoryEnumLiteral(lowlevelState, xStsHistoryEnumLiteral) // Tracing
			}
		}
		//
		
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
		xStsRegionVariable.expression = lowlevelInactiveEnumLiteral.createEnumerationLiteralExpression
		xSts.typeDeclarations += enumTypeDeclaration
		xSts.variableDeclarations += xStsRegionVariable // Target model modification
		xStsRegionVariable.addOnDemandControlAnnotation // It is worth following this variable
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
		val regionVariableGroups = RegionVariableGroups.Matcher.on(targetEngine)
				.getAllValuesOfregionVariableGroup(xStsRegionVariable)
		checkState(regionVariableGroups.size <= 1)
		if (regionVariableGroups.size == 1) {
			return regionVariableGroups.head
		}
		if (regionVariableGroups.empty) {
			// Checking variable group of orthogonal regions
			for (lowlevelOrthogonalRegion : lowlevelRegion.orthogonalRegions) {
				if (trace.isTraced(lowlevelOrthogonalRegion)) {
					val siblingXStsRegionVariable = trace.getXStsVariable(lowlevelOrthogonalRegion)
					val siblingVariableGroup = RegionVariableGroups.Matcher.on(targetEngine)
							.getAllValuesOfregionVariableGroup(siblingXStsRegionVariable)
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
					val xStsVariable = lowlevelVariable.transformVariableDeclaration
					xSts.variableDeclarations += xStsVariable // Target model modification
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
						it.type = lowlevelTimeoutVariable.type.transformType
						it.name = lowlevelTimeoutVariable.name.variableName
					]
					val expression = lowlevelTimeoutVariable.expression
					xStsVariable.expression =  (expression !== null) ?
						expression.transformExpression : // Timeouts are initially true
						0.toIntegerLiteral // Expression is null, i.e., timeout declaration is not started, always true 
						// Theoretically, this variable is not referenced anywhere in this case
					
					xSts.variableDeclarations += xStsVariable // Target model modification
					trace.put(lowlevelTimeoutVariable, xStsVariable) // Tracing
					xStsVariable.addClockAnnotation 
					xSts.getTimeoutGroup.variables += trace.getXStsVariable(lowlevelTimeoutVariable)
				}
			].build
		}
		return timeoutsRule
	}

	protected def getVariableInitializationsRule() {
		if (variableInitializationsRule === null) {
			variableInitializationsRule = createRule(GlobalVariables.instance).action [
				val lowlevelVariable = it.variable
				if (lowlevelVariable.notOptimizable) {
					val xStsVariable = trace.getXStsVariable(lowlevelVariable)
					// By now all variables must be traced because of such initializations: var a = b
					xStsVariable.expression = lowlevelVariable.initialValue.transformExpression
				}
			].build
		}
		return variableInitializationsRule
	}
	
	protected def initializeVariableInitializingAction() {
		val xStsVariables = newArrayList
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
		// Initial value to the events and parameters, their order is not interesting
		xStsVariables += xSts.inEventVariableGroup.variables + xSts.outEventVariableGroup.variables +
				xSts.inEventParameterVariableGroup.variables + xSts.outEventParameterVariableGroup.variables
		// Note that optimization is NOT needed here, as these are already XSTS variables
		for (xStsVariable : xStsVariables) {
			// variableInitializingAction as it must be set before setting the configuration
			variableInitializingAction as SequentialAction => [
				it.actions += xStsVariable.createAssignmentAction(xStsVariable.initialValue)
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
				throw new IllegalArgumentException("Merge states are not supported")
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
				if (lowlevelEvent.notOptimizable && !lowlevelEvent.internal) {
					val lowlevelEnvironmentalAction = inEventAction as SequentialAction
					val xStsEventVariable = trace.getXStsVariable(lowlevelEvent)
					
					// In event variable
					val xStsInEventAssignment = createHavocAction => [
						it.lhs = xStsEventVariable.createReferenceExpression
					]
					
					lowlevelEnvironmentalAction.actions += xStsInEventAssignment
					// Parameter variables
					for (lowlevelParameterDeclaration : it.event.parameters) {
						val xStsParameterVariable = trace.getXStsVariable(lowlevelParameterDeclaration)
						if (lowlevelEvent.persistency == Persistency.TRANSIENT) {
							// Synchronous composite components do not reset transient parameters
							// There is the same optimization in ComponentTransformer too, though
							// Why not default expression? (check StatechartCodeGenerator)
							checkState(xStsParameterVariable.environmentResettable)
							lowlevelEnvironmentalAction.actions += xStsParameterVariable
									.createAssignmentAction(xStsParameterVariable.initialValue)
						}
						
						val xStsInParameterAssignment = createHavocAction => [
							it.lhs = xStsParameterVariable.createReferenceExpression
						]
						
						// Setting the parameter value
						lowlevelEnvironmentalAction.actions += createIfAction(
							// Only if the event is raised
							xStsEventVariable.createReferenceExpression,
							xStsInParameterAssignment
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
				if (lowlevelEvent.notOptimizable && !lowlevelEvent.internal) {
					val lowlevelEnvironmentalAction = outEventAction as SequentialAction
					val xStsEventVariable = trace.getXStsVariable(lowlevelEvent)
					lowlevelEnvironmentalAction.actions += xStsEventVariable
							.createAssignmentAction(createFalseExpression)
					if (event.persistency == Persistency.TRANSIENT) {
						// Resetting parameter for out event
						for (lowlevelParameterDeclaration : it.event.parameters) {
							val xStsParameterVariable = trace.getXStsVariable(lowlevelParameterDeclaration)
							lowlevelEnvironmentalAction.actions += xStsParameterVariable
									.createAssignmentAction(xStsParameterVariable.initialValue)
						}
					}
				}
			].build
		}
		return outEventEnvironmentalActionRule
	}
	
	protected def handleStateInvariants() {
		val lowlevelStatechart = trace.statechart
		val lowlevelStates = lowlevelStatechart.allStates
		
		for (lowlevelState : lowlevelStates) {
			val lowlevelInvariants = lowlevelState.invariants
			val lowlevelRegion = lowlevelState.parentRegion
			if (!lowlevelInvariants.empty && trace.isTraced(lowlevelRegion)) {
				val xStsInvariants = lowlevelState.invariants.map[it.transformExpression]
				val xStsInvariantRhs = xStsInvariants.wrapIntoAndExpression
				
				val xStsVariable = trace.getXStsVariable(lowlevelRegion)
				val xStsLiteral = trace.getXStsEnumLiteral(lowlevelState)
				
				val xStsInvariantLhs = xStsVariable.createEqualityExpression(
						xStsLiteral.createEnumerationLiteralExpression)
				
				val xStsStateInvariant =  xStsInvariantLhs.createImplyExpression(xStsInvariantRhs)
				val xStsAssumeStateInvariant = xStsStateInvariant.createAssumeAction
				xStsAssumeStateInvariant.addInternalInvariantAnnotation
				
				val xStsMergedAction = xSts.mergedAction
				xStsMergedAction.appendToAction(xStsAssumeStateInvariant)
				val xStsCongifurationInitAction = xSts.configurationInitializingTransition.action
				xStsCongifurationInitAction.appendToAction(xStsAssumeStateInvariant.clone)
			}
		}
	}
	
	protected def handleStatechartInvariants() {
		val lowlevelStatechart = trace.statechart
		val lowlevelStatechartInvariants = lowlevelStatechart.invariants
		
		if (!lowlevelStatechartInvariants.empty) {
			val xStsInvariants = lowlevelStatechartInvariants.map[it.transformExpression]
			val xStsStatechartInvariant = xStsInvariants.wrapIntoAndExpression

			val xStsAssumeStatechartInvariant = xStsStatechartInvariant.createAssumeAction
			xStsAssumeStatechartInvariant.addInternalInvariantAnnotation
			
			val xStsMergedAction = xSts.mergedAction
			xStsMergedAction.appendToAction(xStsAssumeStatechartInvariant)
			val xStsCongifurationInitAction = xSts.configurationInitializingTransition.action
			xStsCongifurationInitAction.appendToAction(xStsAssumeStatechartInvariant.clone)
		}
	}
	
	protected def handleEnvironmentalInvariants() {
		val lowlevelStatechart = trace.statechart
		val lowlevelEnvironmentalInvariants = lowlevelStatechart.environmentalInvariants
		
		if (!lowlevelEnvironmentalInvariants.empty) {
			val xStsInvariants = lowlevelEnvironmentalInvariants.map[it.transformExpression]
			val xStsEnvironmentalInvariant = xStsInvariants.wrapIntoAndExpression

			val xStsAssumeEnvironmentalInvariant = xStsEnvironmentalInvariant.createAssumeAction
			xStsAssumeEnvironmentalInvariant.addEnvironmentalInvariantAnnotation
			
			val xStsMergedAction = xSts.mergedAction
			xStsAssumeEnvironmentalInvariant.prependToAction(xStsMergedAction)
		}
	}
	
	protected def handleTransientAndResettableVariableAnnotations() {
		val newMergedAction = createSequentialAction
		
		val resetableVariables = xSts.variableDeclarations.filter[it.resettable]
		for (resetableVariable : resetableVariables) {
			newMergedAction.actions += resetableVariable.createVariableResetAction
		}
		newMergedAction.actions += xSts.mergedAction
		
		val transientVariables = xSts.variableDeclarations.filter[it.transient]
		for (transientVariable : transientVariables) {
			val assignment = transientVariable.createVariableResetAction
			newMergedAction.actions += assignment
			// To reduce state space in the entry action too in the case of transient variables
			xSts.entryEventTransition.action.appendToAction(assignment.clone) // Cloning is important
		}
		
		xSts.changeTransitions(newMergedAction.wrap)
	}
	
	protected def handleRunUponExternalEventAnnotation() {
		val statechart = trace.statechart
		val xStsInEventVariables = xSts.inEventVariableGroup.variables
		val xStsTimeoutVariables = xSts.timeoutGroup.variables
		val runUponExternalEventAnnotation =
				statechart.hasAnnotation(RunUponExternalEventAnnotation) && !xStsInEventVariables.empty
		val runUponExternalEventAnnotationOrInternalTimeout =
				statechart.hasAnnotation(RunUponExternalEventOrInternalTimeoutAnnotation) && !xStsTimeoutVariables.empty
		if (runUponExternalEventAnnotation || runUponExternalEventAnnotationOrInternalTimeout) {
			val xStsMergedAction = xSts.mergedAction
			
			val conditions = <Expression>newArrayList
			conditions += xStsInEventVariables.map[it.createReferenceExpression]
			
			if (runUponExternalEventAnnotationOrInternalTimeout) {
				conditions += trace.getTimeoutExpressions.map[it.clone]
			}
			
			val condition = conditions.wrapIntoOrExpression
			val ifAction = condition.createIfAction(xStsMergedAction)
			
			xSts.mergedTransition.action = ifAction
		}
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
