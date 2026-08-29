/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.scxml.transformation

import static com.google.common.base.Preconditions.checkState
import static hu.bme.mit.gamma.scxml.transformation.Namings.*

class InterfaceTransformer extends AtomicElementTransformer {
	new(StatechartTraceability traceability) {
		super(traceability)
	}
	
	def getOrCreateDefaultInterface() {
		val defaultInterface = traceability.getDefaultInterface
		if (defaultInterface !== null) {
			return defaultInterface
		}
		else {
			val gammaInterface = createDefaultInterface
			traceability.setDefaultInterface(gammaInterface)
			return gammaInterface
		}
	}
	
	protected def createDefaultInterface() {
		val defaultInterface = createInterface
		val defaultInterfaceName = getDefaultInterfaceName(traceability.getTypeName())
		defaultInterface.name = defaultInterfaceName
		
		return defaultInterface
	}
	
	def getOrTransformInterfaceByName(String interfaceName) {
		checkState(interfaceName !== null)
		if (traceability.containsInterface(interfaceName)) {
			return traceability.getInterface(interfaceName)
		}
		else {
			val gammaInterface = transformInterfaceByName(interfaceName)
			traceability.putInterface(interfaceName, gammaInterface)
			return gammaInterface
		}
	}
	
	protected def transformInterfaceByName(String interfaceName) {
		val gammaInterface = createInterface
		val gammaInterfaceName = getInterfaceName(interfaceName)
		gammaInterface.name = gammaInterfaceName
		
		return gammaInterface
	}
	
}