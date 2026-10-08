/********************************************************************************
 * Copyright (c) 2018-2026 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.codegeneration.java

import hu.bme.mit.gamma.codegeneration.java.util.Namings
import hu.bme.mit.gamma.codegeneration.java.util.TypeDeclarationSerializer
import hu.bme.mit.gamma.codegeneration.java.util.TypeSerializer
import hu.bme.mit.gamma.expression.model.LambdaDeclaration
import hu.bme.mit.gamma.expression.model.TupleTypeDefinition
import hu.bme.mit.gamma.expression.util.ComplexTypeUtil
import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures
import hu.bme.mit.gamma.xsts.model.ProcedureDeclaration
import hu.bme.mit.gamma.xsts.model.XSTS

import static extension hu.bme.mit.gamma.codegeneration.java.util.Namings.*
import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class StatechartCodeGenerator {
	
	final String BASE_PACKAGE_NAME
	final String STATECHART_PACKAGE_NAME
	final String CLASS_NAME
	
	final StatechartDefinition gammaStatechart // Needed for the type declarations and interface functions
	final XSTS xSts
	
	final extension TypeDeclarationSerializer typeDeclarationSerializer = TypeDeclarationSerializer.INSTANCE
	final extension TypeSerializer typeSerializer = TypeSerializer.INSTANCE
	final extension VariableDiagnoser variableDiagnoser = VariableDiagnoser.INSTANCE
	final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	final extension ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE
	final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	final extension ComplexTypeUtil complexTypeUtil = ComplexTypeUtil.INSTANCE
	
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
		«val containsTuples = xSts.containsTypeTransitively(TupleTypeDefinition)»
		
		«FOR _package : gammaStatechart.containingPackage.importsWithComponentsOrInterfacesOrTypes.toSet»
			import «_package.getPackageString(BASE_PACKAGE_NAME)».*;
		«ENDFOR»
		«IF containsTuples»
			import java.util.List;
			import java.util.ArrayList;
		«ENDIF»
		
		public class «CLASS_NAME» {
			
			«FOR typeDeclaration : privateTypeDeclarations»
				«typeDeclaration.serialize»
			«ENDFOR»
«««			Not timeout variables
			«FOR variableDeclaration : xSts.retrieveNotTimeoutVariables»
				private «variableDeclaration.type.serialize» «variableDeclaration.name»;
			«ENDFOR»
«««			Timeout variables		
			«FOR variableDeclaration : xSts.retrieveTimeouts»
				private long «variableDeclaration.name»;
			«ENDFOR»
«««			Wrapper statechart
			private «gammaStatechart.componentClassName» wrapper;
			
			public «CLASS_NAME»(«FOR parameter : xSts.retrieveComponentParameters»«
					parameter.type.serialize» «parameter.name», «ENDFOR»«gammaStatechart.componentClassName» wrapper) {
				«FOR parameter : xSts.retrieveComponentParameters»
					this.«parameter.name» = «parameter.name»;
				«ENDFOR»
				this.wrapper = wrapper;
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
						.reject[xSts.retrieveComponentParameters.contains(it)])»
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
			
«««			No separation of variables at this level (apart from type)
			«FOR variable : xSts.variableGroups
					.map[it.variables]
					.flatten SEPARATOR System.lineSeparator»
				public void set«variable.name.toFirstUpper»(«IF variable.clock»long«ELSE»«variable.type.serialize»«ENDIF» «variable.name») {
					this.«variable.name» = «variable.name»;
				}
				
				public «IF variable.clock»long«ELSE»«variable.type.serialize»«ENDIF» get«variable.name.toFirstUpper»() {
					return «variable.name»;
				}
			«ENDFOR»
			
			public void runCycle() {
				clearOutEvents();
				changeState();
				clearInEvents();
			}
			
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
			
			«FOR function : xSts.functionDeclarations.filter[XstsDerivedFeatures.hasDefinition(it)]»
				protected «function.type.serialize» «function.name»(«
						FOR parameter : function.parameterDeclarations SEPARATOR ', '»«parameter.type.serialize» «parameter.name»«ENDFOR») {
					«IF function instanceof LambdaDeclaration»
						return «function.expression.serialize»;
					«ELSEIF function instanceof ProcedureDeclaration»
						«function.body.serialize»
					«ENDIF»
				}
				
			«ENDFOR»
			«FOR port : gammaStatechart.allPorts.filter[it.required]»
				«FOR function : port.allFunctionDeclarations»
					«val xStsFunctionName = port.name + "_" + function.name»
					«IF xStsFunctionName.defined»
					«ELSE»
					protected «IF function.complex»List<Object>«ELSE»«function.type.serialize»«ENDIF» «xStsFunctionName»(«
							FOR parameter : function.parameterDeclarations SEPARATOR ', '»«
							var i = 0»«
							FOR nativeType : parameter.nativeTypes SEPARATOR ", "»«
								nativeType.serialize» «parameter.name»_«i++»«ENDFOR»«ENDFOR») {
						var listeners = wrapper.get«port.name.toFirstUpper»().getRegisteredListeners();
						var listener = listeners.getFirst(); // Shall be one
						«IF !function.isVoid»return «ENDIF»«
								IF xStsFunctionName.defined»«xStsFunctionName»«ELSE»listener.«function.name»«ENDIF»(«
								FOR parameter : function.parameterDeclarations SEPARATOR ", "»«
							var i = 0»«
							FOR nativeType : parameter.nativeTypes SEPARATOR ", "»«
								parameter.name»_«i++»«ENDFOR»«ENDFOR»)«IF function.complex».toList()«ENDIF»;
					}
					«ENDIF»
					
				«ENDFOR»
			«ENDFOR»
			«IF containsTuples»
				«val listName = "flattenedList"»
				private List<Object> «Namings.FLATTEN_LIST_METHOD_NAME»(List<?> list) {
					List<Object> «listName» = new ArrayList<Object>();
					
					for (Object object : list) {
						if (object instanceof List<?> sublist) {
							«listName».addAll(
									«Namings.FLATTEN_LIST_METHOD_NAME»(sublist));
						}
						else {
							«listName».add(object);
						}
					}
					
					return «listName»;
				}
				
			«ENDIF»
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
	
	private def isDefined(String functionName) {
		return xSts.functionDeclarations.filter[XstsDerivedFeatures.hasDefinition(it)]
				.exists[it.name == functionName]
	}
	
	private def getPrivateTypeDeclarations() {
		val privateTypeDeclarations = newArrayList
		privateTypeDeclarations += xSts.typeDeclarations
		privateTypeDeclarations -= xSts.publicTypeDeclarations
		return privateTypeDeclarations
	}
	
	def getClassName() {
		return CLASS_NAME
	}
	
}