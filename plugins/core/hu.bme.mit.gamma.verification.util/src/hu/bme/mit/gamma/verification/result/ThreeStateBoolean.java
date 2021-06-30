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
package hu.bme.mit.gamma.verification.result;

public enum ThreeStateBoolean {
	UNDEF, FALSE, TRUE;
	
	public ThreeStateBoolean opposite() {
		switch (this) {
			case FALSE:
				return TRUE;
			case TRUE:
				return FALSE;
			default:
				return UNDEF;
		}		
	}
	
}