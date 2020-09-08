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
package hu.bme.mit.gamma.headless.application.io;

import java.io.Serializable;
import java.util.Objects;

public class VerificationRequest implements Serializable {

	private static final long serialVersionUID = -5932720107244938443L;

	private String models;

	private String expression;

	public VerificationRequest(String models, String expression) {
		this.models = models;
		this.expression = expression;
	}

	public String getModels() {
		return models;
	}

	public String getExpression() {
		return expression;
	}

	@Override
	public int hashCode() {
		return Objects.hash(expression, models);
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj) {
			return true;
		}
		if (!(obj instanceof VerificationRequest)) {
			return false;
		}
		VerificationRequest other = (VerificationRequest) obj;
		return Objects.equals(expression, other.expression) && Objects.equals(models, other.models);
	}

}
