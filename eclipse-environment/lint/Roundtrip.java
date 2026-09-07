import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.oomph.base.util.BaseResourceFactoryImpl;
import java.io.FileOutputStream;
import java.util.HashMap;

/** Loads an Oomph .setup with the generated packages and writes it straight back out. */
public final class Roundtrip {
  private static final String[] PACKAGES = {
    "org.eclipse.oomph.base.BasePackage", "org.eclipse.oomph.setup.SetupPackage",
    "org.eclipse.oomph.setup.git.GitPackage", "org.eclipse.oomph.setup.jdt.JDTPackage",
    "org.eclipse.oomph.setup.p2.SetupP2Package", "org.eclipse.oomph.setup.targlets.SetupTargletsPackage",
    "org.eclipse.oomph.setup.workingsets.SetupWorkingSetsPackage", "org.eclipse.oomph.predicates.PredicatesPackage",
    "org.eclipse.oomph.resources.ResourcesPackage", "org.eclipse.oomph.targlets.TargletPackage",
    "org.eclipse.oomph.p2.P2Package",
  };
  public static void main(String[] args) throws Exception {
    for (String p : PACKAGES) Class.forName(p).getField("eINSTANCE").get(null);
    ResourceSet rs = new ResourceSetImpl();
    rs.getResourceFactoryRegistry().getExtensionToFactoryMap()
      .put(Resource.Factory.Registry.DEFAULT_EXTENSION, new BaseResourceFactoryImpl());
    Resource r = rs.getResource(URI.createFileURI(new java.io.File(args[0]).getAbsolutePath()), true);
    try (FileOutputStream out = new FileOutputStream(args[1])) {
      r.save(out, new HashMap<>());
    }
  }
}
