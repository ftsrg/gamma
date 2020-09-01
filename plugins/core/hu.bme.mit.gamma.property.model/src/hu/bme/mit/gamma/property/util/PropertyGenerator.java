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
package hu.bme.mit.gamma.property.util;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;

import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.expression.model.AndExpression;
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression;
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition;
import hu.bme.mit.gamma.expression.model.EqualityExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.property.model.CommentableStateFormula;
import hu.bme.mit.gamma.property.model.ComponentInstanceEventParameterReference;
import hu.bme.mit.gamma.property.model.ComponentInstanceEventReference;
import hu.bme.mit.gamma.property.model.ComponentInstanceStateConfigurationReference;
import hu.bme.mit.gamma.property.model.ComponentInstanceVariableReference;
import hu.bme.mit.gamma.property.model.PropertyModelFactory;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.property.model.StateFormula;
import hu.bme.mit.gamma.statechart.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference;
import hu.bme.mit.gamma.statechart.composite.CompositeModelFactory;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Event;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction;
import hu.bme.mit.gamma.statechart.statechart.Region;
import hu.bme.mit.gamma.statechart.statechart.State;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.statechart.statechart.Transition;
import hu.bme.mit.gamma.statechart.util.ExpressionSerializer;
import hu.bme.mit.gamma.statechart.util.StatechartUtil;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class PropertyGenerator {
	// Single component reference or the whole chain is needed
	// That is, we reference the model AFTER or BEFORE the unfolding 
	protected boolean isSimpleComponentReference;
	//
	protected final PropertyUtil propertyUtil = PropertyUtil.INSTANCE;
	protected final StatechartUtil statechartUtil = StatechartUtil.INSTANCE;
	protected final ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE;
	protected final ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE;
	protected final CompositeModelFactory compositeFactory = CompositeModelFactory.eINSTANCE;
	protected final PropertyModelFactory factory = PropertyModelFactory.eINSTANCE;
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	
	public PropertyGenerator(boolean isSimpleComponentReference) {
		this.isSimpleComponentReference = isSimpleComponentReference;
	}
	
	public PropertyPackage initializePackage(Component component) {
		PropertyPackage propertyPackage = factory.createPropertyPackage();
		
		Package _package = StatechartModelDerivedFeatures.getContainingPackage(component);
		
		propertyPackage.getImport().add(_package);
		propertyPackage.setComponent(component);
		
		return propertyPackage;
	}
	
	public List<CommentableStateFormula> createStateReachability(
			Collection<SynchronousComponentInstance> instances) {
		List<CommentableStateFormula> formulas = new ArrayList<CommentableStateFormula>();
		for (SynchronousComponentInstance instance : instances) {
			Component type = instance.getType();
			if (type instanceof StatechartDefinition) {
				StatechartDefinition statechart = (StatechartDefinition) type;
				for (State state : StatechartModelDerivedFeatures.getAllStates(statechart)) {
					ComponentInstanceStateConfigurationReference stateReference =
							factory.createComponentInstanceStateConfigurationReference();
					final Region parentRegion = StatechartModelDerivedFeatures.getParentRegion(state);
					stateReference.setInstance(createInstanceReference(instance));
					stateReference.setRegion(parentRegion);
					stateReference.setState(state);
					StateFormula stateFormula = propertyUtil.createEF(
						propertyUtil.createAtomicFormula(stateReference));
					
					CommentableStateFormula commentableStateFormula = propertyUtil.createCommentableStateFormula(instance.getName() + "." +
							parentRegion.getName() + "." + state.getName(), stateFormula);
					
					formulas.add(commentableStateFormula); 
				}
			}
		}
		return formulas;
	}
	
	public List<CommentableStateFormula> createOutEventReachability(Component component,
			Collection<SynchronousComponentInstance> instances) {
		Collection<Port> simplePorts = StatechartModelDerivedFeatures.getAllConnectedSimplePorts(component);
		List<CommentableStateFormula> formulas = new ArrayList<CommentableStateFormula>(); 
		for (SynchronousComponentInstance instance : instances) {
			Component type = instance.getType();
			List<Port> ports = new ArrayList<Port>(type.getPorts());
			ports.retainAll(simplePorts); // Only that are led out to the system port
			for (Port port : ports) {
				for (Event outEvent : StatechartModelDerivedFeatures.getOutputEvents(port)) {
					EList<ParameterDeclaration> parameters = outEvent.getParameterDeclarations();
					if (parameters.isEmpty()) {
						ComponentInstanceEventReference eventReference =
								propertyUtil.createEventReference(createInstanceReference(instance),
										port, outEvent);
						StateFormula stateFormula = propertyUtil.createEF(
								propertyUtil.createAtomicFormula(eventReference));
						
						CommentableStateFormula commentableStateFormula = propertyUtil.createCommentableStateFormula(
								instance.getName() + "." + port.getName() + "." + outEvent.getName(), stateFormula);
						
						formulas.add(commentableStateFormula); 
					}
					else {
						for (ParameterDeclaration parameter : parameters) {
							Set<Expression> parameterValues = getValues(parameter); // Only bool and enum
							if (parameterValues.isEmpty()) {
								// E.g., integers - plain event
								ComponentInstanceEventReference eventReference =
										propertyUtil.createEventReference(
												createInstanceReference(instance), port, outEvent);
								StateFormula stateFormula = propertyUtil.createEF(
										propertyUtil.createAtomicFormula(eventReference));
								
								CommentableStateFormula commentableStateFormula = propertyUtil.createCommentableStateFormula(
										instance.getName() + "." + port.getName() + "." + outEvent.getName(), stateFormula);
								
								formulas.add(commentableStateFormula); 
							}
							else {
								for (Expression value : parameterValues) {
									ComponentInstanceEventReference eventReference =
											propertyUtil.createEventReference(
													createInstanceReference(instance), port, outEvent);
									ComponentInstanceEventParameterReference parameterReference =
											propertyUtil.createParameterReference(
													createInstanceReference(instance),port, outEvent, parameter);
									
									EqualityExpression equalityExpression = expressionFactory.createEqualityExpression();
									equalityExpression.setLeftOperand(parameterReference);
									equalityExpression.setRightOperand(value);
									
									AndExpression and = expressionFactory.createAndExpression();
									and.getOperands().add(eventReference);
									and.getOperands().add(equalityExpression);
									
									StateFormula stateFormula = propertyUtil.createEF(
											propertyUtil.createAtomicFormula(and));
									
									CommentableStateFormula commentableStateFormula = propertyUtil.createCommentableStateFormula(
											instance.getName() + "." + port.getName() + "." +
											outEvent.getName() + "." + parameter.getName() + " == " +
											expressionSerializer.serialize(value), stateFormula);
									
									formulas.add(commentableStateFormula); 
								}
							}
						}
					}
				}
			}
		}
		return formulas;
	}

	protected Set<Expression> getValues(ParameterDeclaration parameter) {
		Type typeDefinition = StatechartModelDerivedFeatures
				.getTypeDefinition(parameter.getType());
		if (typeDefinition instanceof BooleanTypeDefinition) {
			return Set.of(
				expressionFactory.createTrueExpression(),
				expressionFactory.createFalseExpression());
		}
		else if (typeDefinition instanceof EnumerationTypeDefinition) {
			EnumerationTypeDefinition enumType = (EnumerationTypeDefinition) typeDefinition;
			Set<Expression> literals = new HashSet<Expression>();
			for (EnumerationLiteralDefinition literal : enumType.getLiterals()) {
				EnumerationLiteralExpression expression =
						expressionFactory.createEnumerationLiteralExpression();
				expression.setReference(literal);
				literals.add(expression);
			}
			return literals;
		}
		return Collections.emptySet();
	}
	
	public List<CommentableStateFormula> createTransitionReachability(
			Map<Transition, VariableDeclaration> transitionVariables) {
		List<CommentableStateFormula> formulas = new ArrayList<CommentableStateFormula>();
		if (transitionVariables.isEmpty()) {
			return formulas;
		}
		
		for (Entry<Transition, VariableDeclaration> entry : transitionVariables.entrySet()) {
			VariableDeclaration variable = entry.getValue();
			StatechartDefinition statechart = StatechartModelDerivedFeatures.getContainingStatechart(variable);
			ComponentInstance instance = StatechartModelDerivedFeatures.getReferencingComponentInstance(statechart);
			ComponentInstanceVariableReference reference =
					propertyUtil.createVariableReference(createInstanceReference(instance), variable);
			StateFormula stateFormula = propertyUtil.createEF(
					propertyUtil.createAtomicFormula(reference));
			
			// Comment
			
			Transition transition = entry.getKey();
			
			CommentableStateFormula commentableStateFormula = propertyUtil.createCommentableStateFormula(
					getId(transition), stateFormula);
			
			formulas.add(commentableStateFormula); 
		}
		
		return formulas;
	}
	
	public List<CommentableStateFormula> createInteractionReachability(Map<Entry<RaiseEventAction, Transition>,
			Entry<Entry<VariableDeclaration, Long>, Entry<VariableDeclaration, Long>>> interactions) {
		List<CommentableStateFormula> formulas = new ArrayList<CommentableStateFormula>();
		if (interactions.isEmpty()) {
			return formulas;
		}
		
		for (Entry<Entry<RaiseEventAction, Transition>, Entry<Entry<VariableDeclaration, Long>, Entry<VariableDeclaration, Long>>> entry :
				interactions.entrySet()) {
			Entry<Entry<VariableDeclaration, Long>, Entry<VariableDeclaration, Long>> value = entry.getValue();
			Entry<VariableDeclaration, Long> sending = value.getKey();
			VariableDeclaration senderVariable = sending.getKey();
			Long senderId = sending.getValue();
			Entry<VariableDeclaration, Long> receiving = value.getValue();
			VariableDeclaration receiverVariable = receiving.getKey();
			Long receiverId = receiving.getValue();
			
			// Sender - note that the sender statechart and instance are the same as the receiving one,
			// the senderVariable and receiverVariable are stored in the same statechart (receiverStatechart)
			// Duplicated this part to make it more resilient (if the variables in the future are stored somewhere else)
			EqualityExpression senderEqualityExpression = expressionFactory.createEqualityExpression();
			StatechartDefinition senderStatechart = StatechartModelDerivedFeatures.getContainingStatechart(senderVariable);
			ComponentInstance senderInstance = StatechartModelDerivedFeatures.getReferencingComponentInstance(senderStatechart);
			ComponentInstanceVariableReference senderReference =
					propertyUtil.createVariableReference(createInstanceReference(senderInstance), senderVariable);
			IntegerLiteralExpression senderLiteral = expressionFactory.createIntegerLiteralExpression();
			senderLiteral.setValue(BigInteger.valueOf(senderId));
			senderEqualityExpression.setLeftOperand(senderReference);
			senderEqualityExpression.setRightOperand(senderLiteral);
			// Receiver
			EqualityExpression receiverEqualityExpression = expressionFactory.createEqualityExpression();
			StatechartDefinition receiverStatechart = StatechartModelDerivedFeatures.getContainingStatechart(receiverVariable);
			ComponentInstance receiverInstance = StatechartModelDerivedFeatures.getReferencingComponentInstance(receiverStatechart);
			ComponentInstanceVariableReference receiverReference =
					propertyUtil.createVariableReference(createInstanceReference(receiverInstance), receiverVariable);
			IntegerLiteralExpression receiverLiteral = expressionFactory.createIntegerLiteralExpression();
			receiverLiteral.setValue(BigInteger.valueOf(receiverId));
			receiverEqualityExpression.setLeftOperand(receiverReference);
			receiverEqualityExpression.setRightOperand(receiverLiteral);
			
			AndExpression andExpression = expressionFactory.createAndExpression();
			andExpression.getOperands().add(senderEqualityExpression);
			andExpression.getOperands().add(receiverEqualityExpression);
			
			StateFormula stateFormula = propertyUtil.createEF(
					propertyUtil.createAtomicFormula(andExpression));
			
			// Comment
			
			Entry<RaiseEventAction, Transition> interaction = entry.getKey();
			RaiseEventAction source = interaction.getKey();
			Transition target = interaction.getValue();
			
			CommentableStateFormula commentableStateFormula = propertyUtil.createCommentableStateFormula(
					getId(source) + " -i- " + getId(target), stateFormula);
			
			formulas.add(commentableStateFormula); 
		}
		return formulas;
	}
	
	protected ComponentInstanceReference createInstanceReference(ComponentInstance instance) {
		if (isSimpleComponentReference) {
			ComponentInstanceReference reference = compositeFactory.createComponentInstanceReference();
			reference.getComponentInstanceHierarchy().add(instance);
			return reference;
		}
		else {
			return statechartUtil.createInstanceReference(instance);
		}
	}
	
	// Comments
	
	protected String getInstanceId(EObject object) {
		StatechartDefinition statechart = StatechartModelDerivedFeatures.getContainingStatechart(object);
		try {
			ComponentInstance instance = StatechartModelDerivedFeatures.getReferencingComponentInstance(statechart);
			return instance.getName();
		} catch (IllegalArgumentException e) {
			return "";
		}
	}
	
	protected String getId(RaiseEventAction action) {
		Transition transition = ecoreUtil.getContainerOfType(action, Transition.class);
		if (transition == null) {
			State state = ecoreUtil.getContainerOfType(action, State.class);
			if (state == null) {
				throw new IllegalArgumentException("Not known raise event: " + action);
			}
			return getId(state);
		}
		return getId(transition);
	}
	
	protected String getId(State state) {
		return getInstanceId(state) + "." +
			StatechartModelDerivedFeatures.getParentRegion(state).getName() + "." +
				state.getName();
	}
	
	protected String getId(Transition transition) {
		return getInstanceId(transition) + "." + transition.getSourceState().getName() + " --> " +
				getInstanceId(transition) + "." + transition.getTargetState().getName();
	}
	
}
