import 'package:flutter/material.dart';
import 'crear_medicamento_screen.dart';
import '/presentation/screens/editar_medicamento_screen.dart';
import 'crear_patologia_screen.dart';
import '/presentation/screens/alertas_toma_medicacion.dart';
import '/database/database_helper.dart';
import 'editar_patologia_screen.dart';

class TratamientosScreen extends StatefulWidget {
  final int idUsuario;

  const TratamientosScreen({super.key, required this.idUsuario});

  @override
  State<TratamientosScreen> createState() => _TratamientosScreenState();
}

class _TratamientosScreenState extends State<TratamientosScreen> {
  Map<Map<String, dynamic>, List<Map<String, dynamic>>> _datos = {};

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final patologias = await DatabaseHelper().getPatologiasPorUsuario(
      widget.idUsuario,
    );
    final Map<Map<String, dynamic>, List<Map<String, dynamic>>> temp = {};

    for (var patologia in patologias) {
      final meds = await DatabaseHelper().getMedicamentosPorPatologia(
        patologia['id'],
      );
      temp[patologia] = meds;
    }

    setState(() {
      _datos = temp;
    });
  }

  Future<void> _eliminarMedicamento(int id, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Eliminar medicamento'),
            content: Text('¿Deseas eliminar "$nombre"?'),
            actions: [
              TextButton(
                child: Text('Cancelar'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text('Eliminar', style: TextStyle(color: Colors.red)),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await DatabaseHelper().eliminarMedicamento(id);

      // Cancelar todas las notificaciones
      await AlertasTomaMedicacion.cancelAllNotifications();

      // Reprogramar notificaciones desde la base de datos
      await AlertasTomaMedicacion.reprogramarNotificacionesDesdeBBDD(
        widget.idUsuario,
      );

      await _cargarDatos();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Medicamento eliminado')));
    }
  }

  Future<void> _eliminarPatologia(int id, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Eliminar patología'),
            content: Text('¿Deseas eliminar la patología "$nombre"?'),
            actions: [
              TextButton(
                child: Text('Cancelar'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text('Eliminar', style: TextStyle(color: Colors.red)),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await DatabaseHelper().eliminarPatologia(id);

      // Cancelar todas las notificaciones
      await AlertasTomaMedicacion.cancelAllNotifications();

      // Reprogramar notificaciones desde la base de datos
      await AlertasTomaMedicacion.reprogramarNotificacionesDesdeBBDD(
        widget.idUsuario,
      );

      await _cargarDatos();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Patología eliminada')));
    }
  }

  void _editarPatologia(Map<String, dynamic> patologia) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarPatologiaScreen(patologia: patologia),
      ),
    ).then((_) => _cargarDatos());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 211, 211, 236),
      appBar: AppBar(title: Text('Tratamientos')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: ElevatedButton.icon(
                label: Text('Añadir patología'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              CrearPatologiaScreen(idUsuario: widget.idUsuario),
                    ),
                  ).then((_) => _cargarDatos());
                },
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child:
                  _datos.isEmpty
                      ? Center(child: Text('No hay datos disponibles'))
                      : ListView(
                        children:
                            _datos.entries.map((entry) {
                              final patologia = entry.key;
                              final medicamentos = entry.value;

                              return Card(
                                elevation: 3,
                                margin: EdgeInsets.symmetric(vertical: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              patologia['nombre'],
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: Image.asset(
                                                  'assets/icons/pencil.png',
                                                  width: 20,
                                                  height: 20,
                                                ),
                                                tooltip: 'Modificar Patología',
                                                onPressed:
                                                    () => _editarPatologia(
                                                      patologia,
                                                    ),
                                              ),
                                              IconButton(
                                                icon: Image.asset(
                                                  'assets/icons/delete.png',
                                                  width: 20,
                                                  height: 20,
                                                ),
                                                tooltip: 'Eliminar Patología',
                                                onPressed:
                                                    () => _eliminarPatologia(
                                                      patologia['id'],
                                                      patologia['nombre'],
                                                    ),
                                              ),
                                              IconButton(
                                                icon: Image.asset(
                                                  'assets/icons/healthcare.png',
                                                  width: 30,
                                                  height: 30,
                                                ),
                                                tooltip: 'Añadir medicamento',
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (
                                                            context,
                                                          ) => CrearMedicamentoScreen(
                                                            idUsuario:
                                                                widget
                                                                    .idUsuario,
                                                            idPatologia:
                                                                patologia['id'],
                                                          ),
                                                    ),
                                                  ).then((_) => _cargarDatos());
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Divider(),
                                      if (medicamentos.isEmpty)
                                        Text('Sin medicamentos'),
                                      ...medicamentos.map((med) {
                                        return ListTile(
                                          title: Text(med['nombre']),
                                          subtitle: Text('CN: ${med['cn']}'),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Image.asset(
                                                  'assets/icons/pencil.png',
                                                  width: 20,
                                                  height: 20,
                                                ),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (
                                                            context,
                                                          ) => EditarMedicamentoScreen(
                                                            medicamento: med,
                                                            idUsuario:
                                                                widget
                                                                    .idUsuario,
                                                          ),
                                                    ),
                                                  ).then((_) => _cargarDatos());
                                                },
                                              ),
                                              IconButton(
                                                icon: Image.asset(
                                                  'assets/icons/delete.png',
                                                  width: 20,
                                                  height: 20,
                                                ),
                                                onPressed:
                                                    () => _eliminarMedicamento(
                                                      med['id'],
                                                      med['nombre'],
                                                    ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
