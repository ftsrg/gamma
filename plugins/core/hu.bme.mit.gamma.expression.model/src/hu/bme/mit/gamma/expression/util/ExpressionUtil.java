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
package hu.bme.mit.gamma.expression.util;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.AbstractMap.SimpleEntry;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Map.Entry;
import java.util.Set;
import java.util.stream.Collectors;

import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.expression.model.AccessExpression;
import hu.bme.mit.gamma.expression.model.AndExpression;
import hu.bme.mit.gamma.expression.model.ArrayAccessExpression;
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression;
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition;
import hu.bme.mit.gamma.expression.model.BinaryExpression;
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition;
import hu.bme.mit.gamma.expression.model.ConstantDeclaration;
import hu.bme.mit.gamma.expression.model.DecimalLiteralExpression;
import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition;
import hu.bme.mit.gamma.expression.model.Declaration;
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
import hu.bme.mit.gamma.expression.model.GreaterEqualExpression;
import hu.bme.mit.gamma.expression.model.GreaterExpression;
import hu.bme.mit.gamma.expression.model.IfThenElseExpression;
import hu.bme.mit.gamma.expression.model.InequalityExpression;
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression;
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition;
import hu.bme.mit.gamma.expression.model.LessEqualExpression;
import hu.bme.mit.gamma.expression.model.LessExpression;
import hu.bme.mit.gamma.expression.model.MultiaryExpression;
import hu.bme.mit.gamma.expression.model.NotExpression;
import hu.bme.mit.gamma.expression.model.NullaryExpression;
import hu.bme.mit.gamma.expression.model.OrExpression;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.RationalLiteralExpression;
import hu.bme.mit.gamma.expression.model.RationalTypeDefinition;
import hu.bme.mit.gamma.expression.model.RecordAccessExpression;
import hu.bme.mit.gamma.expression.model.RecordLiteralExpression;
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.TrueExpression;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeDeclaration;
import hu.bme.mit.gamma.expression.model.TypeDefinition;
import hu.bme.mit.gamma.expression.model.TypeReference;
import hu.bme.mit.gamma.expression.model.UnaryExpression;
import hu.bme.mit.gamma.expression.model.ValueDeclaration;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class ExpressionUtil {
	// Singleton
	public static final ExpressionUtil INSTANCE = new ExpressionUtil();
	protected ExpressionUtil() {}
	//
	
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected final ExpressionEvaluator evaluator = ExpressionEvaluator.INSTANCE;
	protected final ExpressionModelFactory factory = ExpressionModelFactory.eINSTANCE;
	
	/**
	 * Worth extending in subclasses.
	 */
	public Declaration getDeclaration(Expression expression) {
		if (expression instanceof DirectReferenceExpression) {
			DirectReferenceExpression reference = (DirectReferenceExpression) expression;
			return reference.getDeclaration();
		}
		if (expression instanceof RecordAccessExpression) {
			RecordAccessExpression access = (RecordAccessExpression) expression;
			FieldReferenceExpression reference = access.getFieldReference();
			return getDeclaration(reference);
		}
		if (expression instanceof FieldReferenceExpression) {
			FieldReferenceExpression reference = (FieldReferenceExpression) expression;
			return reference.getFieldDeclaration();
		}
		if (expression instanceof ArrayAccessExpression) {
			// ?
		}
		if (expression instanceof AccessExpression) {
			// Default access
			AccessExpression access = (AccessExpression) expression;
			Expression operand = access.getOperand();
			return getDeclaration(operand);
		}
		throw new IllegalArgumentException("Not known declaration: " + expression);
	}
	
	/**
	 * Worth extending in subclasses.
	 */
	public ReferenceExpression getAccessReference(Expression expression) {
		if (expression instanceof DirectReferenceExpression) {
			return (DirectReferenceExpression) expression;
		}
		if (expression instanceof AccessExpression) {
			AccessExpression access = (AccessExpression) expression;
			return getAccessReference(access.getOperand());
		}
		throw new IllegalArgumentException("Not known declaration: " + expression);
	}
	
	/**
	 * Worth extending in subclasses.
	 */
	public Declaration getAccessedDeclaration(Expression expression) {
		if (expression instanceof DirectReferenceExpression) {
			DirectReferenceExpression reference = (DirectReferenceExpression) expression;
			return reference.getDeclaration();
		}
		if (expression instanceof AccessExpression) {
			AccessExpression access = (AccessExpression) expression;
			return getAccessedDeclaration(access.getOperand());
		}
		throw new IllegalArgumentException("Not known declaration: " + expression);
	}
	
	/**
	 * Worth extending in subclasses.
	 */
	public Collection<TypeDeclaration> getTypeDeclarations(EObject context) {
		ExpressionPackage _package = ecoreUtil.getSelfOrContainerOfType(context, ExpressionPackage.class);
		return _package.getTypeDeclarations();
	}
	
	//
	
	public FieldAssignment getFieldAssignment(
			RecordLiteralExpression literal, FieldHierarchy fieldHierarchy) {
		List<FieldAssignment> fieldAssignments = literal.getFieldAssignments();
		FieldAssignment fieldAssignment = null;
		for (FieldDeclaration field : fieldHierarchy.getFields()) {
			fieldAssignment = fieldAssignments.stream().filter(it -> 
				it.getReference().getFieldDeclaration() == field).findFirst().get();
			Expression fieldValue = fieldAssignment.getValue();
			if (fieldValue instanceof RecordLiteralExpression) {
				RecordLiteralExpression subrecord = (RecordLiteralExpression) fieldValue;
				fieldAssignments = subrecord.getFieldAssignments();
			}
		}
		return fieldAssignment;
	}
	
	//
	
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
					IntegerLiteralExpression integerLiteralExpression = factory.createIntegerLiteralExpression();
					integerLiteralExpression.setValue(BigInteger.valueOf(value));
					evaluatedExpressions.add(integerLiteralExpression);
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
			EnumerationLiteralExpression literalExpression = factory.createEnumerationLiteralExpression();
			literalExpression.setReference(type.getLiterals().get(index));
			literals.add(literalExpression);
		}
		return literals;
	}

	public boolean isDefinitelyTrueExpression(Expression expression) {
		if (expression instanceof TrueExpression) {
			return true;
		}
		if (expression instanceof BinaryExpression) {
			BinaryExpression binaryExpression = (BinaryExpression) expression;
			Expression leftOperand = binaryExpression.getLeftOperand();
			Expression rightOperand = binaryExpression.getRightOperand();
			if (expression instanceof EqualityExpression ||
					expression instanceof GreaterEqualExpression ||
					expression instanceof LessEqualExpression) {
				if (ecoreUtil.helperEquals(leftOperand, rightOperand)) {
					return true;
				}
			}
			if (!(leftOperand instanceof EnumerationLiteralExpression
					&& rightOperand instanceof EnumerationLiteralExpression)) {
				// Different enum literals could be evaluated to the same value
				try {
					int leftValue = evaluator.evaluate(leftOperand);
					int rightValue = evaluator.evaluate(rightOperand);
					if (leftValue == rightValue) {
						if (expression instanceof EqualityExpression ||
								expression instanceof GreaterEqualExpression ||
								expression instanceof LessEqualExpression) {
							return true;
						}
					}
					else if (leftValue < rightValue) {
						if (expression instanceof LessExpression ||
								expression instanceof LessEqualExpression) {
							return true;
						}
					}
					else { // leftValue > rightValue
						if (expression instanceof GreaterExpression ||
								expression instanceof GreaterEqualExpression) {
							return true;
						}
					}
				} catch (IllegalArgumentException e) {
					// One of the arguments is not evaluable
				}
			}
		}
		if (expression instanceof NotExpression) {
			NotExpression notExpression = (NotExpression) expression;
			return isDefinitelyFalseExpression(notExpression.getOperand());
		}
		if (expression instanceof OrExpression) {
			OrExpression orExpression = (OrExpression) expression;
			for (Expression subExpression : orExpression.getOperands()) {
				if (isDefinitelyTrueExpression(subExpression)) {
					return true;
				}
			}
		}
		if (expression instanceof AndExpression) {
			AndExpression andExpression = (AndExpression) expression;
			for (Expression subExpression : andExpression.getOperands()) {
				if (!isDefinitelyTrueExpression(subExpression)) {
					return false;
				}
			}
			return true;
		}
		return false;
	}

	public boolean isDefinitelyFalseExpression(Expression expression) {
		if (expression instanceof FalseExpression) {
			return true;
		}
		// Checking 'Red == Green' kind of assumptions
		if (expression instanceof BinaryExpression) {
			BinaryExpression binaryExpression = (BinaryExpression) expression;
			Expression leftOperand = binaryExpression.getLeftOperand();
			Expression rightOperand = binaryExpression.getRightOperand();
			if (expression instanceof EqualityExpression) {
				if (leftOperand instanceof EnumerationLiteralExpression
						&& rightOperand instanceof EnumerationLiteralExpression) {
					EnumerationLiteralDefinition leftReference =
							((EnumerationLiteralExpression) leftOperand).getReference();
					EnumerationLiteralDefinition rightReference =
							((EnumerationLiteralExpression) rightOperand).getReference();
					if (!ecoreUtil.helperEquals(leftReference, rightReference)) {
						return true;
					}
				}
			}
			try {
				int leftValue = evaluator.evaluate(leftOperand);
				int rightValue = evaluator.evaluate(rightOperand);
				if (leftValue == rightValue) {
					if (expression instanceof InequalityExpression || 
							expression instanceof LessExpression ||
							expression instanceof GreaterExpression) {
						return true;
					}
				}
				else { // leftValue != rightValue
					if (expression instanceof EqualityExpression) {
						return true;
					}
					if (leftValue < rightValue) {
						if (expression instanceof GreaterExpression ||
								expression instanceof GreaterEqualExpression) {
							return true;
						}
					}
					else { // leftValue > rightValue
						if (expression instanceof LessExpression ||
								expression instanceof LessEqualExpression) {
							return true;
						}
					}
				}
			} catch (IllegalArgumentException e) {
				// One of the arguments is not evaluable
			}
		}
		if (expression instanceof NotExpression) {
			NotExpression notExpression = (NotExpression) expression;
			return isDefinitelyTrueExpression(notExpression.getOperand());
		}
		if (expression instanceof AndExpression) {
			AndExpression andExpression = (AndExpression) expression;
			for (Expression subExpression : andExpression.getOperands()) {
				if (isDefinitelyFalseExpression(subExpression)) {
					return true;
				}
			}
			Collection<EqualityExpression> allEqualityExpressions = collectAllEqualityExpressions(andExpression);
			List<EqualityExpression> referenceEqualityExpressions = filterReferenceEqualityExpressions(
					allEqualityExpressions);
			if (hasEqualityToDifferentLiterals(referenceEqualityExpressions)) {
				return true;
			}
		}
		if (expression instanceof OrExpression) {
			OrExpression orExpression = (OrExpression) expression;
			for (Expression subExpression : orExpression.getOperands()) {
				if (!isDefinitelyFalseExpression(subExpression)) {
					return false;
				}
			}
			return true;
		}
		return false;
	}

	/**
	 * Returns whether the disjunction of the given expressions is a certain event.
	 */
	public boolean isCertainEvent(Expression lhs, Expression rhs) {
		if (lhs instanceof NotExpression) {
			final Expression operand = ((NotExpression) lhs).getOperand();
			if (ecoreUtil.helperEquals(operand, rhs)) {
				return true;
			}
		}
		if (rhs instanceof NotExpression) {
			final Expression operand = ((NotExpression) rhs).getOperand();
			if (ecoreUtil.helperEquals(operand, lhs)) {
				return true;
			}
		}
		return false;
	}
	
	private boolean hasEqualityToDifferentLiterals(List<EqualityExpression> expressions) {
		for (int i = 0; i < expressions.size() - 1; ++i) {
			try {
				EqualityExpression leftEqualityExpression = expressions.get(i);
				Entry<Declaration, Expression> left = getDeclarationExpressions(leftEqualityExpression);
				Declaration leftDeclaration = left.getKey();
				Expression leftValueExpression = left.getValue();
				int leftValue = evaluator.evaluate(leftValueExpression);
				for (int j = i + 1; j < expressions.size(); ++j) {
					try {
						EqualityExpression rightEqualityExpression = expressions.get(j);
						Entry<Declaration, Expression> right = getDeclarationExpressions(rightEqualityExpression);
						Declaration rightDeclaration = right.getKey();
						if (leftDeclaration == rightDeclaration) {
							Expression rightValueExpression = right.getValue();
							int rightValue = evaluator.evaluate(rightValueExpression);
							if (leftValue != rightValue) {
								return true;
							}
						}
					} catch (IllegalArgumentException e) {
						// j is not evaluable
						expressions.remove(j);
						--j;
					}
				}
			} catch (IllegalArgumentException e) {
				// i is not evaluable
				expressions.remove(i);
				--i;
			}
		}
		return false;
	}
	
	protected Entry<Declaration, Expression> getDeclarationExpressions(BinaryExpression expression) {
		Expression leftOperand = expression.getLeftOperand();
		Declaration declaration = getDeclaration(leftOperand);
		Expression rightOperand = expression.getRightOperand();
		return new SimpleEntry<Declaration, Expression>(declaration, rightOperand);
	}
	
	public Collection<EqualityExpression> collectAllEqualityExpressions(AndExpression expression) {
		List<EqualityExpression> equalityExpressions = new ArrayList<EqualityExpression>();
		for (Expression subexpression : expression.getOperands()) {
			if (subexpression instanceof EqualityExpression) {
				equalityExpressions.add((EqualityExpression) subexpression);
			}
			else if (subexpression instanceof AndExpression) {
				equalityExpressions.addAll(collectAllEqualityExpressions((AndExpression) subexpression));
			}
		}
		return equalityExpressions;
	}

	public List<EqualityExpression> filterReferenceEqualityExpressions(Collection<EqualityExpression> expressions) {
		return expressions.stream().filter(it -> it.getLeftOperand() instanceof ReferenceExpression
				&& !(it.getRightOperand() instanceof ReferenceExpression)).collect(Collectors.toList());
	}

	// Arithmetic: for now, integers only

	public Expression add(Expression expression, int value) {
		IntegerLiteralExpression integerLiteralExpression = factory.createIntegerLiteralExpression();
		integerLiteralExpression.setValue(BigInteger.valueOf(evaluator.evaluate(expression) + value));
		return integerLiteralExpression;
	}

	public Expression subtract(Expression expression, int value) {
		IntegerLiteralExpression integerLiteralExpression = factory.createIntegerLiteralExpression();
		integerLiteralExpression.setValue(BigInteger.valueOf(evaluator.evaluate(expression) - value));
		return integerLiteralExpression;
	}

	// Declaration references
	
	// Variables
	public Set<VariableDeclaration> getReferredVariables(EObject object) {
		Set<VariableDeclaration> variables = new HashSet<VariableDeclaration>();
		for (DirectReferenceExpression referenceExpression :
				ecoreUtil.getSelfAndAllContentsOfType(object, DirectReferenceExpression.class)) {
			Declaration declaration = referenceExpression.getDeclaration();
			if (declaration instanceof VariableDeclaration) {
				variables.add((VariableDeclaration) declaration);
			}
		}
		return variables;
	}
	
	protected Set<VariableDeclaration> _getReferredVariables(final NullaryExpression expression) {
		return Collections.emptySet();
	}

	protected Set<VariableDeclaration> _getReferredVariables(final UnaryExpression expression) {
		return getReferredVariables(expression.getOperand());
	}

	protected Set<VariableDeclaration> _getReferredVariables(final IfThenElseExpression expression) {
		Set<VariableDeclaration> variables = new HashSet<VariableDeclaration>();
		variables.addAll(getReferredVariables(expression.getCondition()));
		variables.addAll(getReferredVariables(expression.getThen()));
		variables.addAll(getReferredVariables(expression.getElse()));
		return variables;
	}

	protected Set<VariableDeclaration> _getReferredVariables(final ReferenceExpression expression) {
		if (expression instanceof DirectReferenceExpression) {
			if (((DirectReferenceExpression)expression).getDeclaration() instanceof VariableDeclaration) {
				return Collections.singleton((VariableDeclaration) ((DirectReferenceExpression)expression).getDeclaration());
			}
		} else if (expression instanceof AccessExpression) {
			return getReferredVariables(((AccessExpression)expression).getOperand());
		}
		return Collections.emptySet();
	}

	protected Set<VariableDeclaration> _getReferredVariables(final BinaryExpression expression) {
		Set<VariableDeclaration> variables = new HashSet<VariableDeclaration>();
		variables.addAll(getReferredVariables(expression.getLeftOperand()));
		variables.addAll(getReferredVariables(expression.getRightOperand()));
		return variables;
	}

	protected Set<VariableDeclaration> _getReferredVariables(final MultiaryExpression expression) {
		Set<VariableDeclaration> variables = new HashSet<VariableDeclaration>();
		EList<Expression> _operands = expression.getOperands();
		for (Expression operand : _operands) {
			variables.addAll(getReferredVariables(operand));
		}
		return variables;
	}

	public Set<VariableDeclaration> getReferredVariables(final Expression expression) {
		if (expression instanceof ReferenceExpression) {
			return _getReferredVariables((ReferenceExpression) expression);
		} else if (expression instanceof BinaryExpression) {
			return _getReferredVariables((BinaryExpression) expression);
		} else if (expression instanceof IfThenElseExpression) {
			return _getReferredVariables((IfThenElseExpression) expression);
		} else if (expression instanceof MultiaryExpression) {
			return _getReferredVariables((MultiaryExpression) expression);
		} else if (expression instanceof NullaryExpression) {
			return _getReferredVariables((NullaryExpression) expression);
		} else if (expression instanceof UnaryExpression) {
			return _getReferredVariables((UnaryExpression) expression);
		} else {
			throw new IllegalArgumentException("Unhandled parameter types: " + Arrays.<Object>asList(expression).toString());
		}
	}
	
	// Parameters
	public Set<ParameterDeclaration> getReferredParameters(EObject object) {
		Set<ParameterDeclaration> parameters = new HashSet<ParameterDeclaration>();
		for (DirectReferenceExpression referenceExpression :
				ecoreUtil.getSelfAndAllContentsOfType(object, DirectReferenceExpression.class)) {
			Declaration declaration = referenceExpression.getDeclaration();
			if (declaration instanceof ParameterDeclaration) {
				parameters.add((ParameterDeclaration) declaration);
			}
		}
		return parameters;
	}
	
	protected Set<ParameterDeclaration> _getReferredParameters(final NullaryExpression expression) {
		return Collections.emptySet();
	}

	protected Set<ParameterDeclaration> _getReferredParameters(final UnaryExpression expression) {
		return getReferredParameters(expression.getOperand());
	}

	protected Set<ParameterDeclaration> _getReferredParameters(final IfThenElseExpression expression) {
		Set<ParameterDeclaration> parameters = new HashSet<ParameterDeclaration>();
		parameters.addAll(getReferredParameters(expression.getCondition()));
		parameters.addAll(getReferredParameters(expression.getThen()));
		parameters.addAll(getReferredParameters(expression.getElse()));
		return parameters;
	}

	protected Set<ParameterDeclaration> _getReferredParameters(final ReferenceExpression expression) {
		if (expression instanceof DirectReferenceExpression) {
			DirectReferenceExpression reference = (DirectReferenceExpression) expression;
			Declaration declaration = reference.getDeclaration();
			if (declaration instanceof ParameterDeclaration) {
				ParameterDeclaration parameter = (ParameterDeclaration) declaration;
				return Collections.singleton(parameter);
			}
		}
		else if (expression instanceof AccessExpression) {
			return getReferredParameters(((AccessExpression)expression).getOperand());
		}
		return Collections.emptySet();
	}

	protected Set<ParameterDeclaration> _getReferredParameters(final BinaryExpression expression) {
		Set<ParameterDeclaration> parameters = new HashSet<ParameterDeclaration>();
		parameters.addAll(getReferredParameters(expression.getLeftOperand()));
		parameters.addAll(getReferredParameters(expression.getRightOperand()));
		return parameters;
	}

	protected Set<ParameterDeclaration> _getReferredParameters(final MultiaryExpression expression) {
		Set<ParameterDeclaration> parameters = new HashSet<ParameterDeclaration>();
		EList<Expression> _operands = expression.getOperands();
		for (Expression operand : _operands) {
			parameters.addAll(getReferredParameters(operand));
		}
		return parameters;
	}

	public Set<ParameterDeclaration> getReferredParameters(final Expression expression) {
		if (expression instanceof ReferenceExpression) {
			return _getReferredParameters((ReferenceExpression) expression);
		} else if (expression instanceof BinaryExpression) {
			return _getReferredParameters((BinaryExpression) expression);
		} else if (expression instanceof IfThenElseExpression) {
			return _getReferredParameters((IfThenElseExpression) expression);
		} else if (expression instanceof MultiaryExpression) {
			return _getReferredParameters((MultiaryExpression) expression);
		} else if (expression instanceof NullaryExpression) {
			return _getReferredParameters((NullaryExpression) expression);
		} else if (expression instanceof UnaryExpression) {
			return _getReferredParameters((UnaryExpression) expression);
		} else {
			throw new IllegalArgumentException("Unhandled parameter types: " + Arrays.<Object>asList(expression).toString());
		}
	}
	
	// Constants
	public Set<ConstantDeclaration> getReferredConstants(EObject object) {
		Set<ConstantDeclaration> constants = new HashSet<ConstantDeclaration>();
		for (DirectReferenceExpression referenceExpression :
				ecoreUtil.getSelfAndAllContentsOfType(object, DirectReferenceExpression.class)) {
			Declaration declaration = referenceExpression.getDeclaration();
			if (declaration instanceof ConstantDeclaration) {
				constants.add((ConstantDeclaration) declaration);
			}
		}
		return constants;
	}
	
	protected Set<ConstantDeclaration> _getReferredConstants(final NullaryExpression expression) {
		return Collections.emptySet();
	}

	protected Set<ConstantDeclaration> _getReferredConstants(final UnaryExpression expression) {
		return getReferredConstants(expression.getOperand());
	}

	protected Set<ConstantDeclaration> _getReferredConstants(final IfThenElseExpression expression) {
		Set<ConstantDeclaration> constants = new HashSet<ConstantDeclaration>();
		constants.addAll(getReferredConstants(expression.getCondition()));
		constants.addAll(getReferredConstants(expression.getThen()));
		constants.addAll(getReferredConstants(expression.getElse()));
		return constants;
	}

	protected Set<ConstantDeclaration> _getReferredConstants(final ReferenceExpression expression) {
		if (expression instanceof DirectReferenceExpression ) {
			DirectReferenceExpression reference = (DirectReferenceExpression) expression;
			Declaration declaration = reference.getDeclaration();
			if (declaration instanceof ConstantDeclaration) {
				ConstantDeclaration constant = (ConstantDeclaration) declaration;
				return Collections.singleton(constant);
			}
		}
		else if (expression instanceof AccessExpression) {
			return getReferredConstants(((AccessExpression)expression).getOperand());
		}
		return Collections.emptySet();
	}

	protected Set<ConstantDeclaration> _getReferredConstants(final BinaryExpression expression) {
		Set<ConstantDeclaration> constants = new HashSet<ConstantDeclaration>();
		constants.addAll(getReferredConstants(expression.getLeftOperand()));
		constants.addAll(getReferredConstants(expression.getRightOperand()));
		return constants;
	}

	protected Set<ConstantDeclaration> _getReferredConstants(final MultiaryExpression expression) {
		Set<ConstantDeclaration> constants = new HashSet<ConstantDeclaration>();
		EList<Expression> _operands = expression.getOperands();
		for (Expression operand : _operands) {
			constants.addAll(getReferredConstants(operand));
		}
		return constants;
	}

	public Set<ConstantDeclaration> _getReferredConstants(final Expression expression) {
		if (expression instanceof ReferenceExpression) {
			return _getReferredConstants((ReferenceExpression) expression);
		} else if (expression instanceof BinaryExpression) {
			return _getReferredConstants((BinaryExpression) expression);
		} else if (expression instanceof IfThenElseExpression) {
			return _getReferredConstants((IfThenElseExpression) expression);
		} else if (expression instanceof MultiaryExpression) {
			return _getReferredConstants((MultiaryExpression) expression);
		} else if (expression instanceof NullaryExpression) {
			return _getReferredConstants((NullaryExpression) expression);
		} else if (expression instanceof UnaryExpression) {
			return _getReferredConstants((UnaryExpression) expression);
		} else {
			throw new IllegalArgumentException("Unhandled parameter types: " + Arrays.<Object>asList(expression).toString());
		}
	}
	
	public Set<ConstantDeclaration> getReferredConstants(final Expression expression) {
		if (expression instanceof ReferenceExpression) {
			return _getReferredConstants((ReferenceExpression) expression);
		} else if (expression instanceof BinaryExpression) {
			return _getReferredConstants((BinaryExpression) expression);
		} else if (expression instanceof IfThenElseExpression) {
			return _getReferredConstants((IfThenElseExpression) expression);
		} else if (expression instanceof MultiaryExpression) {
			return _getReferredConstants((MultiaryExpression) expression);
		} else if (expression instanceof NullaryExpression) {
			return _getReferredConstants((NullaryExpression) expression);
		} else if (expression instanceof UnaryExpression) {
			return _getReferredConstants((UnaryExpression) expression);
		} else {
			throw new IllegalArgumentException("Unhandled parameter types: " + Arrays.<Object>asList(expression).toString());
		}
	}
	
	// Values (variables, parameters and constants)
	
	public Set<ValueDeclaration> getReferredValues(final Expression expression) {
		Set<ValueDeclaration> referred = new HashSet<ValueDeclaration>();
		referred.addAll(getReferredVariables(expression));
		referred.addAll(getReferredParameters(expression));
		referred.addAll(getReferredConstants(expression));
		return referred;
	}
	
	// Initial values of types

	public Expression getInitialValue(final VariableDeclaration variableDeclaration) {
		final Expression initialValue = variableDeclaration.getExpression();
		if (initialValue != null) {
			return ecoreUtil.clone(initialValue);
		}
		final Type type = variableDeclaration.getType();
		return getInitialValueOfType(type);
	}
	
	protected Expression _getInitialValueOfType(final TypeReference type) {
		return getInitialValueOfType(type.getReference().getType());
	}

	protected Expression _getInitialValueOfType(final BooleanTypeDefinition type) {
		return factory.createFalseExpression();
	}

	protected Expression _getInitialValueOfType(final IntegerTypeDefinition type) {
		IntegerLiteralExpression integerLiteralExpression = factory.createIntegerLiteralExpression();
		integerLiteralExpression.setValue(BigInteger.ZERO);
		return integerLiteralExpression;
	}

	protected Expression _getInitialValueOfType(final DecimalTypeDefinition type) {
		DecimalLiteralExpression decimalLiteralExpression = factory.createDecimalLiteralExpression();
		decimalLiteralExpression.setValue(BigDecimal.ZERO);
		return decimalLiteralExpression;
	}

	protected Expression _getInitialValueOfType(final RationalTypeDefinition type) {
		RationalLiteralExpression rationalLiteralExpression = factory.createRationalLiteralExpression();
		rationalLiteralExpression.setNumerator(BigInteger.ZERO);
		rationalLiteralExpression.setDenominator(BigInteger.ONE);
		return rationalLiteralExpression;
	}

	protected Expression _getInitialValueOfType(final EnumerationTypeDefinition type) {
		EnumerationLiteralExpression enumerationLiteralExpression = factory.createEnumerationLiteralExpression();
		enumerationLiteralExpression.setReference(type.getLiterals().get(0));
		return enumerationLiteralExpression;
	}
	
	protected Expression _getInitialValueOfType(final ArrayTypeDefinition type) {
		ArrayLiteralExpression arrayLiteralExpression = factory.createArrayLiteralExpression();
		int arraySize = type.getSize().getValue().intValue();
		for (int i = 0; i < arraySize; ++i) {
			Expression elementDefaultValue = getInitialValueOfType(type.getElementType());
			arrayLiteralExpression.getOperands().add(elementDefaultValue);
		}
		return arrayLiteralExpression;
	}
	
	protected Expression _getInitialValueOfType(final RecordTypeDefinition type) {
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
			assignment.setValue(getInitialValueOfType(field.getType()));
			recordLiteralExpression.getFieldAssignments().add(assignment);
		}
		return recordLiteralExpression;
	}

	public Expression getInitialValueOfType(final Type type) {
		if (type instanceof EnumerationTypeDefinition) {
			return _getInitialValueOfType((EnumerationTypeDefinition) type);
		} else if (type instanceof DecimalTypeDefinition) {
			return _getInitialValueOfType((DecimalTypeDefinition) type);
		} else if (type instanceof IntegerTypeDefinition) {
			return _getInitialValueOfType((IntegerTypeDefinition) type);
		} else if (type instanceof RationalTypeDefinition) {
			return _getInitialValueOfType((RationalTypeDefinition) type);
		} else if (type instanceof BooleanTypeDefinition) {
			return _getInitialValueOfType((BooleanTypeDefinition) type);
		} else if (type instanceof TypeReference) {
			return _getInitialValueOfType((TypeReference) type);
		} else if (type instanceof ArrayTypeDefinition) {
			return _getInitialValueOfType((ArrayTypeDefinition) type);
		} else if (type instanceof RecordTypeDefinition) {
			return _getInitialValueOfType((RecordTypeDefinition) type);
		} else {
			throw new IllegalArgumentException("Unhandled parameter types: " + type);
		}
	}
	
	// Types
	
	public TypeDefinition findTypeDefinitionOfType(Type type) {
		if (type instanceof TypeDefinition) {
			return (TypeDefinition) type;
		}
		else {
			// type instanceof TypeReference
			TypeReference typeReference = (TypeReference) type;
			TypeDeclaration typeDeclaration = typeReference.getReference();
			return findTypeDefinitionOfType(typeDeclaration.getType());
		}
	}
	
	public TypeDeclaration wrapIntoDeclaration(Type type, String name) {
		TypeDeclaration declaration = factory.createTypeDeclaration();
		declaration.setName(name);
		declaration.setType(type);
		return declaration;
	}
	
	public AndExpression connectThroughNegations(VariableDeclaration ponate,
			Collection<VariableDeclaration> toBeNegated) {
		AndExpression and = connectThroughNegations(toBeNegated);
		DirectReferenceExpression ponateReference = factory.createDirectReferenceExpression();
		ponateReference.setDeclaration(ponate);
		and.getOperands().add(ponateReference);
		return and;
	}
	
	public AndExpression connectThroughNegations(Collection<VariableDeclaration> toBeNegated) {
		AndExpression and = factory.createAndExpression();
		for (VariableDeclaration toBeNegatedVariable : toBeNegated) {
			DirectReferenceExpression reference = factory.createDirectReferenceExpression();
			reference.setDeclaration(toBeNegatedVariable);
			NotExpression not = factory.createNotExpression();
			not.setOperand(reference);
			and.getOperands().add(not);
		}
		if (and.getOperands().isEmpty()) {
			// If collection is empty, the expression is always true
			and.getOperands().add(factory.createTrueExpression());
		}
		return and;
	}
	
	// Creators
	
	public BigInteger toBigInt(long value) {
		return BigInteger.valueOf(value);
	}
	
	public IntegerLiteralExpression toIntegerLiteral(long value) {
		IntegerLiteralExpression integerLiteral = factory.createIntegerLiteralExpression();
		integerLiteral.setValue(toBigInt(value));
		return integerLiteral;
	}
	
	public DirectReferenceExpression createReferenceExpression(ValueDeclaration variable) {
		DirectReferenceExpression reference = factory.createDirectReferenceExpression();
		reference.setDeclaration(variable);
		return reference;
	}
	
	public EqualityExpression createEqualityExpression(VariableDeclaration variable, Expression expression) {
		EqualityExpression equalityExpression = factory.createEqualityExpression();
		equalityExpression.setLeftOperand(createReferenceExpression(variable));
		equalityExpression.setRightOperand(expression);
		return equalityExpression;
	}
	
	public EqualityExpression createEqualityExpression(Expression lhs, Expression rhs) {
		EqualityExpression equalityExpression = factory.createEqualityExpression();
		equalityExpression.setLeftOperand(lhs);
		equalityExpression.setRightOperand(rhs);
		return equalityExpression;
	}
	
	public EnumerationLiteralExpression wrap(EnumerationLiteralDefinition literal) {
		EnumerationLiteralExpression literalExpression = factory.createEnumerationLiteralExpression();
		literalExpression.setReference(literal);
		return literalExpression;
	}
	
	public Expression wrapIntoMultiaryExpression(Expression original,
			Expression addition, MultiaryExpression potentialContainer) {
		if (original == null) {
			return addition;
		}
		if (addition == null) {
			return original;
		}
		potentialContainer.getOperands().add(original);
		potentialContainer.getOperands().add(addition);
		return potentialContainer;
	}
	
	public Expression wrapIntoMultiaryExpression(Collection<Expression> expressions,
			MultiaryExpression potentialContainer) {
		if (expressions.isEmpty()) {
			return null;
		}
		int size = expressions.size();
		if (size == 1) {
			return expressions.iterator().next();
		}
		potentialContainer.getOperands().addAll(expressions);
		return potentialContainer;
	}
	
	public ReferenceExpression index(ValueDeclaration declaration, List<Expression> indexes) {
		ReferenceExpression referenceExpression = createReferenceExpression(declaration);
		if (indexes.isEmpty()) {
			return referenceExpression;
		}
		ArrayAccessExpression access = factory.createArrayAccessExpression();
		access.setOperand(referenceExpression);
		access.getIndexes().addAll(ecoreUtil.clone(indexes));
		return access;
	}
	
}
