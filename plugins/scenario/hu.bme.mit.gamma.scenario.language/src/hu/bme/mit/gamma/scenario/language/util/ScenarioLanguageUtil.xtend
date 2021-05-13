package hu.bme.mit.gamma.scenario.language.util

import hu.bme.mit.gamma.scenario.model.ScenarioDeclaration
import hu.bme.mit.gamma.statechart.interface_.Package
import org.eclipse.emf.ecore.EObject

class ScenarioLanguageUtil {

	static def getScenarioDeclaration(EObject obj) {
		return EcoreUtilWrapper::getAllContainers(obj).filter(ScenarioDeclaration).head
	}

	static def <T extends EObject> filterInstancesByTypeInReferredStatechart(EObject objInScenarioModel, Class<T> cls) {
		val statechart = hu.bme.mit.gamma.scenario.language.util.ScenarioLanguageUtil.getPackage(objInScenarioModel)
		return StatechartLanguageUtil::filterContainedObjectsByType(statechart, cls)
	}

	private static def Package getPackage(EObject obj) {
		return getScenarioDeclaration(obj).package
	}
}
