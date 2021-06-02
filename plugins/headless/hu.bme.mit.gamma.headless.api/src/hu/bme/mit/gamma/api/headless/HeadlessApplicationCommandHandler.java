package hu.bme.mit.gamma.api.headless;

import java.util.logging.Logger;

import org.eclipse.equinox.app.IApplicationContext;

public abstract class HeadlessApplicationCommandHandler {
	final IApplicationContext context;
	final String[] appArgs;
	protected Logger logger = Logger.getLogger("GammaLogger");

	public HeadlessApplicationCommandHandler(IApplicationContext context, String[] appArgs) {
		this.context = context;
		this.appArgs = appArgs;
	}

	public void execute() throws Exception {
	}
}
