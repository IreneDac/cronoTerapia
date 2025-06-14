import 'package:flutter/material.dart';
import '/database/database_helper.dart';

class EfectoAdverso {
  final String categoria;
  final String descripcion;

  EfectoAdverso({required this.categoria, required this.descripcion});
}

class AlertasPersonalizadasScreen extends StatefulWidget {
  final int idUsuario;

  const AlertasPersonalizadasScreen({Key? key, required this.idUsuario})
    : super(key: key);

  @override
  _AlertasPersonalizadasState createState() => _AlertasPersonalizadasState();
}

class _AlertasPersonalizadasState extends State<AlertasPersonalizadasScreen> {
  List<String> _alertas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarAlertas();
  }

  Future<List<EfectoAdverso>> obtenerEfectosDelUsuario(int idUsuario) async {
    final db = await DatabaseHelper().database;

    final resultado = await db.rawQuery(
      '''
    SELECT ea.categoria, ea.efectoAdverso
    FROM Patologias p
    JOIN Medicamentos m ON p.id = m.idPatologia
    JOIN EfectosSecundarios ea ON m.idEfectoAdverso = ea.id
    WHERE p.idUsuario = ?
  ''',
      [idUsuario],
    );

    return resultado
        .map(
          (fila) => EfectoAdverso(
            categoria: fila['categoria'] as String,
            descripcion: fila['efectoAdverso'] as String,
          ),
        )
        .toList();
  }

  List<String> generarAlertasDesdeHistorial(List<EfectoAdverso> efectos) {
    final alertas = <String>{};

    for (var efecto in efectos) {
      final desc = efecto.descripcion.toLowerCase();
      if (['náuseas', 'diarrea', 'estreñimiento'].contains(desc)) {
        alertas.add(
          'Has reportado efectos digestivos anteriormente. Mantente hidratado y consulta si persisten.',
        );
      } else if (['somnolencia/sedación', 'fatiga', 'mareos'].contains(desc)) {
        alertas.add(
          'Tu historial incluye síntomas de somnolencia o fatiga. Evita conducir si te sientes afectado.',
        );
      } else if ([
        'palpitaciones',
        'hipertensión',
        'hipotensión',
      ].contains(desc)) {
        alertas.add(
          'Has experimentado síntomas cardiovasculares. Consulta si notas alteraciones persistentes.',
        );
      } else if (['insomnio', 'depresión'].contains(desc)) {
        alertas.add(
          'Tu historial muestra alteraciones del sueño o ánimo. Es importante hablar con un profesional.',
        );
      } else if (desc == 'erupción cutánea') {
        alertas.add(
          'Has reportado reacciones dermatológicas. Observa tu piel ante cualquier nuevo tratamiento.',
        );
      } else {
        alertas.add(
          'Has tenido efectos adversos previos como: ${efecto.descripcion}. Toma precauciones.',
        );
      }
    }

    return alertas.toList();
  }

  Future<void> _cargarAlertas() async {
    final efectos = await obtenerEfectosDelUsuario(widget.idUsuario);
    final alertasGeneradas = generarAlertasDesdeHistorial(efectos);

    setState(() {
      _alertas = alertasGeneradas;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 211, 211, 236),
      appBar: AppBar(title: const Text("Alertas Personalizadas")),
      body:
          _alertas.isEmpty
              ? const Center(
                child: Text(
                  'No hay alertas personalizadas',
                  style: TextStyle(fontSize: 16),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: _alertas.length,
                itemBuilder: (context, index) {
                  final alerta = _alertas[index];
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
                            'assets/icons/crisis.png',
                            width: 30,
                            height: 30,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              alerta,
                              style: const TextStyle(fontSize: 16),
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
