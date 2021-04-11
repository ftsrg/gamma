package hu.bme.mit.gamma.plantuml.serialization

import java.io.ByteArrayOutputStream
import java.nio.charset.Charset
import net.sourceforge.plantuml.FileFormat
import net.sourceforge.plantuml.FileFormatOption
import net.sourceforge.plantuml.SourceStringReader

class SvgSerializer {
	// Singleton
	public static final SvgSerializer INSTANCE = new SvgSerializer
	//
	
	def serialize(String plantUmlString) {
		  try (val os = new ByteArrayOutputStream) {
			val reader = new SourceStringReader(plantUmlString)
			reader.outputImage(os, new FileFormatOption(FileFormat.SVG)).description
			val svg = new String(os.toByteArray, Charset.forName("UTF-8"))
			return svg
		  }
	 }

}