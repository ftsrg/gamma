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
package hu.bme.mit.gamma.xsts.codegeneration.java

import hu.bme.mit.gamma.codegeneration.java.util.EventCodeGenerator
import hu.bme.mit.gamma.codegeneration.java.util.InterfaceCodeGenerator
import hu.bme.mit.gamma.codegeneration.java.util.ReflectiveComponentCodeGenerator
import hu.bme.mit.gamma.codegeneration.java.util.TimerCallbackInterfaceGenerator
import hu.bme.mit.gamma.codegeneration.java.util.TimerInterfaceGenerator
import hu.bme.mit.gamma.codegeneration.java.util.TimerServiceCodeGenerator
import hu.bme.mit.gamma.codegeneration.java.util.TypeDeclarationGenerator
import hu.bme.mit.gamma.codegeneration.java.util.VirtualTimerServiceCodeGenerator
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.FileUtil
import hu.bme.mit.gamma.xsts.model.XSTS
import java.io.File

import static extension hu.bme.mit.gamma.codegeneration.java.util.Namings.*
import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class StatechartToJavaCodeGenerator {

	final String BASE_PACKAGE_NAME
	final String STATECHART_PACKAGE_NAME

	final String SRC_FOLDER_URI
	final String BASE_FOLDER_URI
	final String STATECHART_FOLDER_URI
	
	final EventCodeGenerator eventCodeGenerator
	final TimerInterfaceGenerator timerInterfaceGenerator
	final TimerCallbackInterfaceGenerator timerCallbackInterfaceGenerator
	final TimerServiceCodeGenerator timerServiceCodeGenerator
	final VirtualTimerServiceCodeGenerator virtualTimerServiceCodeGenerator
	final TypeDeclarationGenerator typeDeclarationSerializer
	final InterfaceCodeGenerator interfaceGenerator
	final StatechartInterfaceCodeGenerator statechartInterfaceGenerator
	final StatechartWrapperCodeGenerator statechartWrapperCodeGenerator
	final StatechartCodeGenerator statechartCodeGenerator
	final ReflectiveComponentCodeGenerator reflectiveComponentCodeGenerator
	
	final StatechartDefinition gammaStatechart 
	final XSTS xSts
	
	// Auxiliary objects
	protected final extension FileUtil fileUtil = FileUtil.INSTANCE
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	
	new(String targetFolderUri, String basePackageName,
			StatechartDefinition gammaStatechart, XSTS xSts, ActionSerializer actionSerializer) {
		this.gammaStatechart = gammaStatechart
		this.xSts = xSts
		this.BASE_PACKAGE_NAME = basePackageName
		this.SRC_FOLDER_URI = targetFolderUri
		this.BASE_FOLDER_URI = targetFolderUri.generateUri(BASE_PACKAGE_NAME)
		this.STATECHART_PACKAGE_NAME = gammaStatechart.getPackageString(BASE_PACKAGE_NAME)
		this.STATECHART_FOLDER_URI = targetFolderUri.generateUri(STATECHART_PACKAGE_NAME)
		// Classes
		this.eventCodeGenerator = new EventCodeGenerator(BASE_PACKAGE_NAME)
		this.typeDeclarationSerializer = new TypeDeclarationGenerator(BASE_PACKAGE_NAME)
		this.timerInterfaceGenerator = new TimerInterfaceGenerator(BASE_PACKAGE_NAME)
		this.timerCallbackInterfaceGenerator = new TimerCallbackInterfaceGenerator(BASE_PACKAGE_NAME)
		this.timerServiceCodeGenerator = new TimerServiceCodeGenerator(BASE_PACKAGE_NAME)
		this.virtualTimerServiceCodeGenerator = new VirtualTimerServiceCodeGenerator(BASE_PACKAGE_NAME)
		this.interfaceGenerator = new InterfaceCodeGenerator(BASE_PACKAGE_NAME)
		this.statechartInterfaceGenerator = new StatechartInterfaceCodeGenerator(BASE_PACKAGE_NAME,
			STATECHART_PACKAGE_NAME, gammaStatechart)
		this.statechartWrapperCodeGenerator = new StatechartWrapperCodeGenerator(BASE_PACKAGE_NAME,
			STATECHART_PACKAGE_NAME, gammaStatechart, this.xSts)
		this.statechartCodeGenerator = new StatechartCodeGenerator(BASE_PACKAGE_NAME, STATECHART_PACKAGE_NAME,
			gammaStatechart.wrappedStatemachineClassName, gammaStatechart, xSts, actionSerializer)
		this.reflectiveComponentCodeGenerator = new ReflectiveComponentCodeGenerator(BASE_PACKAGE_NAME, gammaStatechart)
	}
	
	def execute() {
		generateEventClass
		generateTimerInterface
		generateTimerCallbackInterface
		generateTimerServiceClass
//		generateVirtualTimerServiceClass
		generateTypeDeclarations
		generateInterfaces
		generateStatechartWrapperInterface
		generateStatechartWrapperClass
		generateStatechartClass
		generateReflectiveInterface
		generateReflectiveClass
	}
	
	def generateEventClass() {
		val componentUri = BASE_FOLDER_URI + File.separator + eventCodeGenerator.className + ".java"
		val code = eventCodeGenerator.createEventClass
		code.saveCode(componentUri)
	}
	
	def generateTimerInterface() {
		val componentUri = BASE_FOLDER_URI + File.separator + timerInterfaceGenerator.yakinduInterfaceName + ".java"
		val code = timerInterfaceGenerator.createITimerInterfaceCode
		code.saveCode(componentUri)
		val gammaComponentUri = BASE_FOLDER_URI + File.separator + timerInterfaceGenerator.gammaInterfaceName + ".java"
		val gammaCode = timerInterfaceGenerator.createGammaTimerInterfaceCode
		gammaCode.saveCode(gammaComponentUri)
		val unifiedTimerInterfaceUri = BASE_FOLDER_URI + File.separator + timerInterfaceGenerator.unifiedInterfaceName + ".java"
		val unifiedTimerInterfaceCode = timerInterfaceGenerator.createUnifiedTimerInterfaceCode
		unifiedTimerInterfaceCode.saveCode(unifiedTimerInterfaceUri)
	}
	
	def generateTimerCallbackInterface() {
		val componentUri = BASE_FOLDER_URI + File.separator + timerCallbackInterfaceGenerator.interfaceName + ".java"
		val code = timerCallbackInterfaceGenerator.createITimerCallbackInterfaceCode
		code.saveCode(componentUri)
	}
	
	def generateTimerServiceClass() {
		val componentUri = BASE_FOLDER_URI + File.separator + timerServiceCodeGenerator.yakinduClassName + ".java"
		val code = timerServiceCodeGenerator.createTimerServiceClassCode
		code.saveCode(componentUri)
		val gammaComponentUri = BASE_FOLDER_URI + File.separator + timerServiceCodeGenerator.gammaClassName + ".java"
		val gammaCode = timerServiceCodeGenerator.createGammaTimerClassCode
		gammaCode.saveCode(gammaComponentUri)
		val unifiedTimerClassUri = BASE_FOLDER_URI + File.separator + timerServiceCodeGenerator.unifiedClassName + ".java"
		val unifiedTimerClassCode = timerServiceCodeGenerator.createUnifiedTimerClassCode
		unifiedTimerClassCode.saveCode(unifiedTimerClassUri)
	}
	
	def generateVirtualTimerServiceClass() {
		val componentUri = BASE_FOLDER_URI + File.separator + virtualTimerServiceCodeGenerator.className + ".java"
		val code = virtualTimerServiceCodeGenerator.createVirtualTimerClassCode
		code.saveCode(componentUri)
	}
	
	def generateTypeDeclarations() {
		// Adding record types, so they can be serialized too
		val typeDeclarations = gammaStatechart.typeDeclarations
//		val recordTypeDeclarations = typeDeclarations.filter[it.typeDefinition instanceof RecordTypeDefinition]
//		val publicTypeDeclarations = newArrayList
//		publicTypeDeclarations += recordTypeDeclarations
//		publicTypeDeclarations += xSts.publicTypeDeclarations
		// Type declarations must be contained by the original package due to package import
		// Therefore, xSts.publicTypeDeclarations cannot be used
		for (typeDeclaration : typeDeclarations.filter[!it.typeDefinition.primitive]) {
			val packageName = typeDeclaration.getPackageString(BASE_PACKAGE_NAME) 
			val DECLARATION_FOLDER_URI = SRC_FOLDER_URI.generateUri(packageName)
			val componentUri = DECLARATION_FOLDER_URI + File.separator + typeDeclaration.name + ".java"
			val code = typeDeclarationSerializer.generateTypeDeclarationCode(typeDeclaration)
			code.saveCode(componentUri)
		}
	}
	
	def generateInterfaces() {
		for (interface : gammaStatechart.interfaces) {
			val interfacePackageName = interface.getPackageString(BASE_PACKAGE_NAME)
			val INTERFACE_FOLDER_URI = SRC_FOLDER_URI.generateUri(interfacePackageName)
			val componentUri = INTERFACE_FOLDER_URI + File.separator + interface.implementationName + ".java"
			val code = interfaceGenerator.createInterface(interface)
			code.saveCode(componentUri)
		}
	}
	
	def generateStatechartWrapperInterface() {
		val componentUri = STATECHART_FOLDER_URI + File.separator + statechartInterfaceGenerator.interfaceName + ".java"
		val code = statechartInterfaceGenerator.createStatechartWrapperInterface
		code.saveCode(componentUri)
	}
	
	def generateStatechartWrapperClass() {
		val componentUri = STATECHART_FOLDER_URI + File.separator + statechartWrapperCodeGenerator.className + ".java"
		val code = statechartWrapperCodeGenerator.createStatechartWrapperClass
		code.saveCode(componentUri)
	}
	
	def generateStatechartClass() {
		val componentUri = STATECHART_FOLDER_URI + File.separator + statechartCodeGenerator.className + ".java"
		val code = statechartCodeGenerator.createStatechartClass
		code.saveCode(componentUri)
	}
	
	def generateReflectiveClass() {
		val componentUri = STATECHART_FOLDER_URI + File.separator + reflectiveComponentCodeGenerator.className + ".java"
		val code = reflectiveComponentCodeGenerator.createReflectiveClass
		code.saveCode(componentUri)
	}
	
	def generateReflectiveInterface() {
		val componentUri = BASE_FOLDER_URI + File.separator + REFLECTIVE_INTERFACE + ".java"
		val code = interfaceGenerator.createReflectiveInterface
		code.saveCode(componentUri)
	}

	/**
	 * Creates a Java class from the the given code at the location specified by the given URI.
	 */
	protected def void saveCode(CharSequence code, String uri) {
		uri.saveString(code.toString)
	}
	
}