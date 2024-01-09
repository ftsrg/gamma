/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
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
import java.util.List
import java.util.Map
import java.util.Scanner
import javax.xml.XMLConstants
import javax.xml.parsers.DocumentBuilderFactory
import org.eclipse.core.resources.IFile
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
	
	def loadLines(File file, int count) {
		val builder = new StringBuilder
		
		var i = 0
		try (val scanner = new Scanner(file)) {
			while (i++ < count && scanner.hasNext) {
				builder.append(scanner.nextLine + System.lineSeparator)
			}
		}
		
		return builder.toString
	}
	
	def loadFirstLine(File file) {
		return file.loadLines(1)
	}
	
	def loadXml(File file) {
		// https://mkyong.com/java/how-to-read-xml-file-in-java-dom-parser/
		val documentBuilderFactory = DocumentBuilderFactory.newInstance
		documentBuilderFactory.setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true)
		val documentBuilder = documentBuilderFactory.newDocumentBuilder
		val document = documentBuilder.parse(file)
		
		document.documentElement.normalize
		return document
	}
	
	def toPath(String packageName) {
		return packageName.replaceAll("\\.", "\\"+ File.separator)
	}
	
	def List<File> getAllContainedFiles(File file) {
		val files = newArrayList
		
		if (files !== null) {
			val containedFiles = file.listFiles
			if (containedFiles !== null) {
				for (containedFile : containedFiles) {
					if (containedFile.file) {
						files += containedFile
					}
					else if (containedFile.directory) {
						files += containedFile.allContainedFiles
					}
				}
			}
		}
		
		return files
	}
	
	def getFile(IFile file) {
		val fullPath = file.fullPath
		return fullPath.toFile
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
	
	def extendFileName(File file, String extensionString) {
		val parent = file.parent
		val extendedFile =  new File(parent + File.separator + file.extensionlessName + extensionString + "." + file.extension)
		
		return extendedFile
	}
	
	def extendAndHideFileName(File file, String extensionString) {
		val parent = file.parent
		val extendedFile =  new File(parent + File.separator + file.extensionlessName.toHiddenFileName + extensionString + "." + file.extension)
		
		return extendedFile
	}
	
	def getUnhiddenFileName(String fileUri) {
		return fileUri.file.name.toUnhiddenFileName
	} 
	
	def getExtensionlessName(File file) {
		return file.name.extensionlessName
	}
	
	def getUnhiddenExtensionlessName(File file) {
		return file.name.unhiddenExtensionlessName
	}
	
	def getExtensionlessName(String fileName) {
		val lastIndex = fileName.extensionDotIndex // So hidden files are handled
		if (lastIndex < 0) {
			return fileName
		}
		return fileName.substring(0, lastIndex)
	}
	
	def getUnhiddenExtensionlessName(String fileName) {
		return fileName.toUnhiddenFileName.extensionlessName
	}
	
	def getExtension(File file) {
		return file.name.extension
	}
	
	def getExtension(String fileName) {
		val lastIndex = fileName.extensionDotIndex // So hidden files are handled
		if (lastIndex < 0) {
			return ""
		}
		return fileName.substring(lastIndex + 1)
	}
	
	private def int getExtensionDotIndex(String fileName) {
		val lastSeparatorIndex = Math.max(
			fileName.lastIndexOf("/"), fileName.lastIndexOf("\\"))
		
		val index = fileName.lastIndexOf(".")
		if (index <= 0 || index < lastSeparatorIndex) {
			return -1 // Hidden file or no extension
		}
		val charBeforeDot = fileName.charAt(index - 1).toString
		if (charBeforeDot == ".") {
			return -1 // Hidden(hidden) file
		}
		
		return index // Valid extension
	}
	
	def hasExtension(String fileName) {
		return fileName != fileName.extensionlessName
	}
	
	def hasExtension(File file) {
		return file.name.hasExtension
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
	
	def changeFileName(String fileUri, String newFileName) {
		val parent = fileUri.parent
		return parent + File.separator + newFileName
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
		return resource.location.toFile
	}
	
	def void forceDelete(File file) {
		if (file.isDirectory) {
			for (subfile : file.listFiles) {
				subfile.forceDelete
			}
		}
		file.delete
	}
	
	def void forceDeleteOnExit(File file) {
		file.deleteOnExit // "Files (or directories) are deleted in the reverse order they are registered"
		if (file.isDirectory) {
			for (subfile : file.listFiles) {
				subfile.forceDeleteOnExit
			}
		}
	}
	
	/**
	 * Returns the next valid name for the file that is suffixed by indices.
	 */
	def Map.Entry<String, Integer> getFileName(File folder, String fileName, String fileExtension) {
		val usedIds = new ArrayList<Integer>();
		folder.mkdirs();
		// Searching the trace folder for highest id
		for (File file: folder.listFiles()) {
			val name = file.getName();
			if (name.matches(fileName + "[0-9]+\\." + fileExtension)) {
				// File extension needed to distinguish .get and .json
				val id = name.substring(fileName.length(),
						name.length() - ("." + fileExtension).length());
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