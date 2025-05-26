import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceSearchWidget extends StatefulWidget {
  final Function(String) onSearch;
  final TextEditingController searchController;
  final String hintText;

  const VoiceSearchWidget({
    super.key,
    required this.onSearch,
    required this.searchController,
    this.hintText = 'Search...',
  });

  @override
  State<VoiceSearchWidget> createState() => _VoiceSearchWidgetState();
}

class _VoiceSearchWidgetState extends State<VoiceSearchWidget> {
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    try {
      final status = await Permission.microphone.request();
      if (status.isGranted) {
        _isInitialized = await _speechToText.initialize(
          onError: (error) => debugPrint('Speech recognition error: $error'),
          onStatus: (status) => debugPrint('Speech recognition status: $status'),
        );
        setState(() {});
      } else {
        debugPrint('Microphone permission denied');
      }
    } catch (e) {
      debugPrint('Error initializing speech: $e');
    }
  }

  Future<void> _startListening() async {
    if (!_isInitialized) {
      await _initializeSpeech();
    }

    if (!_isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return;
    }

    try {
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            final text = result.recognizedWords;
            widget.searchController.text = text;
            widget.onSearch(text);
            setState(() => _isListening = false);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US',
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );
      setState(() => _isListening = true);
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error starting speech recognition')),
      );
    }
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: widget.searchController,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onSubmitted: widget.onSearch,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _isListening ? _stopListening : _startListening,
          icon: Icon(
            _isListening ? Icons.mic : Icons.mic_none,
            color: _isListening ? Theme.of(context).colorScheme.primary : null,
          ),
          tooltip: _isListening ? 'Stop listening' : 'Start voice search',
        ),
      ],
    );
  }

  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }
} 