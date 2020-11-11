package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.expression.model.VariableDeclarationAnnotation
import hu.bme.mit.gamma.util.GammaEcoreUtil

class AnnotationTransformer {
	// Singleton
	public static final AnnotationTransformer INSTANCE = new AnnotationTransformer
	protected new() {}
	//
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	
	def transform(VariableDeclarationAnnotation annotation) {
		return annotation.clone
	}
	
}