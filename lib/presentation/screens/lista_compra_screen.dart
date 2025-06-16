import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '/database/database_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ListaCompraMedicamentosScreen extends StatefulWidget {
  final int idUsuario;

  const ListaCompraMedicamentosScreen({super.key, required this.idUsuario});

  @override
  State<ListaCompraMedicamentosScreen> createState() =>
      _ListaCompraMedicamentosScreenState();
}

class _ListaCompraMedicamentosScreenState
    extends State<ListaCompraMedicamentosScreen> {
  List<Map<String, dynamic>> _medicamentos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarMedicamentos();
  }

  Future<void> _cargarMedicamentos() async {
    final todos = await DatabaseHelper().obtenerMedicamentosPorUsuario(
      widget.idUsuario,
    );

    final proximosAComprar =
        todos.where((m) {
          final dias = m['diasMedicamento'];
          return dias != null && dias is int && dias < 5;
        }).toList();

    setState(() {
      _medicamentos = proximosAComprar;
      _isLoading = false;
    });
  }

  void _compartirLista() {
    if (_medicamentos.isEmpty) return;

    final buffer = StringBuffer("📋 Lista de compra:\n\n");

    for (var med in _medicamentos) {
      buffer.writeln("- ${med['nombre']} (CN: ${med['cn']})");
      buffer.writeln("  Días restantes: ${med['diasMedicamento']}\n");
    }

    Share.share(buffer.toString(), subject: 'Medicamentos por comprar');
  }

  Future<void> _guardarPDF() async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = "${now.day}-${now.month}-${now.year}";

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Lista de compra',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Fecha: $formattedDate',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.Divider(),
              pw.SizedBox(height: 12),
              ..._medicamentos.map(
                (med) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "${med['nombre'] ?? 'Sin nombre'}",
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        "CN: ${med['cn']}",
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.Text(
                        "Días restantes: ${med['diasMedicamento']}",
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    final directory = await getExternalStorageDirectory();
    final path = "${directory!.path}/lista_compra_$formattedDate.pdf";
    final file = File(path);
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('PDF guardado en: $path')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 211, 211, 236),
      appBar: AppBar(
        title: const Text('Lista de compra'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Compartir lista',
            onPressed: _medicamentos.isEmpty ? null : _compartirLista,
          ),

          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: 'Guardar PDF',
            onPressed: _medicamentos.isEmpty ? null : _guardarPDF,
          ),
        ],
      ),

      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _medicamentos.isEmpty
              ? const Center(child: Text('No hay medicamentos por reponer'))
              : ListView.builder(
                itemCount: _medicamentos.length,
                itemBuilder: (context, index) {
                  final medicamento = _medicamentos[index];
                  return Card(
                    color: Colors.white,
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/icons/drugs.png',
                            width: 40,
                            height: 40,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  medicamento['nombre'] ?? 'Sin nombre',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'CN: ${medicamento['cn'] ?? '---'}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                Text(
                                  'Días restantes: ${medicamento['diasMedicamento']}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
