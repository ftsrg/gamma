package hu.bme.mit.gamma.statechart.language.ui.serializer;

import java.io.File;
import java.io.IOException;

import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;

import com.google.inject.Injector;

import hu.bme.mit.gamma.language.util.serialization.GammaLanguageSerializer;
import hu.bme.mit.gamma.statechart.language.ui.internal.LanguageActivator;

public class StatechartLanguageSerializer {

	public void serialize(EObject rootElem, String parentFolder, String fileName) throws IOException {
		// This is how an injected object can be retrieved
		Injector injector = LanguageActivator.getInstance()
				.getInjector(LanguageActivator.HU_BME_MIT_GAMMA_STATECHART_LANGUAGE_STATECHARTLANGUAGE);
		GammaLanguageSerializer serializer = injector.getInstance(GammaLanguageSerializer.class);
		serializer.save(rootElem, URI.decode(parentFolder + File.separator + fileName));
	}
	
}
