import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo Chinese TTS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Chinese Text-to-Speech Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _textController = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  String _selectedLanguage = "zh-CN";
  double _speechRate = 0.5;
  double _pitch = 1.0;

  final Map<String, String> _languages = {
    "zh-CN": "中国語（簡体字）",
    "zh-TW": "中国語（繁体字）",
    "ja-JP": "日本語",
    "en-US": "英語",
  };

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    await _flutterTts.setLanguage(_selectedLanguage);
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(_pitch);

    _flutterTts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
      });
    });

    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });

    _flutterTts.setErrorHandler((msg) {
      setState(() {
        _isSpeaking = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('TTS Error: $msg')),
      );
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _speak() async {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      if (_isSpeaking) {
        await _flutterTts.stop();
      } else {
        await _flutterTts.speak(text);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('テキストを入力してください')),
      );
    }
  }

  void _changeLanguage(String? language) async {
    if (language != null) {
      setState(() {
        _selectedLanguage = language;
      });
      await _flutterTts.setLanguage(language);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'テキストを入力してください:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            
            // 言語選択
            Row(
              children: [
                const Text('言語: ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedLanguage,
                    onChanged: _changeLanguage,
                    items: _languages.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // テキスト入力フィールド
            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'ここにテキストを入力...\n例: 你好世界 (こんにちは世界)',
              ),
            ),
            const SizedBox(height: 20),
            
            // 速度調整
            Row(
              children: [
                const Text('速度: '),
                Expanded(
                  child: Slider(
                    value: _speechRate,
                    min: 0.1,
                    max: 1.0,
                    divisions: 9,
                    label: _speechRate.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        _speechRate = value;
                      });
                      _flutterTts.setSpeechRate(value);
                    },
                  ),
                ),
              ],
            ),
            
            // 音の高さ調整
            Row(
              children: [
                const Text('音の高さ: '),
                Expanded(
                  child: Slider(
                    value: _pitch,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    label: _pitch.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        _pitch = value;
                      });
                      _flutterTts.setPitch(value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // 音声再生ボタン
            ElevatedButton.icon(
              onPressed: _speak,
              icon: Icon(_isSpeaking ? Icons.stop : Icons.volume_up),
              label: Text(_isSpeaking ? '停止' : '音声再生'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: _isSpeaking ? Colors.red : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
