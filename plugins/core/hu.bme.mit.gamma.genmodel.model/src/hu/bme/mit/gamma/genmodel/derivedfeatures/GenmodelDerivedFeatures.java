package hu.bme.mit.gamma.genmodel.derivedfeatures;

import java.util.ArrayList;
import java.util.List;

import hu.bme.mit.gamma.genmodel.model.GenModel;
import hu.bme.mit.gamma.genmodel.model.Task;

public class GenmodelDerivedFeatures {

	public static List<Task> getIncludedTasks(GenModel genmodel) {
		List<Task> tasks = getAllTasks(genmodel);
		tasks.removeAll(genmodel.getTasks());
		return tasks;
	}
	
	public static List<Task> getAllTasks(GenModel genmodel) {
		List<Task> tasks = new ArrayList<Task>(genmodel.getTasks());
		for (GenModel includedGenmodel : genmodel.getGenmodelImports()) {
			tasks.addAll(getAllTasks(includedGenmodel));
		}
		return tasks;
	}
	
}
