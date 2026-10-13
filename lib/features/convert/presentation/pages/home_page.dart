// lib/features/convert/presentation/pages/home_page.dart
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/result.dart';
import '../../domain/entities/conversion_result.dart';
import '../../domain/entities/engine_info.dart';
import '../../domain/entities/source_input.dart';
import '../controllers/providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _controller = TextEditingController();
  bool _loading = false;
  ConversionResult? _result;
  String? _error;

  Future<void> _pickFile() async {
    try {
      final res = await FilePicker.platform.pickFiles(withData: true);
      if (res == null || res.files.isEmpty) return;
      final f = res.files.first;
      final bytes = f.bytes ?? Uint8List(0);
      final input = FileInput(path: f.path ?? '', filename: f.name, bytes: bytes);
      await _convert(input);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _pasteAndConvert() async {
    final text = _controller.text;
    if (text.isEmpty) return;
    await _convert(PastedInput(text));
  }

  Future<void> _convert(SourceInput input) async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    final uc = ref.read(convertHtmlToMarkdownProvider);
    final r = await uc.call(input, preferredEngine: EngineId.html2md);
    setState(() {
      _loading = false;
      if (r is Ok<ConversionResult>) {
        _result = r.value;
      } else {
        final err = r as Err<ConversionResult>;
        _error = err.failure.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vitale'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Pegar HTML o MHTML, o elegir un archivo (.html/.mhtml)'),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '<html>...</html> o contenido MHTML',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton(
                  onPressed: _loading ? null : _pasteAndConvert,
                  child: const Text('Convertir desde texto'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _loading ? null : _pickFile,
                  child: const Text('Elegir archivo'),
                ),
              ],
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              Text('Motor: ${_result!.engineId.name} | MHTML: ${_result!.wasMhtml} | Filtrado: ${_result!.wasFiltered}'),
              const SizedBox(height: 8),
              const Text('Markdown:'),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                child: SelectableText(_result!.markdown),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
