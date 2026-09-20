import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main()=>runApp(const MyApp());
class MyApp extends StatelessWidget{const MyApp({super.key}); @override Widget build(BuildContext c)=>MaterialApp(debugShowCheckedModeBanner:false, theme:ThemeData(useMaterial3:true, fontFamily:'Cairo'), home:const MainMenu());}

class Skin{String name, emoji; Color color; double speed; int price; bool owned; Skin(this.name,this.emoji,this.color,this.speed,this.price,{this.owned=false});}
class LevelData{String name, emoji, desc; Color street, building; double traffic; LevelData(this.name,this.emoji,this.desc,this.street,this.building,this.traffic);}

class MainMenu extends StatefulWidget{const MainMenu({super.key}); @override State<MainMenu> createState()=>_MainMenuState();}
class _MainMenuState extends State<MainMenu>{
  int coins=500, high=0; int selSkin=0, selLevel=0;
  List<Skin> skins=[Skin('العادي','🛺',Colors.yellow,1.0,0,owned:true),Skin('عنتيل','🛺',Colors.red,1.2,1500),Skin('الفنان','🛺',Colors.purple,1.4,4000),Skin('الطيارة','🚀',Colors.cyan,1.7,9000),Skin('الملكي','👑',Colors.amber,1.3,6000)];
  List<LevelData> levels=[LevelData('الحارة','🏘️','عيال بتلعب كورة','سهلة',const Color(0xFF8D6E63),const Color(0xFFD7CCC8),0.02),LevelData('وسط البلد','🏙️','زحمة وتكاتك','متوسطة',const Color(0xFF424242),const Color(0xFF9E9E9E),0.04),LevelData('الدائري','🛣️','نقل تقيل بيجري','صعبة',const Color(0xFF212121),const Color(0xFF616161),0.06),LevelData('الساحل','🏖️','وصلت يا كينج','جحيم',const Color(0xFF4FC3F7),const Color(0xFFFFE082),0.08)];
  List<String> mehraganat=['بنت الجيران','مهرجان العب يلا','مهرجان عود البطل','انتي معلمة','حبي يا ليل','مهرجان اخواتي'];

  @override void initState(){super.initState(); _load();}
  _load() async{var p=await SharedPreferences.getInstance(); setState((){coins=p.getInt('coins')??500; high=p.getInt('tok_high')??0; selSkin=p.getInt('skin')??0; for(int i=0;i<skins.length;i++){skins[i].owned=p.getBool('own_$i')?? (i==0);}});}
  _save() async{var p=await SharedPreferences.getInstance(); p.setInt('coins',coins); p.setInt('tok_high',high); p.setInt('skin',selSkin); for(int i=0;i<skins.length;i++) p.setBool('own_$i',skins[i].owned);}

  @override Widget build(BuildContext c){
    return Scaffold(body: Container(decoration:const BoxDecoration(gradient:LinearGradient(colors:[Color(0xFFFF9800),Color(0xFFFF5722)])), child: SafeArea(child: Column(children:[
      const SizedBox(height:10),
      Row(mainAxisAlignment:MainAxisAlignment.spaceAround, children:[_chip('💰 $coins'), _chip('🏆 $high'), _chip('⛽ ∞')]),
      const SizedBox(height:10),
      const Text('🛺 سواق التوكتوك 🛺', style:TextStyle(fontSize:30,fontWeight:FontWeight.w900,color:Colors.white)),
      const Text('Cairo TukTuk - Full Edition', style:TextStyle(color:Colors.white70)),
      Expanded(child: ListView(padding:const EdgeInsets.all(16), children:[
        _section('🗺️ اختار الخريطة'), SizedBox(height:100, child: ListView.builder(scrollDirection:Axis.horizontal, itemCount:levels.length, itemBuilder:(c,i){var lv=levels[i]; bool sel=i==selLevel; return GestureDetector(onTap:()=>setState(()=>selLevel=i), child: Container(width:140,margin:const EdgeInsets.only(right:10),padding:const EdgeInsets.all(10), decoration:BoxDecoration(color:sel?Colors.white:Colors.white70, borderRadius:BorderRadius.circular(15), border:sel?Border.all(color:Colors.black,width:3):null), child:Column(children:[Text(lv.emoji,style:const TextStyle(fontSize:32)), Text(lv.name,style:const TextStyle(fontWeight:FontWeight.bold)), Text(lv.desc,style:const TextStyle(fontSize:10)), Text(lv.traffic.toString(),style:TextStyle(color:lv.street))])));})),

        _section('🔧 الجراج - اختار التوكتوك'),...skins.asMap().entries.map((e){int idx=e.key; var s=e.value; bool sel=idx==selSkin; return Card(color:sel?Colors.yellow[100]:Colors.white, child: ListTile(leading:Text(s.emoji,style:const TextStyle(fontSize:30)), title:Text('${s.name} - سرعة x${s.speed}'), subtitle:Text(s.owned?'مملوك':'السعر: ${s.price} جنيه'), trailing: sel?const Icon(Icons.check_circle,color:Colors.green):ElevatedButton(onPressed:(){if(s.owned){setState(()=>selSkin=idx);_save();} else if(coins>=s.price){setState((){coins-=s.price; s.owned=true; selSkin=idx;});_save();}}, child:Text(s.owned?'ركب':'اشتري')),));}),

        _section('📻 راديو المهرجانات'), Container(padding:const EdgeInsets.all(10), decoration:BoxDecoration(color:Colors.black,borderRadius:BorderRadius.circular(10)), child: Row(children:[const Icon(Icons.music_note,color:Colors.yellow), const SizedBox(width:8), Expanded(child: Text('شغال دلوقتي: ${mehraganat[Random().nextInt(mehraganat.length)]} 🎶',style:const TextStyle(color:Colors.white))), const Icon(Icons.graphic_eq,color:Colors.green)])),

        const SizedBox(height:20),
        ElevatedButton(onPressed:(){Navigator.push(c, MaterialPageRoute(builder:(_)=>GameScreen(skin:skins[selSkin], level:levels[selLevel], levelIndex:selLevel, onFinish:(sc,earned){setState((){coins+=earned; if(sc>high) high=sc;}); _save();})));}, style:ElevatedButton.styleFrom(backgroundColor:Colors.black, padding:const EdgeInsets.symmetric(vertical:18), shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(15))), child:const Text('يلا نطلع مصلحة 🛺💨', style:TextStyle(fontSize:22,color:Colors.white,fontWeight:FontWeight.bold))),
        const SizedBox(height:10),
        const Text('نصيحة: لم الزباين المستعجلين (ذهبي) بيدفعو الضعف، اهرب من البوليس، وفول بنزين كل شوية!', textAlign:TextAlign.center, style:TextStyle(color:Colors.white, fontSize:12)),
      ])),
    ])))));
  }
  Widget _chip(String t)=>Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:6), decoration:BoxDecoration(color:Colors.black87,borderRadius:BorderRadius.circular(20)), child:Text(t,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold)));
  Widget _section(String t)=>Padding(padding:const EdgeInsets.only(top:16,bottom:8), child:Text(t,style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:Colors.white)));
}

// ===== لعبة القيادة الكاملة =====
class GameObj{double x,y; String type; double speed; GameObj(this.x,this.y,this.type,this.speed);}

class GameScreen extends StatefulWidget{final Skin skin; final LevelData level; final int levelIndex; final Function(int,int) onFinish; const GameScreen({super.key, required this.skin, required this.level, required this.levelIndex, required this.onFinish}); @override State<GameScreen> createState()=>_GameScreenState();}
class _GameScreenState extends State<GameScreen>{
  double toktokX=0.5, fuel=100; int score=0, lives=3, coinsEarned=0; double gameSpeed=4; bool left=false,right=false; List<GameObj> objs=[]; Timer? loop; Random rnd=Random(); String radio='مهرجان العب يلا'; int radioTimer=0;

  @override void initState(){super.initState(); _start();}
  void _start(){
    loop=Timer.periodic(const Duration(milliseconds:16),(_){
      if(!mounted) return;
      setState((){
        if(left && toktokX>0.08) toktokX-=0.018*widget.skin.speed;
        if(right && toktokX<0.92) toktokX+=0.018*widget.skin.speed;
        fuel-=0.04; if(fuel<=0){_over('البنزين خلص!'); return;}
        for(var o in objs) o.y+=o.speed;
        objs.removeWhere((o)=>o.y>110);
        if(rnd.nextDouble()<widget.level.traffic){
          var types=['cust_normal','cust_vip','fuel','money','pothole','police','car','bus']; var w=[35,10,8,12,20,8,15,5]; // weights
          int r=rnd.nextInt(100); String t='cust_normal'; int acc=0; for(int i=0;i<w.length;i++){acc+=w[i]; if(r<acc){t=types[i]; break;}}
          double sp=gameSpeed + (t=='bus'||t=='car'? rnd.nextDouble()*2 : 0);
          objs.add(GameObj(rnd.nextDouble()*0.8+0.1, -10, t, sp));
        }
        // تصادم
        for(var o in List.from(objs)){
          if((o.x-toktokX).abs()<0.13 && (o.y-85).abs()<8){
            switch(o.type){
              case 'cust_normal': score+=20; coinsEarned+=10; objs.remove(o); break;
              case 'cust_vip': score+=50; coinsEarned+=30; objs.remove(o); break;
              case 'money': score+=30; coinsEarned+=25; objs.remove(o); break;
              case 'fuel': fuel=min(100,fuel+35); objs.remove(o); break;
              default: lives--; objs.remove(o); if(lives<=0) _over('البوليس مسكك!'); break;
            }
          }
        }
        score++; radioTimer++; if(radioTimer>400){radio=['مهرجان عود البطل','انتي معلمة','حبيبي يا ليل','قلبك بحر مالح','بنت الجيران'][rnd.nextInt(5)]; radioTimer=0;}
        if(score%600==0) gameSpeed+=0.4;
      });
    });
  }
  void _over(String reason){loop?.cancel(); widget.onFinish(score,coinsEarned); showDialog(barrierDismissible:false, context:context, builder:(c)=>AlertDialog(title:Text(reason), content: Column(mainAxisSize:MainAxisSize.min, children:[Text('المسافة: $score'), Text('كسبت: $coinsEarned جنيه'), Text('البنزين: ${fuel.toStringAsFixed(0)}%')]), actions:[ElevatedButton(onPressed:(){Navigator.pop(c); Navigator.pop(context);}, child:const Text('ارجع الجراج'))]));}
  @override void dispose(){loop?.cancel(); super.dispose();}

  Widget _obj(GameObj o){
    String e='❓'; Color co=Colors.white; double sz=30;
    switch(o.type){
      case 'cust_normal': e='🧍'; co=Colors.green; break;
      case 'cust_vip': e='🤴'; co=Colors.amber; sz=38; break;
      case 'fuel': e='⛽'; co=Colors.red; break;
      case 'money': e='💰'; break;
      case 'pothole': e='🕳️'; break;
      case 'police': e='🚓'; sz=40; break;
      case 'car': e='🚗'; sz=42; break;
      case 'bus': e='🚌'; sz=50; break;
    }
    return Positioned(left: MediaQuery.of(context).size.width*o.x-20, top: MediaQuery.of(context).size.height*o.y/100, child:Text(e,style:TextStyle(fontSize:sz, shadows:[Shadow(color:co, blurRadius:10)])));
  }

  @override Widget build(BuildContext context){
    var w=MediaQuery.of(context).size.width;
    return Scaffold(body: Stack(children:[
      Container(color:widget.level.building), // مباني
      Positioned.fill(child: CustomPaint(painter: RoadPainter(streetColor: widget.level.street))),
     ...objs.map(_obj),
      Positioned(left:w*toktokX-30, bottom:110, child: Column(children:[Container(padding:const EdgeInsets.all(4), decoration:BoxDecoration(color:widget.skin.color, borderRadius:BorderRadius.circular(8)), child:Text(widget.skin.emoji,style:const TextStyle(fontSize:48))), if(widget.skin.speed>1.4) const Text('💨',style:TextStyle(fontSize:20))])),
      // HUD
      Positioned(top:40, left:10, right:10, child: Column(children:[
        Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[
          Container(padding:const EdgeInsets.all(8), decoration:BoxDecoration(color:Colors.black87,borderRadius:BorderRadius.circular(12)), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text('📍 ${widget.level.name} ${widget.level.emoji}',style:const TextStyle(color:Colors.white,fontSize:12)), Text('💰 $score | 🪙 $coinsEarned',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),])),
          Container(padding:const EdgeInsets.all(8), decoration:BoxDecoration(color:Colors.black87,borderRadius:BorderRadius.circular(12)), child:Column(children:[Text('❤️'*lives), const SizedBox(height:4), Stack(children:[Container(width:80,height:8,decoration:BoxDecoration(color:Colors.grey,borderRadius:BorderRadius.circular(4))), Container(width:80*fuel/100,height:8,decoration:BoxDecoration(color:fuel>30?Colors.green:Colors.red,borderRadius:BorderRadius.circular(4)))]), Text('⛽ ${fuel.toStringAsFixed(0)}%',style:const TextStyle(color:Colors.white,fontSize:10))]))
        ]),
        const SizedBox(height:6),
        Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:4), decoration:BoxDecoration(color:Colors.black54,borderRadius:BorderRadius.circular(20)), child:Text('📻 $radio',style:const TextStyle(color:Colors.yellow,fontSize:11))),
      ])),
      // كنترول
      Positioned(left:0, bottom:0, top:0, width:w*0.5, child: GestureDetector(onTapDown:(_)=>left=true, onTapUp:(_)=>left=false, onTapCancel:()=>left=false)),
      Positioned(right:0, bottom:0, top:0, width:w*0.5, child: GestureDetector(onTapDown:(_)=>right=true, onTapUp:(_)=>right=false, onTapCancel:()=>right=false)),
      Positioned(bottom:15, left:20, child:Icon(Icons.arrow_back, color: left?Colors.white:Colors.white30, size:36)), Positioned(bottom:15, right:20, child:Icon(Icons.arrow_forward, color: right?Colors.white:Colors.white30, size:36)),
    ]));
  }
}

class RoadPainter extends CustomPainter{
  final Color streetColor; RoadPainter({required this.streetColor});
  @override void paint(Canvas c, Size s){
    var p=Paint()..color=streetColor;
    c.drawRect(Rect.fromLTWH(s.width*0.12,0,s.width*0.76,s.height),p);
    var line=Paint()..color=Colors.white..strokeWidth=3;
    for(double y=0;y<s.height;y+=40) c.drawLine(Offset(s.width*0.5,y), Offset(s.width*0.5,y+18),line);
    var side=Paint()..color=Colors.white..strokeWidth=4;
    c.drawLine(Offset(s.width*0.12,0), Offset(s.width*0.12,s.height),side);
    c.drawLine(Offset(s.width*0.88,0), Offset(s.width*0.88,s.height),side);
  }
  @override bool shouldRepaint(c)=>false;
}
