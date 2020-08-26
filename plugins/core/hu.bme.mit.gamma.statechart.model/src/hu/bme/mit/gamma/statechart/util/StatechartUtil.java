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
import java.util.Set;

import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.action.model.AssignmentStatement;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.expression.util.ExpressionUtil;
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponent;
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.composite.CascadeCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.composite.CompositeModelFactory;
import hu.bme.mit.gamma.statechart.composite.InstancePortReference;
import hu.bme.mit.gamma.statechart.composite.PortBinding;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponent;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.interface_.Component;
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

public class StatechartUtil extends ExpressionUtil {
	// Singleton
	public static final StatechartUtil INSTANCE = new StatechartUtil();
	protected StatechartUtil() {}
	//

	protected InterfaceModelFactory interfaceFactory = InterfaceModelFactory.eINSTANCE;
	protected StatechartModelFactory statechartFactory = StatechartModelFactory.eINSTANCE;
	protected CompositeModelFactory compositeFactory = CompositeModelFactory.eINSTANCE;
	
	public Set<VariableDeclaration> getWrittenVariables(EObject object) {
		Set<VariableDeclaration> variables = new HashSet<VariableDeclaration>();
		for (AssignmentStatement assignmentStatement :
				ecoreUtil.getSelfAndAllContentsOfType(object, AssignmentStatement.class)) {
			Declaration declaration = assignmentStatement.getLhs().getDeclaration();
			if (declaration instanceof VariableDeclaration) {
				variables.add((VariableDeclaration) declaration);
			}
		}
		return variables;
	}
	
	public Set<VariableDeclaration> getReadVariables(EObject object) {
		Set<VariableDeclaration> variables = new HashSet<VariableDeclaration>();
		for (ReferenceExpression referenceExpression :
				ecoreUtil.getSelfAndAllContentsOfType(object, ReferenceExpression.class)) {
			if (!(referenceExpression.eContainer() instanceof AssignmentStatement)) {
				Declaration declaration = referenceExpression.getDeclaration();
				if (declaration instanceof VariableDeclaration) {
					variables.add((VariableDeclaration) declaration);
				}
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
			ReferenceExpression reference = factory.createReferenceExpression();
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
