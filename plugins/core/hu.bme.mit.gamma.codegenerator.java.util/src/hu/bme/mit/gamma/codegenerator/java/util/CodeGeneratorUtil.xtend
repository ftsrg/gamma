package hu.bme.mit.gamma.codegenerator.java.util

import java.io.File
import java.io.FileWriter
import java.io.IOException
import java.util.Scanner

class CodeGeneratorUtil {
		
	def saveString(File file, String string) throws IOException {
		file.parentFile.mkdirs;
		try (val fileWriter = new FileWriter(file)) {
			fileWriter.write(string)
		}
	}
	
	def loadString(File file) throws IOException {
		val builder = new StringBuilder
		try (val scanner = new Scanner(file)) {
			while (scanner.hasNext) {
				builder.append(scanner.nextLine)
			}
		}
		return builder.toString
	}
	
	def toPath(String packageName) {
		return packageName.replaceAll("\\.", "\\"+ File.separator)
	}
	
	def getFile(File sourceFolder, String packageName, String className) {
		return getFile(sourceFolder.toString, packageName, className)
	} 
	
	def getFile(String sourceFolder, String packageName, String className) {
		return new File(sourceFolder + File.separator + packageName.toPath + File.separator + className + ".java")
	} 
	
}