package hu.bme.mit.gamma.tutorial.contract.finish.interfaces;

import java.util.List;
import hu.bme.mit.gamma.tutorial.contract.finish.*;

public interface ControlInterface {

	interface Provided extends Listener.Required {
		
		boolean isRaisedToggle();
		
		void registerListener(Listener.Provided listener);
		List<Listener.Provided> getRegisteredListeners();
	}
	
	interface Required extends Listener.Provided {
		
		
		void registerListener(Listener.Required listener);
		List<Listener.Required> getRegisteredListeners();
	}
	
	interface Listener {
		
	interface Provided {
		void raiseToggle();
		}
		
	interface Required {
		}
		
	}

}
