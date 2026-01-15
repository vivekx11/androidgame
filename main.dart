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
        scaffoldBackgroundColor: Colors.blueGrey.shade900,
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
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.yellow,
    Colors.cyan,
    Colors.pink,
    Colors.amber,
    Colors.teal,
    Colors.lime,
    Colors.indigo,
    Colors.deepOrange,
    Colors.deepPurple,
    Colors.lightBlue,
    Colors.lightGreen,
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

      // Clamp left/right walls
      if (ballX <= -containerWidth / 2 + 12 ||
          ballX >= containerWidth / 2 - 12) {
        ballSpeedX *= -1;
      }

      // Clamp top wall (fix ball escape)
      double topLimit = -containerHeight / 2 + 12;
      if (ballY <= topLimit) {
        ballY = topLimit;
        ballSpeedY *= -1;
      }

      // Paddle bounce
      if (ballY >= containerHeight / 2 - 30 &&
          (ballX > paddleX - paddleWidth / 2) &&
          (ballX < paddleX + paddleWidth / 2)) {
        ballSpeedY *= -1;
        ballSpeedX += (ballX - paddleX) * 0.05;
      }

      // Box collision
      boxes.removeWhere((box) {
        if ((ballX - box.position.dx).abs() < 30 &&
            (ballY - box.position.dy).abs() < 30) {
          score += 10;
          ballSpeedY *= -1;
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
    super.dispose();
  }

  Widget buildAppBarUI(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      child: Material(
        color: Colors.transparent,
        elevation: 10,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent.withOpacity(0.21), Colors.white12],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.10),
                blurRadius: 12,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              topLabel(Icons.rocket_launch, "Level", "$level"),
              topLabel(Icons.star, "Score", "$score"),
              if (isStarted && !isGameOver) buildAnimatedPauseButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget topLabel(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, color: Colors.amber, size: 27),
      const SizedBox(width: 6),
      Text(
        "$label: ",
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 18,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
      Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 21,
          color: Colors.white,
        ),
      ),
    ],
  );

  Widget buildAnimatedPauseButton() => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(17),
    child: InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: pauseOrResumeGame,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.09),
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.16),
              blurRadius: 11,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.all(6),
        child: AnimatedIcon(
          icon: AnimatedIcons.play_pause,
          progress: playPauseController,
          color: Colors.amber,
          size: 34,
        ),
      ),
    ),
  );

  Widget buildGameArea() {
    return Center(
      child: Container(
        width: containerWidth,
        height: containerHeight,
        padding: EdgeInsets.zero, // explicitly zero padding here
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: Colors.blueAccent, width: 7),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isStarted)
              CustomPaint(painter: GamePainter(paddleX, ballX, ballY, boxes)),
            if (!isStarted) Center(child: buildStartButton()),
            if (isGameOver) buildGameOverOverlay(),
          ],
        ),
      ),
    );
  }

  Widget buildStartButton() => ElevatedButton.icon(
    onPressed: startGame,
    icon: const Icon(Icons.play_arrow, size: 29),
    label: const Text(
      "Start Game",
      style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 18,
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
    ),
  );

  Widget buildGameOverOverlay() => AnimatedBuilder(
    animation: fadeIn,
    builder: (context, child) => Opacity(
      opacity: fadeIn.value,
      child: Container(
        color: Colors.black87.withOpacity(0.78),
        child: Center(
          child: Material(
            elevation: 14,
            borderRadius: BorderRadius.circular(29),
            child: Container(
              width: 330,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurpleAccent.withOpacity(0.9),
                    Colors.blue.shade900.withOpacity(0.82),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(29),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurpleAccent.withOpacity(0.22),
                    blurRadius: 18,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Game Over 💀",
                    style: TextStyle(
                      fontSize: 39,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 19),
                  Icon(
                    Icons.sentiment_very_dissatisfied,
                    color: Colors.red,
                    size: 57,
                  ),
                  const SizedBox(height: 19),
                  Text(
                    "Score: $score",
                    style: const TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 21),
                  ElevatedButton.icon(
                    onPressed: restartGame,
                    icon: const Icon(Icons.replay, size: 23),
                    label: const Text(
                      "Restart",
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 10,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 44,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
              buildAppBarUI(context),
              Expanded(child: buildGameArea()),
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

class GamePainter extends CustomPainter {
  final double paddleX;
  final double ballX, ballY;
  final List<Box> boxes;
  GamePainter(this.paddleX, this.ballX, this.ballY, this.boxes);

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final Paint paddlePaint = Paint()
      ..shader =
          LinearGradient(
            colors: [Colors.green, Colors.teal, Colors.green.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(
            Rect.fromCenter(
              center: Offset(centerX + paddleX, centerY + 270),
              width: 100,
              height: 20,
            ),
          );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX + paddleX, centerY + 270),
          width: 100,
          height: 20,
        ),
        const Radius.circular(14),
      ),
      paddlePaint,
    );

    final Paint ballPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.white,
              Colors.blue.shade200,
              Colors.white,
              Colors.blue.shade500.withOpacity(0.7),
            ],
            center: Alignment.center,
            radius: 0.6,
          ).createShader(
            Rect.fromCircle(
              center: Offset(centerX + ballX, centerY + ballY),
              radius: 19,
            ),
          );
    canvas.drawCircle(Offset(centerX + ballX, centerY + ballY), 13, ballPaint);

    for (final box in boxes) {
      final Paint boxPaint = Paint()..color = box.color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(
              centerX + box.position.dx,
              centerY + box.position.dy,
            ),
            width: 50,
            height: 50,
          ),
          const Radius.circular(10),
        ),
        boxPaint,
      );
      final Paint shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(
              centerX + box.position.dx,
              centerY + box.position.dy + 3,
            ),
            width: 50,
            height: 50,
          ),
          const Radius.circular(10),
        ),
        shadowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
