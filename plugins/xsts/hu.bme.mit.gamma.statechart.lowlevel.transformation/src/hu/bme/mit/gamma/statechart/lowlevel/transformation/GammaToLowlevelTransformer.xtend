package hu.bme.mit.gamma.statechart.lowlevel.transformation

import hu.bme.mit.gamma.statechart.model.Package

import static com.google.common.base.Preconditions.checkState

class GammaToLowlevelTransformer {
	
	protected final extension StatechartToLowlevelTransformer transformer = new StatechartToLowlevelTransformer
	
	def hu.bme.mit.gamma.statechart.lowlevel.model.Package execute(Package _package) {
		// TODO
		checkState(!_package.name.nullOrEmpty)
		return _package.transform
	}
	
	
}
