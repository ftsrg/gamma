/********************************************************************************
 * Copyright (c) 2018-2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.codegeneration.java

import hu.bme.mit.gamma.codegeneration.java.util.Namings
import hu.bme.mit.gamma.codegeneration.java.util.TimingDeterminer
import hu.bme.mit.gamma.statechart.composite.AbstractAsynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.composite.CompositeComponent
import hu.bme.mit.gamma.statechart.interface_.Port

import static extension hu.bme.mit.gamma.codegeneration.java.util.Namings.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class CompositeComponentCodeGenerator {
	
	protected final String PACKAGE_NAME
	// 
	protected final extension TimingDeterminer timingDeterminer = TimingDeterminer.INSTANCE
	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	protected final extension NameGenerator nameGenerator
	protected final extension TypeTransformer typeTransformer
	protected final extension ComponentCodeGenerator componentCodeGenerator
	protected final extension EventDeclarationHandler gammaEventDeclarationHandler
	//
	protected final extension Trace trace

	new(String packageName, Trace trace) {
		this.PACKAGE_NAME = packageName
		this.trace = trace
		this.nameGenerator = new NameGenerator(this.PACKAGE_NAME)
		this.typeTransformer = new TypeTransformer(this.trace)
		this.componentCodeGenerator = new ComponentCodeGenerator(this.trace)
		this.gammaEventDeclarationHandler = new EventDeclarationHandler(this.trace)
	}
	
	/**
	 * Generates the needed Java imports in case of the given composite component.
	 */
	def generateCompositeSystemImports(CompositeComponent component) '''
		import java.util.List;
		import java.util.LinkedList;
		
		import «PACKAGE_NAME».*;
		«FOR packageName : component.containingPackage.componentImports
				.filter[it.containsComponentsOrInterfacesOrTypes]
				.map['''«it.getPackageString(PACKAGE_NAME)».*''']
				.toSet /* For type declarations and same-name packages*/»
			import «packageName»;
		«ENDFOR»
		«IF component instanceof AbstractAsynchronousCompositeComponent»
			import «PACKAGE_NAME».«Namings.CHANNEL_PACKAGE_POSTFIX».*;
		«ENDIF»
	'''
	
	/**
	 * Generates methods that for in-event raisings in the case of composite components.
	 */
	def CharSequence delegateRaisingMethods(Port systemPort) '''
		«FOR event : systemPort.inputEvents SEPARATOR "\n"»
			@Override
			public void raise«event.name.toFirstUpper»(«event.generateParameters») {
				«FOR connector : systemPort.portBindings»
					«connector.instancePortReference.instance.name».get«connector.instancePortReference.port.name.toFirstUpper»().raise«event.name.toFirstUpper»(«event.generateArguments»);
				«ENDFOR»	
			}
		«ENDFOR»
	'''
	
	/**
	 * Generates methods for out-event check delegations in the case of composite components.
	 */
	def CharSequence delegateOutMethods(Port systemPort) '''
«««		Simple flag checks
		«FOR event : systemPort.outputEvents»
			@Override
			public boolean isRaised«event.name.toFirstUpper»() {
				«FOR connector : systemPort.portBindings»
					return «connector.instancePortReference.instance.name».get«connector.instancePortReference.port.name.toFirstUpper»().isRaised«event.name.toFirstUpper»();
				«ENDFOR»
			}
«««			ValueOf checks
			«FOR parameter : event.parameterDeclarations»
				@Override
				public «parameter.type.transformType» get«parameter.name.toFirstUpper»() {
					«FOR connector : systemPort.portBindings»
						return «connector.instancePortReference.instance.name».get«connector.instancePortReference.port.name.toFirstUpper»().get«parameter.name.toFirstUpper»();
					«ENDFOR»
				}
			«ENDFOR»
		«ENDFOR»
	'''
	
	/**
	 * Generates methods for own out-event checks in case of composite components.
	 */
	def CharSequence implementOutMethods(Port systemPort) '''
«««		Simple flag checks
		«FOR event : systemPort.outputEvents SEPARATOR "\n"»
			@Override
			public boolean isRaised«event.name.toFirstUpper»() {
				return isRaised«event.name.toFirstUpper»;
			}
«««			ValueOf checks
			«FOR parameter : event.parameterDeclarations»
				@Override
				public «parameter.type.transformType» get«parameter.name.toFirstUpper»() {
					return «parameter.generateName»;
				}
			«ENDFOR»
		«ENDFOR»
	'''
	
	/** Sets the parameters of the component and instantiates the necessary components with them. */
	def createInstances(CompositeComponent component) '''
		«FOR parameter : component.parameterDeclarations»
			this.«parameter.name» = «parameter.name»;
		«ENDFOR»
		«FOR instance : component.derivedComponents»
			«instance.name» = new «instance.derivedType.generateComponentClassName»(«FOR argument : instance.arguments SEPARATOR ", "»«argument.serialize»«ENDFOR»);
		«ENDFOR»
		«FOR port : component.portBindings.map[it.compositeSystemPort]»
			«port.name.toFirstLower» = new «port.name.toFirstUpper»();
		«ENDFOR»
	'''
	
}