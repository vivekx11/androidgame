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
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFF00FF88),
        ),
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
  final double containerHeight = 580;

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
  late AnimationController ballBounceController;

  final List<Color> boxColors = [
    const Color(0xFFFF6B6B),
    const Color(0xFF4ECDC4),
    const Color(0xFFFFD166),
    const Color(0xFF06D6A0),
    const Color(0xFF118AB2),
    const Color(0xFFEF476F),
    const Color(0xFF9D4EDD),
    const Color(0xFFFF9E6D),
  ];

  final List<Gradient> levelGradients = [
    const LinearGradient(
      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  @override
  void initState() {
    super.initState();
    gameOverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    fadeIn = CurvedAnimation(
      parent: gameOverController,
      curve: Curves.easeInOutBack,
    );
    playPauseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    ballBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
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
      double minY = -containerHeight / 2 + 80;
      double maxY = 0;
      double dx = random.nextDouble() * (maxX - minX) + minX;
      double dy = random.nextDouble() * (maxY - minY) + minY;
      Offset newPos = Offset(dx, dy);
      bool overlaps = placed.any(
        (pos) => (pos - newPos).distance < boxSize + spacing,
      );
      if (!overlaps) {
        final color = boxColors[random.nextInt(boxColors.length)];
        boxes.add(Box(
          position: newPos,
          color: color,
          rotation: random.nextDouble() * 0.2 - 0.1,
        ));
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

      // Clamp left/right walls
      if (ballX <= -containerWidth / 2 + 12 ||
          ballX >= containerWidth / 2 - 12) {
        ballSpeedX *= -1;
        ballBounceController.forward(from: 0);
      }

      // Clamp top wall
      double topLimit = -containerHeight / 2 + 12;
      if (ballY <= topLimit) {
        ballY = topLimit;
        ballSpeedY *= -1;
        ballBounceController.forward(from: 0);
      }

      // Paddle bounce
      if (ballY >= containerHeight / 2 - 30 &&
          (ballX > paddleX - paddleWidth / 2) &&
          (ballX < paddleX + paddleWidth / 2)) {
        ballSpeedY *= -1;
        ballSpeedX += (ballX - paddleX) * 0.05;
        ballBounceController.forward(from: 0);
      }

      // Box collision
      boxes.removeWhere((box) {
        if ((ballX - box.position.dx).abs() < 30 &&
            (ballY - box.position.dy).abs() < 30) {
          score += 10;
          ballSpeedY *= -1;
          ballBounceController.forward(from: 0);
          return true;
        }
        return false;
      });

      // Next level
      if (boxes.isEmpty) {
        level++;
        resetLevel();
      }

      // Game over (bottom)
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
    ballBounceController.dispose();
    super.dispose();
  }

  Widget buildAppBarUI() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: levelGradients[(level - 1) % levelGradients.length],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatCard(Icons.rocket_launch, "LEVEL", "$level"),
          _buildStatCard(Icons.star, "SCORE", "$score"),
          if (isStarted && !isGameOver) _buildPauseButton(),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPauseButton() {
    return GestureDetector(
      onTap: pauseOrResumeGame,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
        ),
        child: Center(
          child: AnimatedIcon(
            icon: AnimatedIcons.play_pause,
            progress: playPauseController,
            color: Colors.white,
            size: 30,
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
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 2),
        ),
        child: Stack(
          children: [
            // Background pattern
            _buildBackgroundPattern(),
            
            if (isStarted)
              CustomPaint(
                painter: GamePainter(
                  paddleX,
                  ballX,
                  ballY,
                  boxes,
                  ballBounceController,
                  levelGradients[(level - 1) % levelGradients.length],
                ),
              ),
            
            if (!isStarted) _buildStartScreen(),
            if (isGameOver) _buildGameOverOverlay(),
            
            // Overlay border
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.05),
                  width: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundPattern() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.1,
        child: CustomPaint(
          painter: BackgroundPainter(),
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Text(
            "BRICK BREAKER",
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: Colors.blue.withOpacity(0.5),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "LEVEL $level",
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.7),
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: startGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF88),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              elevation: 15,
              shadowColor: const Color(0xFF00FF88).withOpacity(0.5),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow, size: 28),
                SizedBox(width: 12),
                Text(
                  "START GAME",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(flex: 3),
          Text(
            "Drag to move paddle",
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return AnimatedBuilder(
      animation: fadeIn,
      builder: (context, child) => Opacity(
        opacity: fadeIn.value,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.9),
                Colors.black.withOpacity(0.7),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Transform.scale(
              scale: fadeIn.value,
              child: Material(
                elevation: 30,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sentiment_dissatisfied,
                        size: 60,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "GAME OVER",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            "FINAL SCORE",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "$score",
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: restartGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          elevation: 10,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.replay, size: 24),
                            SizedBox(width: 12),
                            Text(
                              "PLAY AGAIN",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: GestureDetector(
            onPanUpdate: (details) {
              if (!isStarted || isPaused || isGameOver) return;
              setState(() {
                paddleX += details.delta.dx * 1.5;
                double maxX = containerWidth / 2 - paddleWidth / 2;
                paddleX = paddleX.clamp(-maxX, maxX);
              });
            },
            child: Column(
              children: [
                buildAppBarUI(),
                const SizedBox(height: 20),
                Expanded(child: buildGameArea()),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    "Drag horizontally to control the paddle",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                      letterSpacing: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
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
  final double rotation;
  
  Box({
    required this.position,
    required this.color,
    this.rotation = 0,
  });
}

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw grid
    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Draw corner accents
    final cornerPaint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const radius = 50.0;
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(0, 0), radius: radius),
      -pi / 2,
      pi / 2,
      false,
      cornerPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width, 0), radius: radius),
      0,
      pi / 2,
      false,
      cornerPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(0, size.height), radius: radius),
      pi,
      pi / 2,
      false,
      cornerPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width, size.height), radius: radius),
      pi / 2,
      pi / 2,
      false,
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class GamePainter extends CustomPainter {
  final double paddleX;
  final double ballX, ballY;
  final List<Box> boxes;
  final AnimationController ballAnimation;
  final Gradient levelGradient;

  GamePainter(
    this.paddleX,
    this.ballX,
    this.ballY,
    this.boxes,
    this.ballAnimation,
    this.levelGradient,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw paddle with gradient and shadow
    final paddlePaint = Paint()
      ..shader = levelGradient.createShader(
        Rect.fromCenter(
          center: Offset(centerX + paddleX, centerY + 260),
          width: 100,
          height: 20,
        ),
      );
    
    // Paddle shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX + paddleX, centerY + 265),
          width: 100,
          height: 20,
        ),
        const Radius.circular(10),
      ),
      shadowPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX + paddleX, centerY + 260),
          width: 100,
          height: 20,
        ),
        const Radius.circular(10),
      ),
      paddlePaint,
    );

    // Draw ball with animation
    final ballScale = 1.0 + ballAnimation.value * 0.1;
    final ballPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          const Color(0xFF00FF88).withOpacity(0.8),
          const Color(0xFF00FF88),
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(centerX + ballX, centerY + ballY),
          radius: 15 * ballScale,
        ),
      );

    // Ball glow
    final glowPaint = Paint()
      ..color = const Color(0xFF00FF88).withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    
    canvas.drawCircle(
      Offset(centerX + ballX, centerY + ballY),
      20 * ballScale,
      glowPaint,
    );

    canvas.drawCircle(
      Offset(centerX + ballX, centerY + ballY),
      13 * ballScale,
      ballPaint,
    );

    // Draw boxes with 3D effect
    for (final box in boxes) {
      final boxCenter = Offset(
        centerX + box.position.dx,
        centerY + box.position.dy,
      );

      // Save canvas for rotation
      canvas.save();
      canvas.translate(boxCenter.dx, boxCenter.dy);
      canvas.rotate(box.rotation);

      // Box shadow
      final shadowRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-25, 3, 50, 50),
        const Radius.circular(8),
      );
      canvas.drawRRect(
        shadowRect,
        Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      // Main box
      final boxRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-25, 0, 50, 50),
        const Radius.circular(8),
      );
      final boxGradient = LinearGradient(
        colors: [
          box.color,
          Color.lerp(box.color, Colors.black, 0.2)!,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      
      canvas.drawRRect(
        boxRect,
        Paint()
          ..shader = boxGradient.createShader(
            const Rect.fromLTWH(-25, 0, 50, 50),
          ),
      );

      // Box highlight
      final highlightPath = Path()
        ..moveTo(-20, -20)
        ..lineTo(0, -20)
        ..lineTo(-20, 0)
        ..close();
      
      canvas.drawPath(
        highlightPath,
        Paint()..color = Colors.white.withOpacity(0.2),
      );

      // Box border
      canvas.drawRRect(
        boxRect,
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      canvas.restore();
    }

    // Draw level number in background
    final levelText = TextPainter(
      text: TextSpan(
        text: '${(levelGradient == const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)], begin: Alignment.topLeft, end: Alignment.bottomRight)) ? '1' : 
               (levelGradient == const LinearGradient(colors: [Color(0xFFF093FB), Color(0xFFF5576C)], begin: Alignment.topLeft, end: Alignment.bottomRight)) ? '2' : 
               (levelGradient == const LinearGradient(colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)], begin: Alignment.topLeft, end: Alignment.bottomRight)) ? '3' : '4'}',
        style: TextStyle(
          fontSize: 200,
          fontWeight: FontWeight.w900,
          color: Colors.white.withOpacity(0.03),
        ),
      ),
      textAlign: TextAlign.center,
    )..layout();
    
    levelText.paint(
      canvas,
      Offset(
        centerX - levelText.width / 2,
        centerY - levelText.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) => true;
}
