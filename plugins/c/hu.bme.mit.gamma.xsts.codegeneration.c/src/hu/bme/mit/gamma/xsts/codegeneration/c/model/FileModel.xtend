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

import hu.bme.mit.gamma.util.FileUtil
import java.io.File
import org.eclipse.emf.common.util.URI

/**
 * Represents a file in the generated C code.
 */
abstract class FileModel {
	/** The name of the model. */
	protected String name
	/** The name of the file. */
	protected String filename
	/** The content of the file. */
	protected String content
	/** The includes of the file */
	protected String include
	
	val FileUtil fileUtil = FileUtil.INSTANCE
	
	/**
     * Constructs a new {@code FileModel} instance with the given name.
     * 
     * @param name the name of the model
     * @param filename the name of the file
     */
	new(String name, String filename) {
		this.name = name
		this.filename = filename
		content = new String
		include = new String
	}
	
	/**
     * Saves the file to the given URI.
     * 
     * @param uri the URI where the file should be saved
     */
	def void save(URI uri) {
		val URI local = uri.appendSegment(filename)
		val File file = fileUtil.getFile(local.toFileString())
		
		if (file.exists())
			fileUtil.forceDelete(file)
			
		fileUtil.saveString(file, toString)
	}
	
	/**
     * Adds an include to the file.
     * 
     * @param include the include to be added to the file
     */
	def void addInclude(String include) {
		this.include += include
	}
	
	/**
     * Adds content to the file.
     * 
     * @param content the content to be added to the file
     */
	def void addContent(String content) {
		this.content += System.lineSeparator + content
	}
	
	/**
     * Returns the content of the file.
     * 
     * @return the content of the file
     */
	abstract override String toString()
	
}