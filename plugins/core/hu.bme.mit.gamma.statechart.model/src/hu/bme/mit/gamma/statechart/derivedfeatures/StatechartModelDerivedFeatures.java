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
package hu.bme.mit.gamma.statechart.derivedfeatures;

import java.math.BigInteger;
import java.util.AbstractMap.SimpleEntry;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Map.Entry;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

import org.eclipse.emf.common.util.TreeIterator;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.util.EcoreUtil;

import hu.bme.mit.gamma.action.derivedfeatures.ActionModelDerivedFeatures;
import hu.bme.mit.gamma.action.model.Action;
import hu.bme.mit.gamma.expression.model.ArgumentedElement;
import hu.bme.mit.gamma.expression.model.ElseExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression;
import hu.bme.mit.gamma.expression.model.FunctionDeclaration;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.TypeDefinition;
import hu.bme.mit.gamma.statechart.composite.AbstractAsynchronousCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.AbstractSynchronousCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter;
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponent;
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.composite.BroadcastChannel;
import hu.bme.mit.gamma.statechart.composite.CascadeCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.Channel;
import hu.bme.mit.gamma.statechart.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference;
import hu.bme.mit.gamma.statechart.composite.CompositeComponent;
import hu.bme.mit.gamma.statechart.composite.ControlSpecification;
import hu.bme.mit.gamma.statechart.composite.InstancePortReference;
import hu.bme.mit.gamma.statechart.composite.MessageQueue;
import hu.bme.mit.gamma.statechart.composite.PortBinding;
import hu.bme.mit.gamma.statechart.composite.ScheduledAsynchronousCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.SimpleChannel;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponent;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.contract.AdaptiveContractAnnotation;
import hu.bme.mit.gamma.statechart.interface_.AnyTrigger;
import hu.bme.mit.gamma.statechart.interface_.Clock;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Event;
import hu.bme.mit.gamma.statechart.interface_.EventDeclaration;
import hu.bme.mit.gamma.statechart.interface_.EventDirection;
import hu.bme.mit.gamma.statechart.interface_.EventReference;
import hu.bme.mit.gamma.statechart.interface_.EventSource;
import hu.bme.mit.gamma.statechart.interface_.EventTrigger;
import hu.bme.mit.gamma.statechart.interface_.Interface;
import hu.bme.mit.gamma.statechart.interface_.InterfaceRealization;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.interface_.PackageAnnotation;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.statechart.interface_.RealizationMode;
import hu.bme.mit.gamma.statechart.interface_.SimpleTrigger;
import hu.bme.mit.gamma.statechart.interface_.TimeSpecification;
import hu.bme.mit.gamma.statechart.interface_.TopComponentArgumentsAnnotation;
import hu.bme.mit.gamma.statechart.interface_.UnfoldedPackageAnnotation;
import hu.bme.mit.gamma.statechart.interface_.WrappedPackageAnnotation;
import hu.bme.mit.gamma.statechart.statechart.AnyPortEventReference;
import hu.bme.mit.gamma.statechart.statechart.ChoiceState;
import hu.bme.mit.gamma.statechart.statechart.ClockTickReference;
import hu.bme.mit.gamma.statechart.statechart.CompositeElement;
import hu.bme.mit.gamma.statechart.statechart.DeepHistoryState;
import hu.bme.mit.gamma.statechart.statechart.EntryState;
import hu.bme.mit.gamma.statechart.statechart.ForkState;
import hu.bme.mit.gamma.statechart.statechart.InitialState;
import hu.bme.mit.gamma.statechart.statechart.JoinState;
import hu.bme.mit.gamma.statechart.statechart.MergeState;
import hu.bme.mit.gamma.statechart.statechart.PortEventReference;
import hu.bme.mit.gamma.statechart.statechart.PseudoState;
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction;
import hu.bme.mit.gamma.statechart.statechart.Region;
import hu.bme.mit.gamma.statechart.statechart.SetTimeoutAction;
import hu.bme.mit.gamma.statechart.statechart.ShallowHistoryState;
import hu.bme.mit.gamma.statechart.statechart.State;
import hu.bme.mit.gamma.statechart.statechart.StateAnnotation;
import hu.bme.mit.gamma.statechart.statechart.StateNode;
import hu.bme.mit.gamma.statechart.statechart.StatechartAnnotation;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.statechart.statechart.TimeoutDeclaration;
import hu.bme.mit.gamma.statechart.statechart.TimeoutEventReference;
import hu.bme.mit.gamma.statechart.statechart.Transition;
import hu.bme.mit.gamma.statechart.statechart.TransitionAnnotation;
import hu.bme.mit.gamma.statechart.statechart.TransitionIdAnnotation;
import hu.bme.mit.gamma.statechart.statechart.TransitionPriority;
import hu.bme.mit.gamma.statechart.util.StatechartUtil;

public class StatechartModelDerivedFeatures extends ActionModelDerivedFeatures {
	
	protected static final StatechartUtil statechartUtil = StatechartUtil.INSTANCE;
	
	public static List<ParameterDeclaration> getParameterDeclarations(ArgumentedElement element) {
		if (element instanceof RaiseEventAction) {
			RaiseEventAction raiseEventAction = (RaiseEventAction) element;
			Event event = raiseEventAction.getEvent();
			return event.getParameterDeclarations();
		}
		if (element instanceof ComponentInstance) {
			ComponentInstance instance = (ComponentInstance) element;
			return getDerivedType(instance).getParameterDeclarations();
		}
		if (element instanceof FunctionAccessExpression) {
			FunctionAccessExpression functionAccess = (FunctionAccessExpression) element;
			FunctionDeclaration functionDeclaration = (FunctionDeclaration)
					expressionUtil.getDeclaration(functionAccess.getOperand());
			return functionDeclaration.getParameterDeclarations();
		}
		throw new IllegalArgumentException("Not supported element: " + element);
	}

	public static boolean isBroadcast(InterfaceRealization interfaceRealization) {
		return isProvided(interfaceRealization) &&
			interfaceRealization.getInterface().getEvents().stream().allMatch(it -> it.getDirection() == EventDirection.OUT);
	}
	
	public static boolean isProvided(InterfaceRealization interfaceRealization) {
		return interfaceRealization.getRealizationMode() == RealizationMode.PROVIDED;
	}
	
	public static RealizationMode getOpposite(RealizationMode realizationMode) {
		switch (realizationMode) {
			case PROVIDED:
				return RealizationMode.REQUIRED;
			case REQUIRED:
				return RealizationMode.PROVIDED;
			default:
				throw new IllegalArgumentException("Not known realization mode: " + realizationMode);
		}
	}
	
	public static boolean isBroadcast(Port port) {
		return isBroadcast(port.getInterfaceRealization());
	}
	
	public static boolean isProvided(Port port) {
		return isProvided(port.getInterfaceRealization());
	}
	
	public static Interface getInterface(Port port) {
		return port.getInterfaceRealization().getInterface();
	}
	
	public static boolean contains(Component component, Port port) {
		return getAllPorts(component).contains(port);
	}
	
	public static EventDirection getOpposite(EventDirection eventDirection) {
		switch (eventDirection) {
			case IN:
				return EventDirection.OUT;
			case OUT:
				return EventDirection.IN;
			default:
				throw new IllegalArgumentException("Not known event direction: " + eventDirection);
		}
	}
	
	public static List<Expression> getTopComponentArguments(Package unfoldedPackage) {
		List<Expression> topComponentArguments = new ArrayList<Expression>();
		for (PackageAnnotation annotation : unfoldedPackage.getAnnotations()) {
			if (annotation instanceof TopComponentArgumentsAnnotation) {
				TopComponentArgumentsAnnotation argumentsAnnotation =
						(TopComponentArgumentsAnnotation) annotation;
				topComponentArguments.addAll(argumentsAnnotation.getArguments());
				return topComponentArguments; // There must be only one annotation
			}
		}
		return topComponentArguments;
	}
	
	public static boolean isUnfolded(Component component) {
		return isUnfolded(getContainingPackage(component));
	}
	
	public static boolean isUnfolded(Package gammaPackage) {
		return hasAnnotation(gammaPackage, UnfoldedPackageAnnotation.class);
	}
	
	public static boolean isWrapped(Package gammaPackage) {
		return hasAnnotation(gammaPackage, WrappedPackageAnnotation.class);
	}
	
	public static boolean hasAnnotation(Package gammaPackage,
			Class<? extends PackageAnnotation> annotation) {
		return gammaPackage.getAnnotations().stream().anyMatch(it -> annotation.isInstance(it));
	}
	
	public static Set<Package> getImportableInterfacePackages(Component component) {
		return getAllPorts(component).stream().map(it -> getContainingPackage(
				getInterface(it))).collect(Collectors.toSet());
	}
	
	public static Set<Package> getSelfAndImports(Package gammaPackage) {
		Set<Package> imports = new HashSet<Package>();
		imports.add(gammaPackage);
		imports.addAll(gammaPackage.getImports());
		return imports;
	}
	
	public static Set<Package> getAllImports(Package gammaPackage) {
		Set<Package> imports = new HashSet<Package>();
		imports.addAll(gammaPackage.getImports());
		for (Component component : gammaPackage.getComponents()) {
			for (ComponentInstance componentInstance : getAllInstances(component)) {
				Component type = getDerivedType(componentInstance);
				Package referencedPackage = getContainingPackage(type);
				imports.add(referencedPackage);
				imports.addAll(referencedPackage.getImports());
			}
		}
		return imports;
	}
	
	public static Component getFirstComponent(Package _package) {
		return _package.getComponents().get(0);
	}
	
	public static Set<Component> getAllComponents(Package parentPackage) {
		Set<Component> types = new HashSet<Component>();
		for (Package importedPackage : parentPackage.getImports()) {
			for (Component importedComponent : importedPackage.getComponents()) {
				types.add(importedComponent);
			}
		}
		for (Component siblingComponent : parentPackage.getComponents()) {
			types.add(siblingComponent);
		}
		return types;
	}
	
	public static Set<SynchronousComponent> getAllSynchronousComponents(Package parentPackage) {
		Set<SynchronousComponent> types = new HashSet<SynchronousComponent>();
		for (Component component : getAllComponents(parentPackage)) {
			if (component instanceof SynchronousComponent) {
				types.add((SynchronousComponent) component);
			}
		}
		return types;
	}
	
	public static Set<AsynchronousComponent> getAllAsynchronousComponents(Package parentPackage) {
		Set<AsynchronousComponent> types = new HashSet<AsynchronousComponent>();
		for (Component component : getAllComponents(parentPackage)) {
			if (component instanceof AsynchronousComponent) {
				types.add((AsynchronousComponent) component);
			}
		}
		return types;
	}
	
	public static Set<StatechartDefinition> getAllStatechartComponents(Package parentPackage) {
		Set<StatechartDefinition> types = new HashSet<StatechartDefinition>();
		for (Component component : getAllSynchronousComponents(parentPackage)) {
			if (component instanceof StatechartDefinition) {
				types.add((StatechartDefinition) component);
			}
		}
		return types;
	}
	
	public static boolean areInterfacesEqual(Component lhs, Component rhs) {
		List<Port> lhsPorts = lhs.getPorts();
		List<Port> rhsPorts = rhs.getPorts();
		if (lhsPorts.size() != rhsPorts.size()) {
			return false;
		}
		for (Port lhsPort : lhsPorts) {
			if (!rhsPorts.stream().anyMatch(it -> ecoreUtil.helperEquals(lhsPort, it))) {
				return false;
			}
		}
		return true;
	}
	
	public static List<ComponentInstance> getInstances(ComponentInstance instance) {
		Component type = getDerivedType(instance);
		return getInstances(type);
	}
	
	public static List<ComponentInstance> getInstances(Component component) {
		List<ComponentInstance> instances = new ArrayList<ComponentInstance>();
		if (component instanceof AbstractAsynchronousCompositeComponent) {
			AbstractAsynchronousCompositeComponent asynchronousCompositeComponent =
					(AbstractAsynchronousCompositeComponent) component;
			for (AsynchronousComponentInstance instance : asynchronousCompositeComponent.getComponents()) {
				instances.add(instance);
			}
		}
		else if (component instanceof AsynchronousAdapter) {
			AsynchronousAdapter asynchronousAdapter = (AsynchronousAdapter) component;
			SynchronousComponentInstance wrappedComponent = asynchronousAdapter.getWrappedComponent();
			instances.add(wrappedComponent);
		}
		else if (component instanceof AbstractSynchronousCompositeComponent) {
			AbstractSynchronousCompositeComponent synchronousCompositeComponent =
					(AbstractSynchronousCompositeComponent) component;
			for (SynchronousComponentInstance instance : synchronousCompositeComponent.getComponents()) {
				instances.add(instance);
			}
		}
		return instances;
	}
	
	public static List<ComponentInstance> getAllInstances(Component component) {
		List<ComponentInstance> instances = new ArrayList<ComponentInstance>();
		if (component instanceof AbstractAsynchronousCompositeComponent) {
			AbstractAsynchronousCompositeComponent asynchronousCompositeComponent =
					(AbstractAsynchronousCompositeComponent) component;
			for (AsynchronousComponentInstance instance : asynchronousCompositeComponent.getComponents()) {
				instances.add(instance);
				AsynchronousComponent type = instance.getType();
				instances.addAll(getAllInstances(type));
			}
		}
		else if (component instanceof AsynchronousAdapter) {
			AsynchronousAdapter asynchronousAdapter = (AsynchronousAdapter) component;
			SynchronousComponentInstance wrappedComponent = asynchronousAdapter.getWrappedComponent();
			instances.add(wrappedComponent);
			instances.addAll(getAllInstances(wrappedComponent.getType()));
		}
		else if (component instanceof AbstractSynchronousCompositeComponent) {
			AbstractSynchronousCompositeComponent synchronousCompositeComponent =
					(AbstractSynchronousCompositeComponent) component;
			for (SynchronousComponentInstance instance : synchronousCompositeComponent.getComponents()) {
				instances.add(instance);
				SynchronousComponent type = instance.getType();
				instances.addAll(getAllInstances(type));
			}
		}
		return instances;
	}
	
	public static List<SynchronousComponentInstance> getAllSimpleInstances(ComponentInstance instance) {
		Component type = getDerivedType(instance);
		return getAllSimpleInstances(type);
	}
	
	public static List<SynchronousComponentInstance> getAllSimpleInstances(Component component) {
		List<SynchronousComponentInstance> simpleInstances = new ArrayList<SynchronousComponentInstance>();
		if (component instanceof AbstractAsynchronousCompositeComponent) {
			AbstractAsynchronousCompositeComponent asynchronousCompositeComponent =
					(AbstractAsynchronousCompositeComponent) component;
			for (AsynchronousComponentInstance instance : asynchronousCompositeComponent.getComponents()) {
				simpleInstances.addAll(getAllSimpleInstances(instance));
			}
		}
		else if (component instanceof AsynchronousAdapter) {
			AsynchronousAdapter asynchronousAdapter = (AsynchronousAdapter) component;
			SynchronousComponentInstance wrappedInstance = asynchronousAdapter.getWrappedComponent();
			simpleInstances.addAll(getAllSimpleInstances(wrappedInstance));
		}
		else if (component instanceof AbstractSynchronousCompositeComponent) {
			AbstractSynchronousCompositeComponent synchronousCompositeComponent =
					(AbstractSynchronousCompositeComponent) component;
			for (SynchronousComponentInstance instance : synchronousCompositeComponent.getComponents()) {
				if (isStatechart(instance)) {
					simpleInstances.add(instance);
				}
				else {
					simpleInstances.addAll(getAllSimpleInstances(instance));
				}
			}
		}
		return simpleInstances;
	}
	
	public static List<AsynchronousComponentInstance> getAllAsynchronousSimpleInstances(Component component) {
		List<ComponentInstance> adapterInstances =
				getAllInstances(component).stream()
					.filter(it -> isAdapter(it))
					.collect(Collectors.toList());
		return javaUtil.filterIntoList(adapterInstances, AsynchronousComponentInstance.class);
	}
	
	public static List<ComponentInstanceReference> getAllSimpleInstanceReferences(
			ComponentInstance instance) {
		Component type = getDerivedType(instance);
		return getAllSimpleInstanceReferences(type);
	}
	
	public static List<ComponentInstanceReference> getAllSimpleInstanceReferences(Component component) {
		List<ComponentInstanceReference> instanceReferences = new ArrayList<ComponentInstanceReference>();
		if (component instanceof AbstractAsynchronousCompositeComponent) {
			AbstractAsynchronousCompositeComponent asynchronousCompositeComponent =
					(AbstractAsynchronousCompositeComponent) component;
			for (AsynchronousComponentInstance instance : asynchronousCompositeComponent.getComponents()) {
				List<ComponentInstanceReference> childReferences = getAllSimpleInstanceReferences(instance);
				instanceReferences.addAll(statechartUtil.prepend(childReferences, instance));
			}
		}
		else if (component instanceof AsynchronousAdapter) {
			AsynchronousAdapter adapter = (AsynchronousAdapter) component;
			SynchronousComponentInstance instance = adapter.getWrappedComponent();
			List<ComponentInstanceReference> childReferences = getAllSimpleInstanceReferences(instance);
			instanceReferences.addAll(statechartUtil.prepend(childReferences, instance));
		}
		else if (component instanceof AbstractSynchronousCompositeComponent) {
			AbstractSynchronousCompositeComponent synchronousCompositeComponent =
					(AbstractSynchronousCompositeComponent) component;
			for (SynchronousComponentInstance instance : synchronousCompositeComponent.getComponents()) {
				if (isStatechart(instance)) {
					ComponentInstanceReference instanceReference = statechartUtil.createInstanceReference(instance);
					instanceReferences.add(instanceReference);
				}
				else {
					List<ComponentInstanceReference> childReferences = getAllSimpleInstanceReferences(instance);
					instanceReferences.addAll(statechartUtil.prepend(childReferences, instance));
				}
			}
		}
		return instanceReferences;
	}
	
	public static Collection<StatechartDefinition> getAllContainedStatecharts(SynchronousComponent component) {
		List<StatechartDefinition> statecharts = new ArrayList<StatechartDefinition>();
		for (SynchronousComponentInstance instance : getAllSimpleInstances(component)) {
			statecharts.add(getStatechart(instance));
		}
		return statecharts;
	}
	
	public static List<EventDeclaration> getAllEventDeclarations(Interface _interface) {
		List<EventDeclaration> eventDeclarations = new ArrayList<EventDeclaration>(_interface.getEvents());
		for (Interface parentInterface : _interface.getParents()) {
			eventDeclarations.addAll(getAllEventDeclarations(parentInterface));
		}
		return eventDeclarations;
	}
	
	public static List<Event> getAllEvents(Interface _interface) {
		return getAllEventDeclarations(_interface).stream().map(it -> it.getEvent()).collect(Collectors.toList());
	}
	
	public static EventDirection getDirection(Event event) {
		EventDeclaration eventDeclaration = ecoreUtil.getContainerOfType(event, EventDeclaration.class);
		return eventDeclaration.getDirection();
	}
	
	public static BigInteger getPriorityValue(Event event) {
		BigInteger priority = event.getPriority();
		if (priority == null) {
			return BigInteger.ZERO;
		}
		return priority;
	}
	
	public static List<ParameterDeclaration> getParametersOfTypeDefinition(
			Event event, TypeDefinition type) {
		return event.getParameterDeclarations().stream()
			.filter(it -> getTypeDefinition(it) == type)
			.collect(Collectors.toList());
	}
	
	public static int getIndexOfParametersWithSameTypeDefinition(ParameterDeclaration parameter) {
		Event event = getContainingEvent(parameter);
		TypeDefinition typeDefinition = getTypeDefinition(parameter);
		List<ParameterDeclaration> parametersOfTypeDefinition =
				getParametersOfTypeDefinition(event, typeDefinition);
		return parametersOfTypeDefinition.indexOf(parameter);
	}
	
	public static Event getContainingEvent(ParameterDeclaration parameter) {
		return (Event) parameter.eContainer();
	}
	
	public static EventDeclaration getContainingEventDeclaration(Event event) {
		return (EventDeclaration) event.eContainer();
	}
	
	public static List<EventDeclaration> getAllEventDeclarations(Port port) {
		return getAllEventDeclarations(port.getInterfaceRealization().getInterface());
	}
	
	public static List<Event> getAllEvents(Port port) {
		return getAllEvents(port.getInterfaceRealization().getInterface());
	}
	
	public static List<Event> getInputEvents(Iterable<? extends Port> ports) {
		List<Event> events = new ArrayList<Event>();
		for (Port port : ports) {
			events.addAll(getInputEvents(port));
		}
		return events;
	}
	
	public static List<Event> getInputEvents(Port port) {
		List<Event> events = new ArrayList<Event>();
		InterfaceRealization interfaceRealization = port.getInterfaceRealization();
		Interface _interface = interfaceRealization.getInterface();
		final Collection<EventDeclaration> allEventDeclarations = getAllEventDeclarations(_interface);
		if (interfaceRealization.getRealizationMode() == RealizationMode.PROVIDED) {
			events.addAll(allEventDeclarations.stream()
					.filter(it -> it.getDirection() != EventDirection.OUT)
					.map(it -> it.getEvent())
					.collect(Collectors.toList()));
		}
		if (interfaceRealization.getRealizationMode() == RealizationMode.REQUIRED) {
			events.addAll(allEventDeclarations.stream()
					.filter(it -> it.getDirection() != EventDirection.IN)
					.map(it -> it.getEvent())
					.collect(Collectors.toList()));
		}
		return events;
	}
	
	public static List<Event> getOutputEvents(Iterable<? extends Port> ports) {
		List<Event> events = new ArrayList<Event>();
		for (Port port : ports) {
			events.addAll(getOutputEvents(port));
		}
		return events;
	}
	
	public static List<Event> getOutputEvents(Port port) {
		List<Event> events = new ArrayList<Event>();
		InterfaceRealization interfaceRealization = port.getInterfaceRealization();
		Interface _interface = interfaceRealization.getInterface();
		final Collection<EventDeclaration> allEventDeclarations = getAllEventDeclarations(_interface);
		if (interfaceRealization.getRealizationMode() == RealizationMode.PROVIDED) {
			events.addAll(allEventDeclarations.stream()
					.filter(it -> it.getDirection() != EventDirection.IN)
					.map(it -> it.getEvent())
					.collect(Collectors.toList()));
		}
		if (interfaceRealization.getRealizationMode() == RealizationMode.REQUIRED) {
			events.addAll(allEventDeclarations.stream()
					.filter(it -> it.getDirection() != EventDirection.OUT)
					.map(it -> it.getEvent())
					.collect(Collectors.toList()));
		}
		return events;
	}
	
	public static boolean isInputEvent(Port port, Event event) {
		return getInputEvents(port).contains(event);
	}
	
	public static boolean isOutputEvent(Port port, Event event) {
		return getOutputEvents(port).contains(event);
	}
	
	public static boolean isTopInPackage(Component component) {
		Package _package = getContainingPackage(component);
		for (Component containedComponent : _package.getComponents()) {
			for (ComponentInstance componentInstance : getInstances(containedComponent)) {
				Component type = getDerivedType(componentInstance);
				if (type == component) {
					return false;
				}
			}
		}
		return true;
	}
	
	public static Set<Interface> getInterfaces(Component component) {
		return getAllPorts(component).stream()
				.map(it -> getInterface(it)).collect(Collectors.toSet());
	}
	
	public static List<Port> getAllPorts(AsynchronousAdapter wrapper) {
		List<Port> allPorts = new ArrayList<Port>(wrapper.getPorts());
		allPorts.addAll(wrapper.getWrappedComponent().getType().getPorts());
		return allPorts;
	}
	
	public static List<Port> getAllPorts(Component component) {
		if (component instanceof AsynchronousAdapter) {
			return getAllPorts((AsynchronousAdapter) component);
		}		
		return component.getPorts();
	}
	
	public static boolean isControlSpecification(AsynchronousAdapter adapter, Entry<Port, Event> portEvent) {
		for (ControlSpecification controlSpecification : adapter.getControlSpecifications()) {
			SimpleTrigger trigger = controlSpecification.getTrigger();
			if (trigger instanceof AnyTrigger) {
				return true;
			}
			if (trigger instanceof EventTrigger) {
				EventTrigger eventTrigger = (EventTrigger) trigger;
				EventReference eventReference = eventTrigger.getEventReference();
				List<Entry<Port,Event>> inputEvents = getInputEvents(eventReference);
				if (inputEvents.contains(portEvent)) {
					return true;
				}
			}
		}
		return false;
	}
	
	public static List<MessageQueue> getFunctioningMessageQueues(AsynchronousAdapter adapter) {
		return adapter.getMessageQueues().stream()
				.filter(it -> isFunctioning(it)).collect(Collectors.toList());
	}
	
	public static List<Entry<Port, Event>> getStoredEvents(MessageQueue queue) {
		List<Entry<Port, Event>> events = new ArrayList<Entry<Port, Event>>();
		for (EventReference eventReference : queue.getEventReference()) {
			events.addAll(getInputEvents(eventReference));
		}
		return events;
	}
	
	public static int getEventId(MessageQueue queue,
			Entry<Port, Event> portEvent) {
		List<Entry<Port,Event>> storedEvents = getStoredEvents(queue);
		return storedEvents.indexOf(portEvent) + 1; // Starts from 1, 0 is the "empty cell"
	}
	
	public static Entry<Port, Event> getEvent(MessageQueue queue, int eventId) {
		List<Entry<Port,Event>> storedEvents = getStoredEvents(queue);
		return storedEvents.get(eventId - 1); // Starts from 1, 0 is the "empty cell"
	}
	
	public static boolean isStoredInMessageQueue(
			Entry<Port, Event> portEvent, MessageQueue queue) {
		List<Entry<Port,Event>> storedEvents = getStoredEvents(queue);
		return storedEvents.contains(portEvent);
	}
	
	public static int countAssignedMessageQueues(
			Entry<Port, Event> portEvent, AsynchronousAdapter adapter) {
		int count = 0;
		for (MessageQueue queue : adapter.getMessageQueues()) {
			if (isStoredInMessageQueue(portEvent, queue)) {
				++count;
			}
		}
		return count;
	}
	
	public static boolean isStoredInMessageQueue(
			Entry<Port, Event> portEvent, AsynchronousAdapter adapter) {
		return adapter.getMessageQueues().stream()
				.anyMatch(it -> isStoredInMessageQueue(portEvent, it));
	}
	
	public static boolean isStoredInMessageQueue(Clock clock, MessageQueue queue) {
		for (EventReference eventReference : queue.getEventReference()) {
			if (eventReference instanceof ClockTickReference) {
				ClockTickReference clockTickReference = (ClockTickReference) eventReference;
				if (clockTickReference.getClock() == clock) {
					return true;
				}
			}
		}
		return false;
	}
	
	public static boolean isStoredInMessageQueue(Clock clock, AsynchronousAdapter adapter) {
		return adapter.getMessageQueues().stream()
				.anyMatch(it -> isStoredInMessageQueue(clock, it));
	}
	
	public static boolean isEnvironmental(MessageQueue queue,
			Collection<? extends Port> systemPorts) {
		List<Port> topBoundPorts = getStoredEvents(queue).stream()
				.map(it -> getBoundTopComponentPort(it.getKey())).collect(Collectors.toList());
		return systemPorts.containsAll(topBoundPorts);
	}
	
	public static boolean isFunctioning(MessageQueue queue) {
		Expression capacity = queue.getCapacity();
		Expression messageRetrievalCount = queue.getMessageRetrievalCount();
		return evaluator.evaluateInteger(capacity) > 0 &&
				(messageRetrievalCount == null ||
						evaluator.evaluateInteger(messageRetrievalCount) > 0);
	}
	
	public static List<Entry<Port, Event>> getInputEvents(EventReference eventReference) {
		List<Entry<Port, Event>> events = new ArrayList<Entry<Port, Event>>();
		if (eventReference instanceof PortEventReference) {
			PortEventReference portEventReference = (PortEventReference) eventReference;
			Port port = portEventReference.getPort();
			Event event = portEventReference.getEvent();
			if (getInputEvents(port).contains(event)) {
				events.add(new SimpleEntry<Port, Event>(port, event));
			}
		}
		else if (eventReference instanceof AnyPortEventReference) {
			AnyPortEventReference anyPortEventReference = (AnyPortEventReference) eventReference;
			Port port = anyPortEventReference.getPort();
			for (Event inputEvent : getInputEvents(port)) {
				events.add(new SimpleEntry<Port, Event>(port, inputEvent));
			}
		}
		else if (eventReference instanceof ClockTickReference) {
			// No op
		}
		else {
			throw new IllegalArgumentException("Not supported event reference: " + eventReference);
		}
		return events;
	}
	
	public static List<Event> getInputEvents(Component component) {
		return getInputEvents(getAllPorts(component));
	}
	
	public static List<Event> getOutputEvents(Component component) {
		return getOutputEvents(getAllPorts(component));
	}
	
	public static Port getBoundCompositePort(Port port) {
		Package _package = getContainingPackage(port);
		List<PortBinding> portBindings = ecoreUtil.getAllContentsOfType(_package, PortBinding.class);
		for (PortBinding portBinding : portBindings) {
			InstancePortReference instancePortReference = portBinding.getInstancePortReference();
			if (instancePortReference.getPort() == port) {
				return portBinding.getCompositeSystemPort();
			}
		}
		return null;
	}
	
	public static Collection<PortBinding> getPortBindings(Port port) {
		EObject component = port.eContainer();
		List<PortBinding> portBindings = new ArrayList<PortBinding>();
		if (component instanceof CompositeComponent) {
			CompositeComponent compositeComponent = (CompositeComponent) component;
			for (PortBinding portBinding : compositeComponent.getPortBindings()) {
				if (portBinding.getCompositeSystemPort() == port) {
					portBindings.add(portBinding);
				}
			}
		}		
		return portBindings;
	}
	
	public static List<Port> getAllBoundSimplePorts(Component component) {
		List<Port> simplePorts = new ArrayList<Port>();
		for (Port port : getAllPorts(component)) {
			simplePorts.addAll(getAllBoundSimplePorts(port));
		}
		// Note that one port can be in the list multiple times iff the component is NOT unfolded
		return simplePorts;
	}
	
	public static List<Port> getAllBoundSimplePorts(Port port) {
		List<Port> simplePorts = new ArrayList<Port>();
		Component component = getContainingComponent(port);
		if (component instanceof StatechartDefinition) {
			simplePorts.add(port);
		}
		else if (component instanceof CompositeComponent) {
			CompositeComponent composite = (CompositeComponent) component;
			for (PortBinding portBinding : composite.getPortBindings()) {
				if (portBinding.getCompositeSystemPort() == port) {
					// Makes sense only if the containment hierarchy is a tree structure
					InstancePortReference instancePortReference = portBinding.getInstancePortReference();
					simplePorts.addAll(getAllBoundSimplePorts(
							instancePortReference.getPort()));
				}
			}
		}
		// Note that one port can be in the list multiple times iff the component is NOT unfolded
		return simplePorts;
	}
	
	public static List<Port> getAllBoundAsynchronousSimplePorts(AsynchronousComponent component) {
		List<Port> simplePorts = new ArrayList<Port>();
		for (Port port : getAllPorts(component)) {
			simplePorts.addAll(getAllBoundAsynchronousSimplePorts(port));
		}
		return simplePorts;
	}
	
	public static List<Port> getAllBoundAsynchronousSimplePorts(Port port) {
		List<Port> simplePorts = new ArrayList<Port>();
		Component component = getContainingComponent(port);
		if (component instanceof AbstractAsynchronousCompositeComponent) {
			CompositeComponent composite = (CompositeComponent) component;
			for (PortBinding portBinding : composite.getPortBindings()) {
				if (portBinding.getCompositeSystemPort() == port) {
					// Makes sense only if the containment hierarchy is a tree structure
					InstancePortReference instancePortReference = portBinding.getInstancePortReference();
					simplePorts.addAll(getAllBoundAsynchronousSimplePorts(
							instancePortReference.getPort()));
				}
			}
		}
		else if (component instanceof AsynchronousAdapter) {
			simplePorts.add(port);
		}
		else {
			// Makes sense only if the containment hierarchy is a tree structure
			ComponentInstance instance = getReferencingComponentInstance(component);
			Component containingComponent = getContainingComponent(instance);
			if (containingComponent instanceof AsynchronousAdapter) {
				simplePorts.add(port);
			}
		}
		// Note that one port can be in the list multiple times iff the component is NOT unfolded
		return simplePorts;
	}
	
	public static Port getBoundTopComponentPort(Port port) {
		Package _package = getContainingPackage(port);
		List<PortBinding> portBindings = ecoreUtil.getAllContentsOfType(_package, PortBinding.class);
		for (PortBinding portBinding : portBindings) {
			if (portBinding.getInstancePortReference().getPort() == port) {
				Port systemPort = portBinding.getCompositeSystemPort();
				// Correct as even broadcast ports cannot be bound to multiple system ports (would be unnecessary)
				return getBoundTopComponentPort(systemPort);
			}
		}
		return port;
	}
	
	public static List<Port> getPortsConnectedViaChannel(Port port) {
		Package _package = getContainingPackage(port);
		List<Channel> channels = ecoreUtil.getAllContentsOfType(_package, Channel.class);
		channels.addAll(ecoreUtil.getAllContentsOfType(_package, BroadcastChannel.class));
		for (Channel channel : channels) {
			Port providedPort = channel.getProvidedPort().getPort();
			List<Port> requiredPorts = getRequiredPorts(channel).stream()
					.map(it -> it.getPort()).collect(Collectors.toList());
			if (port == providedPort) {
				return requiredPorts;
			}
			if (requiredPorts.contains(port)) {
				return List.of(providedPort);
			}
		}
		return Collections.emptyList();
	}
	
	public static List<Port> getAllConnectedAsynchronousSimplePorts(Port port) {
		List<Port> portsConnectedViaChannel = new ArrayList<Port>();
		Port actualPort = port;
		while (actualPort != null /* Broadcast ports can go through multiple levels */) {
			portsConnectedViaChannel.addAll(getPortsConnectedViaChannel(actualPort));
			actualPort = getBoundCompositePort(actualPort);
		}
		List<Port> asynchronousSimplePorts = new ArrayList<Port>();
		for (Port portConnectedViaChannel : portsConnectedViaChannel) {
			asynchronousSimplePorts.addAll(
					getAllBoundAsynchronousSimplePorts(portConnectedViaChannel));
		}
		return asynchronousSimplePorts;
	}
	
	public static boolean isInChannel(Port port) {
		Package _package = getContainingPackage(port);
		List<Channel> channels = ecoreUtil.getAllContentsOfType(_package, Channel.class);
		channels.addAll(ecoreUtil.getAllContentsOfType(_package, BroadcastChannel.class));
		for (Channel channel : channels) {
			if (channel.getProvidedPort().getPort() == port ||
					getRequiredPorts(channel).stream().anyMatch(it -> it.getPort() == port)) {
				return true;
			}
		}
		List<PortBinding> portBindings = ecoreUtil.getAllContentsOfType(_package, PortBinding.class);
		for (PortBinding portBinding : portBindings) {
			if (portBinding.getInstancePortReference().getPort() == port) {
				Port systemPort = portBinding.getCompositeSystemPort();
				if (isInChannel(systemPort)) {
					return true;
				}
			}
		}
		return false;
	}
	
	public static List<InstancePortReference> getRequiredPorts(Channel channel) {
		if (channel instanceof SimpleChannel) {
			SimpleChannel simpleChannel = (SimpleChannel) channel;
			return Collections.singletonList(simpleChannel.getRequiredPort());
		}
		if (channel instanceof BroadcastChannel) {
			BroadcastChannel broadcastChannel = (BroadcastChannel) channel;
			return Collections.unmodifiableList(broadcastChannel.getRequiredPorts());
		}
		throw new IllegalArgumentException("Not known channel type: " + channel);
	}
	
	public static boolean equals(InstancePortReference p1, InstancePortReference p2) {
		return p1.getInstance() == p2.getInstance() && p1.getPort() == p2.getPort();
	}
	
	public static Set<Port> getUnusedPorts(ComponentInstance instance) {
		Component container = getContainingComponent(instance);
		Set<Port> usedPorts = ecoreUtil.getAllContentsOfType(container, InstancePortReference.class).stream()
				.filter(it -> it.getInstance() == instance).map(it -> it.getPort()).collect(Collectors.toSet());
		Set<Port> unusedPorts = new HashSet<Port>(getAllPorts(StatechartModelDerivedFeatures.getDerivedType(instance)));
		unusedPorts.removeAll(usedPorts);
		return unusedPorts;
	}
	
	public static EventSource getEventSource(EventReference eventReference) {
		if (eventReference instanceof PortEventReference) {
			PortEventReference portEventReference = (PortEventReference) eventReference;
			return portEventReference.getPort();
		}
		if (eventReference instanceof AnyPortEventReference) {
			AnyPortEventReference anyPortEventReference = (AnyPortEventReference) eventReference;
			return anyPortEventReference.getPort();
		}
		if (eventReference instanceof ClockTickReference) {
			ClockTickReference clockTickReference = (ClockTickReference) eventReference;
			return clockTickReference.getClock();
		}
		if (eventReference instanceof TimeoutEventReference) {
			TimeoutEventReference timeoutEventReference = (TimeoutEventReference) eventReference;
			return timeoutEventReference.getTimeout();
		}
		throw new IllegalArgumentException("Not known type: " + eventReference);
	}
	
	public static Component getDerivedType(ComponentInstance instance) {
		if (instance instanceof SynchronousComponentInstance) {
			SynchronousComponentInstance synchronousInstance = (SynchronousComponentInstance) instance;
			return synchronousInstance.getType();
		}
		if (instance instanceof AsynchronousComponentInstance) {
			AsynchronousComponentInstance asynchronousInstance = (AsynchronousComponentInstance) instance;
			return asynchronousInstance.getType();
		}
		throw new IllegalArgumentException("Not known type: " + instance);
	}
	
	public static List<? extends ComponentInstance> getDerivedComponents(CompositeComponent composite) {
		if (composite instanceof AbstractSynchronousCompositeComponent) {
			AbstractSynchronousCompositeComponent synchronousCompositeComponent =
					(AbstractSynchronousCompositeComponent) composite;
			return synchronousCompositeComponent.getComponents();
		}
		if (composite instanceof AbstractAsynchronousCompositeComponent) {
			AbstractAsynchronousCompositeComponent asynchronousCompositeComponent =
					(AbstractAsynchronousCompositeComponent) composite;
			return asynchronousCompositeComponent.getComponents();
		}
		throw new IllegalArgumentException("Not known type: " + composite);
	}
	
    public static boolean isTimed(Component component) {
    	if (component instanceof StatechartDefinition) {
    		StatechartDefinition statechart = (StatechartDefinition) component;
    		return statechart.getTimeoutDeclarations().size() > 0;
    	}
    	else if (component instanceof AbstractSynchronousCompositeComponent) {
    		AbstractSynchronousCompositeComponent composite = (AbstractSynchronousCompositeComponent) component;
    		return composite.getComponents().stream().anyMatch(it -> isTimed(it.getType()));
    	}
    	else if (component instanceof AsynchronousAdapter) {
    		// Clocks maybe?
    		AsynchronousAdapter adapter = (AsynchronousAdapter) component;
    		return isTimed(adapter.getWrappedComponent().getType());
    	}
    	else if (component instanceof AbstractAsynchronousCompositeComponent) {
    		AbstractAsynchronousCompositeComponent composite = (AbstractAsynchronousCompositeComponent) component;
    		return composite.getComponents().stream().anyMatch(it -> isTimed(it.getType()));
    	}
		throw new IllegalArgumentException("Not known component: " + component);
    }
	
    public static boolean isSynchronous(Component component) {
    	return component instanceof SynchronousComponent;
    }
    
    public static boolean isAsynchronous(Component component) {
    	return component instanceof AsynchronousComponent;
    }
    
    public static boolean isAdapter(Component component) {
    	return component instanceof AsynchronousAdapter;
    }
    
    public static boolean isStatechart(Component component) {
    	return component instanceof StatechartDefinition;
    }
	
    public static boolean isCascade(ComponentInstance instance) {
    	Component type = getDerivedType(instance);
		if (type instanceof StatechartDefinition) {
    		// Statecharts are cascade if contained by cascade composite components
    		return instance.eContainer() instanceof CascadeCompositeComponent;
   		}
   		return type instanceof CascadeCompositeComponent;
    }
    
    public static boolean isSynchronous(ComponentInstance instance) {
    	return isSynchronous(getDerivedType(instance));
    }
    
    public static boolean isAsynchronous(ComponentInstance instance) {
    	return isAsynchronous(getDerivedType(instance));
    }
    
    public static boolean isAdapter(ComponentInstance instance) {
    	return isAdapter(getDerivedType(instance));
    }
    
    public static boolean isStatechart(ComponentInstance instance) {
    	return isStatechart(getDerivedType(instance));
    }
    
    public static StatechartDefinition getStatechart(ComponentInstance instance) {
    	return (StatechartDefinition) getDerivedType(instance);
    }
	
	public static int getLevel(StateNode stateNode) {
		if (isTopRegion(getParentRegion(stateNode))) {
			return 1;
		}
		else {
			return getLevel(getParentState(stateNode)) + 1;
		}
	}
	
	public static List<Transition> getOutgoingTransitions(StateNode node) {
		StatechartDefinition statechart = getContainingStatechart(node);
		return statechart.getTransitions().stream().filter(it -> it.getSourceState() == node)
				.collect(Collectors.toList());
	}
	
	public static List<Transition> getIncomingTransitions(StateNode node) {
		StatechartDefinition statechart = getContainingStatechart(node);
		return statechart.getTransitions().stream().filter(it -> it.getTargetState() == node)
				.collect(Collectors.toList());
	}
	
	public static Collection<StateNode> getAllStateNodes(CompositeElement compositeElement) {
		Set<StateNode> stateNodes = new HashSet<StateNode>();
		for (Region region : compositeElement.getRegions()) {
			for (StateNode stateNode : region.getStateNodes()) {
				stateNodes.add(stateNode);
				if (stateNode instanceof State) {
					State state = (State) stateNode;
					stateNodes.addAll(getAllStateNodes(state));
				}
			}
		}
		return stateNodes;
	}
	
	public static Collection<State> getAllStates(CompositeElement compositeElement) {
		Set<State> states = new HashSet<State>();
		for (StateNode stateNode : getAllStateNodes(compositeElement)) {
			if (stateNode instanceof State) {
				State state = (State) stateNode;
				states.add(state);
			}
		}
		return states;
	}
	
	public static List<State> getStates(Region region) {
		List<State> states = new ArrayList<State>();
		for (StateNode stateNode : region.getStateNodes()) {
			if (stateNode instanceof State) {
				State state = (State) stateNode;
				states.add(state);
			}
		}
		return states;
	}
	
	public static List<PseudoState> getPseudoStates(Region region) {
		List<PseudoState> pseudoStates = new ArrayList<PseudoState>();
		for (StateNode stateNode : region.getStateNodes()) {
			if (stateNode instanceof PseudoState) {
				PseudoState pseudoState = (PseudoState) stateNode;
				pseudoStates.add(pseudoState);
			}
		}
		return pseudoStates;
	}
	
	public static Collection<StateNode> getAllStateNodes(Region region) {
		List<StateNode> states = new ArrayList<StateNode>();
		TreeIterator<Object> allContents = EcoreUtil.getAllContents(region, true);
		while (allContents.hasNext()) {
			Object next = allContents.next();
			if (next instanceof StateNode) {
				states.add((StateNode) next);
			}
		}
		return states;
	}
	
	public static Collection<Region> getAllRegions(CompositeElement compositeElement) {
		Set<Region> regions = new HashSet<Region>(compositeElement.getRegions());
		for (State state : getAllStates(compositeElement)) {
			regions.addAll(getAllRegions(state));
		}
		return regions;
	}
	
	public static Collection<Region> getAllRegions(Region region) {
		Set<Region> regions = new HashSet<Region>();
		regions.add(region);
		TreeIterator<Object> allContents = EcoreUtil.getAllContents(region, true);
		while (allContents.hasNext()) {
			Object next = allContents.next();
			if (next instanceof Region) {
				regions.add((Region) next);
			}
		}
		return regions;
	}
	
	public static State getParentState(StateAnnotation annotation) {
		return (State) annotation.eContainer();
	}
	
	public static Region getParentRegion(StateNode node) {
		return (Region) node.eContainer();
	}
	
	public static boolean isTopRegion(Region region) {
		return getContainingCompositeElement(region) instanceof StatechartDefinition;
	}
	
	public static boolean isSubregion(Region region) {
		return !isTopRegion(region);
	}
	
	public static boolean isOrthogonal(Region region) {
		CompositeElement compositeElement = getContainingCompositeElement(region);
		return compositeElement.getRegions().size() >= 2;
	}
	
	public static CompositeElement getContainingCompositeElement(Region region) {
		return (CompositeElement) region.eContainer();
	}

	public static State getParentState(Region region) {
		if (isTopRegion(region)) {
			throw new IllegalArgumentException("This region has no parent state: " + region);
		}
		return (State) getContainingCompositeElement(region);
	}
	
	public static State getParentState(StateNode node) {
		Region parentRegion = getParentRegion(node);
		return getParentState(parentRegion);
	}
	
	public static Region getParentRegion(Region region) {
		if (isTopRegion(region)) {
			return null;
		}
		return getParentRegion((State) getContainingCompositeElement(region));
	}
	
	public static List<Region> getParentRegions(Region region) {
		if (isTopRegion(region)) {
			return new ArrayList<Region>();
		}
		Region parentRegion = getParentRegion(region);
		List<Region> parentRegions = new ArrayList<Region>();
		parentRegions.add(parentRegion);
		parentRegions.addAll(getParentRegions(parentRegion));
		return parentRegions;
	}
	
	public static List<Region> getSubregions(Region region) {
		List<Region> subregions = new ArrayList<Region>();
		for (List<Region> stateSubregions : getStates(region).stream().map(it -> it.getRegions())
				.collect(Collectors.toList())) {
			for (Region subregion : stateSubregions) {
				subregions.add(subregion);
				subregions.addAll(getSubregions(subregion));
			}
		}
		return subregions;
	}
	
	public static List<hu.bme.mit.gamma.statechart.statechart.State> getCommonAncestors(
			StateNode lhs, StateNode rhs) {
		List<hu.bme.mit.gamma.statechart.statechart.State> ancestors = getAncestors(lhs);
		ancestors.retainAll(getAncestors(rhs));
		return ancestors;
	}
	
	public static List<hu.bme.mit.gamma.statechart.statechart.State> getAncestors(StateNode node) {
		if (node.eContainer().eContainer() instanceof hu.bme.mit.gamma.statechart.statechart.State) {
			hu.bme.mit.gamma.statechart.statechart.State parentState = getParentState(node);
			List<hu.bme.mit.gamma.statechart.statechart.State> ancestors = getAncestors(parentState);
			ancestors.add(parentState);
			return ancestors;
		}
		return new ArrayList<hu.bme.mit.gamma.statechart.statechart.State>();
	}
	
	public static List<hu.bme.mit.gamma.statechart.statechart.State> getAncestorsAndSelf(State node) {
		List<hu.bme.mit.gamma.statechart.statechart.State> ancestors = getAncestors(node);
		ancestors.add(node);
		return ancestors;
	}
	
	public static List<Region> getRegionAncestors(StateNode node) {
		if (node.eContainer().eContainer() instanceof hu.bme.mit.gamma.statechart.statechart.State) {
			hu.bme.mit.gamma.statechart.statechart.State parentState = getParentState(node);
			List<Region> ancestors = getRegionAncestors(parentState);
			ancestors.add(getParentRegion(node));
			return ancestors;
		}
		Region parentRegion = (Region) node.eContainer();
		List<Region> regionList = new ArrayList<Region>();
		regionList.add(parentRegion);
		return regionList;
	}
	
	public static List<Region> getCommonRegionAncestors(StateNode lhs, StateNode rhs) {
		List<Region> ancestors = getRegionAncestors(lhs);
		ancestors.retainAll(getRegionAncestors(rhs));
		return ancestors;
	}
	
	/**
	 * Returns whether the given region has deep history in one of its ancestor regions.
	 */
	private static boolean hasDeepHistoryAbove(Region region) {
		if (isTopRegion(region)) {
			return false;
		}
		Region parentRegion = getParentRegion(region);
		return parentRegion.getStateNodes().stream().anyMatch(it -> it instanceof DeepHistoryState) ||
			hasDeepHistoryAbove(parentRegion);
	}
	
	/**
	 * Returns whether the region has history or not.
	 */
	public static boolean hasHistory(Region region) {
		return hasDeepHistoryAbove(region) || 
			region.getStateNodes().stream().anyMatch(it -> it instanceof ShallowHistoryState) || 
			region.getStateNodes().stream().anyMatch(it -> it instanceof DeepHistoryState);
	}	
	
	public static String getFullContainmentHierarchy(State state) {
		if (state == null) {
			return "";
		}
		Region parentRegion = getParentRegion(state);
		State parentState = null;
		if (parentRegion.eContainer() instanceof State) {
			parentState = getParentState(parentRegion);
		}
		String parentRegionName = parentRegion.getName();
		if (parentState == null) {
			// Yakindu bug? First character is set to lowercase in the case of top regions
			parentRegionName = parentRegionName.substring(0, 1).toLowerCase() + parentRegionName.substring(1); // toFirstLowerCase
			return parentRegionName + "_" + state.getName();
		}
		return getFullContainmentHierarchy(parentState) + "_" + parentRegionName + "_" + state.getName();
	}
	
	public static String getFullRegionPathName(Region lowestRegion) {
		if (!(lowestRegion.eContainer() instanceof State)) {
			return lowestRegion.getName();
		}
		String fullParentRegionPathName = getFullRegionPathName(getParentRegion(lowestRegion));
		return fullParentRegionPathName + "." + lowestRegion.getName(); // Only regions are in path - states could be added too
	}
	
	public static StatechartDefinition getContainingStatechart(EObject object) {
		if (object.eContainer() instanceof StatechartDefinition) {
			return (StatechartDefinition) object.eContainer();
		}
		return getContainingStatechart(object.eContainer());
	}
	
	public static Component getContainingComponent(EObject object) {
		if (object.eContainer() == null) {
			throw new IllegalArgumentException("Not contained by a component: " + object);
		}
		if (object instanceof Component) {
			return (Component) object;
		}
		return getContainingComponent(object.eContainer());
	}
	
	public static Package getContainingPackage(EObject object) {
		if (object instanceof Package) {
			return (Package) object;
		}
//		if (object.eContainer() == null) {
//			throw new IllegalArgumentException("Not contained by a package: " + object);
//		}
		return getContainingPackage(object.eContainer());
	}
	
	public static boolean hasSamePortEvent(RaiseEventAction lhs, RaiseEventAction rhs) {
		return lhs.getPort() == rhs.getPort() && lhs.getEvent() == rhs.getEvent();
	}
	
	public static TransitionIdAnnotation getIdAnnotation(Transition transition) {
		for (TransitionAnnotation annotation : transition.getAnnotations()) {
			if (annotation instanceof TransitionIdAnnotation) {
				return (TransitionIdAnnotation) annotation;
			}
		}
		return null;
	}
	
	public static String getId(Transition transition) {
		TransitionIdAnnotation idAnnotation = getIdAnnotation(transition);
		if (idAnnotation == null) {
			return null;
		}
		return idAnnotation.getName();
	}
	
	public static Collection<PortEventReference> getPortEventReferences(Transition transition) {
		return ecoreUtil.getAllContentsOfType(transition.getTrigger(),
				PortEventReference.class);
	}
	
	public static Collection<PortEventReference> getPortEventReferences(
			Collection<Transition> transitions) {
		Set<PortEventReference> portEventReferenes = new HashSet<PortEventReference>();
		for (Transition transition : transitions) {
			portEventReferenes.addAll(getPortEventReferences(transition));
		}
		return portEventReferenes;
	}
	
	public static Collection<Transition> getSelfAndPrecedingTransitions(Transition transition) {
		StateNode source = transition.getSourceState();
		Set<Transition> transitions = new HashSet<Transition>();
		transitions.add(transition);
		if (!(source instanceof State)) {
			for (Transition incomingTransition : getIncomingTransitions(source)) {
				transitions.addAll(getSelfAndPrecedingTransitions(incomingTransition));
			}
		}
		return transitions;
	}
	
	public static Collection<Transition> getPrioritizedTransitions(Transition gammaTransition) {
		StatechartDefinition gammaStatechart = getContainingStatechart(gammaTransition);
		TransitionPriority transitionPriority = gammaStatechart.getTransitionPriority();
		Collection<Transition> prioritizedTransitions = new ArrayList<Transition>();
		if (transitionPriority != TransitionPriority.OFF) {
			StateNode source = gammaTransition.getSourceState();
			List<Transition> gammaOutgoingTransitions = getOutgoingTransitions(source);
			for (Transition gammaOutgoingTransition : gammaOutgoingTransitions) {
				if (calculatePriority(gammaTransition).longValue() <
						calculatePriority(gammaOutgoingTransition).longValue()) {
					prioritizedTransitions.add(gammaOutgoingTransition);
				}
			}
		}
		return prioritizedTransitions;
	}
	
	public static BigInteger calculatePriority(Transition transition) {
		StatechartDefinition statechart = getContainingStatechart(transition);
		TransitionPriority transitionPriority = statechart.getTransitionPriority();
		StateNode source = transition.getSourceState();
		List<Transition> outgoingTransitions = getOutgoingTransitions(source);
		// If it is an else transition, its priority is always the lowest
		Expression guard = transition.getGuard();
		if (isElseOrDefault(guard)) {
			BigInteger min = outgoingTransitions.stream()
				.filter(it -> !isElseOrDefault(it.getGuard()))
				.map(it -> calculatePriority(it)) // There must not be multiple else guards
				.min((lhs, rhs) -> lhs.compareTo(rhs))
				.orElse(BigInteger.ONE);
			return min.subtract(BigInteger.ONE); // Min - 1
		}
		// Normal transition
		switch (transitionPriority) {
			case ORDER_BASED : {
				int size = outgoingTransitions.size();
				int index = outgoingTransitions.indexOf(transition);
				int priority = size - index;
				return BigInteger.valueOf(priority);
			}
			case VALUE_BASED : {
				return transition.getPriority();
			}
			case OFF : { // Default value is 0
				return transition.getPriority();
			}
			default: {
				throw new IllegalArgumentException("Not supported literal: " + transitionPriority);
			}
		}
	}
	
	public static boolean isSameRegion(Transition transition) {
		return getParentRegion(transition.getSourceState()) == getParentRegion(transition.getTargetState());
	}
	
	public static boolean isToHigher(Transition transition) {
		return isToHigher(transition.getSourceState(), transition.getTargetState());
	}
	
	public static boolean isToHigher(StateNode source, StateNode target) {
		Region sourceParentRegion = getParentRegion(source);
		if (isTopRegion(sourceParentRegion)) {
			return false;
		}
		State sourceParentState = getParentState(source);
		if (getParentRegion(sourceParentState) == getParentRegion(target)) {
			return true;
		}
		return isToHigher(sourceParentState, target);
	}
	
	public static boolean isToLower(Transition transition) {
		return isToLower(transition.getSourceState(), transition.getTargetState());
	}
	
	public static boolean isToLower(StateNode source, StateNode target) {
		Region targetParentRegion = getParentRegion(target);
		if (isTopRegion(targetParentRegion)) {
			return false;
		}
		State targetParentState = getParentState(target);
		if (getParentRegion(source) == getParentRegion(targetParentState)) {
			return true;
		}
		return isToLower(source, targetParentState);
	}
	
	public static boolean isToHigherAndLower(Transition transition) {
		return isToHigherAndLower(transition.getSourceState(), transition.getTargetState());
	}
	
	public static boolean isToHigherAndLower(StateNode source, StateNode target) {
		List<Region> sourceAncestors = getRegionAncestors(source);
		List<Region> targetAncestors = getRegionAncestors(target);
		List<Region> commonAncestors = new ArrayList<Region>(sourceAncestors);
		commonAncestors.retainAll(targetAncestors);
		if (commonAncestors.isEmpty()) {
			// Top region orthogonal invalid transitions
			return false;
		}
		sourceAncestors.removeAll(commonAncestors);
		if (sourceAncestors.isEmpty()) {
			// To lower level
			return false;
		}
		targetAncestors.removeAll(commonAncestors);
		if (targetAncestors.isEmpty()) {
			// To higher level
			return false;
		}
		return true;
	}
	
	public static boolean hasTrigger(Transition transition) {
		return transition.getTrigger() != null;
	}
	
	public static boolean needsTrigger(Transition transition) {
		StateNode source = transition.getSourceState();
		return !(source instanceof EntryState || source instanceof ChoiceState ||
				source instanceof MergeState || source instanceof ForkState ||
				source instanceof JoinState);
	}
	
	public static boolean hasGuard(Transition transition) {
		return transition.getGuard() != null;
	}
	
	public static boolean isEmpty(Transition transition) {
		return !hasTrigger(transition) && !hasGuard(transition) &&
			transition.getEffects().isEmpty();
	}
	
	public static boolean isElse(Transition transition) {
		return transition.getGuard() instanceof ElseExpression;
	}
	
	public static boolean isLoop(Transition transition) {
		return transition.getSourceState() == transition.getTargetState();
	}
	
	public static StateNode getSourceAncestor(Transition transition) {
		return getSourceAncestor(transition.getSourceState(), transition.getTargetState());
	}
	
	public static StateNode getSourceAncestor(StateNode source, StateNode target) {
		if (isToLower(source, target)) {
			return source;
		}
		Region sourceParentRegion = getParentRegion(source);
		if (isTopRegion(sourceParentRegion)) {
			throw new IllegalArgumentException("No source ancestor!");
		}
		State sourceParentState = getParentState(source);
		return getSourceAncestor(sourceParentState, target);
	}
	
	public static StateNode getTargetAncestor(Transition transition) {
		return getTargetAncestor(transition.getSourceState(), transition.getTargetState());
	}
	
	public static StateNode getTargetAncestor(StateNode source, StateNode target) {
		if (isToHigher(source, target)) {
			return source;
		}
		Region targetParentRegion = getParentRegion(target);
		if (isTopRegion(targetParentRegion)) {
			throw new IllegalArgumentException("No target ancestor!");
		}
		State targetParentState = getParentState(target);
		return getTargetAncestor(source, targetParentState);
	}
	
	public static boolean isComposite(StateNode node) {
		if (node instanceof State) {
			return isComposite((State) node);
		}
		return false;
	}
	
	public static boolean isComposite(State state) {
		return !state.getRegions().isEmpty();
	}
	
	public static EObject getContainingTransitionOrState(EObject object) {
		Transition containingTransition = ecoreUtil.getContainerOfType(
				object, Transition.class);
		if (containingTransition != null) {
			// Container is a transition
			return containingTransition;
		}
		// Container is a state
		return ecoreUtil.getContainerOfType(object, State.class);
	}
	
	public static StateNode getContainingOrSourceStateNode(EObject object) {
		EObject container = getContainingTransitionOrState(object);
		if (container instanceof Transition) {
			Transition transition = (Transition) container;
			return transition.getSourceState();
		}
		return (StateNode) container;
	}
	
	public static List<Action> getContainingActionList(EObject object) {
		EObject container = object.eContainer();
		if (container instanceof Transition) {
			Transition transition = (Transition) container;
			return transition.getEffects();
		}
		if (container instanceof State) {
			State state = (State) container;
			if (state.getEntryActions().contains(object)) {
				return state.getEntryActions();
			}
			if (state.getExitActions().contains(object)) {
				return state.getExitActions();
			}
		}
		// Nullptr if the object is not contained by any of the above
		return getContainingActionList(container);
	}
	
	public static int getLiteralIndex(State state) {
		Region parent = getParentRegion(state);
		List<State> states = getStates(parent);
		return states.indexOf(state) + 1 /* + 1 for __Inactive */;
	}
	
	public static EntryState getEntryState(Region region) {
		Collection<StateNode> entryStates = region.getStateNodes().stream()
				.filter(it -> it instanceof EntryState)
				.collect(Collectors.toList());
		Optional<StateNode> entryState = entryStates.stream().filter(it -> it instanceof InitialState).findFirst();
		if (entryState.isPresent()) {
			return (EntryState) entryState.get();
		}
		entryState = entryStates.stream().filter(it -> it instanceof DeepHistoryState).findFirst();
		if (entryState.isPresent()) {
			return (EntryState) entryState.get();
		}
		entryState = entryStates.stream().filter(it -> it instanceof ShallowHistoryState).findFirst();
		if (entryState.isPresent()) {
			return (EntryState) entryState.get();
		}
		throw new IllegalArgumentException("Not known initial states in the region. " + region.getName() + ": " + entryStates);
	}
	
	public static Transition getInitialTransition(Region region) {
		EntryState entryState = getEntryState(region);
		List<Transition> outgoingTransitions = getOutgoingTransitions(entryState);
		if (outgoingTransitions.size() != 1) {
			throw new IllegalArgumentException(outgoingTransitions.toString());
		}
		return outgoingTransitions.get(0);
	}
	
	public static Set<State> getPrecedingStates(StateNode node) {
		Set<State> precedingStates = new HashSet<State>();
		for (Transition incomingTransition : getIncomingTransitions(node)) {
			StateNode source = incomingTransition.getSourceState();
			if (source instanceof State) {
				precedingStates.add((State) source);
			}
			else {
				precedingStates.addAll(getReachableStates(source));
			}
		}
		return precedingStates;
	}
	
	public static Set<State> getReachableStates(StateNode node) {
		Set<State> reachableStates = new HashSet<State>();
		for (Transition outgoingTransition : getOutgoingTransitions(node)) {
			StateNode target = outgoingTransition.getTargetState();
			if (target instanceof State) {
				reachableStates.add((State) target);
			}
			else {
				reachableStates.addAll(getReachableStates(target));
			}
		}
		return reachableStates;
	}
	
	public static TimeSpecification getTimeoutValue(TimeoutDeclaration timeout) {
		StatechartDefinition statechart = getContainingStatechart(timeout);
		TimeSpecification time = null;
		TreeIterator<Object> contents = EcoreUtil.getAllContents(statechart, true);
		while (contents.hasNext()) {
			Object it = contents.next();
			if (it instanceof SetTimeoutAction) {
				SetTimeoutAction action = (SetTimeoutAction) it;
				if (action.getTimeoutDeclaration() == timeout) {
					if (time == null) {
						time = action.getTime();
					}
					else {
						throw new IllegalStateException("This timeout is assigned a value more than once: " + timeout);
					}
				}
			}
		}
		return time;
	}
	
	public static Component getMonitoredComponent(StatechartDefinition adaptiveContract) {
		List<StatechartAnnotation> annotations = adaptiveContract.getAnnotations();
		for (StatechartAnnotation annotation: annotations) { 
			if (annotation instanceof AdaptiveContractAnnotation) {
				AdaptiveContractAnnotation adaptiveContractAnnotation = (AdaptiveContractAnnotation) annotation;
				return adaptiveContractAnnotation.getMonitoredComponent();
			}
		}
		throw new IllegalArgumentException("Not an adaptive contract statechart: " + adaptiveContract);
	}
	
	public static Collection<ComponentInstance> getReferencingComponentInstances(Component component) {
		Package _package = getContainingPackage(component);
		Collection<ComponentInstance> componentInstances = new HashSet<ComponentInstance>();
		for (Component siblingComponent : _package.getComponents()) {
			if (siblingComponent instanceof CompositeComponent) {
				CompositeComponent compositeComponent = (CompositeComponent) siblingComponent;
				for (ComponentInstance componentInstance : getDerivedComponents(compositeComponent)) {
					if (getDerivedType(componentInstance) == component) {
						componentInstances.add(componentInstance);
					}
				}
			}
			if (siblingComponent instanceof AsynchronousAdapter) {
				AsynchronousAdapter asynchronousAdapter = (AsynchronousAdapter) siblingComponent;
				SynchronousComponentInstance componentInstance = asynchronousAdapter.getWrappedComponent();
				if (componentInstance.getType() == component) {
					componentInstances.add(componentInstance);
				}
			}
		}
		return componentInstances;
	}
	
	public static ComponentInstance getReferencingComponentInstance(Component component) {
		Collection<ComponentInstance> instances = getReferencingComponentInstances(component);
		if (instances.size() != 1) {
			throw new IllegalArgumentException("Not one referencing instance: " + instances);
		}
		return instances.stream().findFirst().get();
	}
	
	public static ComponentInstance getContainingComponentInstance(EObject object) {
		StatechartDefinition statechart = getContainingStatechart(object);
		return getReferencingComponentInstance(statechart);
	}
	
	public static List<ComponentInstance> getParentComponentInstances(ComponentInstance instance) {
		Component container = ecoreUtil.getContainerOfType(instance, Component.class);
		try {
			ComponentInstance referencingComponentInstance = getReferencingComponentInstance(container);
			List<ComponentInstance> parentComponentInstances = getParentComponentInstances(referencingComponentInstance);
			parentComponentInstances.add(referencingComponentInstance);
			return parentComponentInstances;
		} catch (IllegalArgumentException e) {
			// Top component
			return new ArrayList<ComponentInstance>();
		}
	}
	
	public static List<ComponentInstance> getWraplessComponentInstanceChain(ComponentInstance instance) {
		List<ComponentInstance> componentInstanceChain = getComponentInstanceChain(instance);
		Package _package = getContainingPackage(instance);
		if (isWrapped(_package)) {
			componentInstanceChain.remove(0); // Removing the wrapper instance
		}
		return componentInstanceChain;
	}
	
	public static List<ComponentInstance> getComponentInstanceChain(ComponentInstance instance) {
		List<ComponentInstance> parentComponentInstances = getParentComponentInstances(instance);
		parentComponentInstances.add(instance);
		return parentComponentInstances;
	}
	
	public static List<ComponentInstance> getComponentInstanceChain(
			ComponentInstanceReference reference) {
		ComponentInstance instance = reference.getComponentInstance();
		ComponentInstanceReference child = reference.getChild();
		if (child == null) {
			List<ComponentInstance> instanceList = new ArrayList<ComponentInstance>();
			instanceList.add(instance);
			return instanceList;
		}
		else {
			List<ComponentInstance> children = getComponentInstanceChain(child);
			children.add(0, instance); // See above: mutable list is returned
			return children;
		}
	}
	
	public static ComponentInstanceReference getParent(ComponentInstanceReference reference) {
		return ecoreUtil.getContainerOfType(reference, ComponentInstanceReference.class);
	}
	
	public static ComponentInstanceReference getFirstInstance(ComponentInstanceReference reference) {
		ComponentInstanceReference parent = getParent(reference);
		if (parent == null) {
			return reference;
		}
		return getFirstInstance(parent);
	}
	
	public static ComponentInstance getLastInstance(ComponentInstanceReference reference) {
		ComponentInstanceReference child = reference.getChild();
		if (child == null) {
			return reference.getComponentInstance();
		}
		return getLastInstance(child);
	}
	
	public static boolean isFirst(ComponentInstanceReference reference) {
		return getParent(reference) == null;
	}
	
	public static boolean isLast(ComponentInstanceReference reference) {
		return reference.getChild() == null;
	}
	
	public static boolean isAtomic(ComponentInstanceReference reference) {
		return isFirst(reference) && isLast(reference);
	}
	
	public static boolean contains(ComponentInstance potentialContainer, ComponentInstance instance) {
		List<ComponentInstance> instances = getInstances(potentialContainer);
		return instances.contains(instance);
	}
	
	public static List<SynchronousComponentInstance> getScheduledInstances(
			AbstractSynchronousCompositeComponent component) {
		if (component instanceof CascadeCompositeComponent) {
			CascadeCompositeComponent cascade = (CascadeCompositeComponent) component;
			List<ComponentInstanceReference> executionList = cascade.getExecutionList();
			if (!executionList.isEmpty()) {
				List<SynchronousComponentInstance> instances =
						new ArrayList<SynchronousComponentInstance>();
				for (ComponentInstanceReference instanceReference : executionList) {
					SynchronousComponentInstance componentInstance =
						(SynchronousComponentInstance) instanceReference.getComponentInstance();
					instances.add(componentInstance);
				}
				return instances;
			}
		}
		return component.getComponents();
	}
	
	public static List<AsynchronousComponentInstance> getScheduledInstances(
			AbstractAsynchronousCompositeComponent component) {
		if (component instanceof ScheduledAsynchronousCompositeComponent) {
			ScheduledAsynchronousCompositeComponent scheduledComponent =
					(ScheduledAsynchronousCompositeComponent) component;
			List<ComponentInstanceReference> executionList = scheduledComponent.getExecutionList();
			if (!executionList.isEmpty()) {
				List<AsynchronousComponentInstance> instances =
						new ArrayList<AsynchronousComponentInstance>();
				for (ComponentInstanceReference instanceReference : executionList) {
					AsynchronousComponentInstance componentInstance =
						(AsynchronousComponentInstance) instanceReference.getComponentInstance();
					instances.add(componentInstance);
				}
				return instances;
			}
		}
		return component.getComponents();
	}
	
	public static List<AsynchronousComponentInstance> getAllScheduledAsynchronousSimpleInstances(
			AbstractAsynchronousCompositeComponent component) {
		List<AsynchronousComponentInstance> simpleInstances =
				new ArrayList<AsynchronousComponentInstance>();
		for (AsynchronousComponentInstance instance : getScheduledInstances(component)) {
			if (isAdapter(instance)) {
				simpleInstances.add(instance);
			}
			else {
				AbstractAsynchronousCompositeComponent type =
						(AbstractAsynchronousCompositeComponent) instance.getType();
				simpleInstances.addAll(
						getAllScheduledAsynchronousSimpleInstances(type));
			}
		}
		return simpleInstances;
	}

}