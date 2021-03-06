package hu.bme.mit.gamma.xsts.uppaal.transformation.api

import hu.bme.mit.gamma.transformation.util.GammaFileNamer
import hu.bme.mit.gamma.uppaal.serializer.UppaalModelSerializer
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.uppaal.transformation.XstsToUppaalTransformer

class Xsts2UppaalTransformerSerializer {
	
	protected final XSTS xSts
	protected final String targetFolderUri
	protected final String fileName
	
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension GammaFileNamer fileNamer = GammaFileNamer.INSTANCE;
	
	new(XSTS xSts, String targetFolderUri, String fileName) {
		this.xSts = xSts
		this.targetFolderUri = targetFolderUri
		this.fileName = fileName
	}
	
	def execute() {
		val xStsToUppaalTransformer = new XstsToUppaalTransformer(xSts)
		val nta = xStsToUppaalTransformer.execute
		nta.normalSave(targetFolderUri, fileName.emfUppaalFileName)
		// Serializing the NTA model to XML
		UppaalModelSerializer.saveToXML(nta, targetFolderUri, fileName.xmlUppaalFileName);
	}
	
}