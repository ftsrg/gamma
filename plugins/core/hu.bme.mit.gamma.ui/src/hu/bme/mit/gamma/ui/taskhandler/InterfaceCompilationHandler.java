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

import hu.bme.mit.gamma.genmodel.model.InterfaceCompilation;

public class InterfaceCompilationHandler extends YakinduCompilationHandler {

	public InterfaceCompilationHandler(IFile file) {
		super(file);
	}
	
	public void execute(InterfaceCompilation interfaceCompilation) throws IOException {
		// Setting target folder
		setTargetFolder(interfaceCompilation);
		//
//		setYakinduCompilation(interfaceCompilation);
//		InterfaceTransformer transformer = new InterfaceTransformer(
//				interfaceCompilation.getStatechart(), interfaceCompilation.getPackageName().get(0));
//		SimpleEntry<Package, Y2GTrace> resultModels = transformer.execute();
//		serializer.saveModel(resultModels.getKey(), targetFolderUri, interfaceCompilation.getFileName().get(0) + ".gcd");
//		serializer.saveModel(resultModels.getValue(), targetFolderUri, "." + interfaceCompilation.getFileName().get(0)  + ".y2g");
	}

}
