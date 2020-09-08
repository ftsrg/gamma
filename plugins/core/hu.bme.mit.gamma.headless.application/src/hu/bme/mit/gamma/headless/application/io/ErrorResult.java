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
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;
import java.util.stream.Stream;

public class ErrorResult implements Serializable {

	private static final long serialVersionUID = -6907091095985135923L;

	private String message;
	private List<String> stackTrace;

	public ErrorResult(String message) {
		this.message = message;
	}

	public ErrorResult(String message, StackTraceElement[] stackTrace) {
		this(message);
		this.stackTrace = mapMessages(stackTrace);
	}

	private List<String> mapMessages(StackTraceElement[] stackTrace) {
		if (stackTrace != null) {
			return Stream.of(stackTrace).map(Object::toString).collect(Collectors.toList());
		}
		return null;
	}

	public String getMessage() {
		return message;
	}

	public List<String> getStackTrace() {
		return stackTrace;
	}

	@Override
	public int hashCode() {
		return Objects.hash(message, stackTrace);
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj) {
			return true;
		}
		if (!(obj instanceof ErrorResult)) {
			return false;
		}
		ErrorResult other = (ErrorResult) obj;
		return Objects.equals(message, other.message) && Objects.equals(stackTrace, other.stackTrace);
	}

}
