package hu.bme.mit.gamma.plantuml.transformation

import hu.bme.mit.gamma.trace.model.ExecutionTrace
import org.eclipse.emf.ecore.resource.Resource

class TraceToPlantUMLTransformer {
	
	protected final ExecutionTrace trace
	
	new(Resource resource) {
		this.trace = resource.contents.head as ExecutionTrace
	}
	
	def execute() {
		return '''
			title "Messages - Sequence Diagram"
			
			actor User
			boundary "Web GUI" as GUI
			control "Shopping Cart" as SC
			entity Widget
			database Widgets
			
			User -> GUI : To boundary
			GUI -> SC : To control
			SC -> Widget : To entity
			Widget -> Widgets : To database			
		'''
	}
	
}