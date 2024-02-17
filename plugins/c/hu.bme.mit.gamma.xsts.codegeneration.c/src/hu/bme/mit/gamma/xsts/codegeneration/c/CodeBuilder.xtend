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
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.xsts.codegeneration.c.model.CodeModel
import hu.bme.mit.gamma.xsts.codegeneration.c.model.HeaderModel
import hu.bme.mit.gamma.xsts.codegeneration.c.platforms.SupportedPlatforms
import hu.bme.mit.gamma.xsts.codegeneration.c.serializer.ActionSerializer
import hu.bme.mit.gamma.xsts.codegeneration.c.serializer.ExpressionSerializer
import hu.bme.mit.gamma.xsts.codegeneration.c.serializer.TypeDeclarationSerializer
import hu.bme.mit.gamma.xsts.codegeneration.c.serializer.VariableDeclarationSerializer
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.transformation.util.VariableGroupRetriever
import java.io.File
import java.nio.file.Files
import java.nio.file.Paths
import java.util.List
import java.util.Set
import org.eclipse.emf.common.util.URI

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*

/**
 * The {@code CodeBuilder} class implements the {@code IStatechartCode} interface and is responsible for generating C code from an XSTS model.
 */
class CodeBuilder implements IStatechartCode {

	/**
	 * The XSTS (Extended Symbolic Transition Systems) used for code generation.
	 */
	XSTS xsts;
	/**
 	 * The name of the component.
 	 */
	String name;
	/**
 	 * The name of the statechart.
	 */
	String stName;

	/**
	 * The code model for generating code.
	 */
	CodeModel code;
	/**
	 * The header model for generating code.
 	 */
	HeaderModel header;

	/**
	 * The supported platform for code generation.
	 */
	SupportedPlatforms platform = SupportedPlatforms.UNIX;

	/* Serializers used for code generation */
	val ActionSerializer actionSerializer = ActionSerializer.INSTANCE;
	val ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE;
	val VariableGroupRetriever variableGroupRetriever = VariableGroupRetriever.INSTANCE;
	val TypeDeclarationSerializer typeDeclarationSerializer = TypeDeclarationSerializer.INSTANCE;
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
	 * The list of components within the system. It is used to determine wether 'statechart->' is neccesarry.
	 */
	public static val List<String> componentVariables = newArrayList;

	/**
     * Constructs a {@code CodeBuilder} object with the given {@code XSTS}.
     * 
     * @param xsts the XSTS (Extended Symbolic Transition Systems) used for code generation
     */
	new(Component component, XSTS xsts) {
		this.xsts = xsts;
		this.name = xsts.name.toFirstUpper;
		this.stName = name + "Statechart";
		
		/* code files */
		this.code = new CodeModel(name);
		this.header = new HeaderModel(name);
		
		/* all non-local variable names */
		xsts.variableDeclarations.forEach [ variableDeclaration |
			componentVariables.add(variableDeclaration.name)
		];
		
		/* in & out events and parameters in a unique set, these sets are being used to reset in/outputs between cycles */
		/* important! only non-persistent parameters are being reset, therefore other parameters will not be included */
		inputs += variableGroupRetriever.getSystemInEventVariableGroup(xsts).variables
		inputs += variableGroupRetriever.getSystemInEventParameterVariableGroup(xsts).variables.filter[it.environmentResettable]
		outputs += variableGroupRetriever.getSystemOutEventVariableGroup(xsts).variables
		outputs += variableGroupRetriever.getSystemOutEventParameterVariableGroup(xsts).variables.filter[it.environmentResettable]
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
     * Constructs the statechart's header code.
     */
	override void constructHeader() {
		/* Add imports to the file */
		header.addInclude('''
			#include <stdint.h>
			#include <stdbool.h>
		''');
		
		/* Enum Type Declarations */
		header.addContent('''
			«FOR typeDeclaration : xsts.typeDeclarations SEPARATOR System.lineSeparator»
				«typeDeclarationSerializer.serialize(typeDeclaration)»
			«ENDFOR»
		''');

		/* Struct Declaration */
		header.addContent('''
			/* Structure representing «name» component */
			typedef struct {
				«FOR variableDeclaration : xsts.variableDeclarations»
					«variableDeclarationSerializer.serialize(variableDeclaration)»
				«ENDFOR»
			} «stName»;
		''');

		/* Declare functions */
		header.addContent('''
			/* Reset component «name» */
			void reset«stName»(«stName»* statechart);
			/* Initialize component «name» */
			void initialize«stName»(«stName»* statechart);
			/* Entry event of component «name» */
			void entryEvents«stName»(«stName»* statechart);
			/* Clear input events of component «name» */
			void clearInEvents«stName»(«stName»* statechart);
			/* Clear output events of component «name» */
			void clearOutEvents«stName»(«stName»* statechart);
			/* Transitions of component «name» */
			void changeState«stName»(«stName»* statechart);
			/* Run cycle in component «name» */
			void runCycle«stName»(«stName»* statechart);
		''');
	}

	/**
     * Constructs the statechart's C code.
     */
	override void constructCode() {
		/* Add imports to the file */
		code.addInclude('''
			#include <stdlib.h>
			#include <string.h>
			#include <stdbool.h>
			
			#include "«name.toLowerCase».h"
			«IF HavocBuilder.isHavocRequired»#include "«name.toLowerCase»havoc.h"«ENDIF»
		''');
		
		/* Reset struct */
		code.addContent('''
			/* Reset component «name» */
			void reset«stName»(«stName»* statechart) {
				«actionSerializer.serialize(xsts.variableInitializingTransition.action)»
			}
		''');

		/* Initialize struct */
		code.addContent('''
			/* Initialize component «name» */
			void initialize«stName»(«stName»* statechart) {
				«actionSerializer.serialize(xsts.configurationInitializingTransition.action)»
			}
		''');

		/* Entry Events */
		code.addContent('''
			/* Entry event of component «name» */
			void entryEvents«stName»(«stName»* statechart) {
				«actionSerializer.serialize(xsts.entryEventTransition.action)»
			}
		''');

		/* Reset In Events */
		code.addContent('''
			/* Clear input events of component «name» */
			void clearInEvents«stName»(«stName»* statechart) {
				«FOR input : inputs SEPARATOR System.lineSeparator»statechart->«input.name» = «expressionSerializer.serialize(input.expression)»;«ENDFOR»
			}
		''');

		/* Reset Out Events */
		code.addContent('''
			/* Clear output events of component «name» */
			void clearOutEvents«stName»(«stName»* statechart) {
				«FOR output : outputs SEPARATOR System.lineSeparator»statechart->«output.name» = «expressionSerializer.serialize(output.expression)»;«ENDFOR»
			}
		''');

		/* Transitions */
		code.addContent('''
			/* Transitions of component «name» */
			void changeState«stName»(«stName»* statechart) {
				«FOR transition : xsts.transitions SEPARATOR System.lineSeparator»«actionSerializer.serialize(transition.action)»«ENDFOR»
			}
		''');

		/* Run cycle */
		code.addContent('''
			/* Run cycle of component «name» */
			void runCycle«stName»(«stName»* statechart) {
				clearOutEvents«stName»(statechart);
				changeState«stName»(statechart);
				clearInEvents«stName»(statechart);
			}
		''');
	}
	
	/**
     * Saves the generated code and header models to the specified URI.
     * 
     * @param uri the URI to save the models to
     */
	override void save(URI uri) {
		/* create src-gen if not present */
		var URI local = uri.appendSegment("src-gen");
		if (!new File(local.toFileString()).exists())
			Files.createDirectories(Paths.get(local.toFileString()));

		/* create c codegen folder if not present */
		local = local.appendSegment(name.toLowerCase)
		if (!new File(local.toFileString()).exists())
			Files.createDirectories(Paths.get(local.toFileString()));

		/* save models */
		code.save(local);
		header.save(local);
	}

}
