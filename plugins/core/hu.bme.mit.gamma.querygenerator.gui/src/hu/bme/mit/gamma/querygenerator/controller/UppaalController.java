/********************************************************************************
 * Copyright (c) 2018 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.querygenerator.controller;

import java.io.File;

import org.eclipse.core.resources.IFile;
import org.eclipse.emf.common.util.URI;

import hu.bme.mit.gamma.querygenerator.UppaalQueryGenerator;
import hu.bme.mit.gamma.querygenerator.application.View;
import hu.bme.mit.gamma.uppaal.transformation.traceability.G2UTrace;
import hu.bme.mit.gamma.uppaal.verification.UppaalVerifier;
import hu.bme.mit.gamma.uppaal.verification.settings.UppaalSettings;
import hu.bme.mit.gamma.uppaal.verification.settings.UppaalSettingsSerializer;
import hu.bme.mit.gamma.verification.util.AbstractVerifier;

public class UppaalController extends AbstractController {

	public UppaalController(View view, IFile file) {
		this.file = file;
		this.view = view;
		this.queryGenerator = new UppaalQueryGenerator((G2UTrace) getTraceability()); // For state-location
	}

	private String getTraceabilityFile() {
		return getParentFolder() + File.separator + "." + getCompositeSystemName() + ".g2u";
	}

	@Override
	public String getGeneratedQueryFile() {
		return getParentFolder() + File.separator + getCompositeSystemName() + ".q";
	}

	@Override
	public String getModelFile() {
		return getLocation(file).substring(0, getLocation(file).lastIndexOf(".")) + ".xml";
	}

	@Override
	public Object getTraceability() {
		URI fileURI = URI.createFileURI(getTraceabilityFile());
		return ecoreUtil.normalLoad(fileURI);
	}

	@Override
	public AbstractVerifier createVerifier() {
		return new UppaalVerifier();
	}

	@Override
	public String getParameters() {
		UppaalSettings.Builder builder = new UppaalSettings.Builder();
		builder.searchOrder(view.getSelectedSearchOrder());
		builder.stateSpaceRepresentation(view.getStateSpaceRepresentation());
		builder.trace(view.getSelectedTrace());
		builder.hashtableSize(view.getHashTableSize());
		builder.stateSpaceReduction(view.getStateSpaceReduction());
		builder.reuseStateSpace(view.isReuseStateSpace());
		UppaalSettings settings = builder.build();

		UppaalSettingsSerializer serializer = new UppaalSettingsSerializer();
		return serializer.serialize(settings);
	}

}