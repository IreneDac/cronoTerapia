import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import '/database/database_helper.dart';

class HojaMedicacionScreen extends StatefulWidget {
  final int idUsuario;
  final String nombre;
  final String apellidos;

  const HojaMedicacionScreen({
    super.key,
    required this.idUsuario,
    required this.nombre,
    required this.apellidos,
  });

  @override
  State<HojaMedicacionScreen> createState() => _HojaMedicacionScreenState();
}

class _HojaMedicacionScreenState extends State<HojaMedicacionScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _patologias = [];
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _cargarDatosYGenerarPDF();
  }

  Future<void> _cargarDatosYGenerarPDF() async {
    final datos = await dbHelper.obtenerPatologiasConMedicamentos(
      widget.idUsuario,
    );

    setState(() {
      _patologias = datos;
    });

    final pdfBytes = await _generarReportePdf();
    await _guardarPdfEnDisco(pdfBytes);

    setState(() {
      _loading = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('PDF generado correctamente')));
  }

  Future<Uint8List> _generarReportePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build:
            (context) => [
              pw.Text(
                'Hoja de Medicación',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Nombre: ${widget.nombre} ${widget.apellidos}'),
              pw.SizedBox(height: 20),

              pw.Text(
                'Patologías y Medicación:',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              ..._patologias.map((p) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      p['nombre'],
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    ...List<pw.Widget>.from(
                      (p['medicamentos'] as List).map(
                        (m) => pw.Bullet(text: m),
                      ),
                    ),
                    pw.SizedBox(height: 10),
                  ],
                );
              }),
            ],
      ),
    );

    return pdf.save();
  }

  Future<void> _guardarPdfEnDisco(Uint8List pdfBytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/hoja_medicacion_usuario_${widget.idUsuario}.pdf',
    );
    await file.writeAsBytes(pdfBytes);
    print('📄 PDF guardado en: ${file.path}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 211, 211, 236),
      appBar: AppBar(title: Text('Hoja de Medicación')),
      body: Center(
        child:
            _loading
                ? CircularProgressIndicator()
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 60,
                    ),
                    SizedBox(height: 20),
                    Text('Hoja de medicación descargada correctamente'),
                    SizedBox(height: 10),
                  ],
                ),
      ),
    );
  }
}
