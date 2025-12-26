import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:convert'; 
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart'; 
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../Sermones/biblioteca_sermones.dart';

class PantallaEditorSermon extends StatefulWidget {
  const PantallaEditorSermon({super.key});

  @override
  State<PantallaEditorSermon> createState() => _PantallaEditorSermonState();
}

class _PantallaEditorSermonState extends State<PantallaEditorSermon> {
  final QuillController _controller = QuillController.basic();
  final TextEditingController _citaController = TextEditingController();
  final TextEditingController _tituloController = TextEditingController();
  String _temaSeleccionado = 'General';
  DateTime _fechaSeleccionada = DateTime.now();

  // --- NUEVA FUNCIÓN: LIMPIAR TODO ---
  void _nuevoSermon() {
    setState(() {
      _controller.clear();
      _tituloController.clear();
      _citaController.clear();
      _temaSeleccionado = 'General';
      _fechaSeleccionada = DateTime.now();
    });
    _mostrarMensaje("Editor listo para un nuevo mensaje");
  }

  // --- FUNCIÓN: INSERTAR VERSÍCULO ---
  Future<void> _insertarVersiculo(String cita) async {
    if (cita.isEmpty) return;
    String busqueda = cita.trim().replaceAll(' ', '/').replaceAll(':', '/');
    final url = Uri.parse('https://bible-api.deno.dev/api/read/rv1960/$busqueda');
    
    try {
      _mostrarMensaje("Buscando en Reina Valera...");
      final response = await http.get(url);
      if (!mounted) return;
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String textoFinal = (data is List) 
            ? data.map((v) => "${v['number']}. ${v['verse']}").join(" ") 
            : (data['verse'] ?? data['content'] ?? "");
        
        String citaFormateada = "\n\"$textoFinal\"\n($cita)\n";
        int index = _controller.selection.baseOffset;
        if (index < 0) index = _controller.document.length;
        
        _controller.document.insert(index, citaFormateada);
        await Future.delayed(const Duration(milliseconds: 200));
        _controller.updateSelection(
          TextSelection.collapsed(offset: index + citaFormateada.length), 
          ChangeSource.local
        );
        _citaController.clear();
      }
    } catch (e) { 
      debugPrint("Error: $e");
      _mostrarMensaje("Error al conectar con la Biblia");
    }
  }

  void _mostrarMensaje(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))
    );
  }

  // --- FUNCIÓN: GUARDAR ---
  void _guardarSermon() {
    final titulo = _tituloController.text.trim();
    if (titulo.isEmpty) { 
      _mostrarMensaje("Escribe un título"); 
      return; 
    }
    try {
      final box = Hive.box('mis_sermones');
      box.add({
        'titulo': titulo, 
        'tema': _temaSeleccionado, 
        'fecha': _fechaSeleccionada.toIso8601String(), 
        'contenido': jsonEncode(_controller.document.toDelta().toJson())
      });
      _mostrarMensaje("¡Sermón guardado!");
    } catch (e) { debugPrint("Error: $e"); }
  }

  // --- FUNCIÓN: EXPORTAR PDF ---
  Future<void> _exportarAPDF() async {
  final pdf = pw.Document();
  final textoSermon = _controller.document.toPlainText();
  final titulo = _tituloController.text.isEmpty ? "SERMÓN SIN TÍTULO" : _tituloController.text;

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) => [
        pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            "Fecha: ${_fechaSeleccionada.day}/${_fechaSeleccionada.month}/${_fechaSeleccionada.year}",
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text(
            titulo.toUpperCase(),
            style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Center(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
            child: pw.Text(
              " TEMA: $_temaSeleccionado ",
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Divider(thickness: 1, color: PdfColors.blueGrey),
        pw.SizedBox(height: 20),

        // Párrafo con el espaciado corregido
        pw.Paragraph(
          text: textoSermon,
          style: const pw.TextStyle(fontSize: 13, lineSpacing: 4), 
          textAlign: pw.TextAlign.justify,
        ),
      ],
      footer: (pw.Context context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 10),
        child: pw.Text(
          'Página ${context.pageNumber} de ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
        ),
      ),
    ),
  );

  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
    name: '${titulo.replaceAll(' ', '_')}.pdf',
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Mi Bosquejo', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.note_add), onPressed: _nuevoSermon, tooltip: 'Nuevo Sermón'),
          IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: _exportarAPDF, tooltip: 'Exportar a PDF'),
          IconButton(
            icon: const Icon(Icons.library_books),
            onPressed: () async {
              final sermon = await Navigator.push(context, MaterialPageRoute(builder: (context) => const BibliotecaSermones()));
              if (sermon != null && mounted) {
                setState(() {
                  _tituloController.text = sermon['titulo'];
                  _temaSeleccionado = sermon['tema'];
                  _fechaSeleccionada = DateTime.parse(sermon['fecha']);
                  final jsonContent = jsonDecode(sermon['contenido']);
                  _controller.document = Document.fromJson(jsonContent);
                });
              }
            },
          ),
          IconButton(icon: const Icon(Icons.save), onPressed: _guardarSermon, tooltip: 'Guardar'),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF1A237E),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                    child: DropdownButton<String>(
                      value: _temaSeleccionado,
                      dropdownColor: const Color(0xFF1A237E),
                      style: const TextStyle(color: Colors.white),
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: ['General', 'Salvación', 'Familia', 'Liderazgo'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) => setState(() => _temaSeleccionado = val!),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white24, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: Text("${_fechaSeleccionada.day}/${_fechaSeleccionada.month}"),
                  onPressed: () async {
                    DateTime? pick = await showDatePicker(context: context, initialDate: _fechaSeleccionada, firstDate: DateTime(2000), lastDate: DateTime(2100));
                    if (pick != null) setState(() => _fechaSeleccionada = pick);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _tituloController,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: "Título del Sermón",
                      filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.title, color: Color(0xFF1A237E)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _citaController,
                    decoration: InputDecoration(
                      hintText: "Buscar en la Biblia...",
                      filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.auto_stories, color: Color(0xFF1A237E)),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add_circle, color: Color(0xFF1A237E)),
                        onPressed: () => _insertarVersiculo(_citaController.text),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                      ),
                      child: Column(
                        children: [
                          QuillSimpleToolbar(configurations: QuillSimpleToolbarConfigurations(controller: _controller)),
                          const Divider(height: 1),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: QuillEditor.basic(configurations: QuillEditorConfigurations(controller: _controller, autoFocus: false)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}