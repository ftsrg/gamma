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
package hu.bme.mit.gamma.trace.language.validation

import hu.bme.mit.gamma.expression.model.ArgumentedElement
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression
import hu.bme.mit.gamma.trace.model.AssignmentAct
import hu.bme.mit.gamma.trace.model.ComponentSchedule
import hu.bme.mit.gamma.trace.model.InstanceSchedule
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.util.TraceModelValidator
import org.eclipse.xtext.validation.Check

/**
 * This class contains custom validation rules. 
 *
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
class TraceLanguageValidator extends AbstractTraceLanguageValidator {
	
	protected final TraceModelValidator traceModelValidator = TraceModelValidator.INSTANCE
	
	new() {
		super.expressionModelValidator = traceModelValidator
	}
	
	@Check
	def checkArgumentTypes(ArgumentedElement element) {
		handleValidationResultMessage(traceModelValidator.checkArgumentTypes(element))
	}
	
	@Check
	def checkRaiseEventAct(RaiseEventAct raiseEventAct) {
		handleValidationResultMessage(traceModelValidator.checkRaiseEventAct(raiseEventAct))
	}
	
	@Check
	def checkInstanceState(ComponentInstanceReferenceExpression instanceState) {
		handleValidationResultMessage(traceModelValidator.checkInstanceState(instanceState))
	}
	
	@Check
	def checkInstanceStateConfiguration(ComponentInstanceStateReferenceExpression configuration) {
		handleValidationResultMessage(traceModelValidator.checkInstanceStateConfiguration(configuration))
	}
	
	@Check
	def checkInstanceVariableState(ComponentInstanceVariableReferenceExpression variableState) {
		handleValidationResultMessage(traceModelValidator.checkInstanceVariableState(variableState))
	}
	
	@Check
	def checkInstanceSchedule(InstanceSchedule schedule) {
		handleValidationResultMessage(traceModelValidator.checkInstanceSchedule(schedule))
	}
	
	@Check
	def checkInstanceSchedule(ComponentSchedule schedule) {
		handleValidationResultMessage(traceModelValidator.checkInstanceSchedule(schedule))
	}
	
	@Check
	def checkComponentInstanceReferences(ComponentInstanceReferenceExpression reference) {
		handleValidationResultMessage(traceModelValidator.checkComponentInstanceReferences(reference))
	}
	
	@Check
	def checkComponentInstanceReferences(AssignmentAct act) {
		handleValidationResultMessage(traceModelValidator.checkAssignmentAct(act))
	}
	
}