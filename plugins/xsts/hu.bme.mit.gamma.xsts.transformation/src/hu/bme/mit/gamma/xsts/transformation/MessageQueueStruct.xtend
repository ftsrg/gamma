/********************************************************************************
 * Copyright (c) 2018-2021 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.transformation

import hu.bme.mit.gamma.expression.model.VariableDeclaration
import org.eclipse.xtend.lib.annotations.Data

@Data
class MessageQueueStruct {
	
	VariableDeclaration arrayVariable // Integer array
	VariableDeclaration sizeVariable // Integer
	
	boolean isInternal // Denoting the queue of an internal parameter
	
}