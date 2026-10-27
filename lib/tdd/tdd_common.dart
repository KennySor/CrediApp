class ConexionException implements Exception {
  ConexionException([this.mensaje = 'Sin conexión']);
  final String mensaje;
}

class Resultado<T> {
  const Resultado(this.codigo, this.mensaje, {this.dato, this.ok = false});
  final String codigo;
  final String mensaje;
  final T? dato;
  final bool ok;
}
