// lib/features/convert/presentation/pages/home_page.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vitale/features/convert/domain/entities/conversion_result.dart';
import 'package:vitale/features/convert/domain/entities/engine_info.dart';
import 'package:vitale/features/convert/domain/entities/source_input.dart';
import 'package:vitale/features/convert/presentation/controllers/convert_controller.dart';

/// Pantalla principal: pegar o elegir una entrada y ver el Markdown resultante.
///
/// Es un `ConsumerWidget` reactivo: observa [convertControllerProvider] y
/// renderiza el estado (`loading`/`error`/`data`) de forma declarativa.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _pickFile(BuildContext context, WidgetRef ref) async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['html', 'htm', 'mhtml'],
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      await ref.read(convertControllerProvider.notifier).convert(
            FileInput(path: file.path ?? '', filename: file.name, bytes: bytes),
            preferredEngine: EngineId.html2md,
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(convertControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Vitale')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Pegar HTML o MHTML, o elegir un archivo (.html/.mhtml)'),
            const SizedBox(height: 12),
            _PasteField(
              isLoading: state.isLoading,
              onConvertText: (text) {
                if (text.isEmpty) return;
                ref.read(convertControllerProvider.notifier).convert(
                      PastedInput(text),
                      preferredEngine: EngineId.html2md,
                    );
              },
              onPickFile: () => _pickFile(context, ref),
            ),
            const SizedBox(height: 12),
            state.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('$error', style: const TextStyle(color: Colors.red)),
              ),
              data: (result) => result == null
                  ? const SizedBox.shrink()
                  : _ResultView(result: result),
            ),
          ],
        ),
      ),
    );
  }
}

/// Campo de pegado que posee su propio `TextEditingController`.
///
/// Estado puramente de UI (texto y ciclo de vida del controller); no guarda
/// estado de conversión.
class _PasteField extends StatefulWidget {
  const _PasteField({
    required this.isLoading,
    required this.onConvertText,
    required this.onPickFile,
  });

  final bool isLoading;
  final ValueChanged<String> onConvertText;
  final VoidCallback onPickFile;

  @override
  State<_PasteField> createState() => _PasteFieldState();
}

class _PasteFieldState extends State<_PasteField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              onPressed: widget.isLoading
                  ? null
                  : () => widget.onConvertText(_controller.text),
              child: const Text('Convertir desde texto'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: widget.isLoading ? null : widget.onPickFile,
              child: const Text('Elegir archivo'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Vista del resultado de conversión.
class _ResultView extends StatelessWidget {
  const _ResultView({required this.result});

  final ConversionResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Motor: ${result.engineId.name} | MHTML: ${result.wasMhtml} | '
          'Filtrado: ${result.wasFiltered}',
        ),
        const SizedBox(height: 8),
        const Text('Markdown:'),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SelectableText(result.markdown),
        ),
      ],
    );
  }
}
