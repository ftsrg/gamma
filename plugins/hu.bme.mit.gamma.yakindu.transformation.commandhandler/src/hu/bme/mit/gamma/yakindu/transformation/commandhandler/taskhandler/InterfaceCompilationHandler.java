package hu.bme.mit.gamma.yakindu.transformation.commandhandler.taskhandler;

import java.io.IOException;
import java.util.AbstractMap.SimpleEntry;

import hu.bme.mit.gamma.statechart.model.Package;
import hu.bme.mit.gamma.genmodel.model.InterfaceCompilation;
import hu.bme.mit.gamma.yakindu.transformation.batch.InterfaceTransformer;
import hu.bme.mit.gamma.yakindu.transformation.traceability.Y2GTrace;

public class InterfaceCompilationHandler extends YakinduCompilationHandler {

	public void execute(InterfaceCompilation interfaceCompilation) throws IOException {
		setYakinduCompilation(interfaceCompilation);
		InterfaceTransformer transformer = new InterfaceTransformer(
				interfaceCompilation.getStatechart(), interfaceCompilation.getPackageName().get(0));
		SimpleEntry<Package, Y2GTrace> resultModels = transformer.execute();
		saveModel(resultModels.getKey(), targetFolderUri, interfaceCompilation.getFileName().get(0) + ".gcd");
		saveModel(resultModels.getValue(), targetFolderUri, "." + interfaceCompilation.getFileName().get(0)  + ".y2g");
	}

}
