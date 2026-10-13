// lib/features/convert/domain/entities/source_input.dart
sealed class SourceInput {
  const SourceInput();
}

class FileInput extends SourceInput {
  final String path;
  final String filename;
  final List<int> bytes;
  const FileInput({required this.path, required this.filename, required this.bytes});
}

class PastedInput extends SourceInput {
  final String text;
  const PastedInput(this.text);
}
