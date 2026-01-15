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
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
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

  final List<Color> gameBoxColors = [
    Colors.red.shade400,
    Colors.blue.shade400,
    Colors.green.shade400,
    Colors.orange.shade400,
    Colors.purple.shade400,
    Colors.yellow.shade400,
    Colors.cyan.shade400,
    Colors.pink.shade400,
    Colors.amber.shade400,
    Colors.teal.shade400,
    Colors.lime.shade400,
    Colors.indigo.shade400,
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
    super.dispose();
  }

  Widget buildNeonAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
      child: Stack(
        children: [
          // Neon glow background
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.purple.shade800.withOpacity(0.3),
                  Colors.blue.shade900.withOpacity(0.1),
                  Colors.black,
                ],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(3),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.shade900,
                      Colors.blue.shade900,
                      Colors.black,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.cyan.shade400,
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.shade400.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.purple.shade500.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNeonStat(Icons.electric_bolt, "LEVEL", "$level"),
                    _buildNeonStat(Icons.star, "SCORE", "$score"),
                    if (isStarted && !isGameOver) _buildNeonPauseButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeonStat(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.cyan.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.cyan.shade400, width: 2),
          ),
          child: Icon(icon, color: Colors.cyan.shade300, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.6),
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.cyan.shade400,
                offset: const Offset(0, 0),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNeonPauseButton() => GestureDetector(
        onTap: pauseOrResumeGame,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.shade700,
                Colors.pink.shade700,
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.purple.shade500.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(color: Colors.pink.shade400, width: 2),
          ),
          child: AnimatedIcon(
            icon: AnimatedIcons.play_pause,
            progress: playPauseController,
            color: Colors.white,
            size: 28,
          ),
        ),
      );

  Widget buildCyberGameArea() {
    return Center(
      child: Container(
        width: containerWidth,
        height: containerHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.cyan.shade400,
            width: 4,
            strokeAlign: BorderSide.strokeAlignCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyan.shade400.withOpacity(0.4),
              blurRadius: 30,
              spreadRadius: 5,
            ),
            BoxShadow(
              color: Colors.purple.shade500.withOpacity(0.3),
              blurRadius: 40,
              spreadRadius: 0,
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Colors.blue.shade900.withOpacity(0.3),
              Colors.black,
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Grid lines background
            CustomPaint(painter: GridPainter()),
            if (isStarted)
              CustomPaint(painter: GamePainter(paddleX, ballX, ballY, boxes)),
            if (!isStarted) _buildCyberStartButton(),
            if (isGameOver) _buildCyberGameOverOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildCyberStartButton() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.cyan.shade400, Colors.purple.shade400],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.cyan.shade400.withOpacity(0.6),
              blurRadius: 25,
              spreadRadius: 3,
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          child: InkWell(
            borderRadius: BorderRadius.circular(25),
            onTap: startGame,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_arrow, size: 32, color: Colors.black),
                  const SizedBox(width: 12),
                  const Text(
                    "START MISSION",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildCyberGameOverOverlay() => AnimatedBuilder(
        animation: fadeIn,
        builder: (context, child) => Opacity(
          opacity: fadeIn.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.9),
                  Colors.purple.shade900.withOpacity(0.7),
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: 340,
                padding: const EdgeInsets.all(35),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.shade800,
                      Colors.black,
                      Colors.blue.shade900,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.red.shade400, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.shade500.withOpacity(0.5),
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
                        gradient: LinearGradient(
                          colors: [Colors.red.shade600, Colors.red.shade800],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.dangerous,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "MISSION FAILED",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        letterSpacing: 3,
                        shadows: [
                          Shadow(
                            color: Colors.red,
                            offset: Offset(0, 0),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "Final Score: $score",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.cyan,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: Colors.cyan,
                            offset: Offset(0, 0),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildCyberRestartButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildCyberRestartButton() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.teal.shade400],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.green.shade400.withOpacity(0.6),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          child: InkWell(
            borderRadius: BorderRadius.circular(25),
            onTap: restartGame,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.replay, size: 28, color: Colors.black),
                  const SizedBox(width: 10),
                  const Text(
                    "RESTART",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
              buildNeonAppBar(),
              Expanded(child: buildCyberGameArea()),
            ],
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
      ..color = Colors.cyan.withOpacity(0.1)
      ..strokeWidth = 1;
    
    // Vertical lines
    for (int i = 0; i < 10; i++) {
      double x = (size.width / 10) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    // Horizontal lines
    for (int i = 0; i < 15; i++) {
      double y = (size.height / 15) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
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

    // Cyber paddle with neon glow
    final paddleRect = Rect.fromCenter(
      center: Offset(centerX + paddleX, centerY + 270),
      width: 100,
      height: 20,
    );
    
    // Paddle outer glow
    final outerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.cyan.shade300.withOpacity(0.8),
          Colors.cyan.shade100.withOpacity(0.3),
          Colors.transparent,
        ],
      ).createShader(paddleRect.inflate(15));
    canvas.drawRRect(
      RRect.fromRectAndRadius(paddleRect.inflate(15), const Radius.circular(20)),
      outerGlow,
    );

    // Paddle inner glow
    final innerGlow = Paint()
      ..shader = LinearGradient(
        colors: [Colors.cyan.shade400, Colors.blue.shade400],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(paddleRect.inflate(5));
    canvas.drawRRect(
      RRect.fromRectAndRadius(paddleRect.inflate(5), const Radius.circular(18)),
      innerGlow,
    );

    // Paddle core
    final corePaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white, Colors.cyan.shade200],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(paddleRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(paddleRect, const Radius.circular(14)),
      corePaint,
    );

    // Cyber ball with multiple glow layers
    final ballCenter = Offset(centerX + ballX, centerY + ballY);
    final ballRect = Rect.fromCircle(center: ballCenter, radius: 19);

    // Outer glow
    final outerBallGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.6),
          Colors.cyan.shade200.withOpacity(0.4),
          Colors.transparent,
        ],
      ).createShader(ballRect.inflate(20));
    canvas.drawCircle(ballCenter, 25, outerBallGlow);

    // Inner glow
    final innerBallGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.cyan.shade300,
          Colors.blue.shade400,
          Colors.white.withOpacity(0.3),
        ],
      ).createShader(ballRect.inflate(10));
    canvas.drawCircle(ballCenter, 18, innerBallGlow);

    // Ball core
    final ballCore = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white, Colors.cyan.shade100, Colors.blue.shade300],
      ).createShader(ballRect);
    canvas.drawCircle(ballCenter, 12, ballCore);

    // Neon boxes with glow effects
    for (final box in boxes) {
      final boxCenter = Offset(centerX + box.position.dx, centerY + box.position.dy);
      final boxRect = Rect.fromCenter(center: boxCenter, width: 50, height: 50);

      // Box outer glow
      final boxGlow = Paint()
        ..shader = RadialGradient(
          colors: [
            box.color.withOpacity(0.6),
            box.color.withOpacity(0.2),
            Colors.transparent,
          ],
        ).createShader(boxRect.inflate(12));
      canvas.drawRRect(
        RRect.fromRectAndRadius(boxRect.inflate(12), const Radius.circular(15)),
        boxGlow,
      );

      // Box core with border glow
      final boxCore = Paint()
        ..shader = LinearGradient(
          colors: [box.color, box.color.withOpacity(0.7), Colors.white.withOpacity(0.2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(boxRect);
      canvas.drawRRect(
        RRect.fromRectAndRadius(boxRect, const Radius.circular(10)),
        boxCore,
      );

      // Neon border
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(
        RRect.fromRectAndRadius(boxRect, const Radius.circular(10)),
        borderPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
