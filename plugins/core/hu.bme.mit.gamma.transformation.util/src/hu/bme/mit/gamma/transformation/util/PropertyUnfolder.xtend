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

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

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
		newPropertyPackage.import += newTopComponent.containingPackage
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
		val newInstance = instance.newSimpleInstance
		val region = reference.region
		// TODO is this  getNewObject method correct, when the new region has fewer states due to reduction?
		val newRegion = instance.getNewObject(region, newTopComponent)
		val state = reference.state
		// TODO is this getNewObject method correct, when the new states has fewer actions due to reduction?
		val newState = instance.getNewObject(state, newTopComponent)
		return reference.clone	=> [
			it.instance = newInstance
			it.region = newRegion
			it.state = newState
		]
	}
	
	def dispatch EObject unfold(ComponentInstanceVariableReference reference) {
		val instance = reference.instance
		val newInstance = instance.newSimpleInstance
		val variable = reference.variable
		val newVariable = instance.getNewObject(variable, newTopComponent)
		return reference.clone	=> [
			it.instance = newInstance
			it.variable = newVariable
		]
	}
	
	def dispatch EObject unfold(ComponentInstanceEventReference reference) {
		val instance = reference.instance
		val newInstance = instance.newSimpleInstance
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
		val newInstance = instance.newSimpleInstance
		val port = reference.port
		val newPort = instance.getNewObject(port, newTopComponent)
		return reference.clone	=> [
			it.instance = newInstance
			it.port = newPort
			// Event and parameter are the same
		]
	}
	
	protected def getNewSimpleInstance(ComponentInstanceReference instance) {
//		val oldPackage = propertyPackage.component.containingPackage
//		if (oldPackage.unfolded) {
//			val statechartInstance = instance.componentInstanceHierarchy.last
//			val newPackage = newTopComponent.containingPackage
//			val newInstances = newPackage.allStatechartComponents.map[it.referencingComponentInstance]
//			val equalInstances = newInstances.filter[it.helperEquals(statechartInstance)]
//			val equalInstance = equalInstances.head
//			return equalInstance.createInstanceReference
//		}
//		else {
			return instance.getNewSimpleInstance(newTopComponent).createInstanceReference
//		}
	}
	
	protected def ComponentInstanceReference createInstanceReference(ComponentInstance instance) {
		return createComponentInstanceReference => [
			it.componentInstanceHierarchy += instance
		]
	}
	
}