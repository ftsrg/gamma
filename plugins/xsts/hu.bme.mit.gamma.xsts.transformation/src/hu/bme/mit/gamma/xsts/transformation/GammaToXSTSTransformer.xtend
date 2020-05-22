package hu.bme.mit.gamma.xsts.transformation

import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.lowlevel.xsts.transformation.ActionOptimizer
import hu.bme.mit.gamma.lowlevel.xsts.transformation.LowlevelToXSTSTransformer
import hu.bme.mit.gamma.lowlevel.xsts.transformation.serializer.ActionSerializer
import hu.bme.mit.gamma.statechart.lowlevel.model.Package
import hu.bme.mit.gamma.statechart.lowlevel.transformation.GammaToLowlevelTransformer
import hu.bme.mit.gamma.statechart.model.StatechartDefinition
import hu.bme.mit.gamma.statechart.model.composite.AbstractSynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.CascadeCompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.Component
import hu.bme.mit.gamma.statechart.model.composite.ComponentInstance
import hu.bme.mit.gamma.xsts.model.model.XSTS
import hu.bme.mit.gamma.xsts.model.model.XSTSModelFactory

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*

class GammaToXSTSTransformer {
	// Source Gamma package
	hu.bme.mit.gamma.statechart.model.Package _package
	// Transformers
	GammaToLowlevelTransformer gammaToLowlevelTransformer = new GammaToLowlevelTransformer
	LowlevelToXSTSTransformer lowlevelToXSTSTransformer
	// Auxiliary objects
	protected final extension ExpressionUtil expressionUtil = new ExpressionUtil
	protected final extension ActionSerializer actionSerializer = new ActionSerializer
	protected final extension EnvironmentalActionFilter environmentalActionFilter = new EnvironmentalActionFilter
	protected final extension EventConnector eventConnector = new EventConnector
	protected final extension ActionOptimizer actionSimplifier = new ActionOptimizer
	protected final extension XSTSModelFactory xstsModelFactory = XSTSModelFactory.eINSTANCE
	
	new(hu.bme.mit.gamma.statechart.model.Package _package) {
		this._package = _package
	}
	
	def execute() {
		val lowlevelPackage = gammaToLowlevelTransformer.transform(_package) // Not execute, as we want to distinguish between statecharts
		// Serializing the xSTS
		val gammaComponent = _package.components.head // Transforming first Gamma component
		val xSts = gammaComponent.transform(lowlevelPackage)
		// Removing duplicated types
		xSts.removeDuplicatedTypes
		// Optimizing
		xSts.initializingAction = xSts.initializingAction.optimize
		xSts.mergedTransition.action = xSts.mergedTransition.action.optimize
		xSts.environmentalAction = xSts.environmentalAction.optimize
		return xSts
	}
	
	def executeAndSerialize() {
		return execute.serializeXSTS
	}
	
	def dispatch XSTS transform(Component component, Package lowlevelPackage) {
		throw new IllegalArgumentException("Not supported component type: " + component)
	}
	
	def dispatch XSTS transform(AbstractSynchronousCompositeComponent component, Package lowlevelPackage) {
		var XSTS xSts = null
		for (subcomponent : component.components) {
			val type = subcomponent.type
			val newXSts = type.transform(lowlevelPackage)
			newXSts.customizeDeclarationNames(subcomponent)
			if (xSts === null) {
				xSts = newXSts
			}
			else {
				// Adding new elements
				xSts.typeDeclarations += newXSts.typeDeclarations
				xSts.publicTypeDeclarations += newXSts.publicTypeDeclarations
				xSts.variableGroups += newXSts.variableGroups
				xSts.variableDeclarations += newXSts.variableDeclarations
				xSts.transientVariables += newXSts.transientVariables
				xSts.controlVariables += newXSts.controlVariables
				xSts.transitions += newXSts.transitions
				xSts.constraints += newXSts.constraints
				// Merged action
				val mergedAction = if (component instanceof CascadeCompositeComponent) createSequentialAction else createOrthogonalAction
				mergedAction.actions += xSts.mergedTransition.action
				mergedAction.actions += newXSts.mergedTransition.action
				xSts.mergedTransition.action = mergedAction
				xSts.connectEventsThroughChannels(component) // Event (variable setting) connecting across channels
				// Initializing action
				val initAction = createSequentialAction
				initAction.actions += xSts.initializingAction
				initAction.actions += newXSts.initializingAction
				xSts.initializingAction = initAction
				// Environmental action
				val environmentAction = createSequentialAction
				environmentAction.actions += xSts.environmentalAction
				environmentAction.actions += newXSts.environmentalAction
				environmentAction.filter(component) // Filtering events not led out to the port
				xSts.environmentalAction = environmentAction
			}
		}
		xSts.name = component.name
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
	
	protected def void customizeDeclarationNames(XSTS xSts, ComponentInstance instance) {
		val type = instance.derivedType
		if (type instanceof StatechartDefinition) {
			for (variable : xSts.variableDeclarations) {
				variable.name = variable.customizeName(instance)
			}
			for (typeDeclaration : xSts.typeDeclarations) {
				typeDeclaration.name = typeDeclaration.customizeName(type)
			}
		}
	}
	
	protected def removeDuplicatedTypes(XSTS xSts) {
		val types = xSts.typeDeclarations
		for (var i = 0; i < types.size - 1; i++) {
			val lhs = types.get(i)
			for (var j = i + 1; j < types.size; j++) {
				val rhs = types.get(j)
				if (lhs.helperEquals(rhs)) {
					lhs.changeAll(rhs, xSts)
					j--
				}
			}
		}
	}
	
}