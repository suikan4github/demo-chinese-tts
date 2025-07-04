import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:pinyin/pinyin.dart';

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
  String _pinyinText = "";
  bool _showPinyin = false;

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('TTS Error: $msg')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('テキストを入力してください')));
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

  void _convertToPinyin() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      // 中国語文字が含まれているかチェック
      if (RegExp(r'[\u4e00-\u9fff]').hasMatch(text)) {
        final pinyin = PinyinHelper.getPinyinE(
          text,
          separator: ' ',
          format: PinyinFormat.WITH_TONE_MARK,
        );
        setState(() {
          _pinyinText = pinyin;
          _showPinyin = true;
        });
      } else {
        setState(() {
          _pinyinText = "";
          _showPinyin = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('中国語文字が検出されませんでした')));
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('テキストを入力してください')));
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
        padding: const EdgeInsets.all(12.0), // スマホ最適化：パディング縮小
        child: SingleChildScrollView(
          // スクロール可能にして画面に収める
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'テキストを入力してください:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // 言語選択（コンパクト化）
              Row(
                children: [
                  const Text('言語: ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedLanguage,
                      onChanged: _changeLanguage,
                      isExpanded: true,
                      items: _languages.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Text(
                            entry.value,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // テキスト入力フィールド（スマホ最適化：2行に縮小）
              TextField(
                controller: _textController,
                maxLines: 2,
                minLines: 2,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '中国語テキストを入力\n例: 你好世界',
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 15),

              // ピンイン表示エリア（拡大）
              if (_showPinyin) ...[
                Container(
                  padding: const EdgeInsets.all(16), // パディングを拡大
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ピンイン（声調記号付き）:',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        constraints: const BoxConstraints(
                          minHeight: 80, // 最小高さを設定して表示エリアを拡大
                        ),
                        child: SelectableText(
                          _pinyinText,
                          style: const TextStyle(
                            fontSize: 18, // フォントサイズを拡大
                            fontFamily: 'monospace',
                            height: 1.4, // 行間を設定
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
              ],

              // 音声再生とピンイン変換ボタン（横並び）
              Row(
                children: [
                  // 音声再生ボタン
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _speak,
                      icon: Icon(
                        _isSpeaking ? Icons.stop : Icons.volume_up,
                        size: 20,
                      ),
                      label: Text(
                        _isSpeaking ? '停止' : '音声再生',
                        style: const TextStyle(fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        backgroundColor: _isSpeaking ? Colors.red : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ピンイン変換ボタン
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _convertToPinyin,
                      icon: const Icon(Icons.translate, size: 20),
                      label: const Text('ピンイン', style: TextStyle(fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // 音声調整（音声再生後に配置）
              const Text(
                '音声調整:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // 速度調整
              Row(
                children: [
                  const Text('速度: ', style: TextStyle(fontSize: 14)),
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
                  Text(
                    '${_speechRate.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),

              // 音の高さ調整
              Row(
                children: [
                  const Text('音高: ', style: TextStyle(fontSize: 14)),
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
                  Text(
                    '${_pitch.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ], // Column children 終了
          ), // Column 終了 (SingleChildScrollView の child)
        ), // SingleChildScrollView 終了 (Padding の child)
      ), // Padding 終了 (Scaffold body)
    ); // Scaffold 終了 (return の値)
  }
}
