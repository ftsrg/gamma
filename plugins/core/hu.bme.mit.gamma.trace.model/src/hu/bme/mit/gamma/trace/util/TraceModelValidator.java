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
package hu.bme.mit.gamma.trace.util;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import org.eclipse.emf.ecore.util.EcoreUtil;

import hu.bme.mit.gamma.expression.model.ArgumentedElement;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.statechart.composite.AsynchronousCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.CompositeModelPackage;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponent;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Event;
import hu.bme.mit.gamma.statechart.interface_.EventDeclaration;
import hu.bme.mit.gamma.statechart.interface_.EventDirection;
import hu.bme.mit.gamma.statechart.interface_.RealizationMode;
import hu.bme.mit.gamma.statechart.statechart.State;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.statechart.statechart.StatechartModelPackage;
import hu.bme.mit.gamma.statechart.util.StatechartModelValidator;
import hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures;
import hu.bme.mit.gamma.trace.model.ComponentSchedule;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.trace.model.InstanceSchedule;
import hu.bme.mit.gamma.trace.model.InstanceState;
import hu.bme.mit.gamma.trace.model.InstanceStateConfiguration;
import hu.bme.mit.gamma.trace.model.InstanceVariableState;
import hu.bme.mit.gamma.trace.model.RaiseEventAct;
import hu.bme.mit.gamma.trace.model.Step;
import hu.bme.mit.gamma.trace.model.TraceModelPackage;

public class TraceModelValidator extends StatechartModelValidator {
	// Singleton
	public static final TraceModelValidator INSTANCE = new TraceModelValidator();
	protected TraceModelValidator() {}
	//
	
	public Collection<ValidationResultMessage> checkArgumentTypes(ArgumentedElement element) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		List<ParameterDeclaration> parameters = TraceModelDerivedFeatures.getParameterDeclarations(element);
		validationResultMessages.addAll(super.checkArgumentTypes(element, parameters));
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkRaiseEventAct(RaiseEventAct raiseEventAct) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Step step = ecoreUtil.getContainerOfType(raiseEventAct, Step.class);
		RealizationMode realizationMode = raiseEventAct.getPort().getInterfaceRealization().getRealizationMode();
		Event event = raiseEventAct.getEvent();
		EventDirection eventDirection = ecoreUtil.getContainerOfType(event, EventDeclaration.class).getDirection();
		if (step.getActions().contains(raiseEventAct)) {
			// It should be an in event
			if (realizationMode == RealizationMode.PROVIDED && eventDirection == EventDirection.OUT ||
				realizationMode == RealizationMode.REQUIRED && eventDirection == EventDirection.IN) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"This event is an out-event of the component",
						new ReferenceInfo(StatechartModelPackage.Literals.RAISE_EVENT_ACTION__EVENT)));
			}			
		}
		else {
			// It should be an out event
			if (realizationMode == RealizationMode.PROVIDED && eventDirection == EventDirection.IN ||
				realizationMode == RealizationMode.REQUIRED && eventDirection == EventDirection.OUT) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"This event is an in-event of the component",
						new ReferenceInfo(StatechartModelPackage.Literals.RAISE_EVENT_ACTION__EVENT)));
			}			
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkInstanceState(InstanceState instanceState) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		ComponentInstanceReferenceExpression instanceReference = TraceModelDerivedFeatures.getInstanceReference(instanceState);
		ComponentInstance instance = StatechartModelDerivedFeatures.getLastInstance(instanceReference);
		if (!StatechartModelDerivedFeatures.isStatechart(instance)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
				"This is not a statechart instance",
					new ReferenceInfo(instanceState)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkInstanceStateConfiguration(
			InstanceStateConfiguration configuration) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		SynchronousComponentInstance instance = (SynchronousComponentInstance)
				StatechartModelDerivedFeatures.getLastInstance(configuration.getInstance());
		SynchronousComponent type = instance.getType();
		if (type instanceof StatechartDefinition) {
			State state = configuration.getState();
			List<State> states =  ecoreUtil.getAllContentsOfType(type,
					hu.bme.mit.gamma.statechart.statechart.State.class);
			if (!states.contains(state)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"This is not a valid state in the specified statechart",
						new ReferenceInfo(CompositeModelPackage.Literals.COMPONENT_INSTANCE_STATE_REFERENCE_EXPRESSION__STATE)));
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkInstanceVariableState(InstanceVariableState variableState) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		ComponentInstanceVariableReferenceExpression variableReference = variableState.getVariableReference();
		ComponentInstanceReferenceExpression instanceReference = variableReference.getInstance();
		ComponentInstance instance = StatechartModelDerivedFeatures.getLastInstance(instanceReference);
		Component type = StatechartModelDerivedFeatures.getDerivedType(instance);
		if (type instanceof StatechartDefinition) {
			VariableDeclaration variable = variableReference.getVariableDeclaration();
			StatechartDefinition statechartDefinition = (StatechartDefinition) type;
			List<VariableDeclaration> variables = statechartDefinition.getVariableDeclarations();
			if (!variables.contains(variable)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"This is not a valid variable in the specified statechart",
						new ReferenceInfo(TraceModelPackage.Literals.INSTANCE_VARIABLE_STATE__VARIABLE_REFERENCE)));
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkInstanceSchedule(InstanceSchedule schedule) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		ExecutionTrace executionTrace = (ExecutionTrace)EcoreUtil.getRootContainer(schedule, true);
		Component component = executionTrace.getComponent();
		if (component != null) {
			if (!(component instanceof AsynchronousCompositeComponent)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"Instance scheduling is valid only if the component is an asynchronous composite component",
						new ReferenceInfo(TraceModelPackage.Literals.INSTANCE_SCHEDULE__SCHEDULED_INSTANCE)));
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkInstanceSchedule(ComponentSchedule schedule) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Step step = ecoreUtil.getContainerOfType(schedule, Step.class);
		ExecutionTrace executionTrace = ecoreUtil.getContainerOfType(step, ExecutionTrace.class);
		Component component = executionTrace.getComponent();
		if (component != null) {
			if (component instanceof AsynchronousCompositeComponent) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"Global component scheduling is not valid if the component is an asynchronous composite component",
						new ReferenceInfo(TraceModelPackage.Literals.STEP__ACTIONS, ecoreUtil.getIndex(schedule), step)));
			}
		}
		return validationResultMessages;
	}
	
}
