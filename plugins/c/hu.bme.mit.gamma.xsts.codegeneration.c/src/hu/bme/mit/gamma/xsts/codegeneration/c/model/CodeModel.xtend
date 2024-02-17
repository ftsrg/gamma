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
 * The CodeModel represents the C code file to be generated. It extends the FileModel class.
 * It contains the file name and content.
 */
class CodeModel extends FileModel {
	
	/**
	 * Creates a new CodeModel instance with the given name.
	 * 
	 * @param name the name of the C file to be generated
	 */
	new(String name) {
		super(name, '''«name.toLowerCase».c''')
	}
	
	/**
     * Returns the content of the file.
     * 
     * @return the content of the file
     */
	override String toString() {
		'''
			«include»
			«content»
		'''
	}
	
}