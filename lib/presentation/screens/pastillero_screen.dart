import 'package:flutter/material.dart';
import '/database/database_helper.dart';

class PastilleroScreen extends StatelessWidget {
  final int idUsuario;

  const PastilleroScreen({super.key, required this.idUsuario});

  Future<List<Map<String, dynamic>>> _cargarMedicamentos() async {
    final patologias = await DatabaseHelper()
        .obtenerPatologiasConMedicamentosConPautas(idUsuario);

    List<Map<String, dynamic>> listaMedicamentos = [];

    for (var patologia in patologias) {
      final meds = patologia['medicamentos'] as List<dynamic>;

      for (var med in meds) {
        listaMedicamentos.add({
          'nombre': med['nombre'] ?? 'Medicamento',
          'desayuno': med['pautaDesayuno']?.toString() ?? '0',
          'comida': med['pautaComida']?.toString() ?? '0',
          'cena': med['pautaCena']?.toString() ?? '0',
        });
      }
    }

    return listaMedicamentos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 211, 211, 236),
      appBar: AppBar(title: Text('Pastillero')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _cargarMedicamentos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay medicamentos cargados.'));
          }

          final medicamentos = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Card(
              color: Colors.white,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pautas de Medicación',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DataTable(
                      columnSpacing: 12,
                      columns: const [
                        DataColumn(label: Text('Medicamento')),
                        DataColumn(label: Text('Desayuno')),
                        DataColumn(label: Text('Comida')),
                        DataColumn(label: Text('Cena')),
                      ],
                      rows:
                          medicamentos.map((med) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      med['nombre'],
                                      softWrap: true,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(Center(child: Text(med['desayuno']))),
                                DataCell(Center(child: Text(med['comida']))),
                                DataCell(Center(child: Text(med['cena']))),
                              ],
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
