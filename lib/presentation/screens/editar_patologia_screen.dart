import 'package:flutter/material.dart';
import '/database/database_helper.dart';

class EditarPatologiaScreen extends StatefulWidget {
  final Map<String, dynamic> patologia;

  const EditarPatologiaScreen({super.key, required this.patologia});

  @override
  State<EditarPatologiaScreen> createState() => _EditarPatologiaScreenState();
}

class _EditarPatologiaScreenState extends State<EditarPatologiaScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.patologia['nombre']);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (_formKey.currentState!.validate()) {
      final nuevoNombre = _nombreController.text.trim();

      await DatabaseHelper().actualizarPatologia(
        widget.patologia['id'],
        nuevoNombre,
      );

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 211, 211, 236),
      appBar: AppBar(title: Text('Editar Patología')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre de la patología',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa un nombre';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _guardarCambios,
                child: Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
