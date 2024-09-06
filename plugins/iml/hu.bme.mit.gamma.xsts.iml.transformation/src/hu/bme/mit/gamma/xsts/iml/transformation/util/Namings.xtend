/********************************************************************************
 * Copyright (c) 2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.iml.transformation.util

import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.xsts.model.HavocAction
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.util.XstsActionUtil

class Namings {
	//
	protected static final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	//
	
	public static final String GLOBAL_RECORD_TYPE_NAME = "t"
	public static final String GLOBAL_RECORD_IDENTIFIER = "r"
	
	public static final String LOCAL_RECORD_TYPE_NAME = "l"
	public static final String LOCAL_RECORD_IDENTIFIER = "l" // Single one as the different ones are not used together
	
	public static final String INIT_LOCAL_RECORD_TYPE_NAME = "il"
	
	public static final String ENV_LOCAL_RECORD_TYPE_NAME = "el"
	
	public static final String ENV_HAVOC_RECORD_TYPE_NAME = "e"
	public static final String ENV_HAVOC_RECORD_IDENTIFIER = "e"
	
	//
	
	public static final String DECLARATION_NAME_PREFIX = "_"
	def static customizeName(Declaration variable) { variable.name.customizeDeclarationName }
	def static customizeDeclarationName(String name) { DECLARATION_NAME_PREFIX + name }
	
	public static final String ENUM_LITERAL_PREFIX = "L_"
	def static customizeName(EnumerationLiteralExpression literal) { literal.reference.customizeName }
	def static customizeName(EnumerationLiteralDefinition literal) { literal.name.customizeEnumLiteralName }
	def static customizeEnumLiteralName(String name) { ENUM_LITERAL_PREFIX + name }
	
	def static customizeHavocField(HavocAction havoc) '''«havoc.lhs.declaration.customizeName»_«havoc.hashCode.toString.replaceAll("-", "_")»'''
	
	def static customizeChoice(NonDeterministicAction choice) '''choice_«choice.hashCode.toString.replaceAll("-", "_")»'''
}