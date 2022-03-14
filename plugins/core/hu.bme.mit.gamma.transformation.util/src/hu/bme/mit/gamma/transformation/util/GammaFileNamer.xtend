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
package hu.bme.mit.gamma.transformation.util

import hu.bme.mit.gamma.util.FileUtil
import java.io.File

class GammaFileNamer {
	// Singleton
	public static final GammaFileNamer INSTANCE =  new GammaFileNamer
	protected new() {}
	//
	
	protected final extension FileUtil fileUtil = FileUtil.INSTANCE
	//
	public static final String EXECUTION_TRACE_FILE_NAME = "ExecutionTrace";
	//
	public static final String PACKAGE_EMF_EXTENSION = "gsm";
	public static final String PACKAGE_XTEXT_EXTENSION = "gcd";
	
	public static final String PROPERTY_XTEXT_EXTENSION = "gpd";
	public static final String PROPERTY_EMF_EXTENSION = "gpm";
	public static final String PROPERTY_SERIALIZED_EXTENSION = "pd"; // Both UPPAAL and Theta
	
	public static final String EXECUTION_XTEXT_EXTENSION = "get";
	public static final String EXECUTION_EMF_EXTENSION = "gtr";
	
	public static final String VERIFICATION_RESULT_EXTENSION = "json";
	
	public static final String XSTS_EMF_EXTENSION = "gsts";
	public static final String XSTS_XTEXT_EXTENSION = "xsts";
	
	public static final String GAMMA_UPPAAL_TRACEABILITY_EXTENSION = "g2u";
	
	public static final String UPPAAL_EMF_EXTENSION = "uppaal";
	public static final String UPPAAL_MODEL_EXTENSION = "xml";
	
	public static final String UPPAAL_QUERY_EXTENSION = "q";
	public static final String THETA_QUERY_EXTENSION = "prop";
	//
	
	def String getPackageFileName(String fileName) '''«fileName.extensionlessName».«PACKAGE_XTEXT_EXTENSION»'''
	
	def String getUnfoldedPackageFileName(String fileName) '''«fileName.extensionlessName.toHiddenFileName».«PACKAGE_EMF_EXTENSION»'''
	
	def String getEmfUppaalFileName(String fileName) '''«fileName.extensionlessName.toHiddenFileName».«UPPAAL_EMF_EXTENSION»'''
	
	def String getGammaUppaalTraceabilityFileName(String fileName) '''«fileName.extensionlessName.toHiddenFileName».«GAMMA_UPPAAL_TRACEABILITY_EXTENSION»'''
	
	def String getExecutionTraceFileName(String fileName) '''«fileName.extensionlessName».«EXECUTION_XTEXT_EXTENSION»'''
	
	def String getPropertyFileName(String fileName) '''«fileName.extensionlessName».«PROPERTY_XTEXT_EXTENSION»'''
	
	def String getHiddenPropertyFileName(String fileName) '''«fileName.extensionlessName.toHiddenFileName».«PROPERTY_XTEXT_EXTENSION»'''
	
	def String getHiddenEmfPropertyFileName(String fileName) '''«fileName.extensionlessName.toHiddenFileName».«PROPERTY_EMF_EXTENSION»'''
	
	def String getHiddenSerializedPropertyFileName(String fileName) '''«fileName.extensionlessName.toHiddenFileName».«PROPERTY_SERIALIZED_EXTENSION»'''
	
	def String getXmlUppaalFileName(String fileName) '''«fileName.extensionlessName».«UPPAAL_MODEL_EXTENSION»'''
	
	def String getUppaalQueryFileName(String fileName) '''«fileName.extensionlessName».«UPPAAL_QUERY_EXTENSION»'''
	
	def String getXtextXStsFileName(String fileName) '''«fileName.extensionlessName».«XSTS_XTEXT_EXTENSION»'''
	
	def String getEmfXStsFileName(String fileName) '''«fileName.extensionlessName».«XSTS_EMF_EXTENSION»'''
	
	//
	
	def String getOriginalGcdComponentUri(String unfoldedComponentUri) '''«unfoldedComponentUri.parent»«File.separator»«unfoldedComponentUri.fileName.toUnhiddenFileName.packageFileName»'''
	def String getOriginalGsmComponentUri(String unfoldedComponentUri) '''«unfoldedComponentUri.parent»«File.separator»«unfoldedComponentUri.fileName.toUnhiddenFileName»'''
	
}