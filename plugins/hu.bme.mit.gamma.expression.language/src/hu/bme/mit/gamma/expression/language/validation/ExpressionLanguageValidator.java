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
package hu.bme.mit.gamma.expression.language.validation;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EStructuralFeature;
import org.eclipse.xtext.validation.Check;

import hu.bme.mit.gamma.expression.model.ArithmeticExpression;
import hu.bme.mit.gamma.expression.model.ArrayAccessExpression;
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression;
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition;
import hu.bme.mit.gamma.expression.model.BinaryExpression;
import hu.bme.mit.gamma.expression.model.BooleanExpression;
import hu.bme.mit.gamma.expression.model.ComparisonExpression;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DivExpression;
import hu.bme.mit.gamma.expression.model.ElseExpression;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression;
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition;
import hu.bme.mit.gamma.expression.model.EquivalenceExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelPackage;
import hu.bme.mit.gamma.expression.model.FieldDeclaration;
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression;
import hu.bme.mit.gamma.expression.model.FunctionDeclaration;
import hu.bme.mit.gamma.expression.model.IfThenElseExpression;
import hu.bme.mit.gamma.expression.model.InitializableElement;
import hu.bme.mit.gamma.expression.model.ModExpression;
import hu.bme.mit.gamma.expression.model.MultiaryExpression;
import hu.bme.mit.gamma.expression.model.NamedElement;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.PredicateExpression;
import hu.bme.mit.gamma.expression.model.RecordAccessExpression;
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.SelectExpression;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeReference;
import hu.bme.mit.gamma.expression.model.UnaryExpression;

/**
 * This class contains custom validation rules. 
 *
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
public class ExpressionLanguageValidator extends AbstractExpressionLanguageValidator {
	
	protected ExpressionTypeDeterminator typeDeterminator = new ExpressionTypeDeterminator();
	
	@Check
	public void checkNameUniqueness(NamedElement element) {
		Collection<? extends NamedElement> namedElements = ExpressionLanguageValidatorUtil.getRecursiveContainerContentsOfType(element, element.getClass());
		namedElements.remove(element);
		for (NamedElement elem : namedElements) {
			if (element.getName().equals(elem.getName())) {
				error("Names must be unique!", ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME);
			}
		}
	}
	
	@Check
	public void checkIfThenElseExpression(IfThenElseExpression expression) {
		ExpressionType expressionType = typeDeterminator.getType(expression.getCondition());
		if (expressionType != ExpressionType.BOOLEAN) {
			error("The condition of the if-then-else expression must be of type boolean, currently it is: " + expressionType.toString().toLowerCase(),
					ExpressionModelPackage.Literals.IF_THEN_ELSE_EXPRESSION__CONDITION);
		}
		if (typeDeterminator.getType(expression.getThen()) != typeDeterminator.getType(expression.getElse())) {
			error("The return type of the else-branch does not match the type of the then-branch!", 
					ExpressionModelPackage.Literals.IF_THEN_ELSE_EXPRESSION__ELSE);
		}
	}
	
	@Check
	public void checkArrayLiteralExpression(ArrayLiteralExpression expression) {
		ExpressionType referenceType = null;
		for(Expression e : expression.getOperands()) {
			ExpressionType examinedType = typeDeterminator.getType(e);
			if (examinedType != referenceType) {
				if(referenceType == null) {
					referenceType = examinedType;
				}
				else {
					error("The operands of the ArrayLiteralExpression are not of the same type!", null);
				}
			}
		}
	}
	
	@Check
	public void checkRecordAccessExpression(RecordAccessExpression recordAccessExpression) {
		RecordTypeDefinition rtd = (RecordTypeDefinition)ExpressionLanguageValidatorUtil.findAccessExpressionTypeDefinition(recordAccessExpression);
		List<FieldDeclaration> fieldDeclarations = rtd.getFieldDeclarations();
		List<String> fieldDeclarationNames = new ArrayList<String>();
		for (FieldDeclaration fd : fieldDeclarations) {
			fieldDeclarationNames.add(fd.getName());
		}
		if (!fieldDeclarationNames.contains(recordAccessExpression.getField())){
			error("The record type does not contain any fields with the given name.",
					ExpressionModelPackage.Literals.RECORD_ACCESS_EXPRESSION__FIELD);
		}
	}
	
	@Check
	public void checkFunctionAccessExpression(FunctionAccessExpression functionAccessExpression) {
		List<Expression> arguments = functionAccessExpression.getArguments();
		ReferenceExpression ref = (ReferenceExpression)functionAccessExpression.getOperand();
		if (ref.getDeclaration() instanceof FunctionDeclaration) {
			List<ParameterDeclaration> parameters = ((FunctionDeclaration)(ref).getDeclaration()).getParameterDeclarations();
			if (arguments.size() != parameters.size()) {
				error("The number of arguments does not match the number of declared parameters for the function!", 
						ExpressionModelPackage.Literals.ARGUMENTED_ELEMENT__ARGUMENTS);
			}
			int i = 0;
			for(Expression arg : arguments) {
				ExpressionType argumentType = typeDeterminator.getType(arg);
				if(!typeDeterminator.equals(parameters.get(i).getType(), argumentType)) {
					error("The types of the arguments and the types of the declared function parameters do not match!",
							ExpressionModelPackage.Literals.ARGUMENTED_ELEMENT__ARGUMENTS);
				}
				++i;
			}
		}
		else {
			error("The referenced object is not a function declaration!",
					ExpressionModelPackage.Literals.ACCESS_EXPRESSION__OPERAND);
		}
	}
	
	@Check
	public void checkArrayAccessExpression(ArrayAccessExpression expression) {
		if (!typeDeterminator.isInteger(expression.getArguments().get(0))) {
			error("The index of the accessed element must be of type integer!", ExpressionModelPackage.Literals.ARGUMENTED_ELEMENT__ARGUMENTS);
		}
	}
	
	@Check
	public void checkSelectExpression(SelectExpression expression){
		if (!((typeDeterminator.getType(expression.getOperand()) == ExpressionType.ARRAY) ||
				(typeDeterminator.getType(expression.getOperand()) == ExpressionType.ENUMERATION) ||
				(typeDeterminator.getType(expression.getOperand()) == ExpressionType.INTEGER_RANGE))) {
			error("Select expression can only be applied to enumerable expressions (array, integer range and enumeration)!" + typeDeterminator.getType(expression.getOperand()).toString(), null);
		}
	}
	
	@Check
	public void checkElseExpression(ElseExpression expression) {
		EObject container = expression.eContainer();
		if (container instanceof Expression) {
			error("Else expressions must not be contained by composite expressions.", 
					expression.eContainingFeature());
		}
	}
	
	@Check
	public void checkBooleanExpression(BooleanExpression expression) {
		if (expression instanceof UnaryExpression) {
			// not
			UnaryExpression unaryExpression = (UnaryExpression) expression;
			if (!typeDeterminator.isBoolean(unaryExpression.getOperand())) {
				error("The operand of this unary boolean operation is evaluated as a non-boolean value.",
						ExpressionModelPackage.Literals.UNARY_EXPRESSION__OPERAND);
			}
		}
		else if (expression instanceof BinaryExpression) {
			// equal and imply
			BinaryExpression binaryExpression = (BinaryExpression) expression;
			if (!typeDeterminator.isBoolean(binaryExpression.getLeftOperand())) {
				error("The left operand of this binary boolean operation is evaluated as a non-boolean value.",
						ExpressionModelPackage.Literals.BINARY_EXPRESSION__LEFT_OPERAND);
			}
			if (!typeDeterminator.isBoolean(binaryExpression.getRightOperand())) {
				error("The right operand of this binary boolean operation is evaluated as a non-boolean value.",
						ExpressionModelPackage.Literals.BINARY_EXPRESSION__RIGHT_OPERAND);
			}
		}
		else if (expression instanceof MultiaryExpression) {
			// and or or or xor
			MultiaryExpression multiaryExpression = (MultiaryExpression) expression;
			for (int i = 0; i < multiaryExpression.getOperands().size(); ++i) {
				Expression operand = multiaryExpression.getOperands().get(i);
				if (!typeDeterminator.isBoolean(operand)) {
					error("This operand of this multiary boolean operation is evaluated as a non-boolean value.",
							ExpressionModelPackage.Literals.MULTIARY_EXPRESSION__OPERANDS, i);
				}
			}
		}
	}
	
	@Check
	public void checkPredicateExpression(PredicateExpression expression) {
		if (expression instanceof UnaryExpression) {
			// in expression, semantics not known
		}
		else if (expression instanceof BinaryExpression) {
			// Equivalence
			if (expression instanceof EquivalenceExpression) {
				EquivalenceExpression equivalenceExpression = (EquivalenceExpression) expression;
				Expression lhs = equivalenceExpression.getLeftOperand();
				Expression rhs = equivalenceExpression.getRightOperand();
				if (lhs instanceof ReferenceExpression) {
					checkTypeAndExpressionConformance(((ReferenceExpression) lhs).getDeclaration().getType(), rhs,
							ExpressionModelPackage.Literals.BINARY_EXPRESSION__RIGHT_OPERAND);
				}
				else if (rhs instanceof ReferenceExpression) {
					checkTypeAndExpressionConformance(((ReferenceExpression) rhs).getDeclaration().getType(), lhs,
							ExpressionModelPackage.Literals.BINARY_EXPRESSION__RIGHT_OPERAND);
				}
				else {
					ExpressionType leftHandSideExpressionType = typeDeterminator.getType(lhs);
					ExpressionType rightHandSideExpressionType = typeDeterminator.getType(rhs);
					if (!leftHandSideExpressionType.equals(rightHandSideExpressionType)) {
						error("The left and right hand sides are not compatible: " + leftHandSideExpressionType + " and " +
							rightHandSideExpressionType, ExpressionModelPackage.Literals.BINARY_EXPRESSION__RIGHT_OPERAND);
					}
				}
			}
			// Comparison
			if (expression instanceof ComparisonExpression) {
				ComparisonExpression binaryExpression = (ComparisonExpression) expression;
				if (!typeDeterminator.isNumber(binaryExpression.getLeftOperand())) {
					error("The left operand of this binary predicate expression is evaluated as a non-comparable value.",
							ExpressionModelPackage.Literals.BINARY_EXPRESSION__LEFT_OPERAND);
				}
				if (!typeDeterminator.isNumber(binaryExpression.getRightOperand())) {
					error("The right operand of this binary predicate expression is evaluated as a non-comparable value.",
							ExpressionModelPackage.Literals.BINARY_EXPRESSION__RIGHT_OPERAND);
				}
			}
		}	
	}
	
	protected void checkTypeAndExpressionConformance(Type type, Expression rhs, EStructuralFeature feature) {
		ExpressionType rightHandSideExpressionType = typeDeterminator.getType(rhs);
		if (!typeDeterminator.equals(type, rightHandSideExpressionType)) {
			error("The types of the variable declaration and the right hand side expression are not the same: " +
					typeDeterminator.transform(type).toString().toLowerCase() + " and " +
					rightHandSideExpressionType.toString().toLowerCase() + ".", feature);
		}
		// Additional checks for enumerations
		EnumerationTypeDefinition enumType = null;
		if (type instanceof EnumerationTypeDefinition) {
			enumType = (EnumerationTypeDefinition) type;
		}
		else if (type instanceof TypeReference &&
				((TypeReference) type).getReference().getType() instanceof EnumerationTypeDefinition) {
			enumType = (EnumerationTypeDefinition) ((TypeReference) type).getReference().getType();
		}
		if (enumType != null) {
			if (rhs instanceof EnumerationLiteralExpression) {
				EnumerationLiteralExpression rhsLiteral = (EnumerationLiteralExpression) rhs;
				if (!enumType.getLiterals().contains(rhsLiteral.getReference())) {
					error("This is not a valid literal of the enum type: " + rhsLiteral.getReference().getName() + ".", feature);
				}
			}
			else {
				error("The right hand side must be of type enumeration literal.", feature);
			}
		}
	}
	
	@Check
	public void checkArithmeticExpression(ArithmeticExpression expression) {
		if (expression instanceof UnaryExpression) {
			// + or -
			UnaryExpression unaryExpression = (UnaryExpression) expression;
			if (!typeDeterminator.isNumber(unaryExpression.getOperand())) {
				error("The operand of this unary arithemtic operation is evaluated as a non-number value.",
						ExpressionModelPackage.Literals.UNARY_EXPRESSION__OPERAND);
			}
		}
		else if (expression instanceof BinaryExpression) {
			// - or / or mod or div
			BinaryExpression binaryExpression = (BinaryExpression) expression;
			if (expression instanceof ModExpression || expression instanceof DivExpression) {
				// Only integers can be operands
				if (!typeDeterminator.isInteger(binaryExpression.getLeftOperand())) {
					error("The left operand of this binary arithemtic operation is evaluated as a non-integer value.",
							ExpressionModelPackage.Literals.BINARY_EXPRESSION__LEFT_OPERAND);
				}
				if (!typeDeterminator.isInteger(binaryExpression.getRightOperand())) {
					error("The right operand of this binary arithemtic operation is evaluated as a non-integer value.",
							ExpressionModelPackage.Literals.BINARY_EXPRESSION__RIGHT_OPERAND);
				}
			}
			else {
				if (!typeDeterminator.isNumber(binaryExpression.getLeftOperand())) {
					error("The left operand of this binary arithemtic operation is evaluated as a non-number value.",
							ExpressionModelPackage.Literals.BINARY_EXPRESSION__LEFT_OPERAND);
				}
				if (!typeDeterminator.isNumber(binaryExpression.getRightOperand())) {
					error("The right operand of this binary arithemtic operation is evaluated as a non-number value.",
							ExpressionModelPackage.Literals.BINARY_EXPRESSION__RIGHT_OPERAND);
				}
			}
		}
		else if (expression instanceof MultiaryExpression) {
			// + or *
			MultiaryExpression multiaryExpression = (MultiaryExpression) expression;
			for (int i = 0; i < multiaryExpression.getOperands().size(); ++i) {
				Expression operand = multiaryExpression.getOperands().get(i);
				if (!typeDeterminator.isNumber(operand)) {
					error("This operand of this multiary arithemtic operation is evaluated as a non-number value.",
							ExpressionModelPackage.Literals.MULTIARY_EXPRESSION__OPERANDS, i);
				}
			}
		}
	}
	
	@Check
	public void checkInitializableElement(InitializableElement elem) {
		try {
			Expression initialExpression = elem.getExpression();
			if (initialExpression == null) {
				return;
			}
			// The declaration has an initial value
			if (elem instanceof Declaration) {
				Declaration declaration = (Declaration) elem;
				if (isDeclarationReferredInExpression(declaration, initialExpression)) {
					error("The initial value must not be the declaration itself.", ExpressionModelPackage.Literals.INITIALIZABLE_ELEMENT__EXPRESSION);
					return;
				}
				Type variableDeclarationType = declaration.getType();
				ExpressionType initialExpressionType = typeDeterminator.getType(elem.getExpression());
				if (!typeDeterminator.equals(variableDeclarationType, initialExpressionType)) {
					error("The types of the declaration and the right hand side expression are not the same: " +
							typeDeterminator.transform(variableDeclarationType).toString().toLowerCase() + " and " +
							initialExpressionType.toString().toLowerCase() + ".",
							ExpressionModelPackage.Literals.INITIALIZABLE_ELEMENT__EXPRESSION);
				} 
				// Additional checks for enumerations
				EnumerationTypeDefinition enumType = null;
				if (variableDeclarationType instanceof EnumerationTypeDefinition) {
					enumType = (EnumerationTypeDefinition) variableDeclarationType;
				}
				else if (variableDeclarationType instanceof TypeReference &&
						((TypeReference) variableDeclarationType).getReference().getType() instanceof EnumerationTypeDefinition) {
					enumType = (EnumerationTypeDefinition) ((TypeReference) variableDeclarationType).getReference().getType();
				}
				if (enumType != null) {
					if (initialExpression instanceof EnumerationLiteralExpression) {
						EnumerationLiteralExpression rhs = (EnumerationLiteralExpression) initialExpression;
						if (!enumType.getLiterals().contains(rhs.getReference())) {
							error("This is not a valid literal of the enum type: " + rhs.getReference().getName() + ".",
									ExpressionModelPackage.Literals.INITIALIZABLE_ELEMENT__EXPRESSION);
						}
					}
					else {
						error("The right hand side must be of type enumeration literal.", ExpressionModelPackage.Literals.INITIALIZABLE_ELEMENT__EXPRESSION);
					}
				}
				// Additional checks for arrays
				ArrayTypeDefinition arrayType = null;
				if (variableDeclarationType instanceof ArrayTypeDefinition) {
					arrayType = (ArrayTypeDefinition) variableDeclarationType;
				}
				else if (variableDeclarationType instanceof TypeReference &&
						((TypeReference) variableDeclarationType).getReference().getType() instanceof ArrayTypeDefinition) {
					arrayType = (ArrayTypeDefinition) ((TypeReference) variableDeclarationType).getReference().getType();
				}
				if (arrayType != null) {
					if (initialExpression instanceof ArrayLiteralExpression) {
						ArrayLiteralExpression rhs = (ArrayLiteralExpression) initialExpression;
						for(Expression e : rhs.getOperands()) {
							if(!typeDeterminator.equals(arrayType.getElementType(), typeDeterminator.getType(e))) {
								error("The elements on the right hand side must be of the declared type of the array.", ExpressionModelPackage.Literals.INITIALIZABLE_ELEMENT__EXPRESSION);
							}
						}
					}
					else {
						error("The right hand side must be of type array literal.", ExpressionModelPackage.Literals.INITIALIZABLE_ELEMENT__EXPRESSION);
					}
				}
			}
		} catch (Exception exception) {
			// There is a type error on a lower level, no need to display the error message on this level too
		}
	}
	
	protected boolean isDeclarationReferredInExpression(Declaration declaration, Expression expression) {
		if (expression instanceof ReferenceExpression) {
			ReferenceExpression referenceExpression = (ReferenceExpression) expression;
			if (referenceExpression.getDeclaration() == declaration) {
				return true;
			}
		}
		for (EObject content : expression.eContents()) {
			Expression containedExpression = (Expression) content;
			boolean isReferred = isDeclarationReferredInExpression(declaration, containedExpression);
			if (isReferred) {
				return true;
			}
		}
		return false;
	}

}