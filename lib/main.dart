import 'package:flutter/material.dart';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'web_utils_stub.dart'
    if (dart.library.html) 'web_utils.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '15 Puzzle',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const PuzzleGame(),
    );
  }
}

class PuzzleGame extends StatefulWidget {
  const PuzzleGame({super.key});

  @override
  State<PuzzleGame> createState() => _PuzzleGameState();
}

class _PuzzleGameState extends State<PuzzleGame> {
  List<int> tiles = [];
  int emptyIndex = 15;
  int moves = 0;

  bool _isShuffling = false;

  // 🔊 Audio
  late final AudioPlayer _player;
  late final AudioPlayer _winPlayer;
  bool _isPlayingSound = false;
  bool _audioInitialized = false;
  static const String _moveSound = 'sounds/tile_tick.wav';
  static const String _newGameSound = 'sounds/new_game_chime.wav';
  static const String _winSound = 'sounds/game_win_fanfare.wav';

  // 🎉 Confetti
  late ConfettiController _confettiController;

  // All acceptable solved layouts (0 = empty)
  static const List<List<int>> _goalBoards = [
    [
      1, 2, 3, 4,
      5, 6, 7, 8,
      9, 10, 11, 12,
      13, 14, 15, 0,
    ],
    [
      15, 14, 13, 12,
      11, 10, 9, 8,
      7, 6, 5, 4,
      3, 2, 1, 0,
    ],
    [
      1, 5, 9, 13,
      2, 6, 10, 14,
      3, 7, 11, 15,
      4, 8, 12, 0,
    ],
    [
      1, 3, 2, 4,
      5, 7, 6, 8,
      9, 11, 10, 12,
      13, 15, 14, 0,
    ],
    [
      1, 9, 2, 10,
      3, 11, 4, 12,
      5, 13, 6, 14,
      7, 15, 8, 0,
    ],
    [
      1, 4, 5, 8,
      2, 3, 6, 7,
      9, 10, 13, 14,
      0, 11, 12, 15,
    ],
  ];

  @override
  void initState() {
    super.initState();

    // Audio setup for short SFX
    _player = AudioPlayer();
    _player.setPlayerMode(PlayerMode.lowLatency);
    _player.setReleaseMode(ReleaseMode.stop);
    _player.setVolume(1.0);

    // Separate player for win sound
    _winPlayer = AudioPlayer();
    _winPlayer.setReleaseMode(ReleaseMode.stop);
    _winPlayer.setVolume(1.0);

    // Confetti init
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    _initializeSolvedBoard(_goalBoards.first);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _shufflePuzzle(playSound: false);
      
      // Remove loading spinner after first frame (web only)
      removeLoadingSpinner();
    });
  }

  @override
  void dispose() {
    _player.dispose();
    _winPlayer.dispose();
    _confettiController.dispose();
    super.dispose();
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
      return available < 520 ? (available < minBoardSize ? minBoardSize : available) : 520;
    } else if (width >= 768) {
      // Tablet: prefer 480px, but adapt if screen is smaller
      return available < 480 ? (available < minBoardSize ? minBoardSize : available) : 480;
    } else {
      // Mobile: use available space, max 340px, min 196px for touch targets
      if (available < minBoardSize) return minBoardSize;
      return available > 340 ? 340 : available;
    }
  }

  /// Initialize audio on first user interaction (required for iOS/Safari)
  Future<void> _initializeAudio() async {
    if (_audioInitialized) return;
    
    try {
      // Initialize audio context for web/Safari
      initAudioContext();
      
      // Preload sounds by playing them at zero volume
      await _player.setVolume(0.0);
      await _player.play(AssetSource(_moveSound));
      await Future.delayed(const Duration(milliseconds: 50));
      await _player.stop();
      await _player.setVolume(1.0);
      
      _audioInitialized = true;
      debugPrint('Audio initialized successfully');
    } catch (e) {
      debugPrint('Audio initialization error: $e');
    }
  }

  Future<void> _playSound(String asset) async {
    if (_isPlayingSound) return; // Skip if already playing
    
    // Initialize audio on first play attempt
    if (!_audioInitialized) {
      await _initializeAudio();
    }
    
    try {
      _isPlayingSound = true;
      await _player.stop();
      await _player.play(AssetSource(asset));
      
      // Reset flag after a short delay
      Future.delayed(const Duration(milliseconds: 50), () {
        _isPlayingSound = false;
      });
    } catch (e) {
      _isPlayingSound = false;
      debugPrint('Audio error: $e');
    }
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
      // Initialize audio on first tap (iOS/Safari requirement)
      if (!_audioInitialized) {
        _initializeAudio();
      }
      
      setState(() {
        tiles[emptyIndex] = tiles[index];
        tiles[index] = 0;
        emptyIndex = index;
        if (countMove) moves++;
      });

      if (playSound && !_isShuffling) {
        _playSound(_moveSound);
      }

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

  void _handleWin() async {
    _confettiController.play();
    try {
      await _winPlayer.play(AssetSource(_winSound));
    } catch (e) {
      debugPrint('Win audio error: $e');
    }
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
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _confettiController.stop();
                  Navigator.of(context).pop();
                  _shufflePuzzle();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('15 Puzzle'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Moves: $moves',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox.square(
                dimension: getBoardSize(context),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: 16,
                    itemBuilder: (context, index) => _buildTile(index),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isShuffling ? null : _shufflePuzzle,
                child: const Text('New Game'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile(int index) {
    final tileNumber = tiles[index];

    if (tileNumber == 0) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _moveTile(index),
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
}
