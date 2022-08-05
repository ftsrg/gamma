/********************************************************************************
 * Copyright (c) 2018-2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.activity.util;

import hu.bme.mit.gamma.action.util.ActionUtil;
import hu.bme.mit.gamma.activity.model.ActivityModelFactory;

public class ActivityUtil extends ActionUtil {
	// Singleton
	public static final ActivityUtil INSTANCE = new ActivityUtil();
	protected ActivityUtil() {}
	//
	
	protected ActivityModelFactory activityFactory = ActivityModelFactory.eINSTANCE;
	
}
