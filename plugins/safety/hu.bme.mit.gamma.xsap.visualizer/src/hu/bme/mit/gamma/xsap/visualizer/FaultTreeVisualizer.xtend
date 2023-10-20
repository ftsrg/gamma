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
package hu.bme.mit.gamma.xsap.visualizer

import java.util.logging.Level
import java.util.logging.Logger
//import org.eclipse.core.runtime.NullProgressMonitor
//import eu.fbk.eclipse.standardtools.faultTreeViewer.utils.FaultTreeViewerUtil

class FaultTreeVisualizer {
	// Singleton
	public static FaultTreeVisualizer INSTANCE = new FaultTreeVisualizer
	protected new() {}
	//
	
	protected final Logger logger = Logger.getLogger("GammaLogger");
	
	def void visualizeFaultTree(String xmlFilePath) {
//		val faultTreeViewer = FaultTreeViewerUtil.instance
		try {
//			faultTreeViewer.openXmlIFileInFTAViewer(xmlFilePath, new NullProgressMonitor)
			logger.log(Level.INFO, "Visualized fault tree at " + xmlFilePath)
		} catch (Exception e) {
			e.printStackTrace()
			logger.log(Level.SEVERE, "Cannot visualize fault tree at " + xmlFilePath)
		}
	}
	
}