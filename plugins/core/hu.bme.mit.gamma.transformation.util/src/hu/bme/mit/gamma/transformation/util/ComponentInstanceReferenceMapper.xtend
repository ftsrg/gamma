package hu.bme.mit.gamma.transformation.util

import hu.bme.mit.gamma.expression.model.NamedElement
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.util.GammaEcoreUtil

class ComponentInstanceReferenceMapper {
	// Singleton
	public static final ComponentInstanceReferenceMapper INSTANCE = new ComponentInstanceReferenceMapper
	protected new() {}
	//
	protected final SimpleInstanceHandler simpleInstanceHandler = SimpleInstanceHandler.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	def checkAndGetNewSimpleInstance(ComponentInstanceReference originalInstance, Component newTopComponent) {
		return simpleInstanceHandler.checkAndGetNewSimpleInstance(originalInstance, newTopComponent)
	}
	
	def <T extends NamedElement> getNewObject(ComponentInstanceReference originalInstance,
			T originalObject, Component newTopComponent) {
		val originalName = originalObject.name
		val newInstance = originalInstance.checkAndGetNewSimpleInstance(newTopComponent)
		val newComponent = newInstance.type
		val contents = newComponent.getAllContentsOfType(originalObject.class)
		for (content : contents) {
			val name = content.name
			// Structural properties during reduction change, names do not change
			if (originalName == name) {
				return content as T
			}
		}
		throw new IllegalStateException("New object not found: " + originalObject + 
			"Known Xtext bug: for generated gdp, the variables references are not resolved.")
	}
	
}