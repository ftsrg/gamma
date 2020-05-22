package hu.bme.mit.gamma.uppaal.verification.result;

public enum ThreeStateBoolean {
	FALSE, TRUE, UNDEF;
	
	public ThreeStateBoolean opposite() {
		switch (this) {
			case FALSE:
				return TRUE;
			case TRUE:
				return FALSE;
			default:
				return UNDEF;
		}		
	}
	
}