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
package hu.bme.mit.gamma.headless.application;

import java.io.IOException;
import java.util.List;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean;

public interface IVerification {

	ThreeStateBoolean verify() throws IOException;

	List<EObject> getResultModels();

	ExecutionTrace getTrace();

}
