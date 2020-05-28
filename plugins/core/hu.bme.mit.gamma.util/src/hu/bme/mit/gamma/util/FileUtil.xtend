package hu.bme.mit.gamma.util

import java.io.File
import java.io.FileWriter
import java.util.Scanner

class FileUtil {
	
	def saveString(File file, String string) {
		file.parentFile.mkdirs
		try (val fileWriter = new FileWriter(file)) {
			fileWriter.write(string)
		}
	}
	
	def loadString(File file) {
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
	
	def getExtensionlessName(File file) {
		val fileName = file.name
		val lastIndex = fileName.lastIndexOf(".")
		if (lastIndex < 0) {
			return fileName
		}
		return fileName.substring(0, lastIndex)
	}
	
}