/********************************************************************************
 * Copyright (c) 2018-2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.lowlevel.xsts.transformation.optimizer.XstsOptimizer
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.DataContainers
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.Events
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.Flows
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.GlobalVariables
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.InEvents
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.InitialNodes
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.Nodes
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.OutEvents
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.PlainVariables
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.ReferredEvents
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.ReferredVariables
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.RegionVariableGroups
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.Regions
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.Statecharts
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.Timeouts
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.TypeDeclarations
import hu.bme.mit.gamma.lowlevel.xsts.transformation.traceability.L2STrace
import hu.bme.mit.gamma.statechart.lowlevel.model.ActivityNode
import hu.bme.mit.gamma.statechart.lowlevel.model.DataFlow
import hu.bme.mit.gamma.statechart.lowlevel.model.EventDeclaration
import hu.bme.mit.gamma.statechart.lowlevel.model.EventDirection
import hu.bme.mit.gamma.statechart.lowlevel.model.Package
import hu.bme.mit.gamma.statechart.lowlevel.model.Persistency
import hu.bme.mit.gamma.statechart.lowlevel.model.Pin
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.VariableGroup
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import hu.bme.mit.gamma.xsts.util.XstsUtils
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
import static extension hu.bme.mit.gamma.xsts.transformation.util.XstsNamings.*
import hu.bme.mit.gamma.statechart.lowlevel.model.Flow

class LowlevelActivityToXstsTransformer {
	// Transformation-related extensions
	extension BatchTransformation transformation
	final extension BatchTransformationStatements statements
	// Transformation rule-related extensions
	final extension BatchTransformationRuleFactory = new BatchTransformationRuleFactory
	// Auxiliary objects
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension VariableDeclarationTransformer variableDeclarationTransformer
	protected final extension ActivityNodeTransformer activityNodeTransformer	
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension XstsActionUtil actionFactory = XstsActionUtil.INSTANCE
	protected final extension XstsOptimizer optimizer = XstsOptimizer.INSTANCE
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
	protected BatchTransformationRule<Statecharts.Match, Statecharts.Matcher> componentParametersRule
	protected BatchTransformationRule<PlainVariables.Match, PlainVariables.Matcher> plainVariablesRule
	protected BatchTransformationRule<Timeouts.Match, Timeouts.Matcher> timeoutsRule
	protected BatchTransformationRule<GlobalVariables.Match, GlobalVariables.Matcher> variableInitializationsRule
	
	protected BatchTransformationRule<InEvents.Match, InEvents.Matcher> inEventEnvironmentalActionRule
	protected BatchTransformationRule<OutEvents.Match, OutEvents.Matcher> outEventEnvironmentalActionRule
		
	protected BatchTransformationRule<Nodes.Match, Nodes.Matcher> activityNodesRule 
	protected BatchTransformationRule<Flows.Match, Flows.Matcher> activityFlowsRule 
	protected BatchTransformationRule<DataContainers.Match, DataContainers.Matcher> activityDataContainersRule
	protected BatchTransformationRule<Nodes.Match, Nodes.Matcher> activityNodeTransitionsRule 
	protected BatchTransformationRule<InitialNodes.Match, InitialNodes.Matcher> initialActivityNodeInitializationRule 
	
	// Optimization
	protected final boolean optimize
	protected Set<EventDeclaration> referredEvents
	protected Set<VariableDeclaration> referredVariables
	
	protected final extension ActivityLiterals activityLiterals = ActivityLiterals.INSTANCE
	protected final extension XstsUtils xstsUtils = XstsUtils.INSTANCE
	
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
			it.typeDeclarations += nodeStateEnumTypeDeclaration
			it.typeDeclarations += flowStateEnumTypeDeclaration
		]
		this.targetEngine = ViatraQueryEngine.on(new EMFScope(this.xSts))
		this.trace = new Trace(_package, xSts)
		
		// The transformers need the trace model for the variable mapping
		this.expressionTransformer = new ExpressionTransformer(this.trace)
		this.variableDeclarationTransformer = new VariableDeclarationTransformer(this.trace)
		this.transformation = BatchTransformation.forEngine(engine).build
		this.statements = transformation.transformationStatements
		
		this.activityNodeTransformer = new ActivityNodeTransformer(this.engine, this.trace)
		
		this.optimize = optimize
		if (optimize) {
			this.referredEvents = ReferredEvents.Matcher.on(engine).allValuesOfevent
			this.referredVariables = ReferredVariables.Matcher.on(engine).allValuesOfvariable
		}
	}

	def execute() {
		getTypeDeclarationsRule.fireAllCurrent
		getEventsRule.fireAllCurrent
		getComponentParametersRule.fireAllCurrent
		getPlainVariablesRule.fireAllCurrent
		// Now component parameters come as plain variables (from constants), so TimeoutsRule must follow PlainVariablesRule
		// Timeouts can refer to constants
		getTimeoutsRule.fireAllCurrent
		
		getActivityDataContainersRule.fireAllCurrent
		getActivityNodesRule.fireAllCurrent
		getActivityFlowsRule.fireAllCurrent
				
		// Event variables, parameters, variables and timeouts are transformed already
		/* By now all variables must be transformed so the expressions and actions can be transformed
		 * correctly with the trace model */
		getVariableInitializationsRule.fireAllCurrent
		getInEventEnvironmentalActionRule.fireAllCurrent
		getOutEventEnvironmentalActionRule.fireAllCurrent
		
		getActivityNodeTransitionsRule.fireAllCurrent
		
		val xStsMergedAction = createNonDeterministicAction
		xStsMergedAction.actions += xSts.transitions.map [it.action]
		xSts.changeTransitions(xStsMergedAction.wrap)
	
		xSts.optimizeXSts
		xSts.fillNullTransitions
		handleTransientAndResettableVariableAnnotations
		// The created EMF models are returned
		return new SimpleEntry<XSTS, L2STrace>(xSts, trace.getTrace)
	}
	
	private def getActivityNodesRule() {
		if (activityNodesRule === null) {
			activityNodesRule = createRule(Nodes.instance).action [
				it.activityNode.createActivityNodeMapping
			].build
		}
		return activityNodesRule
	}

	private def getActivityFlowsRule() {
		if (activityFlowsRule === null) {
			activityFlowsRule = createRule(Flows.instance).action [
				it.flow.createActivityFlowMapping
			].build
		}
		return activityFlowsRule
	}

	private def getActivityDataContainersRule() {
		if (activityDataContainersRule === null) {
			activityDataContainersRule = createRule(DataContainers.instance).action [
				it.dataContainer.createDataContainerMapping
			].build
		}
		return activityDataContainersRule
	}
	
	private def createActivityNodeMapping(ActivityNode activityNode) {
		val xStsActivityNodeVariable = createVariableDeclaration => [
			name = activityNode.activityNodeVariableName
			type = createTypeReference => [
				reference = nodeStateEnumTypeDeclaration
			]
			expression = createEnumerationLiteralExpression => [
				reference = idleNodeStateEnumLiteral
			]
		]
		xStsActivityNodeVariable.addOnDemandControlAnnotation
		xSts.variableDeclarations += xStsActivityNodeVariable
		trace.put(activityNode, xStsActivityNodeVariable)
	}
	
	private dispatch def createDataContainerMapping(Pin pin) {
		val pinType = pin.type.clone() // cloning to prevent loosing it from the original Pin
		val xStsPinVariable = createVariableDeclaration => [
			name = pin.pinVariableName
			type = pinType
			expression = pinType.initialValueOfType
		]
		xSts.variableDeclarations += xStsPinVariable
		
		trace.putDataContainer(pin, xStsPinVariable)
	}
	
	private dispatch def createDataContainerMapping(DataFlow dataFlow) {
		val flowType = dataFlow.targetPin.type.clone() // cloning to prevent loosing it from the original Pin
		val xStsFlowVariable = createVariableDeclaration => [
			name = dataFlow.flowDataTokenVariableName
			type = flowType
			expression = flowType.initialValueOfType
		]
		xSts.variableDeclarations += xStsFlowVariable
		
		trace.putDataContainer(dataFlow, xStsFlowVariable)
	}

	private def createActivityFlowMapping(Flow flow) {
		val xStsFlowVariable = createVariableDeclaration => [
			name = flow.flowVariableName
			type = createTypeReference => [
				reference = flowStateEnumTypeDeclaration
			]
			expression = createEnumerationLiteralExpression => [
				reference = emptyFlowStateEnumLiteral
			]
		]
		xStsFlowVariable.addOnDemandControlAnnotation
		xSts.variableDeclarations += xStsFlowVariable
		trace.put(flow, xStsFlowVariable)
	}
	
	private def getActivityNodeTransitionsRule() {
		if (activityNodeTransitionsRule === null) {
			activityNodeTransitionsRule = createRule(Nodes.instance).action [
				xSts.transitions += it.activityNode.transform.wrap
			].build
		}
		return activityNodeTransitionsRule
	}
	
	protected def isNotOptimizable(EventDeclaration lowlevelEvent) {
		return !optimize || referredEvents.contains(lowlevelEvent)
	}
	
	protected def isNotOptimizable(VariableDeclaration lowlevelVariable) {
		return (!optimize || referredVariables.contains(lowlevelVariable)) &&
			!lowlevelVariable.final // Constants are never transformed
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
							// Event is transient, its parameters are marked environment-resettable variables
							xStsParam.addEnvironmentResettableAnnotation
						}
						eventParameterVariableGroup.variables += xStsParam
						trace.put(lowlevelEventParameter, xStsParam) // Tracing
					}
				}
			].build
		}
		return eventsRule
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
						it.name = lowlevelTimeoutVariable.name.variableName
						it.type = lowlevelTimeoutVariable.type.transformType
						it.expression = lowlevelTimeoutVariable.expression.transformExpression // Timeouts are initially true
					]
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


	protected def getInEventEnvironmentalActionRule() {
		if (inEventEnvironmentalActionRule === null) {
			inEventEnvironmentalActionRule = createRule(InEvents.instance).action [
				val lowlevelEvent = it.event
				if (lowlevelEvent.notOptimizable /*&& !lowlevelEvent.internal*/) { // Activities do not contain internal events yet
					val lowlevelEnvironmentalAction = xSts.inEventAction as SequentialAction
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
				if (lowlevelEvent.notOptimizable /*&& !lowlevelEvent.internal*/) { // Activities do not contain internal events yet
					val lowlevelEnvironmentalAction = xSts.outEventAction
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
