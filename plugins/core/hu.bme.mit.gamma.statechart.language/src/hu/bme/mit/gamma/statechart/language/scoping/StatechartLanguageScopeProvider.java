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
package hu.bme.mit.gamma.statechart.language.scoping;

import static com.google.common.base.Preconditions.checkState;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EReference;
import org.eclipse.xtext.scoping.IScope;
import org.eclipse.xtext.scoping.Scopes;
import org.eclipse.xtext.scoping.impl.SimpleScope;

import com.google.common.collect.Lists;

import hu.bme.mit.gamma.action.model.Action;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelPackage;
import hu.bme.mit.gamma.expression.model.FieldDeclaration;
import hu.bme.mit.gamma.expression.model.ParametricElement;
import hu.bme.mit.gamma.statechart.ActivityComposition.ActivityCompositionPackage;
import hu.bme.mit.gamma.statechart.ActivityComposition.InstanceActivityControllerPortReference;
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter;
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponent;
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.composite.CascadeCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.composite.CompositeComponent;
import hu.bme.mit.gamma.statechart.composite.CompositeModelPackage;
import hu.bme.mit.gamma.statechart.composite.ControlSpecification;
import hu.bme.mit.gamma.statechart.composite.InstancePortReference;
import hu.bme.mit.gamma.statechart.composite.MessageQueue;
import hu.bme.mit.gamma.statechart.composite.ScheduledAsynchronousCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.StatefulComponent;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponent;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.contract.AdaptiveContractAnnotation;
import hu.bme.mit.gamma.statechart.contract.ContractModelPackage;
import hu.bme.mit.gamma.statechart.contract.ScenarioContractAnnotation;
import hu.bme.mit.gamma.statechart.contract.StateContractAnnotation;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Event;
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression;
import hu.bme.mit.gamma.statechart.interface_.Interface;
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelPackage;
import hu.bme.mit.gamma.statechart.interface_.InterfaceRealization;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.statechart.phase.InstanceVariableReference;
import hu.bme.mit.gamma.statechart.phase.MissionPhaseStateAnnotation;
import hu.bme.mit.gamma.statechart.phase.PhaseModelPackage;
import hu.bme.mit.gamma.statechart.statechart.AnyPortEventReference;
import hu.bme.mit.gamma.statechart.statechart.PortEventReference;
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction;
import hu.bme.mit.gamma.statechart.statechart.Region;
import hu.bme.mit.gamma.statechart.statechart.State;
import hu.bme.mit.gamma.statechart.statechart.StateNode;
import hu.bme.mit.gamma.statechart.statechart.StateReferenceExpression;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.statechart.statechart.StatechartModelPackage;
import hu.bme.mit.gamma.statechart.statechart.Transition;
import hu.bme.mit.gamma.statechart.util.StatechartUtil;

public class StatechartLanguageScopeProvider extends AbstractStatechartLanguageScopeProvider {

	public StatechartLanguageScopeProvider() {
		super.util = StatechartUtil.INSTANCE;
	}
	
	@Override
	public IScope getScope(final EObject context, final EReference reference) {

		// Statechart

		try {
			// Adaptive
			if (context instanceof AdaptiveContractAnnotation &&
					reference == ContractModelPackage.Literals.ADAPTIVE_CONTRACT_ANNOTATION__MONITORED_COMPONENT ||
					context instanceof ScenarioContractAnnotation && // Scenario contract
					reference == ContractModelPackage.Literals.SCENARIO_CONTRACT_ANNOTATION__MONITORED_COMPONENT) {
				Package parentPackage = StatechartModelDerivedFeatures.getContainingPackage(context);
				Set<Component> allComponents = StatechartModelDerivedFeatures.getAllComponents(parentPackage);
				// If we want to merge adaptive scenario and behavior descriptions,
				// it makes sense to monitor the parent statechart
				// StatechartDefinition parentStatechart = StatechartModelDerivedFeatures.getContainingStatechart(context);
				// allComponents.remove(parentStatechart);
				return Scopes.scopeFor(allComponents);
			}
			if (context instanceof StateContractAnnotation &&
					reference == ContractModelPackage.Literals.STATE_CONTRACT_ANNOTATION__CONTRACT_STATECHART) {
				Package parentPackage = StatechartModelDerivedFeatures.getContainingPackage(context);
				StatechartDefinition parentStatechart = StatechartModelDerivedFeatures.getContainingStatechart(context);
				Set<StatechartDefinition> allComponents = StatechartModelDerivedFeatures.getAllStatechartComponents(parentPackage);
				allComponents.remove(parentStatechart);
				return Scopes.scopeFor(allComponents);
			}
			// Phase
			if (context instanceof InstanceVariableReference &&
					reference == PhaseModelPackage.Literals.INSTANCE_VARIABLE_REFERENCE__VARIABLE) {
				MissionPhaseStateAnnotation container = ecoreUtil.getContainerOfType(context, MissionPhaseStateAnnotation.class);
				ComponentInstance instance = container.getComponent();
				Component type = StatechartModelDerivedFeatures.getDerivedType(instance);
				if (type instanceof StatechartDefinition) {
					StatechartDefinition statechart = (StatechartDefinition) type;
					return Scopes.scopeFor(statechart.getVariableDeclarations());
				}
			}
			// Transitions
			if (context instanceof Transition && (reference == StatechartModelPackage.Literals.TRANSITION__SOURCE_STATE
					|| reference == StatechartModelPackage.Literals.TRANSITION__TARGET_STATE)) {
				Transition transition = (Transition) context;
				Collection<StateNode> candidates = stateNodesForTransition(transition);
				return Scopes.scopeFor(candidates);
			}
			if (context instanceof PortEventReference && reference == StatechartModelPackage.Literals.PORT_EVENT_REFERENCE__EVENT) {
				Port port = ((PortEventReference) context).getPort();
				Interface _interface = port.getInterfaceRealization().getInterface();
				// Not only in events are returned as less-aware users tend to write out events on triggers
				return Scopes.scopeFor(StatechartModelDerivedFeatures.getAllEvents(_interface));
			}
			if (reference == StatechartModelPackage.Literals.PORT_EVENT_REFERENCE__EVENT) {
				// If the branch above does not work
				StatechartDefinition statechart = StatechartModelDerivedFeatures.getContainingStatechart(context);
				Collection<Event> events = new HashSet<Event>();
				statechart.getPorts()
					.forEach(it -> events.addAll(StatechartModelDerivedFeatures.getAllEvents(it.getInterfaceRealization().getInterface())));
				// Not only in events are returned as less-aware users tend to write out events on triggers
				return Scopes.scopeFor(events);
			}
			if (context instanceof RaiseEventAction
					&& reference == StatechartModelPackage.Literals.RAISE_EVENT_ACTION__EVENT) {
				RaiseEventAction raiseEventAction = (RaiseEventAction) context;
				Port port = raiseEventAction.getPort();
				Interface _interface = port.getInterfaceRealization().getInterface();
				// Not only in events are returned as less-aware users tend to write in events on actions
				return Scopes.scopeFor(StatechartModelDerivedFeatures.getAllEvents(_interface));
			}
			/* Without such scoping rules, the following exception is thrown:
			 * Caused By: org.eclipse.xtext.conversion.ValueConverterException: ID 'Test.testIn.testInValue'
			 * contains invalid characters: '.' (0x2e) */
			// Valueof
			if (context instanceof EventParameterReferenceExpression
					&& reference == InterfaceModelPackage.Literals.EVENT_PARAMETER_REFERENCE_EXPRESSION__PORT) {
				Component component = StatechartModelDerivedFeatures.getContainingComponent(context);				
				return Scopes.scopeFor(component.getPorts());
			}
			if (context instanceof EventParameterReferenceExpression
					&& reference == InterfaceModelPackage.Literals.EVENT_PARAMETER_REFERENCE_EXPRESSION__EVENT) {
				EventParameterReferenceExpression expression = (EventParameterReferenceExpression) context;
				checkState(expression.getPort() != null);
				Port port = expression.getPort();
				return Scopes.scopeFor(StatechartModelDerivedFeatures.getInputEvents(port));
			}
			if (context instanceof EventParameterReferenceExpression
					&& reference == InterfaceModelPackage.Literals.EVENT_PARAMETER_REFERENCE_EXPRESSION__PARAMETER) {
				EventParameterReferenceExpression expression = (EventParameterReferenceExpression) context;
				checkState(expression.getPort() != null);
				Event event = expression.getEvent();
				return Scopes.scopeFor(event.getParameterDeclarations());
			}
			if (reference == StatechartModelPackage.Literals.STATE_REFERENCE_EXPRESSION__REGION) {
				StatechartDefinition statechart = StatechartModelDerivedFeatures.getContainingStatechart(context);
				Collection<Region> allRegions = StatechartModelDerivedFeatures.getAllRegions(statechart);
				return Scopes.scopeFor(allRegions);
			}
			if (context instanceof StateReferenceExpression &&
					reference == StatechartModelPackage.Literals.STATE_REFERENCE_EXPRESSION__STATE) {
				StateReferenceExpression stateReferenceExpression = (StateReferenceExpression) context;
				Region region = stateReferenceExpression.getRegion();
				List<State> states = StatechartModelDerivedFeatures.getStates(region);
				return Scopes.scopeFor(states);
			}

			// Composite system

			// Ports
			if (context instanceof InterfaceRealization && reference == InterfaceModelPackage.Literals.INTERFACE_REALIZATION__INTERFACE) {
				Package gammaPackage = (Package) context.eContainer().eContainer().eContainer();
				if (!gammaPackage.getImports().isEmpty()) {
					Set<Interface> interfaces = new HashSet<Interface>();
					gammaPackage.getImports().stream().map(it -> it.getInterfaces()).forEach(it -> interfaces.addAll(it));
					return Scopes.scopeFor(interfaces);
				}
			}
			if (reference == CompositeModelPackage.Literals.PORT_BINDING__COMPOSITE_SYSTEM_PORT) {
				// Valid in the case of mission phase statecharts?
				Component type = ecoreUtil.getSelfOrContainerOfType(context, Component.class);
				List<Port> ports = StatechartModelDerivedFeatures.getAllPorts(type);
				return Scopes.scopeFor(ports);
			}
			if (context instanceof InstancePortReference && reference == CompositeModelPackage.Literals.INSTANCE_PORT_REFERENCE__PORT) {
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
			if (context instanceof CompositeComponent && reference == CompositeModelPackage.Literals.INSTANCE_PORT_REFERENCE__PORT) {
				// If the branch above does not handle it
				CompositeComponent component = (CompositeComponent) context;
				List<? extends ComponentInstance> components = StatechartModelDerivedFeatures.getDerivedComponents(component);
				Collection<Port> ports = new HashSet<Port>();
				components.stream().map(it -> StatechartModelDerivedFeatures.getDerivedType(it))
								.map(it ->StatechartModelDerivedFeatures.getAllPorts(it))
								.forEach(it -> ports.addAll(it));
				return Scopes.scopeFor(ports); 
			}
			if (context instanceof InstanceActivityControllerPortReference && reference == ActivityCompositionPackage.Literals.INSTANCE_ACTIVITY_CONTROLLER_PORT_REFERENCE__PORT) {
				InstanceActivityControllerPortReference portInstance = (InstanceActivityControllerPortReference) context;
				ComponentInstance instance = portInstance.getInstance();
				Component type = (instance instanceof SynchronousComponentInstance) ? 
						((SynchronousComponentInstance) instance).getType() : 
							((AsynchronousComponentInstance) instance).getType();
				if (type == null) {
					return super.getScope(context, reference); 
				}
				if (type instanceof StatechartDefinition == false) {
					return super.getScope(context, reference); 
				} 
				StatechartDefinition statechart = (StatechartDefinition) type;
				return Scopes.scopeFor(statechart.getActivities());
			}
			// Types
			if (context instanceof SynchronousComponentInstance && reference == CompositeModelPackage.Literals.SYNCHRONOUS_COMPONENT_INSTANCE__TYPE) {
				Package _package = StatechartModelDerivedFeatures.getContainingPackage(context);
				Set<SynchronousComponent> components = StatechartModelDerivedFeatures.getAllSynchronousComponents(_package);
				components.remove(context.eContainer());
				return Scopes.scopeFor(components);
			}
			if (context instanceof AsynchronousComponentInstance && reference == CompositeModelPackage.Literals.ASYNCHRONOUS_COMPONENT_INSTANCE__TYPE) {
				Package _package = StatechartModelDerivedFeatures.getContainingPackage(context);
				Set<AsynchronousComponent> components = StatechartModelDerivedFeatures.getAllAsynchronousComponents(_package);
				components.remove(context.eContainer());
				return Scopes.scopeFor(components);
			}
			if (reference == CompositeModelPackage.Literals.COMPONENT_INSTANCE_REFERENCE_EXPRESSION__COMPONENT_INSTANCE) {
				// Execution list
				if (context instanceof CascadeCompositeComponent) {
					CascadeCompositeComponent cascade = (CascadeCompositeComponent) context;
					return Scopes.scopeFor(cascade.getComponents());
				}
				if (context instanceof ScheduledAsynchronousCompositeComponent) {
					ScheduledAsynchronousCompositeComponent scheduled = (ScheduledAsynchronousCompositeComponent) context;
					return Scopes.scopeFor(scheduled.getComponents());
				}
			}
			// Asynchronous adapter-specific rules
			if (context instanceof PortEventReference && reference == StatechartModelPackage.Literals.PORT_EVENT_REFERENCE__PORT ||
				context instanceof AnyPortEventReference && reference == StatechartModelPackage.Literals.ANY_PORT_EVENT_REFERENCE__PORT) {
				AsynchronousAdapter wrapper = ecoreUtil.getContainerOfType(context, AsynchronousAdapter.class);
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
				AsynchronousAdapter wrapper = ecoreUtil.getContainerOfType(context, AsynchronousAdapter.class);
				return Scopes.scopeFor(StatechartModelDerivedFeatures.getAllPorts(wrapper));
			}
			if ((context instanceof MessageQueue || context instanceof ControlSpecification) &&
					reference == StatechartModelPackage.Literals.PORT_EVENT_REFERENCE__EVENT) {
				AsynchronousAdapter wrapper = ecoreUtil.getContainerOfType(context, AsynchronousAdapter.class);
				Collection<Event> events = new HashSet<Event>();
				StatechartModelDerivedFeatures.getAllPorts(wrapper).stream()
					.forEach(it -> events.addAll(StatechartModelDerivedFeatures.getInputEvents(it)));
				return Scopes.scopeFor(events);
			}
			if (reference == ExpressionModelPackage.Literals.DIRECT_REFERENCE_EXPRESSION__DECLARATION) {
				// 1. Local declarations
				Action actionContainer = ecoreUtil.getSelfOrContainerOfType(context, Action.class);
				if (actionContainer != null) {
					return super.getScope(actionContainer, reference);
					// Super takes care of the parent scopes
				}
				// 2. Variable declarations < parameter declarations < constant declarations - function declarations
				IScope scope = IScope.NULLSCOPE;
				ParametricElement element = ecoreUtil.getSelfOrContainerOfType(context, ParametricElement.class);
				if (element != null) {
					IScope parentScope = super.getScope(context, reference); // Parameters and constants
					if (element instanceof StatefulComponent) {
						StatefulComponent statechart = (StatefulComponent) element;
						Collection<Declaration> declarations = new ArrayList<Declaration>();
						declarations.addAll(statechart.getVariableDeclarations());
						declarations.addAll(statechart.getFunctionDeclarations());
						scope = Scopes.scopeFor(declarations, parentScope);
					} else {
						scope = parentScope;
					}
				}
				// 3. Imports
				Package containingPackage = StatechartModelDerivedFeatures.getContainingPackage(context);
				List<Package> imports = Lists.reverse(containingPackage.getImports()); // Latter imports are stronger
				for (Package _import : imports) {
					IScope parent = super.getScope(_import, reference);
					scope = new SimpleScope(parent, scope.getAllElements());
				}
				return scope;
			}
		} catch (NullPointerException e) {
			// Nullptr exception is thrown if the scope turns out to be empty
			// This can be due to modeling error of the user, e.g., there are no in events on the specified ports
			return super.getScope(context, reference);
		} catch (Exception e) {
			e.printStackTrace();
		} 
		return super.getScope(context, reference);
	}
	
	protected Collection<StateNode> stateNodesForTransition(Transition transition) {
		StatechartDefinition rootElement = StatechartModelDerivedFeatures.getContainingStatechart(transition);
		Collection<StateNode> candidates = ecoreUtil.getAllContentsOfType(rootElement, StateNode.class);
		return candidates;
	}
	
	@Override
	protected List<FieldDeclaration> getFieldDeclarations(Expression operand) {
		if (operand instanceof EventParameterReferenceExpression) {
			EventParameterReferenceExpression reference = (EventParameterReferenceExpression) operand;
			Declaration declaration = reference.getParameter();
			return super.getFieldDeclarations(declaration);
		}
		return super.getFieldDeclarations(operand);
	}

}