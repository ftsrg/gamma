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
import hu.bme.mit.gamma.statechart.statechart.State;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.statechart.statechart.Transition;
import hu.bme.mit.gamma.statechart.util.StatechartUtil;

public class PropertyGenerator {
	// Single component reference or the whole chain is needed
	// That is we reference the model after or before the unfolding 
	protected boolean isSimpleComponentReference;
	//
	protected final PropertyUtil propertyUtil = PropertyUtil.INSTANCE;
	protected final StatechartUtil statechartUtil = StatechartUtil.INSTANCE;
	protected final ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE;
	protected final CompositeModelFactory compositeFactory = CompositeModelFactory.eINSTANCE;
	protected final PropertyModelFactory factory = PropertyModelFactory.eINSTANCE;
	
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
	
	public List<StateFormula> createStateReachability(
			Collection<SynchronousComponentInstance> instances) {
		List<StateFormula> formulas = new ArrayList<StateFormula>();
		for (SynchronousComponentInstance instance : instances) {
			Component type = instance.getType();
			if (type instanceof StatechartDefinition) {
				StatechartDefinition statechart = (StatechartDefinition) type;
				for (State state : StatechartModelDerivedFeatures.getAllStates(statechart)) {
					ComponentInstanceStateConfigurationReference stateReference =
							factory.createComponentInstanceStateConfigurationReference();
					stateReference.setInstance(createInstanceReference(instance));
					stateReference.setRegion(StatechartModelDerivedFeatures.getParentRegion(state));
					stateReference.setState(state);
					StateFormula stateFormula = propertyUtil.createEF(
						propertyUtil.createAtomicFormula(stateReference));
					formulas.add(stateFormula); 
				}
			}
		}
		return formulas;
	}
	
	public List<StateFormula> createOutEventReachability(
			Collection<SynchronousComponentInstance> instances) {
		List<StateFormula> formulas = new ArrayList<StateFormula>();
		for (SynchronousComponentInstance instance : instances) {
			Component type = instance.getType();
			for (Port port : type.getPorts()) {
				for (Event outEvent : StatechartModelDerivedFeatures.getOutputEvents(port)) {
					EList<ParameterDeclaration> parameters = outEvent.getParameterDeclarations();
					if (parameters.isEmpty()) {
						ComponentInstanceEventReference eventReference =
								propertyUtil.createEventReference(createInstanceReference(instance),
										port, outEvent);
						StateFormula stateFormula = propertyUtil.createEF(
								propertyUtil.createAtomicFormula(eventReference));
						formulas.add(stateFormula); 
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
								formulas.add(stateFormula); 
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
									formulas.add(stateFormula); 
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
	
	public List<StateFormula> createTransitionReachability(
			Map<Transition, VariableDeclaration> transitionVariables) {
		List<StateFormula> formulas = new ArrayList<StateFormula>();
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
			formulas.add(stateFormula);
		}
		
		return formulas;
	}
	
	public List<StateFormula> createInteractionReachability(
			Map<Entry<RaiseEventAction, Transition>, Entry<VariableDeclaration, Integer>> interactions) {
		List<StateFormula> formulas = new ArrayList<StateFormula>();
		if (interactions.isEmpty()) {
			return formulas;
		}
		
		for (Entry<Entry<RaiseEventAction, Transition>, Entry<VariableDeclaration, Integer>> entry :
				interactions.entrySet()) {
			Entry<VariableDeclaration, Integer> value = entry.getValue();
			VariableDeclaration variable = value.getKey();
			Integer id = value.getValue();
			
			EqualityExpression equalityExpression = expressionFactory.createEqualityExpression();
			StatechartDefinition statechart = StatechartModelDerivedFeatures.getContainingStatechart(variable);
			ComponentInstance instance = StatechartModelDerivedFeatures.getReferencingComponentInstance(statechart);
			ComponentInstanceVariableReference reference =
					propertyUtil.createVariableReference(createInstanceReference(instance), variable);
			IntegerLiteralExpression literal = expressionFactory.createIntegerLiteralExpression();
			literal.setValue(BigInteger.valueOf(id));
			equalityExpression.setLeftOperand(reference);
			equalityExpression.setRightOperand(literal);
			
			StateFormula stateFormula = propertyUtil.createEF(
					propertyUtil.createAtomicFormula(equalityExpression));
			formulas.add(stateFormula);
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
	
}