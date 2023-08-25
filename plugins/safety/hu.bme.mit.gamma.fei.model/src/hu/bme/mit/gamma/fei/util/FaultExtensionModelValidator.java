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
package hu.bme.mit.gamma.fei.util;

import java.util.ArrayList;
import java.util.Collection;

import hu.bme.mit.gamma.fei.model.Effect;
import hu.bme.mit.gamma.fei.model.FaultMode;
import hu.bme.mit.gamma.fei.model.FeiModelPackage;
import hu.bme.mit.gamma.fei.model.LocalDynamics;
import hu.bme.mit.gamma.fei.model.SelfFixTemplate;
import hu.bme.mit.gamma.statechart.util.StatechartModelValidator;

public class FaultExtensionModelValidator extends StatechartModelValidator {
	// Singleton
	public static final FaultExtensionModelValidator INSTANCE = new FaultExtensionModelValidator();
	protected FaultExtensionModelValidator() {
		// TODO add ExpressionTypeValidator
	}
	//
	
	public Collection<ValidationResultMessage> checkFaultModes(FaultMode faultMode) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		
		LocalDynamics localDynamics = faultMode.getLocalDynamics();
		Effect effect = faultMode.getEffect();
		boolean containsSelfFix = ecoreUtil.containsTypeTransitively(effect, SelfFixTemplate.class);
		if (localDynamics == LocalDynamics.TRANSIENT && !containsSelfFix) {
			validationResultMessages.add(new ValidationResultMessage(
				ValidationResult.ERROR,
					"If the local dynamics is set to 'transient', then the self-fix template must be instantiated",
						new ReferenceInfo(FeiModelPackage.Literals.FAULT_MODE__LOCAL_DYNAMICS)));
		}
		else if (localDynamics == LocalDynamics.PERMANENT && containsSelfFix) {
			validationResultMessages.add(new ValidationResultMessage(
					ValidationResult.ERROR,
						"If the local dynamics is set to 'permanent', then the self-fix template must not be instantiated",
							new ReferenceInfo(FeiModelPackage.Literals.FAULT_MODE__LOCAL_DYNAMICS)));
			}
	
		return validationResultMessages;
	}
			
	
}
