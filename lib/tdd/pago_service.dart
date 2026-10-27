import 'tdd_common.dart';
import 'prestamo_service.dart';

class PagoTdd {
  PagoTdd({
    required this.prestamoId,
    required this.cuotaNumero,
    required this.monto,
    required this.fecha,
  });

  final String prestamoId;
  final int cuotaNumero;
  final double monto;
  final String fecha;
}

abstract class PagoRepository {
  Future<void> registrar(PagoTdd pago);
  Future<List<PagoTdd>> historial(String prestamoId);
}

class PagoService {
  PagoService(this._pagos, this._prestamos);
  final PagoRepository _pagos;
  final PrestamoRepository _prestamos;

  Future<Resultado<PrestamoTdd>> registrarPago({
    required String prestamoId,
    required int cuotaNumero,
    required double monto,
    required String fecha,
  }) async {
    if (monto <= 0) {
      return const Resultado('MONTO_INVALIDO', 'Ingrese un monto válido');
    }
    if (fecha.trim().isEmpty) {
      return const Resultado('FECHA_VACIA', 'Campo de fecha vacío');
    }
    try {
      final p = await _prestamos.buscarPorId(prestamoId);
      if (p == null) return const Resultado('NO_ENCONTRADO', 'Préstamo no encontrado');

      CuotaTdd? cuota;
      for (final c in p.cuotas) {
        if (c.numero == cuotaNumero) cuota = c;
      }
      if (cuota == null) return const Resultado('CUOTA_NO_ENCONTRADA', 'Cuota no encontrada');

      if (monto > p.saldo + 0.001) {
        return const Resultado('EXCEDE_SALDO', 'El monto excede el saldo pendiente');
      }

      if (monto + 0.001 < cuota.monto) {
        cuota.estado = EstadoCuotaTdd.parcial;
        cuota.monto = double.parse((cuota.monto - monto).toStringAsFixed(2));
      } else {
        cuota.estado = EstadoCuotaTdd.pagada;
        cuota.monto = 0;
      }

      if (p.cuotas.every((c) => c.estado == EstadoCuotaTdd.pagada)) {
        p.estado = EstadoPrestamoTdd.cancelado;
      }

      await _pagos.registrar(PagoTdd(
        prestamoId: prestamoId,
        cuotaNumero: cuotaNumero,
        monto: monto,
        fecha: fecha,
      ));
      await _prestamos.actualizar(p);
      return Resultado('OK', 'Pago registrado', dato: p, ok: true);
    } on ConexionException {
      return const Resultado('ERROR_CONEXION', 'Error de conexión al registrar el pago');
    }
  }

  Future<Resultado<List<PagoTdd>>> historial(String prestamoId) async {
    try {
      final h = await _pagos.historial(prestamoId);
      return Resultado('OK', h.isEmpty ? 'Sin pagos' : 'Historial de pagos', dato: h, ok: true);
    } on ConexionException {
      return const Resultado('TIMEOUT', 'Servicio no disponible');
    }
  }

  Resultado<List<CuotaTdd>> cuotasPorEstado(PrestamoTdd p, EstadoCuotaTdd estado) {
    final lista = p.cuotas.where((c) => c.estado == estado).toList();
    return Resultado('OK', 'Cuotas filtradas', dato: lista, ok: true);
  }

  Resultado<double> saldoPendiente(PrestamoTdd p) =>
      Resultado('OK', 'Saldo pendiente', dato: p.saldo, ok: true);
}
