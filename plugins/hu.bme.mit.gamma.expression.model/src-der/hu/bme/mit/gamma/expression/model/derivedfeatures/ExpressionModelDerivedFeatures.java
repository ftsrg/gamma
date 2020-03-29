package hu.bme.mit.gamma.expression.model.derivedfeatures;

import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition;
import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition;
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition;
import hu.bme.mit.gamma.expression.model.RationalTypeDefinition;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeDefinition;
import hu.bme.mit.gamma.expression.model.TypeReference;

public class ExpressionModelDerivedFeatures {

	public static boolean isPrimitive(Type type) {
		if (type instanceof BooleanTypeDefinition || type instanceof IntegerTypeDefinition ||
				type instanceof DecimalTypeDefinition || type instanceof RationalTypeDefinition) {
			return true;
		}
		return false;
	}
	
	public static TypeDefinition getTypeDefinition(Type type) {
		if (type instanceof TypeDefinition) {
			return (TypeDefinition) type;
		}
		if (type instanceof TypeReference) {
			TypeReference typeReference = (TypeReference) type;
			return (TypeDefinition) typeReference.getReference().getType();
		}
		throw new IllegalArgumentException("Not known type: " + type);
	}
	
}
