package hu.bme.mit.gamma.expression.util;

import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition;
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition;
import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition;
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition;
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition;
import hu.bme.mit.gamma.expression.model.RationalTypeDefinition;
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeReference;
import hu.bme.mit.gamma.expression.model.impl.ArrayTypeDefinitionImpl;
import hu.bme.mit.gamma.expression.model.impl.BooleanTypeDefinitionImpl;
import hu.bme.mit.gamma.expression.model.impl.DecimalTypeDefinitionImpl;
import hu.bme.mit.gamma.expression.model.impl.EnumerationTypeDefinitionImpl;
import hu.bme.mit.gamma.expression.model.impl.IntegerTypeDefinitionImpl;
import hu.bme.mit.gamma.expression.model.impl.RationalTypeDefinitionImpl;
import hu.bme.mit.gamma.expression.model.impl.RecordTypeDefinitionImpl;
import hu.bme.mit.gamma.expression.model.impl.TypeReferenceImpl;
import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;

public class TypeSerializer {
	public static final TypeSerializer INSTANCE = new TypeSerializer();
	protected TypeSerializer() {}

	
	public String serialize(Type type) {
		if (type instanceof TypeReferenceImpl) {
			return _serialize((TypeReferenceImpl)type);
		} else if (type instanceof BooleanTypeDefinitionImpl) {
			return _serialize((BooleanTypeDefinitionImpl)type);
		} else if (type instanceof IntegerTypeDefinitionImpl) {
			return _serialize((IntegerTypeDefinitionImpl)type);
		} else if (type instanceof DecimalTypeDefinitionImpl) {
			return _serialize((DecimalTypeDefinitionImpl)type);
		} else if (type instanceof RationalTypeDefinitionImpl) {
			return _serialize((RationalTypeDefinitionImpl)type);
		} else if (type instanceof ArrayTypeDefinitionImpl) {
			return _serialize((ArrayTypeDefinitionImpl)type);
		} else if (type instanceof EnumerationTypeDefinitionImpl) {
			return _serialize((EnumerationTypeDefinitionImpl)type);
		} else if (type instanceof RecordTypeDefinitionImpl) {
			return _serialize((RecordTypeDefinitionImpl)type);
		} else {
			return _serialize(type);
		}
	}
	
	protected String _serialize(Type type) {
		throw new IllegalArgumentException("Not supported type: " + type);
	}
	
	protected String _serialize(TypeReferenceImpl type) {
		if(ExpressionModelDerivedFeatures.isPrimitive(type.getReference().getType())) {
			return _serialize(type.getReference().getType());
		} else {
			return type.getReference().getName();
		}
	}
	
	protected String _serialize(BooleanTypeDefinitionImpl type) {
		return "boolean";
	}
	
	protected String _serialize(IntegerTypeDefinitionImpl type) {
		return "long";
	}
	
	protected String _serialize(DecimalTypeDefinitionImpl type) {
		return "double";
	}
	
	protected String _serialize(RationalTypeDefinitionImpl type) {
		return "double";
	}
	
	protected String _serialize(ArrayTypeDefinitionImpl type) {
		return _serialize(type.getElementType());
	}
	
	protected String _serialize(EnumerationTypeDefinitionImpl type) {
		return ExpressionModelDerivedFeatures.getTypeDeclaration(type).getName();
	}
	
	protected String _serialize(RecordTypeDefinitionImpl type) {
		return ExpressionModelDerivedFeatures.getTypeDeclaration(type).getName();
	}

}
