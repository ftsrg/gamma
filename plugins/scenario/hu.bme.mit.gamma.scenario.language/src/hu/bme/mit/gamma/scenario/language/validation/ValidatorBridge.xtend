package hu.bme.mit.gamma.scenario.language.validation

import hu.bme.mit.gamma.scenario.language.validation.ScenarioLanguageValidator.MarkerContext
import hu.bme.mit.gamma.scenario.language.validation.ScenarioLanguageValidator.MarkerLevel
import java.util.Map
import java.util.Set
import java.util.concurrent.ConcurrentHashMap
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.xtend.lib.annotations.Accessors

class ValidatorBridge {

	public static val ValidatorBridge INSTANCE = new ValidatorBridge

	@Accessors(PUBLIC_SETTER) var ScenarioLanguageValidator validator

	val Map<EObject, Set<MarkerContext>> shouldBeVisible

	private new() {
		this.shouldBeVisible = new ConcurrentHashMap
	}

	def void clear() {
		shouldBeVisible.forEach[key, value|value.forEach[validator.removeMarker(it)]]
		shouldBeVisible.clear
	}
	
	def void showError(String message, EObject target, EStructuralFeature feature, int index) {
		addMarker(new MarkerContext(MarkerLevel.ERROR, message, target, feature, index))
	}

	def void showWarning(String message, EObject target, EStructuralFeature feature, int index) {
		addMarker(new MarkerContext(MarkerLevel.WARNING, message, target, feature, index))
	}

	def void showInfo(String message, EObject target, EStructuralFeature feature, int index) {
		addMarker(new MarkerContext(MarkerLevel.INFO, message, target, feature, index))
	}

	private def void addMarker(MarkerContext ctx) {
		synchronized(shouldBeVisible) {
			val target = ctx.target
			val markers = shouldBeVisible.get(target)
			if(markers.nullOrEmpty) {
				shouldBeVisible.put(target, newHashSet(ctx))
			} else {
				markers.add(ctx)
			}
		}
		validator.addMarker(ctx)
	}
}
