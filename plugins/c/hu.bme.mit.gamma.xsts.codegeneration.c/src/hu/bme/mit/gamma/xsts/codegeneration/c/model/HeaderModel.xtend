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
package hu.bme.mit.gamma.xsts.codegeneration.c.model

/**
 * Represents a C header file model.
 */
class HeaderModel extends FileModel {
	
	/**
     * Creates a new HeaderModel instance with the given name.
     * 
     * @param name the name of the header file
     */
	new(String name) {
		super(name, '''«name.toLowerCase».h''')
	}
	
	/**
     * Returns the content of the file.
     * 
     * @return the content of the file
     */
	override String toString() {
		'''
			«include»
			
			/* header guard */
			#ifndef «name.toUpperCase»_HEADER
			#define «name.toUpperCase»_HEADER
			«content»
			
			#endif /* «name.toUpperCase»_HEADER */
		'''
	}
	
}