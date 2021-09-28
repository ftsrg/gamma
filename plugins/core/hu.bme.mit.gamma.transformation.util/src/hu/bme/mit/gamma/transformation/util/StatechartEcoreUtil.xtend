package hu.bme.mit.gamma.transformation.util

import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.io.File

class StatechartEcoreUtil {
	// Singleton
	public static final StatechartEcoreUtil INSTANCE =  new StatechartEcoreUtil
	protected new() {}
	//
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension GammaFileNamer fileNamer = GammaFileNamer.INSTANCE
	
	def loadOriginalComponent(Component unfoldedComponent) {
		val unfoldedPackageFile = unfoldedComponent.eResource.file
		val unfoldedPackagePath = unfoldedPackageFile.absolutePath
		val originalComponentUri = unfoldedPackagePath.originalComponentUri
		val originalComponentFile = new File(originalComponentUri)
		val originalPackage = originalComponentFile.normalLoad as Package
		val originalComponent = originalPackage.components.findFirst[it.name == unfoldedComponent.name]
		return originalComponent
	}
	
}