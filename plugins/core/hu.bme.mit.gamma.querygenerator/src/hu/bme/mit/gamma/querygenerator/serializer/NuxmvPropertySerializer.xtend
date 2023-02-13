package hu.bme.mit.gamma.querygenerator.serializer

class NuxmvPropertySerializer extends ThetaPropertySerializer {
	// Singleton
	public static final NuxmvPropertySerializer INSTANCE = new NuxmvPropertySerializer
	protected new() {
		super.serializer = new NuxmvPropertyExpressionSerializer(NuxmvReferenceSerializer.INSTANCE)
	}
	//
}