import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'audio_manager.dart';
import 'web_utils_stub.dart' if (dart.library.html) 'web_utils.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = _isDarkMode ? ThemeMode.dark : ThemeMode.light;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '15 Puzzle',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeMode,
      home: PuzzleGame(
        isDarkMode: _isDarkMode,
        onDarkModeChanged: (value) {
          setState(() {
            _isDarkMode = value;
          });
        },
      ),
    );
  }
}

class PuzzleGame extends StatefulWidget {
  const PuzzleGame({
    super.key,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  State<PuzzleGame> createState() => _PuzzleGameState();
}

class _PuzzleGameState extends State<PuzzleGame> {
  List<int> tiles = [];
  int emptyIndex = 15;
  int moves = 0;

  // ⏱️ Timer
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timerTicker;
  Duration _elapsed = Duration.zero;
  Duration? _finalElapsed;
  bool _hasStartedTimer = false;
  bool _isPaused = false;
  bool _isGameOver = false;

  final ScrollController _scrollController = ScrollController();
  final FocusNode _pageFocusNode = FocusNode(debugLabel: 'PuzzlePageFocus');

  static const String _repoUrl = 'https://github.com/gregpuzzles1/15puzzle';
  static const String _issuesUrl =
      'https://github.com/gregpuzzles1/15puzzle/issues';
  static const String _licenseUrl =
      'https://github.com/gregpuzzles1/15puzzle/blob/main/LICENSE';

  bool _isShuffling = false;

  // 🔊 Audio
  late final AudioManager _audioManager;
  bool _audioReady = false;
  static const String _newGameSound = 'sounds/new_game_chime.wav';
  static const String _winSound = 'sounds/game_win_fanfare.wav';

  // 🎉 Confetti
  late ConfettiController _confettiController;

  // All acceptable solved layouts (0 = empty)
  static const List<List<int>> _goalBoards = [
    [
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15,
      0,
    ],
    [
      15,
      14,
      13,
      12,
      11,
      10,
      9,
      8,
      7,
      6,
      5,
      4,
      3,
      2,
      1,
      0,
    ],
    [
      1,
      5,
      9,
      13,
      2,
      6,
      10,
      14,
      3,
      7,
      11,
      15,
      4,
      8,
      12,
      0,
    ],
    [
      1,
      3,
      2,
      4,
      5,
      7,
      6,
      8,
      9,
      11,
      10,
      12,
      13,
      15,
      14,
      0,
    ],
    [
      1,
      9,
      2,
      10,
      3,
      11,
      4,
      12,
      5,
      13,
      6,
      14,
      7,
      15,
      8,
      0,
    ],
    [
      1,
      4,
      5,
      8,
      2,
      3,
      6,
      7,
      9,
      10,
      13,
      14,
      0,
      11,
      12,
      15,
    ],
  ];

  @override
  void initState() {
    super.initState();

    // Audio setup
    _audioManager = AudioManager();
    _audioManager.initialize().then((_) {
      _audioReady = true;
    }).catchError((e) {
      debugPrint('Audio init error: $e');
    });

    // Confetti init
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    _initializeSolvedBoard(_goalBoards.first);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _shufflePuzzle(playSound: false);

      // Remove loading spinner after first frame (web only)
      removeLoadingSpinner();
    });
  }

  @override
  void dispose() {
    _timerTicker?.cancel();
    _audioManager.dispose();
    _confettiController.dispose();
    _scrollController.dispose();
    _pageFocusNode.dispose();
    super.dispose();
  }

  String _formatElapsed(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    String two(int n) => n.toString().padLeft(2, '0');
    if (hours > 0) {
      return '${two(hours)}:${two(minutes)}:${two(seconds)}';
    }
    return '${two(minutes)}:${two(seconds)}';
  }

  void _armTimer() {
    _timerTicker?.cancel();
    _stopwatch
      ..stop()
      ..reset();

    setState(() {
      _elapsed = Duration.zero;
      _finalElapsed = null;
      _hasStartedTimer = true;
      _isPaused = false;
      _isGameOver = false;
    });
  }

  void _beginTimerIfNeeded() {
    if (!_hasStartedTimer || _isPaused || _isGameOver || _isShuffling) return;
    if (_stopwatch.isRunning) return;

    _stopwatch.start();
    _timerTicker?.cancel();
    _timerTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _timerTicker?.cancel();
        return;
      }

      if (!_stopwatch.isRunning) return;

      setState(() {
        _elapsed = _stopwatch.elapsed;
      });
    });
  }

  void _pauseTimer() {
    if (!_hasStartedTimer || _isGameOver) return;
    if (!_stopwatch.isRunning) return;

    _stopwatch.stop();
    _timerTicker?.cancel();
    setState(() {
      _elapsed = _stopwatch.elapsed;
      _isPaused = true;
    });
  }

  void _resumeTimer() {
    if (!_hasStartedTimer || _isGameOver) return;
    if (_stopwatch.isRunning) return;

    _stopwatch.start();
    setState(() {
      _isPaused = false;
    });

    _timerTicker?.cancel();
    _timerTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _timerTicker?.cancel();
        return;
      }

      if (!_stopwatch.isRunning) return;

      setState(() {
        _elapsed = _stopwatch.elapsed;
      });
    });
  }

  void _stopTimer() {
    if (!_hasStartedTimer) return;
    _stopwatch.stop();
    _timerTicker?.cancel();
    setState(() {
      _elapsed = _stopwatch.elapsed;
      _finalElapsed = _elapsed;
      _isGameOver = true;
      _isPaused = false;
    });
  }

  void _scrollBy(double delta) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final target = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target.toDouble(),
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
  }

  /// Calculate optimal board size based on viewport dimensions
  /// - Desktop (≥1024px): min(520, available)
  /// - Tablet (768-1023px): min(480, available)
  /// - Mobile (<768px): min(available, 340), ensure tiles ≥44px
  double getBoardSize(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    // Calculate available space (90% of smaller dimension, minus padding)
    final available = (width < height ? width : height) * 0.9 - 48;

    // Minimum board size for 44px tiles accounting for GridView layout:
    // (44px tile * 4) + (4px spacing * 3 gaps) + (4px padding * 2 sides) = 196px
    const minBoardSize = 196.0;

    if (width >= 1024) {
      // Desktop: prefer 520px, but adapt if screen is smaller
      return available < 520
          ? (available < minBoardSize ? minBoardSize : available)
          : 520;
    } else if (width >= 768) {
      // Tablet: prefer 480px, but adapt if screen is smaller
      return available < 480
          ? (available < minBoardSize ? minBoardSize : available)
          : 480;
    } else {
      // Mobile: use available space, max 340px, min 196px for touch targets
      if (available < minBoardSize) return minBoardSize;
      return available > 340 ? 340 : available;
    }
  }

  void _playSound(String asset) {
    // Important for desktop browsers: audio playback must be initiated
    // synchronously from a user gesture (no awaiting).
    if (!kIsWeb && !_audioReady) return;
    _audioManager.playSound(asset);
  }

  void _playWinSound(String asset) {
    if (!kIsWeb && !_audioReady) return;
    _audioManager.playWinSound(asset);
  }

  void _initializeSolvedBoard(List<int> goal) {
    tiles = List<int>.from(goal);
    emptyIndex = tiles.indexOf(0);
    moves = 0;
  }

  void _shufflePuzzle({bool playSound = true}) {
    final random = Random();
    _isShuffling = true;

    if (playSound) {
      _playSound(_newGameSound);
    }

    final startGoal = _goalBoards[random.nextInt(_goalBoards.length)];
    _initializeSolvedBoard(startGoal);

    for (int i = 0; i < 250; i++) {
      final validMoves = _getValidMoves();
      if (validMoves.isNotEmpty) {
        final move = validMoves[random.nextInt(validMoves.length)];
        _moveTile(
          move,
          countMove: false,
          checkSolved: false,
          playSound: false,
        );
      }
    }

    setState(() => moves = 0);
    _isShuffling = false;

    // Arm timer after shuffle completes; time starts on player's first move.
    _armTimer();
  }

  void _startNewGame() {
    _shufflePuzzle();
  }

  List<int> _getValidMoves() {
    final row = emptyIndex ~/ 4;
    final col = emptyIndex % 4;
    final moves = <int>[];

    if (row > 0) moves.add(emptyIndex - 4);
    if (row < 3) moves.add(emptyIndex + 4);
    if (col > 0) moves.add(emptyIndex - 1);
    if (col < 3) moves.add(emptyIndex + 1);

    return moves;
  }

  void _moveTile(
    int index, {
    bool countMove = true,
    bool checkSolved = true,
    bool playSound = true,
  }) {
    if (_getValidMoves().contains(index)) {
      if (countMove) {
        _beginTimerIfNeeded();
      }
      setState(() {
        tiles[emptyIndex] = tiles[index];
        tiles[index] = 0;
        emptyIndex = index;
        if (countMove) moves++;
      });

      // Tile move/tick sound intentionally disabled (all platforms).

      if (checkSolved && !_isShuffling && _isSolvedAnyWay()) {
        _handleWin();
      }
    }
  }

  bool _isSolvedAnyWay() {
    for (final goal in _goalBoards) {
      bool match = true;
      for (int i = 0; i < 16; i++) {
        if (tiles[i] != goal[i]) {
          match = false;
          break;
        }
      }
      if (match) return true;
    }
    return false;
  }

  void _handleWin() {
    _stopTimer();
    _confettiController.play();
    _playWinSound(_winSound);
    _showWinDialog();
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Stack(
        alignment: Alignment.center,
        children: [
          AlertDialog(
            title: const Text(
              '🎉 Congratulations! 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Text(
                  'You solved the puzzle!',
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Moves: $moves',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Time: ${_formatElapsed(_finalElapsed ?? _elapsed)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _confettiController.stop();
                  Navigator.of(context).pop();
                  _startNewGame();
                },
                child: const Text('Play Again', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: -pi / 2,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.3,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Colors.yellow,
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleExternalLinkTap(String url) async {
    final opened = openExternalUrl(url);
    if (opened) return;

    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard')),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall;
    final linkStyle = textStyle?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
    );

    const emailAddress = 'gregpuzzles1@gmail.com';

    const startYear = 2025;
    final currentYear = DateTime.now().year;
    final yearText =
        currentYear <= startYear ? '$startYear' : '$startYear-$currentYear';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: [
          Text('© $yearText Greg Christian ·', style: textStyle),
          InkWell(
            onTap: () => _handleExternalLinkTap(_licenseUrl),
            child: Text('MIT License', style: linkStyle),
          ),
          Text('·', style: textStyle),
          InkWell(
            onTap: () => _handleExternalLinkTap('mailto:$emailAddress'),
            child: Text(emailAddress, style: linkStyle),
          ),
          Text('·', style: textStyle),
          InkWell(
            onTap: () => _handleExternalLinkTap(_repoUrl),
            child: Text('GitHub', style: linkStyle),
          ),
          Text('·', style: textStyle),
          InkWell(
            onTap: () => _handleExternalLinkTap(_issuesUrl),
            child: Text('Open an Issue', style: linkStyle),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSections(BuildContext context) {
    final headingStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        );
    final bodyStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          height: 1.4,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text('How to play', style: headingStyle),
              const SizedBox(height: 8),
              Text(
                'The goal is to slide the numbered tiles until they are in order from 1 to 15, with the empty space in the bottom-right corner. Tap a tile next to the empty space to move it into the gap.',
                style: bodyStyle,
              ),
              const SizedBox(height: 8),
              Text(
                'Try to solve the puzzle in as few moves as possible. If you get stuck, press “New Game” to reshuffle and start fresh.',
                style: bodyStyle,
              ),
              const SizedBox(height: 20),
              Text('A bit of history', style: headingStyle),
              const SizedBox(height: 8),
              Text(
                'The 15 puzzle is a classic sliding puzzle from the late 1800s. It became a worldwide craze when people challenged friends and family to restore the tiles to the correct order after scrambling them.',
                style: bodyStyle,
              ),
              const SizedBox(height: 8),
              Text(
                'Today it’s still popular as a quick logic game and a great example of how simple rules can create surprisingly deep challenges — including the fact that only certain scrambled positions are solvable.',
                style: bodyStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        title: const Text('15 Puzzle'),
        leading: PopupMenuButton<void>(
          tooltip: 'Settings',
          icon: const Icon(Icons.settings),
          itemBuilder: (context) => [
            PopupMenuItem<void>(
              enabled: false,
              child: StatefulBuilder(
                builder: (context, setMenuState) {
                  var isDarkMode = widget.isDarkMode;

                  void update(bool value) {
                    setMenuState(() {
                      isDarkMode = value;
                    });
                    widget.onDarkModeChanged(value);
                  }

                  return InkWell(
                    onTap: () => update(!isDarkMode),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Dark mode',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Switch(
                          value: isDarkMode,
                          onChanged: update,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(
                'Moves: $moves',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          const SingleActivator(LogicalKeyboardKey.arrowDown):
              const ScrollIntent(direction: AxisDirection.down),
          const SingleActivator(LogicalKeyboardKey.arrowUp):
              const ScrollIntent(direction: AxisDirection.up),
          const SingleActivator(LogicalKeyboardKey.pageDown):
              const ScrollIntent(direction: AxisDirection.down),
          const SingleActivator(LogicalKeyboardKey.pageUp):
              const ScrollIntent(direction: AxisDirection.up),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            ScrollIntent: CallbackAction<ScrollIntent>(
              onInvoke: (intent) {
                final isPage = intent.direction == AxisDirection.down
                    ? HardwareKeyboard.instance.logicalKeysPressed
                        .contains(LogicalKeyboardKey.pageDown)
                    : HardwareKeyboard.instance.logicalKeysPressed
                        .contains(LogicalKeyboardKey.pageUp);

                // Arrow: small nudge; PageUp/PageDown: larger jump.
                final delta = intent.direction == AxisDirection.down
                    ? (isPage ? 420.0 : 80.0)
                    : (isPage ? -420.0 : -80.0);
                _scrollBy(delta);
                return null;
              },
            ),
          },
          child: Focus(
            focusNode: _pageFocusNode,
            autofocus: true,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                if (_pageFocusNode.canRequestFocus) {
                  _pageFocusNode.requestFocus();
                }
              },
              child: Center(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Builder(
                        builder: (context) {
                          final boardSize = getBoardSize(context);
                          return SizedBox(
                            width: boardSize,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: _buildTimerOverlay(context),
                                ),
                                const SizedBox(height: 8),
                                SizedBox.square(
                                  dimension: boardSize,
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: AbsorbPointer(
                                            absorbing: _isPaused || _isGameOver,
                                            child: GridView.builder(
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              gridDelegate:
                                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 4,
                                                crossAxisSpacing: 4,
                                                mainAxisSpacing: 4,
                                              ),
                                              itemCount: 16,
                                              itemBuilder: (context, index) =>
                                                  _buildTile(index),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (_isPaused)
                                        Positioned.fill(
                                          child: IgnorePointer(
                                            ignoring: true,
                                            child: Container(
                                              color: Colors.black
                                                  .withValues(alpha: 0.15),
                                              child: const Center(
                                                child: Text(
                                                  'Paused',
                                                  style: TextStyle(
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _isShuffling ? null : _startNewGame,
                            child: const Text('New Game'),
                          ),
                        ],
                      ),
                      _buildInfoSections(context),
                      const SizedBox(height: 12),
                      _buildFooter(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTile(int index) {
    final tileNumber = tiles[index];
    final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

    if (tileNumber == 0) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    return GestureDetector(
      // On iOS, using onTapDown makes the interaction feel snappier
      // (onTap fires on pointer-up).
      onTap: isIOS
          ? null
          : () {
              if (_isPaused || _isGameOver) return;
              _moveTile(index);
            },
      onTapDown: isIOS
          ? (_) {
              if (_isPaused || _isGameOver) return;
              _moveTile(index);
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: tileNumber.isOdd ? Colors.green[200] : Colors.blue[500],
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$tileNumber',
              style: const TextStyle(
                fontSize: 999,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerOverlay(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isRunning = _stopwatch.isRunning;
    final canToggle = _hasStartedTimer &&
        !_isGameOver &&
        !_isShuffling &&
        (isRunning || _isPaused);

    return Material(
      elevation: 2,
      color: colorScheme.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatElapsed(_elapsed),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: !_hasStartedTimer
                  ? 'Press New Game to start'
                  : (_isShuffling
                      ? 'Shuffling…'
                      : (!isRunning && !_isPaused)
                          ? 'Make a move to start'
                          : (isRunning ? 'Pause' : 'Resume')),
              onPressed: canToggle
                  ? () {
                      if (isRunning) {
                        _pauseTimer();
                      } else {
                        _resumeTimer();
                      }
                    }
                  : null,
              icon: Icon(isRunning ? Icons.pause : Icons.play_arrow),
            ),
          ],
        ),
      ),
    );
  }
}
