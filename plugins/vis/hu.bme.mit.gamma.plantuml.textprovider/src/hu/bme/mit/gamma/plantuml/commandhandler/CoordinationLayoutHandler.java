package hu.bme.mit.gamma.plantuml.commandhandler;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;
import org.eclipse.ui.handlers.HandlerUtil;
import org.eclipse.ui.handlers.RadioState;

public class CoordinationLayoutHandler extends AbstractHandler {

	@Override
	public Object execute(ExecutionEvent event) throws ExecutionException {

		if (HandlerUtil.matchesRadioState(event))
			return null; // we are already in the updated state - do nothing

		String currentState = event.getParameter(RadioState.PARAMETER_ID);
		// update the current state
		HandlerUtil.updateRadioState(event.getCommand(), currentState);

		return null;
	}

}