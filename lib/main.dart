import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override Widget build(BuildContext context) {
    return const MaterialApp(debugShowCheckedModeBanner: false, home: MainMenu());
  }
}

class Skin {
  String name; Color color; int price; bool owned;
  Skin(this.name, this.color, this.price, {this.owned = false});
}

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});
  @override State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  int coins = 500, high = 0, selSkin = 0;
  List<Skin> skins = [
    Skin('الأصفر الأصلي', Colors.amber, 0, owned: true),
    Skin('أحمر عنتيل', Colors.red, 1000),
    Skin('أزرق ساحل', Colors.cyan, 2500),
    Skin('أسود ملكي', Colors.black87, 5000),
  ];

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    var p = await SharedPreferences.getInstance();
    setState(() {
      coins = p.getInt('coins')?? 500;
      high = p.getInt('high')?? 0;
      for (int i = 0; i < skins.length; i++) {
        skins[i].owned = p.getBool('own_$i')?? (i == 0);
      }
    });
  }
  Future<void> _save() async {
    var p = await SharedPreferences.getInstance();
    p.setInt('coins', coins); p.setInt('high', high);
    for (int i = 0; i < skins.length; i++) p.setBool('own_$i', skins[i].owned);
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF9800),
      body: SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _chip('💰 $coins'), _chip('🏆 $high')
        ]),
        const Spacer(),
        const Text('🛺', style: TextStyle(fontSize: 80)),
        const Text('سواق التوكتوك 3D', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 20),
       ...skins.asMap().entries.map((e) {
          var s = e.value; bool sel = e.key == selSkin;
          return Container(margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: sel? Colors.white : Colors.white70, borderRadius: BorderRadius.circular(12), border: sel? Border.all(width: 3) : null),
            child: ListTile(leading: Container(width: 30, height: 20, color: s.color), title: Text(s.name), trailing: ElevatedButton(onPressed: () {
              if (s.owned) { setState(() => selSkin = e.key); }
              else if (coins >= s.price) { setState(() { coins -= s.price; s.owned = true; selSkin = e.key; }); _save(); }
            }, child: Text(s.owned? (sel? 'راكب' : 'ركب') : 'اشتري ${s.price}'))));
        }),
        const Spacer(),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => Game3D(skin: skins[selSkin], onFinish: (sc, earn) { setState(() { coins += earn; if (sc > high) high = sc; }); _save(); })));
        }, style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text('يلا بينا 🛺💨', style: TextStyle(fontSize: 24, color: Colors.white)))),
      ]))),
    );
  }
  Widget _chip(String t) => Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)), child: Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)));
}

class GameObj { double x, y; String type; GameObj(this.x, this.y, this.type); }

class Game3D extends StatefulWidget {
  final Skin skin; final Function(int, int) onFinish;
  const Game3D({super.key, required this.skin, required this.onFinish});
  @override State<Game3D> createState() => _Game3DState();
}

class _Game3DState extends State<Game3D> {
  double toktokX = 0.0; // -1 to 1
  double speed = 2.0; // أبطأ بكتير
  double roadOffset = 0;
  int score = 0, lives = 3, coinsEarned = 0;
  double fuel = 100;
  List<GameObj> objs = [];
  Timer? loop;
  Random rnd = Random();

  @override void initState() {
    super.initState();
    loop = Timer.periodic(const Duration(milliseconds: 30), (t) {
      if (!mounted) return;
      setState(() {
        roadOffset += speed;
        if (roadOffset > 40) roadOffset = 0;
        fuel -= 0.02; // بنزين أبطأ
        if (fuel <= 0) { _gameOver('البنزين خلص'); return; }

        // حركة العوائق بمنظور 3D
        for (var o in objs) { o.y += speed * 0.08; }
        objs.removeWhere((o) => o.y > 1.2);

        if (rnd.nextDouble() < 0.03) {
          var types = ['car', 'car', 'hole', 'fuel', 'money', 'cust'];
          objs.add(GameObj((rnd.nextDouble() * 2 - 1) * 0.7, -0.2, types[rnd.nextInt(types.length)]));
        }

        for (var o in List.from(objs)) {
          if (o.y > 0.6 && o.y < 0.9 && (o.x - toktokX).abs() < 0.18) {
            if (o.type == 'fuel') { fuel = min(100, fuel + 30); }
            else if (o.type == 'money') { score += 30; coinsEarned += 20; }
            else if (o.type == 'cust') { score += 50; coinsEarned += 30; }
            else { lives--; if (lives <= 0) { _gameOver('خبطت!'); return; } }
            objs.remove(o);
          }
        }
        score += 1;
        if (score % 500 == 0 && speed < 5) speed += 0.2;
      });
    });
  }

  void _gameOver(String r) {
    loop?.cancel();
    widget.onFinish(score, coinsEarned);
    showDialog(barrierDismissible: false, context: context, builder: (c) => AlertDialog(title: Text(r), content: Text('مسافة: $score\nكسبت: $coinsEarned 🪙'), actions: [ElevatedButton(onPressed: () { Navigator.pop(c); Navigator.pop(context); }, child: const Text('تمام'))]));
  }

  @override void dispose() { loop?.cancel(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return Scaffold(body: GestureDetector(
      onHorizontalDragUpdate: (d) {
        setState(() {
          toktokX += d.delta.dx * 0.008; // تحكم ناعم زي دريكسيون
          toktokX = toktokX.clamp(-0.85, 0.85);
        });
      },
      child: Stack(children: [
        // سماء
        Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF81D4FA), Color(0xFFB0BEC5)]))),
        // شارع 3D بمنظور
        CustomPaint(size: Size.infinite, painter: Road3DPainter(offset: roadOffset)),

        // العوائق بمنظور
       ...objs.map((o) {
          double scale = (o.y + 0.3).clamp(0.2, 1.2);
          double px = MediaQuery.of(context).size.width * 0.5 + o.x * MediaQuery.of(context).size.width * 0.4 * (o.y + 0.5);
          double py = MediaQuery.of(context).size.height * o.y;
          String emoji = '🚗';
          if (o.type == 'hole') emoji = '🕳️'; if (o.type == 'fuel') emoji = '⛽'; if (o.type == 'money') emoji = '💰'; if (o.type == 'cust') emoji = '🧍';
          return Positioned(left: px - 20 * scale, top: py, child: Transform.scale(scale: scale, child: Text(emoji, style: TextStyle(fontSize: 30 * scale))));
        }),

        // التوكتوك الحقيقي
        Positioned(
          left: MediaQuery.of(context).size.width * 0.5 + toktokX * MediaQuery.of(context).size.width * 0.35 - 35,
          bottom: 120,
          child: CustomPaint(size: const Size(70, 90), painter: ToktokPainter(color: widget.skin.color)),
        ),

        // HUD
        Positioned(top: 40, left: 10, right: 10, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)), child: Text('💰 $score | 🪙 $coinsEarned', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)), child: Column(children: [Text('❤️' * lives), Text('⛽ ${fuel.toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 11))])),
        ])),
        Positioned(bottom: 30, left: 0, right: 0, child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(20)), child: const Text('اسحب يمين وشمال للتحكم 👉👈', style: TextStyle(fontSize: 12))))),
      ]),
    ));
  }
}

class Road3DPainter extends CustomPainter {
  double offset; Road3DPainter({required this.offset});
  @override void paint(Canvas canvas, Size size) {
    var paintRoad = Paint()..color = const Color(0xFF212121);
    var paintSide = Paint()..color = const Color(0xFF9E9E9E);

    // جوانب الطريق
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paintSide);

    // الطريق بمنظور
    Path roadPath = Path();
    roadPath.moveTo(size.width * 0.5 - 30, 0);
    roadPath.lineTo(size.width * 0.5 + 30, 0);
    roadPath.lineTo(size.width * 0.95, size.height);
    roadPath.lineTo(size.width * 0.05, size.height);
    roadPath.close();
    canvas.drawPath(roadPath, paintRoad);

    // خطوط جانبية
    var white = Paint()..color = Colors.white..strokeWidth = 4..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(size.width * 0.5 - 28, 0), Offset(size.width * 0.07, size.height), white);
    canvas.drawLine(Offset(size.width * 0.5 + 28, 0), Offset(size.width * 0.93, size.height), white);

    // خط نص متقطع بمنظور
    var dashPaint = Paint()..color = Colors.white..strokeWidth = 3;
    for (double y = -40 + offset; y < size.height; y += 40) {
      double t = y / size.height;
      double x = size.width * 0.5;
      double w = 20 * t + 5;
      canvas.drawRect(Rect.fromCenter(center: Offset(x, y), width: w, height: 15 * t + 5), dashPaint);
    }
  }
  @override bool shouldRepaint(covariant Road3DPainter old) => old.offset!= offset;
}

class ToktokPainter extends CustomPainter {
  Color color; ToktokPainter({required this.color});
  @override void paint(Canvas c, Size s) {
    var body = Paint()..color = color;
    var black = Paint()..color = Colors.black87;
    var glass = Paint()..color = const Color(0xFF81D4FA);

    // جسم التوكتوك
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(5, 20, s.width - 10, 45), const Radius.circular(8)), body);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(8, 10, s.width - 16, 25), const Radius.circular(6)), black);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(10, 12, s.width - 20, 18), const Radius.circular(4)), glass);
    // عجلات
    c.drawCircle(Offset(15, 70), 10, black);
    c.drawCircle(Offset(s.width - 15, 70), 10, black);
    c.drawCircle(Offset(15, 70), 5, Paint()..color = Colors.grey);
    c.drawCircle(Offset(s.width - 15, 70), 5, Paint()..color = Colors.grey);
    // فانوس
    c.drawCircle(Offset(s.width/2, 35), 5, Paint()..color = Colors.yellowAccent);
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}
