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
package hu.bme.mit.gamma.querygenerator.operators;

public enum TemporalOperator {
	MIGHT_ALWAYS, MUST_ALWAYS, MIGHT_EVENTUALLY, MUST_EVENTUALLY, LEADS_TO;
	
	public String getOperator() {
		switch (this) {
			case MIGHT_ALWAYS:
				return "E[]";
			case MUST_ALWAYS:
				return "A[]";
			case MIGHT_EVENTUALLY:
				return "E<>";
			case MUST_EVENTUALLY:
				return "A<>";
			case LEADS_TO:
				return "-->";
		}
		throw new IllegalArgumentException("Not known operator: " + this);
	}
}