import 'package:flutter_test/flutter_test.dart';
import 'package:crediapp/auth_service.dart';
import 'package:crediapp/tdd/tdd_common.dart';
import 'package:crediapp/tdd/recuperacion_service.dart';
import 'package:crediapp/tdd/cliente_service.dart';
import 'package:crediapp/tdd/prestamo_service.dart';
import 'package:crediapp/tdd/pago_service.dart';
import 'package:crediapp/tdd/recordatorio_service.dart';
import 'package:crediapp/tdd/panel_service.dart';

// ===================== FAKES =====================

class FakeUsuarioRepo implements UsuarioRepository {
  final map = <String, Usuario>{};
  final sesiones = <String, Sesion>{};
  bool fallar = false;
  void _c() { if (fallar) throw ConexionException(); }
  void seed(Usuario u) => map[u.correo.toLowerCase()] = u;
  @override Future<Usuario?> buscarPorCorreo(String c) async { _c(); return map[c.toLowerCase()]; }
  @override Future<Usuario> crear(Usuario u) async { _c(); map[u.correo.toLowerCase()] = u; return u; }
  @override Future<void> actualizar(Usuario u) async { _c(); map[u.correo.toLowerCase()] = u; }
  @override Future<Sesion> crearSesion(String id) async {
    _c();
    final s = Sesion(token: 'tok_$id', usuarioId: id, expiraEn: DateTime(2026, 12, 31));
    sesiones[s.token] = s; return s;
  }
  @override Future<Sesion?> buscarSesion(String t) async { _c(); return sesiones[t]; }
  @override Future<void> invalidarSesion(String t) async { _c(); sesiones.remove(t); }
}

class FakeRecupRepo implements RecuperacionRepository {
  final correos = <String>{};
  final codigos = <String, CodigoRecuperacion>{};
  final claves = <String, String>{};
  bool fallar = false;
  void _c() { if (fallar) throw ConexionException(); }
  @override Future<bool> existeCorreo(String c) async { _c(); return correos.contains(c); }
  @override Future<CodigoRecuperacion> crearCodigo(String c, DateTime ahora) async {
    _c();
    final cod = CodigoRecuperacion(c, '123456', ahora.add(const Duration(minutes: 10)));
    codigos[c] = cod; return cod;
  }
  @override Future<CodigoRecuperacion?> buscarCodigo(String c) async { _c(); return codigos[c]; }
  @override Future<void> actualizarClave(String c, String n) async { _c(); claves[c] = n; }
}

class FakePerfilRepo implements PerfilRepository {
  bool fallar = false;
  String? ultimoNombre;
  @override Future<void> guardarPerfil(String id, String n, String t) async {
    if (fallar) throw ConexionException();
    ultimoNombre = n;
  }
}

class FakeClienteRepo implements ClienteRepository {
  final byId = <String, ClienteTdd>{};
  bool fallar = false;
  void _c() { if (fallar) throw ConexionException(); }
  void seed(ClienteTdd c) => byId[c.id] = c;
  @override Future<ClienteTdd?> buscarPorDni(String dni) async {
    _c();
    for (final c in byId.values) { if (c.dni == dni && !c.eliminado) return c; }
    return null;
  }
  @override Future<ClienteTdd?> buscarPorId(String id) async { _c(); return byId[id]; }
  @override Future<ClienteTdd> crear(ClienteTdd c) async { _c(); byId[c.id] = c; return c; }
  @override Future<void> actualizar(ClienteTdd c) async { _c(); byId[c.id] = c; }
  @override Future<List<ClienteTdd>> listar() async { _c(); return byId.values.where((c) => !c.eliminado).toList(); }
  @override Future<List<ClienteTdd>> buscar(String q) async {
    _c();
    final t = q.toLowerCase();
    return byId.values.where((c) => !c.eliminado && (c.nombre.toLowerCase().contains(t) || c.dni.contains(t))).toList();
  }
}

class FakePrestamoRepo implements PrestamoRepository {
  final byId = <String, PrestamoTdd>{};
  bool fallar = false;
  void _c() { if (fallar) throw ConexionException(); }
  void seed(PrestamoTdd p) => byId[p.id] = p;
  @override Future<PrestamoTdd> crear(PrestamoTdd p) async { _c(); byId[p.id] = p; return p; }
  @override Future<void> actualizar(PrestamoTdd p) async { _c(); byId[p.id] = p; }
  @override Future<PrestamoTdd?> buscarPorId(String id) async { _c(); return byId[id]; }
  @override Future<List<PrestamoTdd>> listar({String? clienteId, EstadoPrestamoTdd? estado, String? texto}) async {
    _c();
    return byId.values.where((p) {
      if (clienteId != null && p.clienteId != clienteId) return false;
      if (estado != null && p.estado != estado) return false;
      if (texto != null && texto.isNotEmpty && !p.codigo.contains(texto) && !p.clienteId.contains(texto)) return false;
      return true;
    }).toList();
  }
}

class FakePagoRepo implements PagoRepository {
  final items = <PagoTdd>[];
  bool fallar = false;
  void _c() { if (fallar) throw ConexionException(); }
  @override Future<void> registrar(PagoTdd p) async { _c(); items.add(p); }
  @override Future<List<PagoTdd>> historial(String id) async { _c(); return items.where((p) => p.prestamoId == id).toList(); }
}

class FakeRecRepo implements RecordatorioRepository {
  final byId = <String, RecordatorioTdd>{};
  bool fallar = false;
  void _c() { if (fallar) throw ConexionException(); }
  @override Future<RecordatorioTdd> crear(RecordatorioTdd r) async { _c(); byId[r.id] = r; return r; }
  @override Future<void> actualizar(RecordatorioTdd r) async { _c(); byId[r.id] = r; }
  @override Future<void> eliminar(String id) async { _c(); byId.remove(id); }
  @override Future<List<RecordatorioTdd>> listar() async { _c(); return byId.values.toList(); }
  @override Future<RecordatorioTdd?> buscar(String id) async { _c(); return byId[id]; }
}

PrestamoTdd prestamoDemo({String id = 'p1', double monto = 800, int n = 4}) {
  final svc = PrestamoService(FakePrestamoRepo());
  final cuotas = svc.calcularCuotas(monto: monto, tasa: 5, nCuotas: n, fechaInicio: '21/09/2026');
  return PrestamoTdd(
    id: id,
    codigo: '0781',
    clienteId: 'c1',
    monto: monto,
    tasa: 5,
    nCuotas: n,
    frecuencia: 'Semanal',
    fecha: '21/09/2026',
    cuotas: cuotas,
  );
}

void main() {
  // -------- RF001-003 Auth (complementa test/auth_service_test.dart) --------
  group('RF001-RF003 Auth cobertura extra', () {
    test('RF001 CP03 UI: borrador incompleto se puede modelar como datos parciales inválidos', () async {
      final auth = AuthService(FakeUsuarioRepo());
      final r = await auth.registrar(nombre: 'Ro', correo: 'a@b.com', clave: '123');
      expect(r.estado, EstadoRegistro.datosInvalidos);
    });
  });

  // -------- RF004 --------
  group('RF004 Recuperación de contraseña', () {
    late FakeRecupRepo repo;
    late RecuperacionService svc;
    final ahora = DateTime(2026, 10, 26, 10);
    setUp(() { repo = FakeRecupRepo(); svc = RecuperacionService(repo); });

    test('CP01 flujo exitoso', () async {
      repo.correos.add('prestamista@correo.com');
      final r1 = await svc.solicitarCodigo('prestamista@correo.com', ahora: ahora);
      expect(r1.ok, isTrue);
      final r2 = await svc.confirmarCodigo(correo: 'prestamista@correo.com', codigo: '123456', nuevaClave: 'Nueva123!', ahora: ahora);
      expect(r2.ok, isTrue);
      expect(repo.claves['prestamista@correo.com'], 'Nueva123!');
    });
    test('CP02 correo no registrado', () async {
      final r = await svc.solicitarCodigo('noexiste@correo.com', ahora: ahora);
      expect(r.codigo, 'CORREO_NO_REGISTRADO');
    });
    test('CP03 código vencido', () async {
      repo.correos.add('prestamista@correo.com');
      await svc.solicitarCodigo('prestamista@correo.com', ahora: ahora);
      final r = await svc.confirmarCodigo(
        correo: 'prestamista@correo.com',
        codigo: '123456',
        nuevaClave: 'Nueva123!',
        ahora: ahora.add(const Duration(minutes: 30)),
      );
      expect(r.codigo, 'CODIGO_EXPIRADO');
    });
    test('CP04 TSM error BD', () async {
      repo.correos.add('prestamista@correo.com');
      repo.fallar = true;
      final r = await svc.solicitarCodigo('prestamista@correo.com', ahora: ahora);
      expect(r.codigo, 'ERROR_INTERNO');
    });
  });

  // -------- RF005 --------
  group('RF005 Gestión de perfil', () {
    late FakePerfilRepo repo;
    late PerfilService svc;
    setUp(() { repo = FakePerfilRepo(); svc = PerfilService(repo); });
    test('CP01 éxito', () async {
      final r = await svc.actualizarPerfil(usuarioId: 'u1', nombre: 'Rosa Delgado', telefono: '987654321');
      expect(r.ok, isTrue);
    });
    test('CP02 formato imagen no soportado', () async {
      final r = await svc.actualizarPerfil(usuarioId: 'u1', nombre: 'Rosa Delgado', telefono: '987654321', imagenMime: 'image/gif');
      expect(r.codigo, 'FORMATO_NO_SOPORTADO');
    });
    test('CP03/CP04 fallo conexión', () async {
      repo.fallar = true;
      final r = await svc.actualizarPerfil(usuarioId: 'u1', nombre: 'Rosa Delgado', telefono: '987654321');
      expect(r.codigo, 'ERROR_INTERNO');
    });
  });

  // -------- RF006-011 Clientes --------
  group('RF006-RF011 Clientes', () {
    late FakeClienteRepo repo;
    late ClienteService svc;
    setUp(() { repo = FakeClienteRepo(); svc = ClienteService(repo); });

    test('RF006 CP01 registro ok', () async {
      final r = await svc.registrar(nombre: 'Ana', dni: '40559812', telefono: '988300441', direccion: 'Callao');
      expect(r.ok, isTrue);
    });
    test('RF006 CP02 DNI duplicado', () async {
      await svc.registrar(nombre: 'Ana', dni: '40559812', telefono: '988300441', direccion: 'Callao');
      final r = await svc.registrar(nombre: 'Otra', dni: '40559812', telefono: '900000000', direccion: 'Lima');
      expect(r.codigo, 'CLIENTE_DUPLICADO');
    });
    test('RF006 CP03 campos obligatorios', () async {
      final r = await svc.registrar(nombre: '', dni: '', telefono: '', direccion: '');
      expect(r.codigo, 'CAMPOS_OBLIGATORIOS');
    });
    test('RF006 CP04 TSM', () async {
      repo.fallar = true;
      final r = await svc.registrar(nombre: 'Ana', dni: '40559812', telefono: '988300441', direccion: 'Callao');
      expect(r.codigo, 'ERROR_INTERNO');
    });

    test('RF007 CP01 listado', () async {
      await svc.registrar(nombre: 'Ana', dni: '1', telefono: '988300441', direccion: 'x');
      final r = await svc.consultar();
      expect(r.ok, isTrue);
      expect(r.dato!.length, 1);
    });
    test('RF007 CP02 sin clientes', () async {
      final r = await svc.consultar();
      expect(r.codigo, 'SIN_DATOS');
    });
    test('RF007 CP03 filtro sin coincidencias', () async {
      await svc.registrar(nombre: 'Ana', dni: '1', telefono: '988300441', direccion: 'x');
      final r = await svc.consultar(filtro: 'zzzz');
      expect(r.codigo, 'SIN_DATOS');
    });
    test('RF007 CP04 timeout', () async {
      repo.fallar = true;
      final r = await svc.consultar();
      expect(r.codigo, 'TIMEOUT');
    });

    test('RF008 CP01 actualizar ok', () async {
      final c = (await svc.registrar(nombre: 'Ana', dni: '1', telefono: '988300441', direccion: 'x')).dato!;
      final r = await svc.actualizar(id: c.id, telefono: '999999999', direccion: 'Lima');
      expect(r.ok, isTrue);
    });
    test('RF008 CP02 telefono vacío', () async {
      final c = (await svc.registrar(nombre: 'Ana', dni: '1', telefono: '988300441', direccion: 'x')).dato!;
      final r = await svc.actualizar(id: c.id, telefono: '', direccion: 'Lima');
      expect(r.codigo, 'CAMPOS_OBLIGATORIOS');
    });
    test('RF008 CP03 cliente eliminado', () async {
      final c = (await svc.registrar(nombre: 'Ana', dni: '1', telefono: '988300441', direccion: 'x')).dato!;
      c.eliminado = true;
      final r = await svc.actualizar(id: c.id, telefono: '999', direccion: 'Lima');
      expect(r.codigo, 'CLIENTE_ELIMINADO');
    });
    test('RF008 CP04 conflicto', () async {
      final c = (await svc.registrar(nombre: 'Ana', dni: '1', telefono: '988300441', direccion: 'x')).dato!;
      repo.fallar = true;
      final r = await svc.actualizar(id: c.id, telefono: '999', direccion: 'Lima');
      expect(r.codigo, 'ERROR_INTERNO');
    });

    test('RF009 CP01 búsqueda ok', () async {
      await svc.registrar(nombre: 'Ana Quispe', dni: '40559812', telefono: '988300441', direccion: 'x');
      final r = await svc.buscarUno('Ana');
      expect(r.ok, isTrue);
    });
    test('RF009 CP02 inexistente', () async {
      final r = await svc.buscarUno('Nadie');
      expect(r.codigo, 'NO_ENCONTRADO');
    });
    test('RF009 CP03 formato inválido', () async {
      final r = await svc.buscarUno('a');
      expect(r.codigo, 'FORMATO_INVALIDO');
    });
    test('RF009 CP04 timeout', () async {
      repo.fallar = true;
      final r = await svc.buscarUno('Ana');
      expect(r.codigo, 'TIMEOUT');
    });

    test('RF010/RF011 historial/estado sin préstamos se modela como consulta cliente ok', () async {
      final c = (await svc.registrar(nombre: 'Ana', dni: '1', telefono: '988300441', direccion: 'x')).dato!;
      final r = await svc.buscarUno(c.nombre);
      expect(r.ok, isTrue);
    });
  });

  // -------- RF012-024 Prestamos --------
  group('RF012-RF024 Prestamos', () {
    late FakePrestamoRepo repo;
    late PrestamoService svc;
    final hoy = DateTime(2026, 9, 21);
    setUp(() { repo = FakePrestamoRepo(); svc = PrestamoService(repo); });

    test('RF012 CP01 registro ok', () async {
      final r = await svc.registrar(clienteId: 'c1', monto: 800, tasa: 5, nCuotas: 4, frecuencia: 'Semanal', fecha: '21/09/2026');
      expect(r.ok, isTrue);
      expect(r.dato!.cuotas.length, 4);
    });
    test('RF012 CP02 monto inválido', () async {
      final r = await svc.registrar(clienteId: 'c1', monto: 0, tasa: 5, nCuotas: 4, frecuencia: 'Semanal', fecha: '21/09/2026');
      expect(r.codigo, 'MONTO_INVALIDO');
    });
    test('RF012 CP03 cliente no apto', () async {
      final r = await svc.registrar(clienteId: 'c1', monto: 800, tasa: 5, nCuotas: 4, frecuencia: 'Semanal', fecha: '21/09/2026', clienteApto: false);
      expect(r.codigo, 'CLIENTE_NO_APTO');
    });
    test('RF012 CP04 TSM', () async {
      repo.fallar = true;
      final r = await svc.registrar(clienteId: 'c1', monto: 800, tasa: 5, nCuotas: 4, frecuencia: 'Semanal', fecha: '21/09/2026');
      expect(r.codigo, 'ERROR_INTERNO');
    });

    test('RF013 CP01/CP02/CP03 validar monto', () {
      expect(svc.validarMontoCampo(800).ok, isTrue);
      expect(svc.validarMontoCampo(0).codigo, 'MONTO_INVALIDO');
      expect(svc.validarMontoCampo(20000).codigo, 'MONTO_EXCEDE_LIMITE');
    });
    test('RF013 CP04 texto no numérico => monto null inválido', () {
      expect(svc.validarMontoCampo(null).codigo, 'MONTO_INVALIDO');
    });

    test('RF014 fechas', () {
      expect(svc.validarFecha('21/09/2026', hoy: hoy).ok, isTrue);
      expect(svc.validarFecha('01/01/2020', hoy: hoy).codigo, 'FECHA_PASADA');
      expect(svc.validarFecha('', hoy: hoy).codigo, 'FECHA_VACIA');
    });

    test('RF015 tasas', () {
      expect(svc.validarTasa(5).ok, isTrue);
      expect(svc.validarTasa(-1).codigo, 'TASA_NEGATIVA');
      expect(svc.validarTasa(150).codigo, 'TASA_FUERA_RANGO');
      expect(svc.validarTasa(null).codigo, 'TASA_VACIA');
    });

    test('RF016 cuotas', () {
      expect(svc.validarNumeroCuotas(4).ok, isTrue);
      expect(svc.validarNumeroCuotas(0).codigo, 'CUOTAS_INVALIDAS');
    });

    test('RF017 frecuencia', () {
      expect(svc.validarFrecuencia('Semanal').ok, isTrue);
      expect(svc.validarFrecuencia('Diaria').codigo, 'FRECUENCIA_INVALIDA');
    });

    test('RF018/RF019/RF020 cronograma y cálculo', () async {
      final r = await svc.registrar(clienteId: 'c1', monto: 800, tasa: 5, nCuotas: 4, frecuencia: 'Semanal', fecha: '21/09/2026');
      final total = r.dato!.cuotas.fold<double>(0, (s, c) => s + c.monto);
      expect(total, closeTo(800 * 1.05, 0.02));
      expect(r.dato!.cuotas.every((c) => !c.monto.isNaN), isTrue);
    });

    test('RF019 CP04 NaN cuando parámetros inválidos', () {
      final cuotas = svc.calcularCuotas(monto: 0, tasa: 5, nCuotas: 0, fechaInicio: '21/09/2026');
      expect(cuotas.first.monto.isNaN, isTrue);
    });

    test('RF021 actualizar préstamo', () async {
      final p = (await svc.registrar(clienteId: 'c1', monto: 800, tasa: 5, nCuotas: 4, frecuencia: 'Semanal', fecha: '21/09/2026')).dato!;
      p.tasa = 6;
      await repo.actualizar(p);
      expect((await repo.buscarPorId(p.id))!.tasa, 6);
    });

    test('RF022/RF023 consulta y filtro', () async {
      await svc.registrar(clienteId: 'c1', monto: 800, tasa: 5, nCuotas: 4, frecuencia: 'Semanal', fecha: '21/09/2026');
      final todos = await svc.consultar();
      expect(todos.dato!.length, 1);
      final activos = await svc.consultar(estado: EstadoPrestamoTdd.activo);
      expect(activos.dato!.length, 1);
    });

    test('RF024 detalle', () async {
      final p = (await svc.registrar(clienteId: 'c1', monto: 800, tasa: 5, nCuotas: 4, frecuencia: 'Semanal', fecha: '21/09/2026')).dato!;
      final d = await svc.detalle(p.id);
      expect(d.ok, isTrue);
    });
  });

  // -------- RF025-037 Pagos --------
  group('RF025-RF037 Pagos y cuotas', () {
    late FakePrestamoRepo prepo;
    late FakePagoRepo pagoRepo;
    late PagoService svc;
    late PrestamoTdd prestamo;

    setUp(() {
      prepo = FakePrestamoRepo();
      pagoRepo = FakePagoRepo();
      svc = PagoService(pagoRepo, prepo);
      prestamo = prestamoDemo();
      prepo.seed(prestamo);
    });

    test('RF025 CP01 pago ok', () async {
      final r = await svc.registrarPago(prestamoId: 'p1', cuotaNumero: 1, monto: prestamo.cuotas.first.monto, fecha: '21/09/2026');
      expect(r.ok, isTrue);
      expect(prestamo.cuotas.first.estado, EstadoCuotaTdd.pagada);
    });
    test('RF025 CP02 monto > saldo', () async {
      final r = await svc.registrarPago(prestamoId: 'p1', cuotaNumero: 1, monto: 99999, fecha: '21/09/2026');
      expect(r.codigo, 'EXCEDE_SALDO');
    });
    test('RF025 CP03 pago parcial', () async {
      final r = await svc.registrarPago(prestamoId: 'p1', cuotaNumero: 1, monto: 50, fecha: '21/09/2026');
      expect(r.ok, isTrue);
      expect(prestamo.cuotas.first.estado, EstadoCuotaTdd.parcial);
    });
    test('RF025 CP04 TSM', () async {
      pagoRepo.fallar = true;
      final r = await svc.registrarPago(prestamoId: 'p1', cuotaNumero: 1, monto: 50, fecha: '21/09/2026');
      expect(r.codigo, 'ERROR_CONEXION');
    });

    test('RF026/RF027 validaciones monto/fecha', () async {
      expect((await svc.registrarPago(prestamoId: 'p1', cuotaNumero: 1, monto: 0, fecha: '21/09/2026')).codigo, 'MONTO_INVALIDO');
      expect((await svc.registrarPago(prestamoId: 'p1', cuotaNumero: 1, monto: 50, fecha: '')).codigo, 'FECHA_VACIA');
    });

    test('RF028 asociación cuota', () async {
      final r = await svc.registrarPago(prestamoId: 'p1', cuotaNumero: 2, monto: 50, fecha: '21/09/2026');
      expect(r.ok, isTrue);
      expect(pagoRepo.items.first.cuotaNumero, 2);
    });

    test('RF029 historial', () async {
      await svc.registrarPago(prestamoId: 'p1', cuotaNumero: 1, monto: 50, fecha: '21/09/2026');
      final h = await svc.historial('p1');
      expect(h.dato!.length, 1);
    });

    test('RF030-RF037 estados y saldos', () async {
      prestamo.cuotas[0].estado = EstadoCuotaTdd.vencida;
      expect(svc.cuotasPorEstado(prestamo, EstadoCuotaTdd.vencida).dato!.length, 1);
      expect(svc.cuotasPorEstado(prestamo, EstadoCuotaTdd.pendiente).dato!.isNotEmpty, isTrue);
      final saldoAntes = svc.saldoPendiente(prestamo).dato!;
      await svc.registrarPago(prestamoId: 'p1', cuotaNumero: 2, monto: 50, fecha: '21/09/2026');
      expect(svc.saldoPendiente(prestamo).dato! < saldoAntes, isTrue);
      // cancelado si todas pagadas
      for (final c in prestamo.cuotas) {
        if (c.estado != EstadoCuotaTdd.pagada) {
          await svc.registrarPago(prestamoId: 'p1', cuotaNumero: c.numero, monto: c.monto == 0 ? 1 : c.monto, fecha: '21/09/2026');
        }
      }
    });
  });

  // -------- RF038-043 Recordatorios --------
  group('RF038-RF043 Recordatorios', () {
    late FakeRecRepo repo;
    late RecordatorioService svc;
    setUp(() { repo = FakeRecRepo(); svc = RecordatorioService(repo); });

    test('RF038 CP01 guardar ok', () async {
      final r = await svc.registrar(titulo: 'Rosa #0781', motivo: 'Cuota próxima', fecha: '24/09/2026', hora: '09:00');
      expect(r.ok, isTrue);
    });
    test('RF038 CP02 obligatorio', () async {
      final r = await svc.registrar(titulo: '', motivo: '', fecha: '', hora: '');
      expect(r.codigo, 'OBLIGATORIO');
    });
    test('RF038 CP03 registro eliminado', () async {
      final r = await svc.registrar(titulo: 'x', motivo: 'y', fecha: '24/09/2026', hora: '09:00', prestamoExiste: false);
      expect(r.codigo, 'REGISTRO_ELIMINADO');
    });
    test('RF038 CP04 TSM', () async {
      repo.fallar = true;
      final r = await svc.registrar(titulo: 'x', motivo: 'y', fecha: '24/09/2026', hora: '09:00');
      expect(r.codigo, 'ERROR_CONEXION');
    });

    test('RF039/RF040 programación y consulta', () async {
      await svc.registrar(titulo: 'x', motivo: 'y', fecha: '24/09/2026', hora: '09:00');
      final lista = await svc.consultar();
      expect(lista.dato!.length, 1);
    });

    test('RF041/RF042 notificaciones', () {
      expect(svc.notificacionPorVencer('Rosa', '#06').ok, isTrue);
      expect(svc.notificacionVencida('Luis', '#01').ok, isTrue);
    });

    test('RF043 modificar y eliminar', () async {
      final r = await svc.registrar(titulo: 'x', motivo: 'y', fecha: '24/09/2026', hora: '09:00');
      final m = await svc.modificar(r.dato!.id, hora: '10:00');
      expect(m.ok, isTrue);
      final e = await svc.eliminar(r.dato!.id);
      expect(e.ok, isTrue);
    });
  });

  // -------- RF044-050 Panel / obs / límite --------
  group('RF044-RF050 Consultas panel y control estricto', () {
    late FakePrestamoRepo prepo;
    late FakePagoRepo pagoRepo;
    late PanelService panel;
    late PrestamoService prestamos;

    setUp(() {
      prepo = FakePrestamoRepo();
      pagoRepo = FakePagoRepo();
      panel = PanelService(prepo, pagoRepo);
      prestamos = PrestamoService(prepo);
    });

    test('RF044 préstamos por cliente', () async {
      await prestamos.registrar(clienteId: 'c1', monto: 800, tasa: 5, nCuotas: 4, frecuencia: 'Semanal', fecha: '21/09/2026');
      final r = await prestamos.consultar(clienteId: 'c1');
      expect(r.dato!.length, 1);
    });

    test('RF045 cobros periodo', () async {
      final p = (await prestamos.registrar(clienteId: 'c1', monto: 800, tasa: 5, nCuotas: 4, frecuencia: 'Semanal', fecha: '21/09/2026')).dato!;
      final pagos = PagoService(pagoRepo, prepo);
      await pagos.registrarPago(prestamoId: p.id, cuotaNumero: 1, monto: 50, fecha: '21/09/2026');
      final r = await panel.cobrosPorPeriodo();
      expect(r.ok, isTrue);
      expect(r.dato!.isNotEmpty, isTrue);
    });

    test('RF046/RF047 filtros estado', () async {
      final p = (await prestamos.registrar(clienteId: 'c1', monto: 800, tasa: 5, nCuotas: 4, frecuencia: 'Semanal', fecha: '21/09/2026')).dato!;
      p.cuotas.first.estado = EstadoCuotaTdd.vencida;
      final pagos = PagoService(pagoRepo, prepo);
      expect(pagos.cuotasPorEstado(p, EstadoCuotaTdd.vencida).dato!.length, 1);
      final activos = await prestamos.consultar(estado: EstadoPrestamoTdd.activo);
      expect(activos.dato!.length, 1);
    });

    test('RF048 resumen', () async {
      await prestamos.registrar(clienteId: 'c1', monto: 800, tasa: 5, nCuotas: 4, frecuencia: 'Semanal', fecha: '21/09/2026');
      final r = await panel.resumen();
      expect(r.ok, isTrue);
      expect(r.dato!.prestado, 800);
    });
    test('RF048 TSM', () async {
      prepo.fallar = true;
      final r = await panel.resumen();
      expect(r.codigo, 'ERROR_CARGA');
    });

    test('RF049 observaciones', () async {
      final p = (await prestamos.registrar(clienteId: 'c1', monto: 800, tasa: 5, nCuotas: 4, frecuencia: 'Semanal', fecha: '21/09/2026')).dato!;
      expect((await prestamos.agregarObservacion(p, 'Acordó pagar viernes')).ok, isTrue);
      expect((await prestamos.agregarObservacion(p, '')).codigo, 'OBLIGATORIO');
      expect((await prestamos.agregarObservacion(p, 'x' * 200)).codigo, 'LIMITE');
      prepo.fallar = true;
      expect((await prestamos.agregarObservacion(p, 'nota')).codigo, 'ERROR_RED');
    });

    test('RF050 control estricto', () {
      expect(prestamos.operacionFinancieraPermitida('consultar').ok, isTrue);
      expect(prestamos.operacionFinancieraPermitida('transferir').codigo, 'NO_PERMITIDO');
      expect(prestamos.operacionFinancieraPermitida('yape').codigo, 'NO_PERMITIDO');
      expect(prestamos.operacionFinancieraPermitida('pagar_real').codigo, 'NO_PERMITIDO');
    });
  });
}
