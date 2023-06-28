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
package hu.bme.mit.gamma.statechart.language.ui.wizard;

import org.eclipse.osgi.util.NLS;

public class Messages extends NLS {
	private static final String BUNDLE_NAME = "hu.bme.mit.gamma.statechart.language.ui.wizard.messages"; //$NON-NLS-1$
	
	public static String HelloWorldProject_Label;
	public static String HelloWorldProject_Description;
	public static String GenericStochasticGammaProject_Label;
	public static String GenericStochasticGammaProject_Description;
	public static String IoTStochasticGammaProject_Label;
	public static String IoTStochasticGammaProject_Description;
	public static String CrossroadGammaProject_Label;
	public static String CrossroadGammaProject_Description;
	
	static {
	// initialize resource bundle
	NLS.initializeMessages(BUNDLE_NAME, Messages.class);
	}
	
	private Messages() {
	}
}
