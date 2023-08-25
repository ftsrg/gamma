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
package hu.bme.mit.gamma.xsts.transformation.serializer

import hu.bme.mit.gamma.expression.model.NamedElement

import static com.google.common.base.Preconditions.checkArgument

class SerializationValidator {
	// Singleton
	public static final SerializationValidator INSTANCE = new SerializationValidator
	protected new() {}
	//
	
	public static val KEYWORDS = #[ 'type', 'ctrl', 'var', 'integer', 'boolean', 'true', 'false', 'if', 'else',
		'par', 'and', 'for', 'from', 'to', 'do', 'choice', 'or', 'local', 'assume', 'havoc',
		'trans', 'init', 'env', 'then', 'default' ]
	
	def validateIdentifier(NamedElement element) {
		val name = element.name
		checkArgument(!KEYWORDS.contains(name), "The identifier of an element must not be an XSTS keyword: " + name)
	}
	
}