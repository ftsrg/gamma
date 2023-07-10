package hu.bme.mit.gamma.xsts.nuxmv.transformation

import hu.bme.mit.gamma.transformation.util.GammaFileNamer
import hu.bme.mit.gamma.util.FileUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.nuxmv.transformation.serializer.ModelSerializer
import java.io.File

class XstsToNuxmvTransformer {
	protected final String targetFolderUri
	protected final String fileName
	protected final XSTS xSts
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ModelSerializer modelSerializer = ModelSerializer.INSTANCE
	protected final extension FileUtil fileUtil = FileUtil.INSTANCE
	protected final extension GammaFileNamer fileNamer = GammaFileNamer.INSTANCE
	
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
		val nuxmvFile = new File(targetFolderUri + File.separator + fileName.smvNuxmvFileName)
		val nuxmvString = xSts.serializeNuxmv
		nuxmvFile.saveString(nuxmvString)
	}
}