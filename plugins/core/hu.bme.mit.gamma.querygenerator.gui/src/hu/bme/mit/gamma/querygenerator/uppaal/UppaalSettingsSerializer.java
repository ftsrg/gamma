package hu.bme.mit.gamma.querygenerator.uppaal;

import static hu.bme.mit.gamma.querygenerator.uppaal.UppaalSettings.SEARCH_ORDER_BF;
import static hu.bme.mit.gamma.querygenerator.uppaal.UppaalSettings.SEARCH_ORDER_DF;
import static hu.bme.mit.gamma.querygenerator.uppaal.UppaalSettings.SEARCH_ORDER_OF;
import static hu.bme.mit.gamma.querygenerator.uppaal.UppaalSettings.SEARCH_ORDER_RDF;
import static hu.bme.mit.gamma.querygenerator.uppaal.UppaalSettings.SEARCH_ORDER_RODF;
import static hu.bme.mit.gamma.querygenerator.uppaal.UppaalSettings.STATE_SPACE_REDUCTION_AGGRESSIVE;
import static hu.bme.mit.gamma.querygenerator.uppaal.UppaalSettings.STATE_SPACE_REDUCTION_CONSERVATIVE;
import static hu.bme.mit.gamma.querygenerator.uppaal.UppaalSettings.STATE_SPACE_REDUCTION_NONE;
import static hu.bme.mit.gamma.querygenerator.uppaal.UppaalSettings.STATE_SPACE_REPRESENTATION_DBM;
import static hu.bme.mit.gamma.querygenerator.uppaal.UppaalSettings.STATE_SPACE_REPRESENTATION_OA;
import static hu.bme.mit.gamma.querygenerator.uppaal.UppaalSettings.STATE_SPACE_REPRESENTATION_UA;
import static hu.bme.mit.gamma.querygenerator.uppaal.UppaalSettings.TRACE_FASTEST;
import static hu.bme.mit.gamma.querygenerator.uppaal.UppaalSettings.TRACE_SHORTEST;
import static hu.bme.mit.gamma.querygenerator.uppaal.UppaalSettings.TRACE_SOME;

public class UppaalSettingsSerializer {

	public String serialize(UppaalSettings settings) {
		return String.format("%s %s %s %s %s %s",
				convertStateSpaceRepresentation(settings.getStateSpaceRepresentation()),
				convertSearchOrder(settings.getSearchOrder(), settings.getTrace()),
				convertDiagnosticTrace(settings.getTrace()),
				convertReuseStateSpace(settings.isReuseStateSpace()),
				convertHashtableSize(settings.getHashtableSize()),
				convertStateSpaceReduction(settings.getStateSpaceReduction()));
	}

	private String convertSearchOrder(String searchOrder, String trace) {
		boolean traceIsShortestOrFastest = TRACE_SHORTEST.equals(trace) || TRACE_FASTEST.equals(trace);
		final String paremterName = "-o ";
		switch (searchOrder) {
		case SEARCH_ORDER_BF:
			return paremterName + "0";
		case SEARCH_ORDER_DF:
			return paremterName + "1";
		case SEARCH_ORDER_RDF:
			return paremterName + "2";
		case SEARCH_ORDER_OF:
			if (traceIsShortestOrFastest) {
				return paremterName + "3";
			}
			// BFS
			return paremterName + "0";
		case SEARCH_ORDER_RODF:
			if (traceIsShortestOrFastest) {
				return paremterName + "4";
			}
			// BFS
			return paremterName + "0";
		default:
			throw new IllegalArgumentException("Not known option: " + searchOrder);
		}
	}

	private String convertStateSpaceRepresentation(String stateSpaceRepresentation) {
		switch (stateSpaceRepresentation) {
		case STATE_SPACE_REPRESENTATION_DBM:
			return "-C";
		case STATE_SPACE_REPRESENTATION_OA:
			return "-A";
		case STATE_SPACE_REPRESENTATION_UA:
			return "-Z";
		default:
			throw new IllegalArgumentException("Not known option: " + stateSpaceRepresentation);
		}
	}

	private String convertHashtableSize(int hashtableSize) {
		/*
		 * -H n Set hash table size for bit state hashing to 2**n (default = 27)
		 */
		final int exponent = 20 + (int) Math.floor(Math.log10(hashtableSize) / Math.log10(2)); // log2(value)
		return "-H " + exponent;
	}

	private String convertStateSpaceReduction(String stateSpaceReduction) {
		final String paremterName = "-S ";
		switch (stateSpaceReduction) {
		case STATE_SPACE_REDUCTION_NONE:
			// BFS
			return paremterName + "0";
		case STATE_SPACE_REDUCTION_CONSERVATIVE:
			// DFS
			return paremterName + "1";
		case STATE_SPACE_REDUCTION_AGGRESSIVE:
			// Random DFS
			return paremterName + "2";
		default:
			throw new IllegalArgumentException("Not known option: " + stateSpaceReduction);
		}
	}

	private String convertReuseStateSpace(boolean isReuseStateSpace) {
		return isReuseStateSpace ? "-T" : "";
	}

	private String convertDiagnosticTrace(String trace) {
		switch (trace) {
		case TRACE_SOME:
			// Some trace
			return "-t0";
		case TRACE_SHORTEST:
			// Shortest trace
			return "-t1";
		case TRACE_FASTEST:
			// Fastest trace
			return "-t2";
		default:
			throw new IllegalArgumentException("Not known option: " + trace);
		}
	}

}
