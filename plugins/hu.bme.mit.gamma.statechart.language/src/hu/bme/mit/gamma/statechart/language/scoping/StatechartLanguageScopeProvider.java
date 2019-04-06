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
package hu.bme.mit.gamma.statechart.language.scoping;

import static com.google.common.base.Preconditions.checkState;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EReference;
import org.eclipse.xtext.EcoreUtil2;
import org.eclipse.xtext.scoping.IScope;
import org.eclipse.xtext.scoping.Scopes;

import hu.bme.mit.gamma.constraint.model.ConstraintModelPackage;
import hu.bme.mit.gamma.constraint.model.Declaration;
import hu.bme.mit.gamma.constraint.model.EnumerationLiteralDefinition;
import hu.bme.mit.gamma.constraint.model.EnumerationLiteralExpression;
import hu.bme.mit.gamma.statechart.model.AnyPortEventReference;
import hu.bme.mit.gamma.statechart.model.Component;
import hu.bme.mit.gamma.statechart.model.InterfaceRealization;
import hu.bme.mit.gamma.statechart.model.Package;
import hu.bme.mit.gamma.statechart.model.Port;
import hu.bme.mit.gamma.statechart.model.PortEventReference;
import hu.bme.mit.gamma.statechart.model.RaiseEventAction;
import hu.bme.mit.gamma.statechart.model.RealizationMode;
import hu.bme.mit.gamma.statechart.model.Region;
import hu.bme.mit.gamma.statechart.model.StateNode;
import hu.bme.mit.gamma.statechart.model.StatechartDefinition;
import hu.bme.mit.gamma.statechart.model.StatechartModelPackage;
import hu.bme.mit.gamma.statechart.model.Transition;
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousAdapter;
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousComponent;
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.model.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.model.composite.CompositeComponent;
import hu.bme.mit.gamma.statechart.model.composite.CompositePackage;
import hu.bme.mit.gamma.statechart.model.composite.ControlSpecification;
import hu.bme.mit.gamma.statechart.model.composite.InstancePortReference;
import hu.bme.mit.gamma.statechart.model.composite.MessageQueue;
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponent;
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.model.interface_.Event;
import hu.bme.mit.gamma.statechart.model.interface_.EventDirection;
import hu.bme.mit.gamma.statechart.model.interface_.EventParameterReferenceExpression;
import hu.bme.mit.gamma.statechart.model.interface_.Interface;
import hu.bme.mit.gamma.statechart.model.interface_.InterfacePackage;

/**
 * This class contains custom scoping description.
 *
 * See
 * https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 */
public class StatechartLanguageScopeProvider extends AbstractStatechartLanguageScopeProvider {

	@Override
	public IScope getScope(final EObject context, final EReference reference) {

		// Statechart

		// Transitions
		try {
			if (context instanceof Transition && (reference == StatechartModelPackage.Literals.TRANSITION__SOURCE_STATE
					|| reference == StatechartModelPackage.Literals.TRANSITION__TARGET_STATE)) {
				final Collection<StateNode> candidates = stateNodesForTransition((Transition) context);
				return Scopes.scopeFor(candidates);
			}
			if (context instanceof PortEventReference && reference == StatechartModelPackage.Literals.PORT_EVENT_REFERENCE__EVENT) {
				Port port = ((PortEventReference) context).getPort();
				Interface _interface = port.getInterfaceRealization().getInterface();
				// Not only in events are returned as less-aware users tend to write out events on triggers
				return Scopes.scopeFor(getAllEvents(_interface));
			}
			if (reference == StatechartModelPackage.Literals.PORT_EVENT_REFERENCE__EVENT) {
				// If the branch above does not work
				StatechartDefinition statechart = StatechartModelDerivedFeatures.getContainingStatechart(context);
				Collection<Event> events = new HashSet<Event>();
				statechart.getPorts()
					.forEach(it -> events.addAll(getAllEvents(it.getInterfaceRealization().getInterface())));
				// Not only in events are returned as less-aware users tend to write out events on triggers
				return Scopes.scopeFor(events);
			}
			if (context instanceof RaiseEventAction
					&& reference == StatechartModelPackage.Literals.RAISE_EVENT_ACTION__EVENT) {
				RaiseEventAction raiseEventAction = (RaiseEventAction) context;
				Port port = raiseEventAction.getPort();
				Interface _interface = port.getInterfaceRealization().getInterface();
				// Not only in events are returned as less-aware users tend to write in events on actions
				return Scopes.scopeFor(getAllEvents(_interface));
			}
			if (context instanceof EnumerationLiteralExpression && 
					reference == ConstraintModelPackage.Literals.ENUMERATION_LITERAL_EXPRESSION__REFERENCE) {
				EObject root = EcoreUtil2.getRootContainer(context, true);
				Collection<EnumerationLiteralDefinition> enumLiterals = EcoreUtil2.getAllContentsOfType(root, EnumerationLiteralDefinition.class);
				return(Scopes.scopeFor(enumLiterals));
			}
			/* Without such scoping rules, the following exception is thrown:
			 * Caused By: org.eclipse.xtext.conversion.ValueConverterException: ID 'Test.testIn.testInValue'
			 * contains invalid characters: '.' (0x2e) */
			// Valueof
			if (context instanceof EventParameterReferenceExpression
					&& reference == InterfacePackage.Literals.EVENT_PARAMETER_REFERENCE_EXPRESSION__PORT) {
				Component component = StatechartModelDerivedFeatures.getContainingComponent(context);				
				return Scopes.scopeFor(component.getPorts());
			}
			if (context instanceof EventParameterReferenceExpression
					&& reference == InterfacePackage.Literals.EVENT_PARAMETER_REFERENCE_EXPRESSION__EVENT) {
				EventParameterReferenceExpression expression = (EventParameterReferenceExpression) context;
				checkState(expression.getPort() != null);
				Port port = expression.getPort();
				return Scopes.scopeFor(getSemanticEvents(Collections.singleton(port), EventDirection.IN));
			}
			if (context instanceof EventParameterReferenceExpression
					&& reference == InterfacePackage.Literals.EVENT_PARAMETER_REFERENCE_EXPRESSION__PARAMETER) {
				EventParameterReferenceExpression expression = (EventParameterReferenceExpression) context;
				checkState(expression.getPort() != null);
				Event event = expression.getEvent();
				return Scopes.scopeFor(event.getParameterDeclarations());
			}

			// Composite system

			// Ports
			if (context instanceof InterfaceRealization && reference == StatechartModelPackage.Literals.INTERFACE_REALIZATION__INTERFACE) {
				Package gammaPackage = (Package) context.eContainer().eContainer().eContainer();
				if (!gammaPackage.getImports().isEmpty()) {
					Set<Interface> interfaces = new HashSet<Interface>();
					gammaPackage.getImports().stream().map(it -> it.getInterfaces()).forEach(it -> interfaces.addAll(it));
					return Scopes.scopeFor(interfaces);
				}
			}
			if (context instanceof InstancePortReference && reference == CompositePackage.Literals.INSTANCE_PORT_REFERENCE__PORT) {
				InstancePortReference portInstance = (InstancePortReference) context;
				ComponentInstance instance = portInstance.getInstance();
				Component type = (instance instanceof SynchronousComponentInstance) ? 
						((SynchronousComponentInstance) instance).getType() : 
							((AsynchronousComponentInstance) instance).getType();
				if (type == null) {
					return super.getScope(context, reference); 
				}
				List<Port> ports = new ArrayList<Port>(type.getPorts());
				// In case of wrappers, we added the ports of the wrapped component as well
				if (type instanceof AsynchronousAdapter) {
					AsynchronousAdapter wrapper = (AsynchronousAdapter) type;
					ports.addAll(wrapper.getWrappedComponent().getType().getPorts());
				}				
				return Scopes.scopeFor(ports);
			}
			if (context instanceof CompositeComponent && reference == CompositePackage.Literals.INSTANCE_PORT_REFERENCE__PORT) {
				// If the branch above does not handle it
				CompositeComponent component = (CompositeComponent) context;
				List<? extends ComponentInstance> components = StatechartModelDerivedFeatures.getDerivedComponents(component);
				Collection<Port> ports = new HashSet<Port>();
				components.stream().map(it -> StatechartModelDerivedFeatures.getDerivedType(it))
								.map(it ->StatechartModelDerivedFeatures.getAllPorts(it))
								.forEach(it -> ports.addAll(it));
				return Scopes.scopeFor(ports); 
			}
			// Types
			if (context instanceof SynchronousComponentInstance && reference == CompositePackage.Literals.SYNCHRONOUS_COMPONENT_INSTANCE__TYPE) {
				return collectComponents((Package) context.eContainer().eContainer(), true);
			}
			if (context instanceof AsynchronousComponentInstance && reference == CompositePackage.Literals.ASYNCHRONOUS_COMPONENT_INSTANCE__TYPE) {
				return collectComponents((Package) context.eContainer().eContainer(), false);
			}		
			// Synchronous wrapper specific rules
			if (context instanceof PortEventReference && reference == StatechartModelPackage.Literals.PORT_EVENT_REFERENCE__PORT ||
				context instanceof AnyPortEventReference && reference == StatechartModelPackage.Literals.ANY_PORT_EVENT_REFERENCE__PORT) {
				AsynchronousAdapter wrapper = null;
				if (context.eContainer().eContainer() instanceof AsynchronousAdapter) {
					// Message queues
					wrapper = (AsynchronousAdapter) context.eContainer().eContainer();
				}
				if (context.eContainer().eContainer().eContainer() instanceof AsynchronousAdapter) {
					// Control specification
					wrapper = (AsynchronousAdapter) context.eContainer().eContainer().eContainer();
				}
				if (wrapper != null) {
					// Derived feature "allPorts" does not work all the time
					Set<Port> ports = new HashSet<Port>();
					ports.addAll(wrapper.getPorts());
					ports.addAll(wrapper.getWrappedComponent().getType().getPorts());
					return Scopes.scopeFor(ports);
				}
			}
			if ((context instanceof MessageQueue || context instanceof ControlSpecification) &&
					(reference == StatechartModelPackage.Literals.PORT_EVENT_REFERENCE__PORT ||
					reference == StatechartModelPackage.Literals.ANY_PORT_EVENT_REFERENCE__PORT)) {
				AsynchronousAdapter wrapper = (AsynchronousAdapter) context.eContainer();
				return Scopes.scopeFor(StatechartModelDerivedFeatures.getAllPorts(wrapper));
			}
			if ((context instanceof MessageQueue || context instanceof ControlSpecification) &&
					reference == StatechartModelPackage.Literals.PORT_EVENT_REFERENCE__EVENT) {
				AsynchronousAdapter wrapper = (AsynchronousAdapter) context.eContainer();
				Collection<Event> events = new HashSet<Event>();
				StatechartModelDerivedFeatures.getAllPorts(wrapper).stream()
					.forEach(it -> events.addAll(getSemanticEvents(Collections.singletonList(it), EventDirection.IN)));
				return Scopes.scopeFor(events);
			}
			if (/*context instanceof EventTrigger && */reference == ConstraintModelPackage.Literals.REFERENCE_EXPRESSION__DECLARATION) {
				Package gammaPackage = (Package) EcoreUtil2.getRootContainer(context, true);
				Component component = null;
				try {
					component = StatechartModelDerivedFeatures.getContainingComponent(context);
				} catch (IllegalArgumentException exception) {
					// The context is not contained by a component, we rely on default scoping
					return super.getScope(context, reference);
				}
				Collection<Declaration> declarations = getAllParameterDeclarations(component);
				// Important to add the normal declarations as well
				Collection<Declaration> normalDeclarations = EcoreUtil2.getAllContentsOfType(gammaPackage, Declaration.class);
				declarations.addAll(normalDeclarations);
				return Scopes.scopeFor(declarations);
			}
		} catch (NullPointerException e) {
			// Nullptr exception is thrown if the scope turns out to be empty
			// This can be due to modeling error of the user, e.g., there no in events on the specified ports
			return super.getScope(context, reference);
		} catch (Exception e) {
			e.printStackTrace();
		} 
		return super.getScope(context, reference);
	}

	private IScope collectComponents(Package parentPackage, boolean isSynchronous) {
		List<Component> types = new ArrayList<Component>();
		for (Package importedPackage : parentPackage.getImports()) {
			for (Component importedComponent : importedPackage.getComponents()) {
				if (importedComponent instanceof SynchronousComponent && isSynchronous) {
					types.add(importedComponent);
				}
				else if (importedComponent instanceof AsynchronousComponent && !isSynchronous) {
					types.add(importedComponent);
				}
			}
		}
		for (Component siblingComponent : parentPackage.getComponents()) {
			if (siblingComponent instanceof SynchronousComponent && isSynchronous) {
				types.add(siblingComponent);
			}
			else if (siblingComponent instanceof AsynchronousComponent && !isSynchronous) {
				types.add(siblingComponent);
			}
		}
		return Scopes.scopeFor(types);
	}

	private Collection<Event> getSemanticEvents(Collection<? extends Port> ports, EventDirection direction) {
		Collection<Event> events =  new HashSet<Event>();
   		for (Interface anInterface : ports.stream().filter(it -> it.getInterfaceRealization()
   				.getRealizationMode() == RealizationMode.PROVIDED).
   				map(it -> it.getInterfaceRealization().getInterface()).collect(Collectors.toSet())) {
			events.addAll(getAllEvents(anInterface, getOppositeDirection(direction)));
   		}
   		for (Interface anInterface : ports.stream().filter(it -> it.getInterfaceRealization()
   				.getRealizationMode() == RealizationMode.REQUIRED)
   				.map(it -> it.getInterfaceRealization().getInterface()).collect(Collectors.toSet())) {
			events.addAll(getAllEvents(anInterface, direction));
   		}
   		return events;
   	}
	
	/** The parent interfaces are taken into considerations as well. */ 
	private Collection<Event> getAllEvents(Interface anInterface, EventDirection oppositeDirection) {
  		if (anInterface == null) {
  			return Collections.emptySet();
  		}
  		Set<Event> eventSet = new HashSet<Event>();
  		for (Interface parentInterface : anInterface.getParents()) {
  			eventSet.addAll(getAllEvents(parentInterface, oppositeDirection));
  		}
  		for (Event event : anInterface.getEvents().stream().filter(it -> it.getDirection() != oppositeDirection).map(it -> it.getEvent()).collect(Collectors.toSet())) {
  			eventSet.add(event);
  		}
  		return eventSet;
  	}
	
	/** The parent interfaces are taken into considerations as well. */ 
	private Collection<Event> getAllEvents(Interface anInterface) {
  		if (anInterface == null) {
  			return Collections.emptySet();
  		}
  		Set<Event> eventSet = new HashSet<Event>();
  		for (Interface parentInterface : anInterface.getParents()) {
  			eventSet.addAll(getAllEvents(parentInterface));
  		}
  		for (Event event : anInterface.getEvents().stream().map(it -> it.getEvent()).collect(Collectors.toSet())) {
  			eventSet.add(event);
  		}
  		return eventSet;
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
	
	private Collection<Declaration> getAllParameterDeclarations(Component component) {
		Set<Declaration> declarations = new HashSet<Declaration>(component.getParameterDeclarations());
		for (Interface gammaInterface : component.getPorts().stream()
				.map(it -> it.getInterfaceRealization().getInterface()).collect(Collectors.toSet())) {
			for (Event event : getAllEvents(gammaInterface, EventDirection.IN)) {
				for (Declaration declaration : event.getParameterDeclarations()) {
					declarations.add(declaration);
				}
			}
			for (Event event : getAllEvents(gammaInterface, EventDirection.OUT)) {
				for (Declaration declaration : event.getParameterDeclarations()) {
					declarations.add(declaration);
				}
			}
		}
		return declarations;
	}
	
	private static Collection<StateNode> stateNodesForTransition(final Transition transition) {
		final StatechartDefinition rootElement = (StatechartDefinition) transition.eContainer();
		final Collection<StateNode> candidates = EcoreUtil2.getAllContentsOfType(rootElement, StateNode.class);
		return candidates;
	}

}
