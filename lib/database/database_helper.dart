import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'AplicacionMedicamentos.db');

    //final exists = await databaseExists(path);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Crear tabla Usuario
        await db.execute('''
          CREATE TABLE Usuario (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            apellidos TEXT NOT NULL
          )
        ''');

        // Crear tabla Configuracion
        await db.execute('''
          CREATE TABLE Configuracion (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            horarioNotifDesayuno TEXT NOT NULL,
            horarioNotifComida TEXT NOT NULL,
            horarioNotifCena TEXT NOT NULL,
            idUsuario INTEGER NOT NULL,
            FOREIGN KEY(idUsuario) REFERENCES Usuario(id)
          )
        ''');

        // Crear tabla Patologías
        await db.execute('''
          CREATE TABLE Patologias (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            idUsuario INTEGER NOT NULL,
            FOREIGN KEY(idUsuario) REFERENCES Usuario(id)
          )
        ''');

        // Crear tabla Medicamentos
        await db.execute('''
          CREATE TABLE Medicamentos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            cn TEXT NOT NULL,
            idPatologia INTEGER NOT NULL,
            pautaDesayuno INTEGER,
            pautaComida INTEGER,
            pautaCena INTEGER,
            duracion INTEGER,    
            diasMedicamento INTEGER,
            idEfectoAdverso INTEGER,
            FOREIGN KEY(idPatologia) REFERENCES Patologias(id),
            FOREIGN KEY(idEfectoAdverso) REFERENCES EfectosSecundariosa(id)
          )
        ''');

        // Crear tabla Efectos Secundarios
        await db.execute('''
          CREATE TABLE EfectosSecundarios (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            categoria TEXT,
            efectoAdverso TEXT NOT NULL
          )
        ''');

        await db.execute('''
          INSERT INTO EfectosSecundarios (id, categoria, efectoAdverso) VALUES
          (1, 'Común', 'Náuseas'),
          (2, 'Común', 'Vómitos'),
          (3, 'Común', 'Diarrea'),
          (4, 'Común', 'Estreñimiento'),
          (5,'Común', 'Dolor de cabeza'),
          (6, 'Común', 'Mareos'),
          (7, 'Común', 'Somnolencia/Sedación'),
          (8, 'Común', 'Fatiga'),
          (9, 'Común', 'Cambios en el apetito'),
          (10, 'Común', 'Insomnio'),
          (11, 'Dermatológicos', 'Erupción cutánea'),     
          (12, 'Digestivas', 'Dolor abdmoninal'),
          (13, 'Neurológicos', 'Temblores'),
          (14, 'Neurológicos', 'Depresión'),
          (15, 'Cardiovasculares', 'Palpitaciones'),
          (16, 'Cardiovasculares', 'Hipertensión'),
          (17, 'Cardiovasculares', 'Hipotensión');

        ''');

        // Crear tabla Registro Medicacion
        await db.execute('''
          CREATE TABLE RegistroMedicacion (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            idNotificacion INTEGER,
            nombreMedicamento TEXT NOT NULL,
            momento TEXT NOT NULL,
            fechaHora TEXT,
            accion TEXT,
            idUsuario INTEGER NOT NULL,
            FOREIGN KEY(idUsuario) REFERENCES Usuario(id)
          )
        ''');
      },
    );
  }

  Future<List<Map<String, dynamic>>> getAllUsuarios() async {
    final db = await database;
    return await db.query('Usuario');
  }

  Future<int> insertUser(String nombre, String apellidos) async {
    final db = await database;
    final id = await db.insert('Usuario', {
      'nombre': nombre,
      'apellidos': apellidos,
    });
    return id;
  }

  Future<void> guardarHorarioNotificaciones(
    int idUsuario, {
    required String desayuno,
    required String comida,
    required String cena,
  }) async {
    final db = await database;

    await db.insert('Configuracion', {
      'idUsuario': idUsuario,
      'horarioNotifDesayuno': desayuno,
      'horarioNotifComida': comida,
      'horarioNotifCena': cena,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateUser({
    required int id,
    required String nombre,
    required String apellidos,
  }) async {
    final db = await database;
    await db.update(
      'Usuario',
      {'nombre': nombre, 'apellidos': apellidos},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteUser(int id) async {
    final db = await database;
    await db.delete('Usuario', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, String>?> obtenerHorariosPorUsuario(int idUsuario) async {
    final db = await DatabaseHelper().database;

    final resultado = await db.query(
      'Configuracion',
      columns: [
        'horarioNotifDesayuno',
        'horarioNotifComida',
        'horarioNotifCena',
      ],
      where: 'idUsuario = ?',
      whereArgs: [idUsuario],
    );

    if (resultado.isNotEmpty) {
      final fila = resultado.first;
      return {
        'desayuno': fila['horarioNotifDesayuno'] as String,
        'comida': fila['horarioNotifComida'] as String,
        'cena': fila['horarioNotifCena'] as String,
      };
    } else {
      return null;
    }
  }

  Future<void> actualizarHorarioDesayuno({
    required int idUsuario,
    required String nuevoHorario,
  }) async {
    final db = await DatabaseHelper().database;

    await db.update(
      'Configuracion',
      {'horarioNotifDesayuno': nuevoHorario},
      where: 'idUsuario = ?',
      whereArgs: [idUsuario],
    );
  }

  Future<void> actualizarHorarioComida({
    required int idUsuario,
    required String nuevoHorario,
  }) async {
    final db = await DatabaseHelper().database;

    await db.update(
      'Configuracion',
      {'horarioNotifComida': nuevoHorario},
      where: 'idUsuario = ?',
      whereArgs: [idUsuario],
    );
  }

  Future<void> actualizarHorarioCena({
    required int idUsuario,
    required String nuevoHorario,
  }) async {
    final db = await DatabaseHelper().database;

    await db.update(
      'Configuracion',
      {'horarioNotifCena': nuevoHorario},
      where: 'idUsuario = ?',
      whereArgs: [idUsuario],
    );
  }

  Future<void> insertarMedicamento({
    required String nombre,
    required String cn,
    required int idPatologia,
    required String pautaDesayuno,
    required String pautaComida,
    required String pautaCena,
    required int duracion,
  }) async {
    final db = await database;
    await db.insert('medicamentos', {
      'nombre': nombre,
      'cn': cn,
      'idPatologia': idPatologia,
      'pautaDesayuno': pautaDesayuno,
      'pautaComida': pautaComida,
      'pautaCena': pautaCena,
      'duracion': duracion,
      'diasMedicamento': duracion,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getMedicamentosPorPatologia(
    int idPatologia,
  ) async {
    final db = await database;
    return await db.query(
      'Medicamentos',
      where: 'idPatologia = ?',
      whereArgs: [idPatologia],
    );
  }

  Future<void> eliminarMedicamento(int id) async {
    final db = await database;
    await db.delete('Medicamentos', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> actualizarMedicamento({
    required int id,
    required String nombre,
    required String cn,
    required String pautaDesayuno,
    required String pautaComida,
    required String pautaCena,
    required int duracion,
    int? idEfectoAdverso,
  }) async {
    final db = await database;

    await db.update(
      'Medicamentos',
      {
        'nombre': nombre,
        'cn': cn,
        'pautaDesayuno': pautaDesayuno,
        'pautaComida': pautaComida,
        'pautaCena': pautaCena,
        'duracion': duracion,
        'idEfectoAdverso': idEfectoAdverso,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> actualizarDiasMedicamento({
    required int id,
    required int diasMedicamento,
  }) async {
    final db = await database;

    await db.update(
      'Medicamentos',
      {'diasMedicamento': diasMedicamento},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getPatologiasPorUsuario(
    int idUsuario,
  ) async {
    final db = await database;
    return await db.query(
      'Patologias',
      where: 'idUsuario = ?',
      whereArgs: [idUsuario],
    );
  }

  Future<List<Map<String, dynamic>>> geMedicamentosPorPatologia(
    int idPatologia,
  ) async {
    final db = await database;
    return await db.query(
      'Medicamentos',
      where: 'idPatologia = ?',
      whereArgs: [idPatologia],
    );
  }

  Future<Map<String, dynamic>?> getCnDiasPorNombreMedicamento(
    String nombre,
  ) async {
    final db = await DatabaseHelper().database;
    final resultado = await db.query(
      'Medicamentos',
      columns: ['cn', 'diasMedicamento'],
      where: 'nombre = ?',
      whereArgs: [nombre],
    );

    if (resultado.isNotEmpty) {
      return {
        'cn': resultado.first['cn'] as String,
        'diasMedicamento': resultado.first['diasMedicamento'] as int,
      };
    } else {
      return null;
    }
  }

  Future<void> insertarPatologia(String nombre, int idUsuario) async {
    final db = await database;
    await db.insert('Patologias', {
      'nombre': nombre,
      'idUsuario': idUsuario,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> actualizarPatologia(int id, String nuevoNombre) async {
    final db = await database;
    return await db.update(
      'Patologias',
      {'nombre': nuevoNombre},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> eliminarPatologia(int idPatologia) async {
    final db = await database;

    await db.delete(
      'Medicamentos',
      where: 'idPatologia = ?',
      whereArgs: [idPatologia],
    );

    await db.delete('Patologias', where: 'id = ?', whereArgs: [idPatologia]);
  }

  Future<List<Map<String, dynamic>>> obtenerPatologiasConMedicamentos(
    int idUsuario,
  ) async {
    final db = await database;

    final patologias = await db.query(
      'Patologias',
      where: 'idUsuario = ?',
      whereArgs: [idUsuario],
    );

    List<Map<String, dynamic>> resultado = [];

    for (var patologia in patologias) {
      final medicamentos = await db.query(
        'Medicamentos',
        where: 'idPatologia = ?',
        whereArgs: [patologia['id']],
      );

      resultado.add({
        'nombre': patologia['nombre'],
        'medicamentos':
            medicamentos.map((m) => m['nombre'].toString()).toList(),
      });
    }

    return resultado;
  }

  Future<List<Map<String, dynamic>>> obtenerMedicamentosPorUsuario(
    int idUsuario,
  ) async {
    final db = await database;

    return await db.rawQuery(
      '''
    SELECT m.*
    FROM medicamentos m
    JOIN patologias p ON m.idPatologia = p.id
    WHERE p.idUsuario = ?
  ''',
      [idUsuario],
    );
  }

  Future<List<Map<String, dynamic>>> obtenerPatologiasConMedicamentosConPautas(
    int idUsuario,
  ) async {
    final db = await database;
    final patologias = await db.query(
      'Patologias',
      where: 'idUsuario = ?',
      whereArgs: [idUsuario],
    );

    List<Map<String, dynamic>> resultado = [];

    for (var patologia in patologias) {
      final medicamentos = await db.query(
        'Medicamentos',
        where: 'idPatologia = ?',
        whereArgs: [patologia['id']],
      );

      List<Map<String, dynamic>> listaMedicamentos =
          medicamentos.map((m) {
            return {
              'nombre': m['nombre'].toString(),
              'pautaDesayuno': m['pautaDesayuno']?.toString() ?? '',
              'pautaComida': m['pautaComida']?.toString() ?? '',
              'pautaCena': m['pautaCena']?.toString() ?? '',
            };
          }).toList();

      resultado.add({'medicamentos': listaMedicamentos});
    }

    return resultado;
  }

  Future<void> guardarRegistroMedicacionTomada({
    required int idNotificacion,
    required String nombreMedicamento,
    required String momento,
    required DateTime fechaHora,
    required int idUsuario,
    required String accion,
  }) async {
    final db = await database;
    await db.insert('RegistroMedicacion', {
      'idNotificacion': idNotificacion,
      'nombreMedicamento': nombreMedicamento,
      'momento': momento,
      'fechaHora': fechaHora.toIso8601String(),
      'idUsuario': idUsuario,
      'accion': accion,
    });
  }

  Future<void> actualizarDuracionMedicamentoPorNombre({
    required int idUsuario,
    required String nombreMedicamento,
    required String tipoPauta,
  }) async {
    final medicamentos = await obtenerMedicamentosPorUsuario(idUsuario);

    final medicamento = medicamentos.firstWhere(
      (m) =>
          m['nombre'].toString().toLowerCase() ==
          nombreMedicamento.toLowerCase(),
      orElse: () => {},
    );

    if (medicamento.isEmpty) {
      return;
    }

    final db = await database;
    final idMedicamento = medicamento['id'];

    String pauta;
    switch (tipoPauta.toLowerCase()) {
      case 'desayuno':
        pauta = 'pautaDesayuno';
        break;
      case 'comida':
        pauta = 'pautaComida';
        break;
      case 'cena':
        pauta = 'pautaCena';
        break;
      default:
        print('Tipo de pauta inválido.');
        return;
    }

    int diasMedicamentoActualizado =
        medicamento['diasMedicamento'] - medicamento[pauta];

    await db.update(
      'medicamentos',
      {'diasMedicamento': diasMedicamentoActualizado},
      where: 'id = ?',
      whereArgs: [idMedicamento],
    );
  }

  Future<Map<String, List<Map<String, dynamic>>>>
  obtenerEfectosAgrupados() async {
    final db = await database;

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

  Future<List<Map<String, dynamic>>> obtenerAccionesPospuestasSemana(
    String momento,
  ) async {
    final db = await DatabaseHelper().database;

    final resultados = await db.query(
      'RegistroMedicacion',
      where:
          'momento = ? AND accion = ? AND fechaHora >= datetime(\'now\', \'-7 days\')',
      whereArgs: [momento, 'Pospuesta'],
    );

    return resultados;
  }
}
