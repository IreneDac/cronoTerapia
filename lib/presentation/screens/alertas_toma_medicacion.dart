import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '/database/database_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AlertasTomaMedicacion {
  static int _idUsuario = 0;

  static final flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const androidInitSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final initSettings = InitializationSettings(android: androidInitSettings);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    //Programación de notificaciones de Toma de medicación
    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final int id = response.id ?? 0;
        final int baseId = id >= 1000 ? id - 1000 : id;
        final actionId = response.actionId;
        final String? payload = response.payload;

        print('CALLBACK ejecutado — Acción: $actionId — ID: $id');

        // Cancelar ambas notificaciones: principal y seguimiento
        await flutterLocalNotificationsPlugin.cancel(baseId);
        await flutterLocalNotificationsPlugin.cancel(baseId + 1000);

        if (actionId == 'take_medication') {
          print("Medicación marcada como tomada");
          print(payload);
          if (payload != null) {
            final partes = payload.split('|');
            final momento = partes.length > 1 ? partes[1] : '';
            final nombreMedicamento = partes.length > 2 ? partes[2] : '';
            await DatabaseHelper().guardarRegistroMedicacionTomada(
              idNotificacion: id,
              nombreMedicamento: nombreMedicamento,
              momento: momento,
              fechaHora: DateTime.now(),
              idUsuario: _idUsuario,
              accion: 'Tomada',
            );

            //Por cada medicamento, actualizo la duración
            List<String> listaMedicamentos = nombreMedicamento.split(',');

            listaMedicamentos = listaMedicamentos.map((n) => n.trim()).toList();
            print(listaMedicamentos);
            for (String medicamento in listaMedicamentos) {
              await DatabaseHelper().actualizarDuracionMedicamentoPorNombre(
                idUsuario: _idUsuario,
                nombreMedicamento: medicamento,
                tipoPauta: momento,
              );
            }

            //Compruebo si al medicamento le quedan menos de 5 pastillas y si hay falta suministro
            for (String medicamento in listaMedicamentos) {
              final datos = await DatabaseHelper()
                  .getCnDiasPorNombreMedicamento(medicamento);
              if (datos != null) {
                final int? dias = datos['diasMedicamento'] as int?;
                if (dias != null && dias < 5) {
                  final String? cn = datos['cn']?.toString();

                  final url = Uri.parse(
                    'https://cima.aemps.es/cima/rest/psuministro/$cn',
                  );

                  try {
                    final response = await http.get(url);
                    if (response.statusCode == 200) {
                      final data = json.decode(response.body);
                      final resultados = data['resultados'] as List<dynamic>?;

                      if (resultados != null && resultados.isNotEmpty) {
                        mostrarNotificacion(
                          titulo:
                              'Medicamento próximo a agotarse con Falta de suministro',
                          cuerpo: medicamento,
                        );
                      } else {
                        mostrarNotificacion(
                          titulo: 'Medicamento próximo a agotarse',
                          cuerpo: medicamento,
                        );
                      }
                    }
                  } catch (e) {
                    print('Error consultando suministro para cn=$cn: $e');
                  }
                }
              }
            }
          }
        } else if (actionId == 'postpone') {
          print("Posponiendo 10 minutos...");
          print(payload);
          if (payload != null) {
            final partes = payload.split('|');
            final momento = partes.length > 1 ? partes[1] : '';
            final nombreMedicamento = partes.length > 2 ? partes[2] : '';

            //Compruebo si en la última semana ha puesto más de dos veces la toma de medicación para este momento
            final pospuestas = await DatabaseHelper()
                .obtenerAccionesPospuestasSemana(momento);

            await DatabaseHelper().guardarRegistroMedicacionTomada(
              idNotificacion: id,
              nombreMedicamento: nombreMedicamento,
              momento: momento,
              fechaHora: DateTime.now(),
              idUsuario: _idUsuario,
              accion: 'Pospuesta',
            );

            if (pospuestas.isNotEmpty) {
              //guardo el nuevo horario de notificaciones
              final horarios = await DatabaseHelper().obtenerHorariosPorUsuario(
                _idUsuario,
              );
              if (momento == 'desayuno' && horarios != null) {
                String horaDesayunoStr = horarios['desayuno']!;

                List<String> partes = horaDesayunoStr.split(':');
                int hora = int.parse(partes[0]);
                int minuto = int.parse(partes[1]);

                DateTime horaDesayuno = DateTime(0, 1, 1, hora, minuto);

                DateTime horaCon10Min = horaDesayuno.add(
                  const Duration(minutes: 10),
                );

                String horaFinal =
                    "${horaCon10Min.hour.toString().padLeft(2, '0')}:${horaCon10Min.minute.toString().padLeft(2, '0')}";
                await DatabaseHelper().actualizarHorarioDesayuno(
                  idUsuario: _idUsuario,
                  nuevoHorario: horaFinal,
                );
              }
              if (momento == 'comida' && horarios != null) {
                String horaComidaStr = horarios['comida']!;

                List<String> partes = horaComidaStr.split(':');
                int hora = int.parse(partes[0]);
                int minuto = int.parse(partes[1]);

                DateTime horaComida = DateTime(0, 1, 1, hora, minuto);

                DateTime horaCon10Min = horaComida.add(
                  const Duration(minutes: 10),
                );

                String horaFinal =
                    "${horaCon10Min.hour.toString().padLeft(2, '0')}:${horaCon10Min.minute.toString().padLeft(2, '0')}";
                await DatabaseHelper().actualizarHorarioComida(
                  idUsuario: _idUsuario,
                  nuevoHorario: horaFinal,
                );
              } else {
                if (horarios != null) {
                  String horaCenaStr = horarios['cena']!;

                  List<String> partes = horaCenaStr.split(':');
                  int hora = int.parse(partes[0]);
                  int minuto = int.parse(partes[1]);

                  DateTime horaCena = DateTime(0, 1, 1, hora, minuto);

                  DateTime horaCon10Min = horaCena.add(
                    const Duration(minutes: 10),
                  );

                  String horaFinal =
                      "${horaCon10Min.hour.toString().padLeft(2, '0')}:${horaCon10Min.minute.toString().padLeft(2, '0')}";
                  await DatabaseHelper().actualizarHorarioCena(
                    idUsuario: _idUsuario,
                    nuevoHorario: horaFinal,
                  );
                }
              }
              //Reprogramo las notificaciones
              cancelAllNotifications();
              reprogramarNotificacionesDesdeBBDD(_idUsuario);

              //Muestro notificación informando al usuario
              mostrarNotificacion(
                titulo: 'Cambio horario Toma de medicación',
                cuerpo: 'Se ha modificado este horario',
              );
            }

            await _programarNotificacionEn(
              tz.TZDateTime.now(tz.local).add(Duration(minutes: 10)),
              999,
              'Recordatorio (pospuesto)',
              '¿Has tomado tu medicamento: $nombreMedicamento?',
              '999|$momento|$nombreMedicamento',
            );
          } else {
            await _programarNotificacionEn(
              tz.TZDateTime.now(tz.local).add(Duration(minutes: 10)),
              999,
              'Recordatorio (pospuesto)',
              '¿Has tomado tu medicamento?',
              '',
            );
          }
        } else {
          // Usuario tocó la notificación sin seleccionar acción
          print("Notificación tocada sin acción específica");
          print('Payload2');
          print('Payload: $payload');

          if (payload != null && payload.contains('|')) {
            final partes = payload.split('|');
            final momento = partes.length > 1 ? partes[1] : '';
            final nombreMedicamento = partes.length > 2 ? partes[2] : '';
            await DatabaseHelper().guardarRegistroMedicacionTomada(
              idNotificacion: id,
              nombreMedicamento: nombreMedicamento,
              momento: momento,
              fechaHora: DateTime.now(),
              idUsuario: _idUsuario,
              accion: 'Sin acción',
            );
          }
        }
      },
    );
  }

  static Future<void> reprogramarNotificacionesDesdeBBDD(int idUsuario) async {
    _idUsuario = idUsuario;

    await cancelAllNotifications();

    //Recupero los horarios de la tabla Configuración
    final horarios = await DatabaseHelper().obtenerHorariosPorUsuario(
      _idUsuario,
    );

    int horaDesayuno = 9;
    int minutoDesayuno = 0;
    int horaComida = 14;
    int minutoComida = 0;
    int horaCena = 21;
    int minutoCena = 0;
    if (horarios != null) {
      String horaDesayunoStr = horarios['desayuno']!;
      List<String> parteDesayuno = horaDesayunoStr.split(':');
      horaDesayuno = int.parse(parteDesayuno[0]);
      minutoDesayuno = int.parse(parteDesayuno[1]);

      String horaComidaStr = horarios['comida']!;
      List<String> partesComida = horaComidaStr.split(':');
      horaComida = int.parse(partesComida[0]);
      minutoComida = int.parse(partesComida[1]);

      String horaCenatr = horarios['cena']!;
      List<String> partesCena = horaCenatr.split(':');
      horaCena = int.parse(partesCena[0]);
      minutoCena = int.parse(partesCena[1]);
    }

    final patologiasConMedicamentos = await DatabaseHelper()
        .obtenerPatologiasConMedicamentosConPautas(idUsuario);

    List<String> desayunoMedicamentos = [];
    List<String> comidaMedicamentos = [];
    List<String> cenaMedicamentos = [];

    for (var patologia in patologiasConMedicamentos) {
      final medicamentos = patologia['medicamentos'] as List<dynamic>;

      for (var med in medicamentos) {
        final String nombre = med['nombre'] ?? 'Medicamento';
        final desayunoValue =
            num.tryParse(med['pautaDesayuno']?.toString() ?? '0') ?? 0;
        final comidaValue =
            num.tryParse(med['pautaComida']?.toString() ?? '0') ?? 0;
        final cenaValue =
            num.tryParse(med['pautaCena']?.toString() ?? '0') ?? 0;

        if (desayunoValue > 0) {
          desayunoMedicamentos.add(nombre);
        }
        if (comidaValue > 0) {
          comidaMedicamentos.add(nombre);
        }
        if (cenaValue > 0) {
          cenaMedicamentos.add(nombre);
        }
      }
    }

    int idBase = 100;

    Future<void> programarNotificacionSiHay(
      int hora,
      int minuto,
      int id,
      String tipo,
      List<String> nombres,
    ) async {
      if (nombres.isNotEmpty) {
        final cuerpo = nombres.join(', ');
        await _programarNotificacionParaHoraYNombre(
          hora,
          minuto,
          id,
          tipo,
          cuerpo,
        );
      }
    }

    await programarNotificacionSiHay(
      horaDesayuno,
      minutoDesayuno,
      idBase,
      'desayuno',
      desayunoMedicamentos,
    );
    idBase += 1;

    await programarNotificacionSiHay(
      horaComida,
      minutoComida,
      idBase,
      'comida',
      comidaMedicamentos,
    );
    idBase += 1;

    await programarNotificacionSiHay(
      horaCena,
      minutoCena,
      idBase,
      'cena',
      cenaMedicamentos,
    );
    idBase += 1;
  }

  static Future<void> _programarNotificacionParaHoraYNombre(
    int hora,
    int minuto,
    int id,
    String momento,
    String nombreMedicamento,
  ) async {
    final ahora = tz.TZDateTime.now(tz.local);
    var horaProgramada = tz.TZDateTime(
      tz.local,
      ahora.year,
      ahora.month,
      ahora.day,
      hora,
      minuto,
    );

    if (horaProgramada.isBefore(ahora)) {
      horaProgramada = horaProgramada.add(Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      'medication_channel',
      'Recordatorios de Medicación',
      channelDescription: 'Notificaciones diarias de medicamentos',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'drawable/drugs',
      actions: [
        AndroidNotificationAction(
          'take_medication',
          'Medicación tomada',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'postpone',
          'Posponer 10 min',
          showsUserInterface: true,
        ),
      ],
    );

    final details = NotificationDetails(android: androidDetails);

    // Notificación principal
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'Toma tu medicamento: $nombreMedicamento ($momento)',
      'Es hora de tu medicación de $momento',
      horaProgramada,
      details,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: '$id|$momento|$nombreMedicamento',
    );

    // Notificación de seguimiento 1 hora después
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id + 1000,
      '¿Tomaste $nombreMedicamento?',
      'No se ha registrado que hayas tomado la medicación.',
      horaProgramada.add(Duration(hours: 1)),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: '$id|$momento|$nombreMedicamento',
    );
  }

  static Future<void> _programarNotificacionEn(
    tz.TZDateTime fecha,
    int id,
    String titulo,
    String mensaje,
    String payload,
  ) async {
    final androidDetails = AndroidNotificationDetails(
      'medication_channel',
      'Recordatorios de Medicación',
      channelDescription: 'Notificaciones diarias de medicamentos',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'drawable/drugs',
      actions: [
        AndroidNotificationAction(
          'take_medication',
          'Medicación tomada',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'postpone',
          'Posponer 10 min',
          showsUserInterface: true,
        ),
      ],
    );

    final details = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      titulo,
      mensaje,
      fecha,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id + 1000,
      '¡Olvidaste tomar tu medicamento!',
      'No se ha registrado que hayas tomado la medicación.',
      fecha.add(Duration(hours: 1)),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: fecha.toString(),
    );
  }

  static Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('Todas las notificaciones programadas han sido canceladas.');
  }

  static Future<void> checkPendingNotifications() async {
    final List<PendingNotificationRequest> pendingNotificationRequests =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    debugPrint('--- Notificaciones Pendientes ---');
    if (pendingNotificationRequests.isEmpty) {
      debugPrint('No hay notificaciones pendientes.');
    } else {
      for (var pending in pendingNotificationRequests) {
        debugPrint(
          'ID: ${pending.id}, Título: ${pending.title}, Cuerpo: ${pending.body}, Payload: ${pending.payload}',
        );
      }
    }
    debugPrint('--- Fin Notificaciones Pendientes ---');
  }

  static Future<void> mostrarNotificacion({
    required String titulo,
    required String cuerpo,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'falta_suministro_channel',
          'Falta de suministro',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'drawable/drugs',
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      titulo,
      cuerpo,
      platformChannelSpecifics,
    );
  }
}
