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
package hu.bme.mit.gamma.fei.language.validation

import hu.bme.mit.gamma.fei.model.FaultMode
import hu.bme.mit.gamma.fei.model.FaultSlice
import hu.bme.mit.gamma.fei.model.FaultTransition
import hu.bme.mit.gamma.fei.util.FaultExtensionModelValidator
import org.eclipse.xtext.validation.Check

class FaultExtensionLanguageValidator extends AbstractFaultExtensionLanguageValidator {
	//
	protected FaultExtensionModelValidator feiModelValidator = FaultExtensionModelValidator.INSTANCE;
	//
	
	new() {
		super.expressionModelValidator = feiModelValidator
		super.actionModelValidator = feiModelValidator
	}
	
	@Check
	def checkFaultModes(FaultMode faultMode) {
		handleValidationResultMessage(feiModelValidator.checkFaultModes(faultMode));
	}
	
	@Check
	def checkGlobalDynamics(FaultSlice faultSlice) {
		handleValidationResultMessage(feiModelValidator.checkGlobalDynamics(faultSlice));
	}
	
	@Check
	def checkFaultTransitions(FaultTransition faultTransition) {
		handleValidationResultMessage(feiModelValidator.checkFaultTransition(faultTransition));
	}
	
}
