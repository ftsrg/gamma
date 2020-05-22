package hu.bme.mit.gamma.statechart.lowlevel.transformation

import hu.bme.mit.gamma.statechart.model.Package

import static com.google.common.base.Preconditions.checkState
import hu.bme.mit.gamma.statechart.model.StatechartDefinition

class GammaToLowlevelTransformer {
	
	protected final extension StatechartToLowlevelTransformer transformer = new StatechartToLowlevelTransformer
	
	def hu.bme.mit.gamma.statechart.lowlevel.model.Package execute(Package _package) {
		checkState(!_package.name.nullOrEmpty)
		val lowlevelPackage = _package.transform // This does not transform components anymore
		// Interfaces are not transformed, the events are transformed (thus, "instantiated") when referred
		for (statechart : _package.components.filter(StatechartDefinition)) {
			lowlevelPackage.components += statechart.transform
		}
		return lowlevelPackage
	}
	
	def hu.bme.mit.gamma.statechart.lowlevel.model.Package transform(Package _package) {
		return transformer.execute(_package)
	}
	
	def hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition transform(StatechartDefinition statechart) {
		return statechart.execute
	}
	
}
