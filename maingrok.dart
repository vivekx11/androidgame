import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyanAccent),
      ),
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
  final double containerWidth = 380;
  final double containerHeight = 620;

  double paddleX = 0;
  double ballX = 0, ballY = 0;
  double ballSpeedX = 3.2, ballSpeedY = -4.8;
  double paddleWidth = 110;

  int level = 1;
  int score = 0;
  bool isGameOver = false;
  bool isStarted = false;
  bool isPaused = false;

  List<Box> boxes = [];
  Timer? gameTimer;
  final Random random = Random();

  late AnimationController gameOverController;
  late Animation<double> gameOverFade;
  late AnimationController pauseController;
  late Animation<double> pauseScale;

  final List<Color> boxColors = [
    Colors.cyanAccent,
    Colors.pinkAccent,
    Colors.limeAccent,
    Colors.amberAccent,
    Colors.purpleAccent,
    Colors.tealAccent,
    const Color(0xFF00D4FF),
    const Color(0xFFFF2E63),
  ];

  @override
  void initState() {
    super.initState();

    gameOverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    gameOverFade = CurvedAnimation(
      parent: gameOverController,
      curve: Curves.easeOutCubic,
    );

    pauseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      value: 1.0,
    );
    pauseScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: pauseController, curve: Curves.elasticOut),
    );
  }

  void startGame() {
    resetLevel();
    gameTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => updateGame(),
    );
    setState(() {
      isStarted = true;
      isPaused = false;
      isGameOver = false;
    });
  }

  void resetLevel() {
    boxes.clear();

    const boxSize = 54.0;
    const spacing = 14.0;
    final placed = <Offset>[];

    int targetBoxes = 7 + level * 3;

    while (boxes.length < targetBoxes && placed.length < 1200) {
      double minX = -containerWidth / 2 + boxSize / 2 + 20;
      double maxX = containerWidth / 2 - boxSize / 2 - 20;
      double minY = -containerHeight / 2 + 80;
      double maxY = -containerHeight / 4;

      double dx = random.nextDouble() * (maxX - minX) + minX;
      double dy = random.nextDouble() * (maxY - minY) + minY;

      Offset pos = Offset(dx, dy);
      bool overlaps = placed.any((p) => (p - pos).distance < boxSize + spacing);

      if (!overlaps) {
        final color = boxColors[random.nextInt(boxColors.length)];
        boxes.add(Box(position: pos, color: color));
        placed.add(pos);
      }
    }

    ballX = 0;
    ballY = 100;
    ballSpeedX = 2.8 + level * 0.45;
    ballSpeedY = -4.2 - level * 0.35;

    isGameOver = false;
    gameOverController.reset();
  }

  void updateGame() {
    if (isGameOver || isPaused || !isStarted) return;

    setState(() {
      ballX += ballSpeedX;
      ballY += ballSpeedY;

      // Wall bounce — left / right
      if (ballX <= -containerWidth / 2 + 18 || ballX >= containerWidth / 2 - 18) {
        ballSpeedX *= -1;
      }

      // Top bounce
      if (ballY <= -containerHeight / 2 + 18) {
        ballY = -containerHeight / 2 + 18;
        ballSpeedY *= -1;
      }

      // Paddle bounce
      if (ballY >= containerHeight / 2 - 45 &&
          ballX > paddleX - paddleWidth / 2 - 8 &&
          ballX < paddleX + paddleWidth / 2 + 8) {
        ballSpeedY *= -1;
        // Add angle based on hit position
        ballSpeedX += (ballX - paddleX) * 0.065;
      }

      // Box hits
      boxes.removeWhere((box) {
        double dx = (ballX - box.position.dx).abs();
        double dy = (ballY - box.position.dy).abs();
        if (dx < 32 && dy < 32) {
          score += 10 + level * 2;
          ballSpeedY *= -1.04; // slight speed increase
          return true;
        }
        return false;
      });

      // Level complete
      if (boxes.isEmpty) {
        level++;
        resetLevel();
      }

      // Game over — fell through bottom
      if (ballY > containerHeight / 2 - 5) {
        isGameOver = true;
        gameTimer?.cancel();
        gameOverController.forward();
      }
    });
  }

  void restartGame() {
    setState(() {
      level = 1;
      score = 0;
      paddleX = 0;
      isStarted = false;
      isGameOver = false;
      isPaused = false;
    });
    gameTimer?.cancel();
  }

  void togglePause() {
    setState(() {
      isPaused = !isPaused;
      if (isPaused) {
        pauseController.reverse();
        gameTimer?.cancel();
      } else {
        pauseController.forward();
        gameTimer = Timer.periodic(
          const Duration(milliseconds: 16),
          (_) => updateGame(),
        );
      }
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    gameOverController.dispose();
    pauseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onPanUpdate: (details) {
            if (!isStarted || isPaused || isGameOver) return;
            setState(() {
              paddleX += details.delta.dx * 1.15;
              paddleX = paddleX.clamp(
                -containerWidth / 2 + paddleWidth / 2,
                containerWidth / 2 - paddleWidth / 2,
              );
            });
          },
          child: Stack(
            children: [
              // Background gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0D1117), Color(0xFF161B22), Color(0xFF0D1117)],
                  ),
                ),
              ),

              Column(
                children: [
                  _buildNeonHeader(),
                  Expanded(child: _buildGameField()),
                ],
              ),

              if (!isStarted) _buildStartOverlay(),
              if (isGameOver) _buildGameOverOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNeonHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.cyan.withOpacity(0.18), Colors.purple.withOpacity(0.13)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.35), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.15),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _neonStat(Icons.rocket, "LEVEL", "$level"),
            _neonStat(Icons.score, "SCORE", "$score"),
            if (isStarted && !isGameOver)
              ScaleTransition(
                scale: pauseScale,
                child: _buildPauseButton(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _neonStat(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.cyanAccent, size: 26),
        const SizedBox(width: 8),
        Text(
          "$label  ",
          style: TextStyle(
            fontSize: 15,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 8)],
          ),
        ),
      ],
    );
  }

  Widget _buildPauseButton() {
    return GestureDetector(
      onTap: togglePause,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.4)),
        ),
        child: AnimatedIcon(
          icon: AnimatedIcons.play_pause,
          progress: pauseController,
          color: Colors.cyanAccent,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildGameField() {
    return Center(
      child: Container(
        width: containerWidth,
        height: containerHeight,
        decoration: BoxDecoration(
          color: const Color(0xFF010409),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.6), width: 3.5),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.25),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isStarted)
              CustomPaint(
                painter: NeonGamePainter(paddleX, ballX, ballY, boxes),
                size: Size(containerWidth, containerHeight),
              ),

            if (!isStarted)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "NEON BREAKOUT",
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: Colors.cyanAccent,
                        letterSpacing: 4,
                        shadows: [Shadow(blurRadius: 20, color: Colors.cyanAccent)],
                      ),
                    ),
                    const SizedBox(height: 50),
                    ElevatedButton.icon(
                      onPressed: startGame,
                      icon: const Icon(Icons.play_arrow_rounded, size: 38),
                      label: const Text("PLAY", style: TextStyle(fontSize: 26)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 22),
                        backgroundColor: Colors.cyanAccent.withOpacity(0.9),
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 20,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartOverlay() {
    return const SizedBox.shrink(); // already in _buildGameField
  }

  Widget _buildGameOverOverlay() {
    return AnimatedBuilder(
      animation: gameOverFade,
      builder: (context, _) => Opacity(
        opacity: gameOverFade.value,
        child: Container(
          color: Colors.black.withOpacity(0.82),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.redAccent, Colors.pinkAccent, Colors.purpleAccent],
                  ).createShader(bounds),
                  child: const Text(
                    "GAME OVER",
                    style: TextStyle(
                      fontSize: 58,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 6,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "SCORE: $score",
                  style: const TextStyle(
                    fontSize: 36,
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 50),
                ElevatedButton.icon(
                  onPressed: restartGame,
                  icon: const Icon(Icons.replay_rounded, size: 32),
                  label: const Text("RESTART", style: TextStyle(fontSize: 24)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                    backgroundColor: Colors.redAccent.withOpacity(0.9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Box {
  final Offset position;
  final Color color;
  Box({required this.position, required this.color});
}

class NeonGamePainter extends CustomPainter {
  final double paddleX;
  final double ballX, ballY;
  final List<Box> boxes;

  NeonGamePainter(this.paddleX, this.ballX, this.ballY, this.boxes);

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Paddle — neon glow
    final paddleRect = Rect.fromCenter(
      center: Offset(centerX + paddleX, centerY + 260),
      width: 110,
      height: 24,
    );

    final paddlePaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.cyanAccent, Colors.tealAccent, Colors.cyan.shade700],
      ).createShader(paddleRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(paddleRect, const Radius.circular(16)),
      paddlePaint,
    );

    // Paddle glow
    final glowPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX + paddleX, centerY + 262),
          width: 118,
          height: 32,
        ),
        const Radius.circular(20),
      ),
      glowPaint,
    );

    // Ball — glowing orb
    final ballCenter = Offset(centerX + ballX, centerY + ballY);
    final ballPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white, Colors.cyanAccent, Colors.blueAccent.shade700],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: ballCenter, radius: 22));

    canvas.drawCircle(ballCenter, 18, ballPaint);

    // Ball outer glow
    final ballGlow = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(ballCenter, 26, ballGlow);

    // Boxes — neon blocks
    for (final box in boxes) {
      final boxRect = Rect.fromCenter(
        center: Offset(centerX + box.position.dx, centerY + box.position.dy),
        width: 54,
        height: 54,
      );

      final boxPaint = Paint()..color = box.color.withOpacity(0.92);
      canvas.drawRRect(
        RRect.fromRectAndRadius(boxRect, const Radius.circular(14)),
        boxPaint,
      );

      // Box glow
      final glow = Paint()
        ..color = box.color.withOpacity(0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.inflate(boxRect, 6, 6),
          const Radius.circular(18),
        ),
        glow,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
