/********************************************************************************
 * Copyright (c) 2018-2026 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.expression.util;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Queue;
import java.util.Set;
import java.util.stream.Collectors;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.AbstractDirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.AccessExpression;
import hu.bme.mit.gamma.expression.model.AddExpression;
import hu.bme.mit.gamma.expression.model.AndExpression;
import hu.bme.mit.gamma.expression.model.ArrayAccessExpression;
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression;
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition;
import hu.bme.mit.gamma.expression.model.BinaryExpression;
import hu.bme.mit.gamma.expression.model.BooleanLiteralExpression;
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition;
import hu.bme.mit.gamma.expression.model.ConstantDeclaration;
import hu.bme.mit.gamma.expression.model.DecimalLiteralExpression;
import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DeclarationReferenceAnnotation;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression;
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition;
import hu.bme.mit.gamma.expression.model.EqualityExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.expression.model.ExpressionPackage;
import hu.bme.mit.gamma.expression.model.FalseExpression;
import hu.bme.mit.gamma.expression.model.FieldAssignment;
import hu.bme.mit.gamma.expression.model.FieldDeclaration;
import hu.bme.mit.gamma.expression.model.FieldReferenceExpression;
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression;
import hu.bme.mit.gamma.expression.model.FunctionDeclaration;
import hu.bme.mit.gamma.expression.model.GreaterEqualExpression;
import hu.bme.mit.gamma.expression.model.GreaterExpression;
import hu.bme.mit.gamma.expression.model.IfThenElseExpression;
import hu.bme.mit.gamma.expression.model.ImplyExpression;
import hu.bme.mit.gamma.expression.model.InequalityExpression;
import hu.bme.mit.gamma.expression.model.InitializableElement;
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression;
import hu.bme.mit.gamma.expression.model.IntegerRangeLiteralExpression;
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition;
import hu.bme.mit.gamma.expression.model.LessEqualExpression;
import hu.bme.mit.gamma.expression.model.LessExpression;
import hu.bme.mit.gamma.expression.model.LiteralExpression;
import hu.bme.mit.gamma.expression.model.MultiaryExpression;
import hu.bme.mit.gamma.expression.model.MultiplyExpression;
import hu.bme.mit.gamma.expression.model.NotExpression;
import hu.bme.mit.gamma.expression.model.NullaryExpression;
import hu.bme.mit.gamma.expression.model.OpaqueExpression;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.ParameterDeclarationAnnotation;
import hu.bme.mit.gamma.expression.model.ParametricElement;
import hu.bme.mit.gamma.expression.model.RationalLiteralExpression;
import hu.bme.mit.gamma.expression.model.RationalTypeDefinition;
import hu.bme.mit.gamma.expression.model.RecordAccessExpression;
import hu.bme.mit.gamma.expression.model.RecordLiteralExpression;
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.SubtractExpression;
import hu.bme.mit.gamma.expression.model.TrueExpression;
import hu.bme.mit.gamma.expression.model.TupleLiteralExpression;
import hu.bme.mit.gamma.expression.model.TupleReferenceExpression;
import hu.bme.mit.gamma.expression.model.TupleTypeDefinition;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeDeclaration;
import hu.bme.mit.gamma.expression.model.TypeDefinition;
import hu.bme.mit.gamma.expression.model.TypeReference;
import hu.bme.mit.gamma.expression.model.UnaryExpression;
import hu.bme.mit.gamma.expression.model.UnaryMinusExpression;
import hu.bme.mit.gamma.expression.model.ValueDeclaration;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.expression.model.VariableDeclarationAnnotation;
import hu.bme.mit.gamma.expression.model.XorExpression;
import hu.bme.mit.gamma.util.GammaEcoreUtil;
import hu.bme.mit.gamma.util.JavaUtil;

public class ExpressionUtil {
	// Singleton
	public static final ExpressionUtil INSTANCE = new ExpressionUtil();
	protected ExpressionUtil() {}
	//
	
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected final JavaUtil javaUtil = JavaUtil.INSTANCE;
	protected final ExpressionEvaluator evaluator = ExpressionEvaluator.INSTANCE;
	protected final ExpressionNegator negator = ExpressionNegator.INSTANCE;
	protected final ExpressionTypeDeterminator2 typeDeterminator = ExpressionTypeDeterminator2.INSTANCE;
	
	protected final ExpressionModelFactory factory = ExpressionModelFactory.eINSTANCE;
	
	// The following methods are worth extending in subclasses
	
	public Declaration getDeclaration(Expression expression) {
		if (expression instanceof AbstractDirectReferenceExpression reference) {
			return reference.getDeclaration();
		}
		if (expression instanceof DirectReferenceExpression reference) {
			return reference.getDeclaration();
		}
		if (expression instanceof RecordAccessExpression access) {
			if (ExpressionModelDerivedFeatures.isRecordAccessEvaluable(access)) { // RecordLiteral
				Expression evaluatedRecordAccess = evaluator.evaluateRecordAccess(access);
				return getDeclaration(evaluatedRecordAccess);
			}
			// Or this branch...
			FieldReferenceExpression reference = access.getFieldReference();
			return getDeclaration(reference);
		}
		if (expression instanceof FieldReferenceExpression reference) {
			return reference.getFieldDeclaration();
		}
		if (expression instanceof ArrayAccessExpression access) {
			if (ExpressionModelDerivedFeatures.isArrayAccessEvaluable(access)) { // ArrayLiteral
				Expression evaluatedArrayAccess = evaluator.evaluateArrayAccess(access);
				return getDeclaration(evaluatedArrayAccess);
			}
			// Also below branch...
		}
		if (expression instanceof AccessExpression access) {
			// Default access
			Expression operand = access.getOperand();
			return getDeclaration(operand);
		}
		throw new IllegalArgumentException("Not known declaration: " + expression);
	}
	
	public ReferenceExpression getAccessReference(Expression expression) {
		if (expression instanceof AbstractDirectReferenceExpression reference) {
			return reference;
		}
		if (expression instanceof DirectReferenceExpression reference) {
			return reference;
		}
		if (expression instanceof ArrayAccessExpression access) {
			if (ExpressionModelDerivedFeatures.isArrayAccessEvaluable(access)) { // ArrayLiteral
				Expression evaluatedArrayAccess = evaluator.evaluateArrayAccess(access);
				return getAccessReference(evaluatedArrayAccess);
			}
			// Also below branch...
		}
		if (expression instanceof RecordAccessExpression access) {
			if (ExpressionModelDerivedFeatures.isRecordAccessEvaluable(access)) { // RecordLiteral
				Expression evaluatedRecordAccess = evaluator.evaluateRecordAccess(access);
				return getAccessReference(evaluatedRecordAccess);
			}
			// Also below branch...
		}
		if (expression instanceof AccessExpression access) {
			Expression operand = access.getOperand();
			return getAccessReference(operand);
		}
		if (expression instanceof TupleReferenceExpression tuple) {
			return tuple;
		}
		// Could be extended to literals too
		throw new IllegalArgumentException("Not supported reference: " + expression);
	}
	
	public Declaration getAccessedDeclaration(Expression expression) {
		ReferenceExpression reference = getAccessReference(expression);
		if (reference instanceof AbstractDirectReferenceExpression directReference) {
			return directReference.getDeclaration();
		}
		if (reference instanceof DirectReferenceExpression directReference) {
			return directReference.getDeclaration();
		}
		throw new IllegalArgumentException("Not supported element: " + expression);
	}
	
	public List<Declaration> getAccessedDeclarations(Expression expression) {
		ReferenceExpression reference = getAccessReference(expression);
		if (reference instanceof TupleReferenceExpression tupleReferenceExpression) {
			List<Declaration> declarations = new ArrayList<Declaration>();
			List<ReferenceExpression> references = tupleReferenceExpression.getReferences();
			for (ReferenceExpression subreference : references) {
				declarations.addAll(
						getAccessedDeclarations(subreference));
			}
			return declarations;
		}
		
		return List.of(
				getAccessedDeclaration(expression));
	}
	
	public FunctionDeclaration getFunctionDeclaration(Expression expression) {
		Declaration declaration = getDeclaration(expression);
		return (FunctionDeclaration) declaration;
	}
	
	public Collection<TypeDeclaration> getTypeDeclarations(EObject context) {
		ExpressionPackage _package = ecoreUtil.getSelfOrContainerOfType(context, ExpressionPackage.class);
		if (_package == null) {
			return Collections.emptyList();
		}
		return _package.getTypeDeclarations();
	}
	
	//
	
	public IntegerRangeLiteralExpression getIntegerRangeLiteralExpression(Expression expression) {
		if (expression instanceof IntegerRangeLiteralExpression literal) {
			return literal;
		}
		if (expression instanceof DirectReferenceExpression reference) {
			Declaration declaration = reference.getDeclaration();
			if (declaration instanceof ConstantDeclaration constant) {
				Expression value = constant.getExpression();
				if (value instanceof IntegerRangeLiteralExpression literal) {
					return literal;
				}
			}
		}
		throw new IllegalArgumentException("Not known expression: " + expression);
	}
	
	// Expression optimization
	
	public Set<Expression> removeDuplicatedExpressions(Collection<Expression> expressions) {
		Set<Integer> integerValues = new HashSet<Integer>();
		Set<Boolean> booleanValues = new HashSet<Boolean>();
		Set<Expression> evaluatedExpressions = new HashSet<Expression>();
		for (Expression expression : expressions) {
			try {
				// Integers and enums
				int value = evaluator.evaluateInteger(expression);
				if (!integerValues.contains(value)) {
					integerValues.add(value);
					evaluatedExpressions.add(toIntegerLiteral(value));
				}
			} catch (Exception e) {}
			// Excluding branches
			try {
				// Boolean
				boolean bool = evaluator.evaluateBoolean(expression);
				if (!booleanValues.contains(bool)) {
					booleanValues.add(bool);
					evaluatedExpressions.add(bool ? factory.createTrueExpression() : factory.createFalseExpression());
				}
			} catch (Exception e) {}
		}
		return evaluatedExpressions;
	}
	
	public Collection<EnumerationLiteralExpression> mapToEnumerationLiterals(
			EnumerationTypeDefinition type, Collection<Expression> expressions) {
		List<EnumerationLiteralExpression> literals = new ArrayList<EnumerationLiteralExpression>();
		for (Expression expression : expressions) {
			int index = evaluator.evaluate(expression);
			List<EnumerationLiteralDefinition> literals2 = type.getLiterals();
			EnumerationLiteralDefinition literal = literals2.get(index);
			EnumerationLiteralExpression literalExpression = createEnumerationLiteralExpression(literal);
			literals.add(literalExpression);
		}
		return literals;
	}

	/**
	 * Returns whether the disjunction of the given expressions is a certain event.
	 */
	public boolean isCertainEvent(Expression lhs, Expression rhs) {
		if (lhs instanceof NotExpression notExpression) {
			final Expression operand = notExpression.getOperand();
			if (ecoreUtil.helperEquals(operand, rhs)) {
				return true;
			}
		}
		if (rhs instanceof NotExpression notExpression) {
			final Expression operand = notExpression.getOperand();
			if (ecoreUtil.helperEquals(operand, lhs)) {
				return true;
			}
		}
		return false;
	}
	
	// Arithmetic: for now, integers only

	public Expression add(Expression expression, long value) {
		return toIntegerLiteral(
				evaluator.evaluate(expression) + value);
	}

	public Expression subtract(Expression expression, long value) {
		return toIntegerLiteral(
				evaluator.evaluate(expression) - value);
	}
	
	public OpaqueExpression createOpaqueExpression(CharSequence chars) {
		return createOpaqueExpression(chars.toString());
	}
	
	public OpaqueExpression createOpaqueExpression(String string) {
		OpaqueExpression opaqueExpression = factory.createOpaqueExpression();
		opaqueExpression.setExpression(string);
		return opaqueExpression;
	}
	
	public Expression createIncrementExpression(Declaration variable) {
		DirectReferenceExpression reference = createReferenceExpression(variable);
		return createIncrementExpression(reference);
	}
	
	public Expression createIncrementExpression(Expression expression) {
		Type type = typeDeterminator.getType(expression);
		Expression _1 = createLiteralOne(type);
		return wrapIntoAddExpression(expression, _1);
	}

	public Expression createDecrementExpression(Declaration variable) {
		DirectReferenceExpression reference = createReferenceExpression(variable);
		return createDecrementExpression(reference);
	}
	
	public Expression createDecrementExpression(Expression expression) {
		Type type = typeDeterminator.getType(expression);
		Expression _1 = createLiteralOne(type);
		return createSubtractExpression(expression, _1);
	}
	
	public Expression wrapIntoAdd(Expression expression, long value) {
		AddExpression addExpression = factory.createAddExpression();
		addExpression.getOperands().add(expression);
		addExpression.getOperands().add(
				toIntegerLiteral(value));
		return addExpression;
	}
	
	public Expression wrapIntoSubtract(Expression expression, long value) {
		SubtractExpression subtractExpression = factory.createSubtractExpression();
		subtractExpression.setLeftOperand(expression);
		subtractExpression.setRightOperand(
				toIntegerLiteral(value));
		return subtractExpression;
	}
	
	public Expression wrapIntoMultiply(Expression expression, long value) {
		IntegerLiteralExpression integerLiteral = toIntegerLiteral(value);
		return wrapIntoMultiply(expression, integerLiteral);
	}
	
	public Expression wrapIntoMultiply(Expression lhs, Expression rhs) {
		MultiplyExpression multiplyExpression = factory.createMultiplyExpression();
		multiplyExpression.getOperands().add(lhs);
		multiplyExpression.getOperands().add(rhs);
		return multiplyExpression;
	}

	// Declaration references
	
	// Variables
	public Set<VariableDeclaration> getReferredVariables(EObject object) {
		Set<VariableDeclaration> variables = new HashSet<VariableDeclaration>();
		for (DirectReferenceExpression referenceExpression :
				ecoreUtil.getSelfAndAllContentsOfType(object, DirectReferenceExpression.class)) {
			Declaration declaration = referenceExpression.getDeclaration();
			if (declaration instanceof VariableDeclaration variable) {
				variables.add(variable);
			}
		}
		return variables;
	}
	
	protected Set<VariableDeclaration> _getReferredVariables(NullaryExpression expression) {
		return Collections.emptySet();
	}

	protected Set<VariableDeclaration> _getReferredVariables(UnaryExpression expression) {
		return getReferredVariables(expression.getOperand());
	}

	protected Set<VariableDeclaration> _getReferredVariables(IfThenElseExpression expression) {
		Set<VariableDeclaration> variables = new HashSet<VariableDeclaration>();
		variables.addAll(
				getReferredVariables(expression.getCondition()));
		variables.addAll(
				getReferredVariables(expression.getThen()));
		variables.addAll(
				getReferredVariables(expression.getElse()));
		return variables;
	}

	protected Set<VariableDeclaration> _getReferredVariables(ReferenceExpression expression) {
		if (expression instanceof DirectReferenceExpression directReferenceExpression) {
			Declaration declaration = directReferenceExpression.getDeclaration();
			if (declaration instanceof VariableDeclaration variable) {
				return Collections.singleton(variable);
			}
		}
		else if (expression instanceof TupleReferenceExpression tupleReferenceExpression) {
			Set<VariableDeclaration> variables = new HashSet<VariableDeclaration>();
			List<ReferenceExpression> references = tupleReferenceExpression.getReferences();
			for (ReferenceExpression reference : references) {
				variables.addAll(
						getReferredVariables(reference));
			}
			return variables;
		}
		else if (expression instanceof ArrayAccessExpression arrayAccessExpression) {
			Set<VariableDeclaration> variables = new HashSet<VariableDeclaration>();
			variables.addAll(
					getReferredVariables(arrayAccessExpression.getOperand()));
			variables.addAll(
					getReferredVariables(arrayAccessExpression.getIndex()));
			return variables;
		}
		else if (expression instanceof FunctionAccessExpression functionAccessExpression) {
			Set<VariableDeclaration> variables = new HashSet<VariableDeclaration>();
			for (Expression argument : functionAccessExpression.getArguments()) {
				variables.addAll(
					getReferredVariables(argument));
			}
			return variables;
		}
		else if (expression instanceof AccessExpression accessExpression) {
			return getReferredVariables(
					accessExpression.getOperand());
		}
		return Collections.emptySet();
	}

	protected Set<VariableDeclaration> _getReferredVariables(BinaryExpression expression) {
		Set<VariableDeclaration> variables = new HashSet<VariableDeclaration>();
		variables.addAll(
				getReferredVariables(expression.getLeftOperand()));
		variables.addAll(
				getReferredVariables(expression.getRightOperand()));
		return variables;
	}

	protected Set<VariableDeclaration> _getReferredVariables(MultiaryExpression expression) {
		Set<VariableDeclaration> variables = new HashSet<VariableDeclaration>();
		List<Expression> _operands = expression.getOperands();
		for (Expression operand : _operands) {
			variables.addAll(
					getReferredVariables(operand));
		}
		return variables;
	}

	public Set<VariableDeclaration> getReferredVariables(Expression expression) {
		if (expression instanceof ReferenceExpression _expression) {
			return _getReferredVariables(_expression);
		}
		else if (expression instanceof BinaryExpression _expression) {
			return _getReferredVariables(_expression);
		}
		else if (expression instanceof IfThenElseExpression _expression) {
			return _getReferredVariables(_expression);
		}
		else if (expression instanceof MultiaryExpression _expression) {
			return _getReferredVariables(_expression);
		}
		else if (expression instanceof NullaryExpression _expression) {
			return _getReferredVariables(_expression);
		}
		else if (expression instanceof UnaryExpression _expression) {
			return _getReferredVariables(_expression);
		}
		else {
			throw new IllegalArgumentException("Unhandled parameter types: " + Arrays.<Object>asList(expression).toString());
		}
	}
	
	// Parameters
	public Set<ParameterDeclaration> getReferredParameters(EObject object) {
		Set<ParameterDeclaration> parameters = new HashSet<ParameterDeclaration>();
		for (DirectReferenceExpression referenceExpression :
				ecoreUtil.getSelfAndAllContentsOfType(object, DirectReferenceExpression.class)) {
			Declaration declaration = referenceExpression.getDeclaration();
			if (declaration instanceof ParameterDeclaration parameter) {
				parameters.add(parameter);
			}
		}
		return parameters;
	}
	
	protected Set<ParameterDeclaration> _getReferredParameters(NullaryExpression expression) {
		return Collections.emptySet();
	}

	protected Set<ParameterDeclaration> _getReferredParameters(UnaryExpression expression) {
		return getReferredParameters(expression.getOperand());
	}

	protected Set<ParameterDeclaration> _getReferredParameters(IfThenElseExpression expression) {
		Set<ParameterDeclaration> parameters = new HashSet<ParameterDeclaration>();
		parameters.addAll(
				getReferredParameters(expression.getCondition()));
		parameters.addAll(
				getReferredParameters(expression.getThen()));
		parameters.addAll(
				getReferredParameters(expression.getElse()));
		return parameters;
	}

	protected Set<ParameterDeclaration> _getReferredParameters(ReferenceExpression expression) {
		if (expression instanceof DirectReferenceExpression reference) {
			Declaration declaration = reference.getDeclaration();
			if (declaration instanceof ParameterDeclaration parameter) {
				return Collections.singleton(parameter);
			}
		}
		else if (expression instanceof AccessExpression accessExpression) {
			return getReferredParameters(
					accessExpression.getOperand());
		}
		return Collections.emptySet();
	}

	protected Set<ParameterDeclaration> _getReferredParameters(BinaryExpression expression) {
		Set<ParameterDeclaration> parameters = new HashSet<ParameterDeclaration>();
		parameters.addAll(
				getReferredParameters(expression.getLeftOperand()));
		parameters.addAll(
				getReferredParameters(expression.getRightOperand()));
		return parameters;
	}

	protected Set<ParameterDeclaration> _getReferredParameters(MultiaryExpression expression) {
		Set<ParameterDeclaration> parameters = new HashSet<ParameterDeclaration>();
		List<Expression> _operands = expression.getOperands();
		for (Expression operand : _operands) {
			parameters.addAll(
					getReferredParameters(operand));
		}
		return parameters;
	}

	public Set<ParameterDeclaration> getReferredParameters(Expression expression) {
		if (expression instanceof ReferenceExpression _expression) {
			return _getReferredParameters(_expression);
		}
		else if (expression instanceof BinaryExpression _expression) {
			return _getReferredParameters(_expression);
		}
		else if (expression instanceof IfThenElseExpression _expression) {
			return _getReferredParameters(_expression);
		}
		else if (expression instanceof MultiaryExpression _expression) {
			return _getReferredParameters(_expression);
		}
		else if (expression instanceof NullaryExpression _expression) {
			return _getReferredParameters(_expression);
		}
		else if (expression instanceof UnaryExpression _expression) {
			return _getReferredParameters(_expression);
		}
		else {
			throw new IllegalArgumentException("Unhandled parameter types: " + Arrays.<Object>asList(expression).toString());
		}
	}
	
	// Constants
	public Set<ConstantDeclaration> getReferredConstants(EObject object) {
		Set<ConstantDeclaration> constants = new HashSet<ConstantDeclaration>();
		for (DirectReferenceExpression referenceExpression :
				ecoreUtil.getSelfAndAllContentsOfType(object, DirectReferenceExpression.class)) {
			Declaration declaration = referenceExpression.getDeclaration();
			if (declaration instanceof ConstantDeclaration constant) {
				constants.add(constant);
			}
		}
		return constants;
	}
	
	protected Set<ConstantDeclaration> _getReferredConstants(NullaryExpression expression) {
		return Collections.emptySet();
	}

	protected Set<ConstantDeclaration> _getReferredConstants(UnaryExpression expression) {
		return getReferredConstants(expression.getOperand());
	}

	protected Set<ConstantDeclaration> _getReferredConstants(IfThenElseExpression expression) {
		Set<ConstantDeclaration> constants = new HashSet<ConstantDeclaration>();
		constants.addAll(
				getReferredConstants(expression.getCondition()));
		constants.addAll(
				getReferredConstants(expression.getThen()));
		constants.addAll(
				getReferredConstants(expression.getElse()));
		return constants;
	}

	protected Set<ConstantDeclaration> _getReferredConstants(ReferenceExpression expression) {
		if (expression instanceof DirectReferenceExpression reference) {
			Declaration declaration = reference.getDeclaration();
			if (declaration instanceof ConstantDeclaration constant) {
				return Collections.singleton(constant);
			}
		}
		else if (expression instanceof AccessExpression accessExpression) {
			return getReferredConstants(
					accessExpression.getOperand());
		}
		return Collections.emptySet();
	}

	protected Set<ConstantDeclaration> _getReferredConstants(BinaryExpression expression) {
		Set<ConstantDeclaration> constants = new HashSet<ConstantDeclaration>();
		constants.addAll(
				getReferredConstants(expression.getLeftOperand()));
		constants.addAll(
				getReferredConstants(expression.getRightOperand()));
		return constants;
	}

	protected Set<ConstantDeclaration> _getReferredConstants(MultiaryExpression expression) {
		Set<ConstantDeclaration> constants = new HashSet<ConstantDeclaration>();
		List<Expression> _operands = expression.getOperands();
		for (Expression operand : _operands) {
			constants.addAll(
					getReferredConstants(operand));
		}
		return constants;
	}

	public Set<ConstantDeclaration> _getReferredConstants(Expression expression) {
		if (expression instanceof ReferenceExpression _expression) {
			return _getReferredConstants(_expression);
		}
		else if (expression instanceof BinaryExpression _expression) {
			return _getReferredConstants(_expression);
		}
		else if (expression instanceof IfThenElseExpression _expression) {
			return _getReferredConstants(_expression);
		}
		else if (expression instanceof MultiaryExpression _expression) {
			return _getReferredConstants(_expression);
		}
		else if (expression instanceof NullaryExpression _expression) {
			return _getReferredConstants(_expression);
		}
		else if (expression instanceof UnaryExpression _expression) {
			return _getReferredConstants(_expression);
		}
		else {
			throw new IllegalArgumentException("Unhandled parameter types: " + Arrays.<Object>asList(expression).toString());
		}
	}
	
	public Set<ConstantDeclaration> getReferredConstants(Expression expression) {
		if (expression instanceof ReferenceExpression _expression) {
			return _getReferredConstants(_expression);
		}
		else if (expression instanceof BinaryExpression _expression) {
			return _getReferredConstants(_expression);
		}
		else if (expression instanceof IfThenElseExpression _expression) {
			return _getReferredConstants(_expression);
		}
		else if (expression instanceof MultiaryExpression _expression) {
			return _getReferredConstants(_expression);
		}
		else if (expression instanceof NullaryExpression _expression) {
			return _getReferredConstants(_expression);
		}
		else if (expression instanceof UnaryExpression _expression) {
			return _getReferredConstants(_expression);
		}
		else {
			throw new IllegalArgumentException("Unhandled parameter types: " + Arrays.<Object>asList(expression).toString());
		}
	}
	
	// Values (variables, parameters and constants)
	
	public Set<ValueDeclaration> getReferredValues(Expression expression) {
		Set<ValueDeclaration> referred = new HashSet<ValueDeclaration>();
		referred.addAll(
				getReferredVariables(expression));
		referred.addAll(
				getReferredParameters(expression));
		referred.addAll(
				getReferredConstants(expression));
		return referred;
	}
	
	// Extract parameters
	
	public List<ConstantDeclaration> extractParameters(ParametricElement parametricElement,
			List<String> names, List<? extends Expression> arguments) {
		List<ParameterDeclaration> parameterDeclarations = parametricElement.getParameterDeclarations();
		return extractParameters(parameterDeclarations, names, arguments);
	}
	
	public List<ConstantDeclaration> extractParameters(
			List<? extends ParameterDeclaration> parameters, List<String> names,
			List<? extends Expression> arguments) {
		List<ConstantDeclaration> constants = new ArrayList<ConstantDeclaration>();
		int size = parameters.size();
		for (int i = 0; i < size; i++) {
			ParameterDeclaration parameter = parameters.get(i);
			Expression argument = arguments.get(i);
			
			Type type = ecoreUtil.clone(parameter.getType());
			String name = names.get(i);
			Expression value = ecoreUtil.clone(argument);
			
			ConstantDeclaration constant = factory.createConstantDeclaration();
			constant.setName(name);
			constant.setType(type);
			constant.setExpression(value);
			constants.add(constant);
			// Changing the references to the constant
			ecoreUtil.change(constant, parameter, parameter.eContainer());
		}
		return constants;
	}
	
	public void inlineParameters(ParametricElement parametricElement,
			List<? extends Expression> arguments) {
		inlineParameters(parametricElement.getParameterDeclarations(), arguments);
	}
	
	public void inlineParameters(List<? extends ParameterDeclaration> parameters,
				List<? extends Expression> arguments) {
		int size = parameters.size();
		for (int i = 0; i < size; i++) {
			ParameterDeclaration parameter = parameters.get(i);
			Expression argument = arguments.get(i);
			
			ParametricElement parametricElement = ecoreUtil.getContainerOfType(parameter, ParametricElement.class);
			List<DirectReferenceExpression> references = ecoreUtil
					.getAllContentsOfType(parametricElement, DirectReferenceExpression.class).stream()
					.filter(it -> it.getDeclaration() == parameter).collect(Collectors.toList());
			for (DirectReferenceExpression reference : references) {
				Expression value = ecoreUtil.clone(argument);
				ecoreUtil.replace(value, reference);
			}
		}
		// Removing later to avoid messing up the indexes
		for (ParameterDeclaration parameter :
					new ArrayList<ParameterDeclaration>(parameters)) {
			ecoreUtil.remove(parameter);
		}
	}
	
	// Initial values of types

	public Expression getInitialValue(VariableDeclaration variableDeclaration) {
		final Expression initialValue = variableDeclaration.getExpression();
		if (initialValue != null) {
			return ecoreUtil.clone(initialValue);
		}
		final Type type = variableDeclaration.getType();
		return getInitialValueOfType(type);
	}
	
	protected Expression _getInitialValueOfType(TypeReference type) {
		TypeDeclaration reference = type.getReference();
		return getInitialValueOfType(
				reference.getType());
	}

	protected Expression _getInitialValueOfType(BooleanTypeDefinition type) {
		return factory.createFalseExpression();
	}

	protected Expression _getInitialValueOfType(IntegerTypeDefinition type) {
		return toIntegerLiteral(0);
	}

	protected Expression _getInitialValueOfType(DecimalTypeDefinition type) {
		DecimalLiteralExpression decimalLiteralExpression = factory.createDecimalLiteralExpression();
		decimalLiteralExpression.setValue(BigDecimal.valueOf(0.0)); // .ZERO cannot be parsed by Xtext
		return decimalLiteralExpression;
	}

	protected Expression _getInitialValueOfType(RationalTypeDefinition type) {
		RationalLiteralExpression rationalLiteralExpression = factory.createRationalLiteralExpression();
		rationalLiteralExpression.setNumerator(BigInteger.ZERO);
		rationalLiteralExpression.setDenominator(BigInteger.ONE);
		return rationalLiteralExpression;
	}

	protected Expression _getInitialValueOfType(EnumerationTypeDefinition type) {
		List<EnumerationLiteralDefinition> literals = type.getLiterals();
		EnumerationLiteralDefinition literal = literals.get(0);
		return createEnumerationLiteralExpression(literal);
	}
	
	protected Expression _getInitialValueOfType(ArrayTypeDefinition type) {
		ArrayLiteralExpression arrayLiteralExpression = factory.createArrayLiteralExpression();
		Expression size = type.getSize();
		int arraySize = evaluator.evaluateInteger(size);
		for (int i = 0; i < arraySize; ++i) {
			Expression elementDefaultValue = getInitialValueOfType(type.getElementType());
			arrayLiteralExpression.getOperands().add(elementDefaultValue);
		}
		return arrayLiteralExpression;
	}
	
	protected Expression _getInitialValueOfType(RecordTypeDefinition type) {
		TypeDeclaration typeDeclaration = ecoreUtil.getContainerOfType(type, TypeDeclaration.class);
		if (typeDeclaration == null) {
			throw new IllegalArgumentException("Record type is not contained by declaration: " + type);
		}
		RecordLiteralExpression recordLiteralExpression = factory.createRecordLiteralExpression();
		recordLiteralExpression.setTypeDeclaration(typeDeclaration);
		for (FieldDeclaration field : type.getFieldDeclarations()) {
			FieldAssignment assignment = factory.createFieldAssignment();
			FieldReferenceExpression fieldReference = factory.createFieldReferenceExpression();
			fieldReference.setFieldDeclaration(field);
			assignment.setReference(fieldReference);
			assignment.setValue(
					getInitialValueOfType(field.getType()));
			recordLiteralExpression.getFieldAssignments().add(assignment);
		}
		return recordLiteralExpression;
	}
	
	protected Expression _getInitialValueOfType(TupleTypeDefinition type) {
		TupleLiteralExpression tupleLiteralExpression = factory.createTupleLiteralExpression();
		
		for (Type subtype : type.getTypes()) {
			Expression initialValue = getInitialValueOfType(subtype);
			tupleLiteralExpression.getOperands().add(initialValue);
		}
		
		return tupleLiteralExpression;
	}

	public Expression getInitialValueOfType(Type type) {
		if (type instanceof EnumerationTypeDefinition _type) {
			return _getInitialValueOfType(_type);
		}
		else if (type instanceof DecimalTypeDefinition _type) {
			return _getInitialValueOfType(_type);
		}
		else if (type instanceof IntegerTypeDefinition _type) {
			return _getInitialValueOfType(_type);
		}
		else if (type instanceof RationalTypeDefinition _type) {
			return _getInitialValueOfType(_type);
		}
		else if (type instanceof BooleanTypeDefinition _type) {
			return _getInitialValueOfType(_type);
		}
		else if (type instanceof TypeReference _type) {
			return _getInitialValueOfType(_type);
		}
		else if (type instanceof ArrayTypeDefinition _type) {
			return _getInitialValueOfType(_type);
		}
		else if (type instanceof RecordTypeDefinition _type) {
			return _getInitialValueOfType(_type);
		}
		else if (type instanceof TupleTypeDefinition _type) {
			return _getInitialValueOfType(_type);
		}
		else {
			throw new IllegalArgumentException("Unhandled parameter types: " + type);
		}
	}
	
	//
	
	public TypeReference createTypeReference(TypeDeclaration type) {
		TypeReference typeReference = factory.createTypeReference();
		typeReference.setReference(type);
		return typeReference;
	}
	
	// Variable handling
	
	public TypeDeclaration wrapIntoDeclaration(Type type, String name) {
		TypeDeclaration declaration = factory.createTypeDeclaration();
		declaration.setName(name);
		declaration.setType(type);
		return declaration;
	}
	
	public AndExpression connectThroughNegations(VariableDeclaration ponate,
			Iterable<? extends ValueDeclaration> toBeNegated) {
		AndExpression and = connectThroughNegations(toBeNegated);
		DirectReferenceExpression ponateReference = createReferenceExpression(ponate);
		and.getOperands().add(ponateReference);
		return and;
	}
	
	public AndExpression connectThroughNegations(Iterable<? extends ValueDeclaration> toBeNegated) {
		Collection<DirectReferenceExpression> toBeNegatedReferences = new ArrayList<DirectReferenceExpression>();
		for (ValueDeclaration toBeNegatedVariable : toBeNegated) {
			toBeNegatedReferences.add(
					createReferenceExpression(toBeNegatedVariable));
		}
		return connectViaNegations(toBeNegatedReferences);
	}
	
	public AndExpression connectViaNegations(Iterable<? extends Expression> toBeNegated) {
		AndExpression and = factory.createAndExpression();
		List<Expression> operands = and.getOperands();
		for (Expression expression : toBeNegated) {
			NotExpression not = factory.createNotExpression();
			not.setOperand(expression);
			operands.add(not);
		}
		if (operands.isEmpty()) {
			// If collection is empty, the expression is always true
			TrueExpression _true = factory.createTrueExpression();
			operands.add(_true);
		}
		return and;
	}
	
	public void reduceCrossReferenceChain(
			Iterable<? extends InitializableElement> initializableElements, EObject context) {
		for (InitializableElement element : initializableElements) {
			Expression initialExpression = element.getExpression();
			if (initialExpression instanceof DirectReferenceExpression reference) {
				Declaration referencedDeclaration = reference.getDeclaration();
				ecoreUtil.change(referencedDeclaration, element, context);
			}
		}
	}
	
	// Parameter annotation handling
	
	public void addInternalAnnotation(ParameterDeclaration parameter) {
		addAnnotation(parameter, factory.createInternalParameterDeclarationAnnotation());
	}
	
	public void addAnnotation(ParameterDeclaration parameter, ParameterDeclarationAnnotation annotation) {
		if (parameter != null) {
			List<ParameterDeclarationAnnotation> annotations = parameter.getAnnotations();
			annotations.add(annotation);
		}
	}
	
	// Variable annotation handling
	
	public void addTransientAnnotation(VariableDeclaration variable) {
		addAnnotationIfNotPresent(variable, factory.createTransientVariableDeclarationAnnotation());
	}
	
	public void addResettableAnnotation(VariableDeclaration variable) {
		addAnnotationIfNotPresent(variable, factory.createResettableVariableDeclarationAnnotation());
	}
	
	public void addEnvironmentResettableAnnotation(VariableDeclaration variable) {
		addAnnotationIfNotPresent(variable, factory.createEnvironmentResettableVariableDeclarationAnnotation());
	}
	
	public void addClockAnnotation(VariableDeclaration variable) {
		addAnnotationIfNotPresent(variable, factory.createClockVariableDeclarationAnnotation());
	}
	
	public void addScheduledClockAnnotation(VariableDeclaration variable) {
		addAnnotationIfNotPresent(variable, factory.createScheduledClockVariableDeclarationAnnotation());
	}
	
	public void addInternalAnnotation(VariableDeclaration variable) {
		addAnnotationIfNotPresent(variable, factory.createInternalVariableDeclarationAnnotation());
	}
	
	public void addDeclarationReferenceAnnotation(VariableDeclaration variable, Declaration declaration) {
		addDeclarationReferenceAnnotations(variable, List.of(declaration));
	}
	
	public void addDeclarationReferenceAnnotations(VariableDeclaration variable,
			Collection<? extends Declaration> declarations) {
		if (declarations.isEmpty()) {
			return; // No use in adding an empty annotation
		}
		
		DeclarationReferenceAnnotation declarationReferenceAnnotation = factory.createDeclarationReferenceAnnotation();
		
		List<Declaration> referencedDeclarations = declarationReferenceAnnotation.getDeclarations();
		referencedDeclarations.addAll(declarations);
		
		addAnnotation(variable, declarationReferenceAnnotation);
	}
	
	public void addUnremovableAnnotation(VariableDeclaration variable) {
		addAnnotationIfNotPresent(variable, factory.createUnremovableVariableDeclarationAnnotation());
	}
	
	public void addInjectedAnnotation(VariableDeclaration variable) {
		addAnnotationIfNotPresent(variable, factory.createInjectedVariableDeclarationAnnotation());
	}
	
	public void addAnnotation(VariableDeclaration variable, VariableDeclarationAnnotation annotation) {
		if (variable != null) {
			List<VariableDeclarationAnnotation> annotations = variable.getAnnotations();
			annotations.add(annotation);
		}
	}
	
	public void addAnnotationIfNotPresent(VariableDeclaration variable, VariableDeclarationAnnotation annotation) {
		if (variable != null && !hasAnnotation(variable, annotation.getClass())) {
			addAnnotation(variable, annotation);
		}
	}
	
	public boolean hasAnnotation(VariableDeclaration variable,
			Class<? extends VariableDeclarationAnnotation> annotationClass) {
		List<VariableDeclarationAnnotation> annotations = variable.getAnnotations();
		return annotations.stream()
				.anyMatch(it -> annotationClass.isInstance(it));
	}
	
	public void removeVariableDeclarationAnnotations(
			Collection<? extends VariableDeclaration> variables,
			Class<? extends VariableDeclarationAnnotation> annotationClass) {
		for (VariableDeclaration variable : variables) {
			List<VariableDeclarationAnnotation> annotations =
					new ArrayList<VariableDeclarationAnnotation>(variable.getAnnotations());
			for (VariableDeclarationAnnotation annotation : annotations) {
				if (annotationClass.isInstance(annotation)) {
					ecoreUtil.remove(annotation);
				}
			}
		}
	}
	
	// Creators
	
	public BooleanLiteralExpression toBooleanLiteral(boolean bool) {
		if (bool) {
			return factory.createTrueExpression();
		}
		return factory.createFalseExpression();
	}
	
	public BigInteger toBigInt(long value) {
		return BigInteger.valueOf(value);
	}
	
	public IntegerLiteralExpression toIntegerLiteral(long value) {
		BigInteger bigInteger = toBigInt(value);
		return toIntegerLiteral(bigInteger);
	}
	
	public IntegerLiteralExpression toIntegerLiteral(BigInteger value) {
		IntegerLiteralExpression integerLiteral = factory.createIntegerLiteralExpression();
		integerLiteral.setValue(value);
		return integerLiteral;
	}
	
	public IntegerLiteralExpression createLiteralZero() {
		return toIntegerLiteral(0);
	}
	
	public IntegerLiteralExpression createLiteralOne() {
		return toIntegerLiteral(1);
	}
	
	public LiteralExpression createLiteralZero(Type type) {
		TypeDefinition typeDefinition = ExpressionModelDerivedFeatures.getTypeDefinition(type);
		if (typeDefinition instanceof IntegerTypeDefinition) {
			return createLiteralZero();
		}
		if (typeDefinition instanceof RationalTypeDefinition ||
				typeDefinition instanceof DecimalTypeDefinition) {
			return toDecimalLiteral(0);
		}
		if (typeDefinition instanceof ArrayTypeDefinition arrayTypeDefinition) {
			Type elementType = arrayTypeDefinition.getElementType();
			return createLiteralZero(elementType);
		}
		throw new IllegalArgumentException("Unkown type: " + type);
	}
	
	public LiteralExpression createLiteralOne(Type type) {
		TypeDefinition typeDefinition = ExpressionModelDerivedFeatures.getTypeDefinition(type);
		if (typeDefinition instanceof IntegerTypeDefinition) {
			return createLiteralOne();
		}
		if (typeDefinition instanceof RationalTypeDefinition ||
				typeDefinition instanceof DecimalTypeDefinition) {
			return toDecimalLiteral(1);
		}
		if (typeDefinition instanceof ArrayTypeDefinition arrayTypeDefinition) {
			Type elementType = arrayTypeDefinition.getElementType();
			return createLiteralOne(elementType);
		}
		throw new IllegalArgumentException("Unkown type: " + type);
	}
	
	public EnumerationLiteralDefinition createEnumerationLiteralDefinition(String name) {
		EnumerationLiteralDefinition literal = factory.createEnumerationLiteralDefinition();
		literal.setName(name);
		return literal;
	}
	
	public BigDecimal toBigDec(double value) {
		BigDecimal decimal = BigDecimal.valueOf(value);
		if (decimal.toString().contains("E")) { // Xtext serializer cannot handle this form
			String plainString = decimal.toPlainString();
			decimal = new BigDecimal(plainString);
		}
		if (!decimal.toString().contains(".")) { // Needed by grammar
			String plainString = decimal.toPlainString() + ".0";
			decimal = new BigDecimal(plainString);
		}
		return decimal;
	}
	
	public DecimalLiteralExpression toDecimalLiteral(double value) {
		BigDecimal bigDecimal = toBigDec(value);
		return toDecimalLiteral(bigDecimal);
	}
	
	public DecimalLiteralExpression toDecimalLiteral(BigDecimal value) {
		DecimalLiteralExpression decimalLiteral = factory.createDecimalLiteralExpression();
		decimalLiteral.setValue(value);
		return decimalLiteral;
	}
	
	public Integer toInteger(LiteralExpression literalExpression) {
		if (literalExpression instanceof IntegerLiteralExpression integer) {
			return integer.getValue().intValue();
		}
		else if (literalExpression instanceof TrueExpression) {
			return 1;
		}
		else if (literalExpression instanceof FalseExpression) {
			return 0;
		}
		else if (literalExpression instanceof EnumerationLiteralExpression enumeration) {
			EnumerationLiteralDefinition enumLiteral = enumeration.getReference();
			return ecoreUtil.getIndex(enumLiteral);
		}
		else {
			throw new IllegalArgumentException("Not known literal: " + literalExpression);
		}
	}
	
	public Double toDouble(LiteralExpression literalExpression) {
		if (literalExpression instanceof IntegerLiteralExpression integer) {
			return integer.getValue().doubleValue();
		}
		else if (literalExpression instanceof DecimalLiteralExpression double_) {
			return double_.getValue().doubleValue();
		}
		else if (literalExpression instanceof RationalLiteralExpression rational) {
			return rational.getNumerator().doubleValue() / rational.getDenominator().doubleValue();
		}
		else if (literalExpression instanceof TrueExpression) {
			return 1.0;
		}
		else if (literalExpression instanceof FalseExpression) {
			return 0.0;
		}
		else if (literalExpression instanceof EnumerationLiteralExpression enumeration) {
			EnumerationLiteralDefinition enumLiteral = enumeration.getReference();
			return (double) ecoreUtil.getIndex(enumLiteral);
		}
		else {
			throw new IllegalArgumentException("Not known literal: " + literalExpression);
		}
	}
	
	public LiteralExpression toNegated(LiteralExpression literalExpression) {
		if (literalExpression instanceof IntegerLiteralExpression integer) {
			IntegerLiteralExpression negative = ecoreUtil.clone(integer);
			BigInteger negativeValue = negative.getValue().negate();
			negative.setValue(negativeValue);
			return negative;
		}
		else if (literalExpression instanceof DecimalLiteralExpression double_) {
			DecimalLiteralExpression negative = ecoreUtil.clone(double_);
			BigDecimal negativeValue = negative.getValue().negate();
			negative.setValue(negativeValue);
			return negative;
		}
		else if (literalExpression instanceof RationalLiteralExpression rational) {
			RationalLiteralExpression negative = ecoreUtil.clone(rational);
			BigInteger negativeValue = negative.getNumerator().negate();
			negative.setNumerator(negativeValue);
			return negative;
		}
		else if (literalExpression instanceof TrueExpression) {
			return factory.createFalseExpression();
		}
		else if (literalExpression instanceof FalseExpression) {
			return factory.createTrueExpression();
		}
		else {
			throw new IllegalArgumentException("Not known literal: " + literalExpression);
		}
	}
	
	public VariableDeclaration createBooleanVariableDeclaration(CharSequence name) {
		BooleanTypeDefinition type = factory.createBooleanTypeDefinition();
		return createVariableDeclarationWithDefaultInitialValue(type, name);
	}
	
	public VariableDeclaration createIntegerVariableDeclaration(CharSequence name) {
		IntegerTypeDefinition type = factory.createIntegerTypeDefinition();
		return createVariableDeclarationWithDefaultInitialValue(type, name);
	}
	
	public VariableDeclaration createVariableDeclaration(Type type, CharSequence name) {
		return createVariableDeclaration(type, name, null);
	}
	
	public VariableDeclaration createVariableDeclarationWithDefaultInitialValue(
			Type type, CharSequence name) {
		return createVariableDeclaration(type, name,
				ExpressionModelDerivedFeatures.getDefaultExpression(type));
	}
	
	public VariableDeclaration createVariableDeclaration(Type type, CharSequence name, Expression expression) {
		VariableDeclaration variableDeclaration = factory.createVariableDeclaration();
		variableDeclaration.setType(type);
		variableDeclaration.setName(name.toString());
		variableDeclaration.setExpression(expression);
		return variableDeclaration;
	}
	
	public Expression createOneInNExpression(List<? extends Declaration> declarations) {
		return create1InNExpression(
				declarations.stream().map(it -> createReferenceExpression(it))
				.toList());
	}
	
	public Expression create1InNExpression(List<? extends Expression> expressions) {
		int size = expressions.size();
		
		if (size == 0) {
			return factory.createFalseExpression();
		}
		if (size == 1) {
			return expressions.get(0);
		}
		if (size == 2) {
			XorExpression xor = factory.createXorExpression();
			for (Expression expression : expressions) {
				xor.getOperands().add(expression);
			}
			return xor;
		}
		
		// Not efficient...
		AndExpression and = factory.createAndExpression();
		XorExpression xor = factory.createXorExpression(); // Same result as Or (but more restrictive when checking values?)
		for (int i = 0; i < size - 1; i++) {
			Expression lhs = expressions.get(i);
			xor.getOperands().add(
					ecoreUtil.clone(lhs));
			for (int j = i + 1; j < size; j++) {
				Expression rhs = expressions.get(j);
				Expression notLhs = createNotExpression(
						ecoreUtil.clone(lhs));
				Expression notRhs = createNotExpression(
						ecoreUtil.clone(rhs));
				
				Expression or = wrapIntoOrExpression(notLhs, notRhs);
				
				and.getOperands().add(or);
			}
		}
		and.getOperands().add(xor);
		
		return and;
	}
	
	public TupleLiteralExpression createTupleLiteralExpression(
				Collection<? extends Expression> values, Type type) {
		TypeDefinition typeDefinition = ExpressionModelDerivedFeatures.getTypeDefinition(type);
		if (typeDefinition instanceof TupleTypeDefinition tupleTypeDefinition) {
			return createTupleLiteralExpression(values, tupleTypeDefinition);
		}
		return createTupleLiteralExpression(values);
	}
	
	public TupleLiteralExpression createTupleLiteralExpression(
				Collection<? extends Expression> values, TupleTypeDefinition tupleType) {
		Queue<Expression> expressions = new LinkedList<Expression>(values);
		return createTupleLiteralExpression(expressions, tupleType);
	}
	
	private TupleLiteralExpression createTupleLiteralExpression(
				Queue<? extends Expression> expressions, TupleTypeDefinition tupleType) {
		TupleLiteralExpression tuple = factory.createTupleLiteralExpression();
		List<Expression> operands = tuple.getOperands();
		
		for (Type subtype : tupleType.getTypes()) {
			Expression value = expressions.peek();
			TypeDefinition subtypeDefinition = ExpressionModelDerivedFeatures.getTypeDefinition(subtype);
			if (typeDeterminator.equalsType(subtype, value)) { // Primitive or tuple
				operands.add(
						expressions.remove());
			}
			else if (subtypeDefinition instanceof TupleTypeDefinition subtupleType) {
				operands.add(
						createTupleLiteralExpression(expressions, subtupleType));
			}
			else {
				throw new IllegalArgumentException("Unknown tuple literal type: " + subtype);
			}
		}
		
		return tuple;
	}
	
	public TupleLiteralExpression createTupleLiteralExpression(Collection<? extends Expression> values) {
		TupleLiteralExpression tuple = factory.createTupleLiteralExpression();
		
		for (Expression value : values) {
			tuple.getOperands().add(value);
		}
		
		return tuple;
	}
	
	public TupleReferenceExpression createTupleAccessExpression(Collection<? extends ReferenceExpression> references) {
		TupleReferenceExpression tuple = factory.createTupleReferenceExpression();
		
		for (ReferenceExpression reference : references) {
			tuple.getReferences().add(reference);
		}
		
		return tuple;
	}
	
	public TupleReferenceExpression createTupleAccessExpression(TupleTypeDefinition tupleType) {
		TupleReferenceExpression tuple = factory.createTupleReferenceExpression();
		List<ReferenceExpression> references = tuple.getReferences();
		
		for (Type subtype : tupleType.getTypes()) {
			TypeDefinition subtypeDefinition = ExpressionModelDerivedFeatures.getTypeDefinition(subtype);
			if (subtypeDefinition instanceof TupleTypeDefinition subtupleType) {
				references.add(
						createTupleAccessExpression(subtupleType));
			}
			else {
				references.add(
						factory.createDirectReferenceExpression());
			}
		}
		
		return tuple;
	}
	
	public TupleReferenceExpression createTupleAccessExpression(TupleTypeDefinition tupleType,
			List<? extends Declaration> variables) {
		TupleReferenceExpression tuple = createTupleAccessExpression(tupleType);
		int i = 0;
		for (DirectReferenceExpression reference :
				ecoreUtil.getAllContentsOfType(tuple, DirectReferenceExpression.class)) {
			Declaration variable = variables.get(i++);
			reference.setDeclaration(variable);
		}
		return tuple;
	}
	
	public IntegerRangeLiteralExpression createIntegerRangeLiteralExpression(
			Expression start, Expression end) {
		return createIntegerRangeLiteralExpression(start, true, end, false);
	}
	
	public IntegerRangeLiteralExpression createIntegerRangeLiteralExpression(
			Expression start, boolean leftInclusive, Expression end, boolean rightIclusive) {
		IntegerRangeLiteralExpression range = factory.createIntegerRangeLiteralExpression();
		range.setLeftOperand(start);
		range.setLeftInclusive(leftInclusive);
		range.setRightOperand(end);
		range.setRightInclusive(rightIclusive);
		return range;
	}

	public ParameterDeclaration createParameterDeclaration(Type type, String name) {
		ParameterDeclaration parameterDeclaration = factory.createParameterDeclaration();
		parameterDeclaration.setType(type);
		parameterDeclaration.setName(name);
		return parameterDeclaration;
	}
	
	public ConstantDeclaration createConstantDeclaration(Type type, String name) {
		return createConstantDeclaration(type, name, null);
	}
	
	public ConstantDeclaration createConstantDeclaration(Type type, String name, Expression expression) {
		ConstantDeclaration constantDeclaration = factory.createConstantDeclaration();
		constantDeclaration.setType(type);
		constantDeclaration.setName(name);
		constantDeclaration.setExpression(expression);
		return constantDeclaration;
	}
	
	public TypeDeclaration createTypeDeclaration(Type type, String name) {
		TypeDeclaration typeDeclaration = factory.createTypeDeclaration();
		typeDeclaration.setType(type);
		typeDeclaration.setName(name);
		return typeDeclaration;
	}
	
	public NotExpression createNotExpression(Expression expression) {
		NotExpression notExpression = factory.createNotExpression();
		notExpression.setOperand(expression);
		return notExpression;
	}
	
	public IfThenElseExpression createIfThenElseExpression(Expression _if,
			Expression then, Expression _else) {
		IfThenElseExpression ifThenElseExpression = factory.createIfThenElseExpression();
		ifThenElseExpression.setCondition(_if);
		ifThenElseExpression.setThen(then);
		ifThenElseExpression.setElse(_else);
		return ifThenElseExpression;
	}
	
	public IfThenElseExpression weave(Collection<? extends IfThenElseExpression> expressions) {
		// Maybe there is a single if-then-else expression
		if (expressions.size() == 1) {
			IfThenElseExpression ifThenElse = javaUtil.getOnlyElement(expressions);
			// Making sure else is not null
			if (ifThenElse.getElse() == null) {
				Expression then = ifThenElse.getThen();
				if (then == null) {
					throw new IllegalArgumentException("Then is null");
				}
				Expression clonedThen = ecoreUtil.clone(then);
				ifThenElse.setElse(clonedThen);
			}
			
			return ifThenElse;
		}
		//
		
		IfThenElseExpression first = null;
		IfThenElseExpression last = null;
		for (IfThenElseExpression expression : expressions) {
			if (first == null) {
				first = expression;
			}
			if (last != null) {
				if (last.getElse() != null) {
					throw new IllegalArgumentException("Not null else: " + expression);
				}
				last.setElse(expression);
			}
			last = expression;
		}
		// Replacing last if-then-else if else is null, otherwise there would be "null" branch
		if (last.getElse() == null) {
			Expression then = last.getThen();
			ecoreUtil.replace(then, last);
		}
		//
		
		return first;
	}
	
	public IfThenElseExpression weaveIntoIfThenElse(Collection<? extends Expression> conditions, Expression primaryReturnValue) {
		Expression finalReturnValue = negator.negate(primaryReturnValue);
		return weaveIntoIfThenElse(conditions, primaryReturnValue, finalReturnValue);
	}
	
	public IfThenElseExpression weaveIntoIfThenElse(Collection<? extends Expression> conditions,
				Expression primaryReturnValue, Expression finalReturnValue) {
		List<IfThenElseExpression> ifThenElses = conditions.stream().map(it ->
					createIfThenElseExpression(it, ecoreUtil.clone(primaryReturnValue), null))
			.collect(Collectors.toList());
		
		IfThenElseExpression lastIfThenElse = javaUtil.getLastElement(ifThenElses);
		lastIfThenElse.setElse(finalReturnValue);
		
		IfThenElseExpression weavedIfThenElse = weave(ifThenElses);
		return weavedIfThenElse;
	}
	
	public FunctionAccessExpression createFunctionAccessExpression(FunctionDeclaration function, List<? extends Expression> arguments) {
		DirectReferenceExpression reference = createReferenceExpression(function);
		FunctionAccessExpression callExpression = factory.createFunctionAccessExpression();
		callExpression.setOperand(reference);
		callExpression.getArguments().addAll(arguments);
		return callExpression;
	}
	
	public RecordAccessExpression createRecordAccessExpression(Declaration declaration, FieldDeclaration field) {
		return createRecordAccessExpression(declaration, List.of(field));
	}
	
	public RecordAccessExpression createRecordAccessExpression(Expression operand, FieldDeclaration field) {
		return createRecordAccessExpression(operand, createReferenceExpression(field));
	}
	
	public RecordAccessExpression createRecordAccessExpression(Declaration declaration, Collection<? extends FieldDeclaration> fields) {
		return createRecordAccessExpression(
				createReferenceExpression(declaration),
				fields.stream().map(it -> createReferenceExpression(it)).toList());
	}
	
	public RecordAccessExpression createRecordAccessExpression(Expression operand, FieldReferenceExpression field) {
		return createRecordAccessExpression(operand, List.of(field));
	}
	
	public RecordAccessExpression createRecordAccessExpression(Expression operand, Iterable<? extends FieldReferenceExpression> fields) {
		if (operand == null) { // operand.declaration can be null, though
			throw new IllegalArgumentException("Declaration is null");
		}
		RecordAccessExpression recordAccess = factory.createRecordAccessExpression();
		recordAccess.setOperand(operand);
		
		for (FieldReferenceExpression field : fields) {
			if (recordAccess.getFieldReference() != null) {
				RecordAccessExpression newRecordAccess = factory.createRecordAccessExpression();
				newRecordAccess.setOperand(recordAccess);
				recordAccess = newRecordAccess;
			}
			recordAccess.setFieldReference(field);
		}
		
		return recordAccess;
	}
	
	public ArrayAccessExpression createArrayAccessExpression(Expression operand, int index) {
		IntegerLiteralExpression integerLiteralExpression = toIntegerLiteral(index);
		return createArrayAccessExpression(operand, integerLiteralExpression);
	}
	
	public ArrayAccessExpression createArrayAccessExpression(Expression operand, List<Integer> indexes) {
		List<IntegerLiteralExpression> indexing = indexes.stream()
				.map(it -> toIntegerLiteral(it)).collect(Collectors.toList());
		return createArrayAccessExpression(operand, indexing);
	}
	
	public ArrayAccessExpression createArrayAccessExpression(Expression operand, Expression index) {
		ArrayAccessExpression access = factory.createArrayAccessExpression();
		access.setOperand(operand);
		access.setIndex(index);
		return access;
	}
	
	public ArrayAccessExpression createArrayAccessExpression(Expression operand,
				Collection<? extends Expression> indexes) {
		ArrayAccessExpression accessExpression = null;
		for (Expression index : indexes) {
			accessExpression = (accessExpression == null) ?
					createArrayAccessExpression(operand, index) :
					createArrayAccessExpression(accessExpression, index);
		}
		return accessExpression;
	}
	
	public ArrayLiteralExpression createArrayLiteralExpression(Declaration declaration) {
		DirectReferenceExpression referenceExpression = createReferenceExpression(declaration);
		return createArrayLiteralExpression(referenceExpression);
	}
	
	public ArrayLiteralExpression createArrayLiteralExpression(Expression operand) {
		ArrayLiteralExpression arrayLiteralExpression = factory.createArrayLiteralExpression();
		
		TypeDefinition typeDefinition = typeDeterminator.getTypeDefinition(operand);
		for (int i = 0; i < ExpressionModelDerivedFeatures.getFirstDimension(typeDefinition); i++) {
			ArrayAccessExpression arrayAccessExpression = createArrayAccessExpression(
					ecoreUtil.clone(operand), i);
			arrayLiteralExpression.getOperands().add(arrayAccessExpression);
		}
		
		return arrayLiteralExpression;
	}
	
	public ArrayLiteralExpression createArrayLiteralExpression(Collection<? extends Expression> values) {
		ArrayLiteralExpression array = factory.createArrayLiteralExpression();
		
		for (Expression value : values) {
			array.getOperands().add(value);
		}
		
		return array;
	}
	
	public DirectReferenceExpression createReferenceExpression(Declaration declaration) {
		if (declaration == null) {
			throw new IllegalArgumentException("Declaration is null");
		}
		DirectReferenceExpression reference = factory.createDirectReferenceExpression();
		reference.setDeclaration(declaration);
		return reference;
	}
	
	public FieldReferenceExpression createReferenceExpression(FieldDeclaration field) {
		if (field == null) {
			throw new IllegalArgumentException("Declaration is null");
		}
		FieldReferenceExpression reference = factory.createFieldReferenceExpression();
		reference.setFieldDeclaration(field);
		return reference;
	}
	
	public FieldAssignment createFieldAssignment(FieldDeclaration field, Expression value) {
		FieldReferenceExpression reference = createReferenceExpression(field);
		FieldAssignment fieldAssignment = factory.createFieldAssignment();
		
		fieldAssignment.setReference(reference);
		fieldAssignment.setValue(value);
		
		return fieldAssignment;
	}
	
	public RecordLiteralExpression createRecordLiteral(RecordTypeDefinition record, List<? extends Expression> values) {
		RecordLiteralExpression recordLiteral = factory.createRecordLiteralExpression();
		TypeDeclaration typeDeclaration = ExpressionModelDerivedFeatures.getTypeDeclaration(record);
		recordLiteral.setTypeDeclaration(typeDeclaration);
		
		List<FieldDeclaration> fieldDeclarations = record.getFieldDeclarations();
		for (int i = 0; i < values.size(); i++) {
			Expression expression = values.get(i);
			FieldDeclaration fieldDeclaration = fieldDeclarations.get(i);
			
			FieldAssignment fieldAssignment = createFieldAssignment(fieldDeclaration, expression);
			recordLiteral.getFieldAssignments().add(fieldAssignment);
		}
		
		return recordLiteral;
	}
	
	public Expression createAnyEqualExpression(Declaration declaration, Collection<? extends Expression> expressions) {
		return createAnyEqualExpression(
				createReferenceExpression(declaration), expressions);
	}
	
	public Expression createAnyEqualExpression(Expression expression, Collection<? extends Expression> expressions) {
		List<Expression> equalityExpressions = new ArrayList<Expression>();
		
		for (Expression _expression : expressions) {
			EqualityExpression equalityExpression = createEqualityExpression(
					ecoreUtil.clone(expression), _expression);
			equalityExpressions.add(equalityExpression);
		}
		
		return wrapIntoOrExpression(equalityExpressions);
	}
	
	public EqualityExpression createEqualityExpression(VariableDeclaration variable, Expression expression) {
		EqualityExpression equalityExpression = factory.createEqualityExpression();
		equalityExpression.setLeftOperand(
				createReferenceExpression(variable));
		equalityExpression.setRightOperand(expression);
		return equalityExpression;
	}
	
	public EqualityExpression createEqualityExpression(Expression lhs, Expression rhs) {
		EqualityExpression equalityExpression = factory.createEqualityExpression();
		equalityExpression.setLeftOperand(lhs);
		equalityExpression.setRightOperand(rhs);
		return equalityExpression;
	}
	
	public InequalityExpression createInequalityExpression(VariableDeclaration variable, Expression expression) {
		InequalityExpression inequalityExpression = factory.createInequalityExpression();
		inequalityExpression.setLeftOperand(
				createReferenceExpression(variable));
		inequalityExpression.setRightOperand(expression);
		return inequalityExpression;
	}
	
	public InequalityExpression createInequalityExpression(Expression lhs, Expression rhs) {
		InequalityExpression inequalityExpression = factory.createInequalityExpression();
		inequalityExpression.setLeftOperand(lhs);
		inequalityExpression.setRightOperand(rhs);
		return inequalityExpression;
	}
	
	public LessExpression createLessExpression(Expression lhs, Expression rhs) {
		LessExpression lessExpression = factory.createLessExpression();
		lessExpression.setLeftOperand(lhs);
		lessExpression.setRightOperand(rhs);
		return lessExpression;
	}
	
	public LessEqualExpression createLessEqualExpression(Expression lhs, Expression rhs) {
		LessEqualExpression lessEqualExpression = factory.createLessEqualExpression();
		lessEqualExpression.setLeftOperand(lhs);
		lessEqualExpression.setRightOperand(rhs);
		return lessEqualExpression;
	}
	
	public GreaterExpression createGreaterExpression(Expression lhs, Expression rhs) {
		GreaterExpression greaterExpression = factory.createGreaterExpression();
		greaterExpression.setLeftOperand(lhs);
		greaterExpression.setRightOperand(rhs);
		return greaterExpression;
	}
	
	public GreaterEqualExpression createGreaterEqualExpression(Expression lhs, Expression rhs) {
		GreaterEqualExpression greaterEqualExpression = factory.createGreaterEqualExpression();
		greaterEqualExpression.setLeftOperand(lhs);
		greaterEqualExpression.setRightOperand(rhs);
		return greaterEqualExpression;
	}
	
	public ImplyExpression createImplyExpression(Expression lhs, Expression rhs) {
		ImplyExpression implyExpression = factory.createImplyExpression();
		implyExpression.setLeftOperand(lhs);
		implyExpression.setRightOperand(rhs);
		return implyExpression;
	}
	
	public IfThenElseExpression createMinExpression(Expression lhs, Expression rhs) {
		return createIfThenElseExpression(
			createLessExpression(lhs, rhs),
				ecoreUtil.clone(lhs), ecoreUtil.clone(rhs));
	}
	
	public IfThenElseExpression createMaxExpression(Expression lhs, Expression rhs) {
		return createIfThenElseExpression(
			createLessExpression(lhs, rhs),
				ecoreUtil.clone(rhs), ecoreUtil.clone(lhs));
	}
	
	public IfThenElseExpression createAbsExpression(Expression operand) {
		Type type = typeDeterminator.getType(operand);
		UnaryMinusExpression minus = factory.createUnaryMinusExpression();
		minus.setOperand(
				ecoreUtil.clone(operand));
		Expression _0 = createLiteralZero(type);
		return createIfThenElseExpression(
			createLessExpression(operand, _0),
				minus, ecoreUtil.clone(operand));
	}
	
	public EnumerationLiteralExpression createEnumerationLiteralExpression(
			EnumerationLiteralDefinition literal) {
		EnumerationLiteralExpression literalExpression = factory.createEnumerationLiteralExpression();
		literalExpression.setReference(literal);
		TypeDeclaration typeDeclaration = ExpressionModelDerivedFeatures.getTypeDeclaration(literal);
		TypeReference typeReference = createTypeReference(typeDeclaration);
		literalExpression.setTypeReference(typeReference);
		return literalExpression;
	}
	
	public SubtractExpression createSubtractExpression(Expression lhs, Expression rhs) {
		SubtractExpression subtractExpression = factory.createSubtractExpression();
		subtractExpression.setLeftOperand(lhs);
		subtractExpression.setRightOperand(rhs);
		return subtractExpression;
	}
	
	public Expression createDefaultExpression(Collection<? extends Expression> expressions) {
		Expression orExpression = wrapIntoOrExpression(expressions);
		NotExpression notExpression = createNotExpression(
				unwrapIfPossible(orExpression));
		return notExpression;
	}
	
	public Expression replaceAndWrapIntoMultiaryExpression(Expression original,
			Expression addition, MultiaryExpression potentialContainer) {
		if (original == null && addition == null) {
			throw new IllegalArgumentException(
					"Null original or addition parameter: " + original + " " + addition);
		}
		ecoreUtil.replace(potentialContainer, original);
		return wrapIntoMultiaryExpression(original, addition, potentialContainer);
	}
	
	public Expression wrapIntoMultiaryExpression(Expression original,
			Expression addition, MultiaryExpression potentialContainer) {
		List<Expression> operands = new ArrayList<Expression>();
		operands.add(original);
		operands.add(addition);
		return wrapIntoMultiaryExpression(operands, potentialContainer);
	}
	
	public Expression wrapIntoMultiaryExpression(Expression original,
			Collection<? extends Expression> additions, MultiaryExpression potentialContainer) {
		List<Expression> operands = new ArrayList<Expression>();
		operands.add(original);
		operands.addAll(additions);
		return wrapIntoMultiaryExpression(operands, potentialContainer);
	}
	
	public Expression wrapIntoMultiaryExpression(Collection<? extends Expression> expressions,
				MultiaryExpression potentialContainer) {
		List<Expression> operands = new ArrayList<Expression>(expressions);
		operands.removeIf(it -> it == null);
		
		if (operands.isEmpty()) {
			return null;
		}
		int size = operands.size();
		if (size == 1) {
			return operands.iterator().next();
		}
		potentialContainer.getOperands().addAll(operands);
		
		return potentialContainer;
	}
	
	public Expression wrapIntoAndExpression(Expression original, Expression addition) {
		return wrapIntoMultiaryExpression(original, addition, factory.createAndExpression());
	}
	
	public Expression wrapIntoAndExpression(Collection<? extends Expression> expressions) {
		return wrapIntoMultiaryExpression(expressions, factory.createAndExpression());
	}
	
	public Expression wrapIntoOrExpression(Expression original, Expression addition) {
		return wrapIntoMultiaryExpression(original, addition, factory.createOrExpression());
	}
	
	public Expression wrapIntoOrExpression(Collection<? extends Expression> expressions) {
		return wrapIntoMultiaryExpression(expressions, factory.createOrExpression());
	}
	
	public Expression wrapIntoAddExpression(Expression original, Expression addition) {
		return wrapIntoMultiaryExpression(original, addition, factory.createAddExpression());
	}
	
	public Expression wrapIntoAddExpression(Collection<? extends Expression> expressions) {
		return wrapIntoMultiaryExpression(expressions, factory.createAddExpression());
	}
	
	public ReferenceExpression index(ValueDeclaration declaration, List<Expression> indexes) {
		if (indexes.isEmpty()) {
			return createReferenceExpression(declaration);
		}
		int index = indexes.size() - 1;
		Expression lastIndex = indexes.get(index);
		ArrayAccessExpression access = factory.createArrayAccessExpression();
		access.setOperand(index(declaration, indexes.subList(0, index)));
		access.setIndex(lastIndex);
		return access;
	}
	
	public MultiaryExpression cloneIntoMultiaryExpression(Expression expression,
			MultiaryExpression container) {
		ecoreUtil.replace(container, expression);
		container.getOperands().add(expression);
		container.getOperands().add(
				ecoreUtil.clone(expression));
		return container;
	}
	
	// Unwrapper
	
	public Expression unwrapIfPossible(Expression expression) {
		if (expression instanceof MultiaryExpression multiaryExpression) {
			List<Expression> operands = multiaryExpression.getOperands();
			int size = operands.size();
			if (size >= 2) {
				return multiaryExpression;
			}
			if (size == 1) {
				return unwrapIfPossible(operands.get(0));
			}
			else {
				throw new IllegalStateException("Empty expression" + expression + " " + size);
			}
		}
		return expression;
	}
	
	// Message queue - array handling
	 
	private int getArrayCapacity(VariableDeclaration arrayVariable) {
		ArrayTypeDefinition type = (ArrayTypeDefinition) arrayVariable.getType();
		Expression size = type.getSize();
		int capacity = evaluator.evaluateInteger(size);
		return capacity;
	}
	
	public Expression peek(VariableDeclaration queue) {
		TypeDefinition typeDefinition = ExpressionModelDerivedFeatures.getTypeDefinition(queue);
		if (typeDefinition instanceof ArrayTypeDefinition) {
			ArrayAccessExpression accessExpression = factory.createArrayAccessExpression();
			accessExpression.setOperand(
					createReferenceExpression(queue));
			accessExpression.setIndex(
					toIntegerLiteral(0));
			return accessExpression;
		}
		throw new IllegalArgumentException("Not an array: " + queue);
	}
	
	public Expression isEmpty(VariableDeclaration sizeVariable) {
		return createLessEqualExpression(
				createReferenceExpression(sizeVariable), toIntegerLiteral(0));
	}
	
	public Expression isMasterQueueEmpty(VariableDeclaration queue, VariableDeclaration sizeVariable) {
		int capacity = getArrayCapacity(queue);
		if (capacity == 1) {
			Expression peek = peek(queue);
			TypeDefinition elementType = ExpressionModelDerivedFeatures.getElementTypeDefinition(queue);
			Expression emptyExpression = ExpressionModelDerivedFeatures.getDefaultExpression(elementType);
			return createEqualityExpression(peek, emptyExpression);
		}
		else {
			return isEmpty(sizeVariable);
		}
	}
	
	public Expression isMasterQueueNotEmpty(VariableDeclaration queue,
			VariableDeclaration sizeVariable) {
		return negator.negate( // To optimize
				isMasterQueueEmpty(queue, sizeVariable));
	}
	
	private LessEqualExpression isFull(VariableDeclaration sizeVariable, int capacity) {
		return createLessEqualExpression(
				toIntegerLiteral(capacity), createReferenceExpression(sizeVariable));
	}
	
	public Expression isMasterQueueFull(VariableDeclaration queue, VariableDeclaration sizeVariable) {
		int capacity = getArrayCapacity(queue);
		if (capacity == 1) {
			Expression peek = peek(queue);
			TypeDefinition elementType = ExpressionModelDerivedFeatures.getElementTypeDefinition(queue);
			Expression emptyExpression = ExpressionModelDerivedFeatures.getDefaultExpression(elementType);
			return createInequalityExpression(peek, emptyExpression);
		}
		else {
			return isFull(sizeVariable, capacity);
		}
	}
	
	public Expression isMasterQueueNotFull(VariableDeclaration queue,
			VariableDeclaration sizeVariable) {
		return negator.negate( // To optimize
				isMasterQueueFull(queue, sizeVariable));
	}
	
	public Expression getMasterQueueSize(VariableDeclaration queue, VariableDeclaration sizeVariable) {
		int capacity = getArrayCapacity(queue);
		if (capacity == 1) {
			return createIfThenElseExpression(
					isMasterQueueEmpty(queue, sizeVariable),
					createLiteralZero(), createLiteralOne());
		}
		return createReferenceExpression(sizeVariable);
	}
	
}