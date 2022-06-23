/********************************************************************************
 * Copyright (c) 2019-2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.ui.taskhandler;

import static com.google.common.base.Preconditions.checkArgument;

import org.eclipse.core.resources.IFile;

import hu.bme.mit.gamma.genmodel.model.YakinduCompilation;

public abstract class YakinduCompilationHandler extends TaskHandler {
	
	public YakinduCompilationHandler(IFile file) {
		super(file);
	}
	
	protected void setYakinduCompilation(YakinduCompilation yakinduCompilation) {
		String fileName = getNameWithoutExtension(
				getContainingFileName(
						yakinduCompilation.getStatechart()));
		checkArgument(yakinduCompilation.getFileName().size() <= 1);
		checkArgument(yakinduCompilation.getPackageName().size() <= 1);
		if (yakinduCompilation.getFileName().isEmpty()) {
			yakinduCompilation.getFileName().add(fileName);
		}
		if (yakinduCompilation.getPackageName().isEmpty()) {
			yakinduCompilation.getPackageName().add(
					yakinduCompilation.getStatechart().getName().toLowerCase());
		}
	}
	
}
