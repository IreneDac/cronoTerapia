import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/database/database_helper.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '/presentation/screens/alertas_toma_medicacion.dart';

class EditarMedicamentoScreen extends StatefulWidget {
  final Map<String, dynamic> medicamento;
  final int idUsuario;

  const EditarMedicamentoScreen({
    super.key,
    required this.medicamento,
    required this.idUsuario,
  });

  @override
  State<EditarMedicamentoScreen> createState() =>
      _EditarMedicamentoScreenState();
}

class _EditarMedicamentoScreenState extends State<EditarMedicamentoScreen> {
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

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  Map<String, List<Map<String, dynamic>>> _efectosAgrupados = {};
  String? _categoriaSeleccionada;
  int? _efectoSecundarioIdSeleccionado;

  @override
  void initState() {
    super.initState();

    _cnController.text = widget.medicamento['cn'] ?? '';
    _nombreController.text = widget.medicamento['nombre'] ?? '';
    _pactivosController.text = widget.medicamento['principiosActivos'] ?? '';
    _labtitularController.text = widget.medicamento['labtitular'] ?? '';
    _labcomercialController.text =
        widget.medicamento['labcomercializador'] ?? '';
    _recetaController.text = widget.medicamento['prescripcion'] ?? '';
    _viaAdminController.text = widget.medicamento['viaAdministracion'] ?? '';
    _formaFarmaceuticaController.text =
        widget.medicamento['formaFarmaceutica'] ?? '';
    _desayunoController.text = widget.medicamento['pautaDesayuno'].toString();
    _comidaController.text = widget.medicamento['pautaComida'].toString();
    _cenaController.text = widget.medicamento['pautaCena'].toString();
    _duracionController.text = widget.medicamento['duracion']?.toString() ?? '';
    _efectoSecundarioIdSeleccionado = widget.medicamento['idEfectoAdverso'];

    _fetchMedicamento(_cnController.text);
    _cargarEfectosSecundarios();
  }

  Future<void> _cargarEfectosSecundarios() async {
    final efectos = await obtenerEfectosAgrupados();

    setState(() {
      _efectosAgrupados = efectos;
      _categoriaSeleccionada =
          efectos.keys.isNotEmpty ? efectos.keys.first : null;
      if (_efectoSecundarioIdSeleccionado != null) {
        for (var categoria in efectos.keys) {
          if (efectos[categoria]!.any(
            (ef) => ef['id'] == _efectoSecundarioIdSeleccionado,
          )) {
            _categoriaSeleccionada = categoria;
            break;
          }
        }
      }
    });
  }

  Future<Map<String, List<Map<String, dynamic>>>>
  obtenerEfectosAgrupados() async {
    final db = await DatabaseHelper().database;
    final resultados = await db.query('EfectosSecundarios');

    Map<String, List<Map<String, dynamic>>> agrupados = {};

    for (var fila in resultados) {
      final categoria = fila['categoria'] as String;
      final efecto = fila['efectoAdverso'] as String;
      final id = fila['id'] as int;

      if (!agrupados.containsKey(categoria)) {
        agrupados[categoria] = [];
      }

      agrupados[categoria]!.add({'id': id, 'nombre': efecto});
    }

    return agrupados;
  }

  Future<void> _fetchMedicamento(String cn) async {
    final url = Uri.parse('https://cima.aemps.es/cima/rest/medicamento?cn=$cn');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _nombreController.text = data['nombre'] ?? _nombreController.text;
          _pactivosController.text =
              (data['principiosActivos'] as List<dynamic>?)
                  ?.map((e) => e['nombre'])
                  .join(', ') ??
              _pactivosController.text;
          _labtitularController.text =
              data['labtitular'] ?? _labtitularController.text;
          _labcomercialController.text =
              data['labcomercializador'] ?? _labcomercialController.text;
          _recetaController.text = data['cpresc'] ?? _recetaController.text;
          _viaAdminController.text =
              (data['viasAdministracion'] as List<dynamic>?)
                  ?.map((e) => e['nombre'])
                  .join(', ') ??
              _viaAdminController.text;
          _formaFarmaceuticaController.text =
              data['formaFarmaceutica']?['nombre'] ??
              _formaFarmaceuticaController.text;
          _prospectoUrl =
              data['docs'] != null && data['docs'].length > 1
                  ? data['docs'][1]['urlHtml']
                  : null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo obtener información del medicamento'),
          ),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al conectar con CIMA')));
    }
  }

  Future<void> _guardarCambios() async {
    final nombre = _nombreController.text.trim();
    final cn = _cnController.text.trim();
    final desayuno = _desayunoController.text.trim();
    final comida = _comidaController.text.trim();
    final cena = _cenaController.text.trim();
    final duracionText = _duracionController.text.trim();

    if (nombre.isEmpty ||
        cn.isEmpty ||
        desayuno.isEmpty ||
        comida.isEmpty ||
        cena.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Todos los campos son obligatorios')),
      );
      return;
    }

    if (_efectoSecundarioIdSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selecciona un efecto secundario')),
      );
      return;
    }

    int? duracion = int.tryParse(duracionText);
    if (duracion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Duración debe ser un número entero válido')),
      );
      return;
    }

    await DatabaseHelper().actualizarMedicamento(
      id: widget.medicamento['id'],
      nombre: nombre,
      cn: cn,
      pautaDesayuno: desayuno,
      pautaComida: comida,
      pautaCena: cena,
      duracion: duracion,
      idEfectoAdverso: _efectoSecundarioIdSeleccionado,
    );

    await AlertasTomaMedicacion.cancelAllNotifications();
    await AlertasTomaMedicacion.reprogramarNotificacionesDesdeBBDD(
      widget.idUsuario,
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Medicamento actualizado')));

    Navigator.pop(context);
  }

  Widget buildReadOnlyField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget buildDateSelector(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          date == null ? 'Selecciona fecha' : _dateFormat.format(date),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 211, 211, 236),
      appBar: AppBar(title: Text('Editar Medicamento')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              buildReadOnlyField(_cnController, 'Código Nacional'),
              buildReadOnlyField(_nombreController, 'Nombre del medicamento'),
              buildReadOnlyField(_pactivosController, 'Principios activos'),
              buildReadOnlyField(_labtitularController, 'Lab. Titular'),
              buildReadOnlyField(
                _labcomercialController,
                'Lab. Comercializador',
              ),
              buildReadOnlyField(_recetaController, 'Prescripción'),
              buildReadOnlyField(_viaAdminController, 'Vía de administración'),
              buildReadOnlyField(
                _formaFarmaceuticaController,
                'Forma farmacéutica',
              ),
              if (_prospectoUrl != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      if (await canLaunchUrl(Uri.parse(_prospectoUrl!))) {
                        await launchUrl(Uri.parse(_prospectoUrl!));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('No se pudo abrir el prospecto'),
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.picture_as_pdf),
                    label: Text('Prospecto'),
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
                  Expanded(
                    child: TextField(
                      controller: _desayunoController,
                      decoration: InputDecoration(labelText: 'Desayuno'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _comidaController,
                      decoration: InputDecoration(labelText: 'Comida'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _cenaController,
                      decoration: InputDecoration(labelText: 'Cena'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _duracionController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Duración (días)'),
              ),

              if (_efectosAgrupados.isNotEmpty &&
                  _categoriaSeleccionada != null) ...[
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Efectos secundarios',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: _categoriaSeleccionada,
                  items:
                      _efectosAgrupados.keys
                          .map(
                            (categoria) => DropdownMenuItem(
                              value: categoria,
                              child: Text(categoria),
                            ),
                          )
                          .toList(),
                  onChanged: (valor) {
                    setState(() {
                      _categoriaSeleccionada = valor;
                      _efectoSecundarioIdSeleccionado = null;
                    });
                  },
                ),
                const SizedBox(height: 8),
                DropdownButton<int>(
                  value: _efectoSecundarioIdSeleccionado,
                  hint: Text('Selecciona efecto secundario'),
                  items:
                      _efectosAgrupados[_categoriaSeleccionada]!
                          .map(
                            (efecto) => DropdownMenuItem(
                              value: efecto['id'] as int,
                              child: Text(efecto['nombre'] as String),
                            ),
                          )
                          .toList(),
                  onChanged: (valor) {
                    setState(() {
                      _efectoSecundarioIdSeleccionado = valor;
                    });
                  },
                ),
              ],

              const SizedBox(height: 30),
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
