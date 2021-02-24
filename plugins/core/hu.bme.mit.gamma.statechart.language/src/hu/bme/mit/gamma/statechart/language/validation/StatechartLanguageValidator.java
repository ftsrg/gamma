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
package hu.bme.mit.gamma.statechart.language.validation;

import java.math.BigInteger;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import java.util.stream.Collectors;

import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.xtext.EcoreUtil2;
import org.eclipse.xtext.validation.Check;

import hu.bme.mit.gamma.action.model.Action;
import hu.bme.mit.gamma.action.model.AssignmentStatement;
import hu.bme.mit.gamma.action.model.Branch;
import hu.bme.mit.gamma.action.model.VariableDeclarationStatement;
import hu.bme.mit.gamma.expression.model.ArgumentedElement;
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition;
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition;
import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.ElseExpression;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression;
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelPackage;
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition;
import hu.bme.mit.gamma.expression.model.NamedElement;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.RationalTypeDefinition;
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeDeclaration;
import hu.bme.mit.gamma.expression.model.TypeReference;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.expression.util.ExpressionType;
import hu.bme.mit.gamma.expression.util.ExpressionUtil;
import hu.bme.mit.gamma.expression.util.ExpressionModelValidator.ValidationResult;
import hu.bme.mit.gamma.expression.util.ExpressionModelValidator.ValidationResultMessage;
import hu.bme.mit.gamma.statechart.composite.AbstractSynchronousCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter;
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponent;
import hu.bme.mit.gamma.statechart.composite.AsynchronousCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.BroadcastChannel;
import hu.bme.mit.gamma.statechart.composite.CascadeCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.Channel;
import hu.bme.mit.gamma.statechart.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference;
import hu.bme.mit.gamma.statechart.composite.CompositeComponent;
import hu.bme.mit.gamma.statechart.composite.CompositeModelPackage;
import hu.bme.mit.gamma.statechart.composite.ControlSpecification;
import hu.bme.mit.gamma.statechart.composite.InstancePortReference;
import hu.bme.mit.gamma.statechart.composite.MessageQueue;
import hu.bme.mit.gamma.statechart.composite.PortBinding;
import hu.bme.mit.gamma.statechart.composite.SimpleChannel;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponent;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.contract.AdaptiveContractAnnotation;
import hu.bme.mit.gamma.statechart.contract.ContractModelPackage;
import hu.bme.mit.gamma.statechart.contract.ScenarioContractAnnotation;
import hu.bme.mit.gamma.statechart.contract.StateContractAnnotation;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.AnyTrigger;
import hu.bme.mit.gamma.statechart.interface_.Clock;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Event;
import hu.bme.mit.gamma.statechart.interface_.EventDeclaration;
import hu.bme.mit.gamma.statechart.interface_.EventDirection;
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression;
import hu.bme.mit.gamma.statechart.interface_.EventReference;
import hu.bme.mit.gamma.statechart.interface_.EventTrigger;
import hu.bme.mit.gamma.statechart.interface_.Interface;
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelPackage;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.interface_.Persistency;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.statechart.interface_.RealizationMode;
import hu.bme.mit.gamma.statechart.interface_.SimpleTrigger;
import hu.bme.mit.gamma.statechart.interface_.TimeSpecification;
import hu.bme.mit.gamma.statechart.interface_.Trigger;
import hu.bme.mit.gamma.statechart.phase.MissionPhaseStateAnnotation;
import hu.bme.mit.gamma.statechart.phase.MissionPhaseStateDefinition;
import hu.bme.mit.gamma.statechart.phase.PhaseModelPackage;
import hu.bme.mit.gamma.statechart.phase.VariableBinding;
import hu.bme.mit.gamma.statechart.statechart.AnyPortEventReference;
import hu.bme.mit.gamma.statechart.statechart.ChoiceState;
import hu.bme.mit.gamma.statechart.statechart.ClockTickReference;
import hu.bme.mit.gamma.statechart.statechart.EntryState;
import hu.bme.mit.gamma.statechart.statechart.ForkState;
import hu.bme.mit.gamma.statechart.statechart.JoinState;
import hu.bme.mit.gamma.statechart.statechart.MergeState;
import hu.bme.mit.gamma.statechart.statechart.OpaqueTrigger;
import hu.bme.mit.gamma.statechart.statechart.OrthogonalRegionSchedulingOrder;
import hu.bme.mit.gamma.statechart.statechart.PortEventReference;
import hu.bme.mit.gamma.statechart.statechart.PseudoState;
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction;
import hu.bme.mit.gamma.statechart.statechart.Region;
import hu.bme.mit.gamma.statechart.statechart.SchedulingOrder;
import hu.bme.mit.gamma.statechart.statechart.SetTimeoutAction;
import hu.bme.mit.gamma.statechart.statechart.StateNode;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.statechart.statechart.StatechartModelPackage;
import hu.bme.mit.gamma.statechart.statechart.TimeoutDeclaration;
import hu.bme.mit.gamma.statechart.statechart.Transition;
import hu.bme.mit.gamma.statechart.statechart.TransitionIdAnnotation;
import hu.bme.mit.gamma.statechart.statechart.TransitionPriority;
import hu.bme.mit.gamma.statechart.util.StatechartModelValidator;

/**
 * This class contains custom validation rules. 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
public class StatechartLanguageValidator extends AbstractStatechartLanguageValidator {
	
	ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE;
	StatechartModelValidator statechartModelValidator = StatechartModelValidator.INSTANCE;
	
	// Some elements can have the same name
	
	
	public void handleValidationResultMessage(Collection<ValidationResultMessage> collection) {
		for (ValidationResultMessage element: collection) {
			if (element.getResult() == ValidationResult.ERROR) {
				if (element.getReferenceInfo().hasInteger() && element.getReferenceInfo().hasSource()) {
					error(element.getResultText(), element.getReferenceInfo().getSource(), element.getReferenceInfo().getReference(), element.getReferenceInfo().getIndex());
				} else if (element.getReferenceInfo().hasInteger() && !(element.getReferenceInfo().hasSource())) {
					error(element.getResultText(), element.getReferenceInfo().getReference(), element.getReferenceInfo().getIndex());
				} else if (element.getReferenceInfo().hasSource() && !(element.getReferenceInfo().hasInteger())) {
					error(element.getResultText(), element.getReferenceInfo().getSource(), element.getReferenceInfo().getReference());
				} else {
					error(element.getResultText(), element.getReferenceInfo().getReference());
				}
			}else if (element.getResult() == ValidationResult.WARNING) {
				if (element.getReferenceInfo().hasInteger() && element.getReferenceInfo().hasSource()) {
					warning(element.getResultText(), element.getReferenceInfo().getSource(), element.getReferenceInfo().getReference(), element.getReferenceInfo().getIndex());
				} else if (element.getReferenceInfo().hasInteger() && !(element.getReferenceInfo().hasSource())) {
					warning(element.getResultText(), element.getReferenceInfo().getReference(), element.getReferenceInfo().getIndex());
				} else if (element.getReferenceInfo().hasSource() && !(element.getReferenceInfo().hasInteger())) {
					warning(element.getResultText(), element.getReferenceInfo().getSource(), element.getReferenceInfo().getReference());
				} else {
					warning(element.getResultText(), element.getReferenceInfo().getReference());
				}
			}else if (element.getResult() == ValidationResult.INFO) {
				if (element.getReferenceInfo().hasInteger() && element.getReferenceInfo().hasSource()) {
					info(element.getResultText(), element.getReferenceInfo().getSource(), element.getReferenceInfo().getReference(), element.getReferenceInfo().getIndex());
				} else if (element.getReferenceInfo().hasInteger() && !(element.getReferenceInfo().hasSource())) {
					info(element.getResultText(), element.getReferenceInfo().getReference(), element.getReferenceInfo().getIndex());
				} else if (element.getReferenceInfo().hasSource() && !(element.getReferenceInfo().hasInteger())) {
					info(element.getResultText(), element.getReferenceInfo().getSource(), element.getReferenceInfo().getReference());
				} else {
					info(element.getResultText(), element.getReferenceInfo().getReference());
				}
			}
		}
	}
	
	
	
	@Check
	@Override
	public void checkNameUniqueness(NamedElement element) {
		handleValidationResultMessage(statechartModelValidator.checkNameUniqueness(element));
	}
	
	// Not supported elements
	
	@Check
	public void checkComponentSepratation(Component component) {
		handleValidationResultMessage(statechartModelValidator.checkComponentSepratation(component));
	}
	
	@Check
	public void checkUnsupportedTriggers(OpaqueTrigger trigger) {
		handleValidationResultMessage(statechartModelValidator.checkUnsupportedTriggers(trigger));
	}
	
	@Check
	public void checkUnsupportedVariableTypes(VariableDeclaration variable) {
		handleValidationResultMessage(statechartModelValidator.checkUnsupportedVariableTypes(variable));
	}
	/*@Check
	public void checkUnsupportedExpressionStatements(ExpressionStatement expressionStatement) {
		error("Expression statements are not supported in the GSL.", ActionModelPackage.Literals.EXPRESSION_STATEMENT__EXPRESSION);
	}*/
	
	// Expressions
	
	@Check
	public void checkArgumentTypes(ArgumentedElement element) {
		handleValidationResultMessage(statechartModelValidator.checkArgumentTypes(element));
	}
	
	// Interfaces
	
	@Check
	public void checkInterfaceInheritance(Interface gammaInterface) {
		handleValidationResultMessage(statechartModelValidator.checkInterfaceInheritance(gammaInterface));
	}
	
	private Interface getParentInterfaces(Interface initialInterface, Interface actualInterface) {
		return statechartModelValidator.getParentInterfaces(initialInterface, actualInterface);
	}
	
	@Check
	public void checkEventPersistency(Event event) {
		handleValidationResultMessage(statechartModelValidator.checkEventPersistency(event));
	}
	
	@Check
	public void checkParameterName(Event event) {
		handleValidationResultMessage(statechartModelValidator.checkParameterName(event));
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
	public void checkStateDefinition(MissionPhaseStateDefinition stateDefinition) {
		handleValidationResultMessage(statechartModelValidator.checkStateDefinition(stateDefinition));
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
	
	//FIXME commented to be able to run after changes
	/*@Check
	public void checkUnusedDeclarations(Declaration declaration) {
		// Not checking parameter declarations of events
		if (declaration.eContainer() instanceof Event) {
			return;
		}
		boolean isReferred;
		if (declaration instanceof TypeDeclaration) {
			isReferred = EcoreUtil2.getAllContentsOfType(EcoreUtil2.getRootContainer(declaration), TypeReference.class)
					.stream().anyMatch(it -> it.getReference() == declaration);
		}
		else {
			isReferred = EcoreUtil2.getAllContentsOfType(EcoreUtil2.getRootContainer(declaration), ReferenceExpression.class)
					.stream().anyMatch(it -> it.getDeclaration() == declaration);
			if (!isReferred) {
				isReferred = EcoreUtil2.getAllContentsOfType(EcoreUtil2.getRootContainer(declaration), VariableBinding.class)
						.stream().anyMatch(it -> it.getStatechartVariable() == declaration);
			}
		}
		if (!isReferred) {
			if (declaration instanceof TypeDeclaration) {
				// Type declarations can be referred from different package
				return;
			}
			warning("This declaration is not used.", ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME);
		}
	}*/
	
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
	public void checkElseTransitionPriority(Transition transition) {
		handleValidationResultMessage(statechartModelValidator.checkElseTransitionPriority(transition));
	}
	
	public boolean needsTrigger(Transition transition) {
		return statechartModelValidator.needsTrigger(transition);
	}
	
	@Check
	public void checkTransitionTriggers(Transition transition) {
		handleValidationResultMessage(statechartModelValidator.checkTransitionTriggers(transition));
	}
	
	@Check
	public void checkTransitionTriggers(ElseExpression elseExpression) {
		handleValidationResultMessage(statechartModelValidator.checkTransitionTriggers(elseExpression));
	}
	
	@Check
	public void checkTransitionEventTriggers(PortEventReference portEventReference) {
		handleValidationResultMessage(statechartModelValidator.checkTransitionEventRaisings(null));
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
	public void checkNodeReachability(StateNode node) {
		handleValidationResultMessage(statechartModelValidator.checkNodeReachability(node));
	}
	
	private boolean hasIncomingTransition(StateNode node) {
		return statechartModelValidator.hasIncomingTransition(node);
	}
	
	private boolean isLoopEdge(Transition transition) {
		return statechartModelValidator.isLoopEdge(transition);
	}
	
	private boolean allTransitionsAreLoop(StateNode node) {
		return statechartModelValidator.allTransitionsAreLoop(node);
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
		handleValidationResultMessage(statechartModelValidator.checkPseudoNodeAcyclicity(node));
	}
	
	private void checkPseudoNodeAcyclicity(PseudoState node, Collection<PseudoState> visitedNodes) {
		handleValidationResultMessage(statechartModelValidator.checkPseudoNodeAcyclicity(node, visitedNodes));
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
	
	private Transition checkTransitionDeterminism(Transition transition, Collection<Transition> transitions) {
		return statechartModelValidator.checkTransitionDeterminism(transition, transitions);
	}
	
	private boolean isTransitionTriggeredByPortEvent(Transition transition, Port port, Event event) {
		return statechartModelValidator.isTransitionTriggeredByPortEvent(transition, port, event);
	}
	
	private boolean isTransitionTriggeredByPortEvent(Transition transition, Port port) {
		return statechartModelValidator.isTransitionTriggeredByPortEvent(transition, port);
	}
	
	@Check
	public void checkTransitionOcclusion(Transition transition) {
		statechartModelValidator.checkTransitionOcclusion(transition);
	}
	
	private Collection<Transition> getOutgoingTransitionsOfAncestors(StateNode source) {
		return statechartModelValidator.getOutgoingTransitionsOfAncestors(source);
	}
	
	
	@Check
	public void checkParallelTransitionAssignments(Transition transition) {
		handleValidationResultMessage(statechartModelValidator.checkParallelTransitionAssignments(transition));
	}
	 
	@Check
	public void checkParallelEventRaisings(Transition transition) {
		handleValidationResultMessage(statechartModelValidator.checkParallelEventRaisings(transition));
	}
	
	private Transition getSameTriggedTransitionOfParallelRegions(Transition transition) {
		return statechartModelValidator.getSameTriggedTransitionOfParallelRegions(transition);
	}
	
	private Collection<Transition> getTransitionsOfSiblingRegions(Collection<Region> siblingRegions) {
		return statechartModelValidator.getTransitionsOfSiblingRegions(siblingRegions);
	}
	
	private Declaration getSameVariableOfAssignments(Transition lhs, Transition rhs) {
		return statechartModelValidator.getSameVariableOfAssignments(lhs, rhs);
	}
	
	private Entry<Port, Event> getSameEventOfParameteredRaisings(Transition lhs, Transition rhs) {
		return statechartModelValidator.getSameEventOfParameteredRaisings(lhs, rhs);
	}
	
	@Check
	private void checkTransitionOrientation(Transition transition) {
		handleValidationResultMessage(statechartModelValidator.checkTransitionOrientation(transition));
	}
	
	@Check
	public void checkTimeSpecification(TimeSpecification timeSpecification) {
		handleValidationResultMessage(statechartModelValidator.checkTimeSpecification(timeSpecification));
	}
	
	// Composite system
	
	@Check
	public void checkName(Package _package) {
		handleValidationResultMessage(statechartModelValidator.checkName(_package));
	}
	
	@Check
	public void checkCircularDependencies(Package statechart) {
		handleValidationResultMessage(statechartModelValidator.checkCircularDependencies(statechart));
	}
	
	private Package getReferredPackages(Package initialStatechart, Package statechart) {
		return statechartModelValidator.getReferredPackages(initialStatechart, statechart);
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
	public void checkUnusedInstancePort(ComponentInstance instance) {
		handleValidationResultMessage(statechartModelValidator.checkUnusedInstancePort(instance));
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
	
	private boolean isBroadcast(Port port) {
		return statechartModelValidator.isBroadcast(port);
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
	
	private boolean equals(InstancePortReference p1, InstancePortReference p2) {
		return statechartModelValidator.equals(p1, p2);
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
		handleValidationResultMessage(statechartModelValidator.checkSynchronousComponentWrapperMultipleEventContainment(wrapper));
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
	
	private Collection<Event> getSemanticEvents(Collection<? extends Port> ports, EventDirection direction) {
		return statechartModelValidator.getSemanticEvents(ports, direction);
	}

	private EventDirection getOppositeDirection(EventDirection direction) {
		return statechartModelValidator.getOppositeDirection(direction);
	}

	/**
	 * The parent interfaces are taken into considerations as well.
	 */
	private Collection<Event> getAllEvents(Interface anInterface, EventDirection oppositeDirection) {
		return statechartModelValidator.getAllEvents(anInterface, oppositeDirection);
	}
	
	private boolean isContainedInQueue(Port port, Event event, AsynchronousAdapter wrapper) {
		return statechartModelValidator.isContainedInQueue(port, event, wrapper);
	}
	
	private boolean isContainedInQueue(Clock clock, AsynchronousAdapter wrapper) {
		return statechartModelValidator.isContainedInQueue(clock, wrapper);
	}
	
	@Check
	public void checkAnyPortControls(AsynchronousAdapter adapter) {
		handleValidationResultMessage(statechartModelValidator.checkAnyPortControls(adapter));
	}
	
	@Check
	public void checkMessageQueueAnyEventReferences(AnyPortEventReference anyPortEventReference) {
		handleValidationResultMessage(statechartModelValidator.checkMessageQueueAnyEventReferences(anyPortEventReference));
	}
	
	@Check
	public void checkExecutionLists(CascadeCompositeComponent cascade) {
		handleValidationResultMessage(statechartModelValidator.checkExecutionLists(cascade));
	}
	
	@Check
	public void checkComponentInstanceReferences(ComponentInstanceReference reference) {
		handleValidationResultMessage(statechartModelValidator.checkComponentInstanceReferences(reference));
	}
	

}