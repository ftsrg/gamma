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

import org.apache.log4j.LogManager;
import org.apache.log4j.Logger;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;

import hu.bme.mit.gamma.headless.application.util.ModelPersistenceUtil;
import hu.bme.mit.gamma.headless.application.util.gamma.PropertySpecificationSerializationUtil;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean;

public class ModelWithCtlMode implements IExecutionMode {

	private static final Logger LOGGER = LogManager.getLogger(ModelWithCtlMode.class);

	private String fileUri;
	private String propertySpecificationFileUri;

	private Resource statechartModelsResource;
	private PropertySpecification propertySpecification;

	private ThreeStateBoolean verificationResult;
	private List<EObject> resultModels;
	private String visualization;

	public ModelWithCtlMode(String fileUri, String propertySpecificationFileUri) {
		this.fileUri = fileUri;
		this.propertySpecificationFileUri = propertySpecificationFileUri;
	}

	private void load() {
		if (statechartModelsResource == null && propertySpecification == null) {
			ResourceSet resourceSet = new ResourceSetImpl();

			URI modelsUri = URI.createURI(fileUri);
			this.statechartModelsResource = resourceSet.getResource(modelsUri, true);

			URI propertySpecificationUri = URI.createURI(propertySpecificationFileUri);
			Resource propertySpecResource = resourceSet.getResource(propertySpecificationUri, true);
			this.propertySpecification = (PropertySpecification) propertySpecResource.getContents().get(0);

			// do not remove this call, otherwise model will not be loaded
			PropertySpecificationSerializationUtil.serialize(propertySpecification);
		}
	}

	@Override
	public Package getWrappedGammaStatechart() {
		load();
		return getPackage(0);
	}

	@Override
	public Package getNormalGammaStatechart() {
		load();
		return getPackage(1);
	}

	@Override
	public PropertySpecification getPropertySpecification() {
		load();
		return propertySpecification;
	}

	@Override
	public void setVerificationResult(ThreeStateBoolean result, List<EObject> models, String visualization) {
		this.verificationResult = result;
		this.resultModels = models;
		this.visualization = visualization;
	}

	@Override
	public void handleError(Exception ex) {
		// Warning: do not change LOGGER.error, because client reads the standard error
		LOGGER.error(ex.getMessage(), ex);
	}

	@Override
	public void finish() {
		String svg = null;
		String modelUri = null;

		URI resultModelUri = ModelPersistenceUtil.saveInOneResource("gammatrace", resultModels);
		if (resultModelUri != null) {
			modelUri = String.format("ModelUri:%s", resultModelUri);
			svg = String.format("TraceVisualization:%s", visualization);
		}
		// Warning: do not change LOGGER.info, because client reads the standard output
		LOGGER.info(String.format("Result:%s;%s;%s", verificationResult, modelUri, svg));
	}

	private Package getPackage(int index) {
		return (Package) statechartModelsResource.getContents().get(index);
	}

}
