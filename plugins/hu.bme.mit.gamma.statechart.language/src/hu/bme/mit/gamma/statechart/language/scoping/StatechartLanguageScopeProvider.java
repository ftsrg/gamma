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
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EReference;
import org.eclipse.xtext.EcoreUtil2;
import org.eclipse.xtext.scoping.IScope;
import org.eclipse.xtext.scoping.Scopes;

import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression;
import hu.bme.mit.gamma.expression.model.ExpressionModelPackage;
import hu.bme.mit.gamma.expression.model.TypeDeclaration;
import hu.bme.mit.gamma.statechart.model.AnyPortEventReference;
import hu.bme.mit.gamma.statechart.model.InterfaceRealization;
import hu.bme.mit.gamma.statechart.model.Package;
import hu.bme.mit.gamma.statechart.model.Port;
import hu.bme.mit.gamma.statechart.model.PortEventReference;
import hu.bme.mit.gamma.statechart.model.RaiseEventAction;
import hu.bme.mit.gamma.statechart.model.StateNode;
import hu.bme.mit.gamma.statechart.model.StatechartDefinition;
import hu.bme.mit.gamma.statechart.model.StatechartModelPackage;
import hu.bme.mit.gamma.statechart.model.Transition;
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousAdapter;
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousComponent;
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.model.composite.Component;
import hu.bme.mit.gamma.statechart.model.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.model.composite.CompositeComponent;
import hu.bme.mit.gamma.statechart.model.composite.CompositePackage;
import hu.bme.mit.gamma.statechart.model.composite.ControlSpecification;
import hu.bme.mit.gamma.statechart.model.composite.InstancePortReference;
import hu.bme.mit.gamma.statechart.model.composite.MessageQueue;
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponent;
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.model.contract.AdaptiveContractAnnotation;
import hu.bme.mit.gamma.statechart.model.contract.ContractPackage;
import hu.bme.mit.gamma.statechart.model.contract.StateContractAnnotation;
import hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.model.interface_.Event;
import hu.bme.mit.gamma.statechart.model.interface_.EventParameterReferenceExpression;
import hu.bme.mit.gamma.statechart.model.interface_.Interface;
import hu.bme.mit.gamma.statechart.model.interface_.InterfacePackage;
import hu.bme.mit.gamma.statechart.model.phase.InstanceVariableReference;
import hu.bme.mit.gamma.statechart.model.phase.PhasePackage;
import hu.bme.mit.gamma.statechart.model.phase.VariableBinding;

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

		try {
			// Adaptive
			if (context instanceof AdaptiveContractAnnotation &&
					reference == ContractPackage.Literals.ADAPTIVE_CONTRACT_ANNOTATION__MONITORED_COMPONENT) {
				Package parentPackage = StatechartModelDerivedFeatures.getContainingPackage(context);
				StatechartDefinition parentStatechart = StatechartModelDerivedFeatures.getContainingStatechart(context);
				Set<Component> allComponents = StatechartModelDerivedFeatures.getAllComponents(parentPackage);
				allComponents.remove(parentStatechart);
				return Scopes.scopeFor(allComponents);
			}
			if (context instanceof StateContractAnnotation &&
					reference == ContractPackage.Literals.STATE_CONTRACT_ANNOTATION__CONTRACT_STATECHARTS) {
				Package parentPackage = StatechartModelDerivedFeatures.getContainingPackage(context);
				StatechartDefinition parentStatechart = StatechartModelDerivedFeatures.getContainingStatechart(context);
				Set<StatechartDefinition> allComponents = StatechartModelDerivedFeatures.getAllStatechartComponents(parentPackage);
				allComponents.remove(parentStatechart);
				return Scopes.scopeFor(allComponents);
			}
			// Phase
			if (context instanceof InstanceVariableReference &&
					reference == PhasePackage.Literals.INSTANCE_VARIABLE_REFERENCE__VARIABLE) {
				EObject container = context.eContainer().eContainer();
				for (EObject eObject : container.eContents()) {
					if (eObject instanceof SynchronousComponentInstance) {
						SynchronousComponentInstance instance = (SynchronousComponentInstance) eObject;
						StatechartDefinition statechart = (StatechartDefinition) instance.getType();
						return Scopes.scopeFor(statechart.getVariableDeclarations());
					}
				}
			}
			// Transitions
			if (context instanceof Transition && (reference == StatechartModelPackage.Literals.TRANSITION__SOURCE_STATE
					|| reference == StatechartModelPackage.Literals.TRANSITION__TARGET_STATE)) {
				final Collection<StateNode> candidates = stateNodesForTransition((Transition) context);
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
			if (context instanceof EnumerationLiteralExpression && 
					reference == ExpressionModelPackage.Literals.ENUMERATION_LITERAL_EXPRESSION__REFERENCE) {
				Package root = (Package) EcoreUtil2.getRootContainer(context, true);
				Collection<EnumerationLiteralDefinition> enumLiterals = EcoreUtil2.getAllContentsOfType(root, EnumerationLiteralDefinition.class);
				for (Package imported : root.getImports()) {
					enumLiterals.addAll(EcoreUtil2.getAllContentsOfType(imported, EnumerationLiteralDefinition.class));
				}
				return Scopes.scopeFor(enumLiterals);
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
				return Scopes.scopeFor(StatechartModelDerivedFeatures.getInputEvents(port));
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
				Package _package = StatechartModelDerivedFeatures.getContainingPackage(context);
				Set<SynchronousComponent> components = StatechartModelDerivedFeatures.getAllSynchronousComponents(_package);
				components.remove(context.eContainer());
				return Scopes.scopeFor(components);
			}
			if (context instanceof AsynchronousComponentInstance && reference == CompositePackage.Literals.ASYNCHRONOUS_COMPONENT_INSTANCE__TYPE) {
				Package _package = StatechartModelDerivedFeatures.getContainingPackage(context);
				Set<AsynchronousComponent> components = StatechartModelDerivedFeatures.getAllAsynchronousComponents(_package);
				components.remove(context.eContainer());
				return Scopes.scopeFor(components);
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
					.forEach(it -> events.addAll(StatechartModelDerivedFeatures.getInputEvents(it)));
				return Scopes.scopeFor(events);
			}
			if (reference == ExpressionModelPackage.Literals.TYPE_REFERENCE__REFERENCE) {
				Package gammaPackage = (Package) EcoreUtil2.getRootContainer(context, true);
				List<TypeDeclaration> typeDeclarations = collectTypeDeclarations(gammaPackage);
				return Scopes.scopeFor(typeDeclarations);
			}
			if (/*context instanceof EventTrigger && */reference == ExpressionModelPackage.Literals.REFERENCE_EXPRESSION__DECLARATION) {
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
	
	private List<TypeDeclaration> collectTypeDeclarations(Package _package) {
		List<TypeDeclaration> types = new ArrayList<TypeDeclaration>();
		for (Package _import :_package.getImports()) {
			types.addAll(_import.getTypeDeclarations());
		}
		types.addAll(_package.getTypeDeclarations());
		return types;
	}

	private Collection<Declaration> getAllParameterDeclarations(Component component) {
		Set<Declaration> declarations = new HashSet<Declaration>(component.getParameterDeclarations());
		for (Interface gammaInterface : component.getPorts().stream()
				.map(it -> it.getInterfaceRealization().getInterface()).collect(Collectors.toSet())) {
			for (Event event : StatechartModelDerivedFeatures.getAllEvents(gammaInterface)) {
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
