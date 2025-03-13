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
package hu.bme.mit.gamma.statechart.util;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map.Entry;
import java.util.Queue;
import java.util.Set;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.action.model.AssignmentStatement;
import hu.bme.mit.gamma.action.util.ActionUtil;
import hu.bme.mit.gamma.expression.model.AccessExpression;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.MultiaryExpression;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeDeclaration;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.statechart.composite.AbstractAsynchronousCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.AbstractSynchronousCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter;
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponent;
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.composite.BroadcastChannel;
import hu.bme.mit.gamma.statechart.composite.CascadeCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.Channel;
import hu.bme.mit.gamma.statechart.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceEventParameterReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceEventReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.CompositeComponent;
import hu.bme.mit.gamma.statechart.composite.CompositeModelFactory;
import hu.bme.mit.gamma.statechart.composite.ControlFunction;
import hu.bme.mit.gamma.statechart.composite.ControlSpecification;
import hu.bme.mit.gamma.statechart.composite.DiscardStrategy;
import hu.bme.mit.gamma.statechart.composite.EventPassing;
import hu.bme.mit.gamma.statechart.composite.InstancePortReference;
import hu.bme.mit.gamma.statechart.composite.MessageQueue;
import hu.bme.mit.gamma.statechart.composite.PortBinding;
import hu.bme.mit.gamma.statechart.composite.SchedulableCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.ScheduledAsynchronousCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.SimpleChannel;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponent;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.AnyTrigger;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.ComponentAnnotation;
import hu.bme.mit.gamma.statechart.interface_.Event;
import hu.bme.mit.gamma.statechart.interface_.EventDeclaration;
import hu.bme.mit.gamma.statechart.interface_.EventDirection;
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression;
import hu.bme.mit.gamma.statechart.interface_.EventReference;
import hu.bme.mit.gamma.statechart.interface_.EventTrigger;
import hu.bme.mit.gamma.statechart.interface_.Interface;
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory;
import hu.bme.mit.gamma.statechart.interface_.InterfaceRealization;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.statechart.interface_.RealizationMode;
import hu.bme.mit.gamma.statechart.interface_.TimeSpecification;
import hu.bme.mit.gamma.statechart.interface_.TimeUnit;
import hu.bme.mit.gamma.statechart.interface_.Trigger;
import hu.bme.mit.gamma.statechart.phase.History;
import hu.bme.mit.gamma.statechart.statechart.AnyPortEventReference;
import hu.bme.mit.gamma.statechart.statechart.AsynchronousStatechartDefinition;
import hu.bme.mit.gamma.statechart.statechart.BinaryTrigger;
import hu.bme.mit.gamma.statechart.statechart.BinaryType;
import hu.bme.mit.gamma.statechart.statechart.ChoiceState;
import hu.bme.mit.gamma.statechart.statechart.CompositeElement;
import hu.bme.mit.gamma.statechart.statechart.EntryState;
import hu.bme.mit.gamma.statechart.statechart.InitialState;
import hu.bme.mit.gamma.statechart.statechart.PortEventReference;
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction;
import hu.bme.mit.gamma.statechart.statechart.Region;
import hu.bme.mit.gamma.statechart.statechart.State;
import hu.bme.mit.gamma.statechart.statechart.StateNode;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory;
import hu.bme.mit.gamma.statechart.statechart.SynchronousStatechartDefinition;
import hu.bme.mit.gamma.statechart.statechart.Transition;
import hu.bme.mit.gamma.statechart.statechart.TransitionPriority;
import hu.bme.mit.gamma.statechart.statechart.UnaryTrigger;
import hu.bme.mit.gamma.statechart.statechart.UnaryType;

public class StatechartUtil extends ActionUtil {
	// Singleton
	public static final StatechartUtil INSTANCE = new StatechartUtil();
	protected StatechartUtil() {}
	//

	protected InterfaceModelFactory interfaceFactory = InterfaceModelFactory.eINSTANCE;
	protected StatechartModelFactory statechartFactory = StatechartModelFactory.eINSTANCE;
	protected CompositeModelFactory compositeFactory = CompositeModelFactory.eINSTANCE;
	
	// Extending super methods
	
	@Override
	public Declaration getDeclaration(Expression expression) {
		if (expression instanceof EventParameterReferenceExpression) {
			EventParameterReferenceExpression reference = (EventParameterReferenceExpression) expression;
			return reference.getParameter();
		}
		return super.getDeclaration(expression);
	}
	
	@Override
	public ReferenceExpression getAccessReference(Expression expression) {
		if (expression instanceof EventParameterReferenceExpression) {
			return (EventParameterReferenceExpression) expression;
		}
		return super.getAccessReference(expression);
	}
	
	@Override
	public Declaration getAccessedDeclaration(Expression expression) {
		ReferenceExpression referenceExpression = getAccessReference(expression);
		if (referenceExpression instanceof EventParameterReferenceExpression) {
			EventParameterReferenceExpression reference = (EventParameterReferenceExpression) referenceExpression;
			return reference.getParameter();
		}
		return super.getAccessedDeclaration(referenceExpression);
	}
	
	@Override
	public Collection<TypeDeclaration> getTypeDeclarations(EObject context) {
		Package _package = ecoreUtil.getSelfOrContainerOfType(context, Package.class);
		List<TypeDeclaration> types = new ArrayList<TypeDeclaration>();
		for (Package _import :_package.getImports()) {
			types.addAll(_import.getTypeDeclarations());
		}
		types.addAll(_package.getTypeDeclarations());
		return types;
	}
	
	//
	
	public ComponentInstanceReferenceExpression createInstanceReferenceChain(ComponentInstance instance) {
		List<ComponentInstance> componentInstanceChain =
				StatechartModelDerivedFeatures.getComponentInstanceChain(instance);
		return createInstanceReference(componentInstanceChain);
	}
	
	public ComponentInstanceReferenceExpression createInstanceReferenceChain(
			List<? extends ComponentInstanceReferenceExpression> instanceReferences) {
		ComponentInstanceReferenceExpression first = instanceReferences.get(0);
		int size = instanceReferences.size();
		
		for (int i = 0; i < size - 1; i++) {
			ComponentInstanceReferenceExpression actual = instanceReferences.get(i);
			ComponentInstanceReferenceExpression next = instanceReferences.get(i + 1);

			actual.setChild(next);
		}
		
		return first;
	}
	
	public ComponentInstanceReferenceExpression createInstanceReference(ComponentInstance instance) {
		return createInstanceReference(
				List.of(instance));
	}
	
	public ComponentInstanceReferenceExpression createInstanceReference(List<? extends ComponentInstance> instances) {
		if (instances.isEmpty()) {
			throw new IllegalArgumentException("Empty instance list: " + instances);
		}
		ComponentInstanceReferenceExpression reference = compositeFactory.createComponentInstanceReferenceExpression();
		for (ComponentInstance instance : instances) {
			reference.setComponentInstance(instance);
			ComponentInstanceReferenceExpression child = compositeFactory.createComponentInstanceReferenceExpression();
			reference.setChild(child);
			reference = child;
		}
		ComponentInstanceReferenceExpression head =
				StatechartModelDerivedFeatures.getFirstInstanceReference(reference);
		ecoreUtil.remove(reference); // No instance
		return head;
	}
	
	public List<ComponentInstanceReferenceExpression> prepend(
			Collection<? extends ComponentInstanceReferenceExpression> references, ComponentInstance instance) {
		List<ComponentInstanceReferenceExpression> newReferences = new ArrayList<ComponentInstanceReferenceExpression>();
		for (ComponentInstanceReferenceExpression reference : references) {
			ComponentInstanceReferenceExpression newReference = prepend(reference, instance);
			newReferences.add(newReference);
		}
		return newReferences;
	}
	
	public ComponentInstanceReferenceExpression prepend(
			ComponentInstanceReferenceExpression reference, ComponentInstance instance) {
		ComponentInstanceReferenceExpression newReference = createInstanceReference(instance);
		newReference.setChild(reference);
		return newReference;
	}
	
	public ComponentInstanceReferenceExpression prependAndReplace(
			ComponentInstanceReferenceExpression reference, ComponentInstance instance) {
		ComponentInstanceReferenceExpression newReference = createInstanceReference(instance);
		ecoreUtil.replace(newReference, reference);
		newReference.setChild(reference);
		return newReference;
	}
	
	//
	
	public Set<VariableDeclaration> getVariables(EObject object) {
		return new HashSet<VariableDeclaration>(
				ecoreUtil.getSelfAndAllContentsOfType(object, VariableDeclaration.class));
	}
	
	public Set<VariableDeclaration> getWrittenVariables(EObject object) {
		Set<VariableDeclaration> variables = new HashSet<VariableDeclaration>();
		for (AssignmentStatement assignmentStatement :
				ecoreUtil.getSelfAndAllContentsOfType(object, AssignmentStatement.class)) {
			ReferenceExpression lhs = assignmentStatement.getLhs();
			if (lhs instanceof DirectReferenceExpression) {
				DirectReferenceExpression reference = (DirectReferenceExpression) lhs;
				Declaration declaration = reference.getDeclaration();
				if (declaration instanceof VariableDeclaration) {
					VariableDeclaration variable = (VariableDeclaration) declaration;
					variables.add(variable);
				}
			}
			else if (lhs instanceof AccessExpression) {
				// TODO handle access expressions
			}
		}
		return variables;
	}
	
	public Set<VariableDeclaration> getReadVariables(EObject object) {
		Set<VariableDeclaration> variables = new HashSet<VariableDeclaration>();
		for (ReferenceExpression referenceExpression :
				ecoreUtil.getSelfAndAllContentsOfType(object, ReferenceExpression.class)) {
			boolean isWritten = false;
			EObject container = referenceExpression.eContainer();
			if (container instanceof AssignmentStatement) {
				AssignmentStatement assignment = (AssignmentStatement) container;
				if (assignment.getLhs() == referenceExpression) {
					isWritten = true;
				}
			}
			if (!isWritten) {
				if (referenceExpression instanceof DirectReferenceExpression) {
					DirectReferenceExpression directReference = (DirectReferenceExpression) referenceExpression;
					Declaration declaration = directReference.getDeclaration();
					if (declaration instanceof VariableDeclaration) {
						VariableDeclaration variable = (VariableDeclaration) declaration;
						variables.add(variable);
					}
				}
				else {
					// TODO handle access expressions
				}
			}
		}
		return variables;
	}
	
	public Set<VariableDeclaration> getUnusedVariables(EObject object) {
		Set<VariableDeclaration> variables = getVariables(object);
		variables.removeAll(getWrittenVariables(object));
		variables.removeAll(getReadVariables(object));
		return variables;
	}
	
	public Set<VariableDeclaration> getOnlyIncrementedVariables(EObject object) {
		Set<VariableDeclaration> variables = new HashSet<VariableDeclaration>();
		for (AssignmentStatement assignmentStatement :
				ecoreUtil.getSelfAndAllContentsOfType(object, AssignmentStatement.class)) {
			ReferenceExpression lhs = assignmentStatement.getLhs();
			Expression rhs = assignmentStatement.getRhs();
			Declaration lhsVariable = getReferredValues(lhs).iterator().next();
			if (ecoreUtil.getSelfAndAllContentsOfType(object, DirectReferenceExpression.class)
					.stream().filter(it -> it != lhs && it.getDeclaration() == lhsVariable)
					.count() ==
				ecoreUtil.getSelfAndAllContentsOfType(rhs, DirectReferenceExpression.class)
					.stream().filter(it -> it.getDeclaration() == lhsVariable)
					.count()) {
				// Every reference is from the rhs
				variables.add((VariableDeclaration) lhsVariable);
			}
		}
		return variables;
	}
	
	public Set<VariableDeclaration> getWrittenOnlyVariables(EObject object) {
		Set<VariableDeclaration> variables = getWrittenVariables(object);
		variables.removeAll(getReadVariables(object));
		return variables;
	}
	
	public Set<VariableDeclaration> getReadOnlyVariables(EObject object) {
		Set<VariableDeclaration> variables = getReadVariables(object);
		variables.removeAll(getWrittenVariables(object));
		return variables;
	}
	
	public ParameterDeclaration extendEventWithParameter(Event event, Type parameterType, String name) {
		ParameterDeclaration parameter = factory.createParameterDeclaration();
		parameter.setType(parameterType);
		parameter.setName(name);
		event.getParameterDeclarations().add(parameter);
		return parameter;
	}
	
	public void setSourceAndTarget(Transition gammaTransition, State gammaState) {
		if (gammaTransition != null && gammaState != null) {
			StatechartDefinition gammaStatechart = StatechartModelDerivedFeatures
				.getContainingStatechart(gammaState);
			gammaTransition.setSourceState(gammaState);
			gammaTransition.setTargetState(gammaState);
			gammaStatechart.getTransitions().add(gammaTransition);
		}
	}
	
	public EventTrigger createEventTrigger(Port port, Event event) {
		PortEventReference portEventReference = statechartFactory.createPortEventReference();
		portEventReference.setPort(port);
		portEventReference.setEvent(event);
		
		EventTrigger eventTrigger = interfaceFactory.createEventTrigger();
		eventTrigger.setEventReference(portEventReference);
		
		return eventTrigger;
	}
	
	public List<Trigger> unwrapAnyTriggers(Iterable<? extends Trigger> triggers) {
		List<Trigger> simpleTriggers = new ArrayList<Trigger>();
		
		for (Trigger trigger : triggers) {
			simpleTriggers.addAll(
					unwrapAnyTrigger(trigger));
		}
		
		return simpleTriggers;
	}
	
	public List<Trigger> unwrapAnyTrigger(Trigger trigger) {
		List<Trigger> triggers = new ArrayList<Trigger>();
		
		if (trigger == null) {
			return triggers;
		}
		else if (trigger instanceof EventTrigger) {
			EventTrigger eventTrigger = (EventTrigger) trigger;
			EventReference eventReference = eventTrigger.getEventReference();
			if (eventReference instanceof AnyPortEventReference) {
				AnyPortEventReference anyPortEventReference = (AnyPortEventReference) eventReference;
				Port port = anyPortEventReference.getPort();
				List<Event> inputEvents = StatechartModelDerivedFeatures.getInputEvents(port);
				for (Event event : inputEvents) {
					EventTrigger newEventTrigger = createEventTrigger(port, event);
					triggers.add(newEventTrigger);
				}
			}
			else {
				triggers.add(trigger);
			}
		}
		else if (trigger instanceof AnyTrigger) {
			Component component = ecoreUtil.getContainerOfType(trigger, Component.class);
			List<Port> ports = StatechartModelDerivedFeatures.getAllPorts(component);
			for (Port port : ports) {
				List<Event> inputEvents = StatechartModelDerivedFeatures.getInputEvents(port);
				for (Event event : inputEvents) {
					EventTrigger newEventTrigger = createEventTrigger(port, event);
					triggers.add(newEventTrigger);
				}
			}
		}
		else {
			triggers.add(trigger);
		}
		
		return triggers;
	}
	
	public void extendTrigger(Transition transition, Trigger trigger, BinaryType type) {
		Trigger originalTrigger = transition.getTrigger();
		if (originalTrigger == null) {
			transition.setTrigger(trigger);
		}
		else {
			Trigger newTrigger = createBinaryTrigger(
					originalTrigger, trigger, type);
			transition.setTrigger(newTrigger);
		}
	}
	
	public Trigger createBinaryTrigger(Trigger oldTrigger, Trigger newTrigger, BinaryType type) {
		if (oldTrigger == null) {
			return newTrigger;
		}
		if (newTrigger == null) {
			return oldTrigger;
		}
		BinaryTrigger binaryTrigger = statechartFactory.createBinaryTrigger();
		binaryTrigger.setType(type);
		binaryTrigger.setLeftOperand(oldTrigger);
		binaryTrigger.setRightOperand(newTrigger);
		return binaryTrigger;
	}
	
	public UnaryTrigger createUnaryTrigger(Trigger trigger, UnaryType type) {
		if (trigger == null) {
			return null;
		}
		UnaryTrigger unaryTrigger = statechartFactory.createUnaryTrigger();
		unaryTrigger.setType(type);
		unaryTrigger.setOperand(trigger);
		return unaryTrigger;
	}
	
	public void extendGuard(Transition transition, Expression guard, MultiaryExpression container) {
		Expression originalGuard = transition.getGuard();
		if (originalGuard == null) {
			transition.setGuard(guard);
		}
		Expression newGuard = wrapIntoMultiaryExpression(
				originalGuard, guard, container);
		transition.setGuard(newGuard);
	}
	
	public boolean areDefinitelyFalseArguments(Expression guard, Port port, Event event,
			List<Expression> arguments) {
		if (guard == null) {
			return false;
		}
		Expression clonedGuard = ecoreUtil.clone(guard);
		List<EventParameterReferenceExpression> parameterReferences =
				ecoreUtil.getSelfAndAllContentsOfType(clonedGuard,
						EventParameterReferenceExpression.class);
		for (EventParameterReferenceExpression parameterReference : parameterReferences) {
			Port referredPort = parameterReference.getPort();
			Event referredEvent = parameterReference.getEvent();
			if (port == referredPort && event == referredEvent) {
				ParameterDeclaration referredParameter = parameterReference.getParameter();
				int index = ecoreUtil.getIndex(referredParameter);
				Expression argument = arguments.get(index);
				Expression clonedArgument = ecoreUtil.clone(argument);
				ecoreUtil.replace(clonedArgument, parameterReference);
			}
		}
		return evaluator.isDefinitelyFalseExpression(clonedGuard);
	}
	
	public int evaluateMilliseconds(TimeSpecification time) {
		int value = evaluator.evaluateInteger(time.getValue());
		TimeUnit unit = time.getUnit();
		switch (unit) {
			case MILLISECOND:
				return value;
			case SECOND:
				return value * 1000;
			case HOUR:
				return value * 1000 * 60 * 60;
			default:
				throw new IllegalArgumentException("Not known unit: " + unit);
		}
	}
	
	public long evaluateNanoseconds(TimeSpecification time) {
		long value = evaluator.evaluateInteger(time.getValue());
		TimeUnit unit = time.getUnit();
		switch (unit) {
			case NANOSECOND:
				return value;
			case MICROSECOND:
				return value * 1000;
			case MILLISECOND:
				return value * 1000000;
			case SECOND:
				return value * 1000000000;
			case HOUR:
				return value * 1000000000 * 60 * 60;
			default:
				throw new IllegalArgumentException("Not known unit: " + unit);
		}
	}
	
	public AsynchronousAdapter wrapIntoAdapter(SynchronousComponent component,
			String adapterName, String instanceName) {
		AsynchronousAdapter adapter = wrapIntoAdapter(component, adapterName);
		SynchronousComponentInstance synchronousInstance = adapter.getWrappedComponent();
		synchronousInstance.setName(instanceName);
		return adapter;
	}
	
	public AsynchronousAdapter wrapIntoAdapter(SynchronousComponent component, String adapterName) {
		AsynchronousAdapter adapter = compositeFactory.createAsynchronousAdapter();
		adapter.setName(adapterName);
		
		SynchronousComponentInstance synchronousInstance = instantiateSynchronousComponent(component);
		adapter.setWrappedComponent(synchronousInstance);
		
		for (ParameterDeclaration parameterDeclaration : component.getParameterDeclarations()) {
			ParameterDeclaration clonedParamaterDeclaration = ecoreUtil.clone(parameterDeclaration);
			adapter.getParameterDeclarations()
					.add(clonedParamaterDeclaration);
			
			DirectReferenceExpression argument = createReferenceExpression(clonedParamaterDeclaration);
			synchronousInstance.getArguments()
					.add(argument);
		}
		
		return adapter;
	}
	
	public AsynchronousAdapter wrapIntoDefaultAdapter(SynchronousComponent component, String adapterName) {
		return wrapIntoDefaultAdapter(component, adapterName, adapterName + "MessageQueue", 4);
	}
	
	public AsynchronousAdapter wrapIntoDefaultAdapter(SynchronousComponent component, String adapterName,
			String messageQueueName, int capacity) {
		return wrapIntoDefaultAdapter(component, adapterName, messageQueueName, toIntegerLiteral(capacity));
	}
	
	public AsynchronousAdapter wrapIntoDefaultAdapter(SynchronousComponent component, String adapterName,
			String messageQueueName, Expression capacity) {
		AsynchronousAdapter adapter = wrapIntoAdapter(component, adapterName);
		
		ControlSpecification controlSpecification = compositeFactory.createControlSpecification();
		controlSpecification.setTrigger(interfaceFactory.createAnyTrigger());
		controlSpecification.setControlFunction(ControlFunction.RUN_ONCE);
		
		adapter.getControlSpecifications().add(controlSpecification);
		
		MessageQueue messageQueue = compositeFactory.createMessageQueue();
		messageQueue.setName(messageQueueName);
		messageQueue.setEventDiscardStrategy(DiscardStrategy.INCOMING);
		messageQueue.setPriority(BigInteger.ONE);
		messageQueue.setCapacity(capacity);
		
		for (Port port : StatechartModelDerivedFeatures.getAllPortsWithInput(component)) {
			AnyPortEventReference reference = statechartFactory.createAnyPortEventReference();
			reference.setPort(port);
			
			EventPassing eventPassing = createEventPassing(reference);
			
			messageQueue.getEventPassings().add(eventPassing);
		}
		
		adapter.getMessageQueues().add(messageQueue);
		
		return adapter;
	}
	
	public Package wrapIntoPackage(Component component) {
		Package _package = createPackage(component.getName().toLowerCase());
		_package.getComponents().add(component);
		return _package;
	}
	
	public Package wrapIntoPackage(Interface _interface) {
		Package _package = createPackage(_interface.getName().toLowerCase());
		_package.getInterfaces().add(_interface);
		return _package;
	}
	
	public Package wrapIntoPackageAndAddImports(Component component) {
		Package _package = wrapIntoPackage(component);
		_package.getImports().addAll(
				StatechartModelDerivedFeatures.getImportablePackages(component));
		return _package;
	}
	
	public Package createPackage(String name) {
		Package _package = interfaceFactory.createPackage();
		_package.setName(name);
		return _package;
	}
	
	public Port createPort(Interface _interface, RealizationMode mode, String name) {
		Port port = interfaceFactory.createPort();
		port.setName(name);
		InterfaceRealization interfaceRealization = interfaceFactory.createInterfaceRealization();
		interfaceRealization.setRealizationMode(mode);
		interfaceRealization.setInterface(_interface);
		port.setInterfaceRealization(interfaceRealization);
		return port;
	}
	
	public Port createOppositePort(Port port) {
		Port oppositePort = ecoreUtil.clone(port);
		
		InterfaceRealization interfaceRealization = oppositePort.getInterfaceRealization();
		RealizationMode realizationMode = interfaceRealization.getRealizationMode();
		RealizationMode opposite = StatechartModelDerivedFeatures.getOpposite(realizationMode);
		interfaceRealization.setRealizationMode(opposite);
		
		return oppositePort;
	}
	
	public Interface createBroadcastInterface(Interface _interface) {
		Interface broadcastInterface = ecoreUtil.clone(_interface);
		
		for (EventDeclaration event : broadcastInterface.getEvents()) {
			event.setDirection(EventDirection.OUT);
		}
		
		return broadcastInterface;
	}
	
	public ComponentInstance instantiateComponent(Component component) {
		if (component instanceof SynchronousComponent) {
			return instantiateSynchronousComponent(
					(SynchronousComponent) component);
		}
		if (component instanceof AsynchronousComponent) {
			return instantiateAsynchronousComponent(
					(AsynchronousComponent) component);
		}
		throw new IllegalArgumentException("Not known type: " + component);
	}
	
	public SynchronousComponentInstance instantiateSynchronousComponent(SynchronousComponent component) {
		SynchronousComponentInstance instance = compositeFactory.createSynchronousComponentInstance();
		instance.setName(
				getWrapperInstanceName(component));
		instance.setType(component);
		return instance;
	}
	
	public AsynchronousComponentInstance instantiateAsynchronousComponent(AsynchronousComponent component) {
		AsynchronousComponentInstance instance = compositeFactory.createAsynchronousComponentInstance();
		instance.setName(getWrapperInstanceName(component));
		instance.setType(component);
		return instance;
	}
	
	public void prependComponentInstance(Component component, ComponentInstance instance) {
		if (component instanceof AbstractSynchronousCompositeComponent) {
			AbstractSynchronousCompositeComponent compositeComponent =
					(AbstractSynchronousCompositeComponent) component;
			SynchronousComponentInstance synchronousInstance = (SynchronousComponentInstance) instance;
			compositeComponent.getComponents().add(0, synchronousInstance);
		}
		else if (component instanceof AbstractAsynchronousCompositeComponent) {
			AbstractAsynchronousCompositeComponent compositeComponent =
					(AbstractAsynchronousCompositeComponent) component;
			AsynchronousComponentInstance asynchronousInstance = (AsynchronousComponentInstance) instance;
			compositeComponent.getComponents().add(0, asynchronousInstance);
		}
		else {
			throw new IllegalArgumentException("Not known type: " + component);
		}
	}
	
	public void addComponentInstance(Component component, ComponentInstance instance) {
		if (component instanceof AbstractSynchronousCompositeComponent) {
			AbstractSynchronousCompositeComponent compositeComponent =
					(AbstractSynchronousCompositeComponent) component;
			SynchronousComponentInstance synchronousInstance = (SynchronousComponentInstance) instance;
			compositeComponent.getComponents().add(synchronousInstance);
		}
		else if (component instanceof AbstractAsynchronousCompositeComponent) {
			AbstractAsynchronousCompositeComponent compositeComponent =
					(AbstractAsynchronousCompositeComponent) component;
			AsynchronousComponentInstance asynchronousInstance = (AsynchronousComponentInstance) instance;
			compositeComponent.getComponents().add(asynchronousInstance);
		}
		else {
			throw new IllegalArgumentException("Not known type: " + component);
		}
	}
	
	public void scheduleInstance(SchedulableCompositeComponent composite, ComponentInstance instance) {
		scheduleInstances(composite, List.of(instance));
	}
	
	public void scheduleInstances(SchedulableCompositeComponent composite,
			List<? extends ComponentInstance> instances) {
		List<ComponentInstanceReferenceExpression> executionList = composite.getExecutionList();
		for (ComponentInstance componentInstance : instances) {
			executionList.add(createInstanceReference(componentInstance));
		}
	}
	
	public void setType(ComponentInstance instance, Component type) {
		if (instance instanceof SynchronousComponentInstance synchronousInstance) {
			SynchronousComponent synchronousType = (SynchronousComponent) type;
			synchronousInstance.setType(synchronousType);
		}
		else if (instance instanceof AsynchronousComponentInstance asynchronousInstance) {
			AsynchronousComponent asynchronousType = (AsynchronousComponent) type;
			asynchronousInstance.setType(asynchronousType);
		}
		else {
			throw new IllegalArgumentException("Not known type: " + type);
		}
	}
	
	public void setInstanceTypes(CompositeComponent changeable, CompositeComponent target) {
		List<? extends ComponentInstance> changeableInstances = StatechartModelDerivedFeatures.getDerivedComponents(changeable);
		List<? extends ComponentInstance> targetInstances = StatechartModelDerivedFeatures.getDerivedComponents(target);
		setInstanceTypes(changeableInstances, targetInstances);
	}

	public void setInstanceTypes(List<? extends ComponentInstance> changeableInstances,
			List<? extends ComponentInstance> targetInstances) {
		for (int i = 0; i < changeableInstances.size(); i++) {
			ComponentInstance changeableInstance = changeableInstances.get(i);
			ComponentInstance targetInstance = targetInstances.get(i);
			setType(changeableInstance,
					StatechartModelDerivedFeatures.getDerivedType(targetInstance));
		}
	}
	
	public SchedulableCompositeComponent wrapComponent(Component component) {
		if (component instanceof SynchronousComponent) {
			return wrapSynchronousComponent(
					(SynchronousComponent) component);
		}
		else if (component instanceof AsynchronousComponent) {
			return wrapAsynchronousComponent(
					(AsynchronousComponent) component);
		}
		throw new IllegalArgumentException("Not known type: " + component);
	}
	
	public CascadeCompositeComponent wrapSynchronousComponent(SynchronousComponent component) {
		CascadeCompositeComponent cascade = compositeFactory.createCascadeCompositeComponent();
		cascade.setName(component.getName()); // Trick: same name, so reflective API will work
		SynchronousComponentInstance instance = instantiateSynchronousComponent(component);
		cascade.getComponents().add(instance);
		
		wrapComponent(cascade, instance);
		
		return cascade;
	}
	
	public ScheduledAsynchronousCompositeComponent wrapAsynchronousComponent(AsynchronousComponent component) {
		ScheduledAsynchronousCompositeComponent asynchron =
				compositeFactory.createScheduledAsynchronousCompositeComponent();
		asynchron.setName(component.getName()); // Trick: same name, so reflective API will work
		AsynchronousComponentInstance instance = instantiateAsynchronousComponent(component);
		asynchron.getComponents().add(instance);
		
		wrapComponent(asynchron, instance);
		
		// Binding internal ports in asynchronous systems is unnecessary
		List<PortBinding> portBindings = new ArrayList<PortBinding>(asynchron.getPortBindings());
		for (PortBinding portBinding : portBindings) {
			Port compositeSystemPort = portBinding.getCompositeSystemPort();
			if (StatechartModelDerivedFeatures.isInternal(compositeSystemPort)) {
				ecoreUtil.remove(portBinding);
				ecoreUtil.remove(compositeSystemPort);
			}
		}
		
		return asynchron;
	}

	private void wrapComponent(CompositeComponent wrapper, ComponentInstance instance) {
		Component component = StatechartModelDerivedFeatures.getDerivedType(instance);
		
		// Parameter declarations
		if (instance.getArguments().isEmpty()) {
			for (ParameterDeclaration parameterDeclaration : component.getParameterDeclarations()) {
				ParameterDeclaration newParameter = ecoreUtil.clone(parameterDeclaration);
				wrapper.getParameterDeclarations().add(newParameter);
				DirectReferenceExpression reference = createReferenceExpression(newParameter);
				instance.getArguments().add(reference);
			}
		}
		
		// Ports
		List<Port> ports = StatechartModelDerivedFeatures.getAllPorts(component);
		for (int i = 0; i < ports.size(); ++i) {
			Port port = ports.get(i);
			Port clonedPort = ecoreUtil.clone(port);
			wrapper.getPorts().add(clonedPort);
			PortBinding portBinding = compositeFactory.createPortBinding();
			portBinding.setCompositeSystemPort(clonedPort);
			InstancePortReference instancePortReference = compositeFactory.createInstancePortReference();
			instancePortReference.setInstance(instance);
			instancePortReference.setPort(port);
			portBinding.setInstancePortReference(instancePortReference);
			wrapper.getPortBindings().add(portBinding);
		}
	}
	
	public String getWrapperInstanceName(Component component) {
		// The same as in Namings.getComponentClassName
		return StatechartModelDerivedFeatures.getWrapperInstanceName(component);
	}
	
	public SimpleChannel connectPortsViaChannels(InstancePortReference lhsReference,
			InstancePortReference rhsReference) {
		return connectPortsViaChannels(lhsReference.getInstance(), lhsReference.getPort(),
				rhsReference.getInstance(), rhsReference.getPort());
	}
	
	public SimpleChannel connectPortsViaChannels(ComponentInstance lhsInstance, Port lhsPort,
			ComponentInstance rhsInstance, Port rhsPort) {
		SimpleChannel channel = compositeFactory.createSimpleChannel();
		
		InstancePortReference providedReference = compositeFactory.createInstancePortReference();
		InstancePortReference requiredReference = compositeFactory.createInstancePortReference();
		
		channel.setProvidedPort(providedReference);
		channel.setRequiredPort(requiredReference);
		if (StatechartModelDerivedFeatures.isProvided(lhsPort)) {
			providedReference.setInstance(lhsInstance);
			providedReference.setPort(lhsPort);
			requiredReference.setInstance(rhsInstance);
			requiredReference.setPort(rhsPort);
		}
		else {
			providedReference.setInstance(rhsInstance);
			providedReference.setPort(rhsPort);
			requiredReference.setInstance(lhsInstance);
			requiredReference.setPort(lhsPort);
		}
		return channel;
	}
	
	public EventPassing createEventPassing(EventReference source) {
		return createEventPassing(source, null);
	}
	
	public EventPassing createEventPassing(EventReference source, EventReference target) {
		EventPassing eventPassing = compositeFactory.createEventPassing();

		eventPassing.setSource(source);
		eventPassing.setTarget(target);
		
		return eventPassing;
	}
	
	public PortBinding createPortBinding(Port systemPort, InstancePortReference portReference) {
		PortBinding portBinding = compositeFactory.createPortBinding();
		portBinding.setCompositeSystemPort(systemPort);
		portBinding.setInstancePortReference(portReference);
		return portBinding;
	}
	
	public InstancePortReference createInstancePortReference(ComponentInstance instance, Port port) {
		InstancePortReference instancePortReference =
				compositeFactory.createInstancePortReference();
		instancePortReference.setInstance(instance);
		instancePortReference.setPort(port);
		return instancePortReference;
	}
	
	public Channel createChannel(InstancePortReference provided, InstancePortReference required) {
		return createChannel(provided, List.of(required));
	}
	
	public Channel createChannel(InstancePortReference provided,
			Collection<? extends InstancePortReference> required) {
		Channel channel = null;
		if (required.size() > 1) {
			BroadcastChannel broadcastChannel = compositeFactory.createBroadcastChannel();
			broadcastChannel.getRequiredPorts().addAll(required);
			channel = broadcastChannel;
		}
		else {
			SimpleChannel simpleChannel = compositeFactory.createSimpleChannel();
			InstancePortReference element = required.iterator().next();
			simpleChannel.setRequiredPort(element);
			channel = simpleChannel;
		}
		channel.setProvidedPort(provided);
		return channel;
	}
	
	// Statechart annotations
	
	protected void addAnnotation(Component component, ComponentAnnotation annotation) {
		component.getAnnotations().add(annotation);
	}
	
	public void addWrapperComponentAnnotation(Component component) {
		addAnnotation(component, interfaceFactory.createWrapperComponentAnnotation());
	}
	
	public void addRunUponExternalEventAnnotation(Component component) {
		addAnnotation(component, statechartFactory.createRunUponExternalEventAnnotation());
	}
	
	public void addMutantAnnotation(Component component) {
		addAnnotation(component, statechartFactory.createMutantAnnotation());
	}
	
	// Statechart element creators
	
	public Transition createTransition(StateNode source, StateNode target) {
		Transition transition = statechartFactory.createTransition();
		transition.setSourceState(source);
		transition.setTargetState(target);
		
		StatechartDefinition statechart =
				StatechartModelDerivedFeatures.getContainingStatechart(source);
		if (statechart != null) {
			statechart.getTransitions().add(transition);
		}
		return transition;
	}
	
	public Transition createMaximumPriorityTransition(StateNode sourceState, StateNode targetState) {
		Transition transition = createTransition(sourceState, targetState);
		maximizeTransitionPriority(transition); // To support if-else over nondeterministic choices

		return transition;
	}
	
	public void maximizeTransitionPriority(Transition transition) {
		StatechartDefinition statechart =
				StatechartModelDerivedFeatures.getContainingStatechart(transition);
		TransitionPriority transitionPriority = statechart.getTransitionPriority();
		if (transitionPriority == TransitionPriority.VALUE_BASED) {
			StateNode source = transition.getSourceState();
			List<Transition> outgoingTransitions =
					StatechartModelDerivedFeatures.getOutgoingTransitions(source);
			
			BigInteger maxPriority = outgoingTransitions.stream()
					.map(it -> it.getPriority())
					.max((lhs, rhs) -> lhs.compareTo(rhs))
					.get();
			BigInteger newPriority = maxPriority.add(BigInteger.ONE);
			
			transition.setPriority(newPriority);
		}
		else if (transitionPriority == TransitionPriority.ORDER_BASED) {
			List<Transition> transitions = statechart.getTransitions();
			boolean foundTransition = false;
			for (int i = 0; i < transitions.size() && !foundTransition; ++i) {
				Transition potentiallySearchedTransition = transitions.get(i);
				if (potentiallySearchedTransition.getSourceState() == transition.getSourceState()) {
					transitions.add(i, transition);
					
					foundTransition = true;
				}
			}
		}
	}
	
	public History createHistory(boolean hasHistory) {
		if (hasHistory) {
			return History.DEEP_HISTORY;
		}
		else {
			return History.NO_HISTORY;
		}
	}
	
	public EntryState createEntryState(History history) {
		switch (history) {
			case NO_HISTORY:
				return statechartFactory.createInitialState();
			case SHALLOW_HISTORY:
				return statechartFactory.createShallowHistoryState();
			case DEEP_HISTORY:
				return statechartFactory.createDeepHistoryState();
		}
		throw new IllegalArgumentException("Not known history: " + history);
	}
	
	public State createRegionWithState(CompositeElement compositeElement,
			EntryState entry, String regionName, String stateName) {
		Region region = statechartFactory.createRegion();
		region.setName(regionName);
		compositeElement.getRegions().add(region);
		
		region.getStateNodes().add(entry);
		
		State state = statechartFactory.createState();
		state.setName(stateName);
		region.getStateNodes().add(state);
		
		createTransition(entry, state);
		
		return state;
	}
	
	public State createState(Region region, String stateName) {
		State state = statechartFactory.createState();
		state.setName(stateName);
		region.getStateNodes().add(state);
		
		return state;
	}
	
	public State createRegionWithState(CompositeElement compositeElement,
			String regionName, String initialStateName, String stateName) {
		InitialState initialState = createInitialState(initialStateName);
		return createRegionWithState(compositeElement,
				initialState, regionName, stateName);
	}
	
	public ChoiceState createChoiceState(Transition incomingTransition, String choiceName,
			Transition outgoingTransition) {
		return createChoiceState(incomingTransition, choiceName, List.of(outgoingTransition));
	}
	
	public ChoiceState createChoiceState(Transition incomingTransition, String choiceName,
			Collection<? extends Transition> outgoingTransitions) {
		ChoiceState choice = statechartFactory.createChoiceState();
		choice.setName(choiceName);
		
		incomingTransition.setTargetState(choice);
		for (Transition outgoingTransition : outgoingTransitions) {
			outgoingTransition.setSourceState(choice);
		}
		
		return choice;
	}
	
	public Transition createChoiceStateWithIncomingTransition(String choiceName, Collection<? extends Transition> outgoingTransitions) {
		Transition incomingTransition = statechartFactory.createTransition();
		incomingTransition.setTrigger(
				statechartFactory.createOnCycleTrigger());
		
		createChoiceState(incomingTransition, choiceName, outgoingTransitions);
		
		return incomingTransition;
	}

	public InitialState createInitialState(String name) {
		InitialState initialState = statechartFactory.createInitialState();
		initialState.setName(name);
		return initialState;
	}
	
	public EventParameterReferenceExpression createEventParameterReference(
			Port port, ParameterDeclaration parameter) {
		EventParameterReferenceExpression expression = interfaceFactory.createEventParameterReferenceExpression();
		expression.setPort(port);
		Event event = ecoreUtil.getContainerOfType(parameter, Event.class);
		expression.setEvent(event);
		expression.setParameter(parameter);
		return expression;
	}
	
	public RaiseEventAction createRaiseEventAction(Port port, Event event, Expression parameter) {
		return createRaiseEventAction(port, event, List.of(parameter));
	}
	
	public RaiseEventAction createRaiseEventAction(
			Port port, Event event, List<? extends Expression> parameters) {
		RaiseEventAction raiseEventAction = statechartFactory.createRaiseEventAction();
		raiseEventAction.setPort(port);
		raiseEventAction.setEvent(event);
		raiseEventAction.getArguments().addAll(parameters);
		return raiseEventAction;
	}
	
	// Atomic component instance reference expressions
	
	public ComponentInstanceStateReferenceExpression createStateReference(
			ComponentInstanceReferenceExpression instance, State state) {
		ComponentInstanceStateReferenceExpression reference =
				compositeFactory.createComponentInstanceStateReferenceExpression();
		reference.setInstance(instance);
		reference.setRegion(StatechartModelDerivedFeatures.getParentRegion(state));
		reference.setState(state);
		return reference;
	}
	
	public ComponentInstanceVariableReferenceExpression createVariableReference(ComponentInstanceReferenceExpression instance,
			VariableDeclaration variable) {
		ComponentInstanceVariableReferenceExpression reference =
				compositeFactory.createComponentInstanceVariableReferenceExpression();
		reference.setInstance(instance);
		reference.setVariableDeclaration(variable);
		return reference;
	}
	
	public ComponentInstanceEventReferenceExpression createEventReference(ComponentInstanceReferenceExpression instance,
			Port port, Event event) {
		ComponentInstanceEventReferenceExpression reference =
				compositeFactory.createComponentInstanceEventReferenceExpression();
		reference.setInstance(instance);
		reference.setPort(port);
		reference.setEvent(event);
		return reference;
	}
	
	public ComponentInstanceEventReferenceExpression createSystemEventReference(Port port, Event event) {
		Entry<List<ComponentInstance>, Port> boundSimplePort = StatechartModelDerivedFeatures.getBoundSimplePort(port);
		if (boundSimplePort == null) {
			return null;
		}
		
		List<ComponentInstance> instances = boundSimplePort.getKey();
		Port simplePort = boundSimplePort.getValue();
		
		ComponentInstanceReferenceExpression instanceReference = createInstanceReference(instances);
		
		return createEventReference(instanceReference, simplePort, event);
	}
	
	public ComponentInstanceEventParameterReferenceExpression createParameterReference(
			ComponentInstanceReferenceExpression instance, Port port, Event event, ParameterDeclaration parameter) {
		ComponentInstanceEventParameterReferenceExpression reference =
				compositeFactory.createComponentInstanceEventParameterReferenceExpression();
		reference.setInstance(instance);
		reference.setPort(port);
		reference.setEvent(event);
		reference.setParameterDeclaration(parameter);
		return reference;
	}
	
	public ComponentInstanceEventParameterReferenceExpression createSystemParameterReference(
			Port port, Event event, ParameterDeclaration parameter) {
		Entry<List<ComponentInstance>, Port> boundSimplePort = StatechartModelDerivedFeatures.getBoundSimplePort(port);
		if (boundSimplePort == null) {
			return null;
		}
		
		List<ComponentInstance> instances = boundSimplePort.getKey();
		Port simplePort = boundSimplePort.getValue();
		
		ComponentInstanceReferenceExpression instanceReference = createInstanceReference(instances);
		
		return createParameterReference(instanceReference, simplePort, event, parameter);
	}
	
	// Synchronous-asynchronous statecharts
	
	public SynchronousStatechartDefinition mapIntoSynchronousStatechart(
			AsynchronousStatechartDefinition statechart) {
		Expression capacity = statechart.getCapacity();
		statechart.setCapacity(null); // As this element cannot be transferred to a synchronous statechart
		
		SynchronousStatechartDefinition synchronousStatechart =
				statechartFactory.createSynchronousStatechartDefinition();
		copyStatechart(statechart, synchronousStatechart);
		
		statechart.setCapacity(capacity); // Resetting capacity
		
		return synchronousStatechart;
	}
	
	public AsynchronousStatechartDefinition mapIntoAsynchronousStatechart(
			StatechartDefinition statechart) {
		AsynchronousStatechartDefinition asynchronousStatechart =
				statechartFactory.createAsynchronousStatechartDefinition();
		copyStatechart(statechart, asynchronousStatechart);
		
		return asynchronousStatechart;
	}

	public void copyStatechart(StatechartDefinition source, StatechartDefinition target) {
		// Attributes
		target.setName(source.getName());
		target.setGuardEvaluation(source.getGuardEvaluation());
		target.setOrthogonalRegionSchedulingOrder(source.getOrthogonalRegionSchedulingOrder());
		target.setSchedulingOrder(source.getSchedulingOrder());
		target.setTransitionPriority(source.getTransitionPriority());
		// Containment
		ecoreUtil.copyContent(source, target);
	}
	
	public List<Transition> relocateIncomingTransitions(StateNode source, StateNode target) {
		List<Transition> incomingTransitions = StatechartModelDerivedFeatures.getIncomingTransitions(source);
		for (Transition incomingTransition : incomingTransitions) {
			incomingTransition.setTargetState(target);
		}
		return incomingTransitions;
	}
	
	public List<Transition> relocateOutgoingTransitions(StateNode source, StateNode target) {
		List<Transition> outgoingTransitions = StatechartModelDerivedFeatures.getOutgoingTransitions(source);
		for (Transition outgoingTransition : outgoingTransitions) {
			outgoingTransition.setSourceState(target);
		}
		return outgoingTransitions;
	}
	
	public void relocateOutgoingTransitionsAndNodes(StateNode source, StateNode target) {
		List<Transition> outgoingTransitions = relocateOutgoingTransitions(source, target);
		
		Region targetRegion = StatechartModelDerivedFeatures.getParentRegion(target);
		
		Set<Transition> checkedTransitions = new HashSet<Transition>();
		Queue<Transition> transitions = new LinkedList<Transition>(outgoingTransitions);
		while (!transitions.isEmpty()) {
			Transition transition = transitions.poll();
			if (!checkedTransitions.contains(transition)) {
				
				StateNode targetNode = transition.getTargetState();
				if (targetNode == source) {
					// If there is a source --> .. --> source loop, we set 'target' as target
					transition.setTargetState(target);
				}
				else {
					targetRegion.getStateNodes().add(targetNode);
				}
				
				transitions.addAll(
						StatechartModelDerivedFeatures.getOutgoingTransitions(targetNode));
				
				checkedTransitions.add(transition);
			}
		}
	}
	
	public void removeRegions(CompositeElement element) {
		StatechartDefinition statechart = StatechartModelDerivedFeatures
				.getContainingStatechart(element);
		
		List<StateNode> nodes = ecoreUtil.getAllContentsOfType(element, StateNode.class);
		
		List<Transition> transitions = new ArrayList<Transition>(
				statechart.getTransitions());
		for (Transition transition : transitions) {
			if (nodes.contains(transition.getSourceState()) ||
					nodes.contains(transition.getTargetState())) {
				ecoreUtil.remove(transition);
			}
		}
		
		ecoreUtil.removeAll(element.getRegions());
	}
	
}