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

public class VerificationResult implements Serializable {

	private static final long serialVersionUID = -7123216859095325985L;

	private PropertyHoldsEnum propertyHolds;
	private String models;
	private String visualization;

	public VerificationResult(PropertyHoldsEnum propertyHolds, String models, String visualization) {
		this.propertyHolds = propertyHolds;
		this.models = models;
		this.visualization = visualization;
	}

	public PropertyHoldsEnum getPropertyHolds() {
		return propertyHolds;
	}

	public String getCounterExample() {
		return models;
	}

	public String getVisualization() {
		return visualization;
	}

	@Override
	public int hashCode() {
		return Objects.hash(models, propertyHolds, visualization);
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj) {
			return true;
		}
		if (!(obj instanceof VerificationResult)) {
			return false;
		}
		VerificationResult other = (VerificationResult) obj;
		return Objects.equals(models, other.models) && propertyHolds == other.propertyHolds
				&& Objects.equals(visualization, other.visualization);
	}

}
