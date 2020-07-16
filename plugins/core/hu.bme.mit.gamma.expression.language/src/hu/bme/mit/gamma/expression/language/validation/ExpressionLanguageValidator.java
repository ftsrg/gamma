/********************************************************************************
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

import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EStructuralFeature;
import org.eclipse.emf.ecore.util.EcoreUtil;
import org.eclipse.xtext.EcoreUtil2;
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
import hu.bme.mit.gamma.expression.model.TypeDeclaration;
import hu.bme.mit.gamma.expression.model.TypeReference;
import hu.bme.mit.gamma.expression.model.UnaryExpression;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator;
import hu.bme.mit.gamma.expression.util.ExpressionUtil;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

/**
 * This class contains custom validation rules. 
 *
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
public class ExpressionLanguageValidator extends AbstractExpressionLanguageValidator {
	
	protected ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE;
	protected ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE;
	protected ExpressionTypeDeterminator typeDeterminator = ExpressionTypeDeterminator.INSTANCE;
	protected GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	
	@Check
	public void checkNameUniqueness(NamedElement element) {
		String name = element.getName();
		EObject root = EcoreUtil.getRootContainer(element);
		Collection<? extends NamedElement> namedElements = EcoreUtil2.getAllContentsOfType(root, element.getClass());
		namedElements.remove(element);
		for (NamedElement otherElement : namedElements) {
			if (name.equals(otherElement.getName())) {
				error("In a Gamma model every identifier must be unique.", ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME);
			}
		}
	}
	
	@Check
	public void checkTypeDeclaration(TypeDeclaration typeDeclaration) {
		Type type = typeDeclaration.getType();
		if (type instanceof TypeReference) {
			TypeReference typeReference = (TypeReference) type;
			TypeDeclaration referencedTypeDeclaration = typeReference.getReference();
			if (typeDeclaration == referencedTypeDeclaration) {
				error("A type declaration cannot reference itself as a type definition.", ExpressionModelPackage.Literals.DECLARATION__TYPE);
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
		if (true) {
			// Blocked as it throws exceptions
			return;
		}
		RecordTypeDefinition rtd = (RecordTypeDefinition) ExpressionLanguageValidatorUtil.
				findAccessExpressionTypeDefinition(recordAccessExpression);
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
		if (true) {
			// Blocked as it throws exceptions
			return;
		}
		List<Expression> arguments = functionAccessExpression.getArguments();
		if (functionAccessExpression.getOperand() instanceof ReferenceExpression) {
			ReferenceExpression ref = (ReferenceExpression) functionAccessExpression.getOperand();
			if (ref.getDeclaration() instanceof FunctionDeclaration) {
				final FunctionDeclaration functionDeclaration = (FunctionDeclaration) ref.getDeclaration();
				List<ParameterDeclaration> parameters = functionDeclaration.getParameterDeclarations();
				if (arguments.size() != parameters.size()) {
					error("The number of arguments does not match the number of declared parameters for the function!", 
							ExpressionModelPackage.Literals.ARGUMENTED_ELEMENT__ARGUMENTS);
				}
				int i = 0;
				for (Expression arg : arguments) {
					ExpressionType argumentType = typeDeterminator.getType(arg);
					if (!typeDeterminator.equals(parameters.get(i).getType(), argumentType)) {
						error("The types of the arguments and the types of the declared function parameters do not match!",
								ExpressionModelPackage.Literals.ARGUMENTED_ELEMENT__ARGUMENTS);
					}
					++i;
				}
			}
			else {
				error("The referenced object is not a function declaration!", ExpressionModelPackage.Literals.ACCESS_EXPRESSION__OPERAND);
			}
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
				ExpressionType leftHandSideExpressionType = typeDeterminator.getType(lhs);
				ExpressionType rightHandSideExpressionType = typeDeterminator.getType(rhs);
				if (!leftHandSideExpressionType.equals(rightHandSideExpressionType)) {
					error("The left and right hand sides are not compatible: " + leftHandSideExpressionType + " and " +
						rightHandSideExpressionType, ExpressionModelPackage.Literals.BINARY_EXPRESSION__RIGHT_OPERAND);
				}
				// Additional checks for enums
				else if (leftHandSideExpressionType == ExpressionType.ENUMERATION) {
					checkEnumerationConformance(lhs, rhs, ExpressionModelPackage.Literals.BINARY_EXPRESSION__RIGHT_OPERAND);
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
	
	protected void checkTypeAndTypeConformance(Type lhs, Type rhs, EStructuralFeature feature) {
		ExpressionType leftHandSideExpressionType = typeDeterminator.transform(lhs);
		ExpressionType rightHandSideExpressionType = typeDeterminator.transform(rhs);
		if (!leftHandSideExpressionType.equals(rightHandSideExpressionType)) {
			error("The types of the left hand side and the right hand side are not the same: " +
					leftHandSideExpressionType.toString().toLowerCase() + " and " +
					rightHandSideExpressionType.toString().toLowerCase() + ".", feature);
			return;
		}
		checkEnumerationConformance(lhs, rhs, feature);
	}
	
	protected void checkTypeAndExpressionConformance(Type type, Expression rhs, EStructuralFeature feature) {
		ExpressionType lhsExpressionType = typeDeterminator.transform(type);
		ExpressionType rhsExpressionType = typeDeterminator.getType(rhs);
		if (!lhsExpressionType.equals(rhsExpressionType)) {
			error("The types of the variable declaration and the right hand side expression are not the same: " +
					lhsExpressionType.toString().toLowerCase() + " and " +
					rhsExpressionType.toString().toLowerCase() + ".", feature);
			return;
		}
		checkEnumerationConformance(type, rhs, feature);
	}
	
	protected void checkEnumerationConformance(Type lhs, Type rhs, EStructuralFeature feature) {
		EnumerationTypeDefinition enumType = typeDeterminator.getEnumerationType(lhs);
		if (enumType != null) {
			final EnumerationTypeDefinition rhsType = typeDeterminator.getEnumerationType(rhs);
			checkEnumerationConformance(enumType, rhsType, feature);
		}
	}

	protected void checkEnumerationConformance(Type type, Expression rhs, EStructuralFeature feature) {
		EnumerationTypeDefinition enumType = typeDeterminator.getEnumerationType(type);
		if (enumType != null) {
			final EnumerationTypeDefinition rhsType = typeDeterminator.getEnumerationType(rhs);
			checkEnumerationConformance(enumType, rhsType, feature);
		}
	}
	
	protected void checkEnumerationConformance(Expression lhs, Expression rhs, EStructuralFeature feature) {
		EnumerationTypeDefinition lhsType = typeDeterminator.getEnumerationType(lhs);
		EnumerationTypeDefinition rhsType = typeDeterminator.getEnumerationType(rhs);
		checkEnumerationConformance(lhsType, rhsType, feature);
	}
	
	protected void checkEnumerationConformance(EnumerationTypeDefinition lhs, EnumerationTypeDefinition rhs,
			EStructuralFeature feature) {
		if (lhs != rhs) {
			error("The right hand side is not the same type of enumeration as the left hand side.", feature);
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
			EObject container = elem.eContainer();
			if (elem instanceof Declaration) {
				Declaration declaration = (Declaration) elem;
				for (VariableDeclaration variableDeclaration : expressionUtil.getReferredVariables(initialExpression)) {
					if (container == variableDeclaration.eContainer()) {
						final EList<EObject> eContents = container.eContents();
						int elemIndex = eContents.indexOf(elem);
						int variableIndex = eContents.indexOf(variableDeclaration);
						if (variableIndex >= elemIndex) {
							error("The declarations referenced in the initial value must be declared before the variable declaration.",
									ExpressionModelPackage.Literals.INITIALIZABLE_ELEMENT__EXPRESSION);
							return;
						}
					}
				}
				// Initial value is correct
				Type variableDeclarationType = declaration.getType();
				ExpressionType initialExpressionType = typeDeterminator.getType(elem.getExpression());
				if (!typeDeterminator.equals(variableDeclarationType, initialExpressionType)) {
					error("The types of the declaration and the right hand side expression are not the same: " +
							typeDeterminator.transform(variableDeclarationType).toString().toLowerCase() + " and " +
							initialExpressionType.toString().toLowerCase() + ".",
							ExpressionModelPackage.Literals.INITIALIZABLE_ELEMENT__EXPRESSION);
				} 
				// Additional checks for enumerations
				checkEnumerationConformance(variableDeclarationType, initialExpression, ExpressionModelPackage.Literals.INITIALIZABLE_ELEMENT__EXPRESSION);
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
	
}