package hu.bme.mit.gamma.querygenerator.uppaal;

public class UppaalSettings {

	public static final UppaalSettings DEFAULT_SETTINGS = createDefault();

	public static final String SEARCH_ORDER_BF = "Breadth First";
	public static final String SEARCH_ORDER_DF = "Depth First";
	public static final String SEARCH_ORDER_RDF = "Random Depth First";
	public static final String SEARCH_ORDER_OF = "Optimal First";
	public static final String SEARCH_ORDER_RODF = "Random Optimal Depth First";
	public static final String SEARCH_ORDER_DEFAULT = SEARCH_ORDER_BF;

	public static final String STATE_SPACE_REPRESENTATION_OA = "Over Approximation";
	public static final String STATE_SPACE_REPRESENTATION_UA = "Under Approximation";
	public static final String STATE_SPACE_REPRESENTATION_DBM = "DBM";
	public static final String STATE_SPACE_REPRESENTATION_DEFAULT = STATE_SPACE_REPRESENTATION_DBM;

	public static final String TRACE_SOME = "Some";
	public static final String TRACE_SHORTEST = "Shortest";
	public static final String TRACE_FASTEST = "Fastest";
	public static final String TRACE_DEFAULT = TRACE_SHORTEST;

	public static final int HASHTABLE_SIZE_64 = 64;
	public static final int HASHTABLE_SIZE_256 = 256;
	public static final int HASHTABLE_SIZE_512 = 512;
	public static final int HASHTABLE_SIZE_1024 = 1024;
	public static final int HASHTABLE_SIZE_DEFAULT = HASHTABLE_SIZE_512;

	public static final String STATE_SPACE_REDUCTION_NONE = "None";
	public static final String STATE_SPACE_REDUCTION_AGGRESSIVE = "Aggressive";
	public static final String STATE_SPACE_REDUCTION_CONSERVATIVE = "Conservative";
	public static final String STATE_SPACE_REDUCTION_DEFAULT = STATE_SPACE_REDUCTION_CONSERVATIVE;

	private String searchOrder;
	private String stateSpaceRepresentation;
	private String trace;
	private int hashtableSize;
	private String stateSpaceReduction;
	private boolean reuseStateSpace;

	public String getSearchOrder() {
		return searchOrder;
	}

	public String getStateSpaceRepresentation() {
		return stateSpaceRepresentation;
	}

	public String getTrace() {
		return trace;
	}

	public int getHashtableSize() {
		return hashtableSize;
	}

	public String getStateSpaceReduction() {
		return stateSpaceReduction;
	}

	public boolean isReuseStateSpace() {
		return reuseStateSpace;
	}

	public static class Builder {

		private UppaalSettings instance;

		public Builder() {
			this.instance = new UppaalSettings();
		}

		public Builder searchOrder(String value) {
			instance.searchOrder = value;
			return this;
		}

		public Builder stateSpaceRepresentation(String value) {
			instance.stateSpaceReduction = value;
			return this;
		}

		public Builder trace(String value) {
			instance.trace = value;
			return this;
		}

		public Builder hashtableSize(int value) {
			instance.hashtableSize = value;
			return this;
		}

		public Builder stateSpaceReduction(String value) {
			instance.stateSpaceReduction = value;
			return this;
		}

		public Builder reuseStateSpace(boolean value) {
			instance.reuseStateSpace = value;
			return this;
		}

		public UppaalSettings build() {
			return instance;
		}

	}

	private static UppaalSettings createDefault() {
		return new Builder().searchOrder(SEARCH_ORDER_DEFAULT)
				.stateSpaceRepresentation(STATE_SPACE_REPRESENTATION_DEFAULT).trace(TRACE_DEFAULT)
				.hashtableSize(HASHTABLE_SIZE_DEFAULT).stateSpaceReduction(STATE_SPACE_REDUCTION_DEFAULT).build();
	}

}
