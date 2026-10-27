import 'tdd_common.dart';
import 'pago_service.dart';
import 'prestamo_service.dart';

class ResumenCartera {
  ResumenCartera({
    required this.prestado,
    required this.cobrado,
    required this.saldo,
    required this.activos,
    required this.cancelados,
  });

  final double prestado;
  final double cobrado;
  final double saldo;
  final int activos;
  final int cancelados;
}

class PanelService {
  PanelService(this._prestamos, this._pagos);
  final PrestamoRepository _prestamos;
  final PagoRepository _pagos;

  Future<Resultado<ResumenCartera>> resumen() async {
    try {
      final lista = await _prestamos.listar();
      final prestado = lista.fold<double>(0, (s, p) => s + p.monto);
      final saldo = lista.fold<double>(0, (s, p) => s + p.saldo);
      final activos = lista.where((p) => p.estado == EstadoPrestamoTdd.activo).length;
      final cancelados = lista.where((p) => p.estado == EstadoPrestamoTdd.cancelado).length;
      final cobrado = prestado - saldo;
      final r = ResumenCartera(
        prestado: prestado.isNaN ? 0 : prestado,
        cobrado: cobrado.isNaN ? 0 : cobrado,
        saldo: saldo.isNaN ? 0 : saldo,
        activos: activos,
        cancelados: cancelados,
      );
      return Resultado('OK', 'Resumen general', dato: r, ok: true);
    } on ConexionException {
      return const Resultado('ERROR_CARGA', 'Error de carga del widget de resumen');
    }
  }

  Future<Resultado<List<PagoTdd>>> cobrosPorPeriodo() async {
    try {
      final prestamos = await _prestamos.listar();
      final todos = <PagoTdd>[];
      for (final p in prestamos) {
        todos.addAll(await _pagos.historial(p.id));
      }
      return Resultado('OK', 'Cobros por periodo', dato: todos, ok: true);
    } on ConexionException {
      return const Resultado('TIMEOUT', 'Servicio no disponible');
    }
  }
}
