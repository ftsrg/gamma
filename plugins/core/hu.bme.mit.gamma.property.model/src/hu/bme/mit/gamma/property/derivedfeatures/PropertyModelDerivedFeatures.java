package hu.bme.mit.gamma.property.derivedfeatures;

import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Package;

public class PropertyModelDerivedFeatures extends StatechartModelDerivedFeatures {

	public static boolean isUnfolded(PropertyPackage propertyPackage) {
		Component component = propertyPackage.getComponent();
		Package containingPackage = getContainingPackage(component);
		return isUnfolded(containingPackage);
		// Atomic instance references?
	}
	
}
