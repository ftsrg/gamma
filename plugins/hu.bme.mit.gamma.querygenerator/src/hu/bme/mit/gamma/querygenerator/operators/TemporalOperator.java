package hu.bme.mit.gamma.querygenerator.operators;

public enum TemporalOperator {
	MIGHT_ALWAYS, MUST_ALWAYS, MIGHT_EVENTUALLY, MUST_EVENTUALLY, LEADS_TO;
	
	public String getOperator() {
		switch (this) {
			case MIGHT_ALWAYS:
				return "E[]";
			case MUST_ALWAYS:
				return "A[]";
			case MIGHT_EVENTUALLY:
				return "E<>";
			case MUST_EVENTUALLY:
				return "A<>";
			case LEADS_TO:
				return "-->";
		}
		throw new IllegalArgumentException("Not known operator: " + this);
	}
}