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

public class VerificationResponse implements Serializable {

	private static final long serialVersionUID = 4226795449871990727L;

	private VerificationResult verificationResult;

	private ErrorResult error;

	public VerificationResponse(VerificationResult result) {
		this.verificationResult = result;
	}

	public VerificationResponse(ErrorResult result) {
		this.error = result;
	}

	public VerificationResult getVerificationResult() {
		return verificationResult;
	}

	public ErrorResult getError() {
		return error;
	}

	@Override
	public int hashCode() {
		return Objects.hash(error, verificationResult);
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj) {
			return true;
		}
		if (!(obj instanceof VerificationResponse)) {
			return false;
		}
		VerificationResponse other = (VerificationResponse) obj;
		return Objects.equals(error, other.error) && Objects.equals(verificationResult, other.verificationResult);
	}

}
