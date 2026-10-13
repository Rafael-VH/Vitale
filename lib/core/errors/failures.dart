// lib/core/errors/failures.dart
sealed class Failure {
  final String message;
  const Failure(this.message);
}

class MhtmlParseFailure extends Failure {
  const MhtmlParseFailure([super.message = 'No se pudo leer el archivo MHTML.']);
}

class EmptyInputFailure extends Failure {
  const EmptyInputFailure([super.message = 'El contenido está vacío.']);
}

class UnsupportedFormatFailure extends Failure {
  const UnsupportedFormatFailure([super.message = 'Formato no soportado.']);
}

class ConversionFailure extends Failure {
  const ConversionFailure([super.message = 'Falló la conversión a Markdown.']);
}

class FileReadFailure extends Failure {
  const FileReadFailure([super.message = 'No se pudo leer el archivo.']);
}

class SaveFailure extends Failure {
  const SaveFailure([super.message = 'No se pudo guardar el archivo.']);
}

class EngineUnavailableFailure extends Failure {
  const EngineUnavailableFailure([super.message = 'No hay ningún motor de conversión disponible en esta plataforma.']);
}

class AllEnginesFailedFailure extends Failure {
  const AllEnginesFailedFailure([super.message = 'Ningún motor pudo convertir el contenido.']);
}
