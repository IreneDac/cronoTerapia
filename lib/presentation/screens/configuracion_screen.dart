import 'package:flutter/material.dart';
import '/database/database_helper.dart';
import '/presentation/screens/alertas_toma_medicacion.dart';
import '/presentation/screens/atribuciones_screen.dart';

class ConfiguracionScreen extends StatefulWidget {
  final int idUsuario;

  const ConfiguracionScreen({super.key, required this.idUsuario});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  TimeOfDay? desayuno;
  TimeOfDay? comida;
  TimeOfDay? cena;

  @override
  void initState() {
    super.initState();
    _cargarHorarios();
  }

  Future<void> _cargarHorarios() async {
    final db = await DatabaseHelper().database;
    final result = await db.query(
      'Configuracion',
      where: 'idUsuario = ?',
      whereArgs: [widget.idUsuario],
      limit: 1,
    );

    if (result.isNotEmpty) {
      final data = result.first;
      setState(() {
        desayuno = _parseTime(data['horarioNotifDesayuno'] as String?);
        comida = _parseTime(data['horarioNotifComida'] as String?);
        cena = _parseTime(data['horarioNotifCena'] as String?);
      });
    }
  }

  TimeOfDay? _parseTime(String? timeString) {
    if (timeString == null) return null;
    final parts = timeString.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay time) {
    return time.hour.toString().padLeft(2, '0') +
        ':' +
        time.minute.toString().padLeft(2, '0');
  }

  Future<void> _seleccionarHora(
    TimeOfDay? horaActual,
    Function(TimeOfDay) onSeleccionada,
  ) async {
    final nuevaHora = await showTimePicker(
      context: context,
      initialTime: horaActual ?? TimeOfDay.now(),
    );

    if (nuevaHora != null) {
      onSeleccionada(nuevaHora);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 211, 211, 236),
      appBar: AppBar(title: Text('Configuración')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Horario de Notificaciones',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            _campoHora('Desayuno', desayuno, (hora) {
              setState(() {
                desayuno = hora;
              });
            }),

            SizedBox(height: 12),

            _campoHora('Comida', comida, (hora) {
              setState(() {
                comida = hora;
              });
            }),

            SizedBox(height: 12),

            _campoHora('Cena', cena, (hora) {
              setState(() {
                cena = hora;
              });
            }),

            SizedBox(height: 24),

            Center(
              child: ElevatedButton(
                onPressed: () async {
                  if (desayuno == null || comida == null || cena == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Por favor, selecciona todas las horas (desayuno, comida y cena).',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final db = await DatabaseHelper().database;
                  await db.update(
                    'Configuracion',
                    {
                      'horarioNotifDesayuno': _formatTime(desayuno!),
                      'horarioNotifComida': _formatTime(comida!),
                      'horarioNotifCena': _formatTime(cena!),
                    },
                    where: 'idUsuario = ?',
                    whereArgs: [widget.idUsuario],
                  );

                  await AlertasTomaMedicacion.cancelAllNotifications();
                  await AlertasTomaMedicacion.reprogramarNotificacionesDesdeBBDD(
                    widget.idUsuario,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Horarios guardados correctamente.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AtribucionesScreen(),
              ),
            );
          },
          child: Text(
            'Ver atribuciones',
            style: TextStyle(
              fontSize: 16,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    );
  }

  Widget _campoHora(
    String label,
    TimeOfDay? time,
    Function(TimeOfDay) onSelected,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 16)),
        ElevatedButton(
          onPressed: () {
            _seleccionarHora(time, onSelected);
          },
          child: Text(time == null ? 'Seleccionar hora' : _formatTime(time)),
        ),
      ],
    );
  }
}
