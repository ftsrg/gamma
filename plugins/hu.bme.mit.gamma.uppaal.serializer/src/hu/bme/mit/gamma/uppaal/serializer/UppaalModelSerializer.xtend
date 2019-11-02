/********************************************************************************
 * Copyright (c) 2018 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.uppaal.serializer

import java.io.FileWriter
import java.io.IOException
import java.util.Map
import java.util.logging.Level
import java.util.logging.Logger
import uppaal.NTA
import uppaal.declarations.DataVariableDeclaration
import uppaal.declarations.FunctionDeclaration
import uppaal.declarations.TypeDeclaration
import uppaal.declarations.VariableDeclaration

import static extension hu.bme.mit.gamma.uppaal.serializer.ExpressionTransformer.*
import uppaal.types.StructTypeSpecification
import java.io.File

/**
 * The class is responsible for serializing the UPPAAL model conforming to the metamodel defined by the de.uni_paderborn.uppaal plugin,
 *  to an XML file, that can be loaded by the UPPAAL.
 * 
 * The serialization is done by specifying the format of the output in character
 * sequences, and each model element is inserted to its place. 
 * 
 * The class has only static fields and methods, because it does not store
 * anything.
 * 
 * @author Benedek Horvath, Bence Graics
 */
class UppaalModelSerializer {
	
	/**
	 * Save the UPPAAL model specified by the UppaalModelBuilder to an XML file,
	 * denoted by its file path. The created XML file can be loaded by the
	 * UPPAAL.
	 * 
	 * @param filepath
	 *            The path for the output file. It contains the file name also,
	 *            except for the file extension.
	 */
	def static saveToXML(NTA nta, String parentFolder, String fileName) {
		try {
			var fw = new FileWriter(parentFolder + File.separator + fileName)
			val header = createHeader(nta)
			val body = createTemplate(nta)
			val footer = createFooter(nta)
			fw.write(header.toString + body.toString + footer)
			fw.close
			// Information message, about the completion of the transformation.
			Logger.getLogger("GammaLogger").log(Level.INFO, "The serialization has been finished.")
		} catch (IOException ex) {
			Logger.getLogger("GammaLogger").log(Level.SEVERE, "An error occurred, while creating the XML file. " + ex.message)
		}
	}
	
	/**
	 * Creates some easy temporal logical queries checking deadlock and the reachability of the states.
	 * The created q file can be loaded by the UPPAAL.
	 * @param states The names of the states in the TTMC model.
	 * @param filepath
	 *            The path for the output file. It contains the file name also,
	 *            except for the file extension.
	 */
	def static createStateReachabilityQueries(Map<String, String[]> states, String suffix, String parentFolder, String fileName) {
		try {
			var writer = new FileWriter(parentFolder + File.separator + fileName, true)
			val deadlockQuery = createDeadlockQuery
			val reachabilityQueries = createStateReachabilityQueries(states, suffix)
			writer.append(deadlockQuery.toString + reachabilityQueries.toString)
			writer.close
			// information message, about the completion of the transformation.
			Logger.getLogger("GammaLogger").log(Level.INFO, "Query generations have been finished.")
		} catch (IOException ex) {
			Logger.getLogger("GammaLogger").log(Level.SEVERE, "An error occurred, while creating the q file. " + ex.message)
		}
	}
	
	
	/**
	 * Creates some easy temporal logical queries checking the fireability of the transitions.
	 * The created q file can be loaded by the UPPAAL.
	 * @param states The names of the states in the TTMC model.
	 * @param filepath
	 *            The path for the output file. It contains the file name also,
	 *            except for the file extension.
	 */
	def static createTransitionFireabilityQueries(String variableName, int maxId, String suffix,
			String parentFolder, String fileName) {
		try {
			var writer = new FileWriter(parentFolder + File.separator + fileName, true)
			val fireabilityQueries = createTransitionFireabilityQueries(variableName, maxId, suffix)
			writer.append(fireabilityQueries.toString)
			writer.close
			// information message, about the completion of the transformation.
			Logger.getLogger("GammaLogger").log(Level.INFO, "Query generations have been finished.")
		} catch (IOException ex) {
			Logger.getLogger("GammaLogger").log(Level.SEVERE, "An error occurred, while creating the q file. " + ex.message)
		}
	}
	/**
	 * Create the header and the beginning of the XML file, that contains 
	 * the declaration of the top-level UPPAAL module (NTA) and the global 
	 * declarations as well.
	 * 
	 * @return The header of the XML file in a char sequence.
	 */
	private def static createHeader(NTA nta) '''
«««		For some reason if this header is in, the xml file cannot be parsed
«««		<?xml version="1.0" encoding="utf-8"?>
«««		<!DOCTYPE nta PUBLIC '-//Uppaal Team//DTD Flat System 1.1//EN' 'http://www.it.uu.se/research/group/darts/uppaal/flat-1_1.dtd'>
		<nta>
		<declaration>
		
		«FOR declaration : nta.globalDeclarations.declaration.filter(TypeDeclaration) SEPARATOR "\n"»
			«IF declaration.typeDefinition instanceof StructTypeSpecification»
				typedef struct { 
					«declaration.typeDefinition.serializeTypeDefinition»
				} «FOR type : declaration.type»«type.serializeType»«ENDFOR»;
			«ENDIF»
		«ENDFOR»
		
		«FOR declaration : nta.globalDeclarations.declaration.filter(VariableDeclaration)
//				.sortBy[it.variable.head.name] /* Declaration order is crucial, it must not be reordered */ 
				SEPARATOR "\n"»
			«declaration.serializeVariable»
		«ENDFOR»
		
		«FOR function : nta.globalDeclarations.declaration.filter(FunctionDeclaration).map[it.function] SEPARATOR "\n"»
			«function.returnType.serializeTypeDefinition» «function.name»(«FOR param : function.parameter SEPARATOR ", "»«param.variableDeclaration.typeDefinition.serializeTypeDefinition»«param.callType.serializeCallType» «param.variableDeclaration.variable.head.name»«ENDFOR») {
				«IF function.block.declarations !== null»
					«FOR declaration : function.block.declarations.declaration.filter(DataVariableDeclaration)»
						«declaration.serializeVariable»
					«ENDFOR»
				«ENDIF»
				«FOR statement : function.block.statement»
					«statement.transformStatement»
				«ENDFOR»
			}
		«ENDFOR»
		
		</declaration>
	'''	
	
	/**
	 * Create the main part of the XML file: the Template, and locations and the 
	 * edges within the Template. All the data for the serialization are fetched 
	 * from the UppaalModelBuilder.
	 * 
	 * @return The main part of the XML file in a char sequence.
	 */
	private def static createTemplate(NTA nta) '''
		«FOR template : nta.template SEPARATOR "\n"»
		<template>
		<name>
		«template.name»
		</name>
		«IF !template.declarations.declaration.filter(VariableDeclaration).empty»
«««			This IF is due to an UPPAAL bug: if there is an empty declaration tag, UPPAAL throws
«««			a nullptr exception upon opening the declaration of a template in the editor
			<declaration>
			«FOR variableDeclaration : template.declarations.declaration.filter(VariableDeclaration) SEPARATOR "\n"»
				«variableDeclaration.serializeVariable»
			«ENDFOR»
			</declaration>
		«ENDIF»
		«FOR location : template.location SEPARATOR "\n"»
		<location id="«location.name»">
		<name>
		«location.name»
		</name>
		«IF !(location.invariant === null)»
		<label kind="invariant">
		«location.invariant.transform»
		</label>
		«ENDIF»
		«IF !(location.comment === null)»
		<label kind="comments">
		«location.comment»
		</label>
		«ENDIF»
		«IF (location.locationTimeKind.literal.equals("COMMITED"))»
		<committed/>
		«ENDIF»
		«IF (location.locationTimeKind.literal.equals("URGENT"))»
		<urgent/>
		«ENDIF»
		</location>
		«ENDFOR»
		<init ref="«template.init.name»"/>
		
		«FOR transition : template.edge SEPARATOR "\n"»
		<transition>
		<source ref="«transition.source.name»"/>
		<target ref="«transition.target.name»"/>
		«IF !(transition.guard === null)»
		<label kind="guard">«transition.guard.transform»</label>
		«ENDIF»
		«IF !(transition.synchronization === null)»
		<label kind="synchronisation">«transition.synchronization.channelExpression.identifier.name»«transition.synchronization.kind.literal»</label>
		«ENDIF»
		«IF !(transition.update === null)»
		<label kind="assignment">«FOR anUpdate : transition.update SEPARATOR ",\n"»«anUpdate.transform»«ENDFOR»</label>
		«ENDIF»
		«IF !(transition.comment === null)»
		<label kind="comments">«transition.comment»</label>
		«ENDIF»
		</transition>
		«ENDFOR»
		</template>
		«ENDFOR»
	'''
	 
	
	/**
	 * Create the footer of the XML file, which contains the instantiation of 
	 * the recently created Template. The instance of the Template is called
	 * "Process" in this implementation.
	 * 
	 * @return The footer of the XML file in a char sequence.
	 */
	private def static createFooter(NTA nta) '''		
		<system>
			«FOR template : nta.template SEPARATOR "\n"»
				«template.name.processNameOfTemplate» = «template.name»();
			«ENDFOR»
«««			The instantiation list needs reversing as they are declared in a decreasing priority			
			system «FOR instantiationList : nta.systemDeclarations.system.instantiationList.reverseView SEPARATOR " &lt; "»«FOR instantiation : instantiationList.template SEPARATOR ", "»«instantiation.name.processNameOfTemplate»«ENDFOR»«ENDFOR»;
		</system>
	</nta>
	'''
	
	/**
	 * Returns a query that checks whether there is a possibility of deadlock in the model
	 */
	private def static createDeadlockQuery() '''
		A[] not deadlock
	'''
	
	/**
	 * Returns a set of queries that checks whether the location equivalent of states are reachable in the model.
	 * It does not generate queries for LocalReactionStates.
	 */
	private def static createStateReachabilityQueries(Map<String, String[]> templateLocationsMap, String suffix) '''
		«FOR templateLocations : templateLocationsMap.entrySet.sortBy[it.key]»
			«FOR state : templateLocations.value.filter[!it.startsWith("LocalReactionState")].sort»
				E<> «templateLocations.key.processNameOfTemplate».«state»«IF suffix !== null»«IF !suffix.nullOrEmpty» && «suffix»«ENDIF»«ENDIF»
			«ENDFOR»
		«ENDFOR»
	'''
	
	/**
	 * Converts the template name to process name.
	 */
	private def static getProcessNameOfTemplate(String templateName) '''
		P_«templateName»'''
		
	/**
	 * Returns a set of queries that checks whether the location equivalent of states are reachable in the model.
	 * It does not generate queries for LocalReactionStates.
	 */
	private def static createTransitionFireabilityQueries(String variableName, int maxId, String suffix) '''
		«FOR i : 0 ..< maxId»
			E<> «variableName» == «i»«IF !suffix.nullOrEmpty» && «suffix»«ENDIF»
		«ENDFOR»
	'''

}
