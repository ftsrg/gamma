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

import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.action.model.AssignmentStatement;
import hu.bme.mit.gamma.action.util.ActionUtil;
import hu.bme.mit.gamma.expression.model.AccessExpression;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.expression.util.ExpressionUtil;
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponent;
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.composite.CascadeCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference;
import hu.bme.mit.gamma.statechart.composite.CompositeModelFactory;
import hu.bme.mit.gamma.statechart.composite.InstancePortReference;
import hu.bme.mit.gamma.statechart.composite.PortBinding;
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
import hu.bme.mit.gamma.statechart.statechart.BinaryTrigger;
import hu.bme.mit.gamma.statechart.statechart.BinaryType;
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

	public Declaration getDeclaration(Expression expression) {
		if (expression instanceof EventParameterReferenceExpression) {
			EventParameterReferenceExpression reference = (EventParameterReferenceExpression) expression;
			Declaration declaration = reference.getParameter();
			return declaration;
		}
		return super.getDeclaration(expression);
	}
	
	public ComponentInstanceReference createInstanceReference(ComponentInstance instance) {
		ComponentInstanceReference instanceReference = compositeFactory.createComponentInstanceReference();
		instanceReference.getComponentInstanceHierarchy().addAll(
				StatechartModelDerivedFeatures.getComponentInstanceChain(instance));
		return instanceReference;
	}
	
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
		return isDefinitelyFalseExpression(clonedGuard);
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
		cascade.setName(component.getName()); // Trick: same name, so reflective api will work
		SynchronousComponentInstance instance = compositeFactory.createSynchronousComponentInstance();
		instance.setName(getWrapperInstanceName(component));
		instance.setType(component);
		for (ParameterDeclaration parameterDeclaration : component.getParameterDeclarations()) {
			ParameterDeclaration newParameter = ecoreUtil.clone(parameterDeclaration, true, true);
			cascade.getParameterDeclarations().add(newParameter);
			DirectReferenceExpression reference = factory.createDirectReferenceExpression();
			reference.setDeclaration(newParameter);
			instance.getArguments().add(reference);
		}
		cascade.getComponents().add(instance);
		EList<Port> ports = component.getPorts();
		for (int i = 0; i < ports.size(); ++i) {
			Port port = ports.get(i);
			Port clonedPort = ecoreUtil.clone(port, true, true);
			cascade.getPorts().add(clonedPort);
			PortBinding portBinding = compositeFactory.createPortBinding();
			portBinding.setCompositeSystemPort(clonedPort);
			InstancePortReference instancePortReference = compositeFactory.createInstancePortReference();
			instancePortReference.setInstance(instance);
			instancePortReference.setPort(port);
			portBinding.setInstancePortReference(instancePortReference);
			cascade.getPortBindings().add(portBinding);
		}
		return cascade;
	}
	
	public String getWrapperInstanceName(Component component) {
		String name = component.getName();
		// The same as in Namings.getComponentClassName
		return Character.toUpperCase(name.charAt(0)) + name.substring(1);
	}
	
}
