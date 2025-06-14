import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/database/database_helper.dart';

class MedicamentosFaltaSuministroScreen extends StatefulWidget {
  final int idUsuario;

  const MedicamentosFaltaSuministroScreen({super.key, required this.idUsuario});

  @override
  State<MedicamentosFaltaSuministroScreen> createState() =>
      _MedicamentosFaltaSuministroScreenState();
}

class _MedicamentosFaltaSuministroScreenState
    extends State<MedicamentosFaltaSuministroScreen> {
  bool _cargando = true;
  List<Map<String, dynamic>> _medicamentosConFalta = [];

  @override
  void initState() {
    super.initState();
    _consultarFaltaSuministro();
  }

  Future<void> _consultarFaltaSuministro() async {
    final medicamentos = await DatabaseHelper().obtenerMedicamentosPorUsuario(
      widget.idUsuario,
    );

    List<Map<String, dynamic>> conFalta = [];

    for (var medicamento in medicamentos) {
      final cn = medicamento['cn']?.toString();
      if (cn == null || cn.isEmpty) continue;

      final url = Uri.parse('https://cima.aemps.es/cima/rest/psuministro/$cn');
      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final resultados = data['resultados'] as List<dynamic>?;

          if (resultados != null && resultados.isNotEmpty) {
            for (var resultado in resultados) {
              conFalta.add({
                'cn': resultado['cn'] ?? '',
                'nombre': resultado['nombre'] ?? '',
                'observ': resultado['observ'] ?? '',
              });
            }
          }
        }
      } catch (e) {
        print('Error consultando suministro para cn=$cn: $e');
      }
    }

    setState(() {
      _medicamentosConFalta = conFalta;
      _cargando = false;
    });
  }

  Widget _buildListaFaltas() {
    return ListView.builder(
      itemCount: _medicamentosConFalta.length,
      itemBuilder: (context, index) {
        final med = _medicamentosConFalta[index];
        return Card(
          color: Colors.white,
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset('assets/icons/crisis.png', width: 30, height: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med['nombre'] ?? 'Medicamento',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        med['observ'] ?? 'Sin observaciones',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 211, 211, 236),
      appBar: AppBar(title: const Text('Problemas de suministro')),
      body:
          _cargando
              ? const Center(child: CircularProgressIndicator())
              : _medicamentosConFalta.isEmpty
              ? const Center(
                child: Text('No hay medicamentos con falta de suministro'),
              )
              : Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Hay medicamentos con falta de suministro:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(child: _buildListaFaltas()),
                  ],
                ),
              ),
    );
  }
}
