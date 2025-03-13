/********************************************************************************
 * Copyright (c) 2019-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.ui.taskhandler;

import java.io.IOException;

import org.eclipse.core.resources.IFile;

import hu.bme.mit.gamma.genmodel.model.StatechartCompilation;

public class StatechartCompilationHandler extends YakinduCompilationHandler {

	public StatechartCompilationHandler(IFile file) {
		super(file);
	}
	
	public void execute(StatechartCompilation statechartCompilation) throws IOException {
		// Setting target folder
		setTargetFolder(statechartCompilation);
		//
		setYakinduCompilation(statechartCompilation);
//		setStatechartCompilation(statechartCompilation, statechartCompilation.getStatechart().getName());
//		ModelValidator validator = new ModelValidator(statechartCompilation.getStatechart());
//		validator.checkModel();
//		YakinduToGammaTransformer transformer = new YakinduToGammaTransformer(statechartCompilation);
//		SimpleEntry<Package, Y2GTrace> resultModels = transformer.execute();
//		// Saving Xtext and EMF models
//		serializer.saveModel(resultModels.getKey(), targetFolderUri, statechartCompilation.getFileName().get(0) + ".gcd");
//		serializer.saveModel(resultModels.getValue(), targetFolderUri, "." + statechartCompilation.getFileName().get(0) + ".y2g");
//		transformer.dispose();
	}

//	private void setStatechartCompilation(StatechartCompilation statechartCompilation, String statechartName) {
//		List<String> statechartNames = statechartCompilation.getStatechartName();
//		checkArgument(statechartNames.size() <= 1);
//		if (statechartNames.isEmpty()) {
//			statechartNames.add(statechartName);
//		}
//	}

}
