import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_player/video_player.dart';
import 'web_helper.dart' if (dart.library.html) 'web_helper_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  if (!kIsWeb) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
  runApp(const PianoGameApp());
}

class PianoGameApp extends StatelessWidget {
  const PianoGameApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Piano Tiles: Fire and Ice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.red,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red, brightness: Brightness.dark),
      ),
      home: const CompanySplashScreen(),
    );
  }
}

Route _fadeRoute(Widget p) => PageRouteBuilder(
  pageBuilder: (c, a, s) => p,
  transitionDuration: 1.seconds,
  transitionsBuilder: (c, a, s, ch) => FadeTransition(opacity: a, child: ch),
);

Route _blackFadeRoute(Widget p) => PageRouteBuilder(
  pageBuilder: (c, a, s) => p,
  transitionDuration: 2.seconds,
  transitionsBuilder: (c, a, s, ch) => Stack(children: [Container(color: Colors.black), FadeTransition(opacity: a, child: ch)]),
);

class AppFile {
  final String name; final String? path; final Uint8List? bytes; final String? webUrl;
  AppFile({required this.name, this.path, this.bytes, this.webUrl});
}

class PianoTile {
  final int spawnTime; final int column; final Color color; double y = -0.1;
  PianoTile({required this.spawnTime, required this.column, required this.color});
}

class CompanySplashScreen extends StatefulWidget {
  const CompanySplashScreen({super.key});
  @override State<CompanySplashScreen> createState() => _CompanySplashScreenState();
}

class _CompanySplashScreenState extends State<CompanySplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(2500.ms, () {
      if (mounted) Navigator.of(context).pushReplacement(_fadeRoute(const GameSplashScreen()));
    });
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Center(child: Image.asset('assets/images/splash_company.png',
        errorBuilder: (c, e, s) => const Text("COMPANY", style: TextStyle(fontSize: 40, color: Colors.white, letterSpacing: 12)))
        .animate().fadeIn(duration: 1.seconds).then().fadeOut(delay: 500.ms)),
  );
}

class GameSplashScreen extends StatefulWidget {
  const GameSplashScreen({super.key});
  @override State<GameSplashScreen> createState() => _GameSplashScreenState();
}

class _GameSplashScreenState extends State<GameSplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(2500.ms, () {
      if (mounted) Navigator.of(context).pushReplacement(_fadeRoute(const LoadingScreen()));
    });
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Center(child: Image.asset('assets/images/splash_game.png',
        errorBuilder: (c, e, s) => const Text("GAME LOGO", style: TextStyle(fontSize: 50, color: Colors.red, fontWeight: FontWeight.w900)))
        .animate().scale(duration: 1.seconds, curve: Curves.elasticOut).then().fadeOut(delay: 500.ms)),
  );
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    Future.delayed(3.seconds, () {
      if (context.mounted) Navigator.of(context).pushReplacement(_blackFadeRoute(const MainMenu()));
    });
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const CircularProgressIndicator(color: Colors.red, strokeWidth: 2).animate(onPlay: (c) => c.repeat()).shimmer(),
        const SizedBox(height: 30),
        const Text("LOADING...", style: TextStyle(letterSpacing: 8, color: Colors.white60, fontSize: 16, fontWeight: FontWeight.bold)).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(),
      ])),
    );
  }
}

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});
  @override State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> with TickerProviderStateMixin {
  bool isNavbarExpanded = false;
  int highscore = 0;
  double volume = 0.5;
  List<AppFile> musicLibrary = [], mapLibrary = [], bgLibrary = [];
  AppFile? selectedMusic, selectedMap, selectedBG;
  final AudioPlayer previewPlayer = AudioPlayer();
  VideoPlayerController? _menuVideoController;

  @override
  void initState() { super.initState(); _loadHighscore(); _loadLibraries(); }

  Future<void> _loadLibraries() async {
    if (kIsWeb) return;
    final dir = await getApplicationDocumentsDirectory();
    for (var sub in ['import/music', 'import/maps', 'import/bg']) {
      final d = Directory('${dir.path}/$sub');
      if (!await d.exists()) await d.create(recursive: true);
    }
    setState(() {
      musicLibrary = Directory('${dir.path}/import/music').listSync().whereType<File>().map((f) => AppFile(name: f.path.split('/').last, path: f.path)).toList();
      mapLibrary = Directory('${dir.path}/import/maps').listSync().whereType<File>().map((f) => AppFile(name: f.path.split('/').last, path: f.path)).toList();
      bgLibrary = Directory('${dir.path}/import/bg').listSync().whereType<File>().map((f) => AppFile(name: f.path.split('/').last, path: f.path)).toList();
    });
  }

  Future<void> _loadHighscore() async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/highscore.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(content);
        setState(() => highscore = data['highscore'] ?? 0);
      } else {
        // Fallback to reading the initial highscore from the asset folder if it doesn't exist yet in ApplicationDocumentsDirectory
        try {
          final content = await rootBundle.loadString('assets/savefile/highscore.json');
          final Map<String, dynamic> data = jsonDecode(content);
          setState(() => highscore = data['highscore'] ?? 0);
        } catch (_) {}
      }
    } catch (_) {}
  }

  void _updateMenuBG() async {
    await _menuVideoController?.dispose(); _menuVideoController = null;
    if (selectedBG != null && selectedBG!.name.toLowerCase().endsWith('.mp4')) {
      if (kIsWeb && selectedBG!.webUrl != null) {
        _menuVideoController = VideoPlayerController.networkUrl(Uri.parse(selectedBG!.webUrl!));
      } else if (selectedBG!.path != null) {
        _menuVideoController = VideoPlayerController.file(File(selectedBG!.path!));
      }
      if (_menuVideoController != null) {
        await _menuVideoController!.initialize(); await _menuVideoController!.setVolume(0); await _menuVideoController!.setLooping(true); await _menuVideoController!.play();
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() { previewPlayer.dispose(); _menuVideoController?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Stack(children: [
      if (selectedBG != null) SizedBox.expand(child: Opacity(opacity: 0.75, child: _menuVideoController != null && _menuVideoController!.value.isInitialized ? FittedBox(fit: BoxFit.cover, child: SizedBox(width: _menuVideoController!.value.size.width, height: _menuVideoController!.value.size.height, child: VideoPlayer(_menuVideoController!))) : (selectedBG!.webUrl != null ? Image.network(selectedBG!.webUrl!, fit: BoxFit.cover) : (selectedBG!.bytes != null ? Image.memory(selectedBG!.bytes!, fit: BoxFit.cover) : (selectedBG!.path != null ? Image.file(File(selectedBG!.path!), fit: BoxFit.cover) : Container()))))),
      Center(child: Column(children: [
        const Spacer(flex: 15),
        Image.asset('assets/images/title_game.png', height: 500, errorBuilder: (c, e, s) => const Text("FIRE & ICE", style: TextStyle(fontSize: 90, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 10)))
            .animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), duration: 4.seconds, curve: Curves.easeInOut).rotate(begin: -0.002, end: 0.002, duration: 5.seconds),
        const SizedBox(height: 30),
        GestureDetector(onTap: () { previewPlayer.stop(); Navigator.push(context, MaterialPageRoute(builder: (c) => GameplayLoadingScreen(music: selectedMusic, map: selectedMap, bg: selectedBG, volume: volume))).then((_) => _loadHighscore()); },
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 110, vertical: 25), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.red, Colors.redAccent]), borderRadius: BorderRadius.circular(50), border: Border.all(color: Colors.white.withOpacity(0.38), width: 2), boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 40, spreadRadius: 4)]), child: const Text("PLAY", style: TextStyle(fontSize: 45, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)))),
        const SizedBox(height: 25),
        Text("HIGHSCORE: $highscore", style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 3)),
        const Spacer(flex: 25),
      ])),
      Positioned(right: 30, bottom: 30, child: SafeArea(child: GestureDetector(onTap: () { if (kIsWeb) { SystemNavigator.pop(); } else { exit(0); } }, child: Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: Colors.red.withOpacity(0.6), width: 4), boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 20)],), child: const Icon(Icons.logout, color: Colors.red, size: 50))))).animate().fadeIn(delay: 500.ms).scale(curve: Curves.elasticOut),
      Align(alignment: Alignment.bottomCenter, child: Padding(padding: const EdgeInsets.only(bottom: 25), child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
        AnimatedContainer(duration: 700.ms, curve: Curves.elasticOut, width: isNavbarExpanded ? 320 : 80, height: 80, decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.white.withOpacity(0.1)))),
        Row(mainAxisSize: MainAxisSize.min, children: [
          if (isNavbarExpanded) ...[_navIcon(Icons.flag, _showMapperDialog), _navIcon(Icons.library_music, _showMusicSelector)],
          GestureDetector(onTap: () => setState(() => isNavbarExpanded = !isNavbarExpanded), child: Container(width: 70, height: 70, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red, boxShadow: [BoxShadow(color: Colors.red, blurRadius: 15)]), child: const Icon(Icons.music_note, color: Colors.white, size: 35))),
          if (isNavbarExpanded) ...[_navIcon(Icons.settings, _showSettingsDialog), _navIcon(Icons.image, _showBGSelector)],
        ]),
      ]))),
    ]),
  );

  Widget _navIcon(IconData icon, VoidCallback onTap) => IconButton(icon: Icon(icon, color: Colors.white, size: 32), onPressed: onTap).animate().scale(duration: 500.ms, curve: Curves.easeOutBack).fadeIn();

  void _showMiniDialog(String title, Widget child) => showDialog(context: context, builder: (c) => Align(alignment: Alignment.bottomCenter, child: Padding(padding: const EdgeInsets.only(bottom: 120), child: Material(color: Colors.transparent, child: Container(width: 450, padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1A1A1A), Colors.black], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.red.withOpacity(0.6), width: 2), boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)]), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(title, style: const TextStyle(color: Colors.red, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 4)), Divider(color: Colors.white.withOpacity(0.12), height: 25), child]))))).animate().scale(curve: Curves.easeOutBack, duration: 400.ms));

  Widget _buildSelectorItem(String name, bool isSelected, VoidCallback onTap) => Container(margin: const EdgeInsets.symmetric(vertical: 5), decoration: BoxDecoration(color: isSelected ? Colors.red.withOpacity(0.3) : Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: isSelected ? Colors.red : Colors.white10, width: 2), boxShadow: isSelected ? [BoxShadow(color: Colors.red.withOpacity(0.2), blurRadius: 8)] : []), child: ListTile(title: Text(name, style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)), trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.red, size: 28) : null, onTap: onTap));

  void _showMapperDialog() => _showMiniDialog("BEAT MAPS", StatefulBuilder(builder: (context, setD) => Column(mainAxisSize: MainAxisSize.min, children: [
    if (mapLibrary.isEmpty) Padding(padding: const EdgeInsets.all(20), child: Text("(empty)", style: TextStyle(color: Colors.white.withOpacity(0.38)))),
    if (mapLibrary.isNotEmpty) SizedBox(height: 280, child: ListView.builder(itemCount: mapLibrary.length, itemBuilder: (c, i) => _buildSelectorItem(mapLibrary[i].name, selectedMap?.name == mapLibrary[i].name, () { setState(() { if (selectedMap?.name == mapLibrary[i].name) { selectedMap = null; } else { selectedMap = mapLibrary[i]; } }); setD(() {}); }))),
    const SizedBox(height: 15),
    ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), minimumSize: const Size(double.infinity, 55)), onPressed: () async {
      FilePickerResult? res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json'], withData: true);
      if (res != null && res.files.single.name != null) {
        final picked = res.files.single; AppFile imported;
        if (!kIsWeb) {
          final dir = await getApplicationDocumentsDirectory(); final file = File('${dir.path}/import/maps/${picked.name}');
          if (picked.bytes != null) await file.writeAsBytes(picked.bytes!);
          await _loadLibraries(); imported = AppFile(name: picked.name, path: file.path);
        } else { imported = AppFile(name: picked.name, bytes: picked.bytes); mapLibrary.add(imported); }
        setState(() => selectedMap = imported); setD(() {});
      }
    }, child: const Text("IMPORT JSON MAP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
  ])));

  void _showMusicSelector() => _showMiniDialog("MUSIC LIBRARY", StatefulBuilder(builder: (context, setD) => Column(mainAxisSize: MainAxisSize.min, children: [
    if (musicLibrary.isEmpty) Padding(padding: const EdgeInsets.all(20), child: Text("(empty)", style: TextStyle(color: Colors.white.withOpacity(0.38)))),
    if (musicLibrary.isNotEmpty) SizedBox(height: 280, child: ListView.builder(itemCount: musicLibrary.length, itemBuilder: (c, i) => _buildSelectorItem(musicLibrary[i].name, selectedMusic?.name == musicLibrary[i].name, () async {
      setState(() { if (selectedMusic?.name == musicLibrary[i].name) { selectedMusic = null; previewPlayer.stop(); } else { selectedMusic = musicLibrary[i]; } }); setD(() {});
      if (selectedMusic != null) {
        await previewPlayer.setVolume(volume);
        if (selectedMusic!.path != null) await previewPlayer.play(DeviceFileSource(selectedMusic!.path!));
        else if (selectedMusic!.bytes != null) await previewPlayer.play(BytesSource(selectedMusic!.bytes!));
      }
    }))),
    const SizedBox(height: 15),
    ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), minimumSize: const Size(double.infinity, 55)), onPressed: () async {
      FilePickerResult? res = await FilePicker.platform.pickFiles(type: FileType.audio, withData: true);
      if (res != null && res.files.single.name != null) {
        final picked = res.files.single; AppFile imported;
        if (!kIsWeb) {
          final dir = await getApplicationDocumentsDirectory(); final file = File('${dir.path}/import/music/${picked.name}');
          if (picked.bytes != null) await file.writeAsBytes(picked.bytes!);
          await _loadLibraries(); imported = AppFile(name: picked.name, path: file.path);
        } else { imported = AppFile(name: picked.name, bytes: picked.bytes); musicLibrary.add(imported); }
        setState(() => selectedMusic = imported); setD(() {});
      }
    }, child: const Text("IMPORT AUDIO FILE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
  ])));

  void _showBGSelector() => _showMiniDialog("BACKGROUNDS", StatefulBuilder(builder: (context, setD) => Column(mainAxisSize: MainAxisSize.min, children: [
    if (bgLibrary.isEmpty) Padding(padding: const EdgeInsets.all(20), child: Text("(empty)", style: TextStyle(color: Colors.white.withOpacity(0.38)))),
    if (bgLibrary.isNotEmpty) SizedBox(height: 280, child: ListView.builder(itemCount: bgLibrary.length, itemBuilder: (c, i) => _buildSelectorItem(bgLibrary[i].name, selectedBG?.name == bgLibrary[i].name, () { setState(() { if (selectedBG?.name == bgLibrary[i].name) { selectedBG = null; } else { selectedBG = bgLibrary[i]; } }); setD(() {}); _updateMenuBG(); }))),
    const SizedBox(height: 15),
    ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), minimumSize: const Size(double.infinity, 55)), onPressed: () async {
      FilePickerResult? res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['png', 'jpg', 'jpeg', 'mp4'], withData: true);
      if (res != null && res.files.single.name != null) {
        final picked = res.files.single; AppFile imported;
        String? webUrl = kIsWeb && picked.bytes != null ? WebHelper.createBlobUrl(picked.bytes!) : null;
        if (!kIsWeb) {
          final dir = await getApplicationDocumentsDirectory(); final file = File('${dir.path}/import/bg/${picked.name}');
          if (picked.bytes != null) await file.writeAsBytes(picked.bytes!);
          await _loadLibraries(); imported = AppFile(name: picked.name, path: file.path);
        } else { imported = AppFile(name: picked.name, bytes: picked.bytes, webUrl: webUrl); bgLibrary.add(imported); }
        setState(() => selectedBG = imported); _updateMenuBG(); setD(() {});
      }
    }, child: const Text("IMPORT MEDIA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
  ])));

  void _showSettingsDialog() => _showMiniDialog("SETTINGS", StatefulBuilder(builder: (context, setD) => Column(children: [Row(children: [Icon(volume > 0.5 ? Icons.volume_up : Icons.volume_down, color: volume > 0.6 ? Colors.red : Colors.blue), Expanded(child: Slider(value: volume, activeColor: volume > 0.6 ? Colors.red : Colors.blue, onChanged: (v) { setD(() => volume = v); setState(() => volume = v); previewPlayer.setVolume(v); }))]), Text("SYSTEM VOLUME", style: TextStyle(color: Colors.white.withOpacity(0.38), fontSize: 14, letterSpacing: 3, fontWeight: FontWeight.bold))])));
}

class GameplayLoadingScreen extends StatelessWidget {
  final AppFile? music, map, bg; final double volume;
  const GameplayLoadingScreen({super.key, this.music, this.map, this.bg, required this.volume});
  @override
  Widget build(BuildContext context) {
    Future.delayed(2.seconds, () {
      if (context.mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (c) => GameplayScreen(music: music, map: map, bg: bg, volume: volume)));
    });
    return Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text("GET READY", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 10)),
      const SizedBox(height: 30),
      Container(width: 300, height: 10, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(5)), child: Align(alignment: Alignment.centerLeft, child: Container(width: 0, height: 10, color: Colors.red).animate().custom(duration: 2.seconds, builder: (c, v, ch) => Container(width: 300 * v, height: 10, color: Colors.red)))),
    ])));
  }
}

class GameplayScreen extends StatefulWidget {
  final AppFile? music, map, bg; final double volume;
  const GameplayScreen({super.key, this.music, this.map, this.bg, required this.volume});
  @override State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  int score = 0, lives = 3; bool isGameOver = false, isStarted = false, isFinished = false, musicEnded = false, winSequenceStarted = false;
  int winMsgIndex = 0; List<PianoTile> tiles = [];
  Timer? gameTimer;
  final AudioPlayer sfx = AudioPlayer(), music = AudioPlayer();
  final Random r = Random(); int startTime = 0; List<MapEntry<int, String>> beatMap = [];
  VideoPlayerController? _videoController;
  double leftFlashOpacity = 0.0, rightFlashOpacity = 0.0;
  static const int travelTime = 1500;
  int lastRandomSpawn = 0;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _init();
    music.onPlayerComplete.listen((_) { if (mounted) { setState(() => musicEnded = true); } });
  }

  void _init() async {
    if (widget.map != null) {
      try {
        final content = widget.map!.bytes != null ? utf8.decode(widget.map!.bytes!) : await File(widget.map!.path!).readAsString();
        final data = jsonDecode(content); 
        final beats = data['beats'] as List;
        for (var b in beats) {
          beatMap.add(MapEntry((b['timestamp_ms'] as num).toInt(), b['color'] as String));
        }
        beatMap.sort((a, b) => a.key.compareTo(b.key));
      } catch (_) {}
    }
    if (widget.bg != null && widget.bg!.name.toLowerCase().endsWith('.mp4')) {
      if (kIsWeb && widget.bg!.webUrl != null) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.bg!.webUrl!));
      } else if (widget.bg!.path != null) {
        _videoController = VideoPlayerController.file(File(widget.bg!.path!));
      }
      if (_videoController != null) { await _videoController!.initialize(); await _videoController!.setVolume(0); await _videoController!.setLooping(true); if (mounted) setState(() {}); }
    }
    sfx.setVolume(widget.volume);
    gameTimer = Timer.periodic(16.ms, (t) => _update());
  }

  void _startGame() async {
    if (isStarted) return;
    startTime = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      isStarted = true;
      lastRandomSpawn = 0;
    });

    if (widget.music != null) {
      await music.setVolume(widget.volume);
      if (widget.music!.path != null) await music.play(DeviceFileSource(widget.music!.path!));
      else if (widget.music!.bytes != null) await music.play(BytesSource(widget.music!.bytes!));
    }
    _videoController?.play();
  }

  void _update() {
    if (isGameOver || isFinished || !isStarted || !mounted || startTime == 0) return;
    final now = DateTime.now().millisecondsSinceEpoch; final elapsed = now - startTime;
    setState(() {
      while (beatMap.isNotEmpty && beatMap.first.key <= elapsed) {
        final e = beatMap.removeAt(0);
        tiles.add(PianoTile(
            spawnTime: elapsed,
            column: e.value == 'red' ? 0 : 1,
            color: e.value == 'red' ? Colors.red : Colors.blue
        ));
      }
      if (widget.map == null && elapsed - lastRandomSpawn > 800) {
        lastRandomSpawn = elapsed;
        tiles.add(PianoTile(
            spawnTime: elapsed,
            column: r.nextInt(2),
            color: r.nextInt(2) == 0 ? Colors.red : Colors.blue
        ));
      }
      for (var t in tiles) {
        t.y = (elapsed - t.spawnTime) / travelTime;
      }
      int missedCount = 0;
      tiles.removeWhere((t) {
        if (t.y > 1.1) { missedCount++; return true; }
        return false;
      });
      if (missedCount > 0) {
        lives = max(0, lives - missedCount);
        if (lives <= 0) _end(false);
      }
      if (musicEnded && tiles.isEmpty && beatMap.isEmpty && !winSequenceStarted) _startWinSequence();
      if (leftFlashOpacity > 0) leftFlashOpacity = max(0, leftFlashOpacity - 0.05);
      if (rightFlashOpacity > 0) rightFlashOpacity = max(0, rightFlashOpacity - 0.05);
    });
  }

  void _handleTap(int col) {
    if (!isStarted) { _startGame(); return; }
    if (isGameOver || isFinished) return;
    int i = tiles.indexWhere((t) => t.column == col && t.y > 0.75 && t.y < 1.1);
    if (i != -1) {
      setState(() { score += 10; tiles.removeAt(i); if (col == 0) leftFlashOpacity = 0.2; else rightFlashOpacity = 0.2; });
      if (widget.music == null) sfx.play(AssetSource('sounds/sound${r.nextInt(5)+1}.mp3'));
    } else {
      setState(() { lives = max(0, lives - 1); });
      if (lives <= 0) _end(false);
    }
  }

  Future<void> _saveHighscore() async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/highscore.json');
      int currentHigh = 0;
      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(content);
        currentHigh = data['highscore'] ?? 0;
      } else {
        try {
          final content = await rootBundle.loadString('assets/savefile/highscore.json');
          final Map<String, dynamic> data = jsonDecode(content);
          currentHigh = data['highscore'] ?? 0;
        } catch (_) {}
      }
      if (score > currentHigh) {
        await file.writeAsString(jsonEncode({'highscore': score}));
      }
    } catch (_) {}
  }

  void _startWinSequence() async {
    winSequenceStarted = true; await _saveHighscore(); await Future.delayed(3.seconds);
    if (mounted) { setState(() { winMsgIndex = r.nextInt(2); isFinished = true; }); await Future.delayed(5.seconds); if (mounted) Navigator.of(context).pop(); }
  }

  void _end(bool won) async {
    if (isGameOver || isFinished) return;
    setState(() { isGameOver = !won; });
    gameTimer?.cancel(); music.stop(); _videoController?.pause(); await _saveHighscore();
  }

  @override
  void dispose() { gameTimer?.cancel(); sfx.dispose(); music.dispose(); _videoController?.dispose(); _focusNode.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: KeyboardListener(focusNode: _focusNode..requestFocus(), onKeyEvent: (event) { if (event is KeyDownEvent) { if (event.logicalKey == LogicalKeyboardKey.keyQ) _handleTap(0); if (event.logicalKey == LogicalKeyboardKey.keyE) _handleTap(1); if (event.logicalKey == LogicalKeyboardKey.space) _startGame(); } },
      child: Stack(children: [
        if (widget.bg != null) ...[
          if (_videoController != null && _videoController!.value.isInitialized) SizedBox.expand(child: FittedBox(fit: BoxFit.cover, child: SizedBox(width: _videoController!.value.size.width, height: _videoController!.value.size.height, child: Opacity(opacity: 0.75, child: VideoPlayer(_videoController!))))),
          if (_videoController == null && !widget.bg!.name.toLowerCase().endsWith('.mp4')) SizedBox.expand(child: widget.bg!.webUrl != null ? Opacity(opacity: 0.75, child: Image.network(widget.bg!.webUrl!, fit: BoxFit.cover)) : (widget.bg!.bytes != null ? Opacity(opacity: 0.75, child: Image.memory(widget.bg!.bytes!, fit: BoxFit.cover)) : (widget.bg!.path != null ? Opacity(opacity: 0.75, child: Image.file(File(widget.bg!.path!), fit: BoxFit.cover)) : Container(color: Colors.black)))),
        ],
        Row(children: [Expanded(child: Container(color: Colors.red.withOpacity(leftFlashOpacity))), Expanded(child: Container(color: Colors.blue.withOpacity(rightFlashOpacity)))]),
        Row(children: [Expanded(child: GestureDetector(behavior: HitTestBehavior.opaque, onTapDown: (_) => _handleTap(0), child: Container(decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.white.withOpacity(0.1))))))), Expanded(child: GestureDetector(behavior: HitTestBehavior.opaque, onTapDown: (_) => _handleTap(1), child: Container(color: Colors.transparent)))]),
        
        Positioned(bottom: MediaQuery.of(context).size.height * 0.15, left: 0, right: 0, child: Container(height: 2, color: Colors.white.withOpacity(0.3))),

        ...tiles.map((t) => Align(alignment: Alignment(t.column == 0 ? -0.5 : 0.5, t.y * 2 - 1), child: Container(width: 170, height: 210, decoration: BoxDecoration(color: t.color, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white, width: 2.5), boxShadow: [BoxShadow(color: t.color.withOpacity(0.6), blurRadius: 18)])))),
        Positioned(top: 40, left: 30, child: Row(children: List.generate(3, (i) => Icon(i < lives ? Icons.favorite : Icons.favorite_border, color: Colors.red, size: 40)))),
        Positioned(top: 40, left: 0, right: 0, child: Center(child: Text("SCORE: $score", style: const TextStyle(fontSize: 45, fontWeight: FontWeight.bold, letterSpacing: 4)))),
        if (!isStarted) Container(color: Colors.black54, child: const Center(child: Text("TAP TO START / PRESS SPACE", style: TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 4)))),
        if (isFinished) Center(child: Image.asset('assets/images/gameplay_msg_$winMsgIndex.png', height: 350).animate().scale(duration: 1.seconds, curve: Curves.elasticOut)),
        if (isGameOver) Container(color: Colors.black87, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Text("YOU LOST!", style: TextStyle(fontSize: 60, color: Colors.red, fontWeight: FontWeight.w900, letterSpacing: 8)), const SizedBox(height: 30), ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("BACK TO MENU", style: TextStyle(letterSpacing: 2)))]))),
      ]),
    ),
  );
}
