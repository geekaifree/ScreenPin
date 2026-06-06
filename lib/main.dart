import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(const ScreenPinApp());

class ScreenPinApp extends StatelessWidget {
  const ScreenPinApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '屏幕贴图', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.amber, useMaterial3: true, brightness: Brightness.light),
    darkTheme: ThemeData(colorSchemeSeed: Colors.amber, useMaterial3: true, brightness: Brightness.dark),
    home: const PinHomePage(),
  );
}

class PinnedNote {
  String id, content;
  double x, y, w, h;
  double opacity;
  int color;
  bool alwaysOnTop;
  PinnedNote({required this.id, required this.content, this.x = 50, this.y = 50, this.w = 200, this.h = 150, this.opacity = 0.9, this.color = 0xFFFFF9C4, this.alwaysOnTop = true});
  Map<String, dynamic> toJson() => {'id': id, 'content': content, 'x': x, 'y': y, 'w': w, 'h': h, 'opacity': opacity, 'color': color, 'top': alwaysOnTop};
  factory PinnedNote.fromJson(Map<String, dynamic> j) => PinnedNote(id: j['id'], content: j['content'], x: j['x']?.toDouble() ?? 50, y: j['y']?.toDouble() ?? 50, w: j['w']?.toDouble() ?? 200, h: j['h']?.toDouble() ?? 150, opacity: j['opacity']?.toDouble() ?? 0.9, color: j['color'] ?? 0xFFFFF9C4, alwaysOnTop: j['top'] ?? true);
}

class PinHomePage extends StatefulWidget {
  const PinHomePage({super.key});
  @override
  State<PinHomePage> createState() => _PinHomePageState();
}

class _PinHomePageState extends State<PinHomePage> {
  List<PinnedNote> _notes = [];
  final _colors = [0xFFFFF9C4, 0xFFC8E6C9, 0xFFBBDEFB, 0xFFF8BBD0, 0xFFFFE0B2, 0xFFD1C4E9, 0xFFB2EBF2, 0xFFFFCCBC];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final d = p.getString('pinned_notes');
    if (d != null) setState(() => _notes = (json.decode(d) as List).map((e) => PinnedNote.fromJson(e)).toList());
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('pinned_notes', json.encode(_notes.map((e) => e.toJson()).toList()));
  }

  void _addNote() {
    final note = PinnedNote(id: DateTime.now().millisecondsSinceEpoch.toString(), content: '新便签\n\n双击编辑内容', x: 50 + _notes.length * 20.0, y: 50 + _notes.length * 20.0);
    setState(() => _notes.add(note));
    _save();
  }

  void _editNote(PinnedNote note) {
    final ctrl = TextEditingController(text: note.content);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('编辑便签'),
      content: TextField(controller: ctrl, maxLines: 8, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '输入内容...')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: () { setState(() => note.content = ctrl.text); _save(); Navigator.pop(ctx); }, child: const Text('保存')),
      ],
    ));
  }

  void _deleteNote(PinnedNote note) { setState(() => _notes.removeWhere((n) => n.id == note.id)); _save(); }

  void _changeColor(PinnedNote note, int color) { setState(() => note.color = color); _save(); }

  void _changeOpacity(PinnedNote note, double opacity) { setState(() => note.opacity = opacity); _save(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📌 屏幕贴图'), centerTitle: true, actions: [
        IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: _addNote, tooltip: '新建便签'),
        IconButton(icon: const Icon(Icons.delete_sweep), onPressed: () => showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('清空确认'), content: const Text('删除所有贴图？'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')), FilledButton(onPressed: () { setState(() => _notes.clear()); _save(); Navigator.pop(ctx); }, child: const Text('删除'))])), tooltip: '清空'),
      ]),
      body: _notes.isEmpty ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.push_pin, size: 80, color: Colors.grey.shade300), const SizedBox(height: 16), Text('点击 + 创建贴图便签', style: TextStyle(color: Colors.grey.shade500, fontSize: 16))])) : Stack(children: _notes.map((note) => Positioned(left: note.x, top: note.y, child: GestureDetector(
        onPanUpdate: (d) => setState(() { note.x += d.delta.dx; note.y += d.delta.dy; }),
        onDoubleTap: () => _editNote(note),
        child: Opacity(opacity: note.opacity, child: Container(width: note.w, height: note.h, decoration: BoxDecoration(color: Color(note.color), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(2, 4))]), child: Column(children: [
          Container(height: 28, decoration: BoxDecoration(color: Color(note.color).withOpacity(0.7), borderRadius: const BorderRadius.vertical(top: Radius.circular(12))), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            IconButton(icon: const Icon(Icons.palette, size: 16), onPressed: () => showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [const Padding(padding: EdgeInsets.all(12), child: Text('选择颜色', style: TextStyle(fontWeight: FontWeight.bold))), Wrap(spacing: 8, runSpacing: 8, children: _colors.map((c) => GestureDetector(onTap: () { _changeColor(note, c); Navigator.pop(ctx); }, child: Container(width: 36, height: 36, decoration: BoxDecoration(color: Color(c), shape: BoxShape.circle, border: Border.all(color: note.color == c ? Colors.black : Colors.transparent, width: 2))))).toList()), Padding(padding: const EdgeInsets.all(12), child: Row(children: [const Text('透明度: '), Expanded(child: Slider(value: note.opacity, min: 0.3, max: 1, onChanged: (v) => _changeOpacity(note, v)))]))])), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 24, minHeight: 24)),
            IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => _deleteNote(note), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 24, minHeight: 24)),
          ])),
          Expanded(child: Padding(padding: const EdgeInsets.all(8), child: Text(note.content, style: const TextStyle(fontSize: 13), overflow: TextOverflow.fade))),
        ])),
      ))).toList()),
    );
  }
}
