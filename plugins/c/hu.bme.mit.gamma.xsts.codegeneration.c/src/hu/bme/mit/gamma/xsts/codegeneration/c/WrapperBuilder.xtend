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

import hu.bme.mit.gamma.expression.model.ClockVariableDeclarationAnnotation
import hu.bme.mit.gamma.expression.model.DeclarationReferenceAnnotation
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.model.impl.DeclarationReferenceAnnotationImpl
import hu.bme.mit.gamma.xsts.codegeneration.c.model.CodeModel
import hu.bme.mit.gamma.xsts.codegeneration.c.model.HeaderModel
import hu.bme.mit.gamma.xsts.codegeneration.c.platforms.IPlatform
import hu.bme.mit.gamma.xsts.codegeneration.c.platforms.Platforms
import hu.bme.mit.gamma.xsts.codegeneration.c.platforms.SupportedPlatforms
import hu.bme.mit.gamma.xsts.codegeneration.c.serializer.ExpressionSerializer
import hu.bme.mit.gamma.xsts.codegeneration.c.serializer.VariableDeclarationSerializer
import hu.bme.mit.gamma.xsts.model.SystemMasterMessageQueueGroup
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.transformation.util.VariableGroupRetriever
import java.io.File
import java.math.BigInteger
import java.nio.file.Files
import java.nio.file.Paths
import java.util.Set
import org.eclipse.emf.common.util.URI

import static extension hu.bme.mit.gamma.xsts.codegeneration.c.util.GeneratorUtil.*

/**
 * The WrapperBuilder class implements the IStatechartCode interface and is responsible for generating the wrapper code.
 */
class WrapperBuilder implements IStatechartCode {
	
	/**
	 * Function pointer generator flag.
	 */
	boolean pointers;
	
	/**
	 * The XSTS (Extended Symbolic Transition Systems) used for code generation.
	 */
	XSTS xsts;
	/**
 	 * The name of the wrapper component.
 	 */
	String name;
	/**
 	 * The name of the original statechart.
	 */
	String stName;
	
	/**
	 * The code model for generating wrapper code.
	 */
	CodeModel code;
	/**
	 * The header model for generating wrapper code.
 	 */
	HeaderModel header;
	
	/**
	 * The supported platform for code generation.
	 */
	SupportedPlatforms platform = SupportedPlatforms.UNIX;
	
	/* Serializers used for code generation */
	val ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE;
	val VariableGroupRetriever variableGroupRetriever = VariableGroupRetriever.INSTANCE;
	val VariableDeclarationSerializer variableDeclarationSerializer = VariableDeclarationSerializer.INSTANCE;
	
	/**
	 * The set of input variable declarations.
	 */
	val Set<VariableDeclaration> inputs = newHashSet;
	/**
	 * The set of output variable declarations.
 	 */
	val Set<VariableDeclaration> outputs = newHashSet;
	
	/**
     * Constructs a WrapperBuilder object.
     * 
     * @param xsts The XSTS (Extended Symbolic Transition Systems) used for wrapper code generation.
     */
	new(XSTS xsts, boolean pointers) {
		this.xsts = xsts
		this.name = xsts.name.toFirstUpper + "Wrapper"
		this.stName = xsts.name + "Statechart"
		this.pointers = pointers
		
		/* code files */
		this.code = new CodeModel(name);
		this.header = new HeaderModel(name);
		
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
		this.platform = platform;
	}
	
	/**
     * Constructs the statechart wrapper's header code.
     */
	override constructHeader() {
		/* Add imports to the file */
		header.addInclude('''
			#include <stdint.h>
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
			/* Wrapper for statechart «stName» */
			typedef struct {
				«stName» «stName.toLowerCase»;
				«Platforms.get(platform).getStruct()»
				«IF pointers»
					«FOR variable : variableGroupRetriever.getSystemOutEventVariableGroup(xsts).variables SEPARATOR System.lineSeparator»void (*event«variable.name.toFirstUpper»)(«variable.declarationReference.map[variableDeclarationSerializer.serialize(it.type, false, it.name) + " " + it.name].join(', ')»);«ENDFOR»
				«ENDIF»
				uint32_t (*getElapsed)(«name»* statechart);
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
		
		/* Setter declarations */
		header.addContent('''
			«FOR variable : inputs»
				/* Setter for «variable.name.toFirstUpper» */
				void set«variable.name.toFirstUpper»(«name»* statechart, «variableDeclarationSerializer.serialize(
					variable.type, 
					variable.annotations.exists[it instanceof ClockVariableDeclarationAnnotation], 
					variable.name
				)» value);
			«ENDFOR»
		''');
		
		/* Getter declarations */
		header.addContent('''
		«FOR variable : outputs»
			/* Getter for «variable.name.toFirstUpper» */
			«variableDeclarationSerializer.serialize(
				variable.type, 
				variable.annotations.exists[it instanceof ClockVariableDeclarationAnnotation], 
				variable.name
			)» get«variable.name.toFirstUpper»(«name»* statechart);
		«ENDFOR»
		''');
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
			/* Initialize component «name» */
			void initialize«name»(«name»* statechart) {
				statechart->getElapsed = &getElapsed;
				«Platforms.get(platform).getInitialization()»
				reset«stName»(&statechart->«stName.toLowerCase»);
				initialize«stName»(&statechart->«stName.toLowerCase»);
				entryEvents«stName»(&statechart->«stName.toLowerCase»);
			}
			
			/* Platform dependent time measurement */
			uint32_t getElapsed(«name»* statechart) {
				«Platforms.get(platform).getTimer()»
				return «IPlatform.CLOCK_VARIABLE_NAME»;
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
			
			/* Run cycle of component «name» */
			void runCycle«name»(«name»* statechart) {
				time«name»(statechart);
				runCycle«stName»(&statechart->«stName.toLowerCase»);
				«IF pointers»checkEventFiring(statechart);«ENDIF»
			}
		''');
		
		if (pointers) {
			code.addContent('''
				void checkEventFiring(«name»* statechart) {
					«FOR variable : variableGroupRetriever.getSystemOutEventVariableGroup(xsts).variables»
						/* Function pointer for «variable.name» */
						if (statechart->«stName.toLowerCase».«variable.name» && statechart->event«variable.name.toFirstUpper» != NULL) {
							statechart->event«variable.name.toFirstUpper»(«variable.declarationReference.map["statechart->" + stName.toLowerCase + "." + it.name].join(', ')»);
						}
					«ENDFOR»
				}
			''');
		}
		
		/* In Events & Parameters */
		code.addContent('''
			«FOR variable : inputs SEPARATOR System.lineSeparator»
				/* Setter for «variable.name.toFirstUpper» */
				void set«variable.name.toFirstUpper»(«name»* statechart, «variableDeclarationSerializer.serialize(
					variable.type, 
					variable.annotations.exists[it instanceof ClockVariableDeclarationAnnotation], 
					variable.name
				)» value) {
					«IF xsts.isAsync»
						«FOR queue : xsts.variableGroups.filter[it.annotation instanceof SystemMasterMessageQueueGroup].head.variables»
							statechart->«stName.toLowerCase».«queue.name»[0] = 0; /* TODO : event id */
						«ENDFOR»
					«ELSE»
						statechart->«stName.toLowerCase».«variable.name» = value;
					«ENDIF»
				}
			«ENDFOR»
		''');

		/* Out Events & Parameters */
		code.addContent('''
		«FOR variable : outputs SEPARATOR System.lineSeparator»
			/* Getter for «variable.name.toFirstUpper» */
			«variableDeclarationSerializer.serialize(
				variable.type, 
				variable.annotations.exists[it instanceof ClockVariableDeclarationAnnotation], 
				variable.name
			)» get«variable.name.toFirstUpper»(«name»* statechart) {
				return statechart->«stName.toLowerCase».«variable.name»;
			}
		«ENDFOR»
		''');
	}
	
	/**
     * Saves the generated wrapper code and header models to the specified URI.
     * 
     * @param uri the URI to save the models to
     */
	override save(URI uri) {
		/* create src-gen if not present */
		var URI local = uri.appendSegment("src-gen");
		if (!new File(local.toFileString()).exists())
			Files.createDirectories(Paths.get(local.toFileString()));
			
		/* create c codegen folder if not present */
		local = local.appendSegment(xsts.name.toLowerCase)
		if (!new File(local.toFileString()).exists())
			Files.createDirectories(Paths.get(local.toFileString()));
		
		/* save models */
		code.save(local);
		header.save(local);
	}
	
	
	
}