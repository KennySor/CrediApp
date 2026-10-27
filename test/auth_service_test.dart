import 'package:flutter_test/flutter_test.dart';
import 'package:crediapp/auth_service.dart';
import 'package:crediapp/tdd/tdd_common.dart';

/// Repositorio falso en memoria (como FakeCuentaRepository del ejemplo TDD-cajero).
class FakeUsuarioRepository implements UsuarioRepository {
  final Map<String, Usuario> _porCorreo = {};
  final Map<String, Sesion> _sesiones = {};
  bool simularFalloConexion = false;

  void _checkConexion() {
    if (simularFalloConexion) throw ConexionException();
  }

  void guardar(Usuario usuario) {
    _porCorreo[usuario.correo.toLowerCase()] = usuario;
  }

  @override
  Future<Usuario?> buscarPorCorreo(String correo) async {
    _checkConexion();
    return _porCorreo[correo.toLowerCase()];
  }

  @override
  Future<Usuario> crear(Usuario usuario) async {
    _checkConexion();
    _porCorreo[usuario.correo.toLowerCase()] = usuario;
    return usuario;
  }

  @override
  Future<void> actualizar(Usuario usuario) async {
    _checkConexion();
    _porCorreo[usuario.correo.toLowerCase()] = usuario;
  }

  @override
  Future<Sesion> crearSesion(String usuarioId) async {
    _checkConexion();
    final sesion = Sesion(
      token: 'tok_$usuarioId',
      usuarioId: usuarioId,
      expiraEn: DateTime(2026, 12, 31),
    );
    _sesiones[sesion.token] = sesion;
    return sesion;
  }

  @override
  Future<Sesion?> buscarSesion(String token) async {
    _checkConexion();
    return _sesiones[token];
  }

  @override
  Future<void> invalidarSesion(String token) async {
    _checkConexion();
    final s = _sesiones[token];
    if (s != null) s.cerrada = true;
    _sesiones.remove(token);
  }

  void guardarSesion(Sesion sesion) {
    _sesiones[sesion.token] = sesion;
  }
}

void main() {
  late FakeUsuarioRepository repositorio;
  late AuthService auth;

  setUp(() {
    repositorio = FakeUsuarioRepository();
    auth = AuthService(repositorio, maxIntentos: 5);
  });

  group('RF001 - Registro de cuenta de usuario', () {
    test('CP01 - Flujo exitoso: registro de cuenta (E1)', () async {
      // ARRANGE (Precondición)
      const correo = 'prestamista@correo.com';
      // ACT
      final resultado = await auth.registrar(
        nombre: 'Rosa Delgado',
        correo: correo,
        clave: 'Clave123!',
      );
      // ASSERT
      expect(resultado.estado, EstadoRegistro.exitoso);
      expect(resultado.idUsuario, isNotNull);
      expect(resultado.mensaje, 'Cuenta creada correctamente');
      final guardado = await repositorio.buscarPorCorreo(correo);
      expect(guardado, isNotNull);
      expect(guardado!.nombre, 'Rosa Delgado');
    });

    test('CP02 - Correo duplicado (A1)', () async {
      repositorio.guardar(Usuario(
        id: 'u1',
        nombre: 'Existente',
        correo: 'prestamista@correo.com',
        clave: 'Clave123!',
      ));

      final resultado = await auth.registrar(
        nombre: 'Otro Usuario',
        correo: 'prestamista@correo.com',
        clave: 'OtraClave1!',
      );

      expect(resultado.estado, EstadoRegistro.correoDuplicado);
      expect(resultado.mensaje, 'Este correo ya está en uso');
      expect(resultado.idUsuario, isNull);
    });

    test('CP04 - Todo sale mal: pérdida de conexión al guardar (TSM)', () async {
      repositorio.simularFalloConexion = true;

      final resultado = await auth.registrar(
        nombre: 'Rosa Delgado',
        correo: 'prestamista@correo.com',
        clave: 'Clave123!',
      );

      expect(resultado.estado, EstadoRegistro.errorConexion);
      expect(
        resultado.mensaje,
        'Error crítico de conexión con el servidor: formulario bloqueado',
      );
    });
  });

  group('RF002 - Inicio de sesión', () {
    test('CP01 - Flujo exitoso: inicio de sesión (E1)', () async {
      repositorio.guardar(Usuario(
        id: 'u1',
        nombre: 'Rosa Delgado',
        correo: 'prestamista@correo.com',
        clave: 'Clave123!',
      ));

      final resultado = await auth.iniciarSesion(
        correo: 'prestamista@correo.com',
        clave: 'Clave123!',
      );

      expect(resultado.estado, EstadoLogin.exitoso);
      expect(resultado.token, isNotNull);
      expect(resultado.expiraEn, isNotNull);
      expect(resultado.mensaje, 'Panel principal');
    });

    test('CP02 - Clave incorrecta (A1)', () async {
      final usuario = Usuario(
        id: 'u1',
        nombre: 'Rosa Delgado',
        correo: 'prestamista@correo.com',
        clave: 'Clave123!',
      );
      repositorio.guardar(usuario);

      final resultado = await auth.iniciarSesion(
        correo: 'prestamista@correo.com',
        clave: 'mala',
      );

      expect(resultado.estado, EstadoLogin.credencialesIncorrectas);
      expect(resultado.mensaje, 'Credenciales incorrectas');
      expect(resultado.token, isNull);
      expect(usuario.intentosFallidos, 1);
    });

    test('CP03 - Intentos fallidos excedidos (A2)', () async {
      final usuario = Usuario(
        id: 'u1',
        nombre: 'Rosa Delgado',
        correo: 'prestamista@correo.com',
        clave: 'Clave123!',
        intentosFallidos: 5,
        estado: EstadoCuenta.bloqueada,
      );
      repositorio.guardar(usuario);

      final resultado = await auth.iniciarSesion(
        correo: 'prestamista@correo.com',
        clave: 'Clave123!',
      );

      expect(resultado.estado, EstadoLogin.intentosExcedidos);
      expect(resultado.mensaje, 'Inicio de sesión bloqueado temporalmente');
      expect(resultado.token, isNull);
    });

    test('CP04 - Todo sale mal: servidor de autenticación sin respuesta (TSM)', () async {
      repositorio.guardar(Usuario(
        id: 'u1',
        nombre: 'Rosa Delgado',
        correo: 'prestamista@correo.com',
        clave: 'Clave123!',
      ));
      repositorio.simularFalloConexion = true;

      final resultado = await auth.iniciarSesion(
        correo: 'prestamista@correo.com',
        clave: 'Clave123!',
      );

      expect(resultado.estado, EstadoLogin.errorServidor);
      expect(
        resultado.mensaje,
        'Pantalla congelada en la carga sin ningún mensaje de error',
      );
    });
  });

  group('RF003 - Cierre de sesión', () {
    test('CP01 - Flujo exitoso: cierre de sesión (E1)', () async {
      repositorio.guardar(Usuario(
        id: 'u1',
        nombre: 'Rosa',
        correo: 'prestamista@correo.com',
        clave: 'Clave123!',
      ));
      final login = await auth.iniciarSesion(
        correo: 'prestamista@correo.com',
        clave: 'Clave123!',
      );

      final resultado = await auth.cerrarSesion(login.token!);

      expect(resultado.estado, EstadoCierreSesion.exitoso);
      expect(await repositorio.buscarSesion(login.token!), isNull);
    });

    test('CP03 - Sesión anterior sin cierre formal (A2)', () async {
      final sesion = Sesion(
        token: 'tok_viejo',
        usuarioId: 'u1',
        expiraEn: DateTime(2026, 12, 31),
        sinCierreFormal: true,
      );
      repositorio.guardarSesion(sesion);

      final resultado = await auth.cerrarSesion('tok_viejo');

      expect(resultado.estado, EstadoCierreSesion.reautenticacionRequerida);
      expect(resultado.mensaje, 'Reautenticación requerida por seguridad');
    });

    test('CP04 - Todo sale mal: timeout al invalidar (TSM)', () async {
      repositorio.guardar(Usuario(
        id: 'u1',
        nombre: 'Rosa',
        correo: 'prestamista@correo.com',
        clave: 'Clave123!',
      ));
      final login = await auth.iniciarSesion(
        correo: 'prestamista@correo.com',
        clave: 'Clave123!',
      );
      repositorio.simularFalloConexion = true;

      final resultado = await auth.cerrarSesion(login.token!);

      expect(resultado.estado, EstadoCierreSesion.errorTimeout);
      expect(
        resultado.mensaje,
        'Carga infinita: la sesión sigue activa sin responder',
      );
    });
  });
}
