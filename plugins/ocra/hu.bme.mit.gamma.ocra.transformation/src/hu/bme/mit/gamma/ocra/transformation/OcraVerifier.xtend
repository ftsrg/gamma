package hu.bme.mit.gamma.ocra.transformation

import hu.bme.mit.gamma.util.FileUtil
import java.io.File
import java.util.Scanner

class OcraVerifier {
	protected final static extension FileUtil fileUtil = FileUtil.INSTANCE
	
	def verifyQuery(File ocraFile) {
		
		//TODO add the OCRA_HOME variable to your system path
		val ocraPath = System.getenv("OCRA_HOME") + File.separator + "ocra-win64.exe"
		val parentPath = ocraFile.parent
		val commandFile = new File(parentPath + File.separator + '''.ocra-commands-«Thread.currentThread.name».cmd''')
		commandFile.deleteOnExit
		val serializedCommand = '''
			set on_failure_script_quits
			ocra_check_syntax -i "«ocraFile.absolutePath»
			quit"
		'''
		fileUtil.saveString(commandFile, serializedCommand)
		
		val ocraCommand = #[ocraPath] + #["-source", commandFile.absolutePath]
				
		try {
			val process =  Runtime.getRuntime().exec(ocraCommand)
			val resultReader = new Scanner(process.inputReader)
			val successRegex = ".*" + "oss specification"+ ".*"
			val failureRegex = "line "+ ".*"
			
			while (resultReader.hasNextLine) {
				val line = resultReader.nextLine
				if (line.matches(successRegex) || line.matches(failureRegex)) {
					System.out.println(line)
				}
			}
		} catch (Exception e) {
			throw e
		}
		
	}
		
}	