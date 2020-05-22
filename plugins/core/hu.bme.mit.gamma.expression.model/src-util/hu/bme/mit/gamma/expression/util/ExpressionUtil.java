package hu.bme.mit.gamma.expression.util;

import java.io.File;
import java.io.IOException;
import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.common.util.TreeIterator;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EStructuralFeature.Setting;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.emf.ecore.util.EcoreUtil;
import org.eclipse.emf.ecore.util.EcoreUtil.Copier;
import org.eclipse.emf.ecore.util.EcoreUtil.EqualityHelper;
import org.eclipse.emf.ecore.util.EcoreUtil.UsageCrossReferencer;

import hu.bme.mit.gamma.expression.model.AndExpression;
import hu.bme.mit.gamma.expression.model.BinaryExpression;
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition;
import hu.bme.mit.gamma.expression.model.DecimalLiteralExpression;
import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression;
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition;
import hu.bme.mit.gamma.expression.model.EqualityExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.expression.model.FalseExpression;
import hu.bme.mit.gamma.expression.model.GreaterEqualExpression;
import hu.bme.mit.gamma.expression.model.IfThenElseExpression;
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression;
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition;
import hu.bme.mit.gamma.expression.model.LessEqualExpression;
import hu.bme.mit.gamma.expression.model.MultiaryExpression;
import hu.bme.mit.gamma.expression.model.NotExpression;
import hu.bme.mit.gamma.expression.model.NullaryExpression;
import hu.bme.mit.gamma.expression.model.OrExpression;
import hu.bme.mit.gamma.expression.model.RationalLiteralExpression;
import hu.bme.mit.gamma.expression.model.RationalTypeDefinition;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.TrueExpression;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeReference;
import hu.bme.mit.gamma.expression.model.UnaryExpression;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;

public class ExpressionUtil {

	protected ExpressionEvaluator evaluator = new ExpressionEvaluator();
	protected ExpressionModelFactory factory = ExpressionModelFactory.eINSTANCE;

	public ExpressionEvaluator getEvaluator() {
		return evaluator;
	}

	@SuppressWarnings("unchecked")
	public <T extends EObject> T getContainer(EObject element, Class<T> _class) {
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
			} catch (Exception e) {
			}
			// Excluding branches
			try {
				// Boolean
				boolean bool = evaluator.evaluateBoolean(expression);
				if (!booleanValues.contains(bool)) {
					booleanValues.add(bool);
					evaluatedExpressions.add(bool ? factory.createTrueExpression() : factory.createFalseExpression());
				}
			} catch (Exception e) {
			}
		}
		return evaluatedExpressions;
	}

	public boolean isDefinitelyTrueExpression(Expression expression) {
		if (expression instanceof TrueExpression) {
			return true;
		}
		if (expression instanceof BinaryExpression) {
			if (expression instanceof EqualityExpression || expression instanceof GreaterEqualExpression
					|| expression instanceof LessEqualExpression) {
				BinaryExpression binaryExpression = (BinaryExpression) expression;
				Expression leftOperand = binaryExpression.getLeftOperand();
				Expression rightOperand = binaryExpression.getRightOperand();
				if (helperEquals(leftOperand, rightOperand)) {
					return true;
				}
				if (!(leftOperand instanceof EnumerationLiteralExpression
						&& rightOperand instanceof EnumerationLiteralExpression)) {
					// Different enum literals could be evaluated to the same value
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
			if (leftOperand instanceof EnumerationLiteralExpression
					&& rightOperand instanceof EnumerationLiteralExpression) {
				EnumerationLiteralDefinition leftReference = ((EnumerationLiteralExpression) leftOperand)
						.getReference();
				EnumerationLiteralDefinition rightReference = ((EnumerationLiteralExpression) rightOperand)
						.getReference();
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
			List<EqualityExpression> referenceEqualityExpressions = filterReferenceEqualityExpressions(
					allEqualityExpressions);
			if (hasEqualityToDifferentLiterals(referenceEqualityExpressions)) {
				return true;
			}
		}
		return false;
	}

	/**
	 * Returns whether the disjunction of the given expressions is a certain event.
	 */
	public boolean isCertainEvent(Expression lhs, Expression rhs) {
		if (lhs instanceof NotExpression) {
			final Expression operand = ((NotExpression) lhs).getOperand();
			if (helperEquals(operand, rhs)) {
				return true;
			}
		}
		if (rhs instanceof NotExpression) {
			final Expression operand = ((NotExpression) rhs).getOperand();
			if (helperEquals(operand, lhs)) {
				return true;
			}
		}
		return false;
	}
	
	private boolean hasEqualityToDifferentLiterals(List<EqualityExpression> expressions) {
		for (int i = 0; i < expressions.size() - 1; ++i) {
			try {
				EqualityExpression leftEqualityExpression = expressions.get(i);
				ReferenceExpression leftReferenceExpression = (ReferenceExpression) leftEqualityExpression
						.getLeftOperand();
				Declaration leftDeclaration = leftReferenceExpression.getDeclaration();
				int leftValue = evaluator.evaluate(leftEqualityExpression.getRightOperand());
				for (int j = i + 1; j < expressions.size(); ++j) {
					try {
						EqualityExpression rightEqualityExpression = expressions.get(j);
						ReferenceExpression rightReferenceExpression = (ReferenceExpression) rightEqualityExpression
								.getLeftOperand();
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
			} else if (subexpression instanceof AndExpression) {
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
		Declaration declaration = expression.getDeclaration();
		if ((declaration instanceof VariableDeclaration)) {
			return Collections.singleton(((VariableDeclaration) declaration));
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
			throw new IllegalArgumentException(
					"Unhandled parameter types: " + Arrays.<Object>asList(expression).toString());
		}
	}

	// Initial values of types

	public Expression getInitialValue(final VariableDeclaration variableDeclaration) {
		final Expression initialValue = variableDeclaration.getExpression();
		if (initialValue != null) {
			return clone(initialValue, true, true);
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
		} else {
			throw new IllegalArgumentException("Unhandled parameter types: " + type);
		}
	}

	// Ecore Helpers

	@SuppressWarnings("unchecked")
	public void change(EObject newObject, EObject oldObject, EObject container) {
		Collection<Setting> oldReferences = UsageCrossReferencer.find(oldObject, container);
		for (Setting oldReference : oldReferences) {
			Object referenceHolder = oldReference.get(true);
			if (referenceHolder instanceof List) {
				List<EObject> list = (List<EObject>) referenceHolder;
				int index = list.indexOf(oldObject);
				list.set(index, newObject);
			}
			else {
				oldReference.set(newObject);
			}
		}
	}
	
	public void changeAndDelete(EObject newObject, EObject oldObject, EObject container) {
		change(newObject, oldObject, container);
		EcoreUtil.delete(oldObject); // Remove does not deletes other references
	}
	
	public void changeAll(EObject newObject, EObject oldObject, EObject container) {
		change(newObject, oldObject, container);
		TreeIterator<EObject> lhsContents = newObject.eAllContents();
		TreeIterator<EObject> rhsContents = oldObject.eAllContents();
		while (lhsContents.hasNext()) {
			EObject lhs = lhsContents.next();
			EObject rhs = rhsContents.next();
			change(lhs, rhs, container);
		}
		assert !rhsContents.hasNext();
	}
	
	public void changeAllAndDelete(EObject newObject, EObject oldObject, EObject container) {
		changeAll(newObject, oldObject, container);
		EcoreUtil.delete(oldObject);
	}

	public EObject normalLoad(URI uri) throws IOException {
		ResourceSet resourceSet = new ResourceSetImpl();
		Resource resource = resourceSet.getResource(uri, true);
		return resource.getContents().get(0);
	}

	public EObject normalLoad(String parentFolder, String fileName) throws IOException {
		return normalLoad(URI.createFileURI(parentFolder + File.separator + fileName));
	}

	public Resource normalSave(ResourceSet resourceSet, EObject rootElem, URI uri) throws IOException {
		Resource resource = resourceSet.createResource(uri);
		resource.getContents().add(rootElem);
		resource.save(Collections.EMPTY_MAP);
		return resource;
	}

	public Resource normalSave(ResourceSet resourceSet, EObject rootElem, String parentFolder, String fileName)
			throws IOException {
		URI uri = URI.createFileURI(parentFolder + File.separator + fileName);
		return normalSave(resourceSet, rootElem, uri);
	}

	public Resource normalSave(EObject rootElem, URI uri) throws IOException {
		return normalSave(new ResourceSetImpl(), rootElem, uri);
	}

	public Resource normalSave(EObject rootElem, String parentFolder, String fileName) throws IOException {
		return normalSave(new ResourceSetImpl(), rootElem, parentFolder, fileName);
	}

	public boolean helperEquals(EObject lhs, EObject rhs) {
		EqualityHelper helper = new EqualityHelper();
		return helper.equals(lhs, rhs);
	}

	@SuppressWarnings("unchecked")
	public <T extends EObject> T clone(T object, boolean a, boolean b) {
		// A new copier should be user every time, otherwise anomalies happen
		// (references are changed without asking)
		Copier copier = new Copier(a, b);
		EObject clone = copier.copy(object);
		copier.copyReferences();
		return (T) clone;
	}

}
