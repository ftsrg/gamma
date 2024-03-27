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
package hu.bme.mit.gamma.statechart.language.validation;

import java.util.List;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.xtext.validation.Check;

import hu.bme.mit.gamma.expression.model.ArgumentedElement;
import hu.bme.mit.gamma.expression.model.ElseExpression;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter;
import hu.bme.mit.gamma.statechart.composite.BroadcastChannel;
import hu.bme.mit.gamma.statechart.composite.CascadeCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.Channel;
import hu.bme.mit.gamma.statechart.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ControlSpecification;
import hu.bme.mit.gamma.statechart.composite.EventPassing;
import hu.bme.mit.gamma.statechart.composite.InstancePortReference;
import hu.bme.mit.gamma.statechart.composite.MessageQueue;
import hu.bme.mit.gamma.statechart.composite.PortBinding;
import hu.bme.mit.gamma.statechart.composite.ScheduledAsynchronousCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.SimpleChannel;
import hu.bme.mit.gamma.statechart.contract.AdaptiveContractAnnotation;
import hu.bme.mit.gamma.statechart.contract.StateContractAnnotation;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Clock;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Event;
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression;
import hu.bme.mit.gamma.statechart.interface_.Interface;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.statechart.interface_.TimeSpecification;
import hu.bme.mit.gamma.statechart.phase.MissionPhaseStateAnnotation;
import hu.bme.mit.gamma.statechart.phase.VariableBinding;
import hu.bme.mit.gamma.statechart.statechart.AnyPortEventReference;
import hu.bme.mit.gamma.statechart.statechart.ChoiceState;
import hu.bme.mit.gamma.statechart.statechart.ComplexTrigger;
import hu.bme.mit.gamma.statechart.statechart.EntryState;
import hu.bme.mit.gamma.statechart.statechart.ForkState;
import hu.bme.mit.gamma.statechart.statechart.JoinState;
import hu.bme.mit.gamma.statechart.statechart.MergeState;
import hu.bme.mit.gamma.statechart.statechart.OpaqueTrigger;
import hu.bme.mit.gamma.statechart.statechart.PortEventReference;
import hu.bme.mit.gamma.statechart.statechart.PseudoState;
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction;
import hu.bme.mit.gamma.statechart.statechart.Region;
import hu.bme.mit.gamma.statechart.statechart.StateNode;
import hu.bme.mit.gamma.statechart.statechart.StateReferenceExpression;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.statechart.statechart.TimeoutDeclaration;
import hu.bme.mit.gamma.statechart.statechart.Transition;
import hu.bme.mit.gamma.statechart.util.StatechartModelValidator;

public class StatechartLanguageValidator extends AbstractStatechartLanguageValidator {
	//
	protected StatechartModelValidator statechartModelValidator = StatechartModelValidator.INSTANCE;
	//
	public StatechartLanguageValidator() {
		super.expressionModelValidator = statechartModelValidator;
		super.actionModelValidator = statechartModelValidator;
	}
	
	@Check
	@Override
	public void checkNameUniqueness(EObject element) {
		if (element instanceof Interface _interface) {
			List<Event> events = ecoreUtil.getAllContentsOfType(_interface, Event.class);
			if (!events.isEmpty()) { // checkNameUniqueness(EObject ) would do this - this way it may be faster
				handleValidationResultMessage(expressionModelValidator.checkNameUniqueness(events));
			}
		}
		else {
			super.checkNameUniqueness(element);
		}
	}
	
	@Check
	public void checkStateNameUniqueness(StatechartDefinition statechart) {
		handleValidationResultMessage(statechartModelValidator.checkStateNameUniqueness(statechart));
	}
	
	@Check
	public void checkTransitionNameUniqueness(StatechartDefinition statechart) {
		handleValidationResultMessage(statechartModelValidator.checkTransitionNameUniqueness(statechart));
	}
	
	@Check
	public void checkComponentSepratation(Component component) {
		handleValidationResultMessage(statechartModelValidator.checkComponentSepratation(component));
	}
	
	@Check
	public void checkUnsupportedTriggers(OpaqueTrigger trigger) {
		handleValidationResultMessage(statechartModelValidator.checkUnsupportedTriggers(trigger));
	}
	
	@Check
	public void checComplexTriggers(ComplexTrigger trigger) {
		handleValidationResultMessage(statechartModelValidator.checkComplexTriggers(trigger));
	}
	
	@Check
	public void checkUnsupportedVariableTypes(VariableDeclaration variable) {
		handleValidationResultMessage(statechartModelValidator.checkUnsupportedVariableTypes(variable));
	}
	
	// We could check if the expression is of type void (warning)
//	@Check
//	public void checkUnsupportedExpressionStatements(ExpressionStatement expressionStatement) {
//	}
	
	// Expressions
	
	@Check
	public void checkArgumentTypes(ArgumentedElement element) {
		handleValidationResultMessage(statechartModelValidator.checkArgumentTypes(element));
	}
	
	// Interfaces
	
	@Check
	public void checkInterfaceInheritance(Interface gammaInterface) {
		handleValidationResultMessage(statechartModelValidator.checkInterfaceInheritance(gammaInterface));
		handleValidationResultMessage(statechartModelValidator.checkInternalEvents(gammaInterface));
	}
	
	@Check
	public void checkEventPersistency(Event event) {
		handleValidationResultMessage(statechartModelValidator.checkEventPersistency(event));
	}
	
	@Check
	public void checkParameterName(Event event) {
		handleValidationResultMessage(statechartModelValidator.checkParameterName(event));
	}
	
	@Check
	public void checkInterfaceInvariants(Interface gammaInterface) {
		handleValidationResultMessage(statechartModelValidator.checkInterfaceInvariants(gammaInterface));
	}
	
	// Statechart adaptive contract
	
	@Check
	public void checkStateAnnotation(StateContractAnnotation annotation) {
		handleValidationResultMessage(statechartModelValidator.checkStateAnnotation(annotation));
	}
	
	@Check
	public void checkStatechartAnnotation(AdaptiveContractAnnotation annotation) {
		handleValidationResultMessage(statechartModelValidator.checkStatechartAnnotation(annotation));
	}
	
	// Statechart mission phase
	
	@Check
	public void checkStateDefinition(MissionPhaseStateAnnotation annotation) {
		handleValidationResultMessage(statechartModelValidator.checkMissionPhaseStateAnnotation(annotation));
	}
	
	@Check
	public void checkVaraibleBindings(VariableBinding variableBinding) {
		handleValidationResultMessage(statechartModelValidator.checkVaraibleBindings(variableBinding));
	}
	
	// Statechart
	
	@Check
	public void checkStatechartScheduling(StatechartDefinition statechart) {
		handleValidationResultMessage(statechartModelValidator.checkStatechartScheduling(statechart));
	}
	
	@Check
	public void checkImports(Package _package) {
		handleValidationResultMessage(statechartModelValidator.checkImports(_package));
	}
	
	@Check
	public void checkRegionEntries(Region region) {
		handleValidationResultMessage(statechartModelValidator.checkRegionEntries(region));
	}
	
	@Check
	public void checkUnusedDeclarations(Component component) {
		handleValidationResultMessage(statechartModelValidator.checkUnusedDeclarations(component));
	}
	
	@Check
	public void checkUnusedTimeoutDeclarations(TimeoutDeclaration declaration) {
		handleValidationResultMessage(statechartModelValidator.checkUnusedTimeoutDeclarations(declaration));
	}
	
	@Check
	public void checkTimeSpecifications(TimeSpecification timeSpecification) {
		handleValidationResultMessage(statechartModelValidator.checkTimeSpecifications(timeSpecification));
	}
	
	@Check
	public void checkPortEventParameterReference(EventParameterReferenceExpression expression) {
		handleValidationResultMessage(statechartModelValidator.checkPortEventParameterReference(expression));
	}
	
	@Check
	public void checkTransitionPriority(Transition transition) {
		handleValidationResultMessage(statechartModelValidator.checkTransitionPriority(transition));
	}
	
	@Check
	public void checkStateInvariants(hu.bme.mit.gamma.statechart.statechart.State state) {
		handleValidationResultMessage(statechartModelValidator.checkStateInvariants(state));
	}
	
	@Check
	public void checkElseTransitionPriority(Transition transition) {
		handleValidationResultMessage(statechartModelValidator.checkElseTransitionPriority(transition));
	}

	@Check
	public void checkTransitionTriggers(Transition transition) {
		handleValidationResultMessage(statechartModelValidator.checkTransitionTriggers(transition));
	}

	@Check
	public void checkInitialTransition(Transition transition) {
		handleValidationResultMessage(statechartModelValidator.checkInitialTransition(transition));
	}
	
	@Check
	public void checkTransitionTriggers(ElseExpression elseExpression) {
		handleValidationResultMessage(statechartModelValidator.checkTransitionTriggers(elseExpression));
	}
	
	@Check
	public void checkTransitionEventTriggers(PortEventReference portEventReference) {
		handleValidationResultMessage(statechartModelValidator.checkTransitionEventTriggers(portEventReference));
	}
	
	@Check
	public void checkTransitionGuards(Transition transition) {
		handleValidationResultMessage(statechartModelValidator.checkTransitionGuards(transition));
	}
	
	@Check
	public void checkTransitionEventRaisings(RaiseEventAction raiseEvent) {
		handleValidationResultMessage(statechartModelValidator.checkTransitionEventRaisings(raiseEvent));
	}
	
	@Check
	public void checkStateReference(StateReferenceExpression reference) {
		handleValidationResultMessage(statechartModelValidator.checkStateReference(reference));
	}
	
	@Check
	public void checkNodeReachability(StateNode node) {
		handleValidationResultMessage(statechartModelValidator.checkNodeReachability(node));
	}
	
	@Check
	public void checkEntryNodes(EntryState entry) {
		handleValidationResultMessage(statechartModelValidator.checkEntryNodes(entry));
	}
	
	@Check
	public void checkEntryNodeTransitions(Transition transition) {
		handleValidationResultMessage(statechartModelValidator.checkEntryNodeTransitions(transition));
	}
	
	@Check
	public void checkPseudoNodeAcyclicity(PseudoState node) {
		if (StatechartModelDerivedFeatures.getIncomingTransitions(node).stream()
				.anyMatch(it -> it.getSourceState() instanceof hu.bme.mit.gamma.statechart.statechart.State)) {
			// Optimization: starting the traversal from states
			handleValidationResultMessage(statechartModelValidator.checkPseudoNodeAcyclicity(node));
		}
	}
	
	@Check
	public void checkChoiceNodes(ChoiceState choice) {
		handleValidationResultMessage(statechartModelValidator.checkChoiceNodes(choice));
	}
	
	@Check
	public void checkForkNodes(ForkState fork) {
		handleValidationResultMessage(statechartModelValidator.checkForkNodes(fork));
	}
	
	@Check
	public void checkMergeNodes(MergeState merge) {
		handleValidationResultMessage(statechartModelValidator.checkMergeNodes(merge));
	}
	
	@Check
	public void checkJoinNodes(JoinState join) {
		handleValidationResultMessage(statechartModelValidator.checkJoinNodes(join));
	}
	
	@Check
	public void checkPseudoNodeTransitions(Transition transition) {
		handleValidationResultMessage(statechartModelValidator.checkPseudoNodeTransitions(transition));
	}
	
	@Check
	public void checkTimeoutTransitions(hu.bme.mit.gamma.statechart.statechart.State state) {
		handleValidationResultMessage(statechartModelValidator.checkTimeoutTransitions(state));
	}
	
	@Check
	public void checkOutgoingTransitionDeterminism(Transition transition) {
		handleValidationResultMessage(statechartModelValidator.checkOutgoingTransitionDeterminism(transition));
	}
	
	@Check
	public void checkTransitionOcclusion(Transition transition) {
		handleValidationResultMessage(statechartModelValidator.checkTransitionOcclusion(transition));
	}
	
	@Check
	public void checkParallelTransitionAssignments(Transition transition) {
		handleValidationResultMessage(statechartModelValidator.checkParallelTransitionAssignments(transition));
	}
	 
	@Check
	public void checkParallelEventRaisings(Transition transition) {
		handleValidationResultMessage(statechartModelValidator.checkParallelEventRaisings(transition));
	}
	
	@Check
	private void checkTransitionOrientation(Transition transition) {
		handleValidationResultMessage(statechartModelValidator.checkTransitionOrientation(transition));
	}
	
	@Check
	public void checkTimeSpecification(TimeSpecification timeSpecification) {
		handleValidationResultMessage(statechartModelValidator.checkTimeSpecification(timeSpecification));
	}
	
	@Check
	public void checkStatechartInvariants(StatechartDefinition statechart) {
		handleValidationResultMessage(statechartModelValidator.checkStatechartInvariants(statechart));
	}
	
	@Check
	public void checkPortInvariants(Port port) {
		handleValidationResultMessage(statechartModelValidator.checkPortInvariants(port));
	}
	
	// Composite system
	
	@Check
	public void checkName(Package _package) {
		handleValidationResultMessage(statechartModelValidator.checkName(_package));
	}
	
	@Check
	public void checkCircularDependencies(Component component) {
		if (!StatechartModelDerivedFeatures.isStatechart(component)) {
			handleValidationResultMessage(statechartModelValidator.checkCircularDependencies(component));
		}
	}
	
	@Check
	public void checkMultipleImports(Package gammaPackage) {
		handleValidationResultMessage(statechartModelValidator.checkMultipleImports(gammaPackage));
	}
	
	@Check
	public void checkParameters(ComponentInstance instance) {
		handleValidationResultMessage(statechartModelValidator.checkParameters(instance));
	}
	
	@Check
	public void checkComponentInstanceArguments(ComponentInstance instance) {
		handleValidationResultMessage(statechartModelValidator.checkComponentInstanceArguments(instance));
	}
	
	@Check
	public void checkPortBinding(Port port) {
		handleValidationResultMessage(statechartModelValidator.checkPortBinding(port));
	}
	
	@Check
	public void checkComponentInstances(ComponentInstance instance) {
		handleValidationResultMessage(statechartModelValidator.checkComponentInstances(instance));
	}
	
	@Check
	public void checkPortBindingUniqueness(PortBinding portBinding) {
		handleValidationResultMessage(statechartModelValidator.checkPortBindingUniqueness(portBinding));
	}
	
	@Check
	public void checkPortBinding(PortBinding portDefinition) {
		handleValidationResultMessage(statechartModelValidator.checkPortBinding(portDefinition));
	}
	
	@Check
	public void checkInstancePortReference(InstancePortReference reference) {
		handleValidationResultMessage(statechartModelValidator.checkInstancePortReference(reference));
	}
	
	@Check
	public void checkPortBindingWithSimpleChannel(SimpleChannel channel) {
		handleValidationResultMessage(statechartModelValidator.checkPortBindingWithSimpleChannel(channel));	
	}
	
	@Check
	public void checkPortBindingWithBroadcastChannel(BroadcastChannel channel) {
		handleValidationResultMessage(statechartModelValidator.checkPortBindingWithBroadcastChannel(channel));		
	}
	
	@Check
	public void checkChannelProvidedPorts(Channel channel) {
		handleValidationResultMessage(statechartModelValidator.checkChannelProvidedPorts(channel));
	}
	
	@Check
	public void checkChannelRequiredPorts(SimpleChannel channel) {
		handleValidationResultMessage(statechartModelValidator.checkChannelRequiredPorts(channel));
	}
	
	@Check
	public void checkChannelRequiredPorts(BroadcastChannel channel) {
		handleValidationResultMessage(statechartModelValidator.checkChannelRequiredPorts(channel));
	}
	
	@Check
	public void checkChannelInput(Channel channel) {
		handleValidationResultMessage(statechartModelValidator.checkChannelInput(channel));		
	}
	
	@Check
	public void checkSimpleChannelOutput(SimpleChannel channel) {
		handleValidationResultMessage(statechartModelValidator.checkSimpleChannelOutput(channel));
	}
	
	@Check
	public void checkBroadcastChannelOutput(BroadcastChannel channel) {
		handleValidationResultMessage(statechartModelValidator.checkBroadcastChannelOutput(channel));	
	}
	
	@Check
	public void checkCascadeLoopChannels(SimpleChannel channel) {
		handleValidationResultMessage(statechartModelValidator.checkCascadeLoopChannels(channel));
	}
	
	@Check
	public void checkCascadeLoopChannels(BroadcastChannel channel) {
		handleValidationResultMessage(statechartModelValidator.checkCascadeLoopChannels(channel));
	}
	
	// Wrapper
	
	@Check
	public void checkWrapperPortName(Port port) {
		handleValidationResultMessage(statechartModelValidator.checkWrapperPortName(port));
	}
	
	@Check
	public void checkWrapperClock(Clock clock) {
		handleValidationResultMessage(statechartModelValidator.checkWrapperClock(clock));
	}
	
	@Check
	public void checkSynchronousComponentWrapperMultipleEventContainment(AsynchronousAdapter wrapper) {
		handleValidationResultMessage(statechartModelValidator
				.checkAsynchronousAdapterMultipleEventContainment(wrapper));
	}
	
	@Check
	public void checkInputPossibility(AsynchronousAdapter wrapper) {
		handleValidationResultMessage(statechartModelValidator.checkInputPossibility(wrapper));
	}
	
	@Check
	public void checkWrappedPort(AsynchronousAdapter wrapper) {
		handleValidationResultMessage(statechartModelValidator.checkWrappedPort(wrapper));
	}
	
	@Check
	public void checkControlSpecification(ControlSpecification controlSpecification) {
		handleValidationResultMessage(statechartModelValidator.checkControlSpecification(controlSpecification));
	}
	
	@Check
	public void checkMessageQueuePriorities(AsynchronousAdapter wrapper) {
		handleValidationResultMessage(statechartModelValidator.checkMessageQueuePriorities(wrapper));
	}
	
	@Check
	public void checkMessageQueue(MessageQueue queue) {
		handleValidationResultMessage(statechartModelValidator.checkMessageQueue(queue));
	}
	
	@Check
	public void checkAnyPortControls(AsynchronousAdapter adapter) {
		handleValidationResultMessage(statechartModelValidator.checkAnyPortControls(adapter));
	}
	
	@Check
	public void checkMessageQueueAnyEventReferences(AnyPortEventReference anyPortEventReference) {
		handleValidationResultMessage(statechartModelValidator
				.checkMessageQueueAnyEventReferences(anyPortEventReference));
	}
	
	@Check
	public void checkEventPassings(EventPassing eventPassing) {
		handleValidationResultMessage(statechartModelValidator.checkEventPassings(eventPassing));
	}
	
	@Check
	public void checkExecutionLists(CascadeCompositeComponent cascade) {
		handleValidationResultMessage(statechartModelValidator.checkExecutionLists(cascade));
	}
	
	@Check
	public void checkExecutionLists(ScheduledAsynchronousCompositeComponent scheduledComponent) {
		handleValidationResultMessage(statechartModelValidator.checkExecutionLists(scheduledComponent));
	}
	
	@Check
	public void checkComponents(ScheduledAsynchronousCompositeComponent scheduledComponent) {
		handleValidationResultMessage(statechartModelValidator.checkComponents(scheduledComponent));
	}
	
	@Check
	public void checkComponentInstanceReferences(ComponentInstanceReferenceExpression reference) {
		handleValidationResultMessage(statechartModelValidator.checkComponentInstanceReferences(reference));
	}
	
}