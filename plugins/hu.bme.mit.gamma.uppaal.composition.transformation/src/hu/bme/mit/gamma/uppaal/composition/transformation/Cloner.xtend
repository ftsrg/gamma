package hu.bme.mit.gamma.uppaal.composition.transformation

import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.util.EcoreUtil.Copier

class Cloner {
	
	/**
	 * EcoreUtil copy.
	 */
	def <T extends EObject> T clone(T model, boolean a, boolean b) {
		// A new copier should be user every time, otherwise anomalies happen (references are changed without asking)
		val copier = new Copier(a, b)
		val clone = copier.copy(model);
		copier.copyReferences();
		return clone as T;
	}	
	
}