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
import org.eclipse.xtext.xbase.lib.Functions.Function1;
import org.eclipse.xtext.xbase.lib.IterableExtensions;

import com.google.common.base.Objects;
import com.google.common.collect.Iterables;
import com.google.common.collect.Lists;

import hu.bme.mit.gamma.action.model.Action;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelPackage;
import hu.bme.mit.gamma.expression.model.FieldDeclaration;
import hu.bme.mit.gamma.expression.model.ParametricElement;
import hu.bme.mit.gamma.expression.model.TypeDeclaration;
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter;
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponent;
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.composite.CascadeCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceElementReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceEventParameterReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceEventReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.CompositeComponent;
import hu.bme.mit.gamma.statechart.composite.CompositeModelPackage;
import hu.bme.mit.gamma.statechart.composite.ControlSpecification;
import hu.bme.mit.gamma.statechart.composite.InstancePortReference;
import hu.bme.mit.gamma.statechart.composite.MessageQueue;
import hu.bme.mit.gamma.statechart.composite.ScheduledAsynchronousCompositeComponent;
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
import hu.bme.mit.gamma.statechart.interface_.InterfaceParameterReferenceExpression;
import hu.bme.mit.gamma.statechart.interface_.InterfaceRealization;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.statechart.phase.InstanceVariableReference;
import hu.bme.mit.gamma.statechart.phase.MissionPhaseStateAnnotation;
import hu.bme.mit.gamma.statechart.phase.PhaseModelPackage;
import hu.bme.mit.gamma.statechart.statechart.AnyPortEventReference;
import hu.bme.mit.gamma.statechart.statechart.CompositeElement;
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
					return Scopes.scopeFor(
							statechart.getVariableDeclarations());
				}
			}
			// Transitions
			if (reference == StatechartModelPackage.Literals.TRANSITION__TARGET_STATE) {
				if (context instanceof Transition transition) { // Start
					StateNode sourceState = transition.getSourceState();
					Region parentRegion = StatechartModelDerivedFeatures.getParentRegion(sourceState);
					IScope parentScope = getParentScope(parentRegion.eContainer(), reference);
					IScope scope = getScope(parentRegion, StatechartModelPackage.Literals.TRANSITION__SOURCE_STATE); // Reusing code
					return embedScopes(
							List.of(parentScope, scope));
				}
				if (context instanceof StatechartDefinition) { // End
					return IScope.NULLSCOPE;
				}
				if (context instanceof Region region) { // Middle
					IScope parentScope = getParentScope(context, reference);
					List<StateNode> stateNodes = region.getStateNodes();
					return Scopes.scopeFor(stateNodes, parentScope);
				}
				else { // Middle (state element)
					return getParentScope(context, reference);
				}
			}
			if (reference == StatechartModelPackage.Literals.TRANSITION__SOURCE_STATE) {
				if (context instanceof Transition) {
					StatechartDefinition statechart = StatechartModelDerivedFeatures.getContainingStatechart(context);
					return getScope(statechart, reference);
				}
				if (context instanceof CompositeElement composite) {
					List<Region> regions = composite.getRegions();
					List<IScope> scopes = new ArrayList<IScope>();
					for (Region region : regions) {
						IScope scope = getScope(region, reference);
						scopes.add(scope);
					}
					return embedScopes(scopes);
				}
				if (context instanceof Region region) {
					List<StateNode> stateNodes = region.getStateNodes();
					List<IScope> scopes = new ArrayList<IScope>();
					for (State state : StatechartModelDerivedFeatures.getStates(region)) {
						IScope scope = getScope(state, reference);
						scopes.add(scope);
					}
					IScope parentScope = embedScopes(scopes);
					return Scopes.scopeFor(stateNodes, parentScope);
				}
			}
			//
			if (context instanceof PortEventReference portEventReference && reference == StatechartModelPackage.Literals.PORT_EVENT_REFERENCE__EVENT) {
				Port port = portEventReference.getPort();
				Interface _interface = port.getInterfaceRealization().getInterface();
				// Not only in events are returned as less-aware users tend to write out events on triggers
				return Scopes.scopeFor(
						StatechartModelDerivedFeatures.getAllEvents(_interface));
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
			if (context instanceof RaiseEventAction raiseEventAction
					&& reference == StatechartModelPackage.Literals.RAISE_EVENT_ACTION__EVENT) {
				Port port = raiseEventAction.getPort();
				Interface _interface = port.getInterfaceRealization().getInterface();
				// Not only in events are returned as less-aware users tend to write in events on actions
				return Scopes.scopeFor(
						StatechartModelDerivedFeatures.getAllEvents(_interface));
			}
			/* Without such scoping rules, the following exception is thrown:
			 * Caused By: org.eclipse.xtext.conversion.ValueConverterException: ID 'Test.testIn.testInValue'
			 * contains invalid characters: '.' (0x2e) */
			// Valueof
			if (context instanceof EventParameterReferenceExpression &&
					reference == InterfaceModelPackage.Literals.EVENT_PARAMETER_REFERENCE_EXPRESSION__PORT) {
				Component component = StatechartModelDerivedFeatures.getContainingComponent(context);				
				return Scopes.scopeFor(component.getPorts());
			}
			if (context instanceof EventParameterReferenceExpression expression &&
					reference == InterfaceModelPackage.Literals.EVENT_PARAMETER_REFERENCE_EXPRESSION__EVENT) {
				checkState(expression.getPort() != null);
				Port port = expression.getPort();
				return Scopes.scopeFor(
						StatechartModelDerivedFeatures.getInputEvents(port));
			}
			if (context instanceof EventParameterReferenceExpression expression &&
					reference == InterfaceModelPackage.Literals.EVENT_PARAMETER_REFERENCE_EXPRESSION__PARAMETER) {
				checkState(expression.getPort() != null);
				Event event = expression.getEvent();
				return Scopes.scopeFor(event.getParameterDeclarations());
			}
			if (reference == StatechartModelPackage.Literals.STATE_REFERENCE_EXPRESSION__REGION) {
				StatechartDefinition statechart = StatechartModelDerivedFeatures.getContainingStatechart(context);
				Collection<Region> allRegions = StatechartModelDerivedFeatures.getAllRegions(statechart);
				return Scopes.scopeFor(allRegions);
			}
			if (context instanceof StateReferenceExpression stateReferenceExpression &&
					reference == StatechartModelPackage.Literals.STATE_REFERENCE_EXPRESSION__STATE) {
				Region region = stateReferenceExpression.getRegion();
				List<State> states = StatechartModelDerivedFeatures.getStates(region);
				return Scopes.scopeFor(states);
			}
			if (context instanceof InterfaceParameterReferenceExpression interfaceParameterReferenceExpression) {
				if (reference == InterfaceModelPackage.Literals.INTERFACE_PARAMETER_REFERENCE_EXPRESSION__PARAMETER) {
					checkState(interfaceParameterReferenceExpression.getEvent() != null);
					Event event = interfaceParameterReferenceExpression.getEvent();					
					return Scopes.scopeFor(
							event.getParameterDeclarations());
				} else if (reference == InterfaceModelPackage.Literals.INTERFACE_PARAMETER_REFERENCE_EXPRESSION__EVENT) {
					Interface _interface = StatechartModelDerivedFeatures.getContainingInterface(interfaceParameterReferenceExpression);	
					return Scopes.scopeFor(
							StatechartModelDerivedFeatures.getAllEvents(_interface));
				}
			}

			// Composite system

			// Ports
			if (context instanceof InterfaceRealization && reference == InterfaceModelPackage.Literals.INTERFACE_REALIZATION__INTERFACE) {
				Package gammaPackage = StatechartModelDerivedFeatures.getContainingPackage(context);
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
			if (context instanceof InstancePortReference portInstance && reference == CompositeModelPackage.Literals.INSTANCE_PORT_REFERENCE__PORT) {
				ComponentInstance instance = portInstance.getInstance();
				Component type = StatechartModelDerivedFeatures.getDerivedType(instance);
				if (type == null) {
					return super.getScope(context, reference); 
				}
				List<Port> ports = new ArrayList<Port>(type.getPorts());
				// In case of wrappers, we added the ports of the wrapped component as well
				if (type instanceof AsynchronousAdapter wrapper) {
					ports.addAll(wrapper.getWrappedComponent().getType().getPorts());
				}				
				return Scopes.scopeFor(ports);
			}
			if (context instanceof CompositeComponent component && reference == CompositeModelPackage.Literals.INSTANCE_PORT_REFERENCE__PORT) {
				// If the branch above does not handle it
				List<? extends ComponentInstance> components = StatechartModelDerivedFeatures.getDerivedComponents(component);
				Collection<Port> ports = new HashSet<Port>();
				components.stream().map(it -> StatechartModelDerivedFeatures.getDerivedType(it))
								.map(it ->StatechartModelDerivedFeatures.getAllPorts(it))
								.forEach(it -> ports.addAll(it));
				return Scopes.scopeFor(ports); 
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
				if (context instanceof CascadeCompositeComponent cascade) {
					return Scopes.scopeFor(cascade.getComponents());
				}
				if (context instanceof ScheduledAsynchronousCompositeComponent scheduled) {
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
				return Scopes.scopeFor(
						StatechartModelDerivedFeatures.getAllPorts(wrapper));
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
					if (element instanceof StatechartDefinition statechart) {
						Collection<Declaration> declarations = new ArrayList<Declaration>();
						declarations.addAll(statechart.getVariableDeclarations());
						declarations.addAll(statechart.getFunctionDeclarations());
						scope = Scopes.scopeFor(declarations, parentScope);
					}
					else {
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
	
	@Override
	protected List<FieldDeclaration> getFieldDeclarations(Expression operand) {
		if (operand instanceof EventParameterReferenceExpression reference) {
			Declaration declaration = reference.getParameter();
			return super.getFieldDeclarations(declaration);
		}
		return super.getFieldDeclarations(operand);
	}

	//
	
	protected IScope handleTypeDeclarationAndComponentInstanceElementReferences(EObject context,
			EReference reference, Collection<? extends Package> packages, Component component) {
		IScope typeScope = handleTypeDeclarationReferences(context, reference, packages);
		if (typeScope != null) {
			return typeScope;
		}
		IScope componentInstanceElementScope = handleComponentInstanceElementReferences(context, reference, component);
		if (componentInstanceElementScope != null) {
			return componentInstanceElementScope;
		}
		
		return null;
	}

	protected IScope handleTypeDeclarationReferences(EObject context, EReference reference,
			Collection<? extends Package> packages) {
		boolean _equals = Objects.equal(reference, ExpressionModelPackage.Literals.TYPE_REFERENCE__REFERENCE);
		if (_equals) {
			Function1<Package, List<TypeDeclaration>> _function = (Package it) -> {	return it.getTypeDeclarations(); };
			Iterable<TypeDeclaration> typeDeclarations = Iterables.<TypeDeclaration>concat(IterableExtensions.map(packages, _function));
			return Scopes.scopeFor(typeDeclarations);
		}
		
		return null;
	}

	protected IScope handleComponentInstanceElementReferences(EObject context, EReference reference, Component component) {
		boolean _equals = Objects.equal(reference, CompositeModelPackage.Literals.COMPONENT_INSTANCE_REFERENCE_EXPRESSION__COMPONENT_INSTANCE);
		if (_equals) {
			ComponentInstanceReferenceExpression instanceContainer = this.ecoreUtil
					.getSelfOrContainerOfType(context, ComponentInstanceReferenceExpression.class);
			ComponentInstanceReferenceExpression _parent = null;
			if (instanceContainer != null) {
				_parent = StatechartModelDerivedFeatures.getParent(instanceContainer);
			}
			ComponentInstanceReferenceExpression parent = _parent;
			List<ComponentInstance> instances = null;
			if (parent == null) {
				instances = StatechartModelDerivedFeatures.getAllInstances(component);
			}
			else {
				instances = StatechartModelDerivedFeatures.getInstances(parent.getComponentInstance());
			}
			
			return Scopes.scopeFor(instances);
		}
		if (context instanceof ComponentInstanceElementReferenceExpression) {
			ComponentInstance instance = StatechartModelDerivedFeatures.getLastInstance(((ComponentInstanceElementReferenceExpression) context).getInstance());
			Component statechart = StatechartModelDerivedFeatures.getDerivedType(instance);
			if (statechart != null) {
				if (statechart instanceof StatechartDefinition) {
					boolean _equals_1 = Objects.equal(reference, CompositeModelPackage.Literals.COMPONENT_INSTANCE_STATE_REFERENCE_EXPRESSION__REGION);
					if (_equals_1) {
						return Scopes.scopeFor(StatechartModelDerivedFeatures.getAllRegions((CompositeElement) statechart));
					}
					boolean _equals_2 = Objects.equal(reference, CompositeModelPackage.Literals.COMPONENT_INSTANCE_STATE_REFERENCE_EXPRESSION__STATE);
					if (_equals_2) {
						ComponentInstanceStateReferenceExpression stateConfigurationReference = (ComponentInstanceStateReferenceExpression) context;
						Region region = stateConfigurationReference.getRegion();
						return Scopes.scopeFor(StatechartModelDerivedFeatures.getStates(region));
					}
					boolean _equals_3 = Objects.equal(reference, CompositeModelPackage.Literals.COMPONENT_INSTANCE_VARIABLE_REFERENCE_EXPRESSION__VARIABLE_DECLARATION);
					if (_equals_3) {
						return Scopes.scopeFor(((StatechartDefinition) statechart).getVariableDeclarations());
					}
					if (Objects.equal(reference, CompositeModelPackage.Literals.COMPONENT_INSTANCE_EVENT_REFERENCE_EXPRESSION__PORT) || 
						Objects.equal(reference, CompositeModelPackage.Literals.COMPONENT_INSTANCE_EVENT_PARAMETER_REFERENCE_EXPRESSION__PORT)) {
						return Scopes.scopeFor(((StatechartDefinition) statechart).getPorts());
					}
					if (Objects.equal(reference, CompositeModelPackage.Literals.COMPONENT_INSTANCE_EVENT_REFERENCE_EXPRESSION__EVENT) || 
						Objects.equal(reference, CompositeModelPackage.Literals.COMPONENT_INSTANCE_EVENT_PARAMETER_REFERENCE_EXPRESSION__EVENT)) {
						if (context instanceof ComponentInstanceEventReferenceExpression) {
							Port port = ((ComponentInstanceEventReferenceExpression) context).getPort();
							boolean _eIsProxy = port.eIsProxy();
							boolean _not = (!_eIsProxy);
							if (_not) {
								return Scopes.scopeFor(StatechartModelDerivedFeatures.getAllEvents(port));
							}
						}
						if (context instanceof ComponentInstanceEventParameterReferenceExpression) {
							Port port_1 = ((ComponentInstanceEventParameterReferenceExpression) context).getPort();
							boolean _eIsProxy_1 = port_1.eIsProxy();
							boolean _not_1 = !_eIsProxy_1;
							if (_not_1) {
								return Scopes.scopeFor(StatechartModelDerivedFeatures.getOutputEvents(port_1));
							}
						}
					}
					boolean _equals_4 = Objects.equal(reference, CompositeModelPackage.Literals.COMPONENT_INSTANCE_EVENT_PARAMETER_REFERENCE_EXPRESSION__PARAMETER_DECLARATION);
					if (_equals_4) {
						ComponentInstanceEventParameterReferenceExpression eventParameterReference = (ComponentInstanceEventParameterReferenceExpression) context;
						return Scopes.scopeFor(eventParameterReference.getEvent().getParameterDeclarations());
					}
				}
			}
		}
		
		return null;
	}
	
}