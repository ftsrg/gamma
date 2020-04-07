/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.codegenerator.java

import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.expression.model.TypeDeclaration

class TypeDeclarationGenerator {
	
	protected final String PACKAGE_NAME
	
	new(String packageName) {
		this.PACKAGE_NAME = packageName
	}
	
	def String serialize(TypeDeclaration type) {
		val declaredType = type.type
		return declaredType.serialize(type.name)
	}
	
	protected def dispatch String serialize(Type type, String name) {
		throw new IllegalArgumentException("Not supported type: " + type)
	}
	
	protected def dispatch String serialize(EnumerationTypeDefinition type, String name) '''
		package «PACKAGE_NAME»;
		
		public enum «name» {
			«FOR literal : type.literals SEPARATOR ', '»«literal.name»«ENDFOR»
		}
	'''
	
}