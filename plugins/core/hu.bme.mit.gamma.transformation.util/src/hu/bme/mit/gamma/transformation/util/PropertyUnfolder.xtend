package hu.bme.mit.gamma.transformation.util

import hu.bme.mit.gamma.property.model.ComponentInstanceEventParameterReference
import hu.bme.mit.gamma.property.model.ComponentInstanceEventReference
import hu.bme.mit.gamma.property.model.ComponentInstanceStateConfigurationReference
import hu.bme.mit.gamma.property.model.ComponentInstanceVariableReference
import hu.bme.mit.gamma.property.model.PropertyPackage
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference
import hu.bme.mit.gamma.statechart.composite.CompositeModelFactory
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.util.GammaEcoreUtil
import org.eclipse.emf.ecore.EObject

class PropertyUnfolder {
	
	protected final PropertyPackage propertyPackage
	protected final Component newTopComponent
	
	protected final extension ComponentInstanceReferenceMapper componentInstanceReferenceMapper =
		ComponentInstanceReferenceMapper.INSTANCE
	protected final extension CompositeModelFactory compositeFactory = CompositeModelFactory.eINSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	new(PropertyPackage propertyPackage, Component newTopComponent) {
		this.propertyPackage = propertyPackage
		this.newTopComponent = newTopComponent
	}
	
	def execute() {
		val newPropertyPackage = propertyPackage.unfold as PropertyPackage
		newPropertyPackage.component = newTopComponent
		return newPropertyPackage
	}
	
	def dispatch EObject unfold(EObject object) {
		val newObject = object.clone
		val contents = newObject.eContents
		val size = contents.size
		for (var i = 0; i < size; i++) {
			val content = contents.get(i)
			val newContent = content.unfold
			newContent.replace(content)
		}
		return newObject
	}
	
	def dispatch EObject unfold(ComponentInstanceStateConfigurationReference reference) {
		val instance = reference.instance
		val newInstance = instance.getNewSimpleInstance(newTopComponent).createInstanceReference
		val region = reference.region
		val newRegion = instance.getNewObject(region, newTopComponent)
		val state = reference.state
		val newState = instance.getNewObject(state, newTopComponent)
		return reference.clone	=> [
			it.instance = newInstance
			it.region = newRegion
			it.state = newState
		]
	}
	
	def dispatch EObject unfold(ComponentInstanceVariableReference reference) {
		val instance = reference.instance
		val newInstance = instance.getNewSimpleInstance(newTopComponent).createInstanceReference
		val variable = reference.variable
		val newVariable = instance.getNewObject(variable, newTopComponent)
		return reference.clone	=> [
			it.instance = newInstance
			it.variable = newVariable
		]
	}
	
	def dispatch EObject unfold(ComponentInstanceEventReference reference) {
		val instance = reference.instance
		val newInstance = instance.getNewSimpleInstance(newTopComponent).createInstanceReference
		val port = reference.port
		val newPort = instance.getNewObject(port, newTopComponent)
		return reference.clone	=> [
			it.instance = newInstance
			it.port = newPort
			// Event is the same
		]
	}
	
	def dispatch EObject unfold(ComponentInstanceEventParameterReference reference) {
		val instance = reference.instance
		val newInstance = instance.getNewSimpleInstance(newTopComponent).createInstanceReference
		val port = reference.port
		val newPort = instance.getNewObject(port, newTopComponent)
		return reference.clone	=> [
			it.instance = newInstance
			it.port = newPort
			// Event and parameter are the same
		]
	}
	
	protected def ComponentInstanceReference createInstanceReference(ComponentInstance instance) {
		return createComponentInstanceReference => [
			it.componentInstanceHierarchy += instance
		]
	}
	
}