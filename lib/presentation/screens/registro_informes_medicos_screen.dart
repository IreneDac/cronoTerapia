import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'pdf_preview_screen.dart';

class RegistroInformesMedicosScreen extends StatefulWidget {
  @override
  _RegistroInformesMedicosScreenState createState() =>
      _RegistroInformesMedicosScreenState();
}

class _RegistroInformesMedicosScreenState
    extends State<RegistroInformesMedicosScreen> {
  List<File> _pdfFiles = [];

  @override
  void initState() {
    super.initState();
    _loadSavedPdfs();
  }

  Future<void> _loadSavedPdfs() async {
    final dir = await _getPdfDirectory();
    final files = dir.listSync();
    setState(() {
      _pdfFiles =
          files
              .whereType<File>()
              .where((file) => file.path.endsWith('.pdf'))
              .toList();
    });
  }

  Future<Directory> _getPdfDirectory() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory('${baseDir.path}/pdfs');
    if (!pdfDir.existsSync()) {
      pdfDir.createSync();
    }
    return pdfDir;
  }

  Future<void> _pickAndSavePdfs() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      final pdfDir = await _getPdfDirectory();

      for (var file in result.files) {
        final sourceFile = File(file.path!);
        final fileName = file.name;
        final newPath = '${pdfDir.path}/$fileName';

        await sourceFile.copy(newPath);
      }

      await _loadSavedPdfs();
    }
  }

  void _openPdf(File pdf) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PdfPreviewScreen(pdfFile: pdf)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 211, 211, 236),
      appBar: AppBar(title: Text('Gestor de PDFs')),
      body:
          _pdfFiles.isEmpty
              ? Center(child: Text('No hay Informes médicos almacenados'))
              : ListView.builder(
                itemCount: _pdfFiles.length,
                itemBuilder: (context, index) {
                  final file = _pdfFiles[index];
                  final fileName = file.path.split('/').last;
                  return ListTile(
                    title: Text(fileName),
                    onTap: () => _openPdf(file),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await file.delete();
                        await _loadSavedPdfs();
                      },
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndSavePdfs,
        child: Icon(Icons.add),
        tooltip: 'Agregar PDF',
      ),
    );
  }
}
