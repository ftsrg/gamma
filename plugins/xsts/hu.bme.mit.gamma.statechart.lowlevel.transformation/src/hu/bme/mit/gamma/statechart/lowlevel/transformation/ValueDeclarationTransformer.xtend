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
package hu.bme.mit.gamma.statechart.lowlevel.transformation

import hu.bme.mit.gamma.expression.model.ConstantDeclaration
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.InitializableElement
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.expression.model.InternalParameterDeclarationAnnotation
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.ParameterDeclarationAnnotation
import hu.bme.mit.gamma.expression.model.ValueDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclarationAnnotation
import hu.bme.mit.gamma.expression.util.ComplexTypeUtil
import hu.bme.mit.gamma.expression.util.FieldHierarchy
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.List

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.LowlevelNamings.*

class ValueDeclarationTransformer {
	// Auxiliary objects
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension TypeTransformer typeTransformer
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ComplexTypeUtil complexTypeUtil = ComplexTypeUtil.INSTANCE
	// Expression factory
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	// Trace needed for variable mappings
	protected final Trace trace
	
	new() { // For external libraries that want to use this class
		this(new Trace)
	}
	
	new(Trace trace) { // For lowlevel statechart transformer
		this.trace = trace
		this.expressionTransformer = new ExpressionTransformer(trace)
		this.typeTransformer = new TypeTransformer(trace)
	}
	
	def transformForParameter(ParameterDeclaration gammaParameter) {
		// This must be an integer parameter
		val typeDefinition = gammaParameter.typeDefinition
		checkState(typeDefinition instanceof IntegerTypeDefinition)
		val lowlevelParameter = gammaParameter.clone
		trace.put(gammaParameter, lowlevelParameter)
		return lowlevelParameter
	}
	
	def List<VariableDeclaration> transformComponentParameter(ParameterDeclaration gammaParameter) {
		val lowlevelVariableNames = gammaParameter.componentParameterNames
		return gammaParameter.transform(lowlevelVariableNames,
			new Tracer {
				override trace(ValueDeclaration value, FieldHierarchy fieldHierarchy,
						VariableDeclaration lowlevelVariable) {
					trace.put(value -> fieldHierarchy, lowlevelVariable)
				}
			}
		)
	}
	
	def List<VariableDeclaration> transformFunctionParameter(ParameterDeclaration gammaParameter) {
		val lowlevelVariableNames = gammaParameter.componentParameterNames
		return gammaParameter.transform(lowlevelVariableNames,
			new Tracer {
				override trace(ValueDeclaration value, FieldHierarchy fieldHierarchy,
						VariableDeclaration lowlevelVariable) {
					trace.put(value -> fieldHierarchy, lowlevelVariable)
				}
			}
		)
	}
	
	def List<VariableDeclaration> transformInParameter(ParameterDeclaration gammaParameter, Port gammaPort) {
		val lowlevelVariableNames = gammaParameter.getInNames(gammaPort)
		return gammaParameter.transform(lowlevelVariableNames, 
			new Tracer {
				override trace(ValueDeclaration value, FieldHierarchy fieldHierarchy,
						VariableDeclaration lowlevelVariable) {
					trace.putInParameter(gammaPort, gammaParameter.containingEvent,
						gammaParameter -> fieldHierarchy, lowlevelVariable)
				}
			}
		)
	}
	
	def List<VariableDeclaration> transformOutParameter(ParameterDeclaration gammaParameter, Port gammaPort) {
		val lowlevelVariableNames = gammaParameter.getOutNames(gammaPort)
		return gammaParameter.transform(lowlevelVariableNames, 
			new Tracer {
				override trace(ValueDeclaration value, FieldHierarchy fieldHierarchy,
						VariableDeclaration lowlevelVariable) {
					trace.putOutParameter(gammaPort, gammaParameter.containingEvent,
						gammaParameter -> fieldHierarchy, lowlevelVariable)
				}
			}
		)
	}
	
	private def List<VariableDeclaration> transform(ParameterDeclaration gammaParameter,
			List<String> lowlevelVariableNames, Tracer tracer) {
		val lowlevelVariables = gammaParameter.transformValue(tracer)
		lowlevelVariables.nameLowlevelVariables(lowlevelVariableNames)
		return lowlevelVariables
	}

	def List<VariableDeclaration> transform(ConstantDeclaration gammaConstant) {
		val lowlevelVariables = gammaConstant.transformValue(
			new Tracer {
				override trace(ValueDeclaration value, FieldHierarchy fieldHierarchy,
						VariableDeclaration lowlevelVariable) {
					trace.put(value -> fieldHierarchy, lowlevelVariable)
				}
			}
		)
		// Adding annotation to denote that these are final variables
		for (lowlevelVariable : lowlevelVariables) {
			lowlevelVariable.annotations += createFinalVariableDeclarationAnnotation
		}
		// Constant variable names do not really matter in terms of traceability
		val lowlevelVariableNames = gammaConstant.names
		lowlevelVariables.nameLowlevelVariables(lowlevelVariableNames)
		//
		return lowlevelVariables
	}
	
	def List<VariableDeclaration> transform(VariableDeclaration gammaVariable) {
		val lowlevelVariables = gammaVariable.transformValue(
			new Tracer {
				override trace(ValueDeclaration value, FieldHierarchy fieldHierarchy,
						VariableDeclaration lowlevelVariable) {
					trace.put(value -> fieldHierarchy, lowlevelVariable)
				}
			}
		)
		val lowlevelVariableNames = gammaVariable.names
		lowlevelVariables.nameLowlevelVariables(lowlevelVariableNames)
		return lowlevelVariables
	}
	
	private def nameLowlevelVariables(List<VariableDeclaration> lowlevelVariables,
			List<String> lowlevelVariableNames) {
		checkState(lowlevelVariables.size == lowlevelVariableNames.size)
		val size = lowlevelVariables.size
		for (var i = 0; i < size; i++) {
			val lowlevelVariable = lowlevelVariables.get(i)
			val lowlevelVariableName = lowlevelVariableNames.get(i)
			lowlevelVariable.name = lowlevelVariableName
		}
	}
	
	def List<VariableDeclaration> transform(ValueDeclaration gammaValue) {
		if (gammaValue instanceof VariableDeclaration) {
			return gammaValue.transform
		}
		if (gammaValue instanceof ConstantDeclaration) {
			return gammaValue.transform
		}
		throw new IllegalArgumentException("Not known value declaration: " + gammaValue)
	}
	
	private def List<VariableDeclaration> transformValue(ValueDeclaration declaration, Tracer tracer) {
		val type = declaration.type
		val fieldHierarchies = type.fieldHierarchies
		val nativeTypes = type.nativeTypes
		checkState(fieldHierarchies.size == nativeTypes.size)
		val size = fieldHierarchies.size
		val lowlevelVariables = newArrayList
		for (var i = 0; i < size; i++) {
			val fieldHierarchy = fieldHierarchies.get(i)
			val nativeType = nativeTypes.get(i).transformType // Only native and arrays
			val lowlevelVariable = createVariableDeclaration => [
				// Name added later
				it.type = nativeType
				if (declaration instanceof VariableDeclaration) {
					for (annotation : declaration.annotations) {
						it.annotations += annotation.transformAnnotation
					}
				}
				else if (declaration instanceof ParameterDeclaration) {
					for (annotation : declaration.annotations) {
						it.annotations += annotation.transformAnnotation
					}
				}
			]
			lowlevelVariables += lowlevelVariable
			// Abstract tracing
			tracer.trace(declaration, fieldHierarchy, lowlevelVariable)
		}
		// Initial values - must come after variable transformation due to the lazy type transformation
		val initialValues = newArrayList
		if (declaration instanceof InitializableElement) {
			val initalExpression = declaration.expression
			if (initalExpression !== null) {
				initialValues += initalExpression.transformExpression
			}
		}
		checkState(initialValues.size == 0 || initialValues.size == lowlevelVariables.size)
		for (var i = 0; i < initialValues.size; i++) {
			val initialValue = initialValues.get(i)
			val lowlevelVariable = lowlevelVariables.get(i)
			lowlevelVariable.expression = initialValue
		}
		
		return lowlevelVariables
	}
	
	private def transformAnnotation(VariableDeclarationAnnotation annotation) {
		return annotation.clone
	}
	
	private def transformAnnotation(ParameterDeclarationAnnotation annotation) {
		switch (annotation) {
			InternalParameterDeclarationAnnotation:
				return createInternalVariableDeclarationAnnotation
			default:
				throw new IllegalArgumentException("Not known annotation: " + annotation)
		}
	}
	
	//
	
	def getTrace() {
		return trace
	}
	
	//
	
	interface Tracer {
		// Maybe it could contain the namings too
		def void trace(ValueDeclaration value, FieldHierarchy fieldHierarchy,
			VariableDeclaration lowlevelVariable)
	}
	
}