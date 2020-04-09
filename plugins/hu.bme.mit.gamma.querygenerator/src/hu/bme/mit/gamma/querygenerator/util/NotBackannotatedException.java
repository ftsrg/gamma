package hu.bme.mit.gamma.querygenerator.util;

public class NotBackannotatedException extends Exception {
	
	private static final long serialVersionUID = 1L;
	private ThreeStateBoolean threeStateBoolean;
	
	public NotBackannotatedException(ThreeStateBoolean threeStateBoolean) {
		this.threeStateBoolean = threeStateBoolean;
	}
	
	public ThreeStateBoolean getThreeStateBoolean() {
		return threeStateBoolean;
	}
}
