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
package hu.bme.mit.gamma.xsts.codegeneration.java

import hu.bme.mit.gamma.codegeneration.java.util.TypeDeclarationSerializer
import hu.bme.mit.gamma.codegeneration.java.util.TypeSerializer
import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.xsts.model.XSTS

import static extension hu.bme.mit.gamma.codegeneration.java.util.Namings.*
import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class StatechartCodeGenerator {
	
	final String BASE_PACKAGE_NAME
	final String STATECHART_PACKAGE_NAME
	final String CLASS_NAME
	
	final StatechartDefinition gammaStatechart // Needed for the type declarations 
	final XSTS xSts
	
	final extension TypeDeclarationSerializer typeDeclarationSerializer = TypeDeclarationSerializer.INSTANCE
	final extension TypeSerializer typeSerializer = TypeSerializer.INSTANCE
	final extension VariableDiagnoser variableDiagnoser = VariableDiagnoser.INSTANCE
	final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	final extension ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE
	// Depending on the xSTS form
	final extension ActionSerializer actionSerializer
	
	new(String basePackageName, String statechartPackageName, String className,
			StatechartDefinition gammaStatechart, XSTS xSts, ActionSerializer actionSerializer) {
		this.BASE_PACKAGE_NAME = basePackageName
		this.STATECHART_PACKAGE_NAME = statechartPackageName
		this.CLASS_NAME = className
		this.gammaStatechart = gammaStatechart
		this.xSts = xSts
		this.actionSerializer = actionSerializer
	}
	
	protected def createStatechartClass() '''
		package «STATECHART_PACKAGE_NAME»;
		
		«FOR _package : gammaStatechart.containingPackage.importsWithComponentsOrInterfacesOrTypes.toSet»
			import «_package.getPackageString(BASE_PACKAGE_NAME)».*;
		«ENDFOR»
		
		public class «CLASS_NAME» {
			
			«FOR typeDeclaration : xSts.privateTypeDeclarations»
				«typeDeclaration.serialize»
			«ENDFOR»
«««			Not timeout variables
			«FOR variableDeclaration : xSts.retrieveNotTimeoutVariables»
				private «variableDeclaration.type.serialize» «variableDeclaration.name»;
			«ENDFOR»
«««			Timeout variables		
			«FOR variableDeclaration : xSts.retrieveTimeouts»
				private «variableDeclaration.type.serialize» «variableDeclaration.name»;
			«ENDFOR»
			
			public «CLASS_NAME»(«FOR parameter : xSts.retrieveComponentParameters SEPARATOR ', '»«parameter.type.serialize» «parameter.name»«ENDFOR») {
				«FOR parameter : xSts.retrieveComponentParameters»
					this.«parameter.name» = «parameter.name»;
				«ENDFOR»
			}
			
			//
			public void reset() {
				this.handleBeforeReset();
				this.resetVariables();
				this.resetStateConfigurations();
				this.raiseEntryEvents();
				this.handleAfterReset();
			}
			
			public void handleBeforeReset() {
«««				Reference variables, e.g., enums, have to be set, as null is not a valid value, including regions: they have to be set to __Inactive__ explicitly on every reset
				«FOR enumVariable : (xSts.retrieveEnumVariables
						.reject[xSts.retrieveComponentParameters.toList.contains(it)])»
					this.«enumVariable.name» = «enumVariable.initialValue.serialize»;
				«ENDFOR»
				clearOutEvents();
				clearInEvents();
			}
			
			public void resetVariables() {
				«xSts.serializeVariableReset»
			}
			
			public void resetStateConfigurations() {
				«xSts.serializeStateConfigurationReset»
			}
			
			public void raiseEntryEvents() {
				«xSts.serializeEntryEventRaise»
			}
			
			public void handleAfterReset() {
				// Empty
			}
			//
			
«««			No separation of variables on this level
			«FOR variable : xSts.variableGroups
					.map[it.variables]
					.flatten SEPARATOR System.lineSeparator»
				public void set«variable.name.toFirstUpper»(«variable.type.serialize» «variable.name») {
					this.«variable.name» = «variable.name»;
				}
				
				public «variable.type.serialize» get«variable.name.toFirstUpper»() {
					return «variable.name»;
				}
			«ENDFOR»
			
			public void runCycle() {
				clearOutEvents();
«««				signalTimePassing(); ««« It causes bugs when the entered timed state is not exited right away on the next run	 
				changeState();
				clearInEvents();
			}
«««			
«««			private void signalTimePassing() {
«««				«FOR timeout : xSts.retrieveTimeouts»
«««					if («timeout.name» == 0) {
«««						«timeout.name» = -1;
«««					}
«««				«ENDFOR»
«««			}

			«xSts.serializeChangeState»
			
			private void clearOutEvents() {
				«FOR event : xSts.retrieveOutEvents»
					«event.name» = false;
				«ENDFOR»
«««				Clearing transient event parameters - why not default expression? (check LowlevelToXstsTransformer)
				«FOR transientOutParameter : xSts.retrieveOutEventParameters.filter[it.environmentResettable]»
					«transientOutParameter.name» = «transientOutParameter.initialValue.serialize»;
				«ENDFOR»
			}
			
			private void clearInEvents() {
				«FOR event : xSts.retrieveInEvents»
					«event.name» = false;
				«ENDFOR»
«««				Clearing transient event parameters - why not default expression? (check LowlevelToXstsTransformer)
				«FOR transientInParameter : xSts.retrieveInEventParameters.filter[it.environmentResettable]»
					«transientInParameter.name» = «transientInParameter.initialValue.serialize»;
				«ENDFOR»
			}
			
			@Override
			public String toString() {
				return
					«FOR variable : xSts.variableGroups
										.map[it.variables]
										.flatten
										SEPARATOR ' + System.lineSeparator() +'»
						"«variable.name» = " + «variable.name»
					«ENDFOR»
				;
			}
			
		}
	'''
	
	private def getPrivateTypeDeclarations(XSTS xSts) {
		val privateTypeDeclarations = newArrayList
		privateTypeDeclarations += xSts.typeDeclarations
		privateTypeDeclarations -= xSts.publicTypeDeclarations
		return privateTypeDeclarations
	} 
		
	def getClassName() {
		return CLASS_NAME
	}
	
}