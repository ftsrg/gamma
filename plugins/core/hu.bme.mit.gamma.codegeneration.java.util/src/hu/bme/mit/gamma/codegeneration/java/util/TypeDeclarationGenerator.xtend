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
package hu.bme.mit.gamma.codegeneration.java.util

import hu.bme.mit.gamma.expression.model.TypeDeclaration

import static extension hu.bme.mit.gamma.codegeneration.java.util.Namings.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class TypeDeclarationGenerator {
	
	protected final String BASE_PACKAGE_NAME
	
	protected final extension TypeDeclarationSerializer typeDeclarationSerializer = TypeDeclarationSerializer.INSTANCE
	
	new(String basePackageName) {
		this.BASE_PACKAGE_NAME = basePackageName
	}
	
	def String generateTypeDeclarationCode(TypeDeclaration type) '''
		package «type.getPackageString(BASE_PACKAGE_NAME)»;
		
		«FOR _package : type.containingPackage.imports.toSet»
			import «_package.getPackageString(BASE_PACKAGE_NAME)».*;
		«ENDFOR»
		
		public «type.serialize»
	'''
	
}