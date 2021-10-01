/********************************************************************************
 * Copyright (c) 2018-2021 Contributors to the Gamma project
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
import java.util.AbstractMap.SimpleEntry;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import java.util.stream.Collectors;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EStructuralFeature;
import org.eclipse.emf.ecore.util.EcoreUtil;

import hu.bme.mit.gamma.action.model.Action;
import hu.bme.mit.gamma.action.model.ActionModelPackage;
import hu.bme.mit.gamma.action.model.AssignmentStatement;
import hu.bme.mit.gamma.action.model.Branch;
import hu.bme.mit.gamma.action.model.ExpressionStatement;
import hu.bme.mit.gamma.action.util.ActionModelValidator;
import hu.bme.mit.gamma.expression.model.ArgumentedElement;
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition;
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition;
import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.ElseExpression;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression;
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelPackage;
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.RationalTypeDefinition;
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeDeclaration;
import hu.bme.mit.gamma.expression.model.TypeDefinition;
import hu.bme.mit.gamma.expression.model.TypeReference;
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
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference;
import hu.bme.mit.gamma.statechart.composite.CompositeComponent;
import hu.bme.mit.gamma.statechart.composite.CompositeModelPackage;
import hu.bme.mit.gamma.statechart.composite.ControlSpecification;
import hu.bme.mit.gamma.statechart.composite.InstancePortReference;
import hu.bme.mit.gamma.statechart.composite.MessageQueue;
import hu.bme.mit.gamma.statechart.composite.PortBinding;
import hu.bme.mit.gamma.statechart.composite.ScheduledAsynchronousCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.SimpleChannel;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponent;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.contract.AdaptiveContractAnnotation;
import hu.bme.mit.gamma.statechart.contract.ContractModelPackage;
import hu.bme.mit.gamma.statechart.contract.ScenarioContractAnnotation;
import hu.bme.mit.gamma.statechart.contract.StateContractAnnotation;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.AnyTrigger;
import hu.bme.mit.gamma.statechart.interface_.Clock;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Event;
import hu.bme.mit.gamma.statechart.interface_.EventDirection;
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression;
import hu.bme.mit.gamma.statechart.interface_.EventReference;
import hu.bme.mit.gamma.statechart.interface_.EventTrigger;
import hu.bme.mit.gamma.statechart.interface_.Interface;
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelPackage;
import hu.bme.mit.gamma.statechart.interface_.InterfaceRealization;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.interface_.Persistency;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.statechart.interface_.RealizationMode;
import hu.bme.mit.gamma.statechart.interface_.SimpleTrigger;
import hu.bme.mit.gamma.statechart.interface_.TimeSpecification;
import hu.bme.mit.gamma.statechart.interface_.Trigger;
import hu.bme.mit.gamma.statechart.phase.MissionPhaseStateAnnotation;
import hu.bme.mit.gamma.statechart.phase.MissionPhaseStateDefinition;
import hu.bme.mit.gamma.statechart.phase.PhaseModelPackage;
import hu.bme.mit.gamma.statechart.phase.VariableBinding;
import hu.bme.mit.gamma.statechart.statechart.AnyPortEventReference;
import hu.bme.mit.gamma.statechart.statechart.ChoiceState;
import hu.bme.mit.gamma.statechart.statechart.ClockTickReference;
import hu.bme.mit.gamma.statechart.statechart.EntryState;
import hu.bme.mit.gamma.statechart.statechart.ForkState;
import hu.bme.mit.gamma.statechart.statechart.JoinState;
import hu.bme.mit.gamma.statechart.statechart.MergeState;
import hu.bme.mit.gamma.statechart.statechart.OpaqueTrigger;
import hu.bme.mit.gamma.statechart.statechart.OrthogonalRegionSchedulingOrder;
import hu.bme.mit.gamma.statechart.statechart.PortEventReference;
import hu.bme.mit.gamma.statechart.statechart.PseudoState;
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction;
import hu.bme.mit.gamma.statechart.statechart.Region;
import hu.bme.mit.gamma.statechart.statechart.SchedulingOrder;
import hu.bme.mit.gamma.statechart.statechart.SetTimeoutAction;
import hu.bme.mit.gamma.statechart.statechart.State;
import hu.bme.mit.gamma.statechart.statechart.StateNode;
import hu.bme.mit.gamma.statechart.statechart.StateReferenceExpression;
import hu.bme.mit.gamma.statechart.statechart.StatechartAnnotation;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.statechart.statechart.StatechartModelPackage;
import hu.bme.mit.gamma.statechart.statechart.TimeoutDeclaration;
import hu.bme.mit.gamma.statechart.statechart.Transition;
import hu.bme.mit.gamma.statechart.statechart.TransitionIdAnnotation;
import hu.bme.mit.gamma.statechart.statechart.TransitionPriority;

public class StatechartModelValidator extends ActionModelValidator {
	// Singleton
	public static final StatechartModelValidator INSTANCE = new StatechartModelValidator();
	protected StatechartModelValidator() {
		super.typeDeterminator = ExpressionTypeDeterminator.INSTANCE; // For state reference
		super.expressionUtil = StatechartUtil.INSTANCE; // For getDeclaration
	}
	//
	
	// Some elements must have globally unique names

	public Collection<ValidationResultMessage> checkStateNameUniqueness(StatechartDefinition statechart) {
		List<State> states = ecoreUtil.getAllContentsOfType(statechart, State.class);
		return checkNameUniqueness(states);
	}
	
	public Collection<ValidationResultMessage> checkTransitionNameUniqueness(StatechartDefinition statechart) {
		List<TransitionIdAnnotation> transitionIdAnnotations = ecoreUtil.getAllContentsOfType(
				statechart, TransitionIdAnnotation.class);
		return checkNameUniqueness(transitionIdAnnotations);
	}
	
	// Not supported elements

	public Collection<ValidationResultMessage> checkComponentSepratation(Component component) {
		Package parentPackage = (Package) component.eContainer();
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		int index = parentPackage.getComponents().indexOf(component);
		if (!parentPackage.getInterfaces().isEmpty()) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
				"Components cannot be defined in package containing an interface", 
					new ReferenceInfo(InterfaceModelPackage.Literals.PACKAGE__COMPONENTS, index, parentPackage)));
		}
		if (!parentPackage.getTypeDeclarations().isEmpty()) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
				"Components cannot be defined in package containing a type declaration", 
					new ReferenceInfo(InterfaceModelPackage.Literals.PACKAGE__COMPONENTS, index, parentPackage)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkUnsupportedTriggers(OpaqueTrigger trigger) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "Not supported trigger", 
				new ReferenceInfo(StatechartModelPackage.Literals.OPAQUE_TRIGGER__TRIGGER)));
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkUnsupportedVariableTypes(VariableDeclaration variable) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Type type = variable.getType();
		if (type != null) {
			TypeDefinition typeDefinition = StatechartModelDerivedFeatures.getTypeDefinition(type);
			if (!(typeDefinition instanceof IntegerTypeDefinition ||
					typeDefinition instanceof BooleanTypeDefinition || 
					typeDefinition instanceof RationalTypeDefinition ||
					typeDefinition instanceof DecimalTypeDefinition ||
					typeDefinition instanceof EnumerationTypeDefinition ||
					typeDefinition instanceof ArrayTypeDefinition ||
					typeDefinition instanceof RecordTypeDefinition)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"This type is not supported in the statechart language", 
						new ReferenceInfo(ExpressionModelPackage.Literals.DECLARATION__TYPE)));
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkUnsupportedExpressionStatements(
			ExpressionStatement expressionStatement) {
		return Collections.singletonList(new ValidationResultMessage(ValidationResult.ERROR, 
				"Expression statements are not supported in the statechart language",
				new ReferenceInfo(ActionModelPackage.Literals.EXPRESSION_STATEMENT__EXPRESSION)));
	}
	
	// Expressions
	
	public Collection<ValidationResultMessage> checkArgumentTypes(ArgumentedElement element) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		List<ParameterDeclaration> parameterDeclarations = StatechartModelDerivedFeatures.getParameterDeclarations(element);
		validationResultMessages.addAll(super.checkArgumentTypes(element, parameterDeclarations));
		return validationResultMessages;
	}
	
	// Interfaces
	
	public Collection<ValidationResultMessage> checkInterfaceInheritance(Interface gammaInterface) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		for (Interface parent : gammaInterface.getParents()) {
			Interface parentInterface = getParentInterfaces(gammaInterface, parent);
			if (parentInterface != null) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"This interface is in a parent circle, referred by " + parentInterface.getName() +
						", but interfaces must have an acyclical parent hierarchy", 
						new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));
			}
		}
		return validationResultMessages;
	}
	
	private Interface getParentInterfaces(Interface initialInterface, Interface actualInterface) {
		if (initialInterface == actualInterface) {
			return initialInterface;
		}
		List<Interface> parents = actualInterface.getParents();
		for (Interface parent : parents) {
			if (parent == initialInterface) {
				return actualInterface;
			}
		}
		for (Interface parent : parents) {
			Interface parentInterface = getParentInterfaces(initialInterface, parent);
			if (parentInterface != null) {
				return parentInterface;
			}
		}
		return null;
	}
	
	public Collection<ValidationResultMessage> checkEventPersistency(Event event) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (event.getPersistency() == Persistency.PERSISTENT) {
			if (event.getParameterDeclarations().isEmpty()) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"A persistent event must have at least one parameter", 
						new ReferenceInfo(InterfaceModelPackage.Literals.EVENT__PERSISTENCY)));
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkParameterName(Event event) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (event.getParameterDeclarations().size() == 1) {
			final ParameterDeclaration parameterDeclaration = event.getParameterDeclarations().get(0);
			if (!parameterDeclaration.getName().equals(event.getName() + "Value")) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.INFO,
					"This parameter should be named " + event.getName() + "Value to be consistent with Yakindu",
						new ReferenceInfo(ExpressionModelPackage.Literals.PARAMETRIC_ELEMENT__PARAMETER_DECLARATIONS)));
			}
		}
		return validationResultMessages;
	}
	
	// Statechart adaptive contract
	
	public Collection<ValidationResultMessage> checkStateAnnotation(StateContractAnnotation annotation) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		StatechartDefinition statechart = StatechartModelDerivedFeatures.getContainingStatechart(annotation);
		List<StatechartAnnotation> statechartAnnotations = statechart.getAnnotations();
		if (!(statechartAnnotations.stream().filter(it->it instanceof AdaptiveContractAnnotation).findFirst().isPresent())) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
				"States with state contracts can be defined only in adaptive contract statecharts", 
					new ReferenceInfo(ContractModelPackage.Literals.STATE_CONTRACT_ANNOTATION__CONTRACT_STATECHARTS)));
			
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkStatechartAnnotation(AdaptiveContractAnnotation annotation) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Component component = StatechartModelDerivedFeatures.getContainingComponent(annotation);
		Component monitoredComponent = annotation.getMonitoredComponent();
		if (!StatechartModelDerivedFeatures.areInterfacesEqual(component, monitoredComponent)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
				"The contained ports of the monitored component are not equal to that of the adaptive statechart", 
					new ReferenceInfo(ContractModelPackage.Literals.ADAPTIVE_CONTRACT_ANNOTATION__MONITORED_COMPONENT)));
		}
		return validationResultMessages;
	}
	
	// Statechart mission phase
	
	public Collection<ValidationResultMessage> checkStateDefinition(MissionPhaseStateDefinition stateDefinition) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		SynchronousComponentInstance component = stateDefinition.getComponent();
		SynchronousComponent type = component.getType();
		if (!(type instanceof StatechartDefinition)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
				"Mission phase state definitions can refer only to statechart definitions as type", 
					new ReferenceInfo(CompositeModelPackage.Literals.SYNCHRONOUS_COMPONENT_INSTANCE__TYPE, component)));
			
		}
		List<VariableBinding> variableBindings = stateDefinition.getVariableBindings();
		for (int i = 0; i < variableBindings.size() - 1; i++) {
			VariableBinding lhs = variableBindings.get(i);
			VariableDeclaration lhsInstanceVariable = lhs.getInstanceVariableReference().getVariable();
			for (int j = i + 1; j < variableBindings.size(); j++) {
				VariableBinding rhs = variableBindings.get(j);
				VariableDeclaration rhsInstanceVariable = rhs.getInstanceVariableReference().getVariable();
				if (lhsInstanceVariable == rhsInstanceVariable) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"More than one statechart variable is bound to this instance variable", 
							new ReferenceInfo(PhaseModelPackage.Literals.VARIABLE_BINDING__INSTANCE_VARIABLE_REFERENCE, lhs)));
				}
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkVaraibleBindings(VariableBinding variableBinding) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		VariableDeclaration statechartVariable = variableBinding.getStatechartVariable();
		VariableDeclaration variable = variableBinding.getInstanceVariableReference().getVariable();
		validationResultMessages.addAll(checkTypeAndTypeConformance(statechartVariable.getType(), variable.getType(),
				PhaseModelPackage.Literals.VARIABLE_BINDING__INSTANCE_VARIABLE_REFERENCE));
		return validationResultMessages;
	}
	
	// Statechart
	
	public Collection<ValidationResultMessage> checkStatechartScheduling(StatechartDefinition statechart) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (statechart.getOrthogonalRegionSchedulingOrder() != OrthogonalRegionSchedulingOrder.SEQUENTIAL) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
				"Only the sequential scheduling of orthogonal regions is supported", 
					new ReferenceInfo(StatechartModelPackage.Literals.STATECHART_DEFINITION__ORTHOGONAL_REGION_SCHEDULING_ORDER)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkStateReference(StateReferenceExpression reference) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Region region = reference.getRegion();
		hu.bme.mit.gamma.statechart.statechart.State state = reference.getState();
		if (region != StatechartModelDerivedFeatures.getParentRegion(state)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
				"The state is not contained by this region", 
					new ReferenceInfo(StatechartModelPackage.Literals.STATE_REFERENCE_EXPRESSION__STATE)));
		}
		StatechartDefinition statechart = StatechartModelDerivedFeatures.getContainingStatechart(region);
		StateNode source = StatechartModelDerivedFeatures.getContainingOrSourceStateNode(reference);
		Region parentRegion = StatechartModelDerivedFeatures.getParentRegion(source);
		StatechartDefinition parentStatechart = StatechartModelDerivedFeatures.getContainingStatechart(parentRegion);
		if (statechart != parentStatechart) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
				"The referenced state must be in the same state machine component", 
					new ReferenceInfo(StatechartModelPackage.Literals.STATE_REFERENCE_EXPRESSION__STATE)));
		}
		if (region == parentRegion) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING, 
				"The referenced state should not be in the same region", 
					new ReferenceInfo(StatechartModelPackage.Literals.STATE_REFERENCE_EXPRESSION__STATE)));
		}
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkImports(Package _package) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Collection<Interface> usedInterfaces = new HashSet<Interface>();
		Collection<Component> usedComponents = new HashSet<Component>();
		Collection<TypeDeclaration> usedTypeDeclarations =
			ecoreUtil.getAllContentsOfType(EcoreUtil.getRootContainer(_package), TypeReference.class)
				.stream().map(it -> it.getReference()).collect(Collectors.toSet());

		Collection<EnumerationLiteralDefinition> usedEnumLiterals =
			ecoreUtil.getAllContentsOfType(EcoreUtil.getRootContainer(_package), EnumerationLiteralExpression.class)
				.stream().map(it -> it.getReference()).collect(Collectors.toSet());
		// Collecting the used components and interfaces
		for (Component component : _package.getComponents()) {
			for (Port port : component.getPorts()) {
				usedInterfaces.add(port.getInterfaceRealization().getInterface());
			}
			if (component instanceof CompositeComponent) {
				Collection<? extends ComponentInstance> derivedComponents = StatechartModelDerivedFeatures
						.getDerivedComponents((CompositeComponent) component);
				for (ComponentInstance componentInstance : derivedComponents) {
					usedComponents.add(StatechartModelDerivedFeatures.getDerivedType(componentInstance));
				}
			}
			if (component instanceof AsynchronousAdapter) {
				AsynchronousAdapter asynchronousAdapter = (AsynchronousAdapter) component;
				usedComponents.add(asynchronousAdapter.getWrappedComponent().getType());
			}
		}
		ecoreUtil.getAllContentsOfType(_package, AdaptiveContractAnnotation.class).stream()
			.forEach(it -> usedComponents.add(it.getMonitoredComponent()));
		ecoreUtil.getAllContentsOfType(_package, ScenarioContractAnnotation.class).stream()
			.forEach(it -> usedComponents.add(it.getMonitoredComponent()));
		ecoreUtil.getAllContentsOfType(_package, StateContractAnnotation.class).stream()
			.forEach(it -> usedComponents.addAll(it.getContractStatecharts()));
		for (MissionPhaseStateAnnotation annotation : ecoreUtil.getAllContentsOfType(
				_package, MissionPhaseStateAnnotation.class)) {
			for (MissionPhaseStateDefinition state : annotation.getStateDefinitions()) {
				usedComponents.add(state.getComponent().getType());
			}
		}
		// Checking the imports
		for (Package importedPackage : _package.getImports()) {
			Collection<Interface> interfaces = new HashSet<Interface>(importedPackage.getInterfaces());
			interfaces.retainAll(usedInterfaces);
			Collection<Component> components = new HashSet<Component>(importedPackage.getComponents());
			components.retainAll(usedComponents);
			Collection<TypeDeclaration> typeDeclarations = new HashSet<TypeDeclaration>(importedPackage.getTypeDeclarations());
			typeDeclarations.retainAll(usedTypeDeclarations);
			Collection<EnumerationLiteralDefinition> enumDefinitions = ecoreUtil.
					getAllContentsOfType(EcoreUtil.getRootContainer(importedPackage), EnumerationLiteralDefinition.class);
			enumDefinitions.retainAll(usedEnumLiterals);
			if (interfaces.isEmpty() && components.isEmpty() && typeDeclarations.isEmpty() && enumDefinitions.isEmpty()) {
				int index = _package.getImports().indexOf(importedPackage);
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING, 
					"No component or interface or type declaration from this imported package is used", 
						new ReferenceInfo(InterfaceModelPackage.Literals.PACKAGE__IMPORTS, index)));
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkRegionEntries(Region region) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		List<StateNode> entries = region.getStateNodes().stream()
				.filter(it -> it instanceof EntryState).collect(Collectors.toList());
		if (entries.isEmpty()) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
				"A region must have at least one entry node", 
					new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));
		}
		for (StateNode entry : entries) {
			Class<? extends StateNode> clazz = entry.getClass();
			long count = entries.stream().filter(it -> clazz.isInstance(it)).count();
			if (count > 1) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"A region must have at most one entry node of a certain type", 
						new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME, entry)));
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkUnusedDeclarations(Component component) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		
		List<Declaration> declarations = ecoreUtil.getAllContentsOfType(component, Declaration.class);
		
		Set<Declaration> usedDeclarations = new HashSet<Declaration>();		
		ecoreUtil.getAllContentsOfType(component, DirectReferenceExpression.class).stream()
				.map(it -> it.getDeclaration()).forEach(it -> usedDeclarations.add(it));
		ecoreUtil.getAllContentsOfType(component, VariableBinding.class).stream()
				.map(it -> it.getStatechartVariable()).forEach(it -> usedDeclarations.add(it));
		
		for (Declaration declaration : declarations) {
			if (!usedDeclarations.contains(declaration)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING, 
					"This declaration is unused", 
						new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME, declaration)));
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkUnusedTimeoutDeclarations(TimeoutDeclaration declaration) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Collection<SetTimeoutAction> timeoutSettings = ecoreUtil.getAllContentsOfType(
				ecoreUtil.getRoot(declaration), SetTimeoutAction.class).stream()
					.filter(it -> it.getTimeoutDeclaration() == declaration)
					.collect(Collectors.toSet());
		if (timeoutSettings.isEmpty()) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING, 
				"This declaration is not used", 
					new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));
		}
		if (timeoutSettings.size() > 1) {
			for (SetTimeoutAction timeoutSetting : timeoutSettings) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"This timeout declaration is set more than once", 
						new ReferenceInfo(StatechartModelPackage.Literals.TIMEOUT_ACTION__TIMEOUT_DECLARATION,
								timeoutSetting)));
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkTimeSpecifications(TimeSpecification timeSpecification) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		try {
			int value = expressionEvaluator.evaluateInteger(timeSpecification.getValue());
			if (value <= 0) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"Time specifications must have positive values: " + value, 
						new ReferenceInfo(InterfaceModelPackage.Literals.TIME_SPECIFICATION__VALUE)));
			}
		} catch (IllegalArgumentException e) {
			// Untransformable expression, it contains variable declarations
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkPortEventParameterReference(EventParameterReferenceExpression expression) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Port port = expression.getPort();
		Event event = expression.getEvent();
		if (event.getPersistency() == Persistency.TRANSIENT) {
			Transition transition = ecoreUtil.getContainerOfType(expression, Transition.class);
			if (transition != null) {
				Collection<Transition> transitions = StatechartModelDerivedFeatures.getSelfAndPrecedingTransitions(transition);
				// Only actual PortRventReferences are returned (no AnyPortEventReferences) even if they are in a NOT trigger
				Collection<PortEventReference> references =	StatechartModelDerivedFeatures.getPortEventReferences(transitions);
				if (references.stream().noneMatch(it -> it.getPort() == port && it.getEvent() == event)) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING,
						"None of the preceding transitions are triggered by this port-event combination", 
							new ReferenceInfo(InterfaceModelPackage.Literals.EVENT_PARAMETER_REFERENCE_EXPRESSION__EVENT)));
				}
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkTransitionPriority(Transition transition) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		StatechartDefinition statechart = StatechartModelDerivedFeatures.getContainingStatechart(transition);
		if (transition.getPriority() != null && !transition.getPriority().equals(BigInteger.ZERO) &&
				statechart.getTransitionPriority() != TransitionPriority.VALUE_BASED) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING,
				"The transition priority setting is not set to value-based, it is set to " + statechart.getTransitionPriority() +
					" therefore this priority specification has no effect",  
						new ReferenceInfo(CompositeModelPackage.Literals.PRIORITIZED_ELEMENT__PRIORITY)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkElseTransitionPriority(Transition transition) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (StatechartModelDerivedFeatures.isElse(transition)) {
			StatechartDefinition statechart = StatechartModelDerivedFeatures.getContainingStatechart(transition);
			TransitionPriority priority = statechart.getTransitionPriority();
			if (priority == TransitionPriority.ORDER_BASED) {
				StateNode source = transition.getSourceState();
				List<Transition> outgoingTransitions = StatechartModelDerivedFeatures.getOutgoingTransitions(source);
				int size = outgoingTransitions.size();
				if (outgoingTransitions.get(size - 1) != transition) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING,
						"This is an else transition, and its priority is bigger than some other transitions " +
						"going out of the same state, as the transition priority is set to " + TransitionPriority.ORDER_BASED,
							new ReferenceInfo(CompositeModelPackage.Literals.PRIORITIZED_ELEMENT__PRIORITY)));
				}
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkTransitionTriggers(Transition transition) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (!StatechartModelDerivedFeatures.needsTrigger(transition)) {
			return validationResultMessages;
		}
		if (transition.getTrigger() == null) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
				"This transition must have a trigger",  
					new ReferenceInfo(StatechartModelPackage.Literals.TRANSITION__TRIGGER)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkTransitionTriggers(ElseExpression elseExpression) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		EObject container = elseExpression.eContainer();
		if (!(container instanceof Transition) && !(container instanceof Branch)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
				"Else expressions must be atomic guards in the expression", 
					new ReferenceInfo(elseExpression.eContainingFeature(), container)));
		}
		if (container instanceof Transition) {
			Transition transition = (Transition) container;
			if (transition.getTrigger() != null) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"Else expressions cannot be used with triggers", 
						new ReferenceInfo(elseExpression.eContainingFeature(), container)));
			}
			StateNode node = transition.getSourceState();
			List<Transition> outgoingTransitions = StatechartModelDerivedFeatures.getOutgoingTransitions(node);
			outgoingTransitions.remove(transition);
			if (outgoingTransitions.stream().anyMatch(it -> it.getGuard() instanceof ElseExpression)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"Only a single transition with and else expression can go out of a certain node", 
						new ReferenceInfo(elseExpression.eContainingFeature(), container)));
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkTransitionEventTriggers(PortEventReference portEventReference) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		EObject eventTrigger = portEventReference.eContainer();
		if (eventTrigger instanceof EventTrigger) {
			Transition transition = ecoreUtil.getContainerOfType(eventTrigger, Transition.class);
			if (transition != null) {
				// If it is a transition trigger
				Port port = portEventReference.getPort();
				Event event = portEventReference.getEvent();
				List<Event> inputEvents = StatechartModelDerivedFeatures.getInputEvents(port);
				if (!inputEvents.contains(event)) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"This event is not an in event",
							new ReferenceInfo(StatechartModelPackage.Literals.PORT_EVENT_REFERENCE__EVENT)));
				}
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkTransitionGuards(Transition transition) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (transition.getGuard() != null) {
			Expression guard = transition.getGuard();
			if (!typeDeterminator.isBoolean(guard)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"This guard is not a boolean expression",
						new ReferenceInfo(StatechartModelPackage.Literals.TRANSITION__GUARD)));
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkTransitionEventRaisings(RaiseEventAction raiseEvent) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Port port = raiseEvent.getPort();
		Event event = raiseEvent.getEvent();
		List<ParameterDeclaration> parameterDeclarations = event.getParameterDeclarations();
		List<Expression> arguments = raiseEvent.getArguments();
		if (!StatechartModelDerivedFeatures.getOutputEvents(port).contains(event)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
				"This event is not an out event",
					new ReferenceInfo(StatechartModelPackage.Literals.RAISE_EVENT_ACTION__EVENT)));
			return validationResultMessages;
		}
		if (arguments.size() != parameterDeclarations.size()) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
				"The number of arguments must match the number of parameters", 
					new ReferenceInfo(ExpressionModelPackage.Literals.ARGUMENTED_ELEMENT__ARGUMENTS)));
			return validationResultMessages;
		}
		if (!arguments.isEmpty()) {
			EObject eContainer = raiseEvent.eContainer();
			for (EObject raiseEventObject : ecoreUtil.getContentsOfType(eContainer, RaiseEventAction.class).stream()
					.filter(it -> eContainer.eContents().indexOf(it) > eContainer.eContents().indexOf(raiseEvent))
					.collect(Collectors.toList())) {
				RaiseEventAction otherRaiseEvent = (RaiseEventAction) raiseEventObject;
				if (otherRaiseEvent.getPort() == raiseEvent.getPort() &&
						otherRaiseEvent.getEvent() == raiseEvent.getEvent() &&
						!otherRaiseEvent.getArguments().isEmpty()) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING, 
						"This event raise argument is overriden by other event raise arguments", 
							new ReferenceInfo(ExpressionModelPackage.Literals.ARGUMENTED_ELEMENT__ARGUMENTS)));
				}
			}
		}
		if (!arguments.isEmpty() && !parameterDeclarations.isEmpty()) {
			for (int i = 0; i < arguments.size() && i < parameterDeclarations.size(); ++i) {
				checkTypeAndExpressionConformance(parameterDeclarations.get(i).getType(), arguments.get(i),
						new ReferenceInfo(ExpressionModelPackage.Literals.ARGUMENTED_ELEMENT__ARGUMENTS, i));
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkNodeReachability(StateNode node) {
		// These nodes do not need incoming transitions
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (node instanceof EntryState) {
			return validationResultMessages;
		}
		if (!hasIncomingTransition(node) || (!StatechartModelDerivedFeatures.getIncomingTransitions(node).isEmpty()
				&& allTransitionsAreLoop(node))) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
				"This node is unreachable", 
					new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));
		}
		return validationResultMessages;
	}
	
	public boolean hasIncomingTransition(StateNode node) {
		boolean hasIncomingTransition = !StatechartModelDerivedFeatures.getIncomingTransitions(node).isEmpty();
		if (hasIncomingTransition) {
			return true;
		}
		// Checking child nodes of composite state node with incoming transitions 
		if (node instanceof hu.bme.mit.gamma.statechart.statechart.State) {
			hu.bme.mit.gamma.statechart.statechart.State stateNode = (hu.bme.mit.gamma.statechart.statechart.State) node;
			Set<StateNode> childNodes = new HashSet<StateNode>();
			stateNode.getRegions().stream()
				.map(it -> it.getStateNodes()).forEach(it -> childNodes.addAll(it));
			for (StateNode childNode : childNodes) {
				if (hasIncomingTransition(childNode)) {
					return true;
				}
			}
		}
		return false;
	}
	
	public boolean isLoopEdge(Transition transition) {
		return transition.getSourceState() == transition.getTargetState();
	}
	
	public boolean allTransitionsAreLoop(StateNode node) {
		Collection<Transition> incomingTransitions = StatechartModelDerivedFeatures.getIncomingTransitions(node);
		Collection<Transition> outgoingTransitions = StatechartModelDerivedFeatures.getOutgoingTransitions(node);
		if (incomingTransitions.size() != outgoingTransitions.size()) {
			return false;
		}
		incomingTransitions.removeAll(outgoingTransitions);
		if (!incomingTransitions.isEmpty()) {
			return false;
		}
		// The incoming and outgoing transitions are the same
		for (Transition outgoingTransition : outgoingTransitions) {
			if (!isLoopEdge(outgoingTransition)) {
				return false;
			}
		}
		return true;
	}
	
	public Collection<ValidationResultMessage> checkEntryNodes(EntryState entry) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Region parentRegion = StatechartModelDerivedFeatures.getParentRegion(entry);
		List<Transition> incomingTransitions = StatechartModelDerivedFeatures.getIncomingTransitions(entry);
		List<Transition> outgoingTransitions = StatechartModelDerivedFeatures.getOutgoingTransitions(entry);
		if (incomingTransitions.stream().map(it -> it.getSourceState()).anyMatch(it -> !(it instanceof EntryState) &&
				StatechartModelDerivedFeatures.getParentRegion(it) == parentRegion)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"Entry nodes must not have incoming transitions from non-entry nodes in the same region", 
					new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));
		}
		if (incomingTransitions.stream().map(it -> it.getSourceState()).anyMatch(it -> it instanceof EntryState &&
				StatechartModelDerivedFeatures.getParentRegion(it) != parentRegion)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"Entry nodes must not have incoming transitions from entry nodes in other regions", 
					new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));		
		}
		if (outgoingTransitions.size() != 1) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"Entry nodes must have a single outgoing transition", 
					new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));
		}
		else {
			// A single transition
			for (Transition transition : outgoingTransitions) {
				StateNode target = transition.getTargetState();
				if (StatechartModelDerivedFeatures.getParentRegion(target) != parentRegion) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"Transitions going out from entry nodes must be targeted to a node in the region of the entry node", 
							new ReferenceInfo(StatechartModelPackage.Literals.TRANSITION__TARGET_STATE, transition)));
				}
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkEntryNodeTransitions(Transition transition) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (!(transition.getSourceState() instanceof EntryState)) {
			return validationResultMessages;
		}
		if (transition.getTrigger() != null) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
				"Entry node transitions must not have triggers", 
					new ReferenceInfo(StatechartModelPackage.Literals.TRANSITION__TRIGGER)));
		}
		if (transition.getGuard() != null) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
				"Entry node transitions must not have guards", 
					new ReferenceInfo(StatechartModelPackage.Literals.TRANSITION__GUARD)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkPseudoNodeAcyclicity(PseudoState node) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		validationResultMessages.addAll(checkPseudoNodeAcyclicity(node, new HashSet<PseudoState>()));
		return validationResultMessages;
	}
	
	private Collection<ValidationResultMessage> checkPseudoNodeAcyclicity(PseudoState node, Set<PseudoState> visitedNodes) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		visitedNodes.add(node);
		for (Transition outgoingTransition : StatechartModelDerivedFeatures.getOutgoingTransitions(node)) {
			StateNode target = outgoingTransition.getTargetState();
			if (target instanceof PseudoState) {
				PseudoState pseudoState = (PseudoState) target;
				if (visitedNodes.contains(pseudoState)) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
							"This transition creates a circle of pseudo nodes, which is forbidden", 
							new ReferenceInfo(StatechartModelPackage.Literals.TRANSITION__TARGET_STATE, outgoingTransition)));
					return validationResultMessages;
				}
				visitedNodes.add(pseudoState);
				validationResultMessages.addAll(checkPseudoNodeAcyclicity(pseudoState, visitedNodes));
			}
			// Node is removed as only directed cycles are erroneous, indirected ones are permitted
			visitedNodes.remove(target);
		}
		// Node is removed as only directed cycles are erroneous, indirected ones are permitted
		visitedNodes.remove(node);
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkChoiceNodes(ChoiceState choice) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Collection<Transition> incomingTransitions = StatechartModelDerivedFeatures.getIncomingTransitions(choice);
		int incomingTransitionSize = incomingTransitions.size();
		if (incomingTransitionSize != 1) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
				"Choice nodes must have a single incoming transition", 
					new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));
		}
		Collection<Transition> outgoingTransitions = StatechartModelDerivedFeatures.getOutgoingTransitions(choice);
		int outgoingTransitionSize = outgoingTransitions.size();
		if (outgoingTransitionSize == 1) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING, 
				"Choice nodes should have at least two outgoing transitions", 
					new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));
		}
		else if (outgoingTransitionSize < 1) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
				"A choice node must have at least one outgoing transition", 
					new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkForkNodes(ForkState fork) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Collection<Transition> incomingTransitions = StatechartModelDerivedFeatures.getIncomingTransitions(fork);
		int incomingTransitionSize = incomingTransitions.size();
		if (incomingTransitionSize != 1) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"Fork nodes must have a single incoming transition", 
					new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));
		}
		Collection<Transition> outgoingTransitions = StatechartModelDerivedFeatures.getOutgoingTransitions(fork);
		int outgoingTransitionSize = outgoingTransitions.size();
		if (outgoingTransitionSize == 1) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING, 
					"Fork nodes must have a single incoming transition", 
					new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));
		}
		else if (outgoingTransitionSize < 1) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"A fork node must have at least one outgoing transition", 
					new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));
		}
		// Targets of fork nodes must always be in distinct regions
		Set<Region> targetedRegions = new HashSet<Region>();
		for (Transition transition : outgoingTransitions) {
			Region region = StatechartModelDerivedFeatures.getParentRegion(transition.getTargetState());
			if (targetedRegions.contains(region) || targetedRegions.stream().anyMatch(it -> 
					ecoreUtil.containsOneOtherTransitively(region, it))) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"Targets of outgoing transitions of fork nodes must be in distinct regions", 
						new ReferenceInfo(StatechartModelPackage.Literals.TRANSITION__TARGET_STATE, transition)));
			}
			else {
				targetedRegions.add(region);
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkMergeNodes(MergeState merge) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Collection<Transition> incomingTransitions = StatechartModelDerivedFeatures.getIncomingTransitions(merge);
		int incomingTransitionSize = incomingTransitions.size();
		if (incomingTransitionSize == 1) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING, 
					"Merge nodes should have at least two incoming transitions", 
					new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));
		}
		else if (incomingTransitionSize < 1) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"A merge node must have at least one incoming transition", 
					new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));
		}
		Collection<Transition> outgoingTransitions = StatechartModelDerivedFeatures.getOutgoingTransitions(merge);
		int outgoingTransitionSize = outgoingTransitions.size();
		if (outgoingTransitionSize != 1) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"Merge nodes must have a single outgoing transition", 
					new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkJoinNodes(JoinState join) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Collection<Transition> incomingTransitions = StatechartModelDerivedFeatures.getIncomingTransitions(join);
		int incomingTransitionSize = incomingTransitions.size();
		if (incomingTransitionSize == 1) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING, 
					"Join nodes should have at least two incoming transitions", 
					new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));
		}
		else if (incomingTransitionSize < 1) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"A join node must have at least one incoming transition", 
					new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));
		}
		Collection<Transition> outgoingTransitions = StatechartModelDerivedFeatures.getOutgoingTransitions(join);
		int outgoingTransitionSize = outgoingTransitions.size();
		if (outgoingTransitionSize != 1) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"Join nodes must have a single outgoing transition", 
					new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));
		}
		// Sources of join nodes must always be in distinct regions
		Set<Region> sourceRegions = new HashSet<Region>();
		for (Transition transition : incomingTransitions) {
			Region region = StatechartModelDerivedFeatures.getParentRegion(transition.getSourceState());
			if (sourceRegions.contains(region) || sourceRegions.stream().anyMatch(it -> 
					ecoreUtil.containsOneOtherTransitively(region, it))) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"Sources of incoming transitions of join nodes must be in distinct regions", 
						new ReferenceInfo(StatechartModelPackage.Literals.TRANSITION__TARGET_STATE, transition)));
			}
			else {
				sourceRegions.add(region);
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkPseudoNodeTransitions(Transition transition) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		StateNode source = transition.getSourceState();
		StateNode target = transition.getTargetState();
		if (source instanceof ChoiceState) {
			if (transition.getTrigger() == null && transition.getGuard() == null) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING, 
					"Transitions from choice nodes should have a trigger or a guard if deterministic behavior is expected", 
						new ReferenceInfo(StatechartModelPackage.Literals.TRANSITION__GUARD)));
			}
		}
		if (source instanceof ForkState) {
			if (transition.getTrigger() != null) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"Transitions from fork nodes must not have triggers", 
						new ReferenceInfo(StatechartModelPackage.Literals.TRANSITION__TRIGGER)));
				
			}
			if (transition.getGuard() != null) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"Transitions from fork nodes must not have guards", 
						new ReferenceInfo(StatechartModelPackage.Literals.TRANSITION__GUARD)));
			}
		}
		if (source instanceof MergeState) {
			if (transition.getTrigger() != null) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"Transitions from merge nodes must not have triggers", 
						new ReferenceInfo(StatechartModelPackage.Literals.TRANSITION__TRIGGER)));
				
			}
			if (transition.getGuard() != null) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"Transitions from merge nodes must not have guards", 
						new ReferenceInfo(StatechartModelPackage.Literals.TRANSITION__GUARD)));
			}
		}
		if (source instanceof JoinState) {
			if (transition.getTrigger() != null) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"Transitions from join nodes must not have triggers", 
						new ReferenceInfo(StatechartModelPackage.Literals.TRANSITION__TRIGGER)));
			}
			if (transition.getGuard() != null) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"Transitions from join nodes must not have guards", 
						new ReferenceInfo(StatechartModelPackage.Literals.TRANSITION__GUARD)));
			}
		}
		if (target instanceof JoinState) {
			if (!(source instanceof PseudoState) &&	!transition.getEffects().isEmpty()) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"Transitions targeted to join nodes must not have actions", 
						new ReferenceInfo(StatechartModelPackage.Literals.TRANSITION__EFFECTS)));
			}
		}
		if ((source instanceof EntryState || source instanceof ChoiceState ||
				source instanceof ForkState) && target instanceof JoinState) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
				"Transitions cannot connect entry, choice or fork states to join states", 
					new ReferenceInfo(StatechartModelPackage.Literals.TRANSITION__TARGET_STATE)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkTimeoutTransitions(
			hu.bme.mit.gamma.statechart.statechart.State state) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		boolean multipleTimedTransitions = StatechartModelDerivedFeatures.getOutgoingTransitions(state).stream()
			.filter(it -> it.getTrigger() instanceof EventTrigger && 
				((EventTrigger) it.getTrigger()).getEventReference() instanceof ClockTickReference &&
				it.getGuard() == null).count() > 1;
		if (multipleTimedTransitions) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"This state has multiple transitions with occluding timing specifications", 
					new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkOutgoingTransitionDeterminism(Transition transition) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		StateNode sourceState = transition.getSourceState();
		Collection<Transition> siblingTransitions = StatechartModelDerivedFeatures.getOutgoingTransitions(sourceState).stream()
				.filter(it -> it != transition).collect(Collectors.toSet());
		Transition nonDeterministicTransition = checkTransitionDeterminism(transition, siblingTransitions);
		if (nonDeterministicTransition != null) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING, 
				"This transitions is in a non-deterministic relation with other transitions from the same source", 
					new ReferenceInfo(StatechartModelPackage.Literals.TRANSITION__TRIGGER)));
		}
		return validationResultMessages;
	}
	
	public Transition checkTransitionDeterminism(Transition transition, Collection<Transition> transitions) {
		Trigger potentialTrigger = transition.getTrigger();
		if (transition.getGuard() != null || !(potentialTrigger instanceof EventTrigger) ||
			(!(((EventTrigger) potentialTrigger).getEventReference() instanceof PortEventReference) &&
			!(((EventTrigger) potentialTrigger).getEventReference() instanceof AnyPortEventReference))) {
			return null;
		}
		EventTrigger trigger = (EventTrigger) potentialTrigger;
		EventReference eventReference = trigger.getEventReference();
		if (eventReference instanceof PortEventReference) {
			PortEventReference portEventReference = (PortEventReference) eventReference;
			for (Transition siblingTransition : transitions) {
				if (isTransitionTriggeredByPortEvent(
						siblingTransition, portEventReference.getPort(), portEventReference.getEvent())) {
					return siblingTransition;
				}
			}
		}
		else if (eventReference instanceof AnyPortEventReference) {
			AnyPortEventReference portEventReference = (AnyPortEventReference) eventReference;
			for (Transition siblingTransition : transitions) {
				if (isTransitionTriggeredByPortEvent(siblingTransition, portEventReference.getPort())) {
					return siblingTransition;
				}
			}
		}
		return null;
	}
	
	public boolean isTransitionTriggeredByPortEvent(Transition transition, Port port, Event event) {
		Trigger trigger = transition.getTrigger();
		if (trigger instanceof EventTrigger) {
			EventTrigger eventTrigger = (EventTrigger) trigger;
			if (eventTrigger.getEventReference() instanceof PortEventReference) {
				PortEventReference candidateEventReference = (PortEventReference) eventTrigger.getEventReference();
				if (candidateEventReference.getPort() == port && candidateEventReference.getEvent() == event) {
					return true;
				}
			}
			else if (eventTrigger.getEventReference() instanceof AnyPortEventReference) {
				AnyPortEventReference candidateEventReference = (AnyPortEventReference) eventTrigger.getEventReference();
				if (candidateEventReference.getPort() == port) {
					return true;
				}
			}
		}
		return false;
	}
	
	public boolean isTransitionTriggeredByPortEvent(Transition transition, Port port) {
		if (transition.getTrigger() instanceof EventTrigger) {
			EventTrigger eventTrigger = (EventTrigger) transition.getTrigger();
			if (eventTrigger.getEventReference() instanceof PortEventReference) {
				PortEventReference candidateEventReference = (PortEventReference) eventTrigger.getEventReference();
				if (candidateEventReference.getPort() == port) {
					return true;
				}
			}
			else if (eventTrigger.getEventReference() instanceof AnyPortEventReference) {
				AnyPortEventReference candidateEventReference = (AnyPortEventReference) eventTrigger.getEventReference();
				if (candidateEventReference.getPort() == port) {
					return true;
				}
			}
		}
		return false;
	}
	
	public Collection<ValidationResultMessage> checkTransitionOcclusion(Transition transition) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		StateNode sourceState = transition.getSourceState();
		Collection<Transition> parentTransitions = getOutgoingTransitionsOfAncestors(sourceState);
		Transition nonDeterministicTransition = checkTransitionDeterminism(transition, parentTransitions);
		StatechartDefinition statechart = (StatechartDefinition) nonDeterministicTransition.eContainer(); 
		if (nonDeterministicTransition != null && 
				statechart.getSchedulingOrder() == SchedulingOrder.TOP_DOWN) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING, 
					"This transitions is occluded by a higher level transition", 
					new ReferenceInfo(StatechartModelPackage.Literals.TRANSITION__TRIGGER)));
		}
		return validationResultMessages;
	}
	
	public Collection<Transition> getOutgoingTransitionsOfAncestors(StateNode source) {
		EObject parentContainer = source.eContainer().eContainer();
		if (parentContainer instanceof hu.bme.mit.gamma.statechart.statechart.State) {
			hu.bme.mit.gamma.statechart.statechart.State parentState = (hu.bme.mit.gamma.statechart.statechart.State) parentContainer;
			Collection<Transition> transitions = StatechartModelDerivedFeatures.getOutgoingTransitions(parentState);
			transitions.addAll(getOutgoingTransitionsOfAncestors(parentState));
			return transitions;
		}
		return new HashSet<Transition>();
	}
	
	public Collection<ValidationResultMessage> checkParallelTransitionAssignments(Transition transition) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Transition sameTriggerParallelTransition = getSameTriggedTransitionOfParallelRegions(transition);
		Declaration declaration = getSameVariableOfAssignments(transition, sameTriggerParallelTransition);
		if (declaration != null) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING, 
				"Both this and transition between " + sameTriggerParallelTransition.getSourceState().getName() + 
					" and " + sameTriggerParallelTransition.getTargetState().getName() + " assigns value to variable " + declaration.getName(),
					new ReferenceInfo(StatechartModelPackage.Literals.TRANSITION__EFFECTS)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkParallelEventRaisings(Transition transition) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Transition sameTriggerParallelTransition = getSameTriggedTransitionOfParallelRegions(transition);
		Entry<Port, Event> portEvent = getSameEventOfParameteredRaisings(transition, sameTriggerParallelTransition);
		if (portEvent != null) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING, 
				"Both this and transition between " + sameTriggerParallelTransition.getSourceState().getName() + 
					" and " + sameTriggerParallelTransition.getTargetState().getName() + " raises the same event " +
					portEvent.getValue().getName() + " with potentionally overwriting parameters", 
						new ReferenceInfo(StatechartModelPackage.Literals.TRANSITION__EFFECTS)));
		}
		return validationResultMessages;
	}
	
	public Transition getSameTriggedTransitionOfParallelRegions(Transition transition) {
		StateNode sourceState = transition.getSourceState();
		Region parentRegion = (Region) sourceState.eContainer();
		if (parentRegion.eContainer() instanceof hu.bme.mit.gamma.statechart.statechart.State) {
			hu.bme.mit.gamma.statechart.statechart.State parentState = (hu.bme.mit.gamma.statechart.statechart.State) parentRegion.eContainer();
			Collection<Region> siblingRegions = new HashSet<Region>(parentState.getRegions());
			siblingRegions.remove(parentRegion);
			Collection<Transition> parallelTransitions = getTransitionsOfSiblingRegions(siblingRegions);
			return checkTransitionDeterminism(transition, parallelTransitions);
		}
		return null;
	}
	
	public Collection<Transition> getTransitionsOfSiblingRegions(Collection<Region> siblingRegions) {
		Collection<Transition> siblingTransitions = new HashSet<Transition>();
		siblingRegions.stream().map(it -> it.getStateNodes()).forEach(it -> it.stream()
				.map(node -> StatechartModelDerivedFeatures.getOutgoingTransitions(node))
				.forEach(sibling -> siblingTransitions.addAll(sibling)));
		return siblingTransitions;
	}
	
	public Declaration getSameVariableOfAssignments(Transition lhs, Transition rhs) {
		for (Action action : lhs.getEffects()) {
			if (action instanceof AssignmentStatement) {
				AssignmentStatement assignment = (AssignmentStatement) action;
				if (assignment.getLhs() instanceof DirectReferenceExpression) {
					DirectReferenceExpression reference = (DirectReferenceExpression) assignment.getLhs();
					Declaration declaration = reference.getDeclaration();
					for (Action rhsAction: rhs.getEffects()) {
						if (rhsAction instanceof AssignmentStatement) {
							AssignmentStatement rhsAssignment = (AssignmentStatement) rhsAction;
							if (rhsAssignment.getLhs() instanceof DirectReferenceExpression) {
								DirectReferenceExpression rhsReference = (DirectReferenceExpression) rhsAssignment.getLhs();
								if (rhsReference.getDeclaration() == declaration) {
									return declaration;
								}
							}
						}
					}
				}
			}
		}
		return null;
	}
	
	public Entry<Port, Event> getSameEventOfParameteredRaisings(Transition lhs, Transition rhs) {
		for (Action action : lhs.getEffects()) {
			if (action instanceof RaiseEventAction) {
				RaiseEventAction lhsRaiseEvent = (RaiseEventAction) action;
				for (Action raiseEvent : rhs.getEffects().stream().filter(it -> it instanceof RaiseEventAction)
						.collect(Collectors.toSet())) {
					RaiseEventAction rhsRaiseEvent = (RaiseEventAction) raiseEvent;
					if (lhsRaiseEvent.getPort() == rhsRaiseEvent.getPort() && 
						lhsRaiseEvent.getEvent() == rhsRaiseEvent.getEvent()) {
						if (!lhsRaiseEvent.getArguments().isEmpty() && !rhsRaiseEvent.getArguments().isEmpty()) {
							return new SimpleEntry<Port, Event>(lhsRaiseEvent.getPort(), lhsRaiseEvent.getEvent());
						}
					}
				}
			}
		}
		return null;
	}
	
	public Collection<ValidationResultMessage> checkTransitionOrientation(Transition transition) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (StatechartModelDerivedFeatures.isSameRegion(transition) ||
				StatechartModelDerivedFeatures.isToLower(transition) ||
				StatechartModelDerivedFeatures.isToHigher(transition) || 
				StatechartModelDerivedFeatures.isToHigherAndLower(transition)) {
			// These transitions are permitted
			return validationResultMessages;
		}
		validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
			"The orientation of this transition is incorrect as the source and target are in orthogonal regions", 
				new ReferenceInfo(StatechartModelPackage.Literals.TRANSITION__SOURCE_STATE)));
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkTimeSpecification(TimeSpecification timeSpecification) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (!typeDeterminator.isInteger(timeSpecification.getValue())) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"Time values must be of type integer", 
					new ReferenceInfo(InterfaceModelPackage.Literals.TIME_SPECIFICATION__VALUE)));
		}
		return validationResultMessages;
	}
	
	// Composite system
	
	public Collection<ValidationResultMessage> checkName(Package _package) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (!_package.getName().toLowerCase().equals(_package.getName())) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.INFO, 
					"Package names in the generated code will not contain uppercase letters", 
					new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));
		}
		return validationResultMessages;
	}
	
	
	public Collection<ValidationResultMessage> checkCircularDependencies(Package statechart) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		for (Package referredStatechart : statechart.getImports()) {
			Package parentStatechart = getReferredPackages(statechart, referredStatechart);
			if (parentStatechart != null) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"This statechart is in a dependency circle, referred by " + parentStatechart.getName() +
						", composite systems must have an acyclical dependency hierarchy",
						new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));
			}
		}
		return validationResultMessages;
	}
	
	public Package getReferredPackages(Package initialStatechart, Package statechart) {
		for (Package referredStatechart : statechart.getImports()) {
			if (referredStatechart == initialStatechart) {
				return statechart;
			}
		}
		for (Package referredStatechart : statechart.getImports()) {
			Package parentStatechart = getReferredPackages(initialStatechart, referredStatechart);
			if (parentStatechart != null) {
				return parentStatechart;
			}
		}
		return null;
	}
	
	public Collection<ValidationResultMessage> checkMultipleImports(Package gammaPackage) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Set<Package> importedPackages = new HashSet<Package>();
		importedPackages.add(gammaPackage);
		for (Package importedPackage : gammaPackage.getImports()) {
			if (importedPackages.contains(importedPackage)) {
				int index = gammaPackage.getImports().indexOf(importedPackage);
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING, 
						"Package " + importedPackage.getName() + " is already imported",
						new ReferenceInfo(InterfaceModelPackage.Literals.PACKAGE__IMPORTS, index)));
			}
			importedPackages.add(importedPackage);
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkParameters(ComponentInstance instance) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Component type = StatechartModelDerivedFeatures.getDerivedType(instance);
		if (instance.getArguments().size() != type.getParameterDeclarations().size()) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"The number of arguments is wrong", 
					new ReferenceInfo(ExpressionModelPackage.Literals.ARGUMENTED_ELEMENT__ARGUMENTS)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkComponentInstanceArguments(ComponentInstance instance) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		try {
			Component type = StatechartModelDerivedFeatures.getDerivedType(instance);
			List<ParameterDeclaration> parameters = type.getParameterDeclarations();
			for (int i = 0; i < parameters.size(); ++i) {
				ParameterDeclaration parameter = parameters.get(i);
				Expression argument = instance.getArguments().get(i);
				Type declarationType = parameter.getType();
				if (!typeDeterminator.equalsType(declarationType, argument)) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"The types of the declaration and the right hand side expression are not the same: " +
							typeDeterminator.print(declarationType) + " and " + typeDeterminator.print(argument),
							new ReferenceInfo(ExpressionModelPackage.Literals.ARGUMENTED_ELEMENT__ARGUMENTS, i)));
				} 
			}
		} catch (Exception exception) {
			// There is a type error on a lower level, no need to display the error message on this level too
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkPortBinding(Port port) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Component container = (Component) port.eContainer();
		if (container instanceof CompositeComponent) {
			CompositeComponent componentDefinition = (CompositeComponent) container;
			for (PortBinding portDefinition : componentDefinition.getPortBindings()) {
				if (portDefinition.getCompositeSystemPort() == port) {
					return validationResultMessages;
				}
			}
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING, 
					"This system port is not connected to any ports of an instance",
					new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkComponentInstances(ComponentInstance instance) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Component type = StatechartModelDerivedFeatures.getContainingComponent(instance);
		String name = instance.getName();
		if (name.startsWith("_") || name.endsWith("_")) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
				"A Gamma instance identifier cannot start or end with an '_' underscore character", 
					new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));
			return validationResultMessages;
		}
		EObject container = instance.eContainer();
		if (type instanceof AsynchronousAdapter || !(container instanceof CompositeComponent)) {
			// Not checking AsynchronousAdapters or port bindings not contained by CompositeComponents
			return validationResultMessages;
		}
		Collection<Port> unusedPorts = StatechartModelDerivedFeatures.getUnusedPorts(instance);
		if (!unusedPorts.isEmpty()) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING, 
				"The following ports are used neither in a system port binding nor a channel: " +
					unusedPorts.stream().map(it -> it.getName()).collect(Collectors.toSet()),
					new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkPortBindingUniqueness(PortBinding portBinding) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Port systemPort = portBinding.getCompositeSystemPort();
		Port instancePort = portBinding.getInstancePortReference().getPort();
		ComponentInstance instance = portBinding.getInstancePortReference().getInstance();
		EObject container = portBinding.eContainer();
		List<PortBinding> portBindings = ecoreUtil.getContentsOfType(container, PortBinding.class);
		if (!StatechartModelDerivedFeatures.getOutputEvents(systemPort).isEmpty() && // Valid for only input ports
				portBindings.stream().filter(it -> it.getCompositeSystemPort() == systemPort).count() > 1) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"This system port is connected to multiple ports of instances",
					new ReferenceInfo(CompositeModelPackage.Literals.PORT_BINDING__COMPOSITE_SYSTEM_PORT)));
		}
		if (portBindings.stream().filter(it -> it.getInstancePortReference().getPort() == instancePort &&
				it.getInstancePortReference().getInstance() == instance).count() > 1) {
			// Erroneous even for broadcast ports as "outwards" port binding should be trivial (single path)
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
				"Multiple system ports are connected to the port of this instance",
					new ReferenceInfo(CompositeModelPackage.Literals.PORT_BINDING__INSTANCE_PORT_REFERENCE)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkPortBinding(PortBinding portDefinition) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		InterfaceRealization compositeInterfaceRealization = portDefinition.getCompositeSystemPort().getInterfaceRealization();
		InterfaceRealization instanceInterfaceRealization = portDefinition.getInstancePortReference().getPort().getInterfaceRealization();
		RealizationMode systemPortIT = compositeInterfaceRealization.getRealizationMode();
		RealizationMode instancePortIT = instanceInterfaceRealization.getRealizationMode();
		Interface systemPortIf = compositeInterfaceRealization.getInterface();
		Interface instancePortIf = instanceInterfaceRealization.getInterface(); 
		if (systemPortIT != instancePortIT) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
				"Ports can be connected only if their interface types match and this is not realized in this case: " +
					systemPortIT.getName() + " -> " + instancePortIT.getName(),
					new ReferenceInfo(CompositeModelPackage.Literals.PORT_BINDING__INSTANCE_PORT_REFERENCE)));
		}	
		if (systemPortIf != instancePortIf) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
				"Ports can be connected only if their interfaces match and this is not realized in this case: " + 
					systemPortIf.getName() + " -> " + instancePortIf.getName(),
					new ReferenceInfo(CompositeModelPackage.Literals.PORT_BINDING__INSTANCE_PORT_REFERENCE)));
		}	
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkInstancePortReference(InstancePortReference reference) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		ComponentInstance instance = reference.getInstance();
		if (instance == null) {
			return validationResultMessages;
		}
		Port port = reference.getPort();
		Component type = StatechartModelDerivedFeatures.getDerivedType(instance);
		Collection<Port> ports = StatechartModelDerivedFeatures.getAllPorts(type);
		if (!ports.contains(port)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"The specified port is not on instance " + instance.getName(),
					new ReferenceInfo(CompositeModelPackage.Literals.INSTANCE_PORT_REFERENCE__PORT)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkPortBindingWithSimpleChannel(SimpleChannel channel) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		EObject root = EcoreUtil.getRootContainer(channel);
		Collection<PortBinding> portDefinitions = ecoreUtil.getAllContentsOfType(root, PortBinding.class);
		for (PortBinding portDefinition : portDefinitions) {
			// Broadcast ports can be used in multiple places
			InstancePortReference providedPort = channel.getProvidedPort();
			if (!StatechartModelDerivedFeatures.isBroadcast(providedPort.getPort()) && StatechartModelDerivedFeatures.equals(
					providedPort, portDefinition.getInstancePortReference())) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"A port of an instance can be included either in a channel or a port binding",
						new ReferenceInfo(CompositeModelPackage.Literals.CHANNEL__PROVIDED_PORT)));
			}
			if (StatechartModelDerivedFeatures.equals(channel.getRequiredPort(), portDefinition.getInstancePortReference())) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"A port of an instance can be included either in a channel or a port binding",
						new ReferenceInfo(CompositeModelPackage.Literals.SIMPLE_CHANNEL__REQUIRED_PORT)));
			}
		}			
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkPortBindingWithBroadcastChannel(BroadcastChannel channel) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		EObject root = EcoreUtil.getRootContainer(channel);
		Collection<PortBinding> portDefinitions = ecoreUtil.getAllContentsOfType(root, PortBinding.class);
		for (PortBinding portDefinition : portDefinitions) {
			for (InstancePortReference output : channel.getRequiredPorts()) {
				if (StatechartModelDerivedFeatures.equals(output, portDefinition.getInstancePortReference())) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
							"A port of an instance can be included either in a channel or a port binding",
							new ReferenceInfo(CompositeModelPackage.Literals.BROADCAST_CHANNEL__REQUIRED_PORTS)));
				}
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkChannelProvidedPorts(Channel channel) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Component parentComponent = (Component) channel.eContainer();
		// Ports inside asynchronous components can be connected to multiple ports
		if (parentComponent instanceof AbstractAsynchronousCompositeComponent) {
			return validationResultMessages;
		}
		// Checking provided instance ports in different channels
		EObject root = EcoreUtil.getRootContainer(channel);
		Collection<InstancePortReference> instancePortReferences = ecoreUtil.
				getAllContentsOfType(root, InstancePortReference.class);
		for (InstancePortReference instancePortReference : instancePortReferences.stream()
						.filter(it -> it != channel.getProvidedPort() && it.eContainer() instanceof Channel)
						.collect(Collectors.toList())) {
			// Broadcast ports are also restricted to be used only in a single channel (restriction on syntax only)
			if (StatechartModelDerivedFeatures.equals(instancePortReference, channel.getProvidedPort())) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"A port of an instance can be included only in a single channel",
						new ReferenceInfo(CompositeModelPackage.Literals.CHANNEL__PROVIDED_PORT)));
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkChannelRequiredPorts(SimpleChannel channel) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Component parentComponent = (Component) channel.eContainer();
		// Ports inside asynchronous components can be connected to multiple ports
		if (parentComponent instanceof AbstractAsynchronousCompositeComponent) {
			return validationResultMessages;
		}
		EObject root = EcoreUtil.getRootContainer(channel);
		Collection<InstancePortReference> instancePortReferences = ecoreUtil.
				getAllContentsOfType(root, InstancePortReference.class);
		// Checking required instance ports in different simple channels
		for (InstancePortReference instancePortReference : instancePortReferences.stream()
				.filter(it -> it != channel.getRequiredPort() && it.eContainer() instanceof Channel)
				.collect(Collectors.toList())) {
			if (StatechartModelDerivedFeatures.equals(instancePortReference, channel.getRequiredPort())) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"A port of an instance can be included only in a single channel",
						new ReferenceInfo(CompositeModelPackage.Literals.SIMPLE_CHANNEL__REQUIRED_PORT)));
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkChannelRequiredPorts(BroadcastChannel channel) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Component parentComponent = (Component) channel.eContainer();
		// Ports inside asynchronous components can be connected to multiple ports
		if (parentComponent instanceof AbstractAsynchronousCompositeComponent) {
			return validationResultMessages;
		}
		EObject root = EcoreUtil.getRootContainer(channel);
		Collection<InstancePortReference> instancePortReferences = ecoreUtil.
				getAllContentsOfType(root, InstancePortReference.class);
		// Checking required instance ports in different broadcast channels
		for (InstancePortReference instancePortReference : instancePortReferences.stream()
				.filter(it -> it.eContainer() != channel && it.eContainer() instanceof Channel)
				.collect(Collectors.toList())) {
			for (InstancePortReference requiredPort : channel.getRequiredPorts()) {
				if (StatechartModelDerivedFeatures.equals(instancePortReference, requiredPort)) {
					int index = channel.getRequiredPorts().indexOf(requiredPort);
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
							"A port of an instance can be included only in a single channel",
							new ReferenceInfo(CompositeModelPackage.Literals.BROADCAST_CHANNEL__REQUIRED_PORTS, index)));
				}
			}
		}
		// Checking required instance ports in the same broadcast channel
		for (InstancePortReference requiredPort : channel.getRequiredPorts()) {
			for (InstancePortReference requiredPort2 : channel.getRequiredPorts().stream()
					.filter(it -> it != requiredPort && it.eContainer() instanceof Channel).collect(Collectors.toList())) {
				if (StatechartModelDerivedFeatures.equals(requiredPort2, requiredPort)) {
					int index = channel.getRequiredPorts().indexOf(requiredPort2);
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"A port of an instance can be included only in a single channel",
							new ReferenceInfo(CompositeModelPackage.Literals.BROADCAST_CHANNEL__REQUIRED_PORTS, index)));
				}
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkChannelInput(Channel channel) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (!(channel.getProvidedPort().getPort().getInterfaceRealization().getRealizationMode() == RealizationMode.PROVIDED)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"A port providing an interface is needed here",
					new ReferenceInfo(CompositeModelPackage.Literals.CHANNEL__PROVIDED_PORT)));
		} 
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkSimpleChannelOutput(SimpleChannel channel) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (channel.getRequiredPort().getPort().getInterfaceRealization().getRealizationMode() != RealizationMode.REQUIRED) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"A port requiring an interface is needed here",
					new ReferenceInfo(CompositeModelPackage.Literals.SIMPLE_CHANNEL__REQUIRED_PORT)));
		}
		// Checking the interfaces
		Interface providedInterface = channel.getProvidedPort().getPort().getInterfaceRealization().getInterface();
		Interface requiredInterface = channel.getRequiredPort().getPort().getInterfaceRealization().getInterface();
		if (providedInterface != requiredInterface) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
				"Ports connected with a channel must have the same interface and " + 
					"this is not realized in this case: the provided interface: " + providedInterface.getName() +
						", the required interface: " + requiredInterface.getName(), 
					new ReferenceInfo(CompositeModelPackage.Literals.SIMPLE_CHANNEL__REQUIRED_PORT)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkBroadcastChannelOutput(BroadcastChannel channel) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (!StatechartModelDerivedFeatures.isBroadcast(channel.getProvidedPort().getPort()) &&
				!(channel.eContainer() instanceof AsynchronousComponent)) {
			// Asynchronous components can have two-way broadcast channels 
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"A port providing a broadcast interface is needed here",
					new ReferenceInfo(CompositeModelPackage.Literals.CHANNEL__PROVIDED_PORT)));
		}
		for (InstancePortReference output : channel.getRequiredPorts()) {
			if (output.getPort().getInterfaceRealization().getRealizationMode() != RealizationMode.REQUIRED) {
				int index = channel.getRequiredPorts().indexOf(output);
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"A port requiring an interface is needed here",
						new ReferenceInfo(CompositeModelPackage.Literals.BROADCAST_CHANNEL__REQUIRED_PORTS, index)));
			}
			Interface requiredInterface = output.getPort().getInterfaceRealization().getInterface();
			Interface providedInterface = channel.getProvidedPort().getPort().getInterfaceRealization().getInterface();
			if (providedInterface != requiredInterface) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"Ports connected with a broadcast channel must have the same interface and " +
						"this is not realized in this case: the provided interface: " + 
						providedInterface.getName() + ", the required interface: " + requiredInterface.getName(), 
						new ReferenceInfo(CompositeModelPackage.Literals.BROADCAST_CHANNEL__REQUIRED_PORTS)));
			}
		}
		return validationResultMessages;
	}
	
	
	public Collection<ValidationResultMessage> checkCascadeLoopChannels(Channel channel) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		ComponentInstance instance = channel.getProvidedPort().getInstance();
		Component type = StatechartModelDerivedFeatures.getDerivedType(instance);
		List<InstancePortReference> requiredPorts = StatechartModelDerivedFeatures.getRequiredPorts(channel);
		if (type instanceof AbstractSynchronousCompositeComponent &&
				requiredPorts.stream().anyMatch(it -> it.getInstance() == instance)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING, 
					"Verification cannot be executed if different ports of a synchronous component are connected", 
					new ReferenceInfo(CompositeModelPackage.Literals.CHANNEL__PROVIDED_PORT)));
		}
		return validationResultMessages;
	}
	
	// Asynchronous adapter
	
	public Collection<ValidationResultMessage> checkWrapperPortName(Port port) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (port.eContainer() instanceof AsynchronousAdapter) {
			AsynchronousAdapter adapter = (AsynchronousAdapter) port.eContainer();
			String portName = port.getName();
			if (adapter.getWrappedComponent().getType().getPorts().stream().anyMatch(it -> it.getName().equals(portName))) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"This port enshadows a port in the wrapped synchronous component", 
						new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkWrapperClock(Clock clock) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		AsynchronousAdapter adapter = ecoreUtil.getContainerOfType(clock, AsynchronousAdapter.class);
		if (!StatechartModelDerivedFeatures.isStoredInMessageQueue(clock, adapter)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"Ticks of this clock are not forwarded to any messages queues", 
					new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkAsynchronousAdapterMultipleEventContainment(AsynchronousAdapter wrapper) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Map<Port, Collection<Event>> containedEvents = new HashMap<Port, Collection<Event>>();
		for (MessageQueue queue : wrapper.getMessageQueues()) {
			for (EventReference eventReference : queue.getEventReference()) {
				int index = queue.getEventReference().indexOf(eventReference);
				if (eventReference instanceof PortEventReference) {
					PortEventReference portEventReference = (PortEventReference) eventReference;
					Port containedPort = portEventReference.getPort();
					Event containedEvent = portEventReference.getEvent();
					if (containedEvents.containsKey(containedPort)) {
						Collection<Event> alreadyContainedEvents = containedEvents.get(containedPort);
						if (alreadyContainedEvents.contains(containedEvent)) {
							validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
									"Event " + containedEvent.getName() + " is already forwarded to a message queue", 
									new ReferenceInfo(CompositeModelPackage.Literals.CHANNEL__PROVIDED_PORT, index, queue)));
						}
						else {
							alreadyContainedEvents.add(containedEvent);
						}
					}
					else {
						Collection<Event> events = new HashSet<Event>();
						events.add(containedEvent);
						containedEvents.put(containedPort, events);
					}
				}
				if (eventReference instanceof AnyPortEventReference) {
					AnyPortEventReference anyPortEventReference = (AnyPortEventReference) eventReference;
					Port containedPort = anyPortEventReference.getPort();
					Collection<Event> events = StatechartModelDerivedFeatures.getInputEvents(containedPort);
					if (containedEvents.containsKey(containedPort)) {
						Collection<Event> alreadyContainedEvents = containedEvents.get(containedPort);
						alreadyContainedEvents.addAll(events);
						Collection<String> alreadyContainedEventNames = alreadyContainedEvents.stream()
								.map(it -> it.getName())
								.collect(Collectors.toSet());
						validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
								"Events " + alreadyContainedEventNames + " are already forwarded to a message queue", 
								new ReferenceInfo(CompositeModelPackage.Literals.MESSAGE_QUEUE__EVENT_REFERENCE, index, queue)));
					}
					else {
						containedEvents.put(containedPort, events);
					}
				}
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkInputPossibility(AsynchronousAdapter wrapper) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (wrapper.getControlSpecifications().isEmpty() && wrapper.getClocks().isEmpty()) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING, 
					"This asynchronous adapter can never be executed",
					new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkWrappedPort(AsynchronousAdapter wrapper) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		for (Port port : StatechartModelDerivedFeatures.getAllPorts(wrapper)) {
			for (Event event : StatechartModelDerivedFeatures.getInputEvents(port)) {
				Entry<Port, Event> portEvent = new SimpleEntry<Port, Event>(port, event);
				int count = StatechartModelDerivedFeatures.countAssignedMessageQueues(portEvent, wrapper);
				if (count != 1) {
					ValidationResult result = (count < 1) ? ValidationResult.WARNING : ValidationResult.ERROR;
					validationResultMessages.add(new ValidationResultMessage(result, 
						"Event " + event.getName() + " of port " + port.getName() +
							" is not forwarded to a single message queue but to " + count,
						new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));
				}
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkControlSpecification(ControlSpecification controlSpecification) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		SimpleTrigger trigger = controlSpecification.getTrigger();
		if (trigger instanceof EventTrigger) {
			EventTrigger eventTrigger = (EventTrigger) trigger;
			EventReference eventReference = eventTrigger.getEventReference();
			// Checking out-events
			if (eventReference instanceof PortEventReference) {
				PortEventReference portEventReference = (PortEventReference) eventReference;
				Port containedPort = portEventReference.getPort();
				Event containedEvent = portEventReference.getEvent();
				List<Event> outputEvents = StatechartModelDerivedFeatures.getOutputEvents(containedPort);
				if (outputEvents.stream().filter(it ->
						StatechartModelDerivedFeatures.getContainingEventDeclaration(it).getDirection() != EventDirection.INOUT
					).anyMatch(it -> it == containedEvent)) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"Event " + containedEvent.getName() + " is an out event and can not be used in a control specification", 
							new ReferenceInfo(CompositeModelPackage.Literals.CONTROL_SPECIFICATION__TRIGGER)));
				}
			}	 
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkMessageQueuePriorities(AsynchronousAdapter wrapper) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Set<Integer> priorityValues = new HashSet<Integer>();
		for (int i = 0; i < wrapper.getMessageQueues().size(); ++i) {
			MessageQueue queue = wrapper.getMessageQueues().get(i);
			int priorityValue = queue.getPriority().intValue();
			if (priorityValues.contains(priorityValue)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING, 
					"Another queue with the same priority is already defined", 
						new ReferenceInfo(CompositeModelPackage.Literals.PRIORITIZED_ELEMENT__PRIORITY, queue)));
			}
			else {
				priorityValues.add(priorityValue);
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkMessageQueue(MessageQueue queue) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		List<EventReference> eventReferences = queue.getEventReference();
		for (EventReference eventReference : eventReferences) {
			int index = queue.getEventReference().indexOf(eventReference);
			// Checking out-events
			if (eventReference instanceof PortEventReference) {
				PortEventReference portEventReference = (PortEventReference) eventReference;
				Port containedPort = portEventReference.getPort();
				Event containedEvent = portEventReference.getEvent();
				List<Event> outputEvents = StatechartModelDerivedFeatures.getOutputEvents(containedPort);
				if (outputEvents.stream().filter(it ->
						StatechartModelDerivedFeatures.getContainingEventDeclaration(it).getDirection() != EventDirection.INOUT
					).anyMatch(it -> it == containedEvent)) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"Event " + containedEvent.getName() + " is an out event and can not be forwarded to a message queue", 
							new ReferenceInfo(CompositeModelPackage.Literals.MESSAGE_QUEUE__EVENT_REFERENCE, index)));
				}
			}			
		}
		
		Expression messageRetrievalCount = queue.getMessageRetrievalCount();
		if (messageRetrievalCount != null) {
			int count = expressionEvaluator.evaluateInteger(messageRetrievalCount);
			if (count < 1) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"Message retrieval count must not be less than 1", 
						new ReferenceInfo(CompositeModelPackage.Literals.MESSAGE_QUEUE__MESSAGE_RETRIEVAL_COUNT)));
			}
			Expression capacityExpression = queue.getCapacity(); 
			int capacity = expressionEvaluator.evaluateInteger(capacityExpression);
			if (capacity < count) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"Message retrieval count must be less than or equals to the capacity", 
							new ReferenceInfo(CompositeModelPackage.Literals.MESSAGE_QUEUE__MESSAGE_RETRIEVAL_COUNT)));
			}
		}
		
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkAnyPortControls(AsynchronousAdapter adapter) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Map<Port, Collection<Event>> usedEvents = new HashMap<Port, Collection<Event>>();
		for (ControlSpecification controlSpecification : adapter.getControlSpecifications()) {
			Trigger trigger = controlSpecification.getTrigger();
			int index =	adapter.getControlSpecifications().indexOf(controlSpecification);
			if (trigger instanceof AnyTrigger) {
				if (adapter.getControlSpecifications().size() > 1) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"This control specification with any trigger enshadows all other control specifications",
							new ReferenceInfo(CompositeModelPackage.Literals.ASYNCHRONOUS_ADAPTER__CONTROL_SPECIFICATIONS, index, adapter)));
					return validationResultMessages;
				}
			}
			if (trigger instanceof EventTrigger) {
				EventTrigger eventTrigger = (EventTrigger) trigger;
				EventReference eventReference = eventTrigger.getEventReference();
				if (eventReference instanceof AnyPortEventReference) {
					AnyPortEventReference anyPortEventReference = (AnyPortEventReference) eventReference;
					Port port = anyPortEventReference.getPort();
					Collection<Event> portEvents = StatechartModelDerivedFeatures.getInputEvents(port);
					if (usedEvents.containsKey(port)) {
						validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"This control specification with any port trigger enshadows all control specifications with reference to the same port",
								new ReferenceInfo(CompositeModelPackage.Literals.ASYNCHRONOUS_ADAPTER__CONTROL_SPECIFICATIONS, index, adapter)));
						Collection<Event> containedEvents = usedEvents.get(port);
						containedEvents.addAll(portEvents);
					}
					else {
						usedEvents.put(port, portEvents);
					}
				}
				else if (eventReference instanceof PortEventReference) {
					PortEventReference portEventReference = (PortEventReference) eventReference;
					Port port = portEventReference.getPort();
					Event event = portEventReference.getEvent();
					if (usedEvents.containsKey(port)) {
						Collection<Event> containedEvents = usedEvents.get(port);
						if (containedEvents.contains(event)) {
							validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
								"This control specification with port event trigger has the same effect as some previous control specification",
									new ReferenceInfo(CompositeModelPackage.Literals.ASYNCHRONOUS_ADAPTER__CONTROL_SPECIFICATIONS, index, adapter)));
						}
						else {
							containedEvents.add(event);
						}
					}
					else {
						Collection<Event> events = new HashSet<Event>();
						events.add(event);
						usedEvents.put(port, events);
					}
				}
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkMessageRetrievalCount(AsynchronousAdapter adapter) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		
		List<ControlSpecification> controlSpecifications = adapter.getControlSpecifications();
		List<MessageQueue> messageQueues = adapter.getMessageQueues();
		if (messageQueues.size() == 1) {
			MessageQueue messageQueue = messageQueues.get(0);
			Expression messageRetrievalCount = messageQueue.getMessageRetrievalCount();
			if (messageRetrievalCount != null) {
				int count = expressionEvaluator.evaluateInteger(messageRetrievalCount);
				if (count == 1) {
					if (controlSpecifications.stream().noneMatch(it -> it.getTrigger() instanceof AnyTrigger)) {
						validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING,
							"Some messages might not be processed during execution as the message retrieval count is 1, "
									+ "but there is no any trigger among the control specifications",
								new ReferenceInfo(CompositeModelPackage.Literals.ASYNCHRONOUS_ADAPTER__MESSAGE_QUEUES)));
					}
				}
			}
		}
		
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkMessageQueueAnyEventReferences(AnyPortEventReference anyPortEventReference) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (anyPortEventReference.eContainer() instanceof MessageQueue &&
				StatechartModelDerivedFeatures.isBroadcast(anyPortEventReference.getPort())) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"There are no events coming in through this port", 
					new ReferenceInfo(StatechartModelPackage.Literals.ANY_PORT_EVENT_REFERENCE__PORT)));
		}
		return validationResultMessages;
		
	}
	
	public Collection<ValidationResultMessage> checkExecutionLists(CascadeCompositeComponent cascade) {
		List<SynchronousComponentInstance> components = cascade.getComponents();
		List<ComponentInstanceReference> executionList = cascade.getExecutionList();
		
		return checkExecutionList(components, executionList,
				CompositeModelPackage.Literals.CASCADE_COMPOSITE_COMPONENT__EXECUTION_LIST);
	}
	
	public Collection<ValidationResultMessage> checkExecutionLists(
			ScheduledAsynchronousCompositeComponent scheduledComponent) {
		List<AsynchronousComponentInstance> components = scheduledComponent.getComponents();
		List<ComponentInstanceReference> executionList = scheduledComponent.getExecutionList();
		
		return checkExecutionList(components, executionList,
				CompositeModelPackage.Literals.SCHEDULED_ASYNCHRONOUS_COMPOSITE_COMPONENT__EXECUTION_LIST);
	}
	
	private Collection<ValidationResultMessage> checkExecutionList(
			List<? extends ComponentInstance> components,
			List<? extends ComponentInstanceReference> executionList, EStructuralFeature reference) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();

		if (executionList.isEmpty()) {
			// Nothing to validate
			return validationResultMessages;
		}
		Collection<ComponentInstance> containedInstances = new HashSet<ComponentInstance>(components);
		for (ComponentInstanceReference instanceReference : executionList) {
			ComponentInstance instance = instanceReference.getComponentInstance();
			if (!components.contains(instance)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					instance.getName() + " is not a contained component", new ReferenceInfo(reference)));
			}
			if (!StatechartModelDerivedFeatures.isAtomic(instanceReference)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					instance.getName() + " is not an atomic component", new ReferenceInfo(reference)));
			}
			
			containedInstances.remove(instance);
		}
		if (!containedInstances.isEmpty()) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
				"The following instances are never executed: " + containedInstances.stream()
					.map(it -> it.getName()).collect(Collectors.toList()), new ReferenceInfo(reference)));
		}
		
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkComponents(
			ScheduledAsynchronousCompositeComponent scheduledComponent) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		
		List<AsynchronousComponentInstance> components = scheduledComponent.getComponents();
		for (AsynchronousComponentInstance component : components) {
			AsynchronousComponent type = component.getType();
			if (!(type instanceof ScheduledAsynchronousCompositeComponent ||
					type instanceof AsynchronousAdapter)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"Scheduled asynchronous composite components cannot contain asynchronous components",
						new ReferenceInfo(
							CompositeModelPackage.Literals.ABSTRACT_ASYNCHRONOUS_COMPOSITE_COMPONENT__COMPONENTS,
								ecoreUtil.getIndex(component))));
			}
		}
		
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkComponentInstanceReferences(ComponentInstanceReference reference) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		
		ComponentInstance instance = reference.getComponentInstance();
		ComponentInstanceReference child = reference.getChild();
		if (child != null) {
			ComponentInstance childInstance = child.getComponentInstance();
			if (!StatechartModelDerivedFeatures.contains(instance, childInstance)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					instance.getName() + " does not contain component instance " + childInstance.getName(),
						new ReferenceInfo(CompositeModelPackage.Literals.COMPONENT_INSTANCE_REFERENCE__COMPONENT_INSTANCE)));
			}
		}
		
		return validationResultMessages;
	}
	
}