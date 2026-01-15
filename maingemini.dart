import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final double containerWidth = 400;
  final double containerHeight = 600;
  double paddleX = 0;
  double ballX = 0, ballY = 0;
  double ballSpeedX = 3, ballSpeedY = -4;
  double paddleWidth = 100;
  int level = 1, score = 0;
  bool isGameOver = false, isStarted = false, isPaused = false;
  List<Box> boxes = [];
  Timer? gameTimer;
  final Random random = Random();

  late AnimationController gameOverController;
  late Animation<double> fadeIn;
  late AnimationController playPauseController;

  @override
  void initState() {
    super.initState();
    gameOverController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    fadeIn = CurvedAnimation(parent: gameOverController, curve: Curves.easeIn);
    playPauseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 340));
  }

  void startGame() {
    resetLevel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (_) => updateGame());
    setState(() {
      isStarted = true;
      isPaused = false;
    });
  }

  void resetLevel() {
    boxes.clear();
    const boxSize = 45.0;
    const spacing = 10.0;
    int boxCount = 8 + level * 2;
    final placed = <Offset>[];

    while (boxes.length < boxCount) {
      double dx = (random.nextDouble() * (containerWidth - 100)) - (containerWidth / 2 - 50);
      double dy = (random.nextDouble() * 200) - 250;
      Offset newPos = Offset(dx, dy);

      bool overlaps = placed.any((pos) => (pos - newPos).distance < boxSize + spacing);
      if (!overlaps) {
        boxes.add(Box(position: newPos, color: Colors.accents[random.nextInt(Colors.accents.length)]));
        placed.add(newPos);
      }
    }
    ballX = 0; ballY = 100;
    ballSpeedX = 2.5 + level * 0.3;
    ballSpeedY = -3.5 - level * 0.3;
    isGameOver = false;
    gameOverController.reset();
  }

  void updateGame() {
    if (isGameOver || isPaused) return;
    setState(() {
      ballX += ballSpeedX;
      ballY += ballSpeedY;

      if (ballX.abs() >= containerWidth / 2 - 15) ballSpeedX *= -1;
      if (ballY <= -containerHeight / 2 + 15) ballSpeedY *= -1;

      if (ballY >= containerHeight / 2 - 40 && (ballX - paddleX).abs() < paddleWidth / 2) {
        ballSpeedY *= -1.02; // Slight speed up
        ballSpeedX += (ballX - paddleX) * 0.1;
      }

      boxes.removeWhere((box) {
        if ((ballX - box.position.dx).abs() < 35 && (ballY - box.position.dy).abs() < 35) {
          score += 10;
          ballSpeedY *= -1;
          return true;
        }
        return false;
      });

      if (boxes.isEmpty) { level++; resetLevel(); }
      if (ballY >= containerHeight / 2) {
        isGameOver = true;
        gameTimer?.cancel();
        gameOverController.forward();
      }
    });
  }

  void pauseOrResumeGame() {
    setState(() {
      isPaused = !isPaused;
      isPaused ? playPauseController.reverse() : playPauseController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [Colors.blueGrey.shade900, Colors.black],
          ),
        ),
        child: SafeArea(
          child: GestureDetector(
            onPanUpdate: (details) {
              if (!isStarted || isPaused || isGameOver) return;
              setState(() {
                paddleX = (paddleX + details.delta.dx).clamp(-containerWidth / 2 + 50, containerWidth / 2 - 50);
              });
            },
            child: Column(
              children: [
                _buildModernHeader(),
                Expanded(child: _buildGameStage()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statColumn("SCORE", score.toString(), Colors.cyanAccent),
              if (isStarted && !isGameOver)
                IconButton(
                  onPressed: pauseOrResumeGame,
                  icon: AnimatedIcon(icon: AnimatedIcons.play_pause, progress: playPauseController, color: Colors.white),
                ),
              _statColumn("LEVEL", level.toString(), Colors.pinkAccent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statColumn(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.white60)),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color, shadows: [Shadow(color: color, blurRadius: 10)])),
      ],
    );
  }

  Widget _buildGameStage() {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Game Border
          Container(
            width: containerWidth,
            height: containerHeight,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: CustomPaint(painter: GamePainter(paddleX, ballX, ballY, boxes)),
          ),
          if (!isStarted) _buildMenuOverlay("NEON BREAKER", "START"),
          if (isGameOver) _buildMenuOverlay("GAME OVER", "RETRY"),
          if (isPaused) _buildMenuOverlay("PAUSED", "RESUME"),
        ],
      ),
    );
  }

  Widget _buildMenuOverlay(String title, String btnText) {
    return Container(
      width: containerWidth,
      height: containerHeight,
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(30)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.black, letterSpacing: 4)),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: isGameOver ? () => setState(() { isStarted = false; score = 0; level = 1; }) : (isPaused ? pauseOrResumeGame : startGame),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: StadiumBorder(),
            ),
            child: Text(btnText, style: const TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    gameOverController.dispose();
    playPauseController.dispose();
    super.dispose();
  }
}

class Box {
  final Offset position;
  final Color color;
  Box({required this.position, required this.color});
}

class GamePainter extends CustomPainter {
  final double paddleX, ballX, ballY;
  final List<Box> boxes;
  GamePainter(this.paddleX, this.ballX, this.ballY, this.boxes);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw Blocks with Neon Glow
    for (var box in boxes) {
      final paint = Paint()..color = box.color;
      final rect = Rect.fromCenter(center: center + box.position, width: 45, height: 25);
      
      // Glow effect
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(5)), 
          Paint()..color = box.color.withOpacity(0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(5)), paint);
    }

    // Draw Paddle
    final paddleRect = Rect.fromCenter(center: center + Offset(paddleX, 270), width: 100, height: 15);
    canvas.drawRRect(RRect.fromRectAndRadius(paddleRect, const Radius.circular(10)), 
        Paint()..color = Colors.cyanAccent..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawRRect(RRect.fromRectAndRadius(paddleRect, const Radius.circular(10)), Paint()..color = Colors.white);

    // Draw Ball
    final ballPos = center + Offset(ballX, ballY);
    canvas.drawCircle(ballPos, 12, Paint()..color = Colors.pinkAccent..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(ballPos, 8, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
