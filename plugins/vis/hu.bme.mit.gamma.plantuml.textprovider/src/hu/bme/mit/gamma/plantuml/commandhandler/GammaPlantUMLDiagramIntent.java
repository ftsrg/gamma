package hu.bme.mit.gamma.plantuml.commandhandler;

import net.sourceforge.plantuml.util.AbstractDiagramIntent;

public class GammaPlantUMLDiagramIntent extends AbstractDiagramIntent<String> {

	public GammaPlantUMLDiagramIntent(String source) {
		super(source);
		plantUMLDiagramText = source;
	}

	protected String plantUMLDiagramText;
	

	public String getDiagramText() {
		// TODO Auto-generated method stub
		return plantUMLDiagramText;
	}
	
	public void setDiagramText(String diagramText) {
		plantUMLDiagramText = diagramText;
	}


}
