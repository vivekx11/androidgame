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
        scaffoldBackgroundColor: const Color(0xFF0A0E27),
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
  final double containerWidth = 400;
  final double containerHeight = 600;

  double paddleX = 0;
  double ballX = 0, ballY = 0;
  double ballSpeedX = 3, ballSpeedY = -4;
  double paddleWidth = 100;

  int level = 1, score = 0;
  bool isGameOver = false;
  bool isStarted = false;
  bool isPaused = false;

  List<Box> boxes = [];
  Timer? gameTimer;
  final Random random = Random();

  late AnimationController gameOverController;
  late Animation<double> fadeIn;
  late AnimationController playPauseController;
  late AnimationController pulseController;

  final List<Color> gameBoxColors = [
    const Color(0xFFFF6B9D),
    const Color(0xFFC86DD7),
    const Color(0xFF3023AE),
    const Color(0xFF53A0FD),
    const Color(0xFF00D4FF),
    const Color(0xFF06FFA5),
    const Color(0xFFFECA57),
    const Color(0xFFFF6348),
    const Color(0xFFFF9FF3),
    const Color(0xFF54A0FF),
    const Color(0xFF00D2D3),
    const Color(0xFF1DD1A1),
    const Color(0xFFFFD32A),
    const Color(0xFFFF793F),
    const Color(0xFFB8E994),
    const Color(0xFF78E08F),
  ];

  @override
  void initState() {
    super.initState();
    gameOverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    fadeIn = CurvedAnimation(parent: gameOverController, curve: Curves.easeIn);
    playPauseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
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
    });
  }

  void resetLevel() {
    boxes.clear();
    const boxSize = 50.0;
    const spacing = 12.0;
    final placed = <Offset>[];
    int boxCount = 6 + level * 2;

    while (boxes.length < boxCount && placed.length < 1000) {
      double minX = -containerWidth / 2 + boxSize / 2;
      double maxX = containerWidth / 2 - boxSize / 2;
      double minY = -containerHeight / 2 + 50;
      double maxY = 0;
      double dx = random.nextDouble() * (maxX - minX) + minX;
      double dy = random.nextDouble() * (maxY - minY) + minY;
      Offset newPos = Offset(dx, dy);
      bool overlaps = placed.any(
        (pos) => (pos - newPos).distance < boxSize + spacing,
      );
      if (!overlaps) {
        final color = gameBoxColors[random.nextInt(gameBoxColors.length)];
        boxes.add(Box(position: newPos, color: color));
        placed.add(newPos);
      }
    }
    ballX = 0;
    ballY = 0;
    ballSpeedX = 2 + level * 0.4;
    ballSpeedY = -3 - level * 0.3;
    isGameOver = false;
    gameOverController.reset();
  }

  void updateGame() {
    if (isGameOver || isPaused) return;
    setState(() {
      ballX += ballSpeedX;
      ballY += ballSpeedY;

      if (ballX <= -containerWidth / 2 + 12 ||
          ballX >= containerWidth / 2 - 12) {
        ballSpeedX *= -1;
      }

      double topLimit = -containerHeight / 2 + 12;
      if (ballY <= topLimit) {
        ballY = topLimit;
        ballSpeedY *= -1;
      }

      if (ballY >= containerHeight / 2 - 30 &&
          (ballX > paddleX - paddleWidth / 2) &&
          (ballX < paddleX + paddleWidth / 2)) {
        ballSpeedY *= -1;
        ballSpeedX += (ballX - paddleX) * 0.05;
      }

      boxes.removeWhere((box) {
        if ((ballX - box.position.dx).abs() < 30 &&
            (ballY - box.position.dy).abs() < 30) {
          score += 10;
          ballSpeedY *= -1;
          return true;
        }
        return false;
      });

      if (boxes.isEmpty) {
        level++;
        resetLevel();
      }

      if (ballY >= containerHeight / 2 - 10) {
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
    });
  }

  void pauseOrResumeGame() {
    setState(() {
      isPaused = !isPaused;
      if (isPaused) {
        playPauseController.reverse();
      } else {
        playPauseController.forward();
      }
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    gameOverController.dispose();
    playPauseController.dispose();
    pulseController.dispose();
    super.dispose();
  }

  Widget buildAppBarUI(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF667EEA).withOpacity(0.15),
            const Color(0xFF764BA2).withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatCard(Icons.layers_rounded, "Level", "$level", const Color(0xFF00D4FF)),
          _buildStatCard(Icons.emoji_events_rounded, "Score", "$score", const Color(0xFFFECA57)),
          if (isStarted && !isGameOver) _buildPauseButton(),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPauseButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: pauseOrResumeGame,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFF6B9D).withOpacity(0.8),
                const Color(0xFFC86DD7).withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B9D).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AnimatedIcon(
            icon: AnimatedIcons.play_pause,
            progress: playPauseController,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget buildGameArea() {
    return Center(
      child: Container(
        width: containerWidth,
        height: containerHeight,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF1A1F3A),
              Color(0xFF0F1419),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(
            width: 3,
            color: Colors.white.withOpacity(0.1),
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667EEA).withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Grid pattern background
              CustomPaint(
                painter: GridPainter(),
                size: Size(containerWidth, containerHeight),
              ),
              if (isStarted)
                CustomPaint(
                  painter: GamePainter(paddleX, ballX, ballY, boxes),
                  size: Size(containerWidth, containerHeight),
                ),
              if (!isStarted) Center(child: buildStartButton()),
              if (isGameOver) buildGameOverOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildStartButton() {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (pulseController.value * 0.05),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667EEA).withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: startGame,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.play_arrow_rounded, size: 32, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        "START GAME",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildGameOverOverlay() {
    return AnimatedBuilder(
      animation: fadeIn,
      builder: (context, child) => Opacity(
        opacity: fadeIn.value,
        child: Container(
          color: Colors.black.withOpacity(0.85),
          child: Center(
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF2C3E50),
                    Color(0xFF1A1F3A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B9D).withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B9D).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 50,
                      color: Color(0xFFFF6B9D),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "GAME OVER",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 60,
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B9D), Color(0xFFC86DD7)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFECA57).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFECA57).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Final Score",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "$score",
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFECA57),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667EEA).withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: restartGame,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.refresh_rounded, color: Colors.white, size: 24),
                              SizedBox(width: 12),
                              Text(
                                "PLAY AGAIN",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0E27), Color(0xFF1A1F3A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: GestureDetector(
            onPanUpdate: (details) {
              if (!isStarted || isPaused || isGameOver) return;
              setState(() {
                paddleX += details.delta.dx;
                double maxX = containerWidth / 2 - paddleWidth / 2;
                paddleX = paddleX.clamp(-maxX, maxX);
              });
            },
            child: Column(
              children: [
                buildAppBarUI(context),
                Expanded(child: buildGameArea()),
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

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;

    const spacing = 30.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class GamePainter extends CustomPainter {
  final double paddleX;
  final double ballX, ballY;
  final List<Box> boxes;
  GamePainter(this.paddleX, this.ballX, this.ballY, this.boxes);

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw paddle with gradient
    final paddleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX + paddleX, centerY + 270),
        width: 100,
        height: 20,
      ),
      const Radius.circular(10),
    );
    
    final paddlePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF00D4FF), Color(0xFF06FFA5)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(paddleRect.outerRect);
    
    canvas.drawRRect(paddleRect, paddlePaint);

    // Draw paddle glow
    final paddleGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00D4FF).withOpacity(0.3),
          Colors.transparent,
        ],
      ).createShader(paddleRect.outerRect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRRect(paddleRect, paddleGlowPaint);

    // Draw ball with glow effect
    final ballCenter = Offset(centerX + ballX, centerY + ballY);
    
    // Ball glow
    final ballGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.6),
          const Color(0xFF00D4FF).withOpacity(0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: ballCenter, radius: 25))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(ballCenter, 20, ballGlowPaint);

    // Ball
    final ballPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          const Color(0xFF00D4FF),
          const Color(0xFF667EEA),
        ],
        center: Alignment.topLeft,
      ).createShader(Rect.fromCircle(center: ballCenter, radius: 12));
    canvas.drawCircle(ballCenter, 12, ballPaint);

    // Draw boxes with modern style
    for (final box in boxes) {
      final boxCenter = Offset(
        centerX + box.position.dx,
        centerY + box.position.dy,
      );
      
      final boxRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: boxCenter, width: 50, height: 50),
        const Radius.circular(12),
      );

      // Box shadow
      final shadowPaint = Paint()
        ..color = box.color.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(boxCenter.dx, boxCenter.dy + 4),
            width: 50,
            height: 50,
          ),
          const Radius.circular(12),
        ),
        shadowPaint,
      );

      // Box gradient
      final boxPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            box.color,
            box.color.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(boxRect.outerRect);
      canvas.drawRRect(boxRect, boxPaint);

      // Box highlight
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            boxCenter.dx - 22,
            boxCenter.dy - 22,
            44,
            15,
          ),
          const Radius.circular(12),
        ),
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
