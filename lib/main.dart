import 'package:flutter/material.dart';
import '/presentation/screens/crear_usuario_screen.dart';
import '/presentation/screens/editar_usuario_screen.dart';
import '/presentation/screens/detalle_usuario_screen.dart';
import '/presentation/screens/alertas_toma_medicacion.dart';
import '/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> requestExactAlarmPermission() async {
  final intent = AndroidIntent(
    action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
    flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
  );
  await intent.launch();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final List<PendingNotificationRequest> pendingRequests =
      await flutterLocalNotificationsPlugin.pendingNotificationRequests();
  print('Número de notificaciones pendientes: ${pendingRequests.length}');
  for (var req in pendingRequests) {
    print(
      '  ID Pendiente: ${req.id}, Título: ${req.title}, Payload: ${req.payload}',
    );
  }

  DateTime now = DateTime.now();
  print('Fecha actual: ${now.day}/${now.month}/${now.year}');
  print('Hora actual del dispositivo: ${now.hour}:${now.minute}:${now.second}');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: '', home: MainScreen());
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _usuarios = [];

  @override
  void initState() {
    super.initState();
    _loadUsuarios();
    AlertasTomaMedicacion.init();
  }

  Future<void> _loadUsuarios() async {
    final results = await dbHelper.getAllUsuarios();
    setState(() {
      _usuarios = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 211, 211, 236),
      appBar: AppBar(
        title: Flexible(
          child: Text(
            'Sistema de Apoyo al Paciente para la Autogestión de Terapias Crónicas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            softWrap: true,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_forever),
            tooltip: 'Borrar base de datos',
            onPressed: () async {
              final databasesPath = await getDatabasesPath();
              String path = '$databasesPath/AplicacionMedicamentos.db';

              await deleteDatabase(path);

              setState(() {
                _usuarios = [];
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Base de datos eliminada')),
              );
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 100),
            _usuarios.isEmpty
                ? ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 35,
                    minHeight: 35,
                    maxWidth: double.infinity,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CrearUsuarioScreen(),
                        ),
                      );
                      _loadUsuarios();
                    },
                    icon: Image.asset(
                      'assets/icons/add-user.png',
                      width: 30,
                      height: 30,
                    ),
                    label: const Text(
                      'Crear nuevo usuario',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                )
                : Expanded(
                  child: ListView.builder(
                    itemCount: _usuarios.length + 1,
                    itemBuilder: (context, index) {
                      if (index < _usuarios.length) {
                        final usuario = _usuarios[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => DetalleUsuarioScreen(
                                              usuario: usuario,
                                            ),
                                      ),
                                    );
                                  },
                                  child: Text(usuario['nombre']),
                                ),
                              ),
                              IconButton(
                                icon: Image.asset(
                                  'assets/icons/pencil.png',
                                  width: 30,
                                  height: 30,
                                ),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => EditarUsuarioScreen(
                                            usuario: usuario,
                                          ),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadUsuarios();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Usuario actualizado correctamente',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),

                              const SizedBox(width: 8),
                              IconButton(
                                icon: Image.asset(
                                  'assets/icons/delete.png',
                                  width: 30,
                                  height: 30,
                                ),
                                onPressed: () async {
                                  final dbHelper = DatabaseHelper();
                                  await dbHelper.deleteUser(usuario['id']);
                                  _loadUsuarios();
                                },
                              ),
                            ],
                          ),
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CrearUsuarioScreen(),
                                ),
                              );
                              _loadUsuarios();
                            },
                            icon: Image.asset(
                              'assets/icons/add-user.png',
                              width: 30,
                              height: 30,
                            ),
                            label: Text('Crear nuevo usuario'),
                          ),
                        );
                      }
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
