import 'package:flutter/material.dart';
import '/database/database_helper.dart';

class EditarUsuarioScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const EditarUsuarioScreen({super.key, required this.usuario});

  @override
  _EditarUsuarioScreenState createState() => _EditarUsuarioScreenState();
}

class _EditarUsuarioScreenState extends State<EditarUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _apellidosController;
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.usuario['nombre']);
    _apellidosController = TextEditingController(
      text: widget.usuario['apellidos'],
    );
  }

  Future<void> _actualizarUsuario() async {
    if (_formKey.currentState!.validate()) {
      final nombre = _nombreController.text.trim();
      final apellidos = _apellidosController.text.trim();

      await dbHelper.updateUser(
        id: widget.usuario['id'],
        nombre: nombre,
        apellidos: apellidos,
      );

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 211, 211, 236),
      appBar: AppBar(title: Text('Editar Usuario')),
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
                onPressed: _actualizarUsuario,
                child: Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
