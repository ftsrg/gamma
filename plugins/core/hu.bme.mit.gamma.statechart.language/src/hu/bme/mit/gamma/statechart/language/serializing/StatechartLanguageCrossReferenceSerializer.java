package hu.bme.mit.gamma.statechart.language.serializing;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.language.util.serialization.GammaLanguageCrossReferenceSerializer;
import hu.bme.mit.gamma.statechart.interface_.Package;


public class StatechartLanguageCrossReferenceSerializer extends GammaLanguageCrossReferenceSerializer {

	@Override
	public Class<? extends EObject> getContext() {
		return Package.class;
	}

	@Override
	public Class<? extends EObject> getTarget() {
		return Package.class;
	}

}
