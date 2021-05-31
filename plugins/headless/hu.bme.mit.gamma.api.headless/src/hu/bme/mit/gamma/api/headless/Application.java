package hu.bme.mit.gamma.api.headless;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Arrays;
import java.util.Map;
import org.eclipse.core.resources.IContainer;
import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IFolder;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IProjectDescription;
import org.eclipse.core.resources.IWorkspace;
import org.eclipse.core.resources.IWorkspaceRoot;
import org.eclipse.core.resources.ResourcesPlugin;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.core.runtime.IPath;
import org.eclipse.core.runtime.IProgressMonitor;
import org.eclipse.core.runtime.NullProgressMonitor;
import org.eclipse.core.runtime.Path;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.equinox.app.IApplication;
import org.eclipse.equinox.app.IApplicationContext;
import org.eclipse.xtext.resource.XtextResourceSet;

import hu.bme.mit.gamma.action.language.ActionLanguageStandaloneSetup;
import hu.bme.mit.gamma.ui.GammaApi;
import hu.bme.mit.gamma.ui.GammaApi.ResourceSetCreator;
import hu.bme.mit.gamma.expression.language.ExpressionLanguageStandaloneSetup;
import hu.bme.mit.gamma.genmodel.language.GenModelStandaloneSetup;
import hu.bme.mit.gamma.property.language.PropertyLanguageStandaloneSetup;
import hu.bme.mit.gamma.statechart.language.StatechartLanguageStandaloneSetup;
import hu.bme.mit.gamma.statechart.language.StatechartLanguageStandaloneSetupGenerated;
import hu.bme.mit.gamma.trace.language.TraceLanguageStandaloneSetup;
import com.google.gson.Gson;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.google.inject.Injector;

import org.apache.commons.io.FileUtils;

public class Application implements IApplication {

	private GammaEntryPoint gammaEntryPoint;
	private ProjectImporter projectImporter;
	private WorkspaceGenerator workspaceGenerator;

	@Override
	public Object start(final IApplicationContext context) throws Exception {

		final Map<?, ?> args = context.getArguments();
		final String[] appArgs = (String[]) args.get(IApplicationContext.APPLICATION_ARGS);

		if (appArgs.length == 0) {
			System.out.println("Arguments must be given!");
			return null;
		} else {
			switch (appArgs[0]) {
			case "workspace":
				workspaceGenerator = new WorkspaceGenerator(context, appArgs);
				workspaceGenerator.execute();
				break;
			case "import":
				projectImporter = new ProjectImporter(context, appArgs);
				projectImporter.execute();
				break;
			case "gamma":
				gammaEntryPoint = new GammaEntryPoint(context, appArgs);
				gammaEntryPoint.execute();
				break;
			}
		}

		return IApplication.EXIT_OK;
	}

	@Override
	public void stop() {

	}

}