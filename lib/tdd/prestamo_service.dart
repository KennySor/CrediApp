import 'tdd_common.dart';

enum EstadoPrestamoTdd { activo, atrasado, cancelado }
enum EstadoCuotaTdd { pendiente, pagada, vencida, parcial }

class CuotaTdd {
  CuotaTdd({
    required this.numero,
    required this.fecha,
    required this.monto,
    this.estado = EstadoCuotaTdd.pendiente,
  });

  final int numero;
  final String fecha;
  double monto;
  EstadoCuotaTdd estado;
}

class PrestamoTdd {
  PrestamoTdd({
    required this.id,
    required this.codigo,
    required this.clienteId,
    required this.monto,
    required this.tasa,
    required this.nCuotas,
    required this.frecuencia,
    required this.fecha,
    this.estado = EstadoPrestamoTdd.activo,
    List<CuotaTdd>? cuotas,
    this.clienteApto = true,
    List<String>? observaciones,
  })  : cuotas = cuotas ?? [],
        observaciones = observaciones ?? [];

  final String id;
  final String codigo;
  final String clienteId;
  double monto;
  double tasa;
  int nCuotas;
  String frecuencia;
  String fecha;
  EstadoPrestamoTdd estado;
  List<CuotaTdd> cuotas;
  bool clienteApto;
  List<String> observaciones;

  double get saldo =>
      cuotas.where((c) => c.estado != EstadoCuotaTdd.pagada).fold(0.0, (s, c) => s + c.monto);
}

abstract class PrestamoRepository {
  Future<PrestamoTdd> crear(PrestamoTdd p);
  Future<void> actualizar(PrestamoTdd p);
  Future<PrestamoTdd?> buscarPorId(String id);
  Future<List<PrestamoTdd>> listar({String? clienteId, EstadoPrestamoTdd? estado, String? texto});
}

class PrestamoService {
  PrestamoService(this._repo, {this.limiteMonto = 10000});
  final PrestamoRepository _repo;
  final double limiteMonto;

  bool montoValido(double? monto) => monto != null && monto > 0;
  bool tasaValida(double? tasa) => tasa != null && tasa >= 0 && tasa <= 100;
  bool frecuenciaValida(String? f) => f != null && ['Semanal', 'Quincenal', 'Mensual'].contains(f);

  bool fechaValida(String fecha, {required DateTime hoy}) {
    final m = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(fecha.trim());
    if (m == null) return false;
    final d = DateTime(int.parse(m.group(3)!), int.parse(m.group(2)!), int.parse(m.group(1)!));
    final soloHoy = DateTime(hoy.year, hoy.month, hoy.day);
    return !d.isBefore(soloHoy);
  }

  List<CuotaTdd> calcularCuotas({
    required double monto,
    required double tasa,
    required int nCuotas,
    required String fechaInicio,
  }) {
    if (nCuotas <= 0 || monto <= 0) {
      return [CuotaTdd(numero: 1, fecha: fechaInicio, monto: double.nan)];
    }
    final total = monto * (1 + tasa / 100);
    final base = double.parse((total / nCuotas).toStringAsFixed(2));
    final cuotas = <CuotaTdd>[];
    var acum = 0.0;
    for (var i = 1; i <= nCuotas; i++) {
      final montoCuota = i == nCuotas ? double.parse((total - acum).toStringAsFixed(2)) : base;
      acum += montoCuota;
      cuotas.add(CuotaTdd(numero: i, fecha: 'C$i', monto: montoCuota));
    }
    return cuotas;
  }

  Future<Resultado<PrestamoTdd>> registrar({
    required String clienteId,
    required double monto,
    required double tasa,
    required int nCuotas,
    required String frecuencia,
    required String fecha,
    bool clienteApto = true,
  }) async {
    if (!montoValido(monto)) {
      return const Resultado('MONTO_INVALIDO', 'Ingrese un monto válido');
    }
    if (monto > limiteMonto) {
      return const Resultado('MONTO_EXCEDE_LIMITE', 'El monto excede el límite permitido');
    }
    if (!clienteApto) {
      return const Resultado('CLIENTE_NO_APTO', 'El cliente no cumple los requisitos');
    }
    try {
      final cuotas = calcularCuotas(monto: monto, tasa: tasa, nCuotas: nCuotas, fechaInicio: fecha);
      if (cuotas.any((c) => c.monto.isNaN)) {
        return const Resultado('CALCULO_INVALIDO', 'Monto por cuota inválido');
      }
      final p = await _repo.crear(PrestamoTdd(
        id: 'p${DateTime.now().millisecondsSinceEpoch}',
        codigo: DateTime.now().millisecondsSinceEpoch.toString().substring(7),
        clienteId: clienteId,
        monto: monto,
        tasa: tasa,
        nCuotas: nCuotas,
        frecuencia: frecuencia,
        fecha: fecha,
        cuotas: cuotas,
        clienteApto: clienteApto,
      ));
      return Resultado('OK', 'Préstamo registrado con cronograma', dato: p, ok: true);
    } on ConexionException {
      return const Resultado('ERROR_INTERNO', 'Error crítico: el cronograma no se genera');
    }
  }

  Future<Resultado<List<PrestamoTdd>>> consultar({
    String? clienteId,
    EstadoPrestamoTdd? estado,
    String? texto,
  }) async {
    try {
      final lista = await _repo.listar(clienteId: clienteId, estado: estado, texto: texto);
      return Resultado('OK', lista.isEmpty ? 'Sin préstamos' : 'Listado de préstamos', dato: lista, ok: true);
    } on ConexionException {
      return const Resultado('TIMEOUT', 'Servicio no disponible');
    }
  }

  Future<Resultado<PrestamoTdd>> detalle(String id) async {
    try {
      final p = await _repo.buscarPorId(id);
      if (p == null) return const Resultado('NO_ENCONTRADO', 'Préstamo no encontrado');
      return Resultado('OK', 'Detalle del préstamo', dato: p, ok: true);
    } on ConexionException {
      return const Resultado('TIMEOUT', 'Servicio no disponible');
    }
  }

  Resultado<double> validarMontoCampo(double? monto) {
    if (!montoValido(monto)) return const Resultado('MONTO_INVALIDO', 'Ingrese un monto válido');
    if (monto! > limiteMonto) {
      return const Resultado('MONTO_EXCEDE_LIMITE', 'El monto excede el límite permitido');
    }
    return Resultado('OK', 'Monto válido', dato: monto, ok: true);
  }

  Resultado<double> validarTasa(double? tasa) {
    if (tasa == null) return const Resultado('TASA_VACIA', 'La tasa no puede estar vacía');
    if (tasa < 0) return const Resultado('TASA_NEGATIVA', 'Tasa de interés negativa');
    if (tasa > 100) return const Resultado('TASA_FUERA_RANGO', 'Tasa fuera de rango');
    return Resultado('OK', 'Tasa válida', dato: tasa, ok: true);
  }

  Resultado<int> validarNumeroCuotas(int? n) {
    if (n == null || n <= 0) return const Resultado('CUOTAS_INVALIDAS', 'Número de cuotas inválido');
    return Resultado('OK', 'Cuotas válidas', dato: n, ok: true);
  }

  Resultado<String> validarFrecuencia(String? f) {
    if (!frecuenciaValida(f)) return const Resultado('FRECUENCIA_INVALIDA', 'Frecuencia inválida');
    return Resultado('OK', 'Frecuencia válida', dato: f, ok: true);
  }

  Resultado<String> validarFecha(String fecha, {required DateTime hoy}) {
    if (fecha.trim().isEmpty) return const Resultado('FECHA_VACIA', 'Campo de fecha vacío');
    if (!fechaValida(fecha, hoy: hoy)) return const Resultado('FECHA_PASADA', 'Fecha anterior a la actual');
    return Resultado('OK', 'Fecha válida', dato: fecha, ok: true);
  }

  Future<Resultado<String>> agregarObservacion(PrestamoTdd p, String texto, {int max = 180}) async {
    if (texto.trim().isEmpty) {
      return const Resultado('OBLIGATORIO', 'Este campo es obligatorio');
    }
    if (texto.length > max) {
      return const Resultado('LIMITE', 'Límite de caracteres superado');
    }
    try {
      p.observaciones.insert(0, texto.trim());
      await _repo.actualizar(p);
      return Resultado('OK', 'Observación registrada', dato: texto.trim(), ok: true);
    } on ConexionException {
      return const Resultado('ERROR_RED', 'Error de red: el texto no se guardó');
    }
  }

  Resultado<bool> operacionFinancieraPermitida(String operacion) {
    const prohibidas = {'transferir', 'yape', 'pagar_real', 'retiro'};
    if (prohibidas.contains(operacion)) {
      return const Resultado('NO_PERMITIDO', 'La operación no está permitida');
    }
    return const Resultado('OK', 'Operación informativa permitida', dato: true, ok: true);
  }
}
