package hu.bme.mit.gamma.scenario.reduction;

public class FragmentInteractionPair {
	
	private int fragment=-1;
	
	private int interaction=-1;

	public int getFragment() {
		return fragment;
	}

	public int getInteraction() {
		return interaction;
	}

	public FragmentInteractionPair(int fragment, int interaction) {
		this.fragment = fragment;
		this.interaction = interaction;
	}
}
