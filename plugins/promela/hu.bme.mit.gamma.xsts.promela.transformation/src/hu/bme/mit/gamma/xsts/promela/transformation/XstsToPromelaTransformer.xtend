package hu.bme.mit.gamma.xsts.promela.transformation

import java.io.File
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.util.FileUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.promela.transformation.serializer.ModelSerializer

class XstsToPromelaTransformer {
	
	protected final String targetFolderUri
	protected final String fileName
	protected final XSTS xSts
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ModelSerializer modelSerializer = ModelSerializer.INSTANCE
	protected final extension FileUtil fileUtil = FileUtil.INSTANCE
	
	new(File file) {
		this.targetFolderUri = file.parent
		this.fileName = file.extensionlessName
		this.xSts = targetFolderUri.normalLoad(file.name) as XSTS
	}
	
	new(XSTS xSts, String targetFolderUri, String fileName) {
		this.xSts = xSts;
		this.targetFolderUri = targetFolderUri;
		this.fileName = fileName;
	}
	
	def void execute() {
		val promelaFile = new File(targetFolderUri + File.separator + fileName + ".pml")
		val promelaString = xSts.serializePromela
		promelaFile.saveString(promelaString)
	}
}