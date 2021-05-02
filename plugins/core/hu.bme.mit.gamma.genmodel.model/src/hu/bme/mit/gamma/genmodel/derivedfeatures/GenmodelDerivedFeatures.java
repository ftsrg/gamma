package hu.bme.mit.gamma.genmodel.derivedfeatures;

import java.util.ArrayList;
import java.util.List;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.genmodel.model.ActivityReference;
import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation;
import hu.bme.mit.gamma.genmodel.model.ComponentReference;
import hu.bme.mit.gamma.genmodel.model.GenModel;
import hu.bme.mit.gamma.genmodel.model.ModelReference;
import hu.bme.mit.gamma.genmodel.model.Task;
import hu.bme.mit.gamma.genmodel.model.XSTSReference;

public class GenmodelDerivedFeatures extends ExpressionModelDerivedFeatures {

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
	
	public static EObject getModel(AnalysisModelTransformation analysisModelTransformation) {
		ModelReference modelReference = analysisModelTransformation.getModel();
		if (modelReference instanceof ComponentReference) {
			ComponentReference componentReference = (ComponentReference) modelReference;
			return componentReference.getComponent();
		}
		if (modelReference instanceof XSTSReference) {
			XSTSReference xStsReference = (XSTSReference) modelReference;
			return xStsReference.getXSts();
		}
		if (modelReference instanceof ActivityReference) {
			ActivityReference activityReference = (ActivityReference) modelReference;
			return activityReference.getActivity();
		}
		throw new IllegalArgumentException("Not supported model reference: " + modelReference);
	}
	
}
