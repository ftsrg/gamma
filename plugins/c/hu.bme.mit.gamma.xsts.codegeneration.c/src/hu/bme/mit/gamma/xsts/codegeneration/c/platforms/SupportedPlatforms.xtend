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
package hu.bme.mit.gamma.xsts.codegeneration.c.platforms

import java.util.HashMap
import java.util.Map

/**
 * Enum representing the supported platforms.
 */
enum SupportedPlatforms {
	UNIX
}

/**
 * Class to manage the platforms and retrieve platform instances.
 */
class Platforms {
	
	/**
     * Map to store the platform instances.
     */
	static val Map<SupportedPlatforms, IPlatform> platforms = addPlatforms()
	
	/**
     * Adds the platform instances to the map.
     *
     * @return The map of platforms.
     */
	private static def addPlatforms() {
		val temp = new HashMap<SupportedPlatforms, IPlatform>()
		
		/* add all available platforms here */
		temp += SupportedPlatforms.UNIX -> new UnixPlatform()
		
		return temp;
	}
	
	/**
     * Gets the platform instance for the given platform enum constant.
     *
     * @param platform The supported platform.
     * @return The platform instance.
     */
	static def IPlatform get(SupportedPlatforms platform) {
		return platforms.get(platform)
	}
	
}