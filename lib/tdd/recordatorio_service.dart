import 'tdd_common.dart';

class RecordatorioTdd {
  RecordatorioTdd({
    required this.id,
    required this.titulo,
    required this.motivo,
    required this.fecha,
    required this.hora,
    this.activo = true,
    this.prestamoExiste = true,
  });

  final String id;
  String titulo;
  String motivo;
  String fecha;
  String hora;
  bool activo;
  bool prestamoExiste;
}

abstract class RecordatorioRepository {
  Future<RecordatorioTdd> crear(RecordatorioTdd r);
  Future<void> actualizar(RecordatorioTdd r);
  Future<void> eliminar(String id);
  Future<List<RecordatorioTdd>> listar();
  Future<RecordatorioTdd?> buscar(String id);
}

class RecordatorioService {
  RecordatorioService(this._repo);
  final RecordatorioRepository _repo;

  Future<Resultado<RecordatorioTdd>> registrar({
    required String titulo,
    required String motivo,
    required String fecha,
    required String hora,
    bool prestamoExiste = true,
  }) async {
    if (titulo.trim().isEmpty ||
        motivo.trim().isEmpty ||
        fecha.trim().isEmpty ||
        hora.trim().isEmpty) {
      return const Resultado('OBLIGATORIO', 'Este campo es obligatorio');
    }
    if (!prestamoExiste) {
      return const Resultado('REGISTRO_ELIMINADO', 'El registro asociado ya no existe');
    }
    try {
      final r = await _repo.crear(RecordatorioTdd(
        id: 'r${DateTime.now().millisecondsSinceEpoch}',
        titulo: titulo.trim(),
        motivo: motivo.trim(),
        fecha: fecha.trim(),
        hora: hora.trim(),
        prestamoExiste: prestamoExiste,
      ));
      return Resultado('OK', 'Recordatorio guardado', dato: r, ok: true);
    } on ConexionException {
      return const Resultado('ERROR_CONEXION', 'Error crítico de conexión con el servidor web');
    }
  }

  Future<Resultado<List<RecordatorioTdd>>> consultar() async {
    try {
      final lista = await _repo.listar();
      return Resultado('OK', 'Recordatorios', dato: lista, ok: true);
    } on ConexionException {
      return const Resultado('TIMEOUT', 'Servicio no disponible');
    }
  }

  Future<Resultado<RecordatorioTdd>> modificar(
    String id, {
    String? fecha,
    String? hora,
    String? motivo,
  }) async {
    try {
      final r = await _repo.buscar(id);
      if (r == null) return const Resultado('NO_ENCONTRADO', 'Recordatorio no encontrado');
      if (fecha != null) r.fecha = fecha;
      if (hora != null) r.hora = hora;
      if (motivo != null) r.motivo = motivo;
      await _repo.actualizar(r);
      return Resultado('OK', 'Recordatorio actualizado', dato: r, ok: true);
    } on ConexionException {
      return const Resultado('ERROR_CONEXION', 'Error al modificar');
    }
  }

  Future<Resultado<void>> eliminar(String id) async {
    try {
      await _repo.eliminar(id);
      return const Resultado('OK', 'Recordatorio eliminado', ok: true);
    } on ConexionException {
      return const Resultado('ERROR_CONEXION', 'Error al eliminar');
    }
  }

  Resultado<String> notificacionPorVencer(String cliente, String cuota) =>
      Resultado('OK', 'Cuota $cuota de $cliente próxima a vencer', dato: 'por_vencer', ok: true);

  Resultado<String> notificacionVencida(String cliente, String cuota) =>
      Resultado('OK', 'Cuota $cuota de $cliente vencida', dato: 'vencida', ok: true);
}
