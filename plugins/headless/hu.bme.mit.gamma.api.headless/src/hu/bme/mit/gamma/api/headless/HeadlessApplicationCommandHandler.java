package hu.bme.mit.gamma.api.headless;

import org.eclipse.equinox.app.IApplicationContext;

public abstract class HeadlessApplicationCommandHandler {
	final IApplicationContext context;
	final String[] appArgs;
	
	
	public HeadlessApplicationCommandHandler(IApplicationContext context, String[] appArgs) {
		this.context = context;
		this.appArgs = appArgs;
	}
	
	public void execute() throws Exception {
	}
}
