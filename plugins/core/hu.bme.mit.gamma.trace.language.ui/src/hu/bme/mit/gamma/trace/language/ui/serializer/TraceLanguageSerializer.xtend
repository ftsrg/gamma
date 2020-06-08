package hu.bme.mit.gamma.trace.language.ui.serializer

import hu.bme.mit.gamma.language.util.serialization.GammaLanguageSerializer
import hu.bme.mit.gamma.trace.language.ui.internal.LanguageActivator
import java.io.File
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EObject

class TraceLanguageSerializer {
	
	def void serialize(EObject rootElem, String parentFolder, String fileName) {
		// This is how an injected object can be retrieved
		val injector = LanguageActivator.getInstance()
				.getInjector(LanguageActivator.HU_BME_MIT_GAMMA_TRACE_LANGUAGE_TRACELANGUAGE);
		val serializer = injector.getInstance(GammaLanguageSerializer);
		serializer.save(rootElem, URI.decode(parentFolder + File.separator + fileName));
	}
	
}