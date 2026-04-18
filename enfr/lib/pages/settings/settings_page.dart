import 'package:enfr/services/api_key_service.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    ApiKeyService.loadKey().then((key) {
      if (key != null && mounted) setState(() => _controller.text = key);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ApiKeyService.saveKey(_controller.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('API key saved')));
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
              'On web, your key is stored in browser localStorage.\n'
              'On Android it is encrypted using the Android Keystore.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
