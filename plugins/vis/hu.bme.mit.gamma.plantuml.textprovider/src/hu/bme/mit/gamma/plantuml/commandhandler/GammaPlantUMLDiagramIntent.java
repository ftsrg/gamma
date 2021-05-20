/********************************************************************************
 * Copyright (c) 2018-2021 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.plantuml.commandhandler;

import net.sourceforge.plantuml.util.AbstractDiagramIntent;

public class GammaPlantUMLDiagramIntent extends AbstractDiagramIntent<String> {

	protected String plantUMLDiagramText;
	
	public GammaPlantUMLDiagramIntent(String source) {
		super(source);
		plantUMLDiagramText = source;
	}
	
	@Override
	public String getDiagramText() {
		return plantUMLDiagramText;
	}
	
}
