/********************************************************************************
 * Copyright (c) 2018 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.yakindu.genmodel.language


/**
 * Initialization support for running Xtext languages without Equinox extension registry.
 */
class GenModelStandaloneSetup extends GenModelStandaloneSetupGenerated {

	def static void doSetup() {
		new GenModelStandaloneSetup().createInjectorAndDoEMFRegistration()
	}
}
