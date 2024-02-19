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
package hu.bme.mit.gamma.xsts.codegeneration.c

import hu.bme.mit.gamma.xsts.codegeneration.c.platforms.SupportedPlatforms
import org.eclipse.emf.common.util.URI

/**
 * An interface for defining statechart code generation behavior.
 */
interface IStatechartCode {
	/**
	 * Constructs the header of the statechart code.
	 */
	def void constructHeader()
	
	/**
	 * Constructs the body of the statechart code.
	 */
	def void constructCode()
	
	/**
	 * Saves the generated code to the specified URI.
	 * 
	 * @param uri the URI to save the code to
	 */
	def void save(URI uri)
	
	/**
 	 * Sets the platform for the generator.
 	 * 
 	 * @param platform the platform to set
 	 */
	def void setPlatform(SupportedPlatforms platform)
}