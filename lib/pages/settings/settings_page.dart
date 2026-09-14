import 'package:enfr/services/api_key_service.dart';
import 'package:enfr/services/model_preference_service.dart';
import 'package:flutter/material.dart';
import 'package:mistralai_client_dart/mistralai_client_dart.dart';

const List<String> _kFallbackModels = [
  'mistral-small-latest',
  'mistral-medium-latest',
  'mistral-large-latest',
];

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _controller = TextEditingController();
  bool _obscure = true;

  List<String> _models = _kFallbackModels;
  String? _selectedModel;
  bool _loadingModels = false;

  @override
  void initState() {
    super.initState();
    ApiKeyService.loadKey().then((key) {
      if (key != null && mounted) setState(() => _controller.text = key);
    });
    ModelPreferenceService.loadModel().then((model) {
      if (mounted) {
        setState(() {
          _selectedModel = model;
          if (!_models.contains(model)) _models = [model, ..._models];
        });
      }
    });
    _refreshModels();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _refreshModels() async {
    final key = _controller.text.trim();
    if (key.isEmpty) return;

    setState(() => _loadingModels = true);
    try {
      final client = MistralAIClient(apiKey: key);
      final response = await client.listModels();
      final models = (response.data ?? [])
          .where((m) => m.capabilities.completionChat)
          .map((m) => m.id)
          .toList();
      if (mounted && models.isNotEmpty) {
        setState(() {
          _models = models;
          if (_selectedModel == null || !_models.contains(_selectedModel)) {
            _selectedModel = _models.first;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not fetch models, showing defaults')));
      }
    } finally {
      if (mounted) setState(() => _loadingModels = false);
    }
  }

  Future<void> _save() async {
    await ApiKeyService.saveKey(_controller.text.trim());
    if (_selectedModel != null) {
      await ModelPreferenceService.saveModel(_selectedModel!);
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Settings saved')));
    }
  }

  Future<void> _clear() async {
    await ApiKeyService.clearKey();
    if (mounted) {
      setState(() => _controller.clear());
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('API key cleared')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mistral API Key',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              obscureText: _obscure,
              decoration: InputDecoration(
                hintText: 'Enter your Mistral API key',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Model', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedModel,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: _models
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedModel = value),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _loadingModels
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  onPressed: _loadingModels ? null : _refreshModels,
                  tooltip: 'Refresh models',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton(onPressed: _save, child: const Text('Save')),
                const SizedBox(width: 12),
                OutlinedButton(onPressed: _clear, child: const Text('Clear')),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Your key is stored in browser localStorage.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
