/********************************************************************************
 * Copyright (c) 2018-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
 package hu.bme.mit.gamma.xsts.codegeneration.c.util

import hu.bme.mit.gamma.action.model.Action
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.DeclarationReferenceAnnotation
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.model.impl.ArrayLiteralExpressionImpl
import hu.bme.mit.gamma.expression.model.impl.ArrayTypeDefinitionImpl
import hu.bme.mit.gamma.expression.model.impl.DeclarationReferenceAnnotationImpl
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.expression.util.ExpressionSerializer
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.composite.CompositeComponent
import hu.bme.mit.gamma.statechart.composite.PortBinding
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.EventDeclaration
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.xsts.codegeneration.c.serializer.VariableDeclarationSerializer
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.CompositeAction
import hu.bme.mit.gamma.xsts.model.EmptyAction
import hu.bme.mit.gamma.xsts.model.MultiaryAction
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.SystemMasterMessageQueueGroup
import hu.bme.mit.gamma.xsts.model.XSTS
import java.util.List
import org.eclipse.emf.common.util.BasicEList
import org.eclipse.emf.ecore.EObject

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class GeneratorUtil {
	
	static val extension ExpressionModelFactory factory = ExpressionModelFactory.eINSTANCE;
	static val extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	static val extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE;
	static val extension VariableDeclarationSerializer variableDeclarationSerializer = VariableDeclarationSerializer.INSTANCE;
	
	/**
	 * Returns whether the given XSTS model is async or not.
	 *
	 * @param xsts the given XSTS model
	 * @return whether the given XSTS model is async or not
	 */
	static def boolean isAsync(XSTS xsts) {
		return xsts.variableGroups.filter[it.annotation instanceof SystemMasterMessageQueueGroup].size > 0
	}
	
	/**
	 * Transforms a string with underscores to camel case by converting each word's first letter
	 * after an underscore to uppercase.
	 *
	 * @param input the string to transform
	 * @return the transformed string in camel case
	 */
	static def String transformString(String input) {
  		val parts = input.split("_")
  		val transformedParts = parts.map [ it.toFirstUpper ]
  		return transformedParts.join("_")
	}
	
	/**
	 * Retrieves the length of an enumeration type.
	 *
	 * @param type The enumeration type to get the length for
	 * @return The number of literals in the enumeration type
 	 */
	static def String getLength(Type type) {
		val type_enum = type as EnumerationTypeDefinition
		return '''«type_enum.literals.size»'''
	}
	
	/**
 	 * Calculates array type based on the given ArrayTypeDefinition.
	 *
	 * @param type the ArrayTypeDefinition to generate the array type for.
	 * @param clock a boolean indicating whether it's a clock.
	 * @param name the name of the array type.
	 * @return the generated array type as a String.
	 */
	static def String getArrayType(ArrayTypeDefinition type, boolean clock, String name) {
		if (!(type.elementType instanceof ArrayTypeDefinitionImpl))
			return type.elementType.serialize(clock, name)
		return (type.elementType as ArrayTypeDefinition).getArrayType(clock, name)
	}
	
	/**
	 * Calculate the array size of an ArrayLiteralExpression recursively.
	 *
	 * @param literal the ArrayLiteralExpression to calculate the size for
	 * @return the size of the ArrayLiteralExpression as an array String
	 */
	static def String getLiteralSize(ArrayLiteralExpression literal) {
		if (literal.operands.head instanceof ArrayLiteralExpressionImpl)
			return '''[«literal.operands.size»]«getLiteralSize(literal.operands.head as ArrayLiteralExpression)»'''
		return '''[«literal.operands.size»]'''
	}
	
	/**
	 * Get a list of declarations referenced by a VariableDeclaration.
	 *
	 * @param variable the VariableDeclaration to get declaration references for
	 * @return a list of declarations referenced by the VariableDeclaration
	 */
	static def List<Declaration> getDeclarationReference(VariableDeclaration variable) {
		val reference = (variable.annotations.filter[it instanceof DeclarationReferenceAnnotationImpl].head as DeclarationReferenceAnnotation)
		if (reference === null) return new BasicEList()
		return reference.declarations
	}
	
	/**
	 * Checks if a MultiaryAction is empty, meaning it has no actions or contains only EmptyAction instances.
	 *
	 * @param action The MultiaryAction to be checked
	 * @return `true` if the MultiaryAction is empty, `false` otherwise
	 */
	static def boolean isEmpty(MultiaryAction action) {
		return action === null || action.actions.filter[!(it instanceof EmptyAction)].size == 0
	}
	
	/**
	 * Retrieves the initial value of a given variable from the model's initial transition.
	 *
	 * @param variable the variable for which the initial value is sought.
	 * @param object the context object in which the variable's initial value is to be determined.
	 * @return a number representing the initial value of the variable, or 0 if not found.
	 */
	static def int getInitialValueEvaluated(VariableDeclaration variable, EObject object) {
		val expression = variable.getInitialValue(object)
		if (expression === null) return 0
		return expressionEvaluator.evaluate(expression)
	}
	
	/**
	 * Retrieves the initial value of a given variable from the model's initial transition.
	 *
	 * @param variable the variable for which the initial value is sought.
	 * @param object the context object in which the variable's initial value is to be determined.
	 * @return a CharSequence representing the initial value of the variable, or 0 if not found.
	 */
	static def CharSequence getInitialValueSerialized(VariableDeclaration variable, EObject object) {
		val expression = variable.getInitialValue(object)
		if (expression === null) return '0'
		return expressionSerializer.serialize(expression)
	}
	
	/**
	 * Retrieves the initial value of a given variable from the model's initial transition.
	 *
	 * @param variable the variable for which the initial value is sought.
	 * @param object the context object in which the variable's initial value is to be determined.
	 * @return an Expression representing the initial value of the variable, or null if not found.
	 */
	static def Expression getInitialValue(VariableDeclaration variable, EObject object) {
		if (object instanceof XSTS) {
			val result = variable.getInitialValue(object.variableInitializingTransition)
			return result
		}
		if (object instanceof AssignmentAction && (object as AssignmentAction).lhs instanceof DirectReferenceExpression && ((object as AssignmentAction).lhs as DirectReferenceExpression).declaration == variable)
			return (object as AssignmentAction).rhs
		
		var Expression result = null
		for (child : object.eContents) {
			result = variable.getInitialValue(child)
			if (result !== null) return result
		}
		return result
	}
	
	static def PortBinding getBindingByCompositeSystemPort(Component component, String name) {
		if (!(component instanceof CompositeComponent))
			return null
		return (component as CompositeComponent).portBindings.filter[it.compositeSystemPort.name == name].head
	}
	
	static def String getRealization(Port port) {
		switch(port.interfaceRealization.realizationMode) {
		case PROVIDED:
			return 'Out'
		case REQUIRED:
			return 'In'
		default:
			return 'In'
		}
	}
	
	static def Port getMatchingPort(Component component, Port port) {
		if (component instanceof CompositeComponent) {
			return component.channels.filter[it.providedPort.port.interfaceRealization.interface == port.interfaceRealization.interface].head.providedPort.port
		}
		
		return port
	}
	
	static def String getXstsVariableName(XSTS xsts, Component component, Port port, EventDeclaration event) {
		if (xsts.async) {
			var adapter = component.getBindingByCompositeSystemPort(port.name).instancePortReference.instance.derivedType
			if (adapter instanceof AsynchronousAdapter)
				return '''statechart->«xsts.name.toLowerCase»statechart.«component.getBindingByCompositeSystemPort(port.name).instancePortReference.port.name»_«event.event.name»_«port.realization»_«component.getBindingByCompositeSystemPort(port.name).instancePortReference.instance.name»_«adapter.wrappedComponent.name»''' 
		}
		return '''statechart->«xsts.name.toLowerCase»statechart.«component.getBindingByCompositeSystemPort(port.name).instancePortReference.port.name»_«event.event.name»_«port.realization»_«component.getBindingByCompositeSystemPort(port.name).instancePortReference.instance.name»'''
	}
	
	static def String getXstsParameterName(XSTS xsts, Component component, Port port, EventDeclaration event, ParameterDeclaration param) {
		if (xsts.async) {
			var adapter = component.getBindingByCompositeSystemPort(port.name).instancePortReference.instance.derivedType
			if (adapter instanceof AsynchronousAdapter)
				return '''statechart->«xsts.name.toLowerCase»statechart.«component.getBindingByCompositeSystemPort(port.name).instancePortReference.port.name»_«event.event.name»_«port.realization»_«param.name»_«component.getBindingByCompositeSystemPort(port.name).instancePortReference.instance.name»_«adapter.wrappedComponent.name»''' 
		}
		return '''statechart->«xsts.name.toLowerCase»statechart.«component.getBindingByCompositeSystemPort(port.name).instancePortReference.port.name»_«event.event.name»_«port.realization»_«param.name»_«component.getBindingByCompositeSystemPort(port.name).instancePortReference.instance.name»'''
	}
	
	// Getting conditions from a non deterministic action point of view
	
	static def dispatch Expression getCondition(Action action) {
		return createTrueExpression
	}
	
	static def dispatch Expression getCondition(SequentialAction action) {
		val xStsSubactions = action.actions
		val firstXStsSubaction = xStsSubactions.head
		if (firstXStsSubaction instanceof AssumeAction) {
			return firstXStsSubaction.condition
		}
		val xStsCompositeSubactions = xStsSubactions.filter(CompositeAction)
		if (xStsCompositeSubactions.empty) {
			return createTrueExpression
		}
		return createAndExpression => [
			for (xStsSubaction : action.actions) {
				it.operands += xStsSubaction.condition
			}
		]
	}
	
	// Should not be present, but there are NonDeterministicActions inside NonDeterministicAction
	static def dispatch Expression getCondition(NonDeterministicAction action) {
		return createOrExpression => [
			for (xStsSubaction : action.actions) {
				it.operands += xStsSubaction.condition
			}
		]
	}
	
	static def dispatch Expression getCondition(AssumeAction action) {
		return action.assumption
	}
	
}