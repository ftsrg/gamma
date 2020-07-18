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
package hu.bme.mit.gamma.codegenerator.java.util

import hu.bme.mit.gamma.expression.model.TypeDeclaration

class TypeDeclarationGenerator {
	
	protected final String PACKAGE_NAME
	
	protected final extension TypeDeclarationSerializer typeDeclarationSerializer = TypeDeclarationSerializer.INSTANCE
	
	new(String packageName) {
		this.PACKAGE_NAME = packageName
	}
	
	def String generateTypeDeclarationCode(TypeDeclaration type) '''
		package «PACKAGE_NAME»;
		public «type.serialize»
	'''
	
}