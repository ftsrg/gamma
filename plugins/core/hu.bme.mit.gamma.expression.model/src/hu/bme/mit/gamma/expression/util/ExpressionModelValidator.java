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
package hu.bme.mit.gamma.expression.util;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EStructuralFeature;

import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.ArgumentedElement;
import hu.bme.mit.gamma.expression.model.ArithmeticExpression;
import hu.bme.mit.gamma.expression.model.ArrayAccessExpression;
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression;
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition;
import hu.bme.mit.gamma.expression.model.BinaryExpression;
import hu.bme.mit.gamma.expression.model.BooleanExpression;
import hu.bme.mit.gamma.expression.model.ComparisonExpression;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.DivExpression;
import hu.bme.mit.gamma.expression.model.DivideExpression;
import hu.bme.mit.gamma.expression.model.ElseExpression;
import hu.bme.mit.gamma.expression.model.EqualityExpression;
import hu.bme.mit.gamma.expression.model.EquivalenceExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelPackage;
import hu.bme.mit.gamma.expression.model.FieldAssignment;
import hu.bme.mit.gamma.expression.model.FieldDeclaration;
import hu.bme.mit.gamma.expression.model.FieldReferenceExpression;
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression;
import hu.bme.mit.gamma.expression.model.FunctionDeclaration;
import hu.bme.mit.gamma.expression.model.GreaterEqualExpression;
import hu.bme.mit.gamma.expression.model.GreaterExpression;
import hu.bme.mit.gamma.expression.model.IfThenElseExpression;
import hu.bme.mit.gamma.expression.model.InequalityExpression;
import hu.bme.mit.gamma.expression.model.InitializableElement;
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression;
import hu.bme.mit.gamma.expression.model.IntegerRangeLiteralExpression;
import hu.bme.mit.gamma.expression.model.IntegerRangeTypeDefinition;
import hu.bme.mit.gamma.expression.model.LessEqualExpression;
import hu.bme.mit.gamma.expression.model.LessExpression;
import hu.bme.mit.gamma.expression.model.LiteralExpression;
import hu.bme.mit.gamma.expression.model.ModExpression;
import hu.bme.mit.gamma.expression.model.MultiaryExpression;
import hu.bme.mit.gamma.expression.model.NamedElement;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.PredicateExpression;
import hu.bme.mit.gamma.expression.model.RationalLiteralExpression;
import hu.bme.mit.gamma.expression.model.RecordAccessExpression;
import hu.bme.mit.gamma.expression.model.RecordLiteralExpression;
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition;
import hu.bme.mit.gamma.expression.model.SelectExpression;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeDeclaration;
import hu.bme.mit.gamma.expression.model.TypeReference;
import hu.bme.mit.gamma.expression.model.UnaryExpression;
import hu.bme.mit.gamma.expression.model.ValueDeclaration;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.util.GammaEcoreUtil;
import hu.bme.mit.gamma.util.JavaUtil;

public class ExpressionModelValidator {
	// Singleton
	public static final ExpressionModelValidator INSTANCE = new ExpressionModelValidator();
	protected ExpressionModelValidator() {}
	//
	
	protected ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE; // Redefinable
	protected ExpressionTypeDeterminator2 typeDeterminator2 = ExpressionTypeDeterminator2.INSTANCE;  // Redefinable
	protected final ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE;
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected final JavaUtil javaUtil = JavaUtil.INSTANCE;
	protected final TypeNamePrettyPrinter typePrinter = TypeNamePrettyPrinter.INSTANCE;
	//
	
	public Collection<ValidationResultMessage> checkNameUniqueness(EObject root) {
		return checkNameUniqueness(ecoreUtil.getContentsOfType(root, NamedElement.class));
	}
	
	public Collection<ValidationResultMessage> checkNameUniqueness(List<? extends NamedElement> elements) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Set<String> names = new HashSet<String>();
		for (NamedElement element : elements) {
			String name = element.getName();
			if (names.contains(name)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"Identifiers in a scope must be unique.", new ReferenceInfo(
								ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME, null, element)));
			}
			else {
				names.add(name);
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkTypeDeclaration(TypeDeclaration typeDeclaration) {
		Type type = typeDeclaration.getType();
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (type instanceof TypeReference) {
			TypeReference typeReference = (TypeReference) type;
			TypeDeclaration referencedTypeDeclaration = typeReference.getReference();
			if (typeDeclaration == referencedTypeDeclaration) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"A type declaration cannot reference itself as a type definition.",
						new ReferenceInfo(ExpressionModelPackage.Literals.DECLARATION__TYPE, null)));
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkArgumentTypes(ArgumentedElement element, List<ParameterDeclaration> parameterDeclarations) {
		List<Expression> arguments = element.getArguments();
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (arguments.size() != parameterDeclarations.size()) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The number of arguments must match the number of parameters.", 
					new ReferenceInfo(ExpressionModelPackage.Literals.ARGUMENTED_ELEMENT__ARGUMENTS, null)));
			return validationResultMessages;
		}
		if (!arguments.isEmpty() && !parameterDeclarations.isEmpty()) {
			for (int i = 0; i < arguments.size() && i < parameterDeclarations.size(); ++i) {
				ParameterDeclaration parameter = parameterDeclarations.get(i);
				Expression argument = arguments.get(i);
				validationResultMessages.addAll(checkTypeAndExpressionConformance(parameter.getType(), argument, 
						ExpressionModelPackage.Literals.ARGUMENTED_ELEMENT__ARGUMENTS));
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkIfThenElseExpression(IfThenElseExpression expression) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (!typeDeterminator2.isBoolean(expression.getCondition())) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The condition of the if-then-else expression must be of type boolean, currently it is: " + 
					typePrinter.print(expression.getCondition()), 
					new ReferenceInfo(ExpressionModelPackage.Literals.IF_THEN_ELSE_EXPRESSION__CONDITION, null)));
		}
		if (!typeDeterminator2.equalsType(expression.getThen(), expression.getElse())) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The return type of the else-branch does not match the type of the then-branch! " +
					"Then: " + typePrinter.print(expression.getThen()) + " - Else: " + typePrinter.print(expression.getElse()), 
					new ReferenceInfo(ExpressionModelPackage.Literals.IF_THEN_ELSE_EXPRESSION__ELSE, null)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkArrayLiteralExpression(ArrayLiteralExpression expression) {
		Type referenceType = null;
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		for (Expression e : expression.getOperands()) {
			Type examinedType = typeDeterminator2.getType(e);
			if (!typeDeterminator2.equals(referenceType, examinedType)) {
				if (referenceType == null) {
					referenceType = examinedType;
				}
				else {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"The operands of the ArrayLiteralExpression are not of the same type!",
							null));
				}
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkRecordAccessExpression(RecordAccessExpression recordAccessExpression) {
		Declaration accessedDeclaration = expressionUtil.getAccessedDeclaration(recordAccessExpression);
		RecordTypeDefinition recordType = (RecordTypeDefinition) ExpressionModelDerivedFeatures.getTypeDefinition(accessedDeclaration);
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (!(accessedDeclaration instanceof ValueDeclaration)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The referred declaration is not accessible as a record!", 
					new ReferenceInfo(ExpressionModelPackage.Literals.ACCESS_EXPRESSION__OPERAND, null)));
			return validationResultMessages;
		}
		// Check if the referred field exists
		List<FieldDeclaration> fieldDeclarations = recordType.getFieldDeclarations();
		Declaration referredField = recordAccessExpression.getFieldReference().getFieldDeclaration();
		if (!fieldDeclarations.contains(referredField)){
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The record type does not contain any fields with the given name.", 
					new ReferenceInfo(ExpressionModelPackage.Literals.RECORD_ACCESS_EXPRESSION__FIELD_REFERENCE, null)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkFunctionAccessExpression(FunctionAccessExpression functionAccessExpression) {
		List<Expression> arguments = functionAccessExpression.getArguments();
		Expression operand = functionAccessExpression.getOperand();
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		// check if the referred object is a function
		if (!(operand instanceof DirectReferenceExpression)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The referenced object is not a valid function declaration!", 
					new ReferenceInfo(ExpressionModelPackage.Literals.ACCESS_EXPRESSION__OPERAND, null)));
			return validationResultMessages;
		}
		DirectReferenceExpression operandAsReference = (DirectReferenceExpression) operand;
		if (!(operandAsReference.getDeclaration() instanceof FunctionDeclaration)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The referenced object is not a valid function declaration!", 
					new ReferenceInfo(ExpressionModelPackage.Literals.ACCESS_EXPRESSION__OPERAND, null)));
			return validationResultMessages;
		}
		// check if the number of arguments equals the number of parameters
		final FunctionDeclaration functionDeclaration = (FunctionDeclaration) operandAsReference.getDeclaration();
		List<ParameterDeclaration> parameters = functionDeclaration.getParameterDeclarations();
		if (arguments.size() != parameters.size()) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The number of arguments does not match the number of declared parameters for the function!", 
					new ReferenceInfo(ExpressionModelPackage.Literals.ARGUMENTED_ELEMENT__ARGUMENTS, null)));
			return validationResultMessages;
		}
		// check if the types of the arguments are the types of the parameters
		int i = 0;
		for (Expression arg : arguments) {
			Type argumentType = typeDeterminator2.getType(arg);
			if (!typeDeterminator2.equals(parameters.get(i).getType(), argumentType)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"The types of the arguments and the types of the declared function parameters do not match!", 
						new ReferenceInfo(ExpressionModelPackage.Literals.ARGUMENTED_ELEMENT__ARGUMENTS, null)));
				return validationResultMessages;
			}
			++i;
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkArrayAccessExpression(ArrayAccessExpression expression) {
		// check if the referred declaration is accessible
		Declaration referredDeclaration = expressionUtil.getDeclaration(expression);
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (!(referredDeclaration instanceof ValueDeclaration)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The referred declaration is not accessible as an array!", 
					new ReferenceInfo(ExpressionModelPackage.Literals.ACCESS_EXPRESSION__OPERAND, null)));
			return validationResultMessages;
		}
		// check if the argument expression can be evaluated as integer
		if (!typeDeterminator2.isInteger(expression.getIndex())) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The index of the accessed element must be of type integer!", 
					new ReferenceInfo(ExpressionModelPackage.Literals.ARRAY_ACCESS_EXPRESSION__INDEX, null)));
			
		}
		// if index evaluated as integer
		else {
			try {
				// check index and size
				int index = expressionEvaluator.evaluateInteger(expression.getIndex());
				int size = expressionEvaluator.evaluateInteger(((ArrayTypeDefinition) referredDeclaration.getType()).getSize()); 
				if (index >= size || index < 0) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"Index out of bounds!", 
							new ReferenceInfo(ExpressionModelPackage.Literals.ARRAY_ACCESS_EXPRESSION__INDEX, null)));
				}
			} catch (Exception exception) {
				// There is a type error on a lower level, no need to display the error message on this level too
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkSelectExpression(SelectExpression expression){
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		// check if the referred object
		if (!(expression.getOperand() instanceof LiteralExpression)) {
			Declaration referredDeclaration = expressionUtil.getDeclaration(expression.getOperand());
			if ((referredDeclaration != null) && !(referredDeclaration instanceof ValueDeclaration)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The specified object is not selectable! This type is: " + typePrinter.print(expression.getOperand()), 
					new ReferenceInfo(ExpressionModelPackage.Literals.ACCESS_EXPRESSION__OPERAND, null)));
				return validationResultMessages;
			}
		}
		if (!(typeDeterminator2.getType(expression.getOperand()) instanceof IntegerLiteralExpression || typeDeterminator2.getType(expression.getOperand()) instanceof IntegerRangeTypeDefinition)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The specified object is not selectable! This type is: " + typePrinter.print(expression.getOperand()), 
					new ReferenceInfo(ExpressionModelPackage.Literals.ACCESS_EXPRESSION__OPERAND, null)));
			return validationResultMessages;
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkElseExpression(ElseExpression expression) {
		EObject container = expression.eContainer();
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (container instanceof Expression) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"Else expressions must not be contained by composite expressions.", 
					new ReferenceInfo(expression.eContainingFeature(), null)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkBooleanExpression(BooleanExpression expression) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (expression instanceof UnaryExpression) {
			// not
			UnaryExpression unaryExpression = (UnaryExpression) expression;
			if (!typeDeterminator2.isBoolean(unaryExpression.getOperand())) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"The operand of this unary boolean operation is evaluated as a non-boolean value.", 
						new ReferenceInfo(ExpressionModelPackage.Literals.UNARY_EXPRESSION__OPERAND, null)));
			}
		}
		else if (expression instanceof BinaryExpression) {
			// equal and imply
			BinaryExpression binaryExpression = (BinaryExpression) expression;
			if (!typeDeterminator2.isBoolean(binaryExpression.getLeftOperand())) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"The left operand of this binary boolean operation is evaluated as a non-boolean value.", 
						new ReferenceInfo(ExpressionModelPackage.Literals.BINARY_EXPRESSION__LEFT_OPERAND, null)));
			}
			if (!typeDeterminator2.isBoolean(binaryExpression.getRightOperand())) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"The right operand of this binary boolean operation is evaluated as a non-boolean value.", 
						new ReferenceInfo(ExpressionModelPackage.Literals.BINARY_EXPRESSION__RIGHT_OPERAND, null)));
			}
		}
		else if (expression instanceof MultiaryExpression) {
			// and or or or xor
			MultiaryExpression multiaryExpression = (MultiaryExpression) expression;
			for (int i = 0; i < multiaryExpression.getOperands().size(); ++i) {
				Expression operand = multiaryExpression.getOperands().get(i);
				if (!typeDeterminator2.isBoolean(operand)) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"This operand of this multiary boolean operation is evaluated as a non-boolean value.", 
							new ReferenceInfo(ExpressionModelPackage.Literals.MULTIARY_EXPRESSION__OPERANDS, i)));
				}
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkPredicateExpression(PredicateExpression expression) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (expression instanceof UnaryExpression) {
			// in expression, semantics not known
		}
		else if (expression instanceof BinaryExpression) {
			// Equivalence
			if (expression instanceof EquivalenceExpression) {
				EquivalenceExpression equivalenceExpression = (EquivalenceExpression) expression;
				Expression lhs = equivalenceExpression.getLeftOperand();
				Expression rhs = equivalenceExpression.getRightOperand();
				Type leftHandSideExpressionType = typeDeterminator2.getType(lhs);
				Type rightHandSideExpressionType = typeDeterminator2.getType(rhs);
				if (!typeDeterminator2.equalsType(lhs, rhs)) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"The left and right hand sides are not compatible: " + typePrinter.print(leftHandSideExpressionType) + " and " + typePrinter.print(rightHandSideExpressionType), 
							new ReferenceInfo(ExpressionModelPackage.Literals.BINARY_EXPRESSION__RIGHT_OPERAND, null)));
				}
			}
			// Comparison
			if (expression instanceof ComparisonExpression) {
				ComparisonExpression binaryExpression = (ComparisonExpression) expression;
				if (!typeDeterminator2.isNumber(binaryExpression.getLeftOperand())) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"The left operand of this binary predicate expression is evaluated as a non-comparable value.", 
							new ReferenceInfo(ExpressionModelPackage.Literals.BINARY_EXPRESSION__LEFT_OPERAND, null)));
				}
				if (!typeDeterminator2.isNumber(binaryExpression.getRightOperand())) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"The right operand of this binary predicate expression is evaluated as a non-comparable value.", 
							new ReferenceInfo(ExpressionModelPackage.Literals.BINARY_EXPRESSION__RIGHT_OPERAND, null)));
					
				}
			}
		}	
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkTypeAndTypeConformance(Type lhs, Type rhs, EStructuralFeature feature) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (!typeDeterminator2.equals(lhs, rhs)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The types of the left hand side and the right hand side are not the same: " +
									typePrinter.print(lhs) + " and " +
									typePrinter.print(rhs) + ".", 
					new ReferenceInfo(feature, null)));
			return validationResultMessages;
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkTypeAndExpressionConformance(Type lhsExpressionType, Expression rhs, EStructuralFeature feature) {
		//ExpressionType lhsExpressionType = typeDeterminator.transform(type);
		Type rhsExpressionType = typeDeterminator2.getType(rhs);
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (!typeDeterminator2.equals(lhsExpressionType, rhsExpressionType)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The types of the declaration and the assigned expression are not the same: " +
									typePrinter.print(lhsExpressionType) + " and " +
									typePrinter.print(rhsExpressionType) + ".", 
					new ReferenceInfo(feature, null)));
			return validationResultMessages;
		}

		return validationResultMessages;
	}
		
	public Collection<ValidationResultMessage> checkArithmeticExpression(ArithmeticExpression expression) {
		
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		
		if (expression instanceof UnaryExpression) {
			// + or -
			UnaryExpression unaryExpression = (UnaryExpression) expression;
			if (!typeDeterminator2.isNumber(unaryExpression.getOperand())) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"The operand of this unary arithemtic operation is evaluated as a non-number value.", 
						new ReferenceInfo(ExpressionModelPackage.Literals.UNARY_EXPRESSION__OPERAND, null)));
			}
		}
		else if (expression instanceof BinaryExpression) {
			// - or / or mod or div
			BinaryExpression binaryExpression = (BinaryExpression) expression;
			if (expression instanceof ModExpression || expression instanceof DivExpression) {
				// Only integers can be operands
				if (!typeDeterminator2.isInteger(binaryExpression.getLeftOperand())) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"The left operand of this binary arithemtic operation is evaluated as a non-integer value.", 
							new ReferenceInfo(ExpressionModelPackage.Literals.BINARY_EXPRESSION__LEFT_OPERAND, null)));
				}
				if (!typeDeterminator2.isInteger(binaryExpression.getRightOperand())) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"The right operand of this binary arithemtic operation is evaluated as a non-integer value.", 
							new ReferenceInfo(ExpressionModelPackage.Literals.BINARY_EXPRESSION__RIGHT_OPERAND, null)));
				}
			}
			else {
				if (!typeDeterminator2.isNumber(binaryExpression.getLeftOperand())) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"The left operand of this binary arithemtic operation is evaluated as a non-number value.", 
							new ReferenceInfo(ExpressionModelPackage.Literals.BINARY_EXPRESSION__LEFT_OPERAND, null)));
				}
				if (!typeDeterminator2.isNumber(binaryExpression.getRightOperand())) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"The right operand of this binary arithemtic operation is evaluated as a non-number value.", 
							new ReferenceInfo(ExpressionModelPackage.Literals.BINARY_EXPRESSION__RIGHT_OPERAND, null)));
				}
			}
		}
		else if (expression instanceof MultiaryExpression) {
			// + or *
			MultiaryExpression multiaryExpression = (MultiaryExpression) expression;
			for (int i = 0; i < multiaryExpression.getOperands().size(); ++i) {
				Expression operand = multiaryExpression.getOperands().get(i);
				if (!typeDeterminator2.isNumber(operand)) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"This operand of this multiary arithemtic operation is evaluated as a non-number value.", 
							new ReferenceInfo(ExpressionModelPackage.Literals.MULTIARY_EXPRESSION__OPERANDS, i)));
				}
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkInitializableElement(InitializableElement elem) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		try {
			Expression initialExpression = elem.getExpression();
			if (initialExpression == null) {
				return validationResultMessages;
			}
			// The declaration has an initial value
			EObject container = elem.eContainer();
			if (elem instanceof Declaration) {
				Declaration declaration = (Declaration) elem;
				for (VariableDeclaration variableDeclaration : expressionUtil.getReferredVariables(initialExpression)) {
					if (container == variableDeclaration.eContainer()) {
						final EList<EObject> eContents = container.eContents();
						int elemIndex = eContents.indexOf(elem);
						int variableIndex = eContents.indexOf(variableDeclaration);
						if (variableIndex >= elemIndex) {
							validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
									"The declarations referenced in the initial value must be declared before the variable declaration.", 
									new ReferenceInfo(ExpressionModelPackage.Literals.INITIALIZABLE_ELEMENT__EXPRESSION, null)));
							
							return validationResultMessages;
						}
					}
				}
				// Initial value is correct
				Type variableDeclarationType = declaration.getType();
				Type initialExpressionType = typeDeterminator2.getType(elem.getExpression());
				if (!typeDeterminator2.equals(variableDeclarationType, initialExpressionType)) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"The types of the declaration and the right hand side expression are not the same: " +
									typePrinter.print(variableDeclarationType) + " and " +
									typePrinter.print(initialExpressionType) + ".", 
							new ReferenceInfo(ExpressionModelPackage.Literals.INITIALIZABLE_ELEMENT__EXPRESSION, null)));
				}
				// Additional checks for arrays
				ArrayTypeDefinition arrayType = null;
				if (ExpressionModelDerivedFeatures.getTypeDefinition(declaration) instanceof ArrayTypeDefinition) {
					arrayType = (ArrayTypeDefinition) declaration.getType();
				}
				if (arrayType != null) {	
					if (initialExpression instanceof ArrayLiteralExpression) {
						ArrayLiteralExpression rhs = (ArrayLiteralExpression) initialExpression;
						Type elementType = typeDeterminator2.removeTypeReferences(arrayType.getElementType());
						for (Expression e : rhs.getOperands()) {
							if (!typeDeterminator2.equals(elementType, typeDeterminator2.getType(e))) {
								validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
										"The elements on the right hand side must be of the declared type of the array.", 
										new ReferenceInfo(ExpressionModelPackage.Literals.INITIALIZABLE_ELEMENT__EXPRESSION, null)));
							}
						}
						// Array size must equal with number of array literal's elements
						if (rhs.getOperands().size() != expressionEvaluator.evaluateInteger(arrayType.getSize())) {
							validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
									"The number of the elements on the right hand side must be equal then the size of the array.",
									new ReferenceInfo(ExpressionModelPackage.Literals.INITIALIZABLE_ELEMENT__EXPRESSION, null)));
						}						
					}
					else {
						validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
								"The right hand side must be of type array literal.", 
								new ReferenceInfo(ExpressionModelPackage.Literals.INITIALIZABLE_ELEMENT__EXPRESSION, null)));
					}
				}
			}
		} catch (Exception exception) {
			// There is a type error on a lower level, no need to display the error message on this level too
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkArrayTypeDefinition(ArrayTypeDefinition arrayType) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		try {
			// The size of the array must be given as an integer
			if (!typeDeterminator2.isInteger(arrayType.getSize())) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"The size of the array must be given as an integer.",
						new ReferenceInfo(ExpressionModelPackage.Literals.ARRAY_TYPE_DEFINITION__SIZE, null)));
			}
			// Array init size must be greater then 0
			if (expressionEvaluator.evaluateInteger(arrayType.getSize()) <= 0) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"The size of the array must be greater then 0.",
						new ReferenceInfo(ExpressionModelPackage.Literals.ARRAY_TYPE_DEFINITION__SIZE, null)));
			}
		} catch (Exception exception) {
			// There is a type error on a lower level, no need to display the error message on this level too
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkSelfComparison(PredicateExpression expression) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();		
		// BinaryExpression
		if (expression instanceof BinaryExpression) {
			BinaryExpression binaryExpression = (BinaryExpression) expression;
			// the left and the right hand sides same
			if (ecoreUtil.helperEquals(binaryExpression.getLeftOperand(), binaryExpression.getRightOperand())) {
				// EquivalenceExpression
				if (expression instanceof EquivalenceExpression) {
					EquivalenceExpression equivalenceExpression = (EquivalenceExpression) expression;
					// EqualityExpression
					if (equivalenceExpression instanceof EqualityExpression) {
						validationResultMessages.add(new ValidationResultMessage(ValidationResult.INFO,
								"This expression is always true, because the left and right hand sides are same!",
								new ReferenceInfo(ExpressionModelPackage.Literals.BINARY_EXPRESSION__RIGHT_OPERAND, null)));
					}
					//InequalityExpressin
					if (equivalenceExpression instanceof InequalityExpression) {
						validationResultMessages.add(new ValidationResultMessage(ValidationResult.INFO,
								"This expression is always false, because the left and right hand sides are same!",
								new ReferenceInfo(ExpressionModelPackage.Literals.BINARY_EXPRESSION__RIGHT_OPERAND, null)));
					}
				}
				// ComparisionExpression
				else if (expression instanceof ComparisonExpression) {
					ComparisonExpression comparisionExpression = (ComparisonExpression) expression;
					if (comparisionExpression instanceof LessEqualExpression || comparisionExpression instanceof GreaterEqualExpression) {
						validationResultMessages.add(new ValidationResultMessage(ValidationResult.INFO,
								"This expression is always true, because the left and right hand sides are same!",
								new ReferenceInfo(ExpressionModelPackage.Literals.BINARY_EXPRESSION__RIGHT_OPERAND, null)));
					}
					if (comparisionExpression instanceof LessExpression || comparisionExpression instanceof GreaterExpression) {
						validationResultMessages.add(new ValidationResultMessage(ValidationResult.INFO,
								"This expression is always false, because the left and right hand sides are same!",
								new ReferenceInfo(ExpressionModelPackage.Literals.BINARY_EXPRESSION__RIGHT_OPERAND, null)));
					}
				}
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkDivZero(ArithmeticExpression expression) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		try {
			// BinaryExpression
			if (expression instanceof BinaryExpression) {
				BinaryExpression binaryExpression = (BinaryExpression) expression;
				// DivideExpression, DivExpression, ModExpression
				if (expression instanceof DivideExpression || expression instanceof DivExpression || expression instanceof ModExpression) {
					// right hand side is zero
					if (expressionEvaluator.evaluateInteger(binaryExpression.getRightOperand()) == 0) {
						validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
								"Division by zero is not allowed.",
								new ReferenceInfo(ExpressionModelPackage.Literals.BINARY_EXPRESSION__RIGHT_OPERAND, null)));
					}
				}
			}
		} catch (Exception exception) {
			// There is a type error on a lower level, no need to display the error message on this level too
		}
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkRecordSelfReference(TypeDeclaration typeDeclaration) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		// visited TypeDeclaration
		List<TypeDeclaration> visitedNodes = new ArrayList<TypeDeclaration>();
		visitedNodes.add(typeDeclaration);
		// search for self-reference
		validationResultMessages.addAll(checkRecordSelfReferenceHelp(typeDeclaration, visitedNodes));

		return validationResultMessages;
	}
	
	private Collection<ValidationResultMessage> checkRecordSelfReferenceHelp(TypeDeclaration typeDeclaration, List<TypeDeclaration> visitedNodes) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		// RecordTypeDefinition
		Type type = visitedNodes.get(0).getType();
		if (type instanceof RecordTypeDefinition) {
			// check all FieldDeclarations
			RecordTypeDefinition recordTypeDefinition = (RecordTypeDefinition) type;
			for (FieldDeclaration fieldDeclaration : recordTypeDefinition.getFieldDeclarations()) {
				// TypeReference
				Type fieldType = (Type) fieldDeclaration.getType();
				if (fieldType instanceof TypeReference) {
					TypeReference fieldTypeReference = (TypeReference) fieldType;
					TypeDeclaration fieldReferencedTypeDeclaration = fieldTypeReference.getReference();
					// equal with checked record
					if (fieldReferencedTypeDeclaration == typeDeclaration) {
						validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
								"Record cannot store itself either directly or indirectly! " +
								visitedNodes.get(0).getName().toUpperCase() + " stores " +
								typeDeclaration.getName().toUpperCase(),
								new ReferenceInfo(ExpressionModelPackage.Literals.DECLARATION__TYPE, null)));
					}
					// check - if it doesn't equal with checked record and if it isn't visited record
					else if (!visitedNodes.contains(fieldReferencedTypeDeclaration)) {
						visitedNodes.add(0, fieldReferencedTypeDeclaration);
						validationResultMessages.addAll(checkRecordSelfReferenceHelp(typeDeclaration, visitedNodes));
					}
				}
			}
		}
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkRationalLiteralExpression(RationalLiteralExpression expression) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		try {
			// check denominator
			if (expression.getDenominator().intValue() == 0) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"The denominator cannot be zero.",
						new ReferenceInfo(ExpressionModelPackage.Literals.RATIONAL_LITERAL_EXPRESSION__DENOMINATOR, null)));
			}
		} catch (Exception exception) {
			// There is a type error on a lower level, no need to display the error message on this level too
		}
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkRecordLiteralExpression(RecordLiteralExpression expression) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		// find RecordTypeDefinition
		TypeDeclaration typeDeclaration = expression.getTypeDeclaration();
		Type type = typeDeclaration.getType();
		RecordTypeDefinition recordTypeDefinition = (RecordTypeDefinition) type;
		// check all FieldDeclaration and all FieldAssignment
		for (FieldDeclaration rTypeField : recordTypeDefinition.getFieldDeclarations()) {
			int counter = 0;
			for (FieldAssignment rLiFieldAssignment : expression.getFieldAssignments()) {
				FieldReferenceExpression fieldReferenceExpression = rLiFieldAssignment.getReference();
				FieldDeclaration fieldDeclaration = fieldReferenceExpression.getFieldDeclaration();
				// same fields
				if (fieldDeclaration == rTypeField) {
					counter++;
				}
			}
			// this field has no value
			if (counter == 0) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"All fields in the definition must have a value!",
						new ReferenceInfo(ExpressionModelPackage.Literals.RECORD_LITERAL_EXPRESSION__FIELD_ASSIGNMENTS, null)));
			}
			// this field has more than once value
			if (counter >= 2) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"You cannot add value to a field more than once!",
						new ReferenceInfo(ExpressionModelPackage.Literals.RECORD_LITERAL_EXPRESSION__FIELD_ASSIGNMENTS, null)));
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkIntegerRangeLiteralExpression(IntegerRangeLiteralExpression expression) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		// check left operand
		if (!typeDeterminator2.isInteger(expression.getLeftOperand())) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The operands of the integer range must be integers, but now the left operand is not an integer! The type of the left operand is: " + 
					typePrinter.print(expression.getLeftOperand()),
					new ReferenceInfo(ExpressionModelPackage.Literals.INTEGER_RANGE_LITERAL_EXPRESSION__LEFT_INCLUSIVE, null)));
		}
		// check right operand		
		if (!typeDeterminator2.isInteger(expression.getRightOperand())) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The operands of the integer range must be integers, but now the right operand is not an integer! The type of the right operand is: " + 
					typePrinter.print(expression.getRightOperand()),
					new ReferenceInfo(ExpressionModelPackage.Literals.INTEGER_RANGE_LITERAL_EXPRESSION__RIGHT_INCLUSIVE, null)));
		}
		return validationResultMessages;
	}
	
	// Internal classes for validation result
	
	public enum ValidationResult {
		// Enum literals that determine the type of the message: error, info, warning.
		ERROR, INFO, WARNING
	}
	
	static public class ValidationResultMessage {
		
		private ValidationResult result;
		private String resultText;
		private ReferenceInfo referenceInfo;
		
		public ValidationResultMessage(ValidationResult result, String resultText,
				ReferenceInfo referenceInfo){
			this.result = result;
			this.resultText = resultText;
			this.referenceInfo = referenceInfo;
		}
		
		public ValidationResult getResult() {
			return result;
		}
		
		public String getResultText() {
			return resultText;
		}
		
		public ReferenceInfo getReferenceInfo() {
			return referenceInfo;
		}
		
	}
	
	static public class ReferenceInfo{
		
		private EStructuralFeature reference;
		private EObject source;
		private Integer index;
		
		public ReferenceInfo(EStructuralFeature reference){
			this(reference, null);
		}
		
		public ReferenceInfo(EStructuralFeature reference, Integer index){
			this(reference, index, null);
		}
		
		public ReferenceInfo(EStructuralFeature reference, Integer index, EObject source) {
			this.reference = reference;
			this.index = index;
			this.source = source;
		}
		
		public boolean hasSource() {
			return source != null;
		}
		
		public boolean hasInteger() {
			return index != null;
		}
		
		public EObject getSource() {
			return source;
		}
		
		public int getIndex() {
			return index;
		}
		
		public EStructuralFeature getReference() {
			return reference;
		}
	}
	
}
