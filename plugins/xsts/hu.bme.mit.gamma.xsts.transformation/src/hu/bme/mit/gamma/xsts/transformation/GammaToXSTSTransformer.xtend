package hu.bme.mit.gamma.xsts.transformation

import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.lowlevel.xsts.transformation.LowlevelToXSTSTransformer
import hu.bme.mit.gamma.lowlevel.xsts.transformation.serializer.ActionSerializer
import hu.bme.mit.gamma.statechart.lowlevel.model.Package
import hu.bme.mit.gamma.statechart.lowlevel.transformation.GammaToLowlevelTransformer
import hu.bme.mit.gamma.statechart.model.StatechartDefinition
import hu.bme.mit.gamma.statechart.model.composite.CascadeCompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.Component
import hu.bme.mit.gamma.statechart.model.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.model.composite.SynchronousCompositeComponent
import hu.bme.mit.gamma.xsts.model.model.XSTS
import hu.bme.mit.gamma.xsts.model.model.XSTSModelFactory

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*

class GammaToXSTSTransformer {
	// Source Gamma pacakge
	hu.bme.mit.gamma.statechart.model.Package _package
	// Transformers
	GammaToLowlevelTransformer gammaToLowlevelTransformer = new GammaToLowlevelTransformer
	LowlevelToXSTSTransformer lowlevelToXSTSTransformer
	ActionSerializer actionSerializer = new ActionSerializer
	// Auxiliary objects
	protected extension ExpressionUtil expressionUtil = new ExpressionUtil
	protected extension XSTSModelFactory xstsModelFactory = XSTSModelFactory.eINSTANCE
	
	new(hu.bme.mit.gamma.statechart.model.Package _package) {
		this._package = _package
	}
	
	def execute() {
		val lowlevelPackage = gammaToLowlevelTransformer.transform(_package) // Not execute, as we want to distinguish between statecharts
		// Serializing the xSTS
		val gammaComponent = _package.components.head // Transforming first Gamma component
		return gammaComponent.transform(lowlevelPackage)
	}
	
	def dispatch XSTS transform(Component component, Package lowlevelPackage) {
		throw new IllegalArgumentException("Not supported component type: " + component)
	}
	
	def dispatch XSTS transform(SynchronousCompositeComponent component, Package lowlevelPackage) {
	}
	
	def dispatch XSTS transform(CascadeCompositeComponent component, Package lowlevelPackage) {
		var XSTS xSts = null
		for (subcomponent : component.components) {
			if (xSts === null) {
				val type = subcomponent.type
				xSts = type.transform(lowlevelPackage)
			}
		}
		return xSts
	}
	
	def dispatch XSTS transform(StatechartDefinition statechart, Package lowlevelPackage) {
		val lowlevelStatechart = gammaToLowlevelTransformer.transform(statechart)
		lowlevelPackage.components += lowlevelStatechart
		lowlevelToXSTSTransformer = new LowlevelToXSTSTransformer(lowlevelPackage)
		val xStsEntry = lowlevelToXSTSTransformer.execute
		lowlevelPackage.components -= lowlevelStatechart // So that next time the matches do not return elements from this statechart
		return xStsEntry.key
	}
	
	protected def customizeDeclarationNames(XSTS xSts, ComponentInstance instance) {
		val type = instance.derivedType
		if (type instanceof StatechartDefinition) {
			for (variable : xSts.variableDeclarations) {
				variable.name = variable.getName(instance)
			}
			for (typeDeclaration : xSts.typeDeclarations) {
				typeDeclaration.name = typeDeclaration.getName(type)
			}
		}
	}
	
	
}