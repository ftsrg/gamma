package hu.bme.mit.gamma.yakindu.transformation.commandhandler.taskhandler;

import static com.google.common.base.Preconditions.checkArgument;

import hu.bme.mit.gamma.yakindu.genmodel.YakinduCompilation;

public abstract class YakinduCompilationHandler extends TaskHandler {
	
	public void setYakinduCompilation(YakinduCompilation yakinduCompilation) {
		String fileName = getNameWithoutExtension(getContainingFileName(yakinduCompilation.getStatechart()));
		checkArgument(yakinduCompilation.getFileName().size() <= 1);
		checkArgument(yakinduCompilation.getPackageName().size() <= 1);
		if (yakinduCompilation.getFileName().isEmpty()) {
			yakinduCompilation.getFileName().add(fileName);
		}
		if (yakinduCompilation.getPackageName().isEmpty()) {
			yakinduCompilation.getPackageName().add(fileName);
		}
	}
}
