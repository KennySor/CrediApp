// Control de autenticación (estilo TDD del ejemplo "cajero" de la profesora).
// Aquí viven las reglas de RF001 (registro) y RF002 (inicio de sesión).
// No importa Flutter UI: las pantallas solo llaman a estos métodos.

import 'tdd/tdd_common.dart';

enum EstadoCuenta { activa, bloqueada }

enum EstadoRegistro {
  exitoso, // RF001-CP01
  correoDuplicado, // RF001-CP02
  datosInvalidos,
  errorConexion, // RF001-CP04 (TSM)
}

enum EstadoLogin {
  exitoso, // RF002-CP01
  credencialesIncorrectas, // RF002-CP02
  intentosExcedidos, // RF002-CP03
  errorServidor, // RF002-CP04 (TSM)
}

enum EstadoCierreSesion {
  exitoso, // RF003-CP01
  reautenticacionRequerida, // RF003-CP03
  errorTimeout, // RF003-CP04 (TSM)
}

class Usuario {
  Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.clave,
    this.estado = EstadoCuenta.activa,
    this.intentosFallidos = 0,
  });

  final String id;
  String nombre;
  String correo;
  String clave;
  EstadoCuenta estado;
  int intentosFallidos;

  bool claveEsCorrecta(String ingresada) => clave == ingresada;
}

class Sesion {
  Sesion({
    required this.token,
    required this.usuarioId,
    required this.expiraEn,
    this.cerrada = false,
    this.sinCierreFormal = false,
  });

  final String token;
  final String usuarioId;
  final DateTime expiraEn;
  bool cerrada;
  bool sinCierreFormal;
}

class ResultadoRegistro {
  const ResultadoRegistro(this.estado, this.mensaje, {this.idUsuario});

  final EstadoRegistro estado;
  final String mensaje;
  final String? idUsuario;
}

class ResultadoLogin {
  const ResultadoLogin(this.estado, this.mensaje, {this.token, this.expiraEn});

  final EstadoLogin estado;
  final String mensaje;
  final String? token;
  final DateTime? expiraEn;
}

class ResultadoCierre {
  const ResultadoCierre(this.estado, this.mensaje);

  final EstadoCierreSesion estado;
  final String mensaje;
}

/// DAO: en producción hablaría con API/BD; en tests usamos un Fake en memoria.
abstract class UsuarioRepository {
  Future<Usuario?> buscarPorCorreo(String correo);
  Future<Usuario> crear(Usuario usuario);
  Future<void> actualizar(Usuario usuario);
  Future<Sesion> crearSesion(String usuarioId);
  Future<Sesion?> buscarSesion(String token);
  Future<void> invalidarSesion(String token);
}

class AuthService {
  AuthService(this._repo, {this.maxIntentos = 5});

  final UsuarioRepository _repo;
  final int maxIntentos;

  /// RF001 — Registro de cuenta de usuario
  Future<ResultadoRegistro> registrar({
    required String nombre,
    required String correo,
    required String clave,
  }) async {
    final nombreOk = nombre.trim();
    final correoOk = correo.trim().toLowerCase();

    if (nombreOk.length < 3 || !_correoValido(correoOk) || clave.length < 8) {
      return const ResultadoRegistro(
        EstadoRegistro.datosInvalidos,
        'Datos de registro inválidos',
      );
    }

    try {
      final existente = await _repo.buscarPorCorreo(correoOk);
      if (existente != null) {
        return const ResultadoRegistro(
          EstadoRegistro.correoDuplicado,
          'Este correo ya está en uso',
        );
      }

      final usuario = Usuario(
        id: 'u${DateTime.now().millisecondsSinceEpoch}',
        nombre: nombreOk,
        correo: correoOk,
        clave: clave, // en producción se cifra
      );
      final creado = await _repo.crear(usuario);
      return ResultadoRegistro(
        EstadoRegistro.exitoso,
        'Cuenta creada correctamente',
        idUsuario: creado.id,
      );
    } on ConexionException {
      return const ResultadoRegistro(
        EstadoRegistro.errorConexion,
        'Error crítico de conexión con el servidor: formulario bloqueado',
      );
    }
  }

  /// RF002 — Inicio de sesión
  Future<ResultadoLogin> iniciarSesion({
    required String correo,
    required String clave,
  }) async {
    final correoOk = correo.trim().toLowerCase();

    try {
      final usuario = await _repo.buscarPorCorreo(correoOk);
      if (usuario == null) {
        return const ResultadoLogin(
          EstadoLogin.credencialesIncorrectas,
          'Credenciales incorrectas',
        );
      }

      if (usuario.estado == EstadoCuenta.bloqueada ||
          usuario.intentosFallidos >= maxIntentos) {
        usuario.estado = EstadoCuenta.bloqueada;
        await _repo.actualizar(usuario);
        return const ResultadoLogin(
          EstadoLogin.intentosExcedidos,
          'Inicio de sesión bloqueado temporalmente',
        );
      }

      if (!usuario.claveEsCorrecta(clave)) {
        usuario.intentosFallidos++;
        if (usuario.intentosFallidos >= maxIntentos) {
          usuario.estado = EstadoCuenta.bloqueada;
        }
        await _repo.actualizar(usuario);
        return const ResultadoLogin(
          EstadoLogin.credencialesIncorrectas,
          'Credenciales incorrectas',
        );
      }

      usuario.intentosFallidos = 0;
      usuario.estado = EstadoCuenta.activa;
      await _repo.actualizar(usuario);
      final sesion = await _repo.crearSesion(usuario.id);
      return ResultadoLogin(
        EstadoLogin.exitoso,
        'Panel principal',
        token: sesion.token,
        expiraEn: sesion.expiraEn,
      );
    } on ConexionException {
      return const ResultadoLogin(
        EstadoLogin.errorServidor,
        'Pantalla congelada en la carga sin ningún mensaje de error',
      );
    }
  }

  /// RF003 — Cierre de sesión
  Future<ResultadoCierre> cerrarSesion(String token) async {
    try {
      final sesion = await _repo.buscarSesion(token);
      if (sesion == null) {
        return const ResultadoCierre(
          EstadoCierreSesion.reautenticacionRequerida,
          'Reautenticación requerida por seguridad',
        );
      }
      if (sesion.sinCierreFormal) {
        return const ResultadoCierre(
          EstadoCierreSesion.reautenticacionRequerida,
          'Reautenticación requerida por seguridad',
        );
      }
      await _repo.invalidarSesion(token);
      return const ResultadoCierre(
        EstadoCierreSesion.exitoso,
        'Sesión cerrada correctamente',
      );
    } on ConexionException {
      return const ResultadoCierre(
        EstadoCierreSesion.errorTimeout,
        'Carga infinita: la sesión sigue activa sin responder',
      );
    }
  }

  bool _correoValido(String correo) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(correo);
}
