/********************************************************************************
 * Copyright (c) 2018-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.codegeneration.java

import hu.bme.mit.gamma.codegeneration.java.queries.AbstractSynchronousCompositeComponents
import hu.bme.mit.gamma.codegeneration.java.queries.AsynchronousCompositeComponents
import hu.bme.mit.gamma.codegeneration.java.queries.Interfaces
import hu.bme.mit.gamma.codegeneration.java.queries.SimpleGammaComponents
import hu.bme.mit.gamma.codegeneration.java.queries.SynchronousComponentWrappers
import hu.bme.mit.gamma.codegeneration.java.queries.TypeDeclarations
import hu.bme.mit.gamma.codegeneration.java.util.EventCodeGenerator
import hu.bme.mit.gamma.codegeneration.java.util.Namings
import hu.bme.mit.gamma.codegeneration.java.util.TimerCallbackInterfaceGenerator
import hu.bme.mit.gamma.codegeneration.java.util.TimerInterfaceGenerator
import hu.bme.mit.gamma.codegeneration.java.util.TimerServiceCodeGenerator
import hu.bme.mit.gamma.codegeneration.java.util.TimingDeterminer
import hu.bme.mit.gamma.codegeneration.java.util.TypeDeclarationGenerator
import hu.bme.mit.gamma.codegeneration.java.util.VirtualTimerServiceCodeGenerator
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Package
import java.io.File
import java.io.FileWriter
import java.util.HashSet
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.viatra.query.runtime.api.IPatternMatch
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.api.ViatraQueryMatcher
import org.eclipse.viatra.query.runtime.emf.EMFScope
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRule
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRuleFactory
import org.eclipse.viatra.transformation.runtime.emf.transformation.batch.BatchTransformation
import org.eclipse.viatra.transformation.runtime.emf.transformation.batch.BatchTransformationStatements

import static extension hu.bme.mit.gamma.codegeneration.java.util.Namings.*
import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*

class GlueCodeGenerator {
	// Transformation-related extensions
	protected extension BatchTransformation transformation
	protected extension BatchTransformationStatements statements
	// Transformation rule-related extensions
	protected final extension BatchTransformationRuleFactory = new BatchTransformationRuleFactory
	// Query engines and resources
	protected final ViatraQueryEngine engine
	protected Component topComponent
	// File URIs where the classes need to be saved
	protected final String BASE_FOLDER_URI
	protected final String BASE_PACKAGE_URI
	protected final String CHANNEL_URI
	// The base of the package name, e.g.,: hu.bme.mit.gamma.tutorial.start
	protected final String BASE_PACKAGE_NAME
	// The base of the package name of the generated Yakindu components, not org.yakindu.scr anymore
	protected final String YAKINDU_PACKAGE_NAME
	// Auxiliary transformer objects
	protected final extension TimingDeterminer timingDeterminer = TimingDeterminer.INSTANCE
	protected final extension TypeDeclarationGenerator typeDeclarationGenerator
	protected final extension NameGenerator nameGenerator
	protected final extension EventCodeGenerator eventCodeGenerator
	protected final extension VirtualTimerServiceCodeGenerator virtualTimerServiceCodeGenerator
	protected final extension TimerInterfaceGenerator timerInterfaceGenerator
	protected final extension TimerCallbackInterfaceGenerator timerCallbackInterfaceGenerator
	protected final extension TimerServiceCodeGenerator timerServiceCodeGenerator
	protected final extension PortInterfaceGenerator portInterfaceGenerator
	protected final extension ComponentInterfaceGenerator componentInterfaceGenerator
	protected final extension ReflectiveComponentCodeGenerator reflectiveComponentCodeGenerator
	protected final extension StatechartWrapperCodeGenerator statechartWrapperCodeGenerator
	protected final extension SynchronousCompositeComponentCodeGenerator synchronousCompositeComponentCodeGenerator
	protected final extension AsynchronousAdapterCodeGenerator synchronousComponentWrapperCodeGenerator
	protected final extension LinkedBlockingQueueSource linkedBlockingQueueSourceGenerator
	protected final extension ChannelInterfaceGenerator channelInterfaceGenerator
	protected final extension ChannelCodeGenerator channelCodeGenerator
	protected final extension AsynchronousCompositeComponentCodeGenerator asynchronousCompositeComponentCodeGenerator
	
	// Transformation rules
	protected BatchTransformationRule<? extends IPatternMatch, ? extends ViatraQueryMatcher<?>> typeDeclarationRule
	protected BatchTransformationRule<? extends IPatternMatch, ? extends ViatraQueryMatcher<?>> portInterfaceRule
	protected BatchTransformationRule<? extends IPatternMatch, ? extends ViatraQueryMatcher<?>> simpleComponentsRule
	protected BatchTransformationRule<? extends IPatternMatch, ? extends ViatraQueryMatcher<?>> simpleComponentsReflectionRule
	protected BatchTransformationRule<? extends IPatternMatch, ? extends ViatraQueryMatcher<?>> synchronousCompositeComponentsRule
	protected BatchTransformationRule<? extends IPatternMatch, ? extends ViatraQueryMatcher<?>> synchronousComponentWrapperRule
	protected BatchTransformationRule<? extends IPatternMatch, ? extends ViatraQueryMatcher<?>> channelsRule
	protected BatchTransformationRule<? extends IPatternMatch, ? extends ViatraQueryMatcher<?>> asynchronousCompositeComponentsRule
	
	new(ResourceSet resourceSet, String basePackageName, String srcGenFolderUri) {
		this.BASE_PACKAGE_NAME = basePackageName
		this.YAKINDU_PACKAGE_NAME = basePackageName
		resourceSet.loadModels
		this.engine = ViatraQueryEngine.on(new EMFScope(resourceSet))
		this.BASE_FOLDER_URI = srcGenFolderUri
		this.BASE_PACKAGE_URI = this.BASE_FOLDER_URI  + File.separator + basePackageName.replaceAll("\\.", "/")
		this.CHANNEL_URI = BASE_PACKAGE_URI + File.separator + Namings.CHANNEL_PACKAGE_POSTFIX
		//
		val trace = new Trace(this.engine)
		this.nameGenerator = new NameGenerator(this.BASE_PACKAGE_NAME)
		this.typeDeclarationGenerator = new TypeDeclarationGenerator(this.BASE_PACKAGE_NAME)
		this.eventCodeGenerator = new EventCodeGenerator(this.BASE_PACKAGE_NAME)
		this.virtualTimerServiceCodeGenerator = new VirtualTimerServiceCodeGenerator(this.BASE_PACKAGE_NAME)
		this.timerInterfaceGenerator = new TimerInterfaceGenerator(this.BASE_PACKAGE_NAME)
		this.timerCallbackInterfaceGenerator = new TimerCallbackInterfaceGenerator(this.BASE_PACKAGE_NAME)
		this.timerServiceCodeGenerator = new TimerServiceCodeGenerator(this.BASE_PACKAGE_NAME)
		this.portInterfaceGenerator  = new PortInterfaceGenerator(this.BASE_PACKAGE_NAME, trace) // Needed, as there is back-annotation here from integers to strings
		this.componentInterfaceGenerator = new ComponentInterfaceGenerator(this.BASE_PACKAGE_NAME)
		this.reflectiveComponentCodeGenerator = new ReflectiveComponentCodeGenerator(this.BASE_PACKAGE_NAME, trace)
		this.statechartWrapperCodeGenerator = new StatechartWrapperCodeGenerator(this.BASE_PACKAGE_NAME, this.YAKINDU_PACKAGE_NAME, trace)
		this.synchronousCompositeComponentCodeGenerator = new SynchronousCompositeComponentCodeGenerator(this.BASE_PACKAGE_NAME, this.YAKINDU_PACKAGE_NAME, trace)
		this.synchronousComponentWrapperCodeGenerator = new AsynchronousAdapterCodeGenerator(this.BASE_PACKAGE_NAME, trace)
		this.linkedBlockingQueueSourceGenerator = new LinkedBlockingQueueSource(this.BASE_PACKAGE_NAME)
		this.channelInterfaceGenerator = new ChannelInterfaceGenerator(this.BASE_PACKAGE_NAME)
		this.channelCodeGenerator = new ChannelCodeGenerator(this.BASE_PACKAGE_NAME)
		this.asynchronousCompositeComponentCodeGenerator = new AsynchronousCompositeComponentCodeGenerator(this.BASE_PACKAGE_NAME, trace)
		this.transformation = BatchTransformation.forEngine(engine).build
		this.statements = transformation.transformationStatements
	}
	
	/**
	 * Loads the the top component from the resource set. 
	 */
	private def loadModels(ResourceSet resourceSet) {
		for (resource : resourceSet.resources) {
			// To eliminate empty resources
			if (!resource.getContents.empty) {
				if (resource.getContents.get(0) instanceof Package) {
					val gammaPackage = resource.getContents.get(0) as Package
					val components = gammaPackage.components
					if (!components.isEmpty) {
						topComponent = components.head
						return
					}
				}							
			}
		}	
	}
	
	/**
	 * Executes the code generation.
	 */
	def execute() {
		checkUniqueInterfaceNames
		generateEventClass
		if (topComponent.needTimer) {				
			// Virtual timer is generated only if there are timing specifications (triggers) in the model
			generateTimerClasses	
		}
		getTypeDeclarationRule.fireAllCurrent
		getPortInterfaceRule.fireAllCurrent
		generateReflectiveInterfaceRule
		getSimpleComponentReflectionRule.fireAllCurrent
//		getSimpleComponentDeclarationRule.fireAllCurrent
		getSynchronousCompositeComponentsRule.fireAllCurrent
		if (hasSynchronousWrapper) {
			generateLinkedBlockingMultiQueueClasses
		}
		getAsynchronousAdapterRule.fireAllCurrent
		if (hasAsynchronousComposite) {
			getChannelsRule.fireAllCurrent
		}
		getAsynchronousCompositeComponentsRule.fireAllCurrent
	}	
	
	protected def checkUniqueInterfaceNames() {
		val interfaces = Interfaces.Matcher.on(engine).allValuesOfinterface
		val nameSet = new HashSet<String>
		for (name : interfaces.map[it.name.toFirstUpper]) {
			if (name.equals("state")) {
				throw new IllegalArgumentException("Interfaces cannot be named \"state\"!")
			}
			// Checking colliding interface names
			if (nameSet.contains(name)) {
				throw new IllegalArgumentException("Same interface names: " + name + "! Interface names must differ in more than just their initial character!")
			}
			nameSet.add(name)
		}
	}
	
	/**
	 * Returns whether there is a synchronous component wrapper in the model.
	 */
	protected def hasSynchronousWrapper() {
		return SynchronousComponentWrappers.Matcher.on(engine).hasMatch
	}
	
	/**
	 * Returns whether there is a synchronous component wrapper in the model.
	 */
	protected def hasAsynchronousComposite() {
		return AsynchronousCompositeComponents.Matcher.on(engine).hasMatch
	}
		
	/**
	 * Creates and saves the message class that is responsible for informing the statecharts about the event that has to be raised (with the given value).
	 */
	protected def generateEventClass() {
		val componentUri = BASE_PACKAGE_URI + File.separator + eventCodeGenerator.className + ".java"
		val code = eventCodeGenerator.createEventClass
		code.saveCode(componentUri)
	}
	
	/**
	 * Creates and saves the message class that is responsible for informing the statecharts about the event that has to be raised (with the given value).
	 */
	protected def generateTimerClasses() {
		val virtualTimerClassCode = createVirtualTimerClassCode
		virtualTimerClassCode.saveCode(BASE_PACKAGE_URI + File.separator + virtualTimerServiceCodeGenerator.className + ".java")
		val timerInterfaceCode = createITimerInterfaceCode
		timerInterfaceCode.saveCode(BASE_PACKAGE_URI + File.separator + timerInterfaceGenerator.yakinduInterfaceName + ".java")
		val timerCallbackInterface = createITimerCallbackInterfaceCode
		timerCallbackInterface.saveCode(BASE_PACKAGE_URI + File.separator + timerCallbackInterfaceGenerator.interfaceName + ".java")
		val timerServiceClass = createTimerServiceClassCode
		timerServiceClass.saveCode(BASE_PACKAGE_URI + File.separator + timerServiceCodeGenerator.yakinduClassName + ".java")
		val gammaTimerInterface = createGammaTimerInterfaceCode
		gammaTimerInterface.saveCode(BASE_PACKAGE_URI + File.separator + timerInterfaceGenerator.gammaInterfaceName + ".java")
		val gammaTimerClass = createGammaTimerClassCode
		gammaTimerClass.saveCode(BASE_PACKAGE_URI + File.separator + timerServiceCodeGenerator.gammaClassName + ".java")
		val unifiedTimerInterface = createUnifiedTimerInterfaceCode
		unifiedTimerInterface.saveCode(BASE_PACKAGE_URI + File.separator + timerInterfaceGenerator.unifiedInterfaceName + ".java")
		val unifiedTimerClass = createUnifiedTimerClassCode
		unifiedTimerClass.saveCode(BASE_PACKAGE_URI + File.separator + timerServiceCodeGenerator.unifiedClassName + ".java")
	}
	
	protected def getTypeDeclarationRule() {
		if (typeDeclarationRule === null) {
			 typeDeclarationRule = createRule(TypeDeclarations.instance).action [
			 	if (!it.typeDeclaration.type.primitive) {
 					val packageName = typeDeclaration.getPackageString(BASE_PACKAGE_NAME)
					val TYPE_FOLDER_URI = BASE_FOLDER_URI.generateUri(packageName)
					val code = it.typeDeclaration.generateTypeDeclarationCode
					code.saveCode(TYPE_FOLDER_URI + File.separator + it.typeDeclaration.name + ".java")
				}
			].build		
		}
		return typeDeclarationRule
	}
	
	/**
	 * Creates a Java interface for each Port Interface.
	 */
	protected def getPortInterfaceRule() {
		if (portInterfaceRule === null) {
			 portInterfaceRule = createRule(Interfaces.instance).action [
 				val interfacePackageName = interface.getPackageString(BASE_PACKAGE_NAME)
				val INTERFACE_FOLDER_URI = BASE_FOLDER_URI.generateUri(interfacePackageName)
				val code = it.interface.generatePortInterfaces
				code.saveCode(INTERFACE_FOLDER_URI + File.separator + it.interface.implementationName + ".java")
			].build		
		}
		return portInterfaceRule
	}
	
	protected def generateReflectiveInterfaceRule() {
		val interfaceUri = BASE_PACKAGE_URI
		val reflectiveCode = generateReflectiveInterface
		reflectiveCode.saveCode(interfaceUri + File.separator + Namings.REFLECTIVE_INTERFACE + ".java")
	}
	
	/**
	 * Creates a reflective Java class for each Gamma component.
	 */
	protected def getSimpleComponentReflectionRule() {
		if (simpleComponentsReflectionRule === null) {
			 simpleComponentsReflectionRule = createRule(SimpleGammaComponents.instance).action [
				val componentUri = BASE_PACKAGE_URI + File.separator  + it.statechartDefinition.containingPackage.name.toLowerCase
				// Generating the reflective class
				val reflectiveCode = it.statechartDefinition.generateReflectiveClass
				reflectiveCode.saveCode(componentUri + File.separator + it.statechartDefinition.reflectiveClassName + ".java")
			].build		
		}
		return simpleComponentsReflectionRule
	}
	
	/**
	 * Creates a Java class for each component transformed from Yakindu given in the component model.
	 */
	protected def getSimpleComponentDeclarationRule() {
		if (simpleComponentsRule === null) {
//			 simpleComponentsRule = createRule(SimpleYakinduComponents.instance).action [
//				val componentUri = BASE_PACKAGE_URI + File.separator  + it.statechartDefinition.containingPackage.name.toLowerCase
//				val code = (it.statechartDefinition as StatechartDefinition).createSimpleComponentClass
//				code.saveCode(componentUri + File.separator + it.statechartDefinition.generateComponentClassName + ".java")
//				// Generating the interface for returning the Ports
//				val interfaceCode = it.statechartDefinition.generateComponentInterface
//				interfaceCode.saveCode(componentUri + File.separator + it.statechartDefinition.generatePortOwnerInterfaceName + ".java")
//			].build
		}
		return simpleComponentsRule
	}
	
	protected def getSynchronousCompositeComponentsRule() {
		if (synchronousCompositeComponentsRule === null) {
			 synchronousCompositeComponentsRule = createRule(AbstractSynchronousCompositeComponents.instance).action [
				val compositeSystemUri = BASE_PACKAGE_URI + File.separator + it.synchronousCompositeComponent.containingPackage.name.toLowerCase
				val code = it.synchronousCompositeComponent.createSynchronousCompositeComponentClass
				code.saveCode(compositeSystemUri + File.separator + it.synchronousCompositeComponent.generateComponentClassName + ".java")
				// Generating the interface that is able to return the Ports
				val interfaceCode = it.synchronousCompositeComponent.generateComponentInterface
				interfaceCode.saveCode(compositeSystemUri + File.separator + it.synchronousCompositeComponent.generatePortOwnerInterfaceName + ".java")
				// Generating the reflective class
				val reflectiveCode = it.synchronousCompositeComponent.generateReflectiveClass
				reflectiveCode.saveCode(compositeSystemUri + File.separator + it.synchronousCompositeComponent.reflectiveClassName + ".java")
			].build		
		}
		return synchronousCompositeComponentsRule
	}
	
	protected def void generateLinkedBlockingMultiQueueClasses() {
		val compositeSystemUri = BASE_PACKAGE_URI
		generateAbstractOfferable.saveCode(compositeSystemUri + File.separator + "AbstractOfferable.java")
		generateAbstractPollable.saveCode(compositeSystemUri + File.separator + "AbstractPollable.java")
		generateLinkedBlockingMultiQueue.saveCode(compositeSystemUri + File.separator + "LinkedBlockingMultiQueue.java")
		generateOfferable.saveCode(compositeSystemUri + File.separator + "Offerable.java")
		generatePollable.saveCode(compositeSystemUri + File.separator + "Pollable.java")
	}
	
	protected def getAsynchronousAdapterRule() {
		if (synchronousComponentWrapperRule === null) {
			 synchronousComponentWrapperRule = createRule(SynchronousComponentWrappers.instance).action [
				val compositeSystemUri = BASE_PACKAGE_URI + File.separator + it.synchronousComponentWrapper.containingPackage.name.toLowerCase
				val code = it.synchronousComponentWrapper.createAsynchronousAdapterClass
				code.saveCode(compositeSystemUri + File.separator + it.synchronousComponentWrapper.generateComponentClassName + ".java")
				val interfaceCode = it.synchronousComponentWrapper.generateComponentInterface
				interfaceCode.saveCode(compositeSystemUri + File.separator + it.synchronousComponentWrapper.generatePortOwnerInterfaceName + ".java")
				// Generating the reflective class
				val reflectiveCode = it.synchronousComponentWrapper.generateReflectiveClass
				reflectiveCode.saveCode(compositeSystemUri + File.separator + it.synchronousComponentWrapper.reflectiveClassName + ".java")
			].build		
		}
		return synchronousComponentWrapperRule
	}
	
	/**
	 * Creates a Java interface for each Port Interface.
	 */
	protected def getChannelsRule() {
		if (channelsRule === null) {
			 channelsRule = createRule(Interfaces.instance).action [
				val channelInterfaceCode = it.interface.createChannelInterfaceCode
				channelInterfaceCode.saveCode(CHANNEL_URI + File.separator + it.interface.generateChannelInterfaceName + ".java")
				val channelClassCode = it.interface.createChannelClassCode
				channelClassCode.saveCode(CHANNEL_URI + File.separator + it.interface.generateChannelName + ".java")	
			].build		
		}
		return channelsRule
	}
	
	protected def getAsynchronousCompositeComponentsRule() {
		if (asynchronousCompositeComponentsRule === null) {
			 asynchronousCompositeComponentsRule = createRule(AsynchronousCompositeComponents.instance).action [
				val compositeSystemUri = BASE_PACKAGE_URI + File.separator + it.asynchronousCompositeComponent.containingPackage.name.toLowerCase
				// Main components
				val code = it.asynchronousCompositeComponent.createAsynchronousCompositeComponentClass
				code.saveCode(compositeSystemUri + File.separator + it.asynchronousCompositeComponent.generateComponentClassName + ".java")
				val interfaceCode = it.asynchronousCompositeComponent.generateComponentInterface
				interfaceCode.saveCode(compositeSystemUri + File.separator + it.asynchronousCompositeComponent.generatePortOwnerInterfaceName + ".java")
				
				// Generating the reflective class
				val reflectiveCode = it.asynchronousCompositeComponent.generateReflectiveClass
				reflectiveCode.saveCode(compositeSystemUri + File.separator + it.asynchronousCompositeComponent.reflectiveClassName + ".java")
			].build		
		}
		return asynchronousCompositeComponentsRule
	}
	
	/**
	 * Creates a Java class from the the given code at the location specified by the given URI.
	 */
	protected def saveCode(CharSequence code, String uri) {
		new File(uri.substring(0, uri.lastIndexOf(File.separator))).mkdirs
		val fw = new FileWriter(uri)
		fw.write(code.toString)
		fw.close
		return 
	}
	
	/**
	 * Disposes of the code generator.
	 */
	def dispose() {
		if (transformation !== null) {
			transformation.dispose
		}
		transformation = null
		return
	}
}
