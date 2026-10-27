import 'tdd_common.dart';

class CodigoRecuperacion {
  CodigoRecuperacion(this.correo, this.codigo, this.expiraEn);
  final String correo;
  final String codigo;
  final DateTime expiraEn;
}

abstract class RecuperacionRepository {
  Future<bool> existeCorreo(String correo);
  Future<CodigoRecuperacion> crearCodigo(String correo, DateTime ahora);
  Future<CodigoRecuperacion?> buscarCodigo(String correo);
  Future<void> actualizarClave(String correo, String nuevaClave);
}

class RecuperacionService {
  RecuperacionService(this._repo);
  final RecuperacionRepository _repo;

  Future<Resultado<void>> solicitarCodigo(String correo, {required DateTime ahora}) async {
    try {
      final ok = await _repo.existeCorreo(correo.trim().toLowerCase());
      if (!ok) {
        return const Resultado('CORREO_NO_REGISTRADO', 'No encontramos una cuenta con ese correo');
      }
      await _repo.crearCodigo(correo.trim().toLowerCase(), ahora);
      return const Resultado('OK', 'Instrucciones enviadas a su correo', ok: true);
    } on ConexionException {
      return const Resultado('ERROR_INTERNO', 'Error de base de datos: recuperación bloqueada');
    }
  }

  Future<Resultado<void>> confirmarCodigo({
    required String correo,
    required String codigo,
    required String nuevaClave,
    required DateTime ahora,
  }) async {
    try {
      final guardado = await _repo.buscarCodigo(correo.trim().toLowerCase());
      if (guardado == null || guardado.codigo != codigo) {
        return const Resultado('CODIGO_INVALIDO', 'Código inválido');
      }
      if (ahora.isAfter(guardado.expiraEn)) {
        return const Resultado('CODIGO_EXPIRADO', 'Código expirado: puede reenviarlo');
      }
      await _repo.actualizarClave(correo.trim().toLowerCase(), nuevaClave);
      return const Resultado('OK', 'Contraseña actualizada', ok: true);
    } on ConexionException {
      return const Resultado('ERROR_INTERNO', 'Error de base de datos: recuperación bloqueada');
    }
  }
}

abstract class PerfilRepository {
  Future<void> guardarPerfil(String usuarioId, String nombre, String telefono);
}

class PerfilService {
  PerfilService(this._repo);
  final PerfilRepository _repo;

  Future<Resultado<void>> actualizarPerfil({
    required String usuarioId,
    required String nombre,
    required String telefono,
    String? imagenMime,
  }) async {
    try {
      if (imagenMime != null && !{'image/jpeg', 'image/png', 'image/webp'}.contains(imagenMime)) {
        return const Resultado('FORMATO_NO_SOPORTADO', 'Formato de imagen no soportado');
      }
      if (nombre.trim().length < 3) {
        return const Resultado('DATOS_INVALIDOS', 'Nombre inválido');
      }
      await _repo.guardarPerfil(usuarioId, nombre.trim(), telefono.trim());
      return const Resultado('OK', 'Perfil actualizado', ok: true);
    } on ConexionException {
      return const Resultado('ERROR_INTERNO', 'Conflicto de versión al guardar');
    }
  }
}
