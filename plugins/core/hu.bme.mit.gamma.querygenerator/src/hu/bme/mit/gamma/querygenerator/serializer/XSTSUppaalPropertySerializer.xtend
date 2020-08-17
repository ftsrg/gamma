package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.property.model.UnaryPathOperator
import hu.bme.mit.gamma.uppaal.util.XSTSNamings


import static hu.bme.mit.gamma.uppaal.util.Namings.*

import static hu.bme.mit.gamma.uppaal.util.XSTSNamings.*

class XSTSUppaalPropertySerializer extends UppaalPropertySerializer {
	// Singleton
	public static final XSTSUppaalPropertySerializer INSTANCE = new XSTSUppaalPropertySerializer
	protected new() {
		super.serializer = (new PropertyExpressionSerializer(ThetaReferenceSerializer.INSTANCE))
	}
	//
	
	protected override String addIsStable(UnaryPathOperator operator) {
		switch (operator) {
			case FUTURE: {
				return '''&& «getProcessName(templateName)».«stableLocationName»'''
			}
			case GLOBAL: {
				return '''|| !«getProcessName(templateName)».«stableLocationName»'''
			}
			default: 
				throw new IllegalArgumentException("Not supported operator: " + operator)
		}
	}
	
}