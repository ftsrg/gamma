/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.util

import java.io.File
import java.io.FileWriter
import java.util.AbstractMap
import java.util.ArrayList
import java.util.Collections
import java.util.Map
import java.util.Scanner
import org.eclipse.core.resources.IResource

class FileUtil {
	// Singleton
	public static final FileUtil INSTANCE = new FileUtil
	protected new() {}
	//
	def saveString(String uri, String string) {
		new File(uri).saveString(string)
	}
	
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
				builder.append(scanner.nextLine + System.lineSeparator)
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
	
	def getFile(String fileUri) {
		return new File(fileUri)
	}
	
	def getFileName(String fileUri) {
		return fileUri.file.name
	} 
	
	def getExtensionlessName(File file) {
		return file.name.extensionlessName
	}
	
	def getExtensionlessName(String fileName) {
		val lastIndex = fileName.lastIndexOf(".")
		if (lastIndex <= 0) { // <= 0 so hidden files are handled
			return fileName
		}
		return fileName.substring(0, lastIndex)
	}
	
	def getExtension(File file) {
		return file.name.extension
	}
	
	def getExtension(String fileName) {
		val lastIndex = fileName.lastIndexOf(".")
		if (lastIndex <= 0) { // <= 0 so hidden files are handled
			return ""
		}
		return fileName.substring(lastIndex + 1)
	}
	
	def isHiddenFile(File file) {
		return file.name.hiddenFile
	}
	
	def isHiddenFile(String fileName) {
		return fileName.startsWith(".")
	}
	
	def toHiddenFileName(String fileName) {
		return "." + fileName
	}
	
	def toUnhiddenFileName(String fileName) {
		if (fileName.startsWith(".")) {
			return fileName.substring(1)
		}
		return fileName
	}
	
	def changeExtension(String fileName, String newExtension) {
		return fileName.extensionlessName + "." + newExtension
	}
	
	def getParent(String fileUri) {
		val file = new File(fileUri)
		return file.parent
	}
	
	def File exploreRelativeFile(File anchor, String relativePath) {
		//
		val relativePathTestFile = new File(relativePath);
		if (relativePathTestFile.exists && relativePathTestFile.isAbsolute) {
			// This is actually an incorrect call, as the String is not
			// a relative path to the anchor, but we handle it anyway
			return relativePathTestFile
		}
		// The string is actually a relative path
		val path = anchor.toString + File.separator + relativePath
		val file = new File(path)
		if (file.exists) {
			return file
		}
		val parent = anchor.parentFile
		return parent.exploreRelativeFile(relativePath)
	}
	
	def isValidRelativeFile(File anchor, String relativePath) {
		try {
			anchor.exploreRelativeFile(relativePath)
			return true
		} catch (NullPointerException e) {
			return false
		}
	}
	
	def toFile(IResource resource) {
		return resource.fullPath.toFile
	}
	
	def void forceDelete(File file) {
		if (file.isDirectory) {
			for (subfile : file.listFiles) {
				subfile.forceDelete
			}
		}
		file.delete
	}
	
    /**
     * Returns the next valid name for the file that is suffixed by indices.
     */
    def Map.Entry<String, Integer> getFileName(File folder, String fileName, String fileExtension) {
    	val usedIds = new ArrayList<Integer>();
    	folder.mkdirs();
    	// Searching the trace folder for highest id
    	for (File file: folder.listFiles()) {
    		if (file.getName().matches(fileName + "[0-9]+\\." + fileExtension)) {
    			// File extension needed to distinguish .get and .json
    			val id = file.getName().substring(fileName.length(), file.getName().length() - ("." + fileExtension).length());
    			usedIds.add(Integer.parseInt(id));
    		}
    	}
    	if (usedIds.isEmpty()) {
    		return new AbstractMap.SimpleEntry<String, Integer>(fileName + "0." + fileExtension, 0);
    	}
    	Collections.sort(usedIds);
    	val biggestId = usedIds.get(usedIds.size() - 1);
    	return new AbstractMap.SimpleEntry<String, Integer>(
    			fileName + (biggestId + 1) + "." + fileExtension, (biggestId + 1));
    }
	
}