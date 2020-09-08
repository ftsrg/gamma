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
package hu.bme.mit.gamma.headless.application.uppaal;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.uppaal.composition.transformation.api.util.DefaultCompositionToUppaalTransformer.Result;
import hu.bme.mit.gamma.uppaal.transformation.traceability.G2UTrace;
import hu.bme.mit.gamma.uppaal.verification.UppaalVerifier;
import hu.bme.mit.gamma.uppaal.verification.settings.UppaalSettings;
import hu.bme.mit.gamma.uppaal.verification.settings.UppaalSettingsSerializer;
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean;

public class UppaalQueryRunner {

	private final Result uppaalTransformationResult;

	private ExecutionTrace uppaalTrace;

	public UppaalQueryRunner(Result uppaalTransformationResult, String ctlExpression) throws IOException {
		this.uppaalTransformationResult = uppaalTransformationResult;
		replaceQueryFileContent(uppaalTransformationResult, ctlExpression);
	}

	public ThreeStateBoolean verify() {
		String cliParamters = new UppaalSettingsSerializer().serialize(UppaalSettings.DEFAULT_SETTINGS);
		G2UTrace trace = uppaalTransformationResult.getTrace();
		File uppaalFile = uppaalTransformationResult.getModelFile();
		File uppaalQueryFile = uppaalTransformationResult.getQueryFile();

		UppaalVerifier verifier = new UppaalVerifier();
		uppaalTrace = verifier.verifyQuery(trace, cliParamters, uppaalFile, uppaalQueryFile, false, false);
		return verifier.getResult();
	}

	public ExecutionTrace getUppaalTrace() {
		return uppaalTrace;
	}

	private void replaceQueryFileContent(Result uppaalTransformationResult, String ctlExpression) throws IOException {
		File queryFile = uppaalTransformationResult.getQueryFile();
		try (FileWriter fileWriter = new FileWriter(queryFile, false)) {
			fileWriter.write(ctlExpression);
		}
	}

}
