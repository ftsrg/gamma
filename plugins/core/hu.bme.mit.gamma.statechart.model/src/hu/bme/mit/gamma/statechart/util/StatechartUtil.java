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
package hu.bme.mit.gamma.statechart.util;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.action.model.AssignmentStatement;
import hu.bme.mit.gamma.action.util.ActionUtil;
import hu.bme.mit.gamma.expression.model.AccessExpression;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeDeclaration;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.expression.util.ExpressionUtil;
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter;
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponent;
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.composite.CascadeCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference;
import hu.bme.mit.gamma.statechart.composite.CompositeComponent;
import hu.bme.mit.gamma.statechart.composite.CompositeModelFactory;
import hu.bme.mit.gamma.statechart.composite.InstancePortReference;
import hu.bme.mit.gamma.statechart.composite.PortBinding;
import hu.bme.mit.gamma.statechart.composite.ScheduledAsynchronousCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.SimpleChannel;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponent;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Event;
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression;
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.statechart.interface_.TimeSpecification;
import hu.bme.mit.gamma.statechart.interface_.TimeUnit;
import hu.bme.mit.gamma.statechart.interface_.Trigger;
import hu.bme.mit.gamma.statechart.interface_.WrappedPackageAnnotation;
import hu.bme.mit.gamma.statechart.statechart.BinaryTrigger;
import hu.bme.mit.gamma.statechart.statechart.BinaryType;
import hu.bme.mit.gamma.statechart.statechart.CompositeElement;
import hu.bme.mit.gamma.statechart.statechart.EntryState;
import hu.bme.mit.gamma.statechart.statechart.InitialState;
import hu.bme.mit.gamma.statechart.statechart.Region;
import hu.bme.mit.gamma.statechart.statechart.State;
import hu.bme.mit.gamma.statechart.statechart.StateNode;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory;
import hu.bme.mit.gamma.statechart.statechart.Transition;

public class StatechartUtil extends ActionUtil {
	// Singleton
	public static final StatechartUtil INSTANCE = new StatechartUtil();
	protected StatechartUtil() {}
	//

	protected InterfaceModelFactory interfaceFactory = InterfaceModelFactory.eINSTANCE;
	protected StatechartModelFactory statechartFactory = StatechartModelFactory.eINSTANCE;
	protected CompositeModelFactory compositeFactory = CompositeModelFactory.eINSTANCE;
	
	protected ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE;

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
	
	public ComponentInstanceReference createInstanceReferenceChain(ComponentInstance instance) {
		List<ComponentInstance> componentInstanceChain =
				StatechartModelDerivedFeatures.getComponentInstanceChain(instance);
		return createInstanceReference(componentInstanceChain);
	}
	
	public ComponentInstanceReference createInstanceReference(ComponentInstance instance) {
		return createInstanceReference(List.of(instance));
	}
	
	public ComponentInstanceReference createInstanceReference(List<ComponentInstance> instances) {
		if (instances.isEmpty()) {
			throw new IllegalArgumentException("Empty instance list: " + instances);
		}
		ComponentInstanceReference reference = compositeFactory.createComponentInstanceReference();
		for (ComponentInstance instance : instances) {
			reference.setComponentInstance(instance);
			ComponentInstanceReference child = compositeFactory.createComponentInstanceReference();
			reference.setChild(child);
			reference = child;
		}
		ComponentInstanceReference head =
				StatechartModelDerivedFeatures.getFirstInstance(reference);
		ecoreUtil.remove(reference); // No instance
		return head;
	}
	
	public List<ComponentInstanceReference> prepend(
			Collection<? extends ComponentInstanceReference> references, ComponentInstance instance) {
		List<ComponentInstanceReference> newReferences = new ArrayList<ComponentInstanceReference>();
		for (ComponentInstanceReference reference : references) {
			ComponentInstanceReference newReference = prepend(reference, instance);
			newReferences.add(newReference);
		}
		return newReferences;
	}
	
	public ComponentInstanceReference prepend(
			ComponentInstanceReference reference, ComponentInstance instance) {
		ComponentInstanceReference newReference = createInstanceReference(instance);
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
			Declaration lhsVariable = expressionUtil.getReferredValues(lhs).iterator().next();
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
	
	public void extendTrigger(Transition transition, Trigger trigger, BinaryType type) {
		if (transition.getTrigger() == null) {
			transition.setTrigger(trigger);
		}
		else {
			BinaryTrigger binaryTrigger = createBinaryTrigger(
					transition.getTrigger(), trigger, type);
			transition.setTrigger(binaryTrigger);
		}
	}
	
	public BinaryTrigger createBinaryTrigger(Trigger oldTrigger,
			Trigger newTrigger, BinaryType type) {
		BinaryTrigger binaryTrigger = statechartFactory.createBinaryTrigger();
		binaryTrigger.setType(type);
		binaryTrigger.setLeftOperand(oldTrigger);
		binaryTrigger.setRightOperand(newTrigger);
		return binaryTrigger;
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
		return adapter;
	}
	
	public Package wrapIntoPackage(Component component) {
		Package _package = interfaceFactory.createPackage();
		_package.setName(component.getName().toLowerCase());
		_package.getComponents().add(component);
		return _package;
	}
	
	public ComponentInstance instantiateComponent(Component component) {
		if (component instanceof SynchronousComponent) {
			return instantiateSynchronousComponent((SynchronousComponent) component);
		}
		if (component instanceof AsynchronousComponent) {
			return instantiateAsynchronousComponent((AsynchronousComponent) component);
		}
		throw new IllegalArgumentException("Not known type" + component);
	}
	
	public SynchronousComponentInstance instantiateSynchronousComponent(SynchronousComponent component) {
		SynchronousComponentInstance instance = compositeFactory.createSynchronousComponentInstance();
		instance.setName(getWrapperInstanceName(component));
		instance.setType(component);
		return instance;
	}
	
	public AsynchronousComponentInstance instantiateAsynchronousComponent(AsynchronousComponent component) {
		AsynchronousComponentInstance instance = compositeFactory.createAsynchronousComponentInstance();
		instance.setName(getWrapperInstanceName(component));
		instance.setType(component);
		return instance;
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
		
		return asynchron;
	}

	private void wrapComponent(CompositeComponent wrapper, ComponentInstance instance) {
		Component component = StatechartModelDerivedFeatures.getDerivedType(instance);
		
		// Package annotation to denote the wrapping
		Package _package = StatechartModelDerivedFeatures.getContainingPackage(component);
		WrappedPackageAnnotation wrappedAnnotation = interfaceFactory.createWrappedPackageAnnotation();
		_package.getAnnotations().add(wrappedAnnotation);
		
		// Parameter declarations
		for (ParameterDeclaration parameterDeclaration : component.getParameterDeclarations()) {
			ParameterDeclaration newParameter = ecoreUtil.clone(parameterDeclaration);
			wrapper.getParameterDeclarations().add(newParameter);
			DirectReferenceExpression reference = expressionUtil
					.createReferenceExpression(newParameter);
			instance.getArguments().add(reference);
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
		String name = component.getName();
		// The same as in Namings.getComponentClassName
		return Character.toUpperCase(name.charAt(0)) + name.substring(1);
	}
	
	public SimpleChannel connectPortsViaChannels(SynchronousComponentInstance lhsInstance, Port lhsPort,
			SynchronousComponentInstance rhsInstance, Port rhsPort) {
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
	
	// Statechart element creators
	
	public Transition createTransition(StateNode source, StateNode target) {
		Transition transition = statechartFactory.createTransition();
		transition.setSourceState(source);
		transition.setTargetState(target);
		
		StatechartDefinition statechart = StatechartModelDerivedFeatures.getContainingStatechart(source);
		if (statechart != null) {
			statechart.getTransitions().add(transition);
		}
		return transition;
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
	
	public State createRegionWithState(CompositeElement compositeElement,
			String regionName, String initialStateName, String stateName) {
		InitialState initialState = statechartFactory.createInitialState();
		initialState.setName(initialStateName);
		return createRegionWithState(compositeElement,
				initialState, regionName, stateName);
	}
	
}