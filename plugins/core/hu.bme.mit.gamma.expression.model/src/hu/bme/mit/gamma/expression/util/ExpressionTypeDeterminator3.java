package hu.bme.mit.gamma.expression.util;

import java.util.List;

import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression;
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition;
import hu.bme.mit.gamma.expression.model.BooleanLiteralExpression;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression;
import hu.bme.mit.gamma.expression.model.RecordLiteralExpression;
import hu.bme.mit.gamma.expression.model.TypeDefinition;

public class ExpressionTypeDeterminator3 {
	// Singleton
	public static final ExpressionTypeDeterminator3 INSTANCE = new ExpressionTypeDeterminator3();
	protected ExpressionTypeDeterminator3() {}
	//
	
	protected final ExpressionModelFactory factory = ExpressionModelFactory.eINSTANCE;

	public TypeDefinition getType(Expression expression) {
		if (expression instanceof BooleanLiteralExpression) {
			return getType((BooleanLiteralExpression) expression);
		}
		if (expression instanceof IntegerLiteralExpression) {
			return getType((IntegerLiteralExpression) expression);
		}
		if (expression instanceof EnumerationLiteralExpression) {
			return getType((EnumerationLiteralExpression) expression);
		}
		if (expression instanceof ArrayLiteralExpression) {
			return getType((ArrayLiteralExpression) expression);
		}
		if (expression instanceof RecordLiteralExpression) {
			return getType((RecordLiteralExpression) expression);
		}
		if (expression instanceof Declaration) {
			return getType((Declaration) expression);
		}
		throw new IllegalArgumentException();
	}
	
	protected TypeDefinition getType(Declaration declaration) {
		return ExpressionModelDerivedFeatures.getTypeDefinition(declaration);
	}

	protected TypeDefinition getType(ArrayLiteralExpression literal) {
		List<Expression> operands = literal.getOperands();
		if (operands.isEmpty()) {
			throw new IllegalArgumentException();
		}
		Expression firstOperand = operands.get(0);
		ArrayTypeDefinition arrayTypeDefinition = factory.createArrayTypeDefinition();
		arrayTypeDefinition.setElementType(getType(firstOperand));
		return arrayTypeDefinition;
	}
	
	protected TypeDefinition getType(RecordLiteralExpression literal) {
		return ExpressionModelDerivedFeatures
				.getTypeDefinition(literal.getTypeDeclaration());
	}

	protected TypeDefinition getType(BooleanLiteralExpression literal) {
		return factory.createBooleanTypeDefinition();
	}

	protected TypeDefinition getType(IntegerLiteralExpression literal) {
		return factory.createIntegerTypeDefinition();
	}

	protected TypeDefinition getType(EnumerationLiteralExpression literal) {
		return ExpressionModelDerivedFeatures
				.getTypeDefinition(ExpressionModelDerivedFeatures.getTypeDeclaration(literal.getReference()));
	}

}
