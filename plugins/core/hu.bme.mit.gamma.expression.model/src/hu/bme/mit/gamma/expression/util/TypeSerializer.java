/********************************************************************************
 * Copyright (c) 2018-2021 Contributors to the Gamma project
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

public class TypeSerializer {
	//
	public static final TypeSerializer INSTANCE = new TypeSerializer();
	protected TypeSerializer() {}
	//

	public String serialize(Type type) {
		if (type instanceof TypeReference) {
			return _serialize((TypeReference) type);
		} else if (type instanceof BooleanTypeDefinition) {
			return _serialize((BooleanTypeDefinition) type);
		} else if (type instanceof IntegerTypeDefinition) {
			return _serialize((IntegerTypeDefinition) type);
		} else if (type instanceof DecimalTypeDefinition) {
			return _serialize((DecimalTypeDefinition) type);
		} else if (type instanceof RationalTypeDefinition) {
			return _serialize((RationalTypeDefinition) type);
		} else if (type instanceof ArrayTypeDefinition) {
			return _serialize((ArrayTypeDefinition) type);
		} else if (type instanceof EnumerationTypeDefinition) {
			return _serialize((EnumerationTypeDefinition) type);
		} else if (type instanceof RecordTypeDefinition) {
			return _serialize((RecordTypeDefinition) type);
		} else {
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
		} else {
			return reference.getName();
		}
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
		return serialize(type.getElementType()) + "[]";
	}

	protected String _serialize(EnumerationTypeDefinition type) {
		return ExpressionModelDerivedFeatures.getTypeDeclaration(type).getName();
	}

	protected String _serialize(RecordTypeDefinition type) {
		return ExpressionModelDerivedFeatures.getTypeDeclaration(type).getName();
	}

}