import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primaryColor: const Color(0xFF8B5A2B), useMaterial3: true),
      home: const QaymaPage(),
    );
  }
}

class Item {
  String name, cat;
  double price;
  int qty;
  Item(this.name, this.cat, this.price, this.qty);
  Map toJson() => {'n': name, 'c': cat, 'p': price, 'q': qty};
  factory Item.fromJson(m) => Item(m['n'], m['c'], (m['p'] as num).toDouble(), m['q']);
}

class QaymaPage extends StatefulWidget {
  const QaymaPage({super.key});
  @override
  State<QaymaPage> createState() => _QaymaPageState();
}

class _QaymaPageState extends State<QaymaPage> {
  final bride = TextEditingController();
  final groom = TextEditingController();
  final gold = TextEditingController(text: '0');
  final moakhar = TextEditingController(text: '0');
  final nameC = TextEditingController();
  final priceC = TextEditingController();
  final qtyC = TextEditingController(text: '1');
  List<Item> items = [];
  String filter = 'الكل';
  String selCat = 'أوضة النوم';
  final cats = ['أوضة النوم', 'المطبخ', 'النيش', 'الأجهزة', 'الدهب', 'المفروشات', 'أخرى'];

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      setState(() {
        bride.text = p.getString('bride') ?? '';
        groom.text = p.getString('groom') ?? '';
        gold.text = p.getString('gold') ?? '0';
        moakhar.text = p.getString('moakhar') ?? '0';
        var s = p.getString('items');
        if (s != null) items = (jsonDecode(s) as List).map((e) => Item.fromJson(e)).toList();
      });
    });
  }

  save() async {
    var p = await SharedPreferences.getInstance();
    p.setString('bride', bride.text);
    p.setString('groom', groom.text);
    p.setString('gold', gold.text);
    p.setString('moakhar', moakhar.text);
    p.setString('items', jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  double get total => items.fold(0, (a, b) => a + b.price * b.qty) + (double.tryParse(gold.text) ?? 0) + (double.tryParse(moakhar.text) ?? 0);

  Future<void> makePdf() async {
    final doc = pw.Document();
    doc.addPage(pw.Page(build: (c) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Center(child: pw.Text('قائمة المنقولات الزوجية', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold))),
      pw.SizedBox(height: 10),
      pw.Text('العريس: ${groom.text}  -  العروسة: ${bride.text}'),
      pw.Text('الذهب: ${gold.text}  -  المؤخر: ${moakhar.text}'),
      pw.SizedBox(height: 10),
      pw.Table.fromTextArray(headers: ['الصنف', 'الفئة', 'العدد', 'السعر'], data: [for (var it in items) [it.name, it.cat, '${it.qty}', '${it.price}']]),
      pw.SizedBox(height: 10),
      pw.Text('الإجمالي: $total جنيه', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    ])));
    await Printing.sharePdf(bytes: await doc.save(), filename: 'El-Ayma-Qayma.pdf');
  }

  @override
  Widget build(BuildContext context) {
    var filtered = filter == 'الكل' ? items : items.where((e) => e.cat == filter).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('القايمة - El Ayma'), backgroundColor: const Color(0xFF8B5A2B), foregroundColor: Colors.white, actions: [IconButton(onPressed: makePdf, icon: const Icon(Icons.picture_as_pdf))]),
      floatingActionButton: FloatingActionButton(backgroundColor: const Color(0xFF8B5A2B), onPressed: () {
        showDialog(context: context, builder: (c) => AlertDialog(title: const Text('إضافة صنف'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameC, decoration: const InputDecoration(labelText: 'اسم الصنف')),
          TextField(controller: priceC, decoration: const InputDecoration(labelText: 'السعر'), keyboardType: TextInputType.number),
          TextField(controller: qtyC, decoration: const InputDecoration(labelText: 'العدد'), keyboardType: TextInputType.number),
          DropdownButton<String>(value: selCat, isExpanded: true, items: cats.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => selCat = v!)),
        ])), actions: [ElevatedButton(onPressed: () { if (nameC.text.isEmpty) return; setState(() => items.add(Item(nameC.text, selCat, double.tryParse(priceC.text) ?? 0, int.tryParse(qtyC.text) ?? 1))); nameC.clear(); priceC.clear(); qtyC.text = '1'; save(); Navigator.pop(context); }, child: const Text('إضافة'))]));
      }, child: const Icon(Icons.add, color: Colors.white)),
      body: Padding(padding: const EdgeInsets.all(10), child: Column(children: [
        Row(children: [Expanded(child: TextField(controller: groom, decoration: const InputDecoration(labelText: 'اسم العريس', border: OutlineInputBorder()), onChanged: (_) => save())), const SizedBox(width: 6), Expanded(child: TextField(controller: bride, decoration: const InputDecoration(labelText: 'اسم العروسة', border: OutlineInputBorder()), onChanged: (_) => save()))]),
        const SizedBox(height: 8),
        Row(children: [Expanded(child: TextField(controller: gold, decoration: const InputDecoration(labelText: 'الذهب', border: OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (_) => save())), const SizedBox(width: 6), Expanded(child: TextField(controller: moakhar, decoration: const InputDecoration(labelText: 'المؤخر', border: OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (_) => save()))]),
        const SizedBox(height: 8),
        SizedBox(height: 40, child: ListView(scrollDirection: Axis.horizontal, children: ['الكل', ...cats].map((c) => Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(label: Text(c), selected: filter == c, onSelected: (_) => setState(() => filter = c)))).toList())),
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(10)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('الإجمالي:', style: TextStyle(fontWeight: FontWeight.bold)), Text('$total ج', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF8B5A2B)))])),
        const
