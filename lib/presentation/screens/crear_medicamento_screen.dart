import 'package:flutter/material.dart';
import '/database/database_helper.dart';
import '/presentation/screens/alertas_toma_medicacion.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class CrearMedicamentoScreen extends StatefulWidget {
  final int idUsuario;
  final int? idPatologia;

  const CrearMedicamentoScreen({
    super.key,
    required this.idUsuario,
    this.idPatologia,
  });

  @override
  _CrearMedicamentoScreenState createState() => _CrearMedicamentoScreenState();
}

class _CrearMedicamentoScreenState extends State<CrearMedicamentoScreen> {
  final TextEditingController _cnController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _pactivosController = TextEditingController();
  final TextEditingController _labtitularController = TextEditingController();
  final TextEditingController _labcomercialController = TextEditingController();
  final TextEditingController _recetaController = TextEditingController();
  final TextEditingController _viaAdminController = TextEditingController();
  final TextEditingController _formaFarmaceuticaController =
      TextEditingController();

  final TextEditingController _desayunoController = TextEditingController();
  final TextEditingController _comidaController = TextEditingController();
  final TextEditingController _cenaController = TextEditingController();

  final TextEditingController _duracionController = TextEditingController();

  String? _prospectoUrl;
  bool _modoManual = false;

  Future<void> fetchMedicamento(String cn) async {
    final url = Uri.parse('https://cima.aemps.es/cima/rest/medicamento?cn=$cn');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _cnController.text =
              data['presentaciones']?.isNotEmpty == true
                  ? data['presentaciones'][0]['cn'] ?? cn
                  : cn;
          _nombreController.text = data['nombre'] ?? '';
          _pactivosController.text =
              (data['principiosActivos'] as List<dynamic>?)
                  ?.map((e) => e['nombre'])
                  .join(', ') ??
              '';
          _labtitularController.text = data['labtitular'] ?? '';
          _labcomercialController.text = data['labcomercializador'] ?? '';
          _recetaController.text = data['cpresc'] ?? '';
          _viaAdminController.text =
              (data['viasAdministracion'] as List<dynamic>?)
                  ?.map((e) => e['nombre'])
                  .join(', ') ??
              '';
          _formaFarmaceuticaController.text =
              data['formaFarmaceutica']?['nombre'] ?? '';
          _prospectoUrl =
              data['docs']?.length > 1 ? data['docs'][1]['urlHtml'] : null;
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Código no encontrado en CIMA')));
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al conectar con CIMA')));
    }
  }

  Future<bool> _guardarMedicamento() async {
    final cn = _cnController.text.trim();
    final nombre = _nombreController.text.trim();
    final desayuno = _desayunoController.text.trim();
    final comida = _comidaController.text.trim();
    final cena = _cenaController.text.trim();
    final duracion = int.tryParse(_duracionController.text.trim());

    if (cn.isEmpty ||
        desayuno.isEmpty ||
        comida.isEmpty ||
        cena.isEmpty ||
        duracion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Completa los campos obligatorios')),
      );
      return false;
    }

    try {
      await DatabaseHelper().insertarMedicamento(
        nombre: nombre,
        cn: cn,
        idPatologia: widget.idPatologia ?? widget.idUsuario,
        pautaDesayuno: desayuno,
        pautaComida: comida,
        pautaCena: cena,
        duracion: duracion,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Medicamento guardado correctamente')),
      );

      Navigator.pop(context);
      return true;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      return false;
    }
  }

  Widget buildReadOnlyField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(labelText: label),
      enabled: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 211, 211, 236),
      appBar: AppBar(title: Text('Nuevo Medicamento')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _modoManual = false;
                        });
                      },
                      child: Text('Escanear Medicamento'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _modoManual = true;
                        });
                      },
                      child: Text('Introducir Manualmente'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cnController,
                      enabled: _modoManual,
                      decoration: InputDecoration(
                        labelText: 'Código Nacional *',
                      ),
                    ),
                  ),
                  if (_modoManual)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          final cn = _cnController.text.trim();
                          if (cn.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Introduce el Código Nacional'),
                              ),
                            );
                            return;
                          }
                          fetchMedicamento(cn);
                        },
                        child: Text('Buscar'),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              buildReadOnlyField(_nombreController, 'Nombre'),
              buildReadOnlyField(_pactivosController, 'Principios activos'),
              buildReadOnlyField(_labtitularController, 'Lab. Titular'),
              buildReadOnlyField(
                _labcomercialController,
                'Lab. Comercializador',
              ),
              buildReadOnlyField(_recetaController, 'Prescripción'),
              buildReadOnlyField(_viaAdminController, 'Vía administración'),
              buildReadOnlyField(
                _formaFarmaceuticaController,
                'Forma farmacéutica',
              ),

              if (_prospectoUrl != null && _prospectoUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: InkWell(
                    onTap: () async {
                      final uri = Uri.parse(_prospectoUrl!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('No se pudo abrir el prospecto'),
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Ver Prospecto',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                'Pauta',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Flexible(
                    child: TextField(
                      controller: _desayunoController,
                      decoration: InputDecoration(labelText: 'Desayuno *'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: TextField(
                      controller: _comidaController,
                      decoration: InputDecoration(labelText: 'Comida *'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: TextField(
                      controller: _cenaController,
                      decoration: InputDecoration(labelText: 'Cena *'),
                    ),
                  ),
                ],
              ),

              TextField(
                controller: _duracionController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Duración (días) *'),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () async {
                  bool exito = await _guardarMedicamento();
                  if (exito) {
                    if (!mounted) return;
                    await AlertasTomaMedicacion.cancelAllNotifications();
                    await AlertasTomaMedicacion.reprogramarNotificacionesDesdeBBDD(
                      widget.idUsuario,
                    );
                  }
                },
                child: Text("Guardar Medicamento"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
