import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main()=>runApp(const MyApp());
class MyApp extends StatelessWidget{const MyApp({super.key}); @override Widget build(BuildContext c)=>MaterialApp(debugShowCheckedModeBanner:false, home:const MainMenu());}

class Skin{String name, emoji; Color color; double speed; int price; bool owned; Skin(this.name,this.emoji,this.color,this.speed,this.price,{this.owned=false});}
class LevelData{String name, emoji, desc; double traffic; Color color; LevelData(this.name,this.emoji,this.desc,this.traffic,this.color);}

class MainMenu extends StatefulWidget{const MainMenu({super.key}); @override State<MainMenu> createState()=>_MainMenuState();}
class _MainMenuState extends State<MainMenu>{
  int coins=500, high=0; int selSkin=0, selLevel=0;
  List<Skin> skins=[Skin('العادي','🛺',Colors.yellow,1.0,0,owned:true),Skin('عنتيل','🛺',Colors.red,1.2,1500),Skin('الفنان','🛺',Colors.purple,1.4,4000),Skin('الطيارة','🚀',Colors.cyan,1.7,9000),Skin('الملكي','👑',Colors.amber,1.3,6000)];
  List<LevelData> levels=[LevelData('الحارة','🏘️','سهلة',0.02,const Color(0xFF8D6E63)),LevelData('وسط البلد','🏙️','متوسطة',0.04,const Color(0xFF424242)),LevelData('الدائري','🛣️','صعبة',0.06,const Color(0xFF212121)),LevelData('الساحل','🏖️','جحيم',0.08,const Color(0xFF4FC3F7))];

  @override void initState(){super.initState(); _load();}
  _load() async{var p=await SharedPreferences.getInstance(); setState((){coins=p.getInt('coins')??500; high=p.getInt('tok_high')??0; selSkin=p.getInt('skin')??0; for(int i=0;i<skins.length;i++){skins[i].owned=p.getBool('own_$i')?? (i==0);}});}
  _save() async{var p=await SharedPreferences.getInstance(); p.setInt('coins',coins); p.setInt('tok_high',high); p.setInt('skin',selSkin); for(int i=0;i<skins.length;i++) p.setBool('own_$i',skins[i].owned);}

  @override Widget build(BuildContext c){
    return Scaffold(backgroundColor:const Color(0xFFFF9800), body: SafeArea(child: Column(children:[
      const SizedBox(height:10),
      Row(mainAxisAlignment:MainAxisAlignment.spaceAround, children:[_chip('💰 $coins'), _chip('🏆 $high')]),
      const SizedBox(height:10),
      const Text('🛺 سواق التوكتوك', style:TextStyle(fontSize:30,fontWeight:FontWeight.w900,color:Colors.white)),
      Expanded(child: ListView(padding:const EdgeInsets.all(16), children:[
        _section('🗺️ اختار الخريطة'), SizedBox(height:90, child: ListView.builder(scrollDirection:Axis.horizontal, itemCount:levels.length, itemBuilder:(c,i){var lv=levels[i]; bool sel=i==selLevel; return GestureDetector(onTap:()=>setState(()=>selLevel=i), child: Container(width:130,margin:const EdgeInsets.only(right:10),padding:const EdgeInsets.all(10), decoration:BoxDecoration(color:sel?Colors.white:Colors.white70, borderRadius:BorderRadius.circular(15), border:sel?Border.all(width:3):null), child:Column(children:[Text(lv.emoji,style:const TextStyle(fontSize:30)), Text(lv.name,style:const TextStyle(fontWeight:FontWeight.bold)), Text(lv.desc,style:const TextStyle(fontSize:11))])));})),

        _section('🔧 الجراج'),...skins.asMap().entries.map((e){int idx=e.key; var s=e.value; bool sel=idx==selSkin; return Card(color:sel?Colors.yellow[100]:Colors.white, child: ListTile(leading:Text(s.emoji,style:const TextStyle(fontSize:28)), title:Text('${s.name} x${s.speed}'), subtitle:Text(s.owned?'مملوك':'السعر ${s.price}'), trailing:ElevatedButton(onPressed:(){if(s.owned){setState(()=>selSkin=idx);_save();} else if(coins>=s.price){setState((){coins-=s.price; s.owned=true; selSkin=idx;});_save();}}, child:Text(s.owned?(sel?'راكب':'ركب'):'اشتري'))));}),

        const SizedBox(height:20),
        ElevatedButton(onPressed:(){Navigator.push(c, MaterialPageRoute(builder:(_)=>GameScreen(skin:skins[selSkin], level:levels[selLevel], onFinish:(sc,earned){setState((){coins+=earned; if(sc>high) high=sc;}); _save();})));}, style:ElevatedButton.styleFrom(backgroundColor:Colors.black, padding:const EdgeInsets.symmetric(vertical:18), shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(15))), child:const Text('يلا نطلع مصلحة 🛺💨', style:TextStyle(fontSize:22,color:Colors.white,fontWeight:FontWeight.bold))),
      ])),
    ]))));
  }
  Widget _chip(String t)=>Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:6), decoration:BoxDecoration(color:Colors.black87,borderRadius:BorderRadius.circular(20)), child:Text(t,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold)));
  Widget _section(String t)=>Padding(padding:const EdgeInsets.only(top:16,bottom:8), child:Text(t,style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:Colors.white)));
}

class GameObj{double x,y; String type; double speed; GameObj(this.x,this.y,this.type,this.speed);}

class GameScreen extends StatefulWidget{final Skin skin; final LevelData level; final Function(int,int) onFinish; const GameScreen({super.key, required this.skin, required this.level, required this.onFinish}); @override State<GameScreen> createState()=>_GameScreenState();}
class _GameScreenState extends State<GameScreen>{
  double toktokX=0.5, fuel=100; int score=0, lives=3, coinsEarned=0; double gameSpeed=4; bool left=false,right=false; List<GameObj> objs=[]; Timer? loop; Random rnd=Random();

  @override void initState(){super.initState(); loop=Timer.periodic(const Duration(milliseconds:18),( _){if(!mounted) return; setState((){
    if(left && toktokX>0.08) toktokX-=0.018*widget.skin.speed;
    if(right && toktokX<0.92) toktokX+=0.018*widget.skin.speed;
    fuel-=0.04; if(fuel<=0){_over('البنزين خلص!'); return;}
    for(var o in objs) o.y+=o.speed; objs.removeWhere((o)=>o.y>110);
    if(rnd.nextDouble()<widget.level.traffic){
