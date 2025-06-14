import 'package:flutter/material.dart';
import '/database/database_helper.dart';

class CrearPatologiaScreen extends StatelessWidget {
  final int idUsuario;

  const CrearPatologiaScreen({super.key, required this.idUsuario});

  @override
  Widget build(BuildContext context) {
    final TextEditingController nombreController = TextEditingController();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 211, 211, 236),
      appBar: AppBar(title: Text('Nueva Patología')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nombreController,
              decoration: InputDecoration(labelText: 'Nombre de la patología'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Guardar'),
              onPressed: () async {
                final nombre = nombreController.text.trim();
                if (nombre.isNotEmpty) {
                  await DatabaseHelper().insertarPatologia(nombre, idUsuario);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
