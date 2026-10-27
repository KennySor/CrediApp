import 'auth_service.dart';
import 'data.dart';

/// Repositorio temporal en memoria para el prototipo académico.
/// En una versión con backend, se sustituirá por una implementación conectada
/// a la base de datos o API.
class AppStoreUsuarioRepository implements UsuarioRepository {
  AppStoreUsuarioRepository() {
    // Conserva la cuenta de demostración que ya utiliza CrediAPP.
    final correoInicial = store.correo.trim().toLowerCase();

    _usuarios[correoInicial] = Usuario(
      id: 'demo',
      nombre: store.nombre,
      correo: correoInicial,
      clave: store.clave,
    );
  }

  final Map<String, Usuario> _usuarios = {};
  final Map<String, Sesion> _sesiones = {};

  @override
  Future<Usuario?> buscarPorCorreo(String correo) async {
    return _usuarios[correo.trim().toLowerCase()];
  }

  @override
  Future<Usuario> crear(Usuario usuario) async {
    final correo = usuario.correo.trim().toLowerCase();
    if (_usuarios.containsKey(correo)) {
      throw StateError('El correo ya está registrado');
    }

    _usuarios[correo] = usuario;
    return usuario;
  }

  @override
  Future<void> actualizar(Usuario usuario) async {
    _usuarios[usuario.correo.trim().toLowerCase()] = usuario;
  }

  @override
  Future<Sesion> crearSesion(String usuarioId) async {
    final token = 'tok_${DateTime.now().microsecondsSinceEpoch}';

    final sesion = Sesion(
      token: token,
      usuarioId: usuarioId,
      expiraEn: DateTime.now().add(const Duration(hours: 8)),
    );

    _sesiones[token] = sesion;
    return sesion;
  }

  @override
  Future<Sesion?> buscarSesion(String token) async {
    return _sesiones[token];
  }

  @override
  Future<void> invalidarSesion(String token) async {
    _sesiones.remove(token);
  }
}

/// Instancias compartidas para que las pantallas usen el mismo servicio
/// y el mismo repositorio mientras la aplicación está abierta.
final authRepository = AppStoreUsuarioRepository();
final authService = AuthService(authRepository);
