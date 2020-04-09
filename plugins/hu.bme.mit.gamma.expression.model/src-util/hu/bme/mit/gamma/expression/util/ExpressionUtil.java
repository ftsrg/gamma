package hu.bme.mit.gamma.expression.util;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.util.EcoreUtil.EqualityHelper;

import hu.bme.mit.gamma.expression.model.AndExpression;
import hu.bme.mit.gamma.expression.model.BinaryExpression;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression;
import hu.bme.mit.gamma.expression.model.EqualityExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.expression.model.FalseExpression;
import hu.bme.mit.gamma.expression.model.GreaterEqualExpression;
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression;
import hu.bme.mit.gamma.expression.model.LessEqualExpression;
import hu.bme.mit.gamma.expression.model.NotExpression;
import hu.bme.mit.gamma.expression.model.OrExpression;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.TrueExpression;

public class ExpressionUtil {

	protected ExpressionEvaluator evaluator = new ExpressionEvaluator();
	protected ExpressionModelFactory factory = ExpressionModelFactory.eINSTANCE;
	
	@SuppressWarnings("unchecked")
	public  <T extends EObject> T getContainer(EObject element, Class<T> _class) {
		EObject container = element.eContainer();
		if (container == null) {
			return null;
		}
		if (_class.isInstance(container)) {
			return (T) container;
		}
		return getContainer(container, _class);
	}
	
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
	
	public boolean isDefinitelyTrueExpression(Expression expression) {
		if (expression instanceof TrueExpression) {
			return true;
		}
		if (expression instanceof BinaryExpression) {
			if (expression instanceof EqualityExpression
					|| expression instanceof GreaterEqualExpression
					|| expression instanceof LessEqualExpression) {
				BinaryExpression binaryExpression = (BinaryExpression) expression;
				Expression leftOperand = binaryExpression.getLeftOperand();
				Expression rightOperand = binaryExpression.getRightOperand();
				if (helperEquals(leftOperand, rightOperand)) {
					return true;
				}
				if (!(leftOperand instanceof EnumerationLiteralExpression &&
						rightOperand instanceof EnumerationLiteralExpression)) {
					try {
						int leftValue = evaluator.evaluate(leftOperand);
						int rightValue = evaluator.evaluate(rightOperand);
						if (leftValue == rightValue) {
							return true;
						}
					} catch (IllegalArgumentException e) {
						// One of the arguments is not evaluable
					}
				}
			}
		}
		if (expression instanceof OrExpression) {
			OrExpression orExpression = (OrExpression) expression;
			for (Expression subExpression : orExpression.getOperands()) {
				if (isDefinitelyTrueExpression(subExpression)) {
					return true;
				}
			}
		}
		return false;
	}
	
	public boolean isDefinitelyFalseExpression(Expression expression) {
		if (expression instanceof FalseExpression) {
			return true;
		}
		// Checking 'Red == Green' kind of assumptions
		if (expression instanceof EqualityExpression) {
			EqualityExpression equilityExpression = (EqualityExpression) expression;
			Expression leftOperand = equilityExpression.getLeftOperand();
			Expression rightOperand = equilityExpression.getRightOperand();
			if (leftOperand instanceof EnumerationLiteralExpression && 
					rightOperand instanceof EnumerationLiteralExpression) {
				EnumerationLiteralDefinition leftReference = ((EnumerationLiteralExpression) leftOperand).getReference();
				EnumerationLiteralDefinition rightReference = ((EnumerationLiteralExpression) rightOperand).getReference();
				if (!helperEquals(leftReference, rightReference)) {
					return true;
				}
			}
			try {
				int leftValue = evaluator.evaluate(leftOperand);
				int rightValue = evaluator.evaluate(rightOperand);
				if (leftValue != rightValue) {
					return true;
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
			List<EqualityExpression> referenceEqualityExpressions = filterReferenceEqualityExpressions(allEqualityExpressions);
			if (hasEqualityToDifferentLiterals(referenceEqualityExpressions)) {
				return true;
			}
		}
		return false;
	}
	
	private boolean hasEqualityToDifferentLiterals(List<EqualityExpression> expressions) {
		for (int i = 0; i < expressions.size() - 1; ++i) {
			try {
				EqualityExpression leftEqualityExpression = expressions.get(i);
				ReferenceExpression leftReferenceExpression = (ReferenceExpression) leftEqualityExpression.getLeftOperand();
				Declaration leftDeclaration = leftReferenceExpression.getDeclaration();
				int leftValue = evaluator.evaluate(leftEqualityExpression.getRightOperand());
				for (int j = i + 1; j < expressions.size(); ++j) {
					try {
						EqualityExpression rightEqualityExpression = expressions.get(j);
						ReferenceExpression rightReferenceExpression = (ReferenceExpression) rightEqualityExpression.getLeftOperand();
						Declaration rightDeclaration = rightReferenceExpression.getDeclaration();
						int rightValue = evaluator.evaluate(rightEqualityExpression.getRightOperand());
						if (leftDeclaration == rightDeclaration && leftValue != rightValue) {
							return true;
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
		return expressions.stream().filter(it -> it.getLeftOperand() instanceof ReferenceExpression &&
				!(it.getRightOperand() instanceof ReferenceExpression)).collect(Collectors.toList());
	}
	
	public boolean helperEquals(EObject lhs, EObject rhs) {
		EqualityHelper helper = new EqualityHelper();
		return helper.equals(lhs, rhs);
	}
	
}
