package hu.bme.mit.gamma.xsts.transformation

import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.statechart.model.composite.Component
import hu.bme.mit.gamma.xsts.model.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.model.CompositeAction
import java.util.Set

import static hu.bme.mit.gamma.xsts.transformation.util.Namings.*
import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*

class EnvironmentalActionFilter {
	// Names that need to be kept
	Set<String> necessaryNames
	// Auxiliary objects
	protected extension ExpressionUtil expressionUtil = new ExpressionUtil
	
	def void filter(CompositeAction action, Component component) {
		necessaryNames = newHashSet
		for (port : component.allConnectedSimplePorts) {
			val statechart = port.containingStatechart
			val instance = statechart.referencingComponentInstance
			for (eventDeclaration : port.interfaceRealization.interface.events) {
				val event = eventDeclaration.event
				necessaryNames += customizeInputName(event, port, instance)
				necessaryNames += customizeOutputName(event, port, instance)
				for (parameter : event.parameterDeclarations) {
					necessaryNames += customizeInName(parameter, port, instance)
					necessaryNames += customizeOutName(parameter, port, instance)
				}
			}
		}
		action.filter
	}
	
	private def void filter(CompositeAction action) {
		val xStsSubactions = action.actions
		val copyXStsSubactions = newArrayList
		copyXStsSubactions += xStsSubactions
		for (xStsSubaction : copyXStsSubactions) {
			if (xStsSubaction instanceof AssignmentAction) {
				val name = xStsSubaction.lhs.declaration.name
				if (!necessaryNames.contains(name)) {
					xStsSubactions -= xStsSubaction
				}
			}
			else if (xStsSubaction instanceof AssumeAction) {
				val variables = xStsSubaction.assumption.referredVariables
				if (!variables.exists[necessaryNames.contains(it.name)]) {
					xStsSubactions -= xStsSubaction
				}
			}
			else if (xStsSubaction instanceof CompositeAction) {
				xStsSubaction.filter
			}
		}
	}
	
	
}