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
package hu.bme.mit.gamma.statechart.lowlevel.util;

import hu.bme.mit.gamma.action.util.ActionUtil;
import hu.bme.mit.gamma.statechart.lowlevel.model.Component;
import hu.bme.mit.gamma.statechart.lowlevel.model.ComponentAnnotation;
import hu.bme.mit.gamma.statechart.lowlevel.model.StatechartModelFactory;

public class LowlevelStatechartUtil extends ActionUtil {
	
	// Singleton
	public static final LowlevelStatechartUtil INSTANCE = new LowlevelStatechartUtil();
	protected LowlevelStatechartUtil() {}
	//

	protected StatechartModelFactory statechartFactory = StatechartModelFactory.eINSTANCE;

	// Statechart annotations
	
	protected void addAnnotation(Component component, ComponentAnnotation annotation) {
		component.getAnnotations().add(annotation);
	}
	
	public void addRunUponExternalEventAnnotation(Component component) {
		addAnnotation(component, statechartFactory.createRunUponExternalEventAnnotation());
	}
	
	public void addRunUponExternalEventOrInternalTimeoutAnnotation(Component component) {
		addAnnotation(component, statechartFactory.createRunUponExternalEventOrInternalTimeoutAnnotation());
	}
	
}
