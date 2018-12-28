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

import hu.bme.mit.gamma.constraint.model.ConstantDeclaration;
import hu.bme.mit.gamma.constraint.model.ConstraintModelPackage;
import hu.bme.mit.gamma.constraint.model.Declaration;
import hu.bme.mit.gamma.constraint.model.Expression;
import hu.bme.mit.gamma.constraint.model.ParameterDeclaration;
import hu.bme.mit.gamma.constraint.model.ReferenceExpression;
import hu.bme.mit.gamma.constraint.model.Type;
import hu.bme.mit.gamma.constraint.model.VariableDeclaration;
import hu.bme.mit.gamma.statechart.model.Action;
import hu.bme.mit.gamma.statechart.model.AnyPortEventReference;
import hu.bme.mit.gamma.statechart.model.AnyTrigger;
import hu.bme.mit.gamma.statechart.model.AssignmentAction;
import hu.bme.mit.gamma.statechart.model.ChoiceState;
import hu.bme.mit.gamma.statechart.model.Clock;
import hu.bme.mit.gamma.statechart.model.ClockTickReference;
import hu.bme.mit.gamma.statechart.model.Component;
import hu.bme.mit.gamma.statechart.model.EntryState;
import hu.bme.mit.gamma.statechart.model.EventReference;
import hu.bme.mit.gamma.statechart.model.EventTrigger;
import hu.bme.mit.gamma.statechart.model.ForkState;
import hu.bme.mit.gamma.statechart.model.JoinState;
import hu.bme.mit.gamma.statechart.model.MergeState;
import hu.bme.mit.gamma.statechart.model.Package;
import hu.bme.mit.gamma.statechart.model.Port;
import hu.bme.mit.gamma.statechart.model.PortEventReference;
import hu.bme.mit.gamma.statechart.model.PseudoState;
import hu.bme.mit.gamma.statechart.model.RaiseEventAction;
import hu.bme.mit.gamma.statechart.model.RealizationMode;
import hu.bme.mit.gamma.statechart.model.Region;
import hu.bme.mit.gamma.statechart.model.SetTimeoutAction;
import hu.bme.mit.gamma.statechart.model.SimpleTrigger;
import hu.bme.mit.gamma.statechart.model.StateNode;
import hu.bme.mit.gamma.statechart.model.StatechartDefinition;
import hu.bme.mit.gamma.statechart.model.StatechartModelPackage;
import hu.bme.mit.gamma.statechart.model.TimeoutDeclaration;
import hu.bme.mit.gamma.statechart.model.Transition;
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousComponent;
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousCompositeComponent;
import hu.bme.mit.gamma.statechart.model.composite.BroadcastChannel;
import hu.bme.mit.gamma.statechart.model.composite.CascadeCompositeComponent;
import hu.bme.mit.gamma.statechart.model.composite.Channel;
import hu.bme.mit.gamma.statechart.model.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.model.composite.CompositeComponent;
import hu.bme.mit.gamma.statechart.model.composite.CompositePackage;
import hu.bme.mit.gamma.statechart.model.composite.ControlSpecification;
import hu.bme.mit.gamma.statechart.model.composite.InstancePortReference;
import hu.bme.mit.gamma.statechart.model.composite.MessageQueue;
import hu.bme.mit.gamma.statechart.model.composite.PortBinding;
import hu.bme.mit.gamma.statechart.model.composite.SimpleChannel;
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponentWrapper;
import hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.model.interface_.Event;
import hu.bme.mit.gamma.statechart.model.interface_.EventDeclaration;
import hu.bme.mit.gamma.statechart.model.interface_.EventDirection;
import hu.bme.mit.gamma.statechart.model.interface_.Interface;

/**
 * This class contains custom validation rules. 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
public class StatechartLanguageValidator extends AbstractStatechartLanguageValidator {
	
	// Interfaces
	
	@Check
	public void checkInterfaceInheritance(Interface gammaInterface) {
		for (Interface parent : gammaInterface.getParents()) {
			Interface parentInterface = getParentInterfaces(gammaInterface, parent);
			if (parentInterface != null) {
				error("This interface is in a parent circle, referred by " + parentInterface.getName() + "!" 
						+ "Interfaces must have an acyclical parent hierarchy!", ConstraintModelPackage.Literals.NAMED_ELEMENT__NAME);
			}
		}
	}
	
	private Interface getParentInterfaces(Interface initialInterface, Interface actualInterface) {
		if (initialInterface == actualInterface) {
			return initialInterface;
		}
		for (Interface parent : actualInterface.getParents()) {
			if (parent == initialInterface) {
				return actualInterface;
			}
		}
		for (Interface parent : actualInterface.getParents()) {
			Interface parentInterface = getParentInterfaces(initialInterface, parent);
			if (parentInterface != null) {
				return parentInterface;
			}
		}
		return null;
	}
	
	// Statechart
	
	@Check
	public void checkImports(Package _package) {
		Collection<Interface> usedInterfaces = new HashSet<Interface>();
		Collection<Component> usedComponents = new HashSet<Component>();
		// Collecting the used components and interfaces
		for (Component component : _package.getComponents()) {
			for (Port port : component.getPorts()) {
				usedInterfaces.add(port.getInterfaceRealization().getInterface());
			}
			if (component instanceof CompositeComponent) {
				Collection<? extends ComponentInstance> derivedComponents = StatechartModelDerivedFeatures
						.getDerivedComponents((CompositeComponent) component);
				for (ComponentInstance componentInstance : derivedComponents) {
					usedComponents.add(StatechartModelDerivedFeatures.getDerivedType(componentInstance));
				}
			}
			if (component instanceof SynchronousComponentWrapper) {
				usedComponents.add(((SynchronousComponentWrapper) component).getWrappedComponent());
			}
		}
		// Checking the imports
		for (Package importedPackage : _package.getImports()) {
			Collection<Interface> interfaces = new HashSet<Interface>(importedPackage.getInterfaces());
			interfaces.retainAll(usedInterfaces);
			Collection<Component> components = new HashSet<Component>(importedPackage.getComponents());
			components.retainAll(usedComponents);
			if (interfaces.isEmpty() && components.isEmpty()) {
				int index = _package.getImports().indexOf(importedPackage);
				warning("No component or interface from this imported package is used.", StatechartModelPackage.Literals.PACKAGE__IMPORTS, index);
			}
		}
	}
	
	@Check
	public void checkRegionEntries(Region region) {
		Collection<StateNode> entries = region.getStateNodes().stream().filter(it -> it instanceof EntryState).collect(Collectors.toSet());
		if (entries.isEmpty()) {
			error("A region must have a single entry node.", ConstraintModelPackage.Literals.NAMED_ELEMENT__NAME);
		}
		else if (entries.size() > 1) {
			for (StateNode entry : entries) {
				error("A region must have a single entry node.", entry, ConstraintModelPackage.Literals.NAMED_ELEMENT__NAME);
			}
		}
	}
	
	@Check
	public void checkUnusedDeclarations(Declaration declaration) {
		// Not checking parameter declarations of events
		if (declaration.eContainer() instanceof Event) {
			return;
		}
		boolean isReferred = EcoreUtil2.getAllContentsOfType(EcoreUtil2.getRootContainer(declaration), ReferenceExpression.class)
								.stream().anyMatch(it -> it.getDeclaration() == declaration);
		if (!isReferred) {
			warning("This declaration is not used.", ConstraintModelPackage.Literals.NAMED_ELEMENT__NAME);
		}
	}
	
	@Check
	public void checkUnusedTimeoutDeclarations(TimeoutDeclaration declaration) {
		Collection<SetTimeoutAction> timeoutSettings = EcoreUtil2.getAllContentsOfType(EcoreUtil2.getRootContainer(declaration),
				SetTimeoutAction.class).stream().filter(it -> it.getTimeoutDeclaration() == declaration).collect(Collectors.toSet());
		if (timeoutSettings.isEmpty()) {
			warning("This declaration is not used.", ConstraintModelPackage.Literals.NAMED_ELEMENT__NAME);
		}
		if (timeoutSettings.size() > 1) {
			for (SetTimeoutAction timeoutSetting : timeoutSettings) {
				error("This timeout declaration is set more than once.", timeoutSetting, StatechartModelPackage.Literals.TIMEOUT_ACTION__TIMEOUT_DECLARATION);
			}
		}
	}
	
	public boolean needsTrigger(Transition transition) {
		return !(transition.getSourceState() instanceof EntryState || transition.getSourceState() instanceof ChoiceState ||
				transition.getSourceState() instanceof MergeState || transition.getSourceState() instanceof ForkState ||
				transition.getSourceState() instanceof JoinState);
	}
	
	@Check
	public void checkTransitionTriggers(Transition transition) {
		// These nodes do not need a trigger
		if (!needsTrigger(transition)) {
			return;
		}
		if (transition.getTrigger() == null) {
			error("This transition must have a trigger.", StatechartModelPackage.Literals.TRANSITION__TRIGGER);
		}
	}
	
	@Check
	public void checkTransitionEventTriggers(PortEventReference portEventReference) {
		EObject eventTrigger = portEventReference.eContainer();
		if (eventTrigger instanceof EventTrigger) {
			EObject transition = eventTrigger.eContainer();
			if (transition instanceof Transition) {
				// If it is a transition trigger
				Port port = portEventReference.getPort();
				Event event = portEventReference.getEvent();
				if (!getSemanticEvents(Collections.singleton(port), EventDirection.IN).contains(event)) {
					error("This event is not an in event.", StatechartModelPackage.Literals.PORT_EVENT_REFERENCE__EVENT);
				}
			}
		}
	}
	
	@Check
	public void checkTransitionGuards(Transition transition) {
		if (transition.getGuard() != null) {
			Expression guard = transition.getGuard();
			if (!typeDeterminator.isBoolean(guard)) {
				error("This guard is not a boolean expression.", StatechartModelPackage.Literals.TRANSITION__GUARD);
			}
		}
	}
	
	@Check
	public void checkTransitionEventRaisings(RaiseEventAction raiseEvent) {
		Port port = raiseEvent.getPort();
		Event event = raiseEvent.getEvent();
		if (!getSemanticEvents(Collections.singleton(port), EventDirection.OUT).contains(event)) {
			error("This event is not an out event.", StatechartModelPackage.Literals.RAISE_EVENT_ACTION__EVENT);
		}
		if (!raiseEvent.getParameters().isEmpty() && raiseEvent.getEvent().getParameterDeclarations().isEmpty()) {
			error("This event is not parametric.", StatechartModelPackage.Literals.RAISE_EVENT_ACTION__EVENT);
		}
	}
	
	@Check
	public void checkAssignmentActions(AssignmentAction assignment) {
		ReferenceExpression reference = (ReferenceExpression) assignment.getLhs();
		// Constant
		if (reference.getDeclaration() instanceof ConstantDeclaration) {
			error("Constants cannot be assigned a value.", StatechartModelPackage.Literals.ASSIGNMENT_ACTION__LHS);
		}
		// Other assignment type checking
		if (reference.getDeclaration() instanceof VariableDeclaration) {
			VariableDeclaration variableDeclaration = (VariableDeclaration) reference.getDeclaration();
			try {
				Type variableDeclarationType = variableDeclaration.getType();
				ExpressionType rightHandSideExpressionType = typeDeterminator.getType(assignment.getRhs());
				if (!typeDeterminator.equals(variableDeclarationType, rightHandSideExpressionType)) {
					error("The types of the variable declaration and the right hand side expression are not the same: " +
							typeDeterminator.transform(variableDeclarationType).toString().toLowerCase() + " and " +
							rightHandSideExpressionType.toString().toLowerCase() + ".",
							StatechartModelPackage.Literals.ASSIGNMENT_ACTION__RHS);
				} 
			} catch (Exception exception) {
				// There is a type error on a lower level, no need to display the error message on this level too
			}
		}
	}
	
	@Check
	public void checkNodeReachability(StateNode node) {
		// These nodes do not need incoming transitions
		if (node instanceof EntryState) {
			return;
		}
		if (!hasIncomingTransition(node) || (!StatechartModelDerivedFeatures.getIncomingTransitions(node).isEmpty()
				&& allTransitionsAreLoop(node))) {
			error("This node is unreachable.", ConstraintModelPackage.Literals.NAMED_ELEMENT__NAME);
		}
	}
	
	private boolean hasIncomingTransition(StateNode node) {
		boolean hasIncomingTransition = !StatechartModelDerivedFeatures.getIncomingTransitions(node).isEmpty();
		if (hasIncomingTransition) {
			return true;
		}
		// Checking child nodes of composite state node with incoming transitions 
		if (node instanceof hu.bme.mit.gamma.statechart.model.State) {
			hu.bme.mit.gamma.statechart.model.State stateNode = (hu.bme.mit.gamma.statechart.model.State) node;
			Set<StateNode> childNodes = new HashSet<StateNode>();
			stateNode.getRegions().stream().map(it -> it.getStateNodes()).forEach(it -> childNodes.addAll(it));
			for (StateNode childNode : childNodes) {
				if (hasIncomingTransition(childNode)) {
					return true;
				}
			}
		}
		return false;
	}
	
	private boolean isLoopEdge(Transition transition) {
		return transition.getSourceState() == transition.getTargetState();
	}
	
	private boolean allTransitionsAreLoop(StateNode node) {
		Collection<Transition> incomingTransitions = StatechartModelDerivedFeatures.getIncomingTransitions(node);
		Collection<Transition> outgoingTransitions = StatechartModelDerivedFeatures.getOutgoingTransitions(node);
		if (incomingTransitions.size() != outgoingTransitions.size()) {
			return false;
		}
		incomingTransitions.removeAll(outgoingTransitions);
		if (!incomingTransitions.isEmpty()) {
			return false;
		}
		// The incoming and outgoing transitions are the same
		for (Transition outgoingTransition : outgoingTransitions) {
			if (!isLoopEdge(outgoingTransition)) {
				return false;
			}
		}
		return true;
	}
	
	@Check
	public void checkEntryNodes(EntryState entry) {
		if (hasIncomingTransition(entry)) {
			error("Entry nodes must not have incoming transitions.", ConstraintModelPackage.Literals.NAMED_ELEMENT__NAME);
		}
		if (StatechartModelDerivedFeatures.getOutgoingTransitions(entry).size() > 1) {
			error("Entry nodes must have a single outgoing transition.", ConstraintModelPackage.Literals.NAMED_ELEMENT__NAME);
		}
	}
	
	@Check
	public void checkEntryNodeTransitions(Transition transition) {
		if (!(transition.getSourceState() instanceof EntryState)) {
			return;
		}
		if (transition.getTrigger() != null) {
			error("Entry node transitions must not have triggers.", StatechartModelPackage.Literals.TRANSITION__TRIGGER);
		}
		if (transition.getGuard() != null) {
			error("Entry node transitions must not have guards.", StatechartModelPackage.Literals.TRANSITION__GUARD);
		}
	}
	
	@Check
	public void checkPseudoNodeAcyclicity(PseudoState node) {
		checkPseudoNodeAcyclicity(node, new HashSet<PseudoState>());
	}
	
	private void checkPseudoNodeAcyclicity(PseudoState node, Collection<PseudoState> visitedNodes) {
		visitedNodes.add(node);
		for (Transition outgoingTransition : StatechartModelDerivedFeatures.getOutgoingTransitions(node)) {
			StateNode target = outgoingTransition.getTargetState();
			if (target instanceof PseudoState) {
				if (visitedNodes.contains(target)) {
					error("This transition creates a circle of pseudo nodes, which is forbidden.", outgoingTransition,
							StatechartModelPackage.Literals.TRANSITION__TARGET_STATE);
					return;
				}
				checkPseudoNodeAcyclicity((PseudoState) target, visitedNodes);
			}
		}
		// Node is removed as only directed cycles are erronoeus, indirected ones are permitted
		visitedNodes.remove(node);
	}
	
	@Check
	public void checkChoiceNodes(ChoiceState choice) {
		Collection<Transition> incomingTransitions = StatechartModelDerivedFeatures.getIncomingTransitions(choice);
		int incomingTransitionSize = incomingTransitions.size();
		if (incomingTransitionSize != 1) {
			error("Choice nodes must have a single incoming transition.", ConstraintModelPackage.Literals.NAMED_ELEMENT__NAME);
		}
		Collection<Transition> outgoingTransitions = StatechartModelDerivedFeatures.getOutgoingTransitions(choice);
		int outgoingTransitionSize = outgoingTransitions.size();
		if (outgoingTransitionSize == 1) {
			warning("Choice nodes should have at least two outgoing transitions.", ConstraintModelPackage.Literals.NAMED_ELEMENT__NAME);
		}
		else if (outgoingTransitionSize < 1) {
			error("A choice node must have at least one outgoing transition.", ConstraintModelPackage.Literals.NAMED_ELEMENT__NAME);
		}
	}
	
	@Check
	public void checkForkNodes(ForkState fork) {
		Collection<Transition> incomingTransitions = StatechartModelDerivedFeatures.getIncomingTransitions(fork);
		int incomingTransitionSize = incomingTransitions.size();
		if (incomingTransitionSize != 1) {
			error("Fork nodes must have a single incoming transition.", ConstraintModelPackage.Literals.NAMED_ELEMENT__NAME);
		}
		Collection<Transition> outgoingTransitions = StatechartModelDerivedFeatures.getOutgoingTransitions(fork);
		int outgoingTransitionSize = outgoingTransitions.size();
		if (outgoingTransitionSize == 1) {
			warning("Fork nodes should have at least two outgoing transitions.", ConstraintModelPackage.Literals.NAMED_ELEMENT__NAME);
		}
		else if (outgoingTransitionSize < 1) {
			error("A fork node must have at least one outgoing transition.", ConstraintModelPackage.Literals.NAMED_ELEMENT__NAME);
		}
		// Targets of fork nodes must always be States
		for (Transition transition : StatechartModelDerivedFeatures.getOutgoingTransitions(fork)) {
			StateNode target = transition.getTargetState();
			if (!(target instanceof hu.bme.mit.gamma.statechart.model.State)) {
				error("Targets of outgoing transitions of fork nodes must be of type State.", ConstraintModelPackage.Literals.NAMED_ELEMENT__NAME);
				error("Targets of outgoing transitions of fork nodes must be of type State.", transition, StatechartModelPackage.Literals.TRANSITION__TARGET_STATE);
			}
		}
		// TODO or a join state should be reachable in accordance with the well-formedness rules
	}
	
	@Check
	public void checkMergeNodes(MergeState merge) {
		Collection<Transition> incomingTransitions = StatechartModelDerivedFeatures.getIncomingTransitions(merge);
		int incomingTransitionSize = incomingTransitions.size();
		if (incomingTransitionSize == 1) {
			warning("Merge nodes should have at least two incoming transitions.", ConstraintModelPackage.Literals.NAMED_ELEMENT__NAME);
		}
		else if (incomingTransitionSize < 1) {
			error("A merge node must have at least one incoming transition.", ConstraintModelPackage.Literals.NAMED_ELEMENT__NAME);
		}
		Collection<Transition> outgoingTransitions = StatechartModelDerivedFeatures.getOutgoingTransitions(merge);
		int outgoingTransitionSize = outgoingTransitions.size();
		if (outgoingTransitionSize != 1) {
			error("Merge nodes must have a single outgoing transition.", ConstraintModelPackage.Literals.NAMED_ELEMENT__NAME);
		}
	}
	
	@Check
	public void checkJoinNodes(JoinState join) {
		Collection<Transition> incomingTransitions = StatechartModelDerivedFeatures.getIncomingTransitions(join);
		int incomingTransitionSize = incomingTransitions.size();
		if (incomingTransitionSize == 1) {
			warning("Join nodes should have at least two incoming transitions.", ConstraintModelPackage.Literals.NAMED_ELEMENT__NAME);
		}
		else if (incomingTransitionSize < 1) {
			error("A join node must have at least one incoming transition.", ConstraintModelPackage.Literals.NAMED_ELEMENT__NAME);
		}
		Collection<Transition> outgoingTransitions = StatechartModelDerivedFeatures.getOutgoingTransitions(join);
		int outgoingTransitionSize = outgoingTransitions.size();
		if (outgoingTransitionSize != 1) {
			error("Join nodes must have a single outgoing transition.", ConstraintModelPackage.Literals.NAMED_ELEMENT__NAME);
		}
		// Sources of join nodes must always be States
		for (Transition transition : StatechartModelDerivedFeatures.getIncomingTransitions(join)) {
			StateNode source = transition.getSourceState();
			if (!(source instanceof hu.bme.mit.gamma.statechart.model.State)) {
				error("Sources of incoming transitions of join nodes must be of type State.", ConstraintModelPackage.Literals.NAMED_ELEMENT__NAME);
				error("Sources of incoming transitions of join nodes must be of type State.", transition, StatechartModelPackage.Literals.TRANSITION__SOURCE_STATE);
			}
		}
		// TODO or a fork state should be reachable in accordance with the well-formedness rules
	}
	
	@Check
	public void checkChoiceNodeTransitions(Transition transition) {
		StateNode source = transition.getSourceState();
		StateNode target = transition.getTargetState();
		if (source instanceof ChoiceState) {
			if (transition.getTrigger() != null) {
				error("Transitions from choice nodes must not have triggers.", StatechartModelPackage.Literals.TRANSITION__TRIGGER);
			}
			if (transition.getGuard() == null) {
				error("Transitions from choice nodes must have guards.", StatechartModelPackage.Literals.TRANSITION__GUARD);
			}
		}
		// If the target is a choice, everything is permitted
		if (source instanceof ForkState) {
			if (transition.getTrigger() != null) {
				error("Transitions from fork nodes must not have triggers.", StatechartModelPackage.Literals.TRANSITION__TRIGGER);
			}
			if (transition.getGuard() != null) {
				error("Transitions from fork nodes must not have guards.", StatechartModelPackage.Literals.TRANSITION__GUARD);
			}
		}
		// If the target is a fork, everything is permitted
		if (source instanceof MergeState) {
			if (transition.getTrigger() != null) {
				error("Transitions from merge nodes must not have triggers.", StatechartModelPackage.Literals.TRANSITION__TRIGGER);
			}
			if (transition.getGuard() != null) {
				error("Transitions from merge nodes must not have guards.", StatechartModelPackage.Literals.TRANSITION__GUARD);
			}
		}
		if (target instanceof MergeState) {
			if (!(source instanceof PseudoState) && !transition.getEffects().isEmpty()) {
				error("Transitions targeted to merge nodes must not have actions.", StatechartModelPackage.Literals.TRANSITION__EFFECTS);
			}
		}
		if (source instanceof JoinState) {
			if (transition.getTrigger() != null) {
				error("Transitions from join nodes must not have triggers.", StatechartModelPackage.Literals.TRANSITION__TRIGGER);
			}
			if (transition.getGuard() != null) {
				error("Transitions from join nodes must not have guards.", StatechartModelPackage.Literals.TRANSITION__GUARD);
			}
		}
		if (target instanceof JoinState) {
			if (!transition.getEffects().isEmpty()) {
				error("Transitions targeted to join nodes must not have actions.", StatechartModelPackage.Literals.TRANSITION__EFFECTS);
			}
		}
	}
	
	@Check
	public void checkTimeoutTransitions(hu.bme.mit.gamma.statechart.model.State state) {
		boolean multipleTimedTransitions = StatechartModelDerivedFeatures.getOutgoingTransitions(state).stream()
				.filter(it -> it.getTrigger() instanceof EventTrigger && 
				((EventTrigger) it.getTrigger()).getEventReference() instanceof ClockTickReference &&
				it.getGuard() == null).count() > 1;
		if (multipleTimedTransitions) {
			error("This state has multiple transitions with occluding timing specifications.", StatechartModelPackage.Literals.TRANSITION__GUARD);
		}
	}
	
	@Check
	public void checkOutgoingTransitionDeterminism(Transition transition) {
		StateNode sourceState = transition.getSourceState();
		Collection<Transition> siblingTransitions = StatechartModelDerivedFeatures.getOutgoingTransitions(sourceState).stream()
				.filter(it -> it != transition).collect(Collectors.toSet());
		Transition nonDeterministicTransition = checkTransitionDeterminism(transition, siblingTransitions);
		if (nonDeterministicTransition != null) {
			error("This transitions is in a non-deterministic relation with other transitions from the same source.",
					StatechartModelPackage.Literals.TRANSITION__TRIGGER);
		}
	}
	
	private Transition checkTransitionDeterminism(Transition transition, Collection<Transition> transitions) {
		if (transition.getGuard() != null || !(transition.getTrigger() instanceof EventTrigger) ||
			(!(((EventTrigger) transition.getTrigger()).getEventReference() instanceof PortEventReference) &&
			!(((EventTrigger) transition.getTrigger()).getEventReference() instanceof AnyPortEventReference))) {
			return null;
		}
		EventTrigger trigger = (EventTrigger) transition.getTrigger();
		EventReference eventReference = trigger.getEventReference();
		if (eventReference instanceof PortEventReference) {
			PortEventReference portEventReference = (PortEventReference) eventReference;
			for (Transition siblingTransition : transitions) {
				if (isTransitionTriggeredByPortEvent(siblingTransition, portEventReference.getPort(), portEventReference.getEvent())) {
					return siblingTransition;
				}
			}
		}
		else if (eventReference instanceof AnyPortEventReference) {
			AnyPortEventReference portEventReference = (AnyPortEventReference) eventReference;
			for (Transition siblingTransition : transitions) {
				if (isTransitionTriggeredByPortEvent(siblingTransition, portEventReference.getPort())) {
					return siblingTransition;
				}
			}
		}
		return null;
	}
	
	private boolean isTransitionTriggeredByPortEvent(Transition transition, Port port, Event event) {
		if (transition.getTrigger() instanceof EventTrigger) {
			EventTrigger eventTrigger = (EventTrigger) transition.getTrigger();
			if (eventTrigger.getEventReference() instanceof PortEventReference) {
				PortEventReference candidateEventReference = (PortEventReference) eventTrigger.getEventReference();
				if (candidateEventReference.getPort() == port && candidateEventReference.getEvent() == event) {
					return true;
				}
			}
			else if (eventTrigger.getEventReference() instanceof AnyPortEventReference) {
				AnyPortEventReference candidateEventReference = (AnyPortEventReference) eventTrigger.getEventReference();
				if (candidateEventReference.getPort() == port) {
					return true;
				}
			}
		}
		return false;
	}
	
	private boolean isTransitionTriggeredByPortEvent(Transition transition, Port port) {
		if (transition.getTrigger() instanceof EventTrigger) {
			EventTrigger eventTrigger = (EventTrigger) transition.getTrigger();
			if (eventTrigger.getEventReference() instanceof PortEventReference) {
				PortEventReference candidateEventReference = (PortEventReference) eventTrigger.getEventReference();
				if (candidateEventReference.getPort() == port) {
					return true;
				}
			}
			else if (eventTrigger.getEventReference() instanceof AnyPortEventReference) {
				AnyPortEventReference candidateEventReference = (AnyPortEventReference) eventTrigger.getEventReference();
				if (candidateEventReference.getPort() == port) {
					return true;
				}
			}
		}
		return false;
	}
	
	@Check
	public void checkTransitionOcclusion(Transition transition) {
		StateNode sourceState = transition.getSourceState();
		Collection<Transition> parentTransitions = getOutgoingTransitionsOfAncestors(sourceState);
		Transition nonDeterministicTransition = checkTransitionDeterminism(transition, parentTransitions);
		if (nonDeterministicTransition != null) {
			error("This transitions is occluded by a higher level transition.",
					StatechartModelPackage.Literals.TRANSITION__TRIGGER);
		}
	}
	
	private Collection<Transition> getOutgoingTransitionsOfAncestors(StateNode source) {
		if (source.eContainer().eContainer() instanceof hu.bme.mit.gamma.statechart.model.State) {
			hu.bme.mit.gamma.statechart.model.State parentState = (hu.bme.mit.gamma.statechart.model.State) source.eContainer().eContainer();
			Collection<Transition> transitions = StatechartModelDerivedFeatures.getOutgoingTransitions(parentState) ;
			transitions.addAll(getOutgoingTransitionsOfAncestors(parentState));
			return transitions;
		}
		return new HashSet<Transition>();
	}
	
	@Check
	public void checkParallelTransitionAssignments(Transition transition) {
		Transition sameTriggerParallelTransition = getSameTriggedTransitionOfParallelRegions(transition);
		Declaration declaration = getSameVariableOfAssignments(transition, sameTriggerParallelTransition);
		if (declaration != null) {
			warning("Both this and transition between " + sameTriggerParallelTransition.getSourceState().getName() + 
				" and " + sameTriggerParallelTransition.getTargetState().getName() + " assigns value to variable " + declaration.getName(),
				StatechartModelPackage.Literals.TRANSITION__EFFECTS);
		}
	}

	@Check
	public void checkParallelEventRaisings(Transition transition) {
		Transition sameTriggerParallelTransition = getSameTriggedTransitionOfParallelRegions(transition);
		Entry<Port, Event> portEvent = getSameEventOfParameteredRaisings(transition, sameTriggerParallelTransition);
		if (portEvent != null) {
			warning("Both this and transition between " + sameTriggerParallelTransition.getSourceState().getName() + 
				" and " + sameTriggerParallelTransition.getTargetState().getName() + " raises the same event "
					+ portEvent.getValue().getName() + " with potentional parameters.",
				StatechartModelPackage.Literals.TRANSITION__EFFECTS);
		}
	}
	
	private Transition getSameTriggedTransitionOfParallelRegions(Transition transition) {
		StateNode sourceState = transition.getSourceState();
		Region parentRegion = (Region) sourceState.eContainer();
		if (parentRegion.eContainer() instanceof hu.bme.mit.gamma.statechart.model.State) {
			hu.bme.mit.gamma.statechart.model.State parentState = (hu.bme.mit.gamma.statechart.model.State) parentRegion.eContainer();
			Collection<Region> siblingRegions = new HashSet<Region>(parentState.getRegions());
			siblingRegions.remove(parentRegion);
			Collection<Transition> parallelTransitions = getTransitionsOfSiblingRegions(siblingRegions);
			return checkTransitionDeterminism(transition, parallelTransitions);
		}
		return null;
	}
	
	private Collection<Transition> getTransitionsOfSiblingRegions(Collection<Region> siblingRegions) {
		Collection<Transition> siblingTransitions = new HashSet<Transition>();
		siblingRegions.stream().map(it -> it.getStateNodes()).forEach(it -> it.stream()
				.map(node -> StatechartModelDerivedFeatures.getOutgoingTransitions(node))
				.forEach(sibling -> siblingTransitions.addAll(sibling)));
		return siblingTransitions;
	}
	
	private Declaration getSameVariableOfAssignments(Transition lhs, Transition rhs) {
		for (Action action : lhs.getEffects()) {
			if (action instanceof AssignmentAction) {
				AssignmentAction assignment = (AssignmentAction) action;
				if (assignment.getLhs() instanceof ReferenceExpression) {
					ReferenceExpression reference = (ReferenceExpression) assignment.getLhs();
					Declaration declaration = reference.getDeclaration();
					for (Action rhsAction: rhs.getEffects()) {
						if (rhsAction instanceof AssignmentAction) {
							AssignmentAction rhsAssignment = (AssignmentAction) rhsAction;
							if (rhsAssignment.getLhs() instanceof ReferenceExpression) {
								ReferenceExpression rhsReference = (ReferenceExpression) rhsAssignment.getLhs();
								if (rhsReference.getDeclaration() == declaration) {
									return declaration;
								}
							}
						}
					}
				}
			}
		}
		return null;
	}
	
	private Entry<Port, Event> getSameEventOfParameteredRaisings(Transition lhs, Transition rhs) {
		for (Action action : lhs.getEffects()) {
			if (action instanceof RaiseEventAction) {
				RaiseEventAction lhsRaiseEvent = (RaiseEventAction) action;
				for (Action raiseEvent : rhs.getEffects().stream().filter(it -> it instanceof RaiseEventAction)
						.collect(Collectors.toSet())) {
					RaiseEventAction rhsRaiseEvent = (RaiseEventAction) raiseEvent;
					if (lhsRaiseEvent.getPort() == rhsRaiseEvent.getPort() && 
						lhsRaiseEvent.getEvent() == rhsRaiseEvent.getEvent()) {
						if (!lhsRaiseEvent.getParameters().isEmpty() && !rhsRaiseEvent.getParameters().isEmpty()) {
							return new HashMap.SimpleEntry<Port, Event>(lhsRaiseEvent.getPort(), lhsRaiseEvent.getEvent());
						}
					}
				}
			}
		}
		return null;
	}
	
	@Check
	private void checkTransitionOrientation(Transition transition) {
		if (transition.getSourceState().eContainer() == transition.getTargetState().eContainer()) {
			// Transitions in same region are permitted
			return;
		}
		Collection<hu.bme.mit.gamma.statechart.model.State> commonAncestors = getCommonAncestors(transition.getSourceState(),
			 transition.getTargetState());
		if (!commonAncestors.isEmpty()) {
			error("The orientation of this transition is incorrect as the source and target have common ancestor states: " +
				commonAncestors.stream().map(it -> it.getName()).collect(Collectors.toSet()) + ".",
				StatechartModelPackage.Literals.TRANSITION__SOURCE_STATE);
		}
	}
	
	private Collection<hu.bme.mit.gamma.statechart.model.State> getCommonAncestors(StateNode lhs, StateNode rhs) {
		Collection<hu.bme.mit.gamma.statechart.model.State> ancestors = getAncestors(lhs);
		ancestors.retainAll(getAncestors(rhs));
		return ancestors;
	}
	
	private Collection<hu.bme.mit.gamma.statechart.model.State> getAncestors(StateNode node) {
		if (node.eContainer().eContainer() instanceof hu.bme.mit.gamma.statechart.model.State) {
			hu.bme.mit.gamma.statechart.model.State parentState = (hu.bme.mit.gamma.statechart.model.State) node.eContainer().eContainer();
			Collection<hu.bme.mit.gamma.statechart.model.State> ancestors = getAncestors(parentState);
			ancestors.add(parentState);
			return ancestors;
		}
		return new HashSet<hu.bme.mit.gamma.statechart.model.State>();
	}
	
	// Composite system
	
	@Check
	public void checkCircularDependencies(Package statechart) {
		for (Package referredStatechart : statechart.getImports()) {
			Package parentStatechart = getReferredPackages(statechart, referredStatechart);
			if (parentStatechart != null) {
				error("This statechart is in a dependency circle, referred by " + parentStatechart.getName() + "!" 
						+ "Composite systems must have an acyclical dependency hierarchy!", ConstraintModelPackage.Literals.NAMED_ELEMENT__NAME);
			}
		}
	}
	
	private Package getReferredPackages(Package initialStatechart, Package statechart) {
		for (Package referredStatechart : statechart.getImports()) {
			if (referredStatechart == initialStatechart) {
				return statechart;
			}
		}
		for (Package referredStatechart : statechart.getImports()) {
			Package parentStatechart = getReferredPackages(initialStatechart, referredStatechart);
			if (parentStatechart != null) {
				return parentStatechart;
			}
		}
		return null;
	}
	
	@Check
	public void checkMultipleImports(Package gammaPackage) {
		Set<Package> importedPackages = new HashSet<Package>();
		importedPackages.add(gammaPackage);
		for (Package importedPackage : gammaPackage.getImports()) {
			if (importedPackages.contains(importedPackage)) {
				int index = gammaPackage.getImports().indexOf(importedPackage);
				warning("Package " + importedPackage.getName() + " is already imported!", StatechartModelPackage.Literals.PACKAGE__IMPORTS, index);
			}
			importedPackages.add(importedPackage);
		}
	}
	
	@Check
	public void checkParameters(ComponentInstance instance) {
		Component type = StatechartModelDerivedFeatures.getDerivedType(instance);
		if (instance.getParameters().size() != type.getParameterDeclarations().size()) {
			error("The number of arguments is wrong.", ConstraintModelPackage.Literals.PARAMETERIZED_ELEMENT__PARAMETERS);
		}
	}
	
	@Check
	public void checkComponentInstanceArguments(ComponentInstance instance) {
		try {
			Component type = StatechartModelDerivedFeatures.getDerivedType(instance);
			EList<ParameterDeclaration> parameters = type.getParameterDeclarations();
			for (int i = 0; i < parameters.size(); ++i) {
				ParameterDeclaration parameter = parameters.get(i);
				Expression argument = instance.getParameters().get(i);
				Type declarationType = parameter.getType();
				ExpressionType argumentType = typeDeterminator.getType(argument);
				if (!typeDeterminator.equals(declarationType, argumentType)) {
					error("The types of the declaration and the right hand side expression are not the same: " +
							typeDeterminator.transform(declarationType).toString().toLowerCase() + " and " +
							argumentType.toString().toLowerCase() + ".",
							ConstraintModelPackage.Literals.PARAMETERIZED_ELEMENT__PARAMETERS, i);
				} 
			}
		} catch (Exception exception) {
			// There is a type error on a lower level, no need to display the error message on this level too
		}
	}
	
	@Check
	public void checkPortBinding(Port port) {
		Component container = (Component) port.eContainer();
		if (container instanceof CompositeComponent) {
			CompositeComponent componentDefinition = (CompositeComponent) container;
			for (PortBinding portDefinition : componentDefinition.getPortBindings()) {
				if (portDefinition.getCompositeSystemPort() == port) {
					return;
				}
			}
			warning("This system port is not connected to any ports of an instance!", ConstraintModelPackage.Literals.NAMED_ELEMENT__NAME);
		}
	}
	
	@Check
	public void checkUnusedInstancePort(ComponentInstance instance) {
		EObject root = EcoreUtil2.getRootContainer(instance);
		Collection<Port> usedPorts = EcoreUtil2.getAllContentsOfType(root, InstancePortReference.class).stream()
				.filter(it -> it.getInstance() == instance).map(it -> it.getPort()).collect(Collectors.toSet());
		Collection<Port> unusedPorts = new HashSet<Port>(StatechartModelDerivedFeatures.getDerivedType(instance).getPorts());
		unusedPorts.removeAll(usedPorts);
		if (!unusedPorts.isEmpty()) {
			warning("The following ports are not used either in system port binding or a channel: " +
				unusedPorts.stream().map(it -> it.getName()).collect(Collectors.toSet()), ConstraintModelPackage.Literals.NAMED_ELEMENT__NAME);
		}
	}
	
	@Check
	public void checkPortBindingUniqueness(PortBinding portBinding) {
		Port systemPort = portBinding.getCompositeSystemPort();
		Port instancePort = portBinding.getInstancePortReference().getPort();
		ComponentInstance instance = portBinding.getInstancePortReference().getInstance();
		CompositeComponent composite = (CompositeComponent) portBinding.eContainer();
		if (composite.getPortBindings().stream().filter(it -> it.getCompositeSystemPort() == systemPort).count() > 1) {
			error("This system port is connected to multiple ports of instances!",
					CompositePackage.Literals.PORT_BINDING__COMPOSITE_SYSTEM_PORT);
		}
		if (composite.getPortBindings().stream().filter(it -> it.getInstancePortReference().getPort() == instancePort &&
				it.getInstancePortReference().getInstance() == instance).count() > 1) {
			error("Multiple system ports are connected to the port of this instance!",
					CompositePackage.Literals.PORT_BINDING__INSTANCE_PORT_REFERENCE);
		}
	}
	
	@Check
	public void checkPortBinding(PortBinding portDefinition) {
		RealizationMode systemPortIT = portDefinition.getCompositeSystemPort().getInterfaceRealization().getRealizationMode();
		RealizationMode instancePortIT = portDefinition.getInstancePortReference().getPort().getInterfaceRealization().getRealizationMode();
		Interface systemPortIf = portDefinition.getCompositeSystemPort().getInterfaceRealization().getInterface();
		Interface instancePortIf = portDefinition.getInstancePortReference().getPort().getInterfaceRealization().getInterface(); 
		if (systemPortIT != instancePortIT) {
			error("Ports can be connected only if their interface types match. This is not realized in this case: " + systemPortIT.getName() 
				+ " -> " + instancePortIT.getName(), CompositePackage.Literals.PORT_BINDING__INSTANCE_PORT_REFERENCE);
		}	
		if (systemPortIf != instancePortIf) {
			error("Ports can be connected only if their interfaces match. This is not realized in this case: " + systemPortIf.getName()
				+ " -> " + instancePortIf.getName(), CompositePackage.Literals.PORT_BINDING__INSTANCE_PORT_REFERENCE);
		}	
	}
	
	@Check
	public void checkInstancePortReference(InstancePortReference reference) {
		ComponentInstance instance = reference.getInstance();
		Port port = reference.getPort();
		Component type = StatechartModelDerivedFeatures.getDerivedType(instance);
		Collection<Port> ports = StatechartModelDerivedFeatures.getAllPorts(type);
		if (!ports.contains(port)) {
			error("The specified port is not on instance " + instance.getName() + ".",
					CompositePackage.Literals.INSTANCE_PORT_REFERENCE__PORT);
		}
	}
	
	@Check
	public void checkPortBindingWithSimpleChannel(SimpleChannel channel) {
		EObject root = EcoreUtil2.getRootContainer(channel);
		Collection<PortBinding> portDefinitions = EcoreUtil2.getAllContentsOfType(root, PortBinding.class);
		for (PortBinding portDefinition : portDefinitions) {
			// Broadcast ports can be used in multiple places
			if (!isBroadcast(channel.getProvidedPort().getPort()) && equals(channel.getProvidedPort(), portDefinition.getInstancePortReference())) {
				error("A port of an instance can be included either in a channel or a port binding!",
						CompositePackage.Literals.CHANNEL__PROVIDED_PORT);
			}
			if (equals(channel.getRequiredPort(), portDefinition.getInstancePortReference())) {
				error("A port of an instance can be included either in a channel or a port binding!",
						CompositePackage.Literals.SIMPLE_CHANNEL__REQUIRED_PORT);
			}
		}			
	}
	
	private boolean isBroadcast(Port port) {
		return StatechartModelDerivedFeatures.isBroadcast(port);
	}
	
	@Check
	public void checkPortBindingWithBroadcastChannel(BroadcastChannel channel) {
		EObject root = EcoreUtil2.getRootContainer(channel);
		Collection<PortBinding> portDefinitions = EcoreUtil2.getAllContentsOfType(root, PortBinding.class);
		for (PortBinding portDefinition : portDefinitions) {
			for (InstancePortReference output : channel.getRequiredPorts()) {
				if (equals(output, portDefinition.getInstancePortReference())) {
					error("A port of an instance can be included either in a channel or a port binding!",
							CompositePackage.Literals.BROADCAST_CHANNEL__REQUIRED_PORTS);
				}
			}
		}			
	}
	
	@Check
	public void checkChannelProvidedPorts(Channel channel) {
		Component parentComponent = (Component) channel.eContainer();
		// Ports inside asynchronous components can be connected to multiple ports
		if (parentComponent instanceof AsynchronousCompositeComponent) {
			return;
		}
		// Checking provided instance ports in different channels
		EObject root = EcoreUtil2.getRootContainer(channel);
		Collection<InstancePortReference> instancePortReferences = EcoreUtil2.getAllContentsOfType(root, InstancePortReference.class);
		for (InstancePortReference instancePortReference : instancePortReferences.stream()
						.filter(it -> it != channel.getProvidedPort() && it.eContainer() instanceof Channel).collect(Collectors.toList())) {
			// Broadcast ports are also restricted to be used only in a single channel (restriction on syntax only)
			if (equals(instancePortReference, channel.getProvidedPort())) {
				error("A port of an instance can be included only in a single channel!", CompositePackage.Literals.CHANNEL__PROVIDED_PORT);
			}
		}
	}
	
	@Check
	public void checkChannelRequiredPorts(SimpleChannel channel) {
		Component parentComponent = (Component) channel.eContainer();
		// Ports inside asynchronous components can be connected to multiple ports
		if (parentComponent instanceof AsynchronousCompositeComponent) {
			return;
		}
		EObject root = EcoreUtil2.getRootContainer(channel);
		Collection<InstancePortReference> instancePortReferences = EcoreUtil2.getAllContentsOfType(root, InstancePortReference.class);
		// Checking required instance ports in different simple channels
		for (InstancePortReference instancePortReference : instancePortReferences.stream()
				.filter(it -> it != channel.getRequiredPort() && it.eContainer() instanceof Channel).collect(Collectors.toList())) {
			if (equals(instancePortReference, channel.getRequiredPort())) {
				error("A port of an instance can be included only in a single channel!", CompositePackage.Literals.SIMPLE_CHANNEL__REQUIRED_PORT);
			}
		}
	}
	
	@Check
	public void checkChannelRequiredPorts(BroadcastChannel channel) {
		Component parentComponent = (Component) channel.eContainer();
		// Ports inside asynchronous components can be connected to multiple ports
		if (parentComponent instanceof AsynchronousCompositeComponent) {
			return;
		}
		EObject root = EcoreUtil2.getRootContainer(channel);
		Collection<InstancePortReference> instancePortReferences = EcoreUtil2.getAllContentsOfType(root, InstancePortReference.class);
		// Checking required instance ports in different broadcast channels
		for (InstancePortReference instancePortReference : instancePortReferences.stream()
				.filter(it -> it.eContainer() != channel && it.eContainer() instanceof Channel).collect(Collectors.toList())) {
			for (InstancePortReference requiredPort : channel.getRequiredPorts()) {
				if (equals(instancePortReference, requiredPort)) {
					int index = channel.getRequiredPorts().indexOf(requiredPort);
					error("A port of an instance can be included only in a single channel!", CompositePackage.Literals.BROADCAST_CHANNEL__REQUIRED_PORTS, index);
				}
			}
		}
		// Checking required instance ports in the same broadcast channel
		for (InstancePortReference requiredPort : channel.getRequiredPorts()) {
			for (InstancePortReference requiredPort2 : channel.getRequiredPorts().stream()
					.filter(it -> it != requiredPort && it.eContainer() instanceof Channel).collect(Collectors.toList())) {
				if (equals(requiredPort2, requiredPort)) {
					int index = channel.getRequiredPorts().indexOf(requiredPort2);
					error("A port of an instance can be included only in a single channel!", CompositePackage.Literals.BROADCAST_CHANNEL__REQUIRED_PORTS, index);
				}
			}
		}
	}
	
	private boolean equals(InstancePortReference p1, InstancePortReference p2) {
		return p1.getInstance() == p2.getInstance() && p1.getPort() == p2.getPort();
	}
	
	@Check
	public void checkChannelInput(Channel channel) {
		if (!(channel.getProvidedPort().getPort().getInterfaceRealization().getRealizationMode() == RealizationMode.PROVIDED)) {
			error("A port providing an interface is needed here!", CompositePackage.Literals.CHANNEL__PROVIDED_PORT);
		}		
	}
	
	@Check
	public void checkSimpleChannelOutput(SimpleChannel channel) {
		if (channel.getRequiredPort().getPort().getInterfaceRealization().getRealizationMode()  != RealizationMode.REQUIRED) {
			error("A port requiring an interface is needed here!", CompositePackage.Literals.SIMPLE_CHANNEL__REQUIRED_PORT);
		}
		// Checking the interfaces
		Interface providedInterface = channel.getProvidedPort().getPort().getInterfaceRealization().getInterface();
		Interface requiredInterface = channel.getRequiredPort().getPort().getInterfaceRealization().getInterface();
		if (providedInterface != requiredInterface) {
			error("Ports connected with a channel must have the same interface! This is not realized in this case. The provided interface: " + providedInterface.getName() +
					". The required interface: " + requiredInterface.getName() + ".", CompositePackage.Literals.SIMPLE_CHANNEL__REQUIRED_PORT);
		}
	}
	
	@Check
	public void checkBroadcastChannelOutput(BroadcastChannel channel) {
		if (!isBroadcast(channel.getProvidedPort().getPort()) && !(channel.eContainer() instanceof AsynchronousComponent)) {
			// Asynchronous components can have two-way broadcast channels 
			error("A port providing a broadcast interface is needed here!", CompositePackage.Literals.CHANNEL__PROVIDED_PORT);
		}
		for (InstancePortReference output : channel.getRequiredPorts()) {
			if (output.getPort().getInterfaceRealization().getRealizationMode() != RealizationMode.REQUIRED) {
				int index = channel.getRequiredPorts().indexOf(output);
				error("A port requiring an interface is needed here!", CompositePackage.Literals.BROADCAST_CHANNEL__REQUIRED_PORTS, index);
			}
			Interface requiredInterface = output.getPort().getInterfaceRealization().getInterface();
			Interface providedInterface = channel.getProvidedPort().getPort().getInterfaceRealization().getInterface();
			if (providedInterface != requiredInterface) {
				error("Ports connected with a broadcast channel must have the same interface! This is not realized in this case. The provided interface: "
						+ providedInterface.getName() + ". The required interface: " + requiredInterface.getName() + ".", CompositePackage.Literals.BROADCAST_CHANNEL__REQUIRED_PORTS);
			}
		}		
	}
	
	@Check
	public void checkCascadeLoopChannels(SimpleChannel channel) {
		ComponentInstance instance = channel.getProvidedPort().getInstance();
		if (StatechartModelDerivedFeatures.getDerivedType(instance) instanceof CascadeCompositeComponent &&
				instance == channel.getRequiredPort().getInstance()) {			
			warning("Verification cannot be executed if ports of a cascade component are connected to each other.", CompositePackage.Literals.CHANNEL__PROVIDED_PORT);
		}
	}
	
	@Check
	public void checkCascadeLoopChannels(BroadcastChannel channel) {
		ComponentInstance instance = channel.getProvidedPort().getInstance();
		if (StatechartModelDerivedFeatures.getDerivedType(instance)  instanceof CascadeCompositeComponent &&
				channel.getRequiredPorts().stream().anyMatch(it -> it.getInstance() == instance)) {			
			warning("Verification cannot be executed if ports of a cascade component are connected to each other.", CompositePackage.Literals.CHANNEL__PROVIDED_PORT);
		}
	}
	
	// Wrapper
	
	@Check
	public void checkSynchronousComponentWrapper(SynchronousComponentWrapper wrapper) {
		if (wrapper.getWrappedComponent() instanceof StatechartDefinition) {
			error("The direct wrapping of statechart components is not (yet) supported.", CompositePackage.Literals.SYNCHRONOUS_COMPONENT_WRAPPER__WRAPPED_COMPONENT);
		}
	}
	
	@Check
	public void checkWrapperClock(Clock clock) {
		if (!isContainedInQueue(clock, (SynchronousComponentWrapper) clock.eContainer())) {
			warning("Ticks of this clock are not forwarded to any messages queues.", ConstraintModelPackage.Literals.NAMED_ELEMENT__NAME);
		}
	}
	
	@Check
	public void checkSynchronousComponentWrapperMultipleEventContainment(SynchronousComponentWrapper wrapper) {
		Map<Port, Collection<Event>> containedEvents = new HashMap<Port, Collection<Event>>();
		for (MessageQueue queue : wrapper.getMessageQueues()) {
			for (EventReference eventReference : queue.getEventReference()) {
				int index = queue.getEventReference().indexOf(eventReference);
				if (eventReference instanceof PortEventReference) {
					PortEventReference portEventReference = (PortEventReference) eventReference;
					Port containedPort = portEventReference.getPort();
					Event containedEvent = portEventReference.getEvent();
					if (containedEvents.containsKey(containedPort)) {
						Collection<Event> alreadyContainedEvents = containedEvents.get(containedPort);
						if (alreadyContainedEvents.contains(containedEvent)) {
							error("Event " + containedEvent.getName() + " is already forwarded to a message queue.",
									queue, CompositePackage.Literals.MESSAGE_QUEUE__EVENT_REFERENCE, index);
						}
						else {
							alreadyContainedEvents.add(containedEvent);
						}
					}
					else {
						Collection<Event> events = new HashSet<Event>();
						events.add(containedEvent);
						containedEvents.put(containedPort, events);
					}
				}
				if (eventReference instanceof AnyPortEventReference) {
					AnyPortEventReference anyPortEventReference = (AnyPortEventReference) eventReference;
					Port containedPort = anyPortEventReference.getPort();
					Collection<Event> events = new HashSet<Event>(getSemanticEvents(Collections.singleton(containedPort), EventDirection.IN));
					if (containedEvents.containsKey(containedPort)) {
						Collection<Event> alreadyContainedEvents = containedEvents.get(containedPort);
						alreadyContainedEvents.addAll(events);
						Collection<String> alreadyContainedEventNames = alreadyContainedEvents.stream().map(it -> it.getName()).collect(Collectors.toSet());
						error("Events " + alreadyContainedEventNames + " are already forwarded to a message queue.",
								queue, CompositePackage.Literals.MESSAGE_QUEUE__EVENT_REFERENCE, index);
					}
					else {
						containedEvents.put(containedPort, events);
					}
				}
			}
		}
	}
	
	
	@Check
	public void checkWrappedPort(SynchronousComponentWrapper wrapper) {
		for (Port port : wrapper.getWrappedComponent().getPorts()) {
			for (Event event : getSemanticEvents(Collections.singleton(port), EventDirection.IN)) {
				if (!isContainedInQueue(port, event, wrapper)) {
					warning("Event " + event.getName() + " of port " + port.getName() + 
							" is not forwarded to a message queue.", ConstraintModelPackage.Literals.NAMED_ELEMENT__NAME);
				}
			}
		}
	}
	
	@Check
	public void checkControlSpecification(ControlSpecification controlSpecification) {
		SimpleTrigger trigger = controlSpecification.getTrigger();
		if (trigger instanceof EventTrigger) {
			EventTrigger eventTrigger = (EventTrigger) trigger;
			EventReference eventReference = eventTrigger.getEventReference();
			// Checking out-events
			if (eventReference instanceof PortEventReference) {
				PortEventReference portEventReference = (PortEventReference) eventReference;
				Port containedPort = portEventReference.getPort();
				Event containedEvent = portEventReference.getEvent();
				if (getSemanticEvents(Collections.singleton(containedPort), EventDirection.OUT).stream()
						.filter(it -> ((EventDeclaration) it.eContainer()).getDirection() != EventDirection.INOUT)
						.anyMatch(it -> it == containedEvent)) {
					error("Event " + containedEvent.getName() + " is an out event and can not be used in a control specification.", CompositePackage.Literals.CONTROL_SPECIFICATION__TRIGGER);
				}
			}	 
		}
	}
	
	@Check
	public void checkMessageQueuePriorities(SynchronousComponentWrapper wrapper) {
		Set<Integer> priorityValues = new HashSet<Integer>();
		for (int i = 0; i < wrapper.getMessageQueues().size(); ++i) {
			MessageQueue queue = wrapper.getMessageQueues().get(i);
			int priorityValue = queue.getPriority().intValue();
			if (priorityValues.contains(priorityValue)) {
				warning("Another queue with the same priority is already defined.", queue,
						CompositePackage.Literals.MESSAGE_QUEUE__PRIORITY);
			}
			else {
				priorityValues.add(priorityValue);
			}
		}
	}
	
	@Check
	public void checkMessageQueue(MessageQueue queue) {
		List<EventReference> eventReferences = queue.getEventReference();
		for (EventReference eventReference : eventReferences) {
			int index = queue.getEventReference().indexOf(eventReference);
			// Checking out-events
			if (eventReference instanceof PortEventReference) {
				PortEventReference portEventReference = (PortEventReference) eventReference;
				Port containedPort = portEventReference.getPort();
				Event containedEvent = portEventReference.getEvent();
				if (getSemanticEvents(Collections.singleton(containedPort), EventDirection.OUT).stream()
						.filter(it -> ((EventDeclaration) it.eContainer()).getDirection() != EventDirection.INOUT)
						.anyMatch(it -> it == containedEvent)) {
					error("Event " + containedEvent.getName() + " is an out event and can not be forwarded to a message queue.", CompositePackage.Literals.MESSAGE_QUEUE__EVENT_REFERENCE, index);
				}
			}			
		}
	}
	
	private Collection<Event> getSemanticEvents(Collection<? extends Port> ports, EventDirection direction) {
		Collection<Event> events = new HashSet<Event>();
		for (Interface anInterface : ports.stream()
				.filter(it -> it.getInterfaceRealization().getRealizationMode() == RealizationMode.PROVIDED)
				.map(it -> it.getInterfaceRealization().getInterface()).collect(Collectors.toSet())) {
			events.addAll(getAllEvents(anInterface, getOppositeDirection(direction)));
		}
		for (Interface anInterface : ports.stream()
				.filter(it -> it.getInterfaceRealization().getRealizationMode() == RealizationMode.REQUIRED)
				.map(it -> it.getInterfaceRealization().getInterface()).collect(Collectors.toSet())) {
			events.addAll(getAllEvents(anInterface, direction));
		}
		return events;
	}

	private EventDirection getOppositeDirection(EventDirection direction) {
		switch (direction) {
			case IN:
				return EventDirection.OUT;
			case OUT:
				return EventDirection.IN;
			default:
				throw new IllegalArgumentException("Not known direction: " + direction);
		}
	}

	/**
	 * The parent interfaces are taken into considerations as well.
	 */
	private Collection<Event> getAllEvents(Interface anInterface, EventDirection oppositeDirection) {
		if (anInterface == null) {
			return Collections.emptySet();
		}
		Collection<Event> eventSet = new HashSet<Event>();
		for (Interface parentInterface : anInterface.getParents()) {
			eventSet.addAll(getAllEvents(parentInterface, oppositeDirection));
		}
		for (Event event : anInterface.getEvents().stream().filter(it -> it.getDirection() != oppositeDirection)
				.map(it -> it.getEvent()).collect(Collectors.toSet())) {
			eventSet.add(event);
		}
		return eventSet;
	}
	
	private boolean isContainedInQueue(Port port, Event event, SynchronousComponentWrapper wrapper) {
		for (MessageQueue queue : wrapper.getMessageQueues()) {
			for (EventReference eventReference : queue.getEventReference()) {
				if (StatechartModelDerivedFeatures.getEventSource(eventReference)  == port) {
					if (eventReference instanceof AnyPortEventReference) {
						return true;
					}
					if (eventReference instanceof PortEventReference) {
						PortEventReference portEventReference = (PortEventReference) eventReference;
						if (portEventReference.getEvent() == event) {
							return true;
						}
					}
				}
			}
		}
		return false;
	}
	
	private boolean isContainedInQueue(Clock clock, SynchronousComponentWrapper wrapper) {
		for (MessageQueue queue : wrapper.getMessageQueues()) {
			for (EventReference eventReference : queue.getEventReference()) {
				if (eventReference instanceof ClockTickReference) {
					if (((ClockTickReference) eventReference).getClock() == clock) {
						return true;
					}
				}
			}
		}
		return false;
	}
	
	@Check
	public void checkAnyPortControls(ControlSpecification controlSpecification) {
		if (controlSpecification.getTrigger() instanceof AnyTrigger) {
			if (controlSpecification.eContainer() instanceof SynchronousComponentWrapper) {
				SynchronousComponentWrapper wrapper = (SynchronousComponentWrapper) controlSpecification.eContainer();
				int controlIndex = wrapper.getControlSpecifications().indexOf(controlSpecification);
				if (controlIndex < wrapper.getControlSpecifications().size() - 1) {
					warning("This control specification with any trigger enshadows the following control specifications.", CompositePackage.Literals.CONTROL_SPECIFICATION__TRIGGER);
				}
			}
		}
	}
	
	@Check
	public void checkMessageQueueAnyEventReferences(AnyPortEventReference anyPortEventReference) {
		if (anyPortEventReference.eContainer() instanceof MessageQueue && isBroadcast(anyPortEventReference.getPort())) {
			error("There are no events coming in through this port.", StatechartModelPackage.Literals.ANY_PORT_EVENT_REFERENCE__PORT);
		}
	}
	
	@Check
	public void checkExecutionLists(CascadeCompositeComponent cascade) {
		if (cascade.getExecutionList().isEmpty()) {
			// Nothing to validate
			return;
		}
		Collection<SynchronousComponentInstance> containedInstances = new HashSet<SynchronousComponentInstance>(cascade.getComponents());
		containedInstances.removeAll(cascade.getExecutionList());
		if (!containedInstances.isEmpty()) {
			error("The following instances are never executed: " + containedInstances.stream().map(it -> it.getName())
					.collect(Collectors.toSet()) + ".",	CompositePackage.Literals.CASCADE_COMPOSITE_COMPONENT__EXECUTION_LIST);
		}
	}
		
}
