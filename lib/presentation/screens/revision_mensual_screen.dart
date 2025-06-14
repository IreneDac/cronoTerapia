import 'package:flutter/material.dart';
import '/database/database_helper.dart';

class RevisionMensualScreen extends StatefulWidget {
  final int idUsuario;

  const RevisionMensualScreen({Key? key, required this.idUsuario})
    : super(key: key);

  @override
  _RevisionMensualScreenState createState() => _RevisionMensualScreenState();
}

class _RevisionMensualScreenState extends State<RevisionMensualScreen> {
  List<Map<String, dynamic>> _datos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final db = await DatabaseHelper().database;

    final medicamentos = await db.rawQuery(
      '''
      SELECT m.*
      FROM medicamentos m
      JOIN patologias p ON m.idPatologia = p.id
      WHERE p.idUsuario = ?
    ''',
      [widget.idUsuario],
    );

    List<Map<String, dynamic>> lista = [];

    for (var med in medicamentos) {
      final nombreMed = med['nombre'];

      //Marcada como Tomada
      final marcadaComoTomada = await db.rawQuery(
        '''
        SELECT COUNT(*) as total
        FROM RegistroMedicacion rm
        WHERE rm.nombreMedicamento = ? AND rm.idUsuario = ?
          AND accion = 'Tomada'
          AND strftime('%Y-%m', fechaHora) = strftime('%Y-%m', 'now')
        ''',
        [nombreMed, widget.idUsuario],
      );

      final iMarcadaComoTomada =
          int.tryParse(marcadaComoTomada.first['total'].toString()) ?? 0;

      // Incumplimiento Pospuesta
      final incumplimientoPospuesta = await db.rawQuery(
        '''
        SELECT COUNT(*) as total
        FROM RegistroMedicacion rm
        WHERE rm.nombreMedicamento = ? AND rm.idUsuario = ?
          AND accion = 'Pospuesta'
          AND strftime('%Y-%m', fechaHora) = strftime('%Y-%m', 'now')
        ''',
        [nombreMed, widget.idUsuario],
      );

      final incumplimiento = incumplimientoPospuesta.first['total'] as int;

      // Incumplimiento Sin acción
      final incumplimientoSinAccionResult = await db.rawQuery(
        '''
        SELECT COUNT(*) as total
        FROM RegistroMedicacion rm
        WHERE rm.nombreMedicamento = ? AND rm.idUsuario = ?
          AND accion = 'Sin acción'
          AND strftime('%Y-%m', fechaHora) = strftime('%Y-%m', 'now')
        ''',
        [nombreMed, widget.idUsuario],
      );

      final int incumplimientoSinAccion =
          incumplimientoSinAccionResult.first['total'] as int;

      // Efecto adverso
      String efectoAdverso = '-';
      if (med['idEfectoAdverso'] != null) {
        final efectoResult = await db.query(
          'EfectosSecundarios',
          where: 'id = ?',
          whereArgs: [med['idEfectoAdverso']],
          limit: 1,
        );
        if (efectoResult.isNotEmpty) {
          efectoAdverso = efectoResult.first['efectoAdverso'] as String? ?? '-';
        }
      }

      lista.add({
        'nombre': nombreMed,
        'iMarcadaComoTomada': iMarcadaComoTomada,
        'incumplimiento': incumplimiento,
        'incumplimientoSinAccion': incumplimientoSinAccion,
        'efectoAdverso': efectoAdverso,
      });
    }

    setState(() {
      _datos = lista;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 211, 211, 236),
        appBar: AppBar(title: const Text('Revisión Mensual')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_datos.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Revisión Mensual')),
        body: const Center(child: Text('No hay medicamentos registrados.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 211, 211, 236),
      appBar: AppBar(title: const Text('Revisión Mensual')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _datos.length,
        itemBuilder: (context, index) {
          final item = _datos[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['nombre'] ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Tomas de medicación:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),

                  _buildRow('A la hora:', item['iMarcadaComoTomada']),
                  _buildRow('Pospuesta:', item['incumplimiento'], isBold: true),
                  _buildRow(
                    'Sin acción:',
                    item['incumplimientoSinAccion'],
                    isBold: true,
                  ),

                  const SizedBox(height: 12),

                  _buildRow('Efecto adverso:', item['efectoAdverso'] ?? '-'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRow(String label, dynamic value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.toString(),
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
