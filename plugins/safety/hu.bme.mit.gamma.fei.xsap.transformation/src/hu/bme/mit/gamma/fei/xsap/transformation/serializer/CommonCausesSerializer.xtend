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
package hu.bme.mit.gamma.fei.xsap.transformation.serializer

import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.fei.model.CommonCause
import hu.bme.mit.gamma.fei.model.CommonCauseMode
import hu.bme.mit.gamma.fei.model.CommonCauseProbability
import hu.bme.mit.gamma.fei.model.CommonCauseRange
import hu.bme.mit.gamma.fei.model.CommonCauses

class CommonCausesSerializer {
	// Singleton
	public static CommonCausesSerializer INSTANCE = new CommonCausesSerializer
	protected new() {}
	//
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	//
	
	def serializeCommonCauses(CommonCauses commonCauses) '''
		«IF commonCauses !== null»
			COMMON CAUSES
				«FOR cause : commonCauses.commonCauses»
					«cause.serializeCommonCause»
				«ENDFOR»
		«ENDIF»
	'''
	
	//
	
	protected def serializeCommonCause(CommonCause commonCause) '''
		CAUSE «commonCause.name» «commonCause.probability.serializeCommonCauseProbability»
			MODULE main
				«FOR mode : commonCause.modes»
					«mode.serializeCommonCauseMode»
				«ENDFOR»
	'''
	
	protected def serializeCommonCauseProbability(CommonCauseProbability probability) '''
		«IF probability !== null»{«probability.value.evaluateDecimal»}«ENDIF»
	'''
	
	protected def serializeCommonCauseMode(CommonCauseMode mode) '''
		MODE «mode.faultSlice.name».«mode.faultMode.name» «mode.range.serializeCommonCauseRange»;
	'''
	
	protected def serializeCommonCauseRange(CommonCauseRange range) '''
		WITHIN «IF range === null || range.lowerBound === null && range.higherBound === null»0 .. 0
		«ELSE»
			«IF range.lowerBound !== null»«range.lowerBound.evaluateInteger»«ELSE»0«ENDIF» .. «
				IF range.higherBound !== null»«range.higherBound.evaluateInteger»«
				ELSE»«range.lowerBound.evaluateInteger»«ENDIF»
		«ENDIF»
	'''
	
}