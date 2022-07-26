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
package hu.bme.mit.gamma.property.language.validation

import hu.bme.mit.gamma.property.util.PropertyModelValidator
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import org.eclipse.xtext.validation.Check

class PropertyLanguageValidator extends AbstractPropertyLanguageValidator {
	
	protected final PropertyModelValidator validator = PropertyModelValidator.INSTANCE
	
	new() {
		super.expressionModelValidator = validator
		super.actionModelValidator = validator
		super.statechartModelValidator = validator
	}
	
	@Check
	override checkComponentInstanceReferences(ComponentInstanceReferenceExpression reference) {
		handleValidationResultMessage(validator.checkComponentInstanceReferences(reference))
	}
	
}