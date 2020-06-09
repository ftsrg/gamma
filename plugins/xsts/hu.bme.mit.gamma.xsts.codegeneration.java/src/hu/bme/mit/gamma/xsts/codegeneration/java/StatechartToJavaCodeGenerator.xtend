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

import hu.bme.mit.gamma.codegenerator.java.util.EventCodeGenerator
import hu.bme.mit.gamma.codegenerator.java.util.InterfaceCodeGenerator
import hu.bme.mit.gamma.codegenerator.java.util.ReflectiveComponentCodeGenerator
import hu.bme.mit.gamma.codegenerator.java.util.TimerCallbackInterfaceGenerator
import hu.bme.mit.gamma.codegenerator.java.util.TimerInterfaceGenerator
import hu.bme.mit.gamma.codegenerator.java.util.TimerServiceCodeGenerator
import hu.bme.mit.gamma.codegenerator.java.util.TypeDeclarationGenerator
import hu.bme.mit.gamma.codegenerator.java.util.VirtualTimerServiceCodeGenerator
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.util.FileUtil
import hu.bme.mit.gamma.xsts.model.model.XSTS
import java.io.File

import static extension hu.bme.mit.gamma.codegenerator.java.util.Namings.*

class StatechartToJavaCodeGenerator {

	final String BASE_PACKAGE_NAME
	final String INTERFACE_PACKAGE_NAME
	final String STATECHART_PACKAGE_NAME
	
	final String BASE_FOLDER_URI
	final String INTERFACE_FOLDER_URI
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
	protected final extension FileUtil fileUtil = new FileUtil
	
	new(String targetFolderUri, String basePackageName,
			StatechartDefinition gammaStatechart, XSTS xSts, ActionSerializer actionSerializer) {
		this.BASE_PACKAGE_NAME = basePackageName
		this.BASE_FOLDER_URI = targetFolderUri + "/" + BASE_PACKAGE_NAME.replaceAll("\\.", "/")
		this.INTERFACE_PACKAGE_NAME = BASE_PACKAGE_NAME.interfacePackageString
		this.INTERFACE_FOLDER_URI = targetFolderUri + "/" + INTERFACE_PACKAGE_NAME.replaceAll("\\.", "/")
		this.STATECHART_PACKAGE_NAME = gammaStatechart.getPackageString(BASE_PACKAGE_NAME)
		this.STATECHART_FOLDER_URI = targetFolderUri + "/" + STATECHART_PACKAGE_NAME.replaceAll("\\.", "/")
		// Classes
		this.eventCodeGenerator = new EventCodeGenerator(BASE_PACKAGE_NAME)
		this.typeDeclarationSerializer = new TypeDeclarationGenerator(BASE_PACKAGE_NAME)
		this.timerInterfaceGenerator = new TimerInterfaceGenerator(BASE_PACKAGE_NAME)
		this.timerCallbackInterfaceGenerator = new TimerCallbackInterfaceGenerator(BASE_PACKAGE_NAME)
		this.timerServiceCodeGenerator = new TimerServiceCodeGenerator(BASE_PACKAGE_NAME)
		this.virtualTimerServiceCodeGenerator = new VirtualTimerServiceCodeGenerator(BASE_PACKAGE_NAME)
		this.interfaceGenerator = new InterfaceCodeGenerator(BASE_PACKAGE_NAME)
		this.statechartInterfaceGenerator = new StatechartInterfaceCodeGenerator(INTERFACE_PACKAGE_NAME,
			STATECHART_PACKAGE_NAME, gammaStatechart)
		this.statechartWrapperCodeGenerator = new StatechartWrapperCodeGenerator(BASE_PACKAGE_NAME,
			INTERFACE_PACKAGE_NAME, STATECHART_PACKAGE_NAME, gammaStatechart, xSts)
		this.statechartCodeGenerator = new StatechartCodeGenerator(BASE_PACKAGE_NAME, STATECHART_PACKAGE_NAME,
			gammaStatechart.wrappedStatemachineClassName, xSts, actionSerializer)
		this.reflectiveComponentCodeGenerator = new ReflectiveComponentCodeGenerator(BASE_PACKAGE_NAME, gammaStatechart)
		this.gammaStatechart = gammaStatechart
		this.xSts = xSts
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
//		val componentUri = BASE_FOLDER_URI + File.separator + timerInterfaceGenerator.yakinduInterfaceName + ".java"
//		val code = timerInterfaceGenerator.createYakinduTimerInterface
//		code.saveCode(componentUri)
		val gammaComponentUri = BASE_FOLDER_URI + File.separator + timerInterfaceGenerator.gammaInterfaceName + ".java"
		val gammaCode = timerInterfaceGenerator.createGammaTimerInterfaceCode
		gammaCode.saveCode(gammaComponentUri)
	}
	
	def generateTimerCallbackInterface() {
		val componentUri = BASE_FOLDER_URI + File.separator + timerCallbackInterfaceGenerator.interfaceName + ".java"
		val code = timerCallbackInterfaceGenerator.createITimerCallbackInterfaceCode
		code.saveCode(componentUri)
	}
	
	def generateTimerServiceClass() {
//		val componentUri = BASE_FOLDER_URI + File.separator + timerServiceCodeGenerator.yakinduClassName + ".java"
//		val code = timerServiceCodeGenerator.createYakinduTimerServiceClass
//		code.saveCode(componentUri)
		val gammaComponentUri = BASE_FOLDER_URI + File.separator + timerServiceCodeGenerator.gammaClassName + ".java"
		val gammaCode = timerServiceCodeGenerator.createGammaTimerClassCode
		gammaCode.saveCode(gammaComponentUri)
	}
	
	def generateVirtualTimerServiceClass() {
		val componentUri = BASE_FOLDER_URI + File.separator + virtualTimerServiceCodeGenerator.className + ".java"
		val code = virtualTimerServiceCodeGenerator.createVirtualTimerClassCode
		code.saveCode(componentUri)
	}
	
	def generateTypeDeclarations() {
		for (typeDeclaration : xSts.publicTypeDeclarations) {
			val componentUri = BASE_FOLDER_URI + File.separator + typeDeclaration.name + ".java"
			val code = typeDeclarationSerializer.generateTypeDeclarationCode(typeDeclaration)
			code.saveCode(componentUri)
		}
	}
	
	def generateInterfaces() {
		for (interface : gammaStatechart.ports.map[it.interfaceRealization.interface].toSet) {
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