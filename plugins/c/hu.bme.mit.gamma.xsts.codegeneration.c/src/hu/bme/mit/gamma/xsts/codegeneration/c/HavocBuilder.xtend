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

import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.codegeneration.c.model.CodeModel
import hu.bme.mit.gamma.xsts.codegeneration.c.model.HeaderModel
import hu.bme.mit.gamma.xsts.codegeneration.c.platforms.SupportedPlatforms
import hu.bme.mit.gamma.xsts.model.HavocAction
import hu.bme.mit.gamma.xsts.model.XSTS
import java.io.File
import java.nio.file.Files
import java.nio.file.Paths
import org.eclipse.emf.common.util.URI

import static extension hu.bme.mit.gamma.xsts.codegeneration.c.util.GeneratorUtil.*

class HavocBuilder implements IStatechartCode {
	/**
	 * The XSTS (Extended Symbolic Transition Systems) used for code generation.
	 */
	XSTS xsts
	/**
 	 * The name of the component.
 	 */
	String name
	
	/**
	 * The code model for generating code.
	 */
	CodeModel code
	/**
	 * The header model for generating code.
 	 */
	HeaderModel header
	/**
	 * Whether our XSTS model contains HavocAction-s or not. Enough to compute once.
	 */
	static boolean containsHavocAction = false
	
	/* Serializers used for havoc code generation */
	val GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	
	/* Boundary definitions */
	val INT_MIN = -32768  // -2^15 
	val INT_MAX = 32767   //  2^15 - 1

	val FLOAT_MIN = -32768  // -2^15 
	val FLOAT_MAX = 32767   //  2^15 - 1

	/**
	 * The supported platform for code generation.
	 */
	SupportedPlatforms platform = SupportedPlatforms.UNIX
	
	/**
     * Constructs a {@code HavocBuilder} object with the given {@code XSTS}.
     * 
     * @param xsts the XSTS (Extended Symbolic Transition Systems) used for code generation
     */
	new(Component component, XSTS xsts) {
		this.xsts = xsts
		this.name = xsts.name.toFirstUpper + "Havoc"
		
		/* code files */
		this.code = new CodeModel(name)
		this.header = new HeaderModel(name)
		
		/* parts of the XSTS model that our code generator use */
		val usedParts = newArrayList
		usedParts += xsts.variableInitializingTransition
		usedParts += xsts.configurationInitializingTransition
		usedParts += xsts.entryEventTransition
		usedParts.addAll(xsts.transitions)
		
		/* do those parts contain any havoc actions */
		containsHavocAction = usedParts.exists[type | gammaEcoreUtil.containsType(type, HavocAction)]
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
     * Returns whether the xsts model contains havoc actions or not.
     */
	static def boolean isHavocRequired() {
		return containsHavocAction
	}
	
	/**
     * Constructs the havoc header code.
     */
	override constructHeader() {
		/* Add imports to the file */
		header.addInclude('''
			#include <time.h>
			#include <stdint.h>
			#include <stdbool.h>
			
			#include "«xsts.name.toLowerCase».h"
		''');
		
		/* Declaration of boundaries */
		header.addContent('''
			/* boundaries for int */
			#define INT_MIN «INT_MIN»
			#define INT_MAX «INT_MAX»
			
			/* boundaries for float */
			#define FLOAT_MIN «FLOAT_MIN»
			#define FLOAT_MAX «FLOAT_MAX»
			
			/* boundaries for enums */
			«FOR type : xsts.typeDeclarations»
				#define «type.name.toUpperCase»_LENGTH «type.type.getLength»
			«ENDFOR»
		''');
		
		/* Declaration of functions */
		header.addContent('''
			/* runtime generated random boolean */
			bool havoc_bool();
			/* runtime generated random int */
			int havoc_int();
			/* runtime generated random float */
			float havoc_float();
			«FOR type : xsts.typeDeclarations»
				/* runtime generated random «type.name» */
				enum «type.name.transformString» havoc_«type.name»();
			«ENDFOR»
		''');
	}
	
	/**
     * Constructs the havoc code.
     */
	override constructCode() {
		/* Add imports to the file */
		code.addInclude('''
			#include <stdlib.h>
			#include <stdbool.h>
			
			#include "«name.toLowerCase».h"
		''');
		
		/* Function for generating random values for each type */
		code.addContent('''
			/* runtime generated random boolean */
			bool havoc_bool() {
				srand(time(NULL));
				return rand() % 2 == 0;
			}

			/* runtime generated random int */
			int32_t havoc_int() {
				srand(time(NULL));
				return (rand() % (INT_MAX - INT_MIN + 1)) + INT_MIN;
			}
			
			/* runtime generated random float */
			float havoc_float() {
				srand(time(NULL));
				return ((float)rand() / RAND_MAX) * (FLOAT_MAX - FLOAT_MIN) + FLOAT_MIN;
			}
			
			«FOR type : xsts.typeDeclarations SEPARATOR System.lineSeparator»
				/* runtime generated random «type.name» */
				enum «type.name.transformString» havoc_«type.name»() {
					srand(time(NULL));
					return (enum «type.name.transformString»)(rand() % «type.name.toUpperCase»_LENGTH);
				}
			«ENDFOR»
		''')
	}
	
	/**
     * Saves the generated havoc code and header to the specified URI.
     * Prevents saving if there is no need for havoc functions.
     * 
     * @param uri the URI to save the models to
     */
	override save(URI uri) {
		/* prevent saving in case there is no havoc action */
		if (!HavocBuilder.isHavocRequired()) {
			return
		}
			
		/* create src-gen if not present */
		var URI local = uri.appendSegment("src-gen")
		if (!new File(local.toFileString()).exists()) {
			Files.createDirectories(Paths.get(local.toFileString()))
		}

		/* create c codegen folder if not present */
		local = local.appendSegment(xsts.name.toLowerCase)
		if (!new File(local.toFileString()).exists()) {
			Files.createDirectories(Paths.get(local.toFileString()))
		}

		/* save models */
		code.save(local)
		header.save(local)
	}
	
}