import 'package:flutter/material.dart';
import '/database/database_helper.dart';
import 'package:intl/intl.dart';

class CumplimientosScreen extends StatelessWidget {
  final int idUsuario;

  const CumplimientosScreen({super.key, required this.idUsuario});

  Future<List<Map<String, dynamic>>> _fetchRegistros() async {
    final db = await DatabaseHelper().database;
    return await db.query(
      'RegistroMedicacion',
      where: 'idUsuario = ?',
      whereArgs: [idUsuario],
      orderBy: 'fechaHora DESC',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 211, 211, 236),
      appBar: AppBar(title: Text('Cumplimientos de Medicación')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchRegistros(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No hay Cumplimientos de Medicación almacenados.'),
            );
          }

          final registros = snapshot.data!;

          return ListView.builder(
            itemCount: registros.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final registro = registros[index];
              String accion = registro['accion'];

              Widget icono;
              if (accion == 'Tomada') {
                icono = Image.asset(
                  'assets/icons/check.png',
                  width: 30,
                  height: 30,
                );
              } else if (accion == 'Pospuesta') {
                icono = Image.asset(
                  'assets/icons/clock.png',
                  width: 30,
                  height: 30,
                );
              } else {
                icono = const SizedBox(width: 30);
              }

              return Card(
                color: Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 2,
                child: ListTile(
                  leading: Padding(
                    padding: const EdgeInsets.only(
                      top: 8.0,
                    ), // alinea con el texto
                    child: icono,
                  ),
                  title: Text(
                    registro['nombreMedicamento'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Momento: ${registro['momento']}\n'
                    'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(registro['fechaHora']))}\n'
                    'Acción: ${registro['accion']}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
