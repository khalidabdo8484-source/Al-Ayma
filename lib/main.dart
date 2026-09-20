import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MyApp());
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override Widget build(BuildContext c) => MaterialApp(debugShowCheckedModeBanner: false, theme: ThemeData(fontFamily: 'Cairo'), home: const TokTokGame());
}

class GameObj { double x, y; String type; GameObj(this.x, this.y, this.type); }

class TokTokGame extends StatefulWidget { const TokTokGame({super.key}); @override State<TokTokGame> createState() => _TokTokGameState(); }

class _TokTokGameState extends State<TokTokGame> {
  double toktokX = 0.5; // 0 to 1
  List<GameObj> objs = [];
  int score = 0, lives = 3, high = 0;
  double speed = 3.5;
  bool isPlaying = false, isLeft = false, isRight = false;
  Timer? gameLoop;
  Random rnd = Random();

  @override void initState() { super.initState(); _loadHigh(); }

  _loadHigh() async { var p = await SharedPreferences.getInstance(); setState(()=> high = p.getInt('tok_high') ?? 0); }

  void startGame() {
    setState(() { score = 0; lives = 3; objs = []; speed = 3.5; isPlaying = true; toktokX = 0.5; });
    gameLoop?.cancel();
    gameLoop = Timer.periodic(const Duration(milliseconds: 16), (t) {
      if (!isPlaying) return;
      setState(() {
        // حركة التوكتوك
        if (isLeft && toktokX > 0.05) toktokX -= 0.015;
        if (isRight && toktokX < 0.95) toktokX += 0.015;

        // نزول العوائق
        for (var o in objs) { o.y += speed; }
        objs.removeWhere((o) => o.y > 110);

        // اضافة حاجات جديدة
        if (rnd.nextDouble() < 0.04) {
          var type = ['customer','pothole','police','money'][rnd.nextInt(4)];
          if (type == 'customer' || type == 'money' || rnd.nextDouble() < 0.03) {
            objs.add(GameObj(rnd.nextDouble() * 0.8 + 0.1, -10, type));
          } else {
            objs.add(GameObj(rnd.nextDouble() * 0.8 + 0.1, -10, type));
          }
        }

        // تصادم
        for (var o in List.from(objs)) {
          if ((o.x - toktokX).abs() < 0.12 && (o.y - 85).abs() < 8) {
            if (o.type == 'customer') { score += 10; objs.remove(o); }
            else if (o.type == 'money') { score += 25; objs.remove(o); }
            else { lives--; objs.remove(o); if (lives <= 0) { gameOver(); } }
          }
        }

        score += 1; // عداد مسافة
        if (score % 500 == 0) speed += 0.3;
      });
    });
  }

  void gameOver() async {
    isPlaying = false;
    gameLoop?.cancel();
    if (score > high) {
      high = score;
      var p = await SharedPreferences.getInstance();
      p.setInt('tok_high', high);
    }
    setState(() {});
  }

  Widget _buildObj(GameObj o) {
    IconData icon; Color col; String label;
    switch (o.type) {
      case 'customer': icon = Icons.person; col = Colors.green; label = 'زبون'; break;
      case 'money': icon = Icons.attach_money; col = Colors.amber; label = 'فلوس'; break;
      case 'pothole': icon = Icons.warning; col = Colors.brown; label = 'مطب'; break;
      default: icon = Icons.local_police; col = Colors.blue; label = 'بوليس';
    }
    return Positioned(
      left: MediaQuery.of(context).size.width * o.x - 20,
      top: MediaQuery.of(context).size.height * o.y / 100,
      child: Column(children: [Icon(icon, color: col, size: 32), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))]),
    );
  }

  @override Widget build(BuildContext context) {
    var w = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF87CEEB), Color(0xFFFFE4B5)])),
        child: Stack(children: [
          // الشارع
          Positioned.fill(child: CustomPaint(painter: RoadPainter())),
          
          // الـ objects
          ...objs.map(_buildObj),

          // التوكتوك
          Positioned(
            left: w * toktokX - 35,
            bottom: 100,
            child: const Text('🛺', style: TextStyle(fontSize: 60)),
          ),

          // HUD فوق
          Positioned(top: 40, left: 10, right: 10, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)), child: Text('💰 $score  |  أعلى: $high', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)), child: Text('❤️ ' * lives, style: const TextStyle(color: Colors.white))),
          ])),

          // ازرار التحكم
          if (isPlaying) ...[
            Positioned(left: 0, bottom: 0, top: 0, width: w * 0.5, child: GestureDetector(onTapDown: (_) => isLeft = true, onTapUp: (_) => isLeft = false, onTapCancel: () => isLeft = false)),
            Positioned(right: 0, bottom: 0, top: 0, width: w * 0.5, child: GestureDetector(onTapDown: (_) => isRight = true, onTapUp: (_) => isRight = false, onTapCancel: () => isRight = false)),
            Positioned(bottom: 20, left: 20, child: Icon(Icons.arrow_back, color: Colors.white.withOpacity(0.5), size: 40)),
            Positioned(bottom: 20, right: 20, child: Icon(Icons.arrow_forward, color: Colors.white.withOpacity(0.5), size: 40)),
          ],

          // شاشة البداية / النهاية
          if (!isPlaying) Center(child: Container(padding: const EdgeInsets.all(24), margin: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]), child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🛺', style: TextStyle(fontSize: 80)),
            const Text('سواق التوكتوك', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF8B5A2B))),
            const SizedBox(height: 8),
            Text(lives <= 0 ? 'البوليس مسكك! 😭' : 'جاهز تلف القاهرة؟', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('السكور: $score', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('🟢 الزبون = +10\n💰 الفلوس = +25\n🟤 المطب = -قلب\n🔵 البوليس = -قلب\n\nدوس يمين وشمال على الشاشة عشان تتحرك', textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: startGame, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5A2B), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12)), child: Text(lives <= 0 ? 'العب تاني' : 'يلا بينا', style: const TextStyle(color: Colors.white, fontSize: 20))),
          ]))),
        ]),
      ),
    );
  }
}

class RoadPainter extends CustomPainter {
  @override void paint(Canvas c, Size s) {
    var paint = Paint()..color = const Color(0xFF4A4A4A);
    c.drawRect(Rect.fromLTWH(s.width * 0.1, 0, s.width * 0.8, s.height), paint);
    var dash = Paint()..color = Colors.white..strokeWidth = 3;
    for (double y = 0; y < s.height; y += 40) { c.drawLine(Offset(s.width * 0.5, y), Offset(s.width * 0.5, y + 20), dash); }
  }
  @override bool shouldRepaint(c) => false;
}
