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
package hu.bme.mit.gamma.headless.application.modes;

import java.util.List;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean;

public interface IExecutionMode {

	String SERIALIZED_REQUEST_MODE = "serializedRequest";
	String MODEL_WITH_CTL_MODE = "modelWithCtl";

	Package getWrappedGammaStatechart();

	Package getNormalGammaStatechart();

	PropertySpecification getPropertySpecification();

	void setVerificationResult(ThreeStateBoolean result, List<EObject> models, String visualization);

	void handleError(Exception ex);

	void finish();
}
