/********************************************************************************
 * Copyright (c) 2018-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.codegeneration.c.serializer

import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.expression.model.TypeDeclaration

/**
 * A serializer for type declarations.
 */
class TypeDeclarationSerializer {
	
	/**
	 * Transforms a string with underscores to camel case by converting each word's first letter
	 * after an underscore to uppercase.
	 *
	 * @param input the string to transform
	 * @return the transformed string in camel case
	 */
	def String transformString(String input) {
  		val parts = input.split("_")
  		val transformedParts = parts.map [ it.toFirstUpper ]
  		return transformedParts.join("_")
	}
	
	
	/**
	 * Serializes an enumeration type definition.
	 * 
	 * @param type The enumeration type definition.
	 * @param name The name of the enumeration type.
	 * @return The serialized string representation.
	 */
	def dispatch String serialize(EnumerationTypeDefinition type, String name) {
		return '''
			/* Enum representing region «name» */
			enum «transformString(name)» {
				«FOR literal : type.literals SEPARATOR ',' + System.lineSeparator»«literal.name»_«name.toLowerCase»«ENDFOR»
			} «name.toLowerCase»;
		''';
	}
	
	/**
	 * Serializes a type declaration of an unsupported type.
	 * 
	 * @param type The unsupported type.
	 * @param name The name of the type declaration.
	 * @throws IllegalArgumentException Always thrown.
	 */
	def dispatch String serialize(Type type, String name) {
		throw new IllegalArgumentException("Not supported type: " + type);
	}
	
	/**
	 * Serializes a type declaration.
	 * 
	 * @param type The type declaration.
	 * @return The serialized string representation.
	 */
	def String serialize(TypeDeclaration type) {
		type.type.serialize(type.name);
	}
	
}