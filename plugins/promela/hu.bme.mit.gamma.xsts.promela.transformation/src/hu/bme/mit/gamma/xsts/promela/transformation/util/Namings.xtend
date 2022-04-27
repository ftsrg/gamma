package hu.bme.mit.gamma.xsts.promela.transformation.util

import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.XstsNamings.*
import static extension hu.bme.mit.gamma.transformation.util.Namings.*
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance

class Namings {
	static def String costumizeEnumLiteralName(EnumerationLiteralExpression expression) '''«expression.reference.typeDeclaration.name»«expression.reference.name»'''
	static def String costumizeEnumLiteralName(EnumerationTypeDefinition type, EnumerationLiteralDefinition literal) '''«type.typeDeclaration.name»«literal.name»'''
	static def String costumizeEnumLiteralName(State state, Region parentRegion, ComponentInstanceReference instance) '''«parentRegion.name.regionTypeName»_«instance.FQN»«state.customizeName»'''
	static def String costumizeEnumLiteralName(State state, Region parentRegion, SynchronousComponentInstance instance) '''«parentRegion.name.regionTypeName»_«instance.FQN»«state.customizeName»'''
}