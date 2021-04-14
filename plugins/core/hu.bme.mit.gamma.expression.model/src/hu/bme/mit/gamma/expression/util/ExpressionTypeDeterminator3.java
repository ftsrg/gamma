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
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeDefinition;
import hu.bme.mit.gamma.expression.model.TypeReference;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class ExpressionTypeDeterminator3 {
	// Singleton
	public static final ExpressionTypeDeterminator3 INSTANCE = new ExpressionTypeDeterminator3();
	protected ExpressionTypeDeterminator3() {}
	//

	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected final ExpressionModelFactory factory = ExpressionModelFactory.eINSTANCE;
	
	
	public TypeDefinition getTypeDefinition(Expression expression) {
		Type type = getType(expression);
		for (TypeReference reference : ecoreUtil.getAllContentsOfType(type, TypeReference.class)) {
			TypeDefinition typeDefinition = ExpressionModelDerivedFeatures.getTypeDefinition(reference);
			ecoreUtil.replace(typeDefinition, reference);
		}
		return ExpressionModelDerivedFeatures.getTypeDefinition(type);
	}

	public Type getType(Expression expression) {
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
	
	protected Type getType(Declaration declaration) {
		return ExpressionModelDerivedFeatures.getTypeDefinition(declaration);
	}

	protected Type getType(ArrayLiteralExpression literal) {
		List<Expression> operands = literal.getOperands();
		if (operands.isEmpty()) {
			throw new IllegalArgumentException();
		}
		Expression firstOperand = operands.get(0);
		ArrayTypeDefinition arrayTypeDefinition = factory.createArrayTypeDefinition();
		arrayTypeDefinition.setElementType(getType(firstOperand));
		return arrayTypeDefinition;
	}
	
	protected Type getType(RecordLiteralExpression literal) {
		TypeReference typeReference = factory.createTypeReference();
		typeReference.setReference(literal.getTypeDeclaration());
		return typeReference;
	}

	protected Type getType(BooleanLiteralExpression literal) {
		return factory.createBooleanTypeDefinition();
	}

	protected Type getType(IntegerLiteralExpression literal) {
		return factory.createIntegerTypeDefinition();
	}

	protected Type getType(EnumerationLiteralExpression literal) {
		TypeReference typeReference = factory.createTypeReference();
		typeReference.setReference(ExpressionModelDerivedFeatures.getTypeDeclaration(literal.getReference()));
		return typeReference;
	}

}