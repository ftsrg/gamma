package hu.bme.mit.gamma.ui.taskhandler;

import static com.google.common.base.Preconditions.checkArgument;

import java.io.IOException;

import hu.bme.mit.gamma.eventpriority.transformation.EventPriorityTransformer;
import hu.bme.mit.gamma.genmodel.model.EventPriorityTransformation;
import hu.bme.mit.gamma.statechart.model.Package;
import hu.bme.mit.gamma.statechart.model.StatechartDefinition;

public class EventPriorityTransformationHandler extends TaskHandler {

	public void execute(EventPriorityTransformation eventPriorityTransformation) throws IOException {
		setFileName(eventPriorityTransformation);
		StatechartDefinition statechart = eventPriorityTransformation.getStatechart();
		EventPriorityTransformer eventPriorityTransformer = new EventPriorityTransformer(statechart);
		Package prioritizedTransitionsStatechartPackage = eventPriorityTransformer.execute();
		saveModel(prioritizedTransitionsStatechartPackage,
				targetFolderUri, eventPriorityTransformation.getFileName().get(0) + ".gcd");
	}
	
	private void setFileName(EventPriorityTransformation eventPriorityTransformation) {
		String fileName = getNameWithoutExtension(getContainingFileName(eventPriorityTransformation.getStatechart()));
		checkArgument(eventPriorityTransformation.getFileName().size() <= 1);
		if (eventPriorityTransformation.getFileName().isEmpty()) {
			eventPriorityTransformation.getFileName().add(fileName);
		}
	}
	
}
