import 'package:enfr/services/api_key_service.dart';
import 'package:enfr/services/eleven_labs_settings_service.dart';
import 'package:enfr/services/model_preference_service.dart';
import 'package:enfr/services/text_to_speech_service.dart';
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

  final _elevenLabsController = TextEditingController();
  bool _elevenLabsObscure = true;

  /// Voice id → voice: the account's own voices followed by Québec voices
  /// from the Voice Library. Starts with just the saved voice until fetched.
  Map<String, Voice> _voices = {};
  String? _selectedVoice;
  bool _loadingVoices = false;

  @override
  void initState() {
    super.initState();
    ApiKeyService.loadKey().then((key) {
      if (key != null && mounted) setState(() => _controller.text = key);
    });
    ElevenLabsSettingsService.loadVoice().then((voice) {
      if (mounted) {
        setState(() {
          _selectedVoice = voice;
          _voices.putIfAbsent(
              voice,
              () => Voice(
                  voice,
                  voice == ElevenLabsSettingsService.defaultVoice
                      ? 'George (default)'
                      : voice));
        });
      }
    });
    ElevenLabsSettingsService.loadKey().then((key) {
      if (key != null && mounted) {
        setState(() => _elevenLabsController.text = key);
        _refreshVoices();
      }
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
    _elevenLabsController.dispose();
    super.dispose();
  }

  Future<void> _refreshVoices() async {
    final key = _elevenLabsController.text.trim();
    if (key.isEmpty) return;

    setState(() => _loadingVoices = true);
    final tts = TextToSpeechService();
    // Fetched independently so one failing doesn't hide the other's voices.
    // Keys restricted to text-to-speech can't list voices; the saved or
    // default voice still works.
    final results = await Future.wait([
      tts.listVoices(key).then<List<Voice>?>((v) => v, onError: (_) => null),
      tts
          .listQuebecVoices(key)
          .then<List<Voice>?>((v) => v, onError: (_) => null),
    ]);
    if (!mounted) return;
    final [own, quebec] = results;
    setState(() {
      _loadingVoices = false;
      final saved = _selectedVoice == null ? null : _voices[_selectedVoice];
      _voices = {for (final v in own ?? const <Voice>[]) v.id: v};
      // Library voices already in the account stay listed as own voices.
      for (final v in quebec ?? const <Voice>[]) {
        _voices.putIfAbsent(v.id, () => v);
      }
      if (_selectedVoice != null && !_voices.containsKey(_selectedVoice)) {
        if (saved != null) {
          _voices[_selectedVoice!] = saved;
        } else {
          _selectedVoice = _voices.keys.firstOrNull;
        }
      }
    });
    if (own == null || quebec == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(own == null && quebec == null
              ? 'Could not fetch voices, showing default'
              : own == null
                  ? 'Could not fetch your voices'
                  : 'Could not fetch Québec voices')));
    }
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
    final elevenLabsKey = _elevenLabsController.text.trim();
    await ElevenLabsSettingsService.saveKey(elevenLabsKey);
    final voice = _selectedVoice == null ? null : _voices[_selectedVoice];
    if (voice != null) {
      var voiceId = voice.id;
      if (voice.isShared) {
        // Library voices must be in the account before text-to-speech can
        // use them.
        try {
          voiceId =
              await TextToSpeechService().addSharedVoice(elevenLabsKey, voice);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not add ${voice.name}: $e')));
          }
          return;
        }
      }
      await ElevenLabsSettingsService.saveVoice(voiceId);
    }
    if (mounted) {
      // The root ScaffoldMessenger keeps showing this on the page below.
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Settings saved')));
      Navigator.of(context).pop();
    }
  }

  Future<void> _clear() async {
    await ApiKeyService.clearKey();
    await ElevenLabsSettingsService.clearKey();
    if (mounted) {
      setState(() {
        _controller.clear();
        _elevenLabsController.clear();
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('API keys cleared')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
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
            const SizedBox(height: 24),
            const Text('ElevenLabs API Key',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _elevenLabsController,
              obscureText: _elevenLabsObscure,
              decoration: InputDecoration(
                hintText: 'Enter your ElevenLabs API key',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_elevenLabsObscure
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () =>
                      setState(() => _elevenLabsObscure = !_elevenLabsObscure),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Voice', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    // Keyed on the voice list so the field picks up a new
                    // selection after the voices are fetched.
                    key: ValueKey(_voices.keys.join(',')),
                    initialValue: _selectedVoice,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: _voices.values
                        .map((v) => DropdownMenuItem(
                            value: v.id,
                            child: Text(
                              v.isShared ? '${v.name} · Québec' : v.name,
                              overflow: TextOverflow.ellipsis,
                            )))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedVoice = value),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _loadingVoices
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  onPressed: _loadingVoices ? null : _refreshVoices,
                  tooltip: 'Refresh voices',
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
              'Your keys are stored in browser localStorage.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
