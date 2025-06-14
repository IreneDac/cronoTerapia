import 'package:flutter/material.dart';
import '/database/database_helper.dart';

class CrearUsuarioScreen extends StatefulWidget {
  const CrearUsuarioScreen({super.key});

  @override
  _CrearUsuarioScreenState createState() => _CrearUsuarioScreenState();
}

class _CrearUsuarioScreenState extends State<CrearUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();

  final dbHelper = DatabaseHelper();

  Future<void> _guardarUsuario() async {
    if (_formKey.currentState!.validate()) {
      final nombre = _nombreController.text.trim();
      final apellidos = _apellidosController.text.trim();

      final int idUsuario = await dbHelper.insertUser(nombre, apellidos);

      await dbHelper.guardarHorarioNotificaciones(
        idUsuario,
        desayuno: '09:00',
        comida: '14:00',
        cena: '21:00',
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 211, 211, 236),
      appBar: AppBar(title: Text('Nuevo Usuario')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(labelText: 'Nombre'),
                validator:
                    (value) => value!.isEmpty ? 'Introduce el nombre' : null,
              ),
              TextFormField(
                controller: _apellidosController,
                decoration: InputDecoration(labelText: 'Apellidos'),
                validator:
                    (value) =>
                        value!.isEmpty ? 'Introduce los apellidos' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _guardarUsuario,
                child: Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
