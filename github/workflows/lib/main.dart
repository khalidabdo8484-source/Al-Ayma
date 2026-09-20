import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(const AymaApp());

class AymaApp extends StatelessWidget {
  const AymaApp({super.key});
  @override Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'القايمة',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFFC9A86A)),
      home: const AymaPage(),
    );
  }
}

class Item { String name; String cat; double price; int qty; Item(this.name,this.cat,this.price,this.qty); Map toJson()=>{'n':name,'c':cat,'p':price,'q':qty}; static Item fromJson(m)=>Item(m['n'],m['c'],(m['p'] as num).toDouble(),m['q']); }

class AymaPage extends StatefulWidget {
  const AymaPage({super.key});
  @override State<AymaPage> createState()=> _AymaPageState();
}

class _AymaPageState extends State<AymaPage> {
  final brideC=TextEditingController(); final groomC=TextEditingController(); final goldC=TextEditingController(text:'0'); final moakharC=TextEditingController(text:'0');
  List<Item> items=[]; String filter='الكل';
  final cats=['الكل','أوضة النوم','المطبخ','النيش','الأجهزة','الدهب','المفروشات','أخرى'];
  final nameC=TextEditingController(); final priceC=TextEditingController(); final qtyC=TextEditingController(text:'1'); String selCat='أوضة النوم';

  @override void initState(){super.initState(); load();}
  Future<void> load() async { final p=await SharedPreferences.getInstance(); setState((){ brideC.text=p.getString('bride')??''; groomC.text=p.getString('groom')??''; goldC.text=p.getString('gold')??'0'; moakharC.text=p.getString('moakhar')??'0'; final s=p.getString('items'); if(s!=null) items=(jsonDecode(s) as List).map((e)=>Item.fromJson(e)).toList(); }); }
  Future<void> save() async { final p=await SharedPreferences.getInstance(); await p.setString('bride', brideC.text); await p.setString('groom', groomC.text); await p.setString('gold', goldC.text); await p.setString('moakhar', moakharC.text); await p.setString('items', jsonEncode(items.map((e)=>e.toJson()).toList())); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ ✅'))); setState((){}); }

  double get total => items.fold(0,(a,b)=>a+b.price*b.qty) + (double.tryParse(goldC.text)??0) + (double.tryParse(moakharC.text)??0);
  double get itemsTotal => items.fold(0,(a,b)=>a+b.price*b.qty);

  void addItem(){ if(nameC.text.isEmpty) return; final pr=double.tryParse(priceC.text)??0; final q=int.tryParse(qtyC.text)??1; setState(()=>items.add(Item(nameC.text,selCat,pr,q))); nameC.clear(); priceC.clear(); qtyC.text='1'; save(); Navigator.pop(context); }
  void showAdd(){ showDialog(context: context, builder: (c)=>AlertDialog(title: const Text('إضافة حاجة للقايمة'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: nameC, decoration: const InputDecoration(labelText:'اسم الحاجة مثلا: ثلاجة توشيبا')), DropdownButtonFormField(value: selCat, items: cats.where((e)=>e!='الكل').map((e)=>DropdownMenuItem(value:e, child:Text(e))).toList(), onChanged:(v)=>setState(()=>selCat=v!)), TextField(controller: priceC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'السعر')), TextField(controller: qtyC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'العدد'))])), actions: [TextButton(onPressed:()=>Navigator.pop(context), child: const Text('إلغاء')), ElevatedButton(onPressed: addItem, child: const Text('إضافة'))])); }

  Future<void> makePdf() async {
    final doc=pw.Document();
    doc.addPage(pw.Page(build: (cc)=>pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children:[
      pw.Center(child: pw.Text('قائمة منقولات زوجية', style: pw.TextStyle(fontSize:22, fontWeight:pw.FontWeight.bold))),
      pw.SizedBox(height:8),
      pw.Text('العريس: ${groomC.text} - العروسة: ${brideC.text} - التاريخ: ${DateTime.now().toString().split(' ')[0]}'),
      pw.Divider(),
      pw.Table.fromTextArray(headers:['م','الصنف','العدد','السعر','الإجمالي'], data: [for(int i=0;i<items.length;i++) ['${i+1}', items[i].name, '${items[i].qty}', '${items[i].price}', '${items[i].price*items[i].qty}']]),
      pw.SizedBox(height:10),
      pw.Text('إجمالي المنقولات: $itemsTotal جنيه'),
      pw.Text('قيمة الدهب: ${goldC.text} جنيه'),
      pw.Text('المؤخر: ${moakharC.text} جنيه'),
      pw.Divider(),
      pw.Text('الإجمالي الكلي للقايمة: $total جنيه', style: pw.TextStyle(fontWeight:pw.FontWeight.bold)),
      pw.SizedBox(height:30),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children:[pw.Column(children:[pw.Text('توقيع الزوج'), pw.SizedBox(height:20), pw.Text('........................')]), pw.Column(children:[pw.Text('توقيع الزوجة'), pw.SizedBox(height:20), pw.Text('........................')]), pw.Column(children:[pw.Text('الشاهد'), pw.SizedBox(height:20), pw.Text('........................')])]),
    ])));
    await Printing.sharePdf(bytes: await doc.save(), filename: 'qayma.pdf');
  }

  @override Widget build(BuildContext context) {
    final filtered = filter=='الكل'? items : items.where((e)=>e.cat==filter).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('القايمة'), backgroundColor: const Color(0xFF8B5A2B), foregroundColor: Colors.white, centerTitle: true, actions: [IconButton(onPressed: makePdf, icon: const Icon(Icons.picture_as_pdf))]),
      floatingActionButton: FloatingActionButton.extended(onPressed: showAdd, backgroundColor: const Color(0xFF8B5A2B), icon: const Icon(Icons.add, color: Colors.white), label: const Text('إضافة', style: TextStyle(color: Colors.white))),
      body: ListView(padding: const EdgeInsets.all(12), children:[
        Row(children:[Expanded(child: TextField(controller: groomC, onChanged:(_)=>save(), decoration: const InputDecoration(labelText:'اسم العريس', border: OutlineInputBorder()))), const SizedBox(width:8), Expanded(child: TextField(controller: brideC, onChanged:(_)=>save(), decoration: const InputDecoration(labelText:'اسم العروسة', border: OutlineInputBorder())))]),
        const SizedBox(height:8),
        Row(children:[Expanded(child: TextField(controller: goldC, keyboardType: TextInputType.number, onChanged:(_)=>save(), decoration: const InputDecoration(labelText:'قيمة الدهب', border: OutlineInputBorder()))), const SizedBox(width:8), Expanded(child: TextField(controller: moakharC, keyboardType: TextInputType.number, onChanged:(_)=>save(), decoration: const InputDecoration(labelText:'المؤخر', border: OutlineInputBorder())))]),
        const SizedBox(height:10),
        SizedBox(height:40, child: ListView(scrollDirection: Axis.horizontal, children: cats.map((c)=>Padding(padding: const EdgeInsets.only(right:6), child: ChoiceChip(label: Text(c), selected: filter==c, onSelected:(_)=>setState(()=>filter=c)))).toList())),
        const SizedBox(height:8),
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF8B5A2B).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Column(children:[Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[const Text('إجمالي العفش:'), Text('$itemsTotal ج', style: const TextStyle(fontWeight: FontWeight.bold))]), const Divider(), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[const Text('الإجمالي الكلي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize:16)), Text('$total ج', style: const TextStyle(fontWeight: FontWeight.bold, fontSize:18, color: Color(0xFF8B5A2B)))])])),
        const SizedBox(height:10),
       ...filtered.asMap().entries.map((e)=>Card(child: ListTile(title: Text(e.value.name), subtitle: Text('${e.value.cat} - ${e.value.price} x ${e.value.qty}'), trailing: Row(mainAxisSize: MainAxisSize.min, children:[Text('${e.value.price*e.value.qty}', style: const TextStyle(fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed:(){ setState(()=>items.removeAt(items.indexOf(e.value))); save(); })])))),
        if(filtered.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('لسه مضفتش حاجة - دوس إضافة'))),
        const SizedBox(height:80),
      ]),
    );
  }
}
