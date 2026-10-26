import 'package:flutter/material.dart';

enum EstadoPrestamo { activo, atrasado, cancelado }

enum EstadoCuota { pendiente, pagada, vencida }

enum TipoAviso { vencida, porVencer, pago }

class Aviso {
  Aviso({required this.tipo, required this.texto, required this.fecha, this.leido = false});

  final TipoAviso tipo;
  final String texto;
  final String fecha;
  bool leido;
}

class Cliente {
  Cliente({
    required this.id,
    required this.nombre,
    required this.dni,
    required this.telefono,
    required this.direccion,
  });

  final String id;
  String nombre;
  final String dni;
  String telefono;
  String direccion;

  String get iniciales {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first[0] + partes[1][0]).toUpperCase();
  }
}

class Cuota {
  Cuota({
    required this.numero,
    required this.fecha,
    required this.monto,
    required this.estado,
  });

  final int numero;
  final String fecha;
  final double monto;
  EstadoCuota estado;
}

class Prestamo {
  Prestamo({
    required this.id,
    required this.codigo,
    required this.clienteId,
    required this.monto,
    required this.tasa,
    required this.frecuencia,
    required this.fecha,
    required this.estado,
    required this.cuotas,
    List<String>? observaciones,
  }) : observaciones = observaciones ?? [];

  final String id;
  final String codigo;
  final String clienteId;
  final double monto;
  final double tasa;
  final String frecuencia;
  final String fecha;
  EstadoPrestamo estado;
  final List<Cuota> cuotas;
  final List<String> observaciones;

  double get saldo => cuotas
      .where((c) => c.estado != EstadoCuota.pagada)
      .fold(0, (s, c) => s + c.monto);

  int get pagadas => cuotas.where((c) => c.estado == EstadoCuota.pagada).length;
}

class Pago {
  Pago({
    required this.clienteNombre,
    required this.detalle,
    required this.fecha,
    required this.monto,
  });

  final String clienteNombre;
  final String detalle;
  final String fecha;
  final double monto;
}

class Recordatorio {
  Recordatorio({
    required this.titulo,
    required this.motivo,
    required this.fecha,
    required this.hora,
    this.cumplido = false,
  });

  final String titulo;
  final String motivo;
  final String fecha;
  final String hora;
  bool cumplido;
}

class AppStore extends ChangeNotifier {
  String nombre = 'Rosa Delgado Chávez';
  String correo = 'rosa.delgado@prestamosya.pe';
  String telefono = '+51 987 654 321';
    String clave = '12345678';

  bool claveCorrecta(String v) => v == clave;

  void cambiarClave(String nueva) {
    clave = nueva;
    notifyListeners();
  }

  void cambiarCorreo(String nuevo) {
    correo = nuevo;
    notifyListeners();
  }

  final clientes = <Cliente>[
    Cliente(
      id: 'c1',
      nombre: 'Rosa Delgado Chávez',
      dni: '41782903',
      telefono: '+51 987 111 222',
      direccion: 'Jr. Los Pinos 120, Lima',
    ),
    Cliente(
      id: 'c2',
      nombre: 'Jorge Ramos Silva',
      dni: '45128911',
      telefono: '+51 999 220 110',
      direccion: 'Av. Colonial 450, Lima',
    ),
    Cliente(
      id: 'c3',
      nombre: 'Ana Quispe Mamani',
      dni: '40559812',
      telefono: '+51 988 300 441',
      direccion: 'Calle Unión 18, Callao',
    ),
    Cliente(
      id: 'c4',
      nombre: 'Luis Flores Paredes',
      dni: '43311220',
      telefono: '+51 977 654 009',
      direccion: 'Mz. B Lt. 4, San Juan',
    ),
  ];

  late final prestamos = <Prestamo>[
    Prestamo(
      id: 'p1',
      codigo: '0781',
      clienteId: 'c1',
      monto: 800,
      tasa: 5,
      frecuencia: 'Semanal',
      fecha: '21/09/2026',
      estado: EstadoPrestamo.activo,
      cuotas: [
        Cuota(numero: 5, fecha: '18/09', monto: 200, estado: EstadoCuota.pagada),
        Cuota(numero: 6, fecha: '25/09', monto: 200, estado: EstadoCuota.pendiente),
        Cuota(numero: 7, fecha: '02/10', monto: 200, estado: EstadoCuota.pendiente),
        Cuota(numero: 8, fecha: '09/10', monto: 200, estado: EstadoCuota.pendiente),
      ],
    ),
    Prestamo(
      id: 'p2',
      codigo: '0142',
      clienteId: 'c2',
      monto: 150,
      tasa: 8,
      frecuencia: 'Quincenal',
      fecha: '01/09/2026',
      estado: EstadoPrestamo.atrasado,
      cuotas: [
        Cuota(numero: 1, fecha: '15/09', monto: 80, estado: EstadoCuota.vencida),
        Cuota(numero: 2, fecha: '30/09', monto: 70, estado: EstadoCuota.pendiente),
      ],
    ),
    Prestamo(
      id: 'p3',
      codigo: '0090',
      clienteId: 'c3',
      monto: 500,
      tasa: 4,
      frecuencia: 'Mensual',
      fecha: '02/06/2026',
      estado: EstadoPrestamo.cancelado,
      cuotas: [
        Cuota(numero: 1, fecha: '02/07', monto: 250, estado: EstadoCuota.pagada),
        Cuota(numero: 2, fecha: '02/08', monto: 250, estado: EstadoCuota.pagada),
      ],
    ),
    Prestamo(
      id: 'p4',
      codigo: '0210',
      clienteId: 'c4',
      monto: 300,
      tasa: 6,
      frecuencia: 'Semanal',
      fecha: '10/09/2026',
      estado: EstadoPrestamo.atrasado,
      cuotas: [
        Cuota(numero: 1, fecha: '17/09', monto: 100, estado: EstadoCuota.vencida),
        Cuota(numero: 2, fecha: '24/09', monto: 100, estado: EstadoCuota.pendiente),
        Cuota(numero: 3, fecha: '01/10', monto: 100, estado: EstadoCuota.pendiente),
      ],
    ),
  ];

    final pagos = <Pago>[
    Pago(clienteNombre: 'Rosa Delgado Chávez', detalle: '21/09 · Cuota #05', fecha: '21/09/2026', monto: 200),
    Pago(clienteNombre: 'Ana Quispe Mamani', detalle: '02/08 · Cuota #02', fecha: '02/08/2026', monto: 250),
    Pago(clienteNombre: 'Ana Quispe Mamani', detalle: '02/07 · Cuota #01', fecha: '02/07/2026', monto: 250),
  ];

  final recordatorios = <Recordatorio>[
    Recordatorio(
      titulo: 'Rosa Delgado · #0781',
      motivo: 'Cuota próxima a vencer',
      fecha: '24/09/2026',
      hora: '09:00 a. m.',
    ),
    Recordatorio(
      titulo: 'Luis Flores · #0210',
      motivo: 'Cuota vencida',
      fecha: '22/09/2026',
      hora: '08:30 a. m.',
    ),
  ];

  final avisos = <Aviso>[
    Aviso(tipo: TipoAviso.porVencer, texto: 'Cuota #06 de Rosa Delgado vence el 25/09', fecha: '24/09/2026'),
    Aviso(tipo: TipoAviso.vencida, texto: 'Cuota vencida de Luis Flores · préstamo #0210', fecha: '22/09/2026'),
    Aviso(tipo: TipoAviso.pago, texto: 'Pago registrado: Jorge Ramos · S/ 150', fecha: '19/09/2026', leido: true),
  ];

  void marcarLeido(Aviso a) {
    a.leido = true;
    notifyListeners();
  }


  Cliente clienteDe(String id) => clientes.firstWhere((c) => c.id == id);

  List<Prestamo> prestamosDe(String clienteId) =>
      prestamos.where((p) => p.clienteId == clienteId).toList();

  String estadoCliente(Cliente c) {
    final lista = prestamosDe(c.id);
    if (lista.any((p) => p.estado == EstadoPrestamo.atrasado)) return 'ATRASADO';
    if (lista.any((p) => p.estado == EstadoPrestamo.activo)) return 'ACTIVO';
    if (lista.isEmpty || lista.every((p) => p.estado == EstadoPrestamo.cancelado)) {
      return 'SIN PRÉST.';
    }
    return 'ACTIVO';
  }

     List<Pago> pagosEntre(DateTime? desde, DateTime? hasta) {
    final l = pagos.where((p) {
      if (desde == null && hasta == null) return true;
      final d = parseFecha(p.fecha);
      if (d == null) return false;
      if (desde != null && d.isBefore(desde)) return false;
      if (hasta != null && d.isAfter(hasta)) return false;
      return true;
    }).toList();
    l.sort((a, b) => (parseFecha(b.fecha) ?? DateTime(2000)).compareTo(parseFecha(a.fecha) ?? DateTime(2000)));
    return l;
  }

  double get cobradoMes {
    final h = DateTime.now();
    return pagosEntre(DateTime(h.year, h.month, 1), DateTime(h.year, h.month + 1, 0))
        .fold<double>(0, (s, p) => s + p.monto);
  }

  double get totalCobrado => pagos.fold<double>(0, (s, p) => s + p.monto);

  String get iniciales {
    final p = nombre.trim().split(RegExp(r'\s+'));
    if (p.length == 1) return p.first.substring(0, 1).toUpperCase();
    return (p[0][0] + p[1][0]).toUpperCase();
  }

  double get porCobrar =>
      prestamos.fold(0, (s, p) => s + p.saldo);

  List<MapEntry<Prestamo, Cuota>> get cuotasPorCobrar {
    final l = <MapEntry<Prestamo, Cuota>>[];
    for (final p in prestamos.where((p) => p.estado != EstadoPrestamo.cancelado)) {
      for (final c in p.cuotas.where((c) => c.estado != EstadoCuota.pagada)) {
        l.add(MapEntry(p, c));
      }
    }
    l.sort((a, b) {
      final va = a.value.estado == EstadoCuota.vencida ? 0 : 1;
      final vb = b.value.estado == EstadoCuota.vencida ? 0 : 1;
      if (va != vb) return va.compareTo(vb);
      return ordenFecha(a.value.fecha).compareTo(ordenFecha(b.value.fecha));
    });
    return l;
  }

  List<MapEntry<Prestamo, Cuota>> get proximasCuotas {
    final vistos = <String>{};
    return cuotasPorCobrar.where((e) => vistos.add(e.key.id)).toList();
  }

    void actualizarPerfil({required String nombre, required String telefono}) {
    this.nombre = nombre;
    this.telefono = telefono;
    notifyListeners();
  }

  void agregarCliente(Cliente c) {
    clientes.insert(0, c);
    notifyListeners();
  }

  void editarCliente(Cliente c, {required String telefono, required String direccion}) {
    c.telefono = telefono;
    c.direccion = direccion;
    notifyListeners();
  }

  Prestamo registrarPrestamo({
    required String clienteId,
    required double monto,
    required double tasa,
    required int nCuotas,
    required String frecuencia,
    required String fecha,
  }) {
    final cuota = (monto * (1 + tasa / 100)) / nCuotas;
    final cuotas = List.generate(
      nCuotas,
      (i) => Cuota(
        numero: i + 1,
        fecha: 'C${i + 1}',
        monto: double.parse(cuota.toStringAsFixed(2)),
        estado: EstadoCuota.pendiente,
      ),
    );
    final codigo = (700 + prestamos.length).toString().padLeft(4, '0');
    final p = Prestamo(
      id: 'p${prestamos.length + 1}',
      codigo: codigo,
      clienteId: clienteId,
      monto: monto,
      tasa: tasa,
      frecuencia: frecuencia,
      fecha: fecha,
      estado: EstadoPrestamo.activo,
      cuotas: cuotas,
    );
    prestamos.insert(0, p);
    notifyListeners();
    return p;
  }

  void registrarPago(Prestamo prestamo, Cuota cuota, double monto, String fecha) {
    cuota.estado = EstadoCuota.pagada;
    if (prestamo.cuotas.every((c) => c.estado == EstadoCuota.pagada)) {
      prestamo.estado = EstadoPrestamo.cancelado;
    } else if (prestamo.cuotas.any((c) => c.estado == EstadoCuota.vencida)) {
      prestamo.estado = EstadoPrestamo.atrasado;
    } else {
      prestamo.estado = EstadoPrestamo.activo;
    }
    pagos.insert(
      0,
      Pago(
        clienteNombre: clienteDe(prestamo.clienteId).nombre,
        detalle: '$fecha · Cuota #${cuota.numero.toString().padLeft(2, '0')}',
        fecha: fecha,
        monto: monto,
      ),
    );

        avisos.insert(
      0,
      Aviso(
        tipo: TipoAviso.pago,
        texto: 'Pago registrado: ${clienteDe(prestamo.clienteId).nombre} · ${soles(monto)}',
        fecha: fecha,
      ),
    );
    notifyListeners();
  }

  void agregarRecordatorio(Recordatorio r) {
    recordatorios.insert(0, r);
    notifyListeners();
  }

    void eliminarRecordatorio(Recordatorio r) {
    recordatorios.remove(r);
    notifyListeners();
  }

  void alternarCumplido(Recordatorio r) {
    r.cumplido = !r.cumplido;
    notifyListeners();
  }

  void agregarObservacion(Prestamo p, String texto) {
    p.observaciones.insert(0, texto);
    notifyListeners();
  }
}

String soles(num valor) {
  final texto = valor.toStringAsFixed(valor % 1 == 0 ? 0 : 2);
  final partes = texto.split('.');
  final entero = partes.first.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  return partes.length == 1 ? 'S/ $entero' : 'S/ $entero.${partes[1]}';
}

final store = AppStore();

String etiquetaEstado(EstadoPrestamo e) {
  switch (e) {
    case EstadoPrestamo.activo:
      return 'ACTIVO';
    case EstadoPrestamo.atrasado:
      return 'ATRASADO';
    case EstadoPrestamo.cancelado:
      return 'CANCELADO';
  }
}

String? vNombre(String? v) =>
    (v ?? '').trim().length < 3 ? 'Ingresa tu nombre completo' : null;

String? vTelefono(String? v) {
  final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
  final ok = d.length == 9 || (d.length == 11 && d.startsWith('51'));
  return ok ? null : 'Teléfono inválido (9 dígitos)';
}

String? vCorreo(String? v) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((v ?? '').trim()) ? null : 'Correo inválido';

String? vClaveNueva(String? v) {
  final t = v ?? '';
  if (t.length < 8) return 'Mínimo 8 caracteres';
  if (!RegExp(r'[A-Z]').hasMatch(t)) return 'Incluye una mayúscula';
  if (!RegExp(r'\d').hasMatch(t)) return 'Incluye un número';
  if (!RegExp(r'[^A-Za-z0-9]').hasMatch(t)) return 'Incluye un símbolo';
  return null;
}

int ordenFecha(String f) {
  final m = RegExp(r'^(\d{1,2})/(\d{1,2})').firstMatch(f);
  if (m == null) return 9999;
  return int.parse(m.group(2)!) * 100 + int.parse(m.group(1)!);
}

String hoyTexto() {
  final d = DateTime.now();
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

DateTime? parseFecha(String f) {
  final m = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})').firstMatch(f.trim());
  if (m == null) return null;
  return DateTime(int.parse(m.group(3)!), int.parse(m.group(2)!), int.parse(m.group(1)!));
}

String fechaTexto(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';  