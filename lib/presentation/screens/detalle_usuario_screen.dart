import 'package:flutter/material.dart';
import 'package:flutter_application_1/presentation/screens/registro_informes_medicos_screen.dart';
import '/presentation/screens/tratamientos_screen.dart';
import '/presentation/screens/hoja_medicacion_screen.dart';
import '/presentation/screens/alertas_toma_medicacion.dart';
import '/presentation/screens/cumplimientos_screen.dart';
import '/presentation/screens/pastillero_screen.dart';
import '/presentation/screens/lista_compra_screen.dart';
import '/presentation/screens/problemas_suministro_screen.dart';
import '/presentation/screens/alertas_personalizadas_screen.dart';
import '/presentation/screens/revision_mensual_screen.dart';
import '/presentation/screens/configuracion_screen.dart';

class DetalleUsuarioScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const DetalleUsuarioScreen({super.key, required this.usuario});

  @override
  State<DetalleUsuarioScreen> createState() => _DetalleUsuarioScreenState();
}

class _DetalleUsuarioScreenState extends State<DetalleUsuarioScreen> {
  @override
  Widget build(BuildContext context) {
    final List<Widget> botones = [
      _botonCuadrado(
        icon: Image.asset('assets/icons/drugs.png', width: 40, height: 40),
        label: 'Tratamientos',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      TratamientosScreen(idUsuario: widget.usuario['id']),
            ),
          );
        },
      ),
      _botonCuadrado(
        icon: Image.asset('assets/icons/compliance.png', width: 40, height: 40),
        label: 'Cumplimientos',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      CumplimientosScreen(idUsuario: widget.usuario['id']),
            ),
          );
        },
      ),
      _botonCuadrado(
        icon: Image.asset('assets/icons/evaluation.png', width: 40, height: 40),
        label: 'Hoja medicación',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => HojaMedicacionScreen(
                    idUsuario: widget.usuario['id'],
                    nombre: widget.usuario['nombre'],
                    apellidos: widget.usuario['apellidos'],
                  ),
            ),
          );
        },
      ),
      _botonCuadrado(
        icon: Image.asset('assets/icons/pill-box.png', width: 40, height: 40),
        label: 'Pastillero',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      PastilleroScreen(idUsuario: widget.usuario['id']),
            ),
          );
        },
      ),
      _botonCuadrado(
        icon: Image.asset(
          'assets/icons/shopping-cart.png',
          width: 40,
          height: 40,
        ),
        label: 'Lista de compra',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ListaCompraMedicamentosScreen(
                    idUsuario: widget.usuario['id'],
                  ),
            ),
          );
        },
      ),
      _botonCuadrado(
        icon: Image.asset('assets/icons/risk.png', width: 40, height: 40),
        label: 'Problemas de suministro',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => MedicamentosFaltaSuministroScreen(
                    idUsuario: widget.usuario['id'],
                  ),
            ),
          );
        },
      ),
      _botonCuadrado(
        icon: Image.asset('assets/icons/crisis.png', width: 40, height: 40),
        label: 'Alertas personalizadas',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => AlertasPersonalizadasScreen(
                    idUsuario: widget.usuario['id'],
                  ),
            ),
          );
        },
      ),
      _botonCuadrado(
        icon: Image.asset('assets/icons/review.png', width: 40, height: 40),
        label: 'Revisión mensual del tratamiento',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      RevisionMensualScreen(idUsuario: widget.usuario['id']),
            ),
          );
        },
      ),
      _botonCuadrado(
        icon: Image.asset(
          'assets/icons/medical-file.png',
          width: 40,
          height: 40,
        ),
        label: 'Informes médicos',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PdfManagerScreen()),
          );
        },
      ),
      _botonCuadrado(
        icon: Icon(Icons.add_alert, size: 48),
        label: 'Alertas',
        onPressed: () async {
          await AlertasTomaMedicacion.checkPendingNotifications();
        },
      ),
      _botonCuadrado(
        icon: Icon(Icons.add_alert, size: 48),
        label: 'Cancelar Notificaciones',
        onPressed: () async {
          await AlertasTomaMedicacion.cancelAllNotifications();
        },
      ),
    ];

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 211, 211, 236),
      appBar: AppBar(
        title: Text(
          '${widget.usuario['nombre']} ${widget.usuario['apellidos']}',
        ),
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/icons/settings.png',
              width: 40,
              height: 40,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          ConfiguracionScreen(idUsuario: widget.usuario['id']),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,
                children: botones,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botonCuadrado({
    required Widget icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
