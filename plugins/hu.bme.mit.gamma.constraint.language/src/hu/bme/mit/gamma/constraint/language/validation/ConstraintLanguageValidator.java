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
package hu.bme.mit.gamma.constraint.language.validation;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.stream.Collectors;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.xtext.EcoreUtil2;
import org.eclipse.xtext.validation.Check;

import hu.bme.mit.gamma.constraint.model.AddExpression;
import hu.bme.mit.gamma.constraint.model.ArithmeticExpression;
import hu.bme.mit.gamma.constraint.model.BinaryExpression;
import hu.bme.mit.gamma.constraint.model.BooleanExpression;
import hu.bme.mit.gamma.constraint.model.BooleanLiteralExpression;
import hu.bme.mit.gamma.constraint.model.BooleanTypeDefinition;
import hu.bme.mit.gamma.constraint.model.ComparisonExpression;
import hu.bme.mit.gamma.constraint.model.ConstraintModelPackage;
import hu.bme.mit.gamma.constraint.model.DecimalLiteralExpression;
import hu.bme.mit.gamma.constraint.model.Declaration;
import hu.bme.mit.gamma.constraint.model.DefinableDeclaration;
import hu.bme.mit.gamma.constraint.model.DivExpression;
import hu.bme.mit.gamma.constraint.model.DivideExpression;
import hu.bme.mit.gamma.constraint.model.ElseExpression;
import hu.bme.mit.gamma.constraint.model.EnumerationLiteralExpression;
import hu.bme.mit.gamma.constraint.model.EnumerationTypeDefinition;
import hu.bme.mit.gamma.constraint.model.Expression;
import hu.bme.mit.gamma.constraint.model.IntegerLiteralExpression;
import hu.bme.mit.gamma.constraint.model.IntegerTypeDefinition;
import hu.bme.mit.gamma.constraint.model.ModExpression;
import hu.bme.mit.gamma.constraint.model.MultiaryExpression;
import hu.bme.mit.gamma.constraint.model.MultiplyExpression;
import hu.bme.mit.gamma.constraint.model.NamedElement;
import hu.bme.mit.gamma.constraint.model.NaturalTypeDefinition;
import hu.bme.mit.gamma.constraint.model.PredicateExpression;
import hu.bme.mit.gamma.constraint.model.RationalLiteralExpression;
import hu.bme.mit.gamma.constraint.model.RealTypeDefinition;
import hu.bme.mit.gamma.constraint.model.ReferenceExpression;
import hu.bme.mit.gamma.constraint.model.SubtractExpression;
import hu.bme.mit.gamma.constraint.model.Type;
import hu.bme.mit.gamma.constraint.model.TypeDeclaration;
import hu.bme.mit.gamma.constraint.model.TypeReference;
import hu.bme.mit.gamma.constraint.model.UnaryExpression;
import hu.bme.mit.gamma.constraint.model.UnaryMinusExpression;
import hu.bme.mit.gamma.constraint.model.UnaryPlusExpression;

/**
 * This class contains custom validation rules. 
 *
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
public class ConstraintLanguageValidator extends AbstractConstraintLanguageValidator {
	
	protected ExpressionTypeDeterminator typeDeterminator = new ExpressionTypeDeterminator();
	
	@Check
	public void checkNameUniqueness(NamedElement element) {
		Collection<? extends NamedElement> namedElements = EcoreUtil2.getAllContentsOfType(EcoreUtil2.getRootContainer(element), element.getClass());
		namedElements.remove(element);
		for (NamedElement elem : namedElements) {
			if (element.getName().equals(elem.getName())) {
				error("Names must be unique!", ConstraintModelPackage.Literals.NAMED_ELEMENT__NAME);
			}
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
						ConstraintModelPackage.Literals.UNARY_EXPRESSION__OPERAND);
			}
		}
		else if (expression instanceof BinaryExpression) {
			// equal and imply
			BinaryExpression binaryExpression = (BinaryExpression) expression;
			if (!typeDeterminator.isBoolean(binaryExpression.getLeftOperand())) {
				error("The left operand of this binary boolean operation is evaluated as a non-boolean value.",
						ConstraintModelPackage.Literals.BINARY_EXPRESSION__LEFT_OPERAND);
			}
			if (!typeDeterminator.isBoolean(binaryExpression.getRightOperand())) {
				error("The right operand of this binary boolean operation is evaluated as a non-boolean value.",
						ConstraintModelPackage.Literals.BINARY_EXPRESSION__RIGHT_OPERAND);
			}
		}
		else if (expression instanceof MultiaryExpression) {
			// and or or or xor
			MultiaryExpression multiaryExpression = (MultiaryExpression) expression;
			for (int i = 0; i < multiaryExpression.getOperands().size(); ++i) {
				Expression operand = multiaryExpression.getOperands().get(i);
				if (!typeDeterminator.isBoolean(operand)) {
					error("This operand of this multiary boolean operation is evaluated as a non-boolean value.",
							ConstraintModelPackage.Literals.MULTIARY_EXPRESSION__OPERANDS, i);
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
			// equivalence and comparison
			// No need to validate equivalence, it is interpreted between anything
			if (expression instanceof ComparisonExpression) {
				ComparisonExpression binaryExpression = (ComparisonExpression) expression;
				if (!typeDeterminator.isNumber(binaryExpression.getLeftOperand())) {
					error("The left operand of this binary predicate expression is evaluated as a non-comparable value.",
							ConstraintModelPackage.Literals.BINARY_EXPRESSION__LEFT_OPERAND);
				}
				if (!typeDeterminator.isNumber(binaryExpression.getRightOperand())) {
					error("The right operand of this binary predicate expression is evaluated as a non-comparable value.",
							ConstraintModelPackage.Literals.BINARY_EXPRESSION__RIGHT_OPERAND);
				}
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
						ConstraintModelPackage.Literals.UNARY_EXPRESSION__OPERAND);
			}
		}
		else if (expression instanceof BinaryExpression) {
			// - or / or mod or div
			BinaryExpression binaryExpression = (BinaryExpression) expression;
			if (expression instanceof ModExpression || expression instanceof DivExpression) {
				// Only integers can be operands
				if (!typeDeterminator.isInteger(binaryExpression.getLeftOperand())) {
					error("The left operand of this binary arithemtic operation is evaluated as a non-integer value.",
							ConstraintModelPackage.Literals.BINARY_EXPRESSION__LEFT_OPERAND);
				}
				if (!typeDeterminator.isInteger(binaryExpression.getRightOperand())) {
					error("The right operand of this binary arithemtic operation is evaluated as a non-integer value.",
							ConstraintModelPackage.Literals.BINARY_EXPRESSION__RIGHT_OPERAND);
				}
			}
			else {
				if (!typeDeterminator.isNumber(binaryExpression.getLeftOperand())) {
					error("The left operand of this binary arithemtic operation is evaluated as a non-number value.",
							ConstraintModelPackage.Literals.BINARY_EXPRESSION__LEFT_OPERAND);
				}
				if (!typeDeterminator.isNumber(binaryExpression.getRightOperand())) {
					error("The right operand of this binary arithemtic operation is evaluated as a non-number value.",
							ConstraintModelPackage.Literals.BINARY_EXPRESSION__RIGHT_OPERAND);
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
							ConstraintModelPackage.Literals.MULTIARY_EXPRESSION__OPERANDS, i);
				}
			}
		}
	}
	
	@Check
	public void checkDefinableDeclaration(DefinableDeclaration declaration) {
		try {
			Expression initialExpression = declaration.getExpression();
			if (initialExpression == null) {
				return;
			}
			// The declaration has an initial value
			if (isDeclarationReferredInExpression(declaration, initialExpression)) {
				error("The initial value must not be the declaration itself.", ConstraintModelPackage.Literals.DEFINABLE_DECLARATION__EXPRESSION);
				return;
			}
			Type variableDeclarationType = declaration.getType();
			ExpressionType initialExpressionType = typeDeterminator.getType(declaration.getExpression());
			if (!typeDeterminator.equals(variableDeclarationType, initialExpressionType)) {
				error("The types of the declaration and the right hand side expression are not the same: " +
						typeDeterminator.transform(variableDeclarationType).toString().toLowerCase() + " and " +
						initialExpressionType.toString().toLowerCase() + ".",
						ConstraintModelPackage.Literals.DEFINABLE_DECLARATION__EXPRESSION);
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
	
	protected enum ExpressionType { BOOLEAN, NATURAL, INTEGER, REAL, ENUMERATION, ERROR }

	protected class ExpressionTypeDeterminator {
		
		/**
		 * Collector of extension methods.
		 */
		public ExpressionType getType(Expression expression) {
			if (expression instanceof BooleanLiteralExpression) {
				return getType((BooleanLiteralExpression) expression);
			}
			if (expression instanceof IntegerLiteralExpression) {
				return getType((IntegerLiteralExpression) expression);
			}
			if (expression instanceof RationalLiteralExpression) {
				return getType((RationalLiteralExpression) expression);
			}
			if (expression instanceof DecimalLiteralExpression) {
				return getType((DecimalLiteralExpression) expression);
			}
			if (expression instanceof EnumerationLiteralExpression) {
				return getType((EnumerationLiteralExpression) expression);
			}
			if (expression instanceof ReferenceExpression) {
				return getType((ReferenceExpression) expression);
			}
			if (expression instanceof ElseExpression) {
				return getType((ElseExpression) expression);
			}
			if (expression instanceof BooleanExpression) {
				return getType((BooleanExpression) expression);
			}
			if (expression instanceof PredicateExpression) {
				return getType((PredicateExpression) expression);
			}
			if (expression instanceof UnaryPlusExpression) {
				return getArithmeticUnaryType((UnaryPlusExpression) expression);
			}
			if (expression instanceof UnaryMinusExpression) {
				return getArithmeticUnaryType((UnaryMinusExpression) expression);
			}
			if (expression instanceof SubtractExpression) {
				return getArithmeticBinaryType((SubtractExpression) expression);
			}
			if (expression instanceof DivideExpression) {
				return getArithmeticBinaryType((DivideExpression) expression);
			}
			if (expression instanceof ModExpression) {
				return getArithmeticBinaryIntegerType((ModExpression) expression);
			}
			if (expression instanceof DivExpression) {
				return getArithmeticBinaryIntegerType((DivExpression) expression);
			}
			if (expression instanceof AddExpression) {
				return getArithmeticMultiaryType((AddExpression) expression);
			}
			if (expression instanceof MultiplyExpression) {
				return getArithmeticMultiaryType((MultiplyExpression) expression);
			}
			throw new IllegalArgumentException("Not known expression: " + expression);
		}
		
		// Extension methods
		
		// Literals
		
		private ExpressionType getType(BooleanLiteralExpression expression) {
			return ExpressionType.BOOLEAN;
		}
		
		private ExpressionType getType(IntegerLiteralExpression expression) {
			return ExpressionType.INTEGER;
		}
		
		private ExpressionType getType(RationalLiteralExpression expression) {
			return ExpressionType.REAL;
		}
		
		private ExpressionType getType(DecimalLiteralExpression expression) {
			return ExpressionType.REAL;
		}
		
		private ExpressionType getType(EnumerationLiteralExpression expression) {
			return ExpressionType.ENUMERATION;
		}
		
		// References
		
		private ExpressionType getType(ReferenceExpression expression) {
			Type declarationType = expression.getDeclaration().getType();
			return transform(declarationType);
		}
		
		// Else
		
		private ExpressionType getType(ElseExpression expression) {
			return ExpressionType.BOOLEAN;
		}
		
		// Boolean
		
		private ExpressionType getType(BooleanExpression expression) {
			return ExpressionType.BOOLEAN;
		}
		
		// Predicate
		
		private ExpressionType getType(PredicateExpression expression) {
			return ExpressionType.BOOLEAN;
		}
		
		// Arithmetics
		
		private ExpressionType getArithmeticType(Collection<ExpressionType> collection) {
			// Wrong types, not suitable for arithmetic operations
			if (collection.stream().anyMatch(it -> !isNumber(it))) {
				throw new IllegalArgumentException("Type is not suitable for arithmetic operations: " + collection);
			}
			// All types are numbers
			if (collection.stream().anyMatch(it -> it == ExpressionType.REAL)) {
				return ExpressionType.REAL;
			}
			if (collection.stream().anyMatch(it -> it == ExpressionType.INTEGER)) {
				return ExpressionType.INTEGER;
			}
			return ExpressionType.NATURAL;
		}
		
		// Unary
		
		/**
		 * Unary plus and minus.
		 */
		private <T extends ArithmeticExpression & UnaryExpression> ExpressionType getArithmeticUnaryType(T expression) {
			ExpressionType type = getType(expression.getOperand());
			if (isNumber(type)) {
				return type;
			}
			throw new IllegalArgumentException("Type is not suitable type for expression: " + type + System.lineSeparator() + expression);
		}
		
		// Binary
		
		/**
		 * Subtract and divide.
		 */
		private <T extends ArithmeticExpression & BinaryExpression> ExpressionType getArithmeticBinaryType(T expression) {
			List<ExpressionType> types = new ArrayList<ExpressionType>();
			types.add(getType(expression.getLeftOperand()));
			types.add(getType(expression.getRightOperand()));		
			return getArithmeticType(types);
		}
		
		/**
		 * Modulo and div.
		 */
		private <T extends ArithmeticExpression & BinaryExpression> ExpressionType getArithmeticBinaryIntegerType(T expression) {
			ExpressionType type = getArithmeticBinaryType(expression);
			if (type == ExpressionType.INTEGER || type == ExpressionType.NATURAL) {
				return type;
			}
			throw new IllegalArgumentException("Type is not suitable type for expression: " + type + System.lineSeparator() + expression);
		}
		
		// Multiary
		
		/**
		 * Add and multiply.
		 */
		private <T extends ArithmeticExpression & MultiaryExpression> ExpressionType getArithmeticMultiaryType(T expression) {
			Collection<ExpressionType> types = expression.getOperands().stream()
					.map(it -> getType(it)).collect(Collectors.toSet());
			return getArithmeticType(types);
		}
		
		// Easy determination of boolean and number types
		
		public boolean isBoolean(Expression	expression) {
			if (expression instanceof ReferenceExpression) {
				ReferenceExpression referenceExpression = (ReferenceExpression) expression;
				Declaration declaration = referenceExpression.getDeclaration();
				Type declarationType = declaration.getType();
				return transform(declarationType) == ExpressionType.BOOLEAN;
			}
			return expression instanceof BooleanExpression || expression instanceof PredicateExpression ||
				expression instanceof ElseExpression;
		}
		
		private boolean isInteger(ExpressionType type) {
			return type == ExpressionType.INTEGER ||
					type == ExpressionType.NATURAL;
		}
		
		public boolean isInteger(Expression expression) {
			return isInteger(getType(expression));
		}
		
		private boolean isNumber(ExpressionType type) {
			return type == ExpressionType.INTEGER ||
					type == ExpressionType.REAL || 
					type == ExpressionType.NATURAL;
		}
		
		public boolean isNumber(Expression expression) {
			if (expression instanceof ReferenceExpression) {
				ReferenceExpression referenceExpression = (ReferenceExpression) expression;
				Declaration declaration = referenceExpression.getDeclaration();
				Type declarationType = declaration.getType();
				return isNumber(transform(declarationType));
			}
			return expression instanceof ArithmeticExpression;
		}
		
		// Transform type
		
		public ExpressionType transform(Type type) {
			if (type == null) {
				// During editing the type of the reference expression can be null
				return ExpressionType.ERROR;
			}
			if (type instanceof BooleanTypeDefinition) {
				return ExpressionType.BOOLEAN;
			}
			if (type instanceof IntegerTypeDefinition) {
				return ExpressionType.INTEGER;
			}
			if (type instanceof RealTypeDefinition) {
				return ExpressionType.REAL;
			}
			if (type instanceof NaturalTypeDefinition) {
				return ExpressionType.NATURAL;
			}
			if (type instanceof EnumerationTypeDefinition) {
				return ExpressionType.ENUMERATION;
			}
			if (type instanceof TypeReference) {
				TypeReference reference = (TypeReference) type;
				TypeDeclaration declaration = reference.getReference();
				Type declaredType = declaration.getType();
				return transform(declaredType);
			}
			throw new IllegalArgumentException("Not known type: " + type);
		}
		
		// Type equal
		
		public boolean equals(Type type, ExpressionType expressionType) {
			return type instanceof BooleanTypeDefinition && expressionType == ExpressionType.BOOLEAN ||
				type instanceof IntegerTypeDefinition && expressionType == ExpressionType.INTEGER ||
				type instanceof RealTypeDefinition && expressionType == ExpressionType.REAL ||
				type instanceof NaturalTypeDefinition && expressionType == ExpressionType.NATURAL||
				type instanceof EnumerationTypeDefinition && expressionType == ExpressionType.ENUMERATION;
		}
		
	}

}