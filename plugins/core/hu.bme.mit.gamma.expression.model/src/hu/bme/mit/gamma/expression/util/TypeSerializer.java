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

import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition;
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition;
import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition;
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition;
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition;
import hu.bme.mit.gamma.expression.model.RationalTypeDefinition;
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeDeclaration;
import hu.bme.mit.gamma.expression.model.TypeReference;
import hu.bme.mit.gamma.expression.model.VoidTypeDefinition;

public class TypeSerializer {
	//
	public static final TypeSerializer INSTANCE = new TypeSerializer();
	protected TypeSerializer() {}
	//
	protected final ExpressionEvaluator evaluator = ExpressionEvaluator.INSTANCE;
	//

	public String serialize(Type type) {
		if (type instanceof TypeReference _type) {
			return _serialize(_type);
		}
		else if (type instanceof VoidTypeDefinition _type) {
			return _serialize(_type);
		}
		else if (type instanceof BooleanTypeDefinition _type) {
			return _serialize(_type);
		}
		else if (type instanceof IntegerTypeDefinition _type) {
			return _serialize(_type);
		}
		else if (type instanceof DecimalTypeDefinition _type) {
			return _serialize(_type);
		}
		else if (type instanceof RationalTypeDefinition _type) {
			return _serialize(_type);
		}
		else if (type instanceof ArrayTypeDefinition _type) {
			return _serialize(_type);
		}
		else if (type instanceof EnumerationTypeDefinition _type) {
			return _serialize(_type);
		}
		else if (type instanceof RecordTypeDefinition _type) {
			return _serialize(_type);
		}
		else {
			return _serialize(type);
		}
	}

	protected String _serialize(Type type) {
		throw new IllegalArgumentException("Not supported type: " + type);
	}

	protected String _serialize(TypeReference type) {
		TypeDeclaration reference = type.getReference();
		Type referencedType = reference.getType();
		if (ExpressionModelDerivedFeatures.isPrimitive(referencedType)) {
			return serialize(referencedType);
		}
		else {
			return reference.getName();
		}
	}
	
	protected String _serialize(VoidTypeDefinition type) {
		return "void";
	}

	protected String _serialize(BooleanTypeDefinition type) {
		return "boolean";
	}

	protected String _serialize(IntegerTypeDefinition type) {
		return "long";
	}

	protected String _serialize(DecimalTypeDefinition type) {
		return "double";
	}

	protected String _serialize(RationalTypeDefinition type) {
		return "rational";
	}

	protected String _serialize(ArrayTypeDefinition type) {
		Type elementType = type.getElementType();
		return serialize(elementType) + "[]";
	}

	protected String _serialize(EnumerationTypeDefinition type) {
		TypeDeclaration typeDeclaration = ExpressionModelDerivedFeatures.getTypeDeclaration(type);
		return typeDeclaration.getName();
	}

	protected String _serialize(RecordTypeDefinition type) {
		TypeDeclaration typeDeclaration = ExpressionModelDerivedFeatures.getTypeDeclaration(type);
		return typeDeclaration.getName();
	}
	
	//
	
	public String serializeId(Type type) {
		if (type instanceof ArrayTypeDefinition _type) {
			return _serializeId(_type);
		}
		return serialize(type);
	}
	
	protected String _serializeId(ArrayTypeDefinition type) {
		Type elementType = type.getElementType();
		return evaluator.evaluate(
				type.getSize()) + "_" + serializeId(elementType);
	}

}