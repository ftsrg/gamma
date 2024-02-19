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
package hu.bme.mit.gamma.xsts.codegeneration.c

import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.RealizationMode
import hu.bme.mit.gamma.xsts.codegeneration.c.model.CodeModel
import hu.bme.mit.gamma.xsts.codegeneration.c.model.HeaderModel
import hu.bme.mit.gamma.xsts.codegeneration.c.platforms.IPlatform
import hu.bme.mit.gamma.xsts.codegeneration.c.platforms.Platforms
import hu.bme.mit.gamma.xsts.codegeneration.c.platforms.SupportedPlatforms
import hu.bme.mit.gamma.xsts.codegeneration.c.serializer.VariableDeclarationSerializer
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.transformation.util.VariableGroupRetriever
import java.io.File
import java.math.BigInteger
import java.nio.file.Files
import java.nio.file.Paths
import java.util.Set
import org.eclipse.emf.common.util.URI

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.codegeneration.c.util.GeneratorUtil.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.LowlevelNamings.*

/**
 * The WrapperBuilder class implements the IStatechartCode interface and is responsible for generating the wrapper code.
 */
class WrapperBuilder implements IStatechartCode {
	
	/**
	 * Function pointer generator flag. This flag enables the generation
	 * of function pointers for firing out events as function calls.
	 */
	boolean generatePointers
	
	/**
	 * The XSTS (Extended Symbolic Transition Systems) used for code generation.
	 */
	XSTS xsts
	/**
 	 * The name of the wrapper component.
 	 */
	String name
	/**
 	 * The name of the original statechart.
	 */
	String stName
	
	/**
	 * The code model for generating wrapper code.
	 */
	CodeModel code
	/**
	 * The header model for generating wrapper code.
 	 */
	HeaderModel header
	/**
	 * The Gamma component
	 */
	Component component
	
	/**
	 * The supported platform for code generation.
	 */
	SupportedPlatforms platform = SupportedPlatforms.UNIX
	
	/* Serializers used for code generation */
	val ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	val VariableGroupRetriever variableGroupRetriever = VariableGroupRetriever.INSTANCE
	val VariableDeclarationSerializer variableDeclarationSerializer = VariableDeclarationSerializer.INSTANCE
	
	/**
	 * The set of input variable declarations.
	 */
	val Set<VariableDeclaration> inputs = newHashSet
	/**
	 * The set of output variable declarations.
 	 */
	val Set<VariableDeclaration> outputs = newHashSet
	
	/**
     * Constructs a WrapperBuilder object.
     * 
     * @param xsts The XSTS (Extended Symbolic Transition Systems) used for wrapper code generation.
     */
	new(Component component, XSTS xsts, boolean generatePointers) {
		this.xsts = xsts
		this.name = xsts.name.toFirstUpper + "Wrapper"
		this.stName = xsts.name + "Statechart"
		this.generatePointers = generatePointers
		this.component = component
		
		/* code files */
		this.code = new CodeModel(name)
		this.header = new HeaderModel(name)
		
		/* in & out events and parameters in a unique set, these sets are being used to generate setters/getters representing ports */
		/* important! in the wrapper we need every parameter regardless of persistency */
		inputs += variableGroupRetriever.getSystemInEventVariableGroup(xsts).variables
		inputs += variableGroupRetriever.getSystemInEventParameterVariableGroup(xsts).variables
		outputs += variableGroupRetriever.getSystemOutEventVariableGroup(xsts).variables
		outputs += variableGroupRetriever.getSystemOutEventParameterVariableGroup(xsts).variables
	}
	
	/**
     * Sets the platform for code generation.
     * 
     * @param platform the platform
     */
	override setPlatform(SupportedPlatforms platform) {
		this.platform = platform
	}
	
	/**
     * Constructs the statechart wrapper's header code.
     */
	override constructHeader() {
		/* Add imports to the file */
		header.addInclude('''
			#include <stdint.h>
			«IF xsts.async»#include <string.h>«ENDIF»
			#include <stdbool.h>
			«Platforms.get(platform).getHeaders()»
			
			#include "«xsts.name.toLowerCase».h"
		''');
		
		/* Max value before overflow */
		header.addContent('''
			#define UINT32_MAX_VALUE 4294967295           // 32 bit unsigned
			#define UINT64_MAX_VALUE 18446744073709551615 // 64 bit unsigned
		''')
		
		/* Wrapper Struct */
		header.addContent('''
			/* Forward declaration of «name» */
			typedef struct «name»;

			/* Wrapper for statechart «stName» */
			typedef struct {
				«stName» «stName.toLowerCase»;
				«Platforms.get(platform).getStruct()»
				«IF generatePointers» «FOR port : component.ports.filter[it.interfaceRealization.realizationMode == RealizationMode.PROVIDED]»
					«FOR event : port.interfaceRealization.interface.events SEPARATOR System.lineSeparator»void (*event«event.event.getOutputName(port).toFirstUpper»)(«FOR param : event.event.parameterDeclarations SEPARATOR ', '»«variableDeclarationSerializer.serialize(param.type, false, param.name)»«ENDFOR»);«ENDFOR»
				«ENDFOR»«ENDIF»
				uint32_t (*getElapsed)(struct «name»*);
			} «name»;
		''');
		
		/* Initialization & Cycle declaration */
		header.addContent('''
			/* Initialize component «name» */
			void initialize«name»(«name» *statechart);
			/* Calculate Timeout events */
			void time«name»(«name»* statechart);
			/* Run cycle of component «name» */
			void runCycle«name»(«name»* statechart);
		''');
		
		/* Out events */
		header.addContent('''
			«FOR port : component.ports.filter[it.interfaceRealization.realizationMode == RealizationMode.PROVIDED] SEPARATOR System.lineSeparator»«FOR event : port.interfaceRealization.interface.events SEPARATOR System.lineSeparator»
				/* Out event block of «event.event.name» at port «port.name» */
				bool «event.event.getOutputName(port)»(«name»* statechart);
				«FOR param : event.event.parameterDeclarations»
					«variableDeclarationSerializer.serialize(param.type, false, param.name)» «event.event.getOutputName(port)»_«param.name»(«name»* statechart);
				«ENDFOR»
				/* End of block «event.event.name» at port «port.name» */
			«ENDFOR»«ENDFOR»
		''')
		
		/* In events */
		header.addContent('''
			«FOR port : component.ports.filter[it.interfaceRealization.realizationMode == RealizationMode.REQUIRED] SEPARATOR System.lineSeparator»«FOR event : port.interfaceRealization.interface.events SEPARATOR System.lineSeparator»
				/* In event block of «event.event.name» at port «port.name» */
				void «event.event.getInputName(port)»(«name»* statechart, bool value«FOR param : event.event.parameterDeclarations», «variableDeclarationSerializer.serialize(param.type, false, param.name)» «param.name»«ENDFOR»);
				/* End of block «event.event.name» at port «port.name» */
			«ENDFOR»«ENDFOR»
		''')

	}
	
	/**
     * Constructs the statechart wrapper's C code.
     */
	override constructCode() {
		/* Add imports to the file */
		code.addInclude('''
			#include <stdlib.h>
			#include <stdbool.h>
			
			#include "«name.toLowerCase».h"
		''');
		
		/* Initialize wrapper & Run cycle*/
		code.addContent('''
			/* Platform dependent time measurement */
			uint32_t getElapsed(«name»* statechart) {
				«Platforms.get(platform).getTimer()»
				return «IPlatform.CLOCK_VARIABLE_NAME»;
			}
			
			/* Initialize component «name» */
			void initialize«name»(«name»* statechart) {
				statechart->getElapsed = &getElapsed;
				«Platforms.get(platform).getInitialization()»
				reset«stName»(&statechart->«stName.toLowerCase»);
				initialize«stName»(&statechart->«stName.toLowerCase»);
				entryEvents«stName»(&statechart->«stName.toLowerCase»);
			}
			
			/* Calculate Timeout events */
			void time«name»(«name»* statechart) {
				uint32_t «IPlatform.CLOCK_VARIABLE_NAME» = statechart->getElapsed(statechart);
				«FOR variable : variableGroupRetriever.getTimeoutGroup(xsts).variables»
					/* Overflow detection in «variable.name» */
					if ((«IF new BigInteger(variable.getInitialValueEvaluated(xsts).toString) > VariableDeclarationSerializer.UINT32_MAX»UINT64_MAX_VALUE«ELSE»UINT32_MAX_VALUE«ENDIF» - «IPlatform.CLOCK_VARIABLE_NAME») < statechart->«stName.toLowerCase».«variable.name») {
						statechart->«stName.toLowerCase».«variable.name» = «variable.getInitialValueSerialized(xsts)»;
					}
					/* Add elapsed time to timeout variable «variable.name» */
					statechart->«stName.toLowerCase».«variable.name» += «IPlatform.CLOCK_VARIABLE_NAME»;
				«ENDFOR»
			}
		''');
		
		if (generatePointers) {
			code.addContent('''
				void checkEventFiring(«name»* statechart) {
					«FOR port : component.ports.filter[it.interfaceRealization.realizationMode == RealizationMode.PROVIDED]»
						«FOR event : port.interfaceRealization.interface.events»
							if («getXstsVariableName(xsts, component, port, event)» && statechart->event«event.event.getOutputName(port).toFirstUpper» != NULL) {
								statechart->event«event.event.getOutputName(port).toFirstUpper»(«FOR param : event.event.parameterDeclarations SEPARATOR ', '»statechart->«stName.toLowerCase».«component.getBindingByCompositeSystemPort(port.name).instancePortReference.port.name»_«event.event.name»_«port.realization»_«param.name»_«component.getBindingByCompositeSystemPort(port.name).instancePortReference.instance.name»«ENDFOR»);
							}
						«ENDFOR»
					«ENDFOR»
				}
			''');
		}
		
		code.addContent('''
		/* Run cycle of component «name» */
		void runCycle«name»(«name»* statechart) {
			time«name»(statechart);
			runCycle«stName»(&statechart->«stName.toLowerCase»);
			«IF generatePointers»checkEventFiring(statechart);«ENDIF»
		}
		''')
		
		/* Out events */
		code.addContent('''
			«FOR port : component.ports.filter[it.interfaceRealization.realizationMode == RealizationMode.PROVIDED] SEPARATOR System.lineSeparator»«FOR event : port.interfaceRealization.interface.events SEPARATOR System.lineSeparator»
				/* Out event block of «event.event.name» at port «port.name» */
				bool «event.event.getOutputName(port)»(«name»* statechart) {
					return «getXstsVariableName(xsts, component, port, event)»;
					//return statechart->«stName.toLowerCase».«component.getBindingByCompositeSystemPort(port.name).instancePortReference.port.name»_«event.event.name»_«port.realization»_«component.getBindingByCompositeSystemPort(port.name).instancePortReference.instance.name»;
				}
				«FOR param : event.event.parameterDeclarations»
					«variableDeclarationSerializer.serialize(param.type, false, param.name)» «event.event.getOutputName(port)»_«param.name»(«name»* statechart) {
						return «getXstsParameterName(xsts, component, port, event, param)»;
						//return statechart->«stName.toLowerCase».«component.getBindingByCompositeSystemPort(port.name).instancePortReference.port.name»_«event.event.name»_«port.realization»_«param.name»_«component.getBindingByCompositeSystemPort(port.name).instancePortReference.instance.name»;
					}
				«ENDFOR»
				/* End of block «event.event.name» at port «port.name» */
			«ENDFOR»«ENDFOR»
		''')
		
		/* In events */
		code.addContent('''
			«FOR port : component.ports.filter[it.interfaceRealization.realizationMode == RealizationMode.REQUIRED] SEPARATOR System.lineSeparator»«FOR event : port.interfaceRealization.interface.events SEPARATOR System.lineSeparator»
				/* In event block of «event.event.name» at port «port.name» */
				void «event.event.getInputName(port)»(«name»* statechart, bool value«FOR param : event.event.parameterDeclarations», «variableDeclarationSerializer.serialize(param.type, false, param.name)» «param.name»«ENDFOR») {
					«IF xsts.async && component.getBindingByCompositeSystemPort(port.name).instancePortReference.instance.derivedType instanceof AsynchronousAdapter»
						«FOR queue : (component.getBindingByCompositeSystemPort(port.name).instancePortReference.instance.derivedType as AsynchronousAdapter).messageQueues»
							if (statechart->«stName.toLowerCase».sizeMaster«queue.name.toFirstUpper»Of«component.getBindingByCompositeSystemPort(port.name).instancePortReference.instance.name» < «expressionEvaluator.evaluate(queue.capacity)») {
								int32_t temp[«expressionEvaluator.evaluate(queue.capacity)»] = {«queue.getEventId(queue.storedEvents.filter[it.value == event.event].head)»«FOR index : 0 .. expressionEvaluator.evaluate(queue.capacity) - 1», statechart->«stName.toLowerCase».master_«queue.name»Of«component.getBindingByCompositeSystemPort(port.name).instancePortReference.instance.name»[«index»]«ENDFOR»};
								memcpy(statechart->«stName.toLowerCase».master_«queue.name»Of«component.getBindingByCompositeSystemPort(port.name).instancePortReference.instance.name», temp, sizeof(statechart->«stName.toLowerCase».master_«queue.name»Of«component.getBindingByCompositeSystemPort(port.name).instancePortReference.instance.name»));
							}
						«ENDFOR»
					«ENDIF»
					«getXstsVariableName(xsts, component, port, event)» = value;
					//statechart->«stName.toLowerCase».«component.getBindingByCompositeSystemPort(port.name).instancePortReference.port.name»_«event.event.name»_«port.realization»_«component.getBindingByCompositeSystemPort(port.name).instancePortReference.instance.name» = value;
					«FOR param : event.event.parameterDeclarations»
						«getXstsParameterName(xsts, component, port, event, param)» = «param.name»;
						//statechart->«stName.toLowerCase».«component.getBindingByCompositeSystemPort(port.name).instancePortReference.port.name»_«event.event.name»_«port.realization»_«param.name»_«component.getBindingByCompositeSystemPort(port.name).instancePortReference.instance.name» = «param.name»;
					«ENDFOR»
				}
				/* End of block «event.event.name» at port «port.name» */
			«ENDFOR»«ENDFOR»
		''')
		
	}
	
	/**
     * Saves the generated wrapper code and header models to the specified URI.
     * 
     * @param uri the URI to save the models to
     */
	override save(URI uri) {
		/* create src-gen if not present */
		var URI local = uri.appendSegment("src-gen")
		if (!new File(local.toFileString()).exists())
			Files.createDirectories(Paths.get(local.toFileString()))
			
		/* create c codegen folder if not present */
		local = local.appendSegment(xsts.name.toLowerCase)
		if (!new File(local.toFileString()).exists())
			Files.createDirectories(Paths.get(local.toFileString()))
		
		/* save models */
		code.save(local)
		header.save(local)
	}
	
	
	
}