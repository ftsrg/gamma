/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.expression.model.Comment
import hu.bme.mit.gamma.property.model.CommentableStateFormula
import hu.bme.mit.gamma.property.model.StateFormula
import hu.bme.mit.gamma.property.util.PropertyUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.util.JavaUtil
import java.util.Collection
import java.util.logging.Logger

abstract class PropertySerializer {
	//
	protected extension PropertyExpressionSerializer serializer
	//
	protected final extension PropertyUtil util = PropertyUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension JavaUtil javaUtil = JavaUtil.INSTANCE
	protected final Logger logger = Logger.getLogger("GammaLogger")
	//
	new(PropertyExpressionSerializer serializer) {
		this.serializer = serializer
	}
	
	abstract def String serialize(StateFormula formula)
	abstract def String serialize(Comment comment)
	
	def String serialize(CommentableStateFormula formula) '''
		«FOR comment : formula.comments SEPARATOR System.lineSeparator»«comment.serialize»«ENDFOR»
		«formula.formula.serialize»
	'''
	
	def String serializeCommentableStateFormulas(Collection<CommentableStateFormula> formulas) '''
		«FOR formula : formulas»
			«formula.serialize»
		«ENDFOR»
	'''
	
	def String serializeStateFormulas(Collection<StateFormula> formulas) '''
		«FOR formula : formulas»
			«formula.serialize»
		«ENDFOR»
	'''
	
	//
	
	def getPropertyExpressionSerializer() {
		return this.serializer
	}
	
}