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
package hu.bme.mit.gamma.querygenerator.controller;

import java.io.IOException;

import org.eclipse.core.resources.IFile;

import hu.bme.mit.gamma.querygenerator.ThetaQueryGenerator;
import hu.bme.mit.gamma.querygenerator.application.View;
import hu.bme.mit.gamma.theta.verification.ThetaVerifier;
import hu.bme.mit.gamma.verification.util.AbstractVerifier;

public class ThetaController extends AbstractController {

	public ThetaController(View view, IFile file) throws IOException {
		this.file = file;
		this.view = view;
		this.queryGenerator = new ThetaQueryGenerator(); // For state-location
	}
	
	@Override
	public void verify(String query) {
	}

	@Override
	public void executeGeneratedQueries() {
	}

	@Override
	public String getParameters() {
		return "";
	}

	@Override
	public String getModelFile() {
		return getLocation(file).substring(0, getLocation(file).lastIndexOf(".")) + ".xsts";
	}

	@Override
	public String getGeneratedQueryFile() {
		return null;
	}

	@Override
	public Object getTraceability() {
		return null;
	}

	@Override
	public AbstractVerifier createVerifier() {
		return new ThetaVerifier();
	}

}
