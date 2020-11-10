package hu.bme.mit.gamma.transformation.util

import hu.bme.mit.gamma.util.FileUtil

class GammaFileNamer {
	// Singleton
	public static final GammaFileNamer INSTANCE =  new GammaFileNamer
	protected new() {}
	//
	
	protected final extension FileUtil fileUtil = FileUtil.INSTANCE
	
	public static final String PACKAGE_EMF_EXTENSION = "gsm";
	public static final String PACKAGE_XTEXT_EXTENSION = "gcd";
	
	public static final String PROPERTY_XTEXT_EXTENSION = "gpd";
	public static final String PROPERTY_EMF_EXTENSION = "gpm";
	
	public static final String EXECUTION_XTEXT_EXTENSION = "get";
	
	public static final String XSTS_EMF_EXTENSION = "gsts";
	public static final String XSTS_XTEXT_EXTENSION = "xsts";
	
	public static final String GAMMA_UPPAAL_TRACEABILITY_EXTENSION = "g2u";
	
	public static final String UPPAAL_EMF_EXTENSION = "uppaal";
	public static final String UPPAAL_MODEL_EXTENSION = "xml";
	
	public static final String UPPAAL_QUERY_EXTENSION = "q";
	public static final String THETA_QUERY_EXTENSION = "prop";
	
	def String getPackageFileName(String extensionlessName) '''«extensionlessName».«PACKAGE_XTEXT_EXTENSION»'''
	
	def String getUnfoldedPackageFileName(String extensionlessName) '''«extensionlessName.toHiddenFileName».«PACKAGE_EMF_EXTENSION»'''
	
	def String getEmfUppaalFileName(String extensionlessName) '''«extensionlessName.toHiddenFileName».«UPPAAL_EMF_EXTENSION»'''
	
	def String getGammaUppaalTraceabilityFileName(String extensionlessName) '''«extensionlessName.toHiddenFileName».«GAMMA_UPPAAL_TRACEABILITY_EXTENSION»'''
	
	def String getPropertyFileName(String extensionlessName) '''«extensionlessName».«PROPERTY_XTEXT_EXTENSION»'''
	
	def String getHiddenPropertyFileName(String extensionlessName) '''«extensionlessName.toHiddenFileName».«PROPERTY_XTEXT_EXTENSION»'''
	
	def String getHiddenEmfPropertyFileName(String extensionlessName) '''«extensionlessName.toHiddenFileName».«PROPERTY_EMF_EXTENSION»'''
	
	def String getXmlUppaalFileName(String extensionlessName) '''«extensionlessName».«UPPAAL_MODEL_EXTENSION»'''
	
	def String getUppaalQueryFileName(String extensionlessName) '''«extensionlessName».«UPPAAL_QUERY_EXTENSION»'''
	
	def String getXtextXStsFileName(String extensionlessName) '''«extensionlessName».«XSTS_XTEXT_EXTENSION»'''
	
	def String getEmfXStsFileName(String extensionlessName) '''«extensionlessName».«XSTS_EMF_EXTENSION»'''
	
}