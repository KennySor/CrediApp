
import 'package:supabase_flutter/supabase_flutter.dart';

/// Autenticación real en la nube mediante Supabase.
/// Se mantiene separado de AuthService para conservar las pruebas existentes.
class SupabaseAuthService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Usuario que tiene la sesión abierta actualmente.
  User? get usuarioActual => _client.auth.currentUser;

  /// Comprueba si existe una sesión activa.
  bool get tieneSesion => _client.auth.currentSession != null;

  /// Registra una cuenta nueva en Supabase Auth.
  Future<AuthResponse> registrar({
    required String nombre,
    required String correo,
    required String telefono,
    required String clave,
  }) {
    return _client.auth.signUp(
      email: correo.trim().toLowerCase(),
      password: clave,
      data: {
        'nombre': nombre.trim(),
        'telefono': telefono.trim(),
      },
    );
  }

  /// Inicia sesión con las credenciales de Supabase.
  Future<AuthResponse> iniciarSesion({
    required String correo,
    required String clave,
  }) {
    return _client.auth.signInWithPassword(
      email: correo.trim().toLowerCase(),
      password: clave,
    );
  }

  /// Cierra la sesión real de Supabase.
  Future<void> cerrarSesion() {
    return _client.auth.signOut();
  }

  /// Solicita un correo para recuperar la contraseña.
  Future<void> recuperarClave(String correo) {
    return _client.auth.resetPasswordForEmail(
      correo.trim().toLowerCase(),
    );
  }
}

/// Instancia compartida para las pantallas de CrediAPP.
final supabaseAuthService = SupabaseAuthService();
