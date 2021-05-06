package hu.bme.mit.gamma.expression.util;

import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition;
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition;
import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition;
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.IntegerRangeTypeDefinition;
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition;
import hu.bme.mit.gamma.expression.model.RationalTypeDefinition;
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeReference;
import hu.bme.mit.gamma.expression.model.VoidTypeDefinition;

public class TypeNamePrettyPrinter {
	public static final TypeNamePrettyPrinter INSTANCE = new TypeNamePrettyPrinter();
	protected TypeNamePrettyPrinter() {}
	
	protected ExpressionTypeDeterminator2 typeDeterminator = ExpressionTypeDeterminator2.INSTANCE;
	
	public String print(Expression expression) {
		Type type = typeDeterminator.getType(expression);
		return print(type);
	}
	
	public String print(Type type) {
		if (type instanceof IntegerTypeDefinition) {
			return "INTEGER";
		}
		if (type instanceof IntegerRangeTypeDefinition) {
			return "INTEGER RANGE";
		}
		if (type instanceof DecimalTypeDefinition) {
			return "DECIMAL";
		}
		if (type instanceof BooleanTypeDefinition) {
			return "BOOLEAN";
		}
		if (type instanceof RationalTypeDefinition) {
			return "RATIONAL";
		}
		if (type instanceof ArrayTypeDefinition) {
			return "ARRAY, type of elements: " + print(((ArrayTypeDefinition) type).getElementType());
		}
		if (type instanceof RecordTypeDefinition) {
			return "RECORD";
		}
		if (type instanceof EnumerationTypeDefinition) {
			return "ENUMERATION, name of enumeration: " + 
					ExpressionModelDerivedFeatures.getTypeDeclaration(type).getName();
		}
		if (type instanceof VoidTypeDefinition) {
			return "VOID";
		}
		if (type instanceof TypeReference) {
			return print(((TypeReference) type).getReference().getType());
		}
		throw new IllegalArgumentException("Unknown type!");
	}
}
