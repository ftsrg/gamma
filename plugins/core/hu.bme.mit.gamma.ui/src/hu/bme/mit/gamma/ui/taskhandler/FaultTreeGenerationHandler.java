/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.ui.taskhandler;

import org.eclipse.core.resources.IFile;

public class FaultTreeGenerationHandler extends SafetyAssessmentHandler {
	
	public FaultTreeGenerationHandler(IFile file) {
		super(file);
	}
	
	@Override
	String getCommand() {
//		return "go_msat" + System.lineSeparator() +
//				"compute_fault_tree_msat_bmc"; // And this line is extended by super
		return "go_msat" + System.lineSeparator() +
				"compute_fault_tree_param";
	}

	@Override
	String getCommandFileNamePrefix() {
		return "generate_ft";
	}
	
}
