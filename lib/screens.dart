import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data.dart';
import 'theme.dart';
import 'widgets.dart';
import 'seguridad.dart';
import 'auth_repository.dart';
import 'auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'supabase_auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final correo = TextEditingController(text: 'rosa.delgado@prestamosya.pe');
  final clave = TextEditingController(text: '12345678');

  int _intentosFallidos = 0;
  int _segundosRestantes = 0;
  Timer? _timerBloqueo;

  void _iniciarBloqueo() {
    _timerBloqueo?.cancel();

    setState(() => _segundosRestantes = 20);

    _timerBloqueo = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_segundosRestantes <= 1) {
        timer.cancel();
        _timerBloqueo = null;
        _desbloquearCuenta();
      } else {
        setState(() => _segundosRestantes--);
      }
    });
  }

  Future<void> _desbloquearCuenta() async {
    final usuario = await authRepository.buscarPorCorreo(correo.text);

    if (usuario != null) {
      usuario.intentosFallidos = 0;
      usuario.estado = EstadoCuenta.activa;
      await authRepository.actualizar(usuario);
    }

    if (!mounted) return;

    setState(() {
      _intentosFallidos = 0;
      _segundosRestantes = 0;
    });

    aviso(context, 'Ya puedes volver a iniciar sesión');
  }

  @override
  void dispose() {
    _timerBloqueo?.cancel();
    correo.dispose();
    clave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          children: [
            const Center(
              child: CircleAvatar(
                radius: 36,
                backgroundColor: CrediColors.vino,
                child: Text(
                  'CA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: CrediColors.texto,
                  ),
                  children: [
                    TextSpan(text: 'Credi'),
                    TextSpan(
                      text: 'APP',
                      style: TextStyle(color: CrediColors.vino),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Gestión y control de préstamos',
                style: TextStyle(color: CrediColors.muted),
              ),
            ),
            const SizedBox(height: 28),
            Campo(
              label: 'Correo electrónico',
              controller: correo,
              keyboard: TextInputType.emailAddress,
            ),
            Campo(label: 'Contraseña', controller: clave, obscure: true),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RecuperarPage()),
                ),
                child: const Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(color: CrediColors.vino),
                ),
              ),
            ),

            BotonVino(
              texto: _segundosRestantes > 0
                  ? 'Bloqueado (${_segundosRestantes}s)'
                  : 'Iniciar sesión',
              onPressed: _segundosRestantes > 0
                  ? null
                  : () async {
                      if (correo.text.trim().isEmpty || clave.text.isEmpty) {
                        aviso(context, 'Ingresa correo y contraseña');
                        return;
                      }

                      try {
                        await supabaseAuthService.iniciarSesion(
                          correo: correo.text,
                          clave: clave.text,
                        );

                        if (!mounted) return;

                        _intentosFallidos = 0;

                        seleccionarStoreParaUsuario(correo.text);

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ShellPage(
                              token:
                                  Supabase
                                      .instance
                                      .client
                                      .auth
                                      .currentSession
                                      ?.accessToken ??
                                  '',
                            ),
                          ),
                        );
                      } on AuthException catch (e) {
                        if (!mounted) return;

                        clave.clear();
                        _intentosFallidos++;

                        if (_intentosFallidos >= 5) {
                          _iniciarBloqueo();
                          aviso(context, 'Cuenta bloqueada por 20 segundos');
                        } else if (e.statusCode == '400' ||
                            e.statusCode == '401') {
                          aviso(context, 'Correo o contraseña incorrectos');
                        } else {
                          aviso(
                            context,
                            'No se pudo iniciar sesión. Inténtalo nuevamente.',
                          );
                        }
                      } catch (_) {
                        if (!mounted) return;
                        aviso(
                          context,
                          'Error de conexión. Inténtalo nuevamente.',
                        );
                      }
                    },
            ),

            const SizedBox(height: 18),
            const Center(
              child: Text(
                '¿No tienes cuenta?',
                style: TextStyle(color: CrediColors.muted),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegistroPage()),
              ),
              child: const Text(
                'Crear cuenta',
                style: TextStyle(
                  color: CrediColors.texto,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final _form = GlobalKey<FormState>();
  final nombre = TextEditingController();
  final correo = TextEditingController();
  final telefono = TextEditingController();
  final clave = TextEditingController();

  static const _claveNombre = 'registro_borrador_nombre';
  static const _claveCorreo = 'registro_borrador_correo';
  static const _claveTelefono = 'registro_borrador_telefono';
  static const _clavePendiente = 'registro_borrador_pendiente';

  bool _registrando = false;
  bool _recuperandoBorrador = true;
  bool _mostrarAvisoBorrador = false;

  @override
  void initState() {
    super.initState();
    _recuperarBorrador();
    nombre.addListener(_guardarBorrador);
    correo.addListener(_guardarBorrador);
    telefono.addListener(_guardarBorrador);
  }

  Future<void> _recuperarBorrador() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendiente = prefs.getBool(_clavePendiente) ?? false;

      if (!mounted) return;

      if (pendiente) {
        nombre.text = prefs.getString(_claveNombre) ?? '';
        correo.text = prefs.getString(_claveCorreo) ?? '';
        telefono.text = prefs.getString(_claveTelefono) ?? '';

        setState(() => _mostrarAvisoBorrador = true);
      }
    } catch (_) {
      // Si el almacenamiento no está disponible, el formulario sigue funcionando.
    } finally {
      if (mounted) {
        setState(() => _recuperandoBorrador = false);
      }
    }
  }

  Future<void> _guardarBorrador() async {
    if (_recuperandoBorrador) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final hayDatos =
          nombre.text.trim().isNotEmpty ||
          correo.text.trim().isNotEmpty ||
          telefono.text.trim().isNotEmpty;

      if (!hayDatos) {
        await _eliminarBorrador();
        return;
      }

      await prefs.setString(_claveNombre, nombre.text);
      await prefs.setString(_claveCorreo, correo.text);
      await prefs.setString(_claveTelefono, telefono.text);
      await prefs.setBool(_clavePendiente, true);
    } catch (_) {
      // El registro continúa disponible aunque falle el borrador.
    }
  }

  Future<void> _eliminarBorrador() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_claveNombre);
    await prefs.remove(_claveCorreo);
    await prefs.remove(_claveTelefono);
    await prefs.remove(_clavePendiente);
  }

  Future<void> _registrar() async {
    if (!_form.currentState!.validate() || _registrando) return;

    setState(() => _registrando = true);

    try {
      final resultado = await supabaseAuthService.registrar(
        nombre: nombre.text.trim(),
        correo: correo.text.trim(),
        telefono: telefono.text.trim(),
        clave: clave.text,
      );

      if (!mounted) return;

      if (resultado.user == null) {
        aviso(context, 'No se pudo crear la cuenta. Inténtalo nuevamente.');
        return;
      }

      try {
        await _eliminarBorrador();
      } catch (_) {
        // La cuenta ya se creó en Supabase.
      }

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);

      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Cuenta creada. Si se solicita verificar el correo, revisa tu bandeja.',
          ),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      final mensaje = e.message.toLowerCase().contains('already registered')
          ? 'Este correo ya está registrado.'
          : 'No se pudo crear la cuenta. Verifica tus datos e inténtalo nuevamente.';

      aviso(context, mensaje);
    } catch (_) {
      if (!mounted) return;
      aviso(context, 'Error de conexión. Inténtalo nuevamente.');
    } finally {
      if (mounted) {
        setState(() => _registrando = false);
      }
    }
  }

  @override
  void dispose() {
    nombre.removeListener(_guardarBorrador);
    correo.removeListener(_guardarBorrador);
    telefono.removeListener(_guardarBorrador);
    nombre.dispose();
    correo.dispose();
    telefono.dispose();
    clave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: barra('Crear cuenta'),
      body: _recuperandoBorrador
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_mostrarAvisoBorrador)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Registro incompleto',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Campo(
                    label: 'Nombre completo',
                    controller: nombre,
                    validator: vNombre,
                  ),
                  Campo(
                    label: 'Correo electrónico',
                    controller: correo,
                    keyboard: TextInputType.emailAddress,
                    validator: vCorreo,
                  ),

                  Campo(
                    label: 'Teléfono',
                    controller: telefono,
                    keyboard: TextInputType.phone,

                    validator: (v) {
                      final numero = v?.trim() ?? '';

                      // El teléfono es opcional.
                      if (numero.isEmpty) return null;

                      // En Perú, el celular debe tener 9 dígitos y comenzar con 9.
                      if (!RegExp(r'^9\d{8}$').hasMatch(numero)) {
                        return 'Ingresa un celular válido';
                      }

                      return null;
                    },
                  ),

                  Campo(
                    label: 'Contraseña',
                    controller: clave,
                    obscure: true,
                    validator: (v) {
                      if (v == null || v.length < 8) {
                        return 'La contraseña debe tener al menos 8 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  BotonVino(
                    texto: _registrando ? 'Registrando...' : 'Registrar cuenta',
                    onPressed: _registrando ? null : _registrar,
                  ),
                ],
              ),
            ),
    );
  }
}

class RecuperarPage extends StatefulWidget {
  const RecuperarPage({super.key});

  @override
  State<RecuperarPage> createState() => _RecuperarPageState();
}

class _RecuperarPageState extends State<RecuperarPage> {
  final correo = TextEditingController(text: 'rosa.delgado@prestamosya.pe');
  final codigo = TextEditingController();
  final clave = TextEditingController();
  bool enviado = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: barra('Recuperar contraseña'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Te enviaremos un código a tu correo para restablecer la contraseña.',
            style: TextStyle(color: CrediColors.muted),
          ),
          const SizedBox(height: 16),
          Campo(label: 'Correo electrónico', controller: correo),
          BotonVino(
            texto: 'Enviar código',
            onPressed: () => setState(() => enviado = true),
          ),
          if (enviado) ...[
            const SizedBox(height: 16),
            Campo(
              label: 'Código recibido',
              controller: codigo,
              keyboard: TextInputType.number,
            ),
            Campo(label: 'Nueva contraseña', controller: clave, obscure: true),
            BotonVino(
              texto: 'Restablecer y volver',
              onPressed: () {
                aviso(context, 'Contraseña actualizada');
                Navigator.pop(context);
              },
            ),
          ],
        ],
      ),
    );
  }
}

// Carga los datos de la cuenta autenticada al entrar a la aplicación.
// Cada consulta se limita al usuario actual; si una tabla está vacía, se limpian
// los datos de ejemplo locales para que una cuenta nueva empiece en cero.
Future<void> _cargarDatosUsuarioIniciales() async {
  final db = Supabase.instance.client;
  final usuario = db.auth.currentUser;
  if (usuario == null) return;

  try {
    final filasClientes = await db.from('clientes')
        .select('id, nombre_cliente, dni_cliente, telefono_cliente, direccion_cliente')
        .eq('usuario_id', usuario.id);
    final clientes = (filasClientes as List).map((f) => Cliente(
      id: f['id'].toString(),
      nombre: (f['nombre_cliente'] ?? '').toString(),
      dni: (f['dni_cliente'] ?? '').toString(),
      telefono: (f['telefono_cliente'] ?? '').toString(),
      direccion: (f['direccion_cliente'] ?? '').toString(),
    )).toList();

    final filasPrestamos = await db.from('prestamos')
        .select('id, cliente_id, fecha_emision, monto_prestado, tasa_interes, numero_cuotas, frecuencia_pago, estado_prestamo')
        .eq('usuario_id', usuario.id)
        .order('creado_en', ascending: false);

    final filasCuotas = await db.from('cuotas')
        .select('id, prestamo_id, numero_cuota, fecha_vencimiento, monto_programado, estado_cuota')
        .eq('usuario_id', usuario.id)
        .order('numero_cuota');

    final filasPagos = await db.from('pagos')
        .select('cuota_id, fecha_pago, monto_abonado, tipo_movimiento, observacion')
        .eq('usuario_id', usuario.id)
        .order('fecha_pago', ascending: false);

    String fecha(dynamic valor) {
      final texto = (valor ?? '').toString();
      final partes = texto.split('-');
      return partes.length == 3
          ? '${partes[2]}/${partes[1]}/${partes[0]}'
          : texto;
    }

    DateTime? fechaSql(dynamic valor) {
      final texto = (valor ?? '').toString();
      if (texto.length < 10) return null;
      return DateTime.tryParse(texto.substring(0, 10));
    }

    final pagosPorCuota = <String, double>{};
    for (final pago in (filasPagos as List)) {
      final cuotaId = (pago['cuota_id'] ?? '').toString();
      final importe = (pago['monto_abonado'] as num?)?.toDouble() ?? 0;
      pagosPorCuota[cuotaId] = (pagosPorCuota[cuotaId] ?? 0) + importe;
    }

    final cuotasPorPrestamo = <String, List<Cuota>>{};
    final cuotaIdAPrestamo = <String, String>{};
    final fechaVencimientoPorCuota = <String, DateTime?>{};

    for (final fila in (filasCuotas as List)) {
      final pid = (fila['prestamo_id'] ?? '').toString();
      final cuotaId = (fila['id'] ?? '').toString();
      cuotaIdAPrestamo[cuotaId] = pid;
      final importe = (fila['monto_programado'] as num?)?.toDouble() ?? 0;
      final pagado = pagosPorCuota[cuotaId] ?? 0;
      final vencimiento = fechaSql(fila['fecha_vencimiento']);
      fechaVencimientoPorCuota[cuotaId] = vencimiento;
      final textoEstado = (fila['estado_cuota'] ?? 'pendiente').toString().toLowerCase();
      final estado = pagado >= importe - 0.001
          ? EstadoCuota.pagada
          : ((textoEstado == 'atrasada' || textoEstado == 'vencida') ||
                  (vencimiento != null && vencimiento.isBefore(DateTime.now()) &&
                      DateTime.now().difference(vencimiento).inDays >= 1))
              ? EstadoCuota.vencida
              : EstadoCuota.pendiente;

      cuotasPorPrestamo.putIfAbsent(pid, () => []).add(Cuota(
        id: cuotaId,
        numero: (fila['numero_cuota'] as num?)?.toInt() ?? 1,
        fecha: fecha(fila['fecha_vencimiento']),
        monto: importe,
        montoPagado: pagado.clamp(0.0, importe).toDouble(),
        estado: estado,
      ));
    }

    final prestamos = <Prestamo>[];
    final estadoActualizado = <String, String>{};

    for (final fila in (filasPrestamos as List)) {
      final id = fila['id'].toString();
      final estadoOriginal = (fila['estado_prestamo'] ?? 'activo').toString().toLowerCase();
      final frecuenciaRaw = (fila['frecuencia_pago'] ?? '').toString().toLowerCase();
      final lista = cuotasPorPrestamo[id] ?? <Cuota>[];
      lista.sort((a, b) => a.numero.compareTo(b.numero));

      final monto = (fila['monto_prestado'] as num?)?.toDouble() ?? 0;
      final tasa = (fila['tasa_interes'] as num?)?.toDouble() ?? 0;
      final n = (fila['numero_cuotas'] as num?)?.toInt() ?? lista.length;
      final cuotasFinales = lista.isNotEmpty ? lista : List.generate(n, (i) => Cuota(
        numero: i + 1,
        fecha: '—',
        monto: n > 0 ? monto * (1 + tasa / 100) / n : 0,
        estado: EstadoCuota.pendiente,
      ));

      final todasPagadas = cuotasFinales.isNotEmpty &&
          cuotasFinales.every((c) => c.saldoPendiente <= 0.001);
      final algunaVencida = cuotasFinales.any((c) =>
          c.estado == EstadoCuota.vencida && c.saldoPendiente > 0.001);

      String estadoNuevo;
      if (estadoOriginal == 'cancelado') {
        estadoNuevo = 'cancelado';
      } else if (todasPagadas) {
        estadoNuevo = 'finalizado';
      } else if (algunaVencida) {
        estadoNuevo = 'atrasado';
      } else {
        estadoNuevo = 'activo';
      }
      estadoActualizado[id] = estadoNuevo;

      prestamos.add(Prestamo(
        id: id,
        codigo: id.length >= 4 ? id.substring(id.length - 4).toUpperCase() : id,
        clienteId: (fila['cliente_id'] ?? '').toString(),
        monto: monto,
        tasa: tasa,
        frecuencia: frecuenciaRaw == 'semanal'
            ? 'Semanal'
            : frecuenciaRaw == 'quincenal' ? 'Quincenal' : 'Mensual',
        fecha: fecha(fila['fecha_emision']),
        estado: estadoNuevo == 'finalizado'
            ? EstadoPrestamo.finalizado
            : estadoNuevo == 'cancelado'
                ? EstadoPrestamo.cancelado
                : estadoNuevo == 'atrasado'
                    ? EstadoPrestamo.atrasado
                    : EstadoPrestamo.activo,
        cuotas: cuotasFinales,
      ));
    }

    // Persistir el estado calculado para que todas las pantallas y sesiones coincidan.
    for (final entry in estadoActualizado.entries) {
      final original = (filasPrestamos as List).firstWhere((f) => f['id'].toString() == entry.key);
      if ((original['estado_prestamo'] ?? '').toString().toLowerCase() != entry.value) {
        await db.from('prestamos')
            .update({'estado_prestamo': entry.value})
            .eq('id', entry.key)
            .eq('usuario_id', usuario.id);
      }
    }

    final nombrePorPrestamo = <String, String>{};
    for (final p in prestamos) {
      final coincidencias = clientes.where((c) => c.id == p.clienteId);
      nombrePorPrestamo[p.id] = coincidencias.isEmpty ? 'Cliente' : coincidencias.first.nombre;
    }

    final pagos = <Pago>[];
    for (final fila in (filasPagos as List)) {
      final cuotaId = (fila['cuota_id'] ?? '').toString();
      final pid = cuotaIdAPrestamo[cuotaId];
      final coincidencias = prestamos.where((p) => p.id == pid);
      if (coincidencias.isEmpty) continue;
      final prestamo = coincidencias.first;
      final fechaPago = (fila['fecha_pago'] ?? '').toString();
      final numero = prestamo.cuotas.where((c) => c.id == cuotaId);
      final importe = (fila['monto_abonado'] as num?)?.toDouble() ?? 0;
      final textoFecha = fechaPago.length >= 10 ? fecha(fechaPago.substring(0, 10)) : fechaPago;
      pagos.add(Pago(
        clienteNombre: nombrePorPrestamo[prestamo.id] ?? 'Cliente',
        detalle: (fila['observacion'] ?? 'Pago de cuota').toString(),
        fecha: textoFecha,
        monto: importe,
        prestamoId: prestamo.id,
        cuotaNumero: numero.isEmpty ? null : numero.first.numero,
      ));
    }

    // Los avisos se derivan de los datos reales; no dependen de una lista demo.
    final avisos = <Aviso>[];
    final hoy = DateTime.now();
    for (final p in prestamos) {
      if (p.estado == EstadoPrestamo.cancelado || p.estado == EstadoPrestamo.finalizado) continue;
      final cliente = nombrePorPrestamo[p.id] ?? 'Cliente';
      for (final cuota in p.cuotas) {
        if (cuota.saldoPendiente <= 0.001 || cuota.id == null) continue;
        final v = fechaVencimientoPorCuota[cuota.id!];
        if (v == null) continue;
        final dias = DateTime(v.year, v.month, v.day).difference(DateTime(hoy.year, hoy.month, hoy.day)).inDays;
        if (dias < 0) {
          avisos.add(Aviso(
            tipo: TipoAviso.vencida,
            texto: 'Cuota vencida #${cuota.numero} de $cliente · préstamo #${p.codigo}',
            fecha: fecha(hoy.toIso8601String().substring(0, 10)),
          ));
        } else if (dias <= 3) {
          avisos.add(Aviso(
            tipo: TipoAviso.porVencer,
            texto: 'Cuota #${cuota.numero} de $cliente vence el ${cuota.fecha}',
            fecha: fecha(hoy.toIso8601String().substring(0, 10)),
          ));
        }
      }
    }
    for (final pago in pagos) {
      avisos.add(Aviso(
        tipo: TipoAviso.pago,
        texto: 'Pago registrado: ${pago.clienteNombre} · ${soles(pago.monto)}',
        fecha: pago.fecha,
      ));
    }

    // Recuperar recordatorios persistidos en la tabla existente.
    final filasRecordatorios = await db.from('recordatorios')
        .select('id, prestamo_id, titulo, descripcion, fecha_recordatorio, estado')
        .eq('usuario_id', usuario.id)
        .order('fecha_recordatorio', ascending: true);
    final recordatorios = (filasRecordatorios as List).map((r) {
      final dt = DateTime.tryParse((r['fecha_recordatorio'] ?? '').toString()) ?? DateTime.now();
      final fechaTexto = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      final horaTexto = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return Recordatorio(
        id: r['id']?.toString(),
        prestamoId: r['prestamo_id']?.toString(),
        titulo: (r['titulo'] ?? '').toString(),
        motivo: (r['descripcion'] ?? '').toString(),
        fecha: fechaTexto,
        hora: horaTexto,
        cumplido: (r['estado'] ?? '').toString().toLowerCase() == 'cumplido',
      );
    }).toList();

    store.clientes..clear()..addAll(clientes);
    store.prestamos..clear()..addAll(prestamos);
    store.pagos..clear()..addAll(pagos);
    store.avisos..clear()..addAll(avisos);
    store.recordatorios..clear()..addAll(recordatorios);
    store.notifyListeners();
  } catch (e, st) {
    debugPrint('Error al cargar datos de Supabase para el usuario: $e');
    debugPrintStack(stackTrace: st);
  }
}

class ShellPage extends StatefulWidget {
  const ShellPage({super.key, this.inicial = 0, this.token});

  final int inicial;
  final String? token;

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  late int index = widget.inicial;
  @override
  void initState() {
    super.initState();
    _cargarDatosUsuarioIniciales();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) => [
          HomePage(),
          ClientesPage(),
          PrestamosPage(),
          AvisosPage(),
          PerfilPage(token: widget.token),
        ][index],
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        height: 68,
        backgroundColor: Colors.white,
        indicatorColor: CrediColors.rosaSuave,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: CrediColors.vino),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: CrediColors.vino),
            label: 'Clientes',
          ),
          NavigationDestination(
            icon: Icon(Icons.credit_card_outlined),
            selectedIcon: Icon(Icons.credit_card, color: CrediColors.vino),
            label: 'Créditos',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications, color: CrediColors.vino),
            label: 'Avisos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: CrediColors.vino),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final nombreUsuario = store.nombre.trim().isNotEmpty
        ? store.nombre.trim()
        : Supabase.instance.client.auth.currentUser?.userMetadata?['nombre']
                  ?.toString()
                  .trim() ??
              '';

    final primero = nombreUsuario.isEmpty
        ? 'bienvenido'
        : nombreUsuario.split(RegExp(r'\s+')).first;

    final proximas = store.proximasCuotas.take(3).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, $primero',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'Cartera de préstamos activa',
                      style: TextStyle(color: CrediColors.muted),
                    ),
                  ],
                ),
              ),
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ShellPage(inicial: 4),
                  ),
                  (_) => false,
                ),
                child: AvatarIni(texto: store.iniciales, radio: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _resumen(
                  soles(store.cobradoMes),
                  'Cobrado este mes',
                  CrediColors.verde,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _resumen(
                  soles(store.porCobrar),
                  'Por cobrar',
                  CrediColors.texto,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Accesos rápidos',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.45,
            children: [
              _acceso(
                Icons.add,
                'Nuevo préstamo',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NuevoPrestamoPage()),
                ),
              ),
              _acceso(
                Icons.payments_outlined,
                'Registrar pago',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ElegirPrestamoPagoPage(),
                  ),
                ),
              ),
              _acceso(
                Icons.person_add_alt,
                'Nuevo cliente',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ClienteFormPage()),
                ),
              ),
              _acceso(
                Icons.notifications_active_outlined,
                'Recordatorios',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RecordatoriosPage()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Tarjeta(
            color: CrediColors.vinoOscuro,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccionBloqueadaPage()),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transferencias y pagos reales',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'No disponibles en este sistema',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Cuotas próximas a vencer',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CuotasPage()),
                ),
                child: const Text('Ver todas'),
              ),
            ],
          ),

          if (proximas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No hay cuotas pendientes',
                  style: TextStyle(color: CrediColors.muted),
                ),
              ),
            ),
          ...proximas.map((e) {
            final cliente = store.clienteDe(e.key.clienteId);
            final vencida = e.value.estado == EstadoCuota.vencida;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Tarjeta(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RegistrarPagoPage(prestamo: e.key, cuota: e.value),
                  ),
                ),
                child: Row(
                  children: [
                    AvatarIni(texto: cliente.iniciales),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cliente.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '#${e.key.codigo} · cuota ${e.value.numero} · ${e.value.fecha}',
                            style: const TextStyle(
                              color: CrediColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          soles(e.value.monto),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        ChipEstado(texto: vencida ? 'VENCIDA' : 'PENDIENTE'),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CobrosPage()),
                  ),
                  child: const Text('Cobros'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ResumenPage()),
                  ),
                  child: const Text('Resumen'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resumen(String valor, String etiqueta, Color color) {
    return Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valor,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            etiqueta,
            style: const TextStyle(color: CrediColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _acceso(IconData icon, String texto, VoidCallback onTap) {
    return Tarjeta(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: CrediColors.vino),
          const SizedBox(height: 8),
          Text(texto, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class AccionBloqueadaPage extends StatelessWidget {
  const AccionBloqueadaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: barra('Acción no permitida'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            const CircleAvatar(
              radius: 36,
              backgroundColor: CrediColors.rosaSuave,
              child: Icon(Icons.block, color: CrediColors.vino, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Esta operación está fuera del alcance',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const Text(
              'CrediAPP no transfiere dinero ni funciona como billetera. Solo permite registrar y controlar préstamos, cuotas y pagos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: CrediColors.muted, height: 1.4),
            ),
            const Spacer(),
            BotonVino(
              texto: 'Volver al menú',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key, this.token});

  final String? token;

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final _form = GlobalKey<FormState>();

  late final nombre = TextEditingController(
    text: store.nombre.isNotEmpty
        ? store.nombre
        : Supabase.instance.client.auth.currentUser?.userMetadata?['nombre']
                  ?.toString() ??
              '',
  );

  late final telefono = TextEditingController(
    text: store.telefono.isNotEmpty
        ? store.telefono
        : Supabase.instance.client.auth.currentUser?.userMetadata?['telefono']
                  ?.toString() ??
              '',
  );

  late final correo = TextEditingController(
    text: Supabase.instance.client.auth.currentUser?.email ?? store.correo,
  );

  bool get _hayCambios =>
      nombre.text.trim() != store.nombre ||
      telefono.text.trim() != store.telefono;

  Future<void> _salir() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que deseas salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    try {
      await supabaseAuthService.cerrarSesion();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    } on AuthException {
      if (!mounted) return;
      aviso(context, 'No se pudo cerrar la sesión. Inténtalo nuevamente.');
    } catch (_) {
      if (!mounted) return;
      aviso(context, 'Error al cerrar sesión. Comprueba tu conexión.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombrePerfil = store.nombre.trim();
    final ini = nombrePerfil
        .split(RegExp(r'\s+'))
        .where((parte) => parte.isNotEmpty)
        .toList();

    final sigla = ini.isEmpty
        ? '?'
        : ini.length > 1
        ? '${ini[0][0]}${ini[1][0]}'.toUpperCase()
        : ini[0][0].toUpperCase();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(
            child: Text(
              'Mi perfil',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: CircleAvatar(
              radius: 36,
              backgroundColor: CrediColors.vino,
              child: Text(
                sigla,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              store.nombre,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          const Center(
            child: Text(
              'Prestamista',
              style: TextStyle(color: CrediColors.muted),
            ),
          ),
          const SizedBox(height: 18),
          Form(
            key: _form,
            child: Column(
              children: [
                Campo(
                  label: 'Nombre completo',
                  controller: nombre,
                  validator: vNombre,
                  onChanged: (_) => setState(() {}),
                ),
                Campo(
                  label: 'Correo electrónico (protegido)',
                  controller: correo,
                  locked: true,
                ),
                Campo(
                  label: 'Teléfono',
                  controller: telefono,
                  keyboard: TextInputType.phone,
                  validator: vTelefono,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          BotonVino(
            texto: 'Guardar cambios',
            onPressed: _hayCambios
                ? () {
                    if (!_form.currentState!.validate()) return;
                    store.actualizarPerfil(
                      nombre: nombre.text.trim(),
                      telefono: telefono.text.trim(),
                    );
                    setState(() {});
                    aviso(context, 'Perfil actualizado');
                  }
                : null,
          ),
          const SizedBox(height: 16),
          Tarjeta(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SeguridadPage()),
            ).then((_) => setState(() => correo.text = store.correo)),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: CrediColors.vino),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Seguridad: contraseña y correo',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Icon(Icons.chevron_right),
              ],
            ),
          ),
          TextButton(
            onPressed: _salir,
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(
                color: CrediColors.vino,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  String q = '';
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    final usuario = Supabase.instance.client.auth.currentUser;
    if (usuario == null) {
      if (mounted) setState(() { _cargando = false; _error = 'Inicia sesión para ver tus clientes.'; });
      return;
    }
    try {
      final filas = await Supabase.instance.client
          .from('clientes')
          .select('id, nombre_cliente, dni_cliente, telefono_cliente, direccion_cliente')
          .eq('usuario_id', usuario.id)
          .order('nombre_cliente');
      final cargados = (filas as List).map((fila) => Cliente(
        id: fila['id'].toString(),
        nombre: (fila['nombre_cliente'] ?? '').toString(),
        dni: (fila['dni_cliente'] ?? '').toString(),
        telefono: (fila['telefono_cliente'] ?? '').toString(),
        direccion: (fila['direccion_cliente'] ?? '').toString(),
      )).toList();
      if (!mounted) return;
      store.clientes
        ..clear()
        ..addAll(cargados);
      store.notifyListeners();
      setState(() { _cargando = false; _error = null; });
    } catch (e, stackTrace) {
      // Diagnóstico temporal: muestra en la terminal el error real de Supabase.
      debugPrint('ERROR REAL AL CARGAR CLIENTES DESDE SUPABASE: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'Error de Supabase: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lista = store.clientes.where((c) {
      final t = q.toLowerCase();
      return c.nombre.toLowerCase().contains(t) || c.dni.contains(t);
    }).toList();
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: CrediColors.vino,
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const ClienteFormPage()));
          if (mounted) _cargarClientes();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          children: [
            const Center(child: Text('Clientes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
            const SizedBox(height: 12),
            TextField(onChanged: (v) => setState(() => q = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar por nombre o DNI')),
            const SizedBox(height: 12),
            if (_cargando) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
            if (_error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(_error!, style: const TextStyle(color: Colors.red))),
            if (!_cargando && _error == null) Text('${lista.length} clientes', style: const TextStyle(color: CrediColors.muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (!_cargando && _error == null) ...lista.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Tarjeta(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HistorialClientePage(cliente: c))),
                child: Row(children: [
                  AvatarIni(texto: c.iniciales), const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('DNI ${c.dni}', style: const TextStyle(color: CrediColors.muted, fontSize: 12)),
                  ])),
                  ChipEstado(texto: store.estadoCliente(c)),
                ]),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class ClienteFormPage extends StatefulWidget {
  const ClienteFormPage({super.key, this.cliente});

  final Cliente? cliente;

  @override
  State<ClienteFormPage> createState() => _ClienteFormPageState();
}

class _ClienteFormPageState extends State<ClienteFormPage> {
  late final nombre = TextEditingController(text: widget.cliente?.nombre ?? '');
  late final dni = TextEditingController(text: widget.cliente?.dni ?? '');
  late final telefono = TextEditingController(
    text: widget.cliente?.telefono ?? '',
  );
  late final direccion = TextEditingController(
    text: widget.cliente?.direccion ?? '',
  );

  bool get editando => widget.cliente != null;
  bool _guardando = false;

  Future<void> _guardarCliente() async {
    if (_guardando) return;
    final nombreIngresado = nombre.text.trim();
    final dniIngresado = dni.text.trim();
    final telefonoIngresado = telefono.text.trim();
    if (telefonoIngresado.length != 9 || !telefonoIngresado.startsWith('9')) { aviso(context, 'El teléfono debe tener 9 dígitos y empezar con 9'); return; }
    if (!editando && nombreIngresado.isEmpty) { aviso(context, 'Ingresa los nombres y apellidos'); return; }
    if (!editando && !RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ'’\- ]+$").hasMatch(nombreIngresado)) { aviso(context, 'El nombre solo puede contener letras y espacios'); return; }
    if (!editando && !RegExp(r'^\d{8}$').hasMatch(dniIngresado)) { aviso(context, 'El DNI debe tener exactamente 8 dígitos'); return; }
    final usuario = Supabase.instance.client.auth.currentUser;
    if (usuario == null) { aviso(context, 'Tu sesión ha caducado. Inicia sesión nuevamente.'); return; }
    setState(() => _guardando = true);
    try {
      if (editando) {
        await Supabase.instance.client.from('clientes').update({ 'telefono_cliente': telefonoIngresado, 'direccion_cliente': direccion.text.trim() }).eq('id', widget.cliente!.id).eq('usuario_id', usuario.id);
        store.editarCliente(widget.cliente!, telefono: telefonoIngresado, direccion: direccion.text.trim());
      } else {
        final fila = await Supabase.instance.client.from('clientes').insert({ 'usuario_id': usuario.id, 'nombre_cliente': nombreIngresado, 'dni_cliente': dniIngresado, 'telefono_cliente': telefonoIngresado, 'direccion_cliente': direccion.text.trim() }).select('id, nombre_cliente, dni_cliente, telefono_cliente, direccion_cliente').single();
        store.agregarCliente(Cliente(id: fila['id'].toString(), nombre: fila['nombre_cliente'].toString(), dni: fila['dni_cliente'].toString(), telefono: fila['telefono_cliente'].toString(), direccion: (fila['direccion_cliente'] ?? '').toString()));
      }
      if (!mounted) return;
      aviso(context, 'Cliente guardado en Supabase');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) aviso(context, 'No se pudo guardar en Supabase. Revisa las columnas de la tabla clientes y sus políticas RLS.');
    } finally { if (mounted) setState(() => _guardando = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: barra(editando ? 'Editar cliente' : 'Nuevo cliente'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Campo(
            label: 'Nombres y apellidos',
            controller: nombre,
            readOnly: editando,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r"[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ'’\- ]"),
              ),
            ],
          ),
          Campo(
            label: 'Documento (DNI)',
            controller: dni,
            keyboard: TextInputType.number,
            readOnly: editando,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
            ],
          ),
          Campo(
            label: 'Teléfono',
            controller: telefono,
            keyboard: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(9),
            ],
          ),
          Campo(label: 'Dirección', controller: direccion),
          if (editando)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'El nombre y el documento quedan bloqueados.',
                style: TextStyle(color: CrediColors.muted, fontSize: 12),
              ),
            ),
          BotonVino(
            texto: editando ? 'Guardar cambios' : 'Guardar cliente',
            onPressed: _guardando ? null : _guardarCliente,
          ),
        ],
      ),
    );
  }
}

class HistorialClientePage extends StatelessWidget {
  const HistorialClientePage({super.key, required this.cliente});

  final Cliente cliente;

  @override
  Widget build(BuildContext context) {
    final lista = store.prestamosDe(cliente.id);
    return Scaffold(
      appBar: barra('Historial del cliente'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Tarjeta(
            child: Row(
              children: [
                AvatarIni(texto: cliente.iniciales, radio: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente.nombre,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'DNI ${cliente.dni}',
                        style: const TextStyle(color: CrediColors.muted),
                      ),
                      Text(
                        cliente.telefono,
                        style: const TextStyle(
                          color: CrediColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClienteFormPage(cliente: cliente),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EstadoPrestamosPage(cliente: cliente),
              ),
            ),
            child: const Text('Ver estado de préstamos'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Préstamos y comportamiento de pago',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (lista.isEmpty) const Text('Este cliente aún no tiene préstamos.'),
          ...lista.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Tarjeta(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetallePrestamoPage(prestamo: p),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Préstamo #${p.codigo}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${p.pagadas}/${p.cuotas.length} cuotas al día',
                            style: const TextStyle(
                              color: CrediColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          soles(p.monto),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        ChipEstado(texto: etiquetaEstado(p.estado)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EstadoPrestamosPage extends StatelessWidget {
  const EstadoPrestamosPage({super.key, required this.cliente});

  final Cliente cliente;

  @override
  Widget build(BuildContext context) {
    final lista = store.prestamosDe(cliente.id);
    final alDia = lista
        .where(
          (p) =>
              p.estado == EstadoPrestamo.activo ||
              p.estado == EstadoPrestamo.cancelado,
        )
        .length;
    final atrasos = lista
        .where((p) => p.estado == EstadoPrestamo.atrasado)
        .length;
    return Scaffold(
      appBar: barra('Estado de préstamos'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            cliente.nombre,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _caja('$alDia', 'Al día / cerrados', CrediColors.verde),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _caja('$atrasos', 'Con atraso', const Color(0xFFB42318)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...lista.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Tarjeta(
                child: Row(
                  children: [
                    Expanded(child: Text('Préstamo #${p.codigo}')),
                    ChipEstado(texto: etiquetaEstado(p.estado)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _caja(String n, String t, Color c) {
    return Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            n,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: c,
            ),
          ),
          Text(t, style: const TextStyle(color: CrediColors.muted)),
        ],
      ),
    );
  }
}

class PrestamosPage extends StatefulWidget {
  const PrestamosPage({super.key});

  @override
  State<PrestamosPage> createState() => _PrestamosPageState();
}

class _PrestamosPageState extends State<PrestamosPage> {
  String filtro = 'Todos';
  String q = '';
  bool _cargando = true;
  String? _errorCarga;

  @override
  void initState() {
    super.initState();
    _cargarPrestamosSupabase();
  }

  Future<void> _cargarPrestamosSupabase() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
      _errorCarga = null;
    });
    await _cargarDatosUsuarioIniciales();
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _errorCarga = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lista = store.prestamos.where((p) {
      final cliente = store.clienteDe(p.clienteId).nombre.toLowerCase();
      final okTexto =
          cliente.contains(q.toLowerCase()) ||
          p.codigo.contains(q) ||
          etiquetaEstado(p.estado).toLowerCase().contains(q.toLowerCase());
      final okEstado =
          filtro == 'Todos' ||
          (filtro == 'Activos' && p.estado == EstadoPrestamo.activo) ||
          (filtro == 'Atrasados' && p.estado == EstadoPrestamo.atrasado) ||
          (filtro == 'Cancelados' && p.estado == EstadoPrestamo.cancelado) ||
          (filtro == 'Finalizados' && p.estado == EstadoPrestamo.finalizado);
      return okTexto && okEstado;
    }).toList();
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: CrediColors.vino,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NuevoPrestamoPage()),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          children: [
            const Center(
              child: Text(
                'Préstamos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => q = v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Filtrar por cliente o estado',
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: ['Todos', 'Activos', 'Atrasados', 'Cancelados', 'Finalizados'].map((
                f,
              ) {
                final sel = filtro == f;
                return ChoiceChip(
                  label: Text(f),
                  selected: sel,
                  selectedColor: CrediColors.vinoOscuro,
                  labelStyle: TextStyle(
                    color: sel ? Colors.white : CrediColors.texto,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => filtro = f),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            if (_cargando)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!_cargando && _errorCarga != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Text(_errorCarga!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  OutlinedButton(onPressed: _cargarPrestamosSupabase, child: const Text('Reintentar')),
                ]),
              ),
            if (!_cargando && _errorCarga == null && lista.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Aún no tienes préstamos registrados')),
              ),
            if (!_cargando && _errorCarga == null) ...lista.map((p) {
              final coincidenciasCliente = store.clientes.where((x) => x.id == p.clienteId).toList();
              final c = coincidenciasCliente.isNotEmpty ? coincidenciasCliente.first : Cliente(id: p.clienteId, nombre: 'Cliente no encontrado', dni: '', telefono: '', direccion: '');
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Tarjeta(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetallePrestamoPage(prestamo: p),
                    ),
                  ),
                  child: Row(
                    children: [
                      AvatarIni(texto: c.iniciales),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Préstamo #${p.codigo}',
                              style: const TextStyle(
                                color: CrediColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            soles(
                              p.estado == EstadoPrestamo.cancelado
                                  ? 0
                                  : p.monto,
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          ChipEstado(texto: etiquetaEstado(p.estado)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _LimiteNumericoFormatter extends TextInputFormatter {
  _LimiteNumericoFormatter({required this.maximo, this.decimales = 0});
  final double maximo;
  final int decimales;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final patron = decimales > 0 ? RegExp('^[0-9]*[.,]?[0-9]{0,$decimales}\$') : RegExp(r'^\d*$');
    if (!patron.hasMatch(newValue.text)) return oldValue;
    final numero = double.tryParse(newValue.text.replaceAll(',', '.'));
    if (numero != null && numero > maximo) return oldValue;
    return newValue;
  }
}

class NuevoPrestamoPage extends StatefulWidget {
  const NuevoPrestamoPage({super.key});

  @override
  State<NuevoPrestamoPage> createState() => _NuevoPrestamoPageState();
}

class _NuevoPrestamoPageState extends State<NuevoPrestamoPage> {
  String? clienteId = store.clientes.isNotEmpty ? store.clientes.first.id : null;
  final monto = TextEditingController(text: '800.00');
  final tasa = TextEditingController(text: '5');
  final cuotas = TextEditingController(text: '4');
  String frecuencia = 'Semanal';
  DateTime fechaEmision = DateTime.now();
  bool _guardando = false;

  String get _fechaTexto =>
      '${fechaEmision.day.toString().padLeft(2, '0')}/${fechaEmision.month.toString().padLeft(2, '0')}/${fechaEmision.year}';

  DateTime _sumarMes(DateTime fecha, int meses) {
    final mes = fecha.month + meses;
    final anio = fecha.year + ((mes - 1) ~/ 12);
    final mesFinal = ((mes - 1) % 12) + 1;
    final ultimoDia = DateTime(anio, mesFinal + 1, 0).day;
    return DateTime(anio, mesFinal, fecha.day > ultimoDia ? ultimoDia : fecha.day);
  }

  String _fechaSql(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fechaCorta(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: fechaEmision.isBefore(DateTime(hoy.year, hoy.month, hoy.day))
          ? DateTime(hoy.year, hoy.month, hoy.day)
          : fechaEmision,
      firstDate: DateTime(hoy.year, hoy.month, hoy.day),
      lastDate: DateTime(hoy.year, hoy.month, hoy.day).add(const Duration(days: 30)),
      helpText: 'Fecha de emisión (hoy hasta 30 días)',
    );
    if (elegida != null && mounted) setState(() => fechaEmision = elegida);
  }

  Future<void> _registrar() async {
    if (_guardando) return;
    final m = double.tryParse(monto.text.trim().replaceAll(',', '.'));
    final t = double.tryParse(tasa.text.trim().replaceAll(',', '.'));
    final n = int.tryParse(cuotas.text.trim());

    if (clienteId == null || !store.clientes.any((c) => c.id == clienteId)) {
      aviso(context, 'Selecciona un cliente válido');
      return;
    }
    if (m == null || !m.isFinite || m < 1 || m > 300000) {
      aviso(context, 'El monto debe estar entre S/ 1 y S/ 300,000');
      return;
    }
    if (t == null || !t.isFinite || t < 0 || t > 100) {
      aviso(context, 'La tasa debe estar entre 0% y 100%');
      return;
    }
    final maxCuotas = frecuencia == 'Semanal' ? 52 : (frecuencia == 'Quincenal' ? 24 : 12);
    if (n == null || n < 1 || n > maxCuotas) {
      aviso(context, 'Para frecuencia $frecuencia, usa entre 1 y $maxCuotas cuotas');
      return;
    }
    final hoy = DateTime.now();
    final hoyFecha = DateTime(hoy.year, hoy.month, hoy.day);
    final limiteFecha = hoyFecha.add(const Duration(days: 30));
    final fechaSeleccionada = DateTime(fechaEmision.year, fechaEmision.month, fechaEmision.day);
    if (fechaSeleccionada.isBefore(hoyFecha) || fechaSeleccionada.isAfter(limiteFecha)) {
      aviso(context, 'La fecha de emisión debe estar entre hoy y los próximos 30 días');
      return;
    }

    final usuario = Supabase.instance.client.auth.currentUser;
    if (usuario == null) {
      aviso(context, 'Inicia sesión para registrar el préstamo');
      return;
    }

    setState(() => _guardando = true);
    String? prestamoId;
    try {
      final db = Supabase.instance.client;
      final fila = await db.from('prestamos').insert({
        'usuario_id': usuario.id,
        'cliente_id': clienteId,
        'fecha_emision': _fechaSql(fechaEmision),
        'monto_prestado': m,
        'tasa_interes': t,
        'numero_cuotas': n,
        'frecuencia_pago': frecuencia.toLowerCase(),
        'estado_prestamo': 'activo',
      }).select('id').single();
      prestamoId = fila['id'] as String;

      final montoCuota = double.parse(((m * (1 + t / 100)) / n).toStringAsFixed(2));
      final filasCuotas = List.generate(n, (i) {
        DateTime vencimiento;
        if (frecuencia == 'Semanal') {
          vencimiento = fechaEmision.add(Duration(days: 7 * (i + 1)));
        } else if (frecuencia == 'Quincenal') {
          vencimiento = fechaEmision.add(Duration(days: 14 * (i + 1)));
        } else {
          vencimiento = _sumarMes(fechaEmision, i + 1);
        }
        return {
          'usuario_id': usuario.id,
          'prestamo_id': prestamoId,
          'numero_cuota': i + 1,
          'fecha_vencimiento': _fechaSql(vencimiento),
          'monto_programado': montoCuota,
          'estado_cuota': 'pendiente',
        };
      });
      final filasCuotasGuardadas = await db
          .from('cuotas')
          .insert(filasCuotas)
          .select('id, numero_cuota');

      final idCuotaPorNumero = <int, String>{
        for (final fila in (filasCuotasGuardadas as List))
          (fila['numero_cuota'] as num).toInt(): fila['id'].toString(),
      };

      final cuotasLocales = List.generate(n, (i) {
        DateTime vencimiento;
        if (frecuencia == 'Semanal') {
          vencimiento = fechaEmision.add(Duration(days: 7 * (i + 1)));
        } else if (frecuencia == 'Quincenal') {
          vencimiento = fechaEmision.add(Duration(days: 14 * (i + 1)));
        } else {
          vencimiento = _sumarMes(fechaEmision, i + 1);
        }
        return Cuota(
          id: idCuotaPorNumero[i + 1],
          numero: i + 1,
          fecha: _fechaCorta(vencimiento),
          monto: montoCuota,
          estado: EstadoCuota.pendiente,
        );
      });
      final p = store.registrarPrestamo(
        clienteId: clienteId!, monto: m, tasa: t, nCuotas: n,
        frecuencia: frecuencia, fecha: _fechaTexto,
        id: prestamoId, cuotasGeneradas: cuotasLocales,
      );
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CronogramaPage(prestamo: p)));
    } catch (e) {
      // Si falló el guardado de cuotas, se intenta revertir el préstamo para no dejarlo incompleto.
      if (prestamoId != null) {
        try {
          await Supabase.instance.client.from('prestamos').delete().eq('id', prestamoId).eq('usuario_id', usuario.id);
        } catch (_) {}
      }
      if (mounted) aviso(context, 'No se pudo guardar el préstamo y sus cuotas en Supabase: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  void dispose() {
    monto.dispose();
    tasa.dispose();
    cuotas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: barra('Nuevo préstamo'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Cliente', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: clienteId,
            items: store.clientes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre))).toList(),
            onChanged: _guardando ? null : (v) => setState(() => clienteId = v),
          ),
          const SizedBox(height: 14),
          Campo(label: 'Monto (S/ 1–300,000)', controller: monto, keyboard: const TextInputType.numberWithOptions(decimal: true), suffix: 'S/', inputFormatters: [_LimiteNumericoFormatter(maximo: 300000, decimales: 2)]),
          Campo(label: 'Tasa de interés (0–100%)', controller: tasa, keyboard: const TextInputType.numberWithOptions(decimal: true), suffix: '%', inputFormatters: [_LimiteNumericoFormatter(maximo: 100, decimales: 2)]),
          Campo(label: 'Número de cuotas (según frecuencia)', controller: cuotas, keyboard: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)]),
          const Text('Frecuencia de pago', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: frecuencia,
            items: const ['Semanal', 'Quincenal', 'Mensual'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
            onChanged: _guardando ? null : (v) { if (v != null) setState(() => frecuencia = v); },
          ),
          const SizedBox(height: 14),
          const Text('Fecha de emisión', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: _guardando ? null : _elegirFecha, icon: const Icon(Icons.calendar_today), label: Text(_fechaTexto)),
          const SizedBox(height: 8),
          const Text('Monto máximo S/ 300,000 · tasa máxima 100%. Cuotas: semanal hasta 52, quincenal hasta 24 y mensual hasta 12. Fecha: hoy o dentro de los próximos 30 días.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          BotonVino(texto: _guardando ? 'Guardando...' : 'Registrar préstamo', onPressed: _guardando ? null : _registrar),
        ],
      ),
    );
  }
}

class CronogramaPage extends StatelessWidget {
  const CronogramaPage({super.key, required this.prestamo});

  final Prestamo prestamo;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final coincidencias = store.prestamos.where((p) => p.id == prestamo.id);
        final actual = coincidencias.isEmpty ? prestamo : coincidencias.first;
        final cliente = store.clienteDe(actual.clienteId);
        return Scaffold(
          appBar: barra('Cronograma de pagos'),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${cliente.nombre} · #${actual.codigo}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                '${actual.frecuencia} · ${soles(actual.monto)}',
                style: const TextStyle(color: CrediColors.muted),
              ),
              const SizedBox(height: 12),
              ...actual.cuotas.map((c) {
                final estado = c.saldoPendiente <= 0.001 || c.estado == EstadoCuota.pagada
                    ? 'PAGADA'
                    : c.estado == EstadoCuota.vencida
                        ? 'VENCIDA'
                        : c.montoPagado > 0 ? 'ABONO PARCIAL' : 'PENDIENTE';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Tarjeta(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '#${c.numero.toString().padLeft(2, '0')} · ${c.fecha}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(soles(c.saldoPendiente),
                                style: const TextStyle(fontWeight: FontWeight.w800)),
                            ChipEstado(texto: estado),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              if (actual.saldo > 0.001)
                BotonVino(
                  texto: 'Registrar pago',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RegistrarPagoPage(prestamo: actual),
                      ),
                    );
                    await _cargarDatosUsuarioIniciales();
                  },
                )
              else
                const ChipEstado(texto: 'FINALIZADO'),
            ],
          ),
        );
      },
    );
  }
}

class DetallePrestamoPage extends StatelessWidget {
  const DetallePrestamoPage({super.key, required this.prestamo});

  final Prestamo prestamo;

  @override
  Widget build(BuildContext context) {
    final cliente = store.clienteDe(prestamo.clienteId);
    final avance = prestamo.cuotas.isEmpty
        ? 0.0
        : prestamo.pagadas / prestamo.cuotas.length;
    return Scaffold(
      appBar: barra('Detalle del préstamo'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            cliente.nombre,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          Text(
            'Préstamo #${prestamo.codigo}',
            style: const TextStyle(color: CrediColors.muted),
          ),
          const SizedBox(height: 12),
          Tarjeta(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fila('Monto', soles(prestamo.monto)),
                _fila('Saldo', soles(prestamo.saldo)),
                _fila('Tasa', '${prestamo.tasa.toStringAsFixed(0)}%'),
                _fila('Frecuencia', prestamo.frecuencia),
                _fila('Cuotas pagadas', '${prestamo.pagadas}'),
                _fila(
                  'Cuotas pendientes',
                  '${prestamo.cuotas.length - prestamo.pagadas}',
                ),
                const SizedBox(height: 8),
                const Text('Avance'),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: avance,
                    minHeight: 8,
                    color: CrediColors.vino,
                    backgroundColor: CrediColors.rosaSuave,
                  ),
                ),
                const SizedBox(height: 8),
                ChipEstado(texto: etiquetaEstado(prestamo.estado)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          BotonVino(
            texto: 'Ver cronograma',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CronogramaPage(prestamo: prestamo),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HistorialPagosPage(prestamo: prestamo),
              ),
            ),
            child: const Text('Historial de pagos'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ObservacionPage(prestamo: prestamo),
              ),
            ),
            child: const Text('Registrar observación'),
          ),
          if (prestamo.observaciones.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Observaciones',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            ...prestamo.observaciones.map(
              (o) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Tarjeta(child: Text(o)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fila(String a, String b) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(a, style: const TextStyle(color: CrediColors.muted)),
          ),
          Text(b, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class ElegirPrestamoPagoPage extends StatefulWidget {
  const ElegirPrestamoPagoPage({super.key});

  @override
  State<ElegirPrestamoPagoPage> createState() => _ElegirPrestamoPagoPageState();
}

class _ElegirPrestamoPagoPageState extends State<ElegirPrestamoPagoPage> {
  final busqueda = TextEditingController();
  String filtro = 'Todos';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final q = busqueda.text.trim().toLowerCase();
        final lista = store.prestamos.where((p) {
          if (p.estado == EstadoPrestamo.cancelado) return false;
          if (filtro == 'Atrasados' && p.estado != EstadoPrestamo.atrasado)
            return false;
          if (filtro == 'Al día' && p.estado != EstadoPrestamo.activo)
            return false;
          if (q.isNotEmpty) {
            final c = store.clienteDe(p.clienteId);
            if (!'${c.nombre} ${c.dni} ${p.codigo}'.toLowerCase().contains(q))
              return false;
          }
          return true;
        }).toList();

        return Scaffold(
          appBar: barra('Registrar pago'),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: busqueda,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, DNI o #préstamo',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: q.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(busqueda.clear),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Todos', 'Atrasados', 'Al día']
                      .map(
                        (f) => FiltroChip(
                          texto: f,
                          activo: filtro == f,
                          onTap: () => setState(() => filtro = f),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 10),
              if (lista.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'Sin resultados',
                      style: TextStyle(color: CrediColors.muted),
                    ),
                  ),
                ),
              ...lista.map((p) {
                final c = store.clienteDe(p.clienteId);
                final atrasado = p.estado == EstadoPrestamo.atrasado;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Tarjeta(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RegistrarPagoPage(prestamo: p),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '#${p.codigo} · ${p.frecuencia}',
                                style: const TextStyle(
                                  color: CrediColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              soles(p.saldo),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            ChipEstado(texto: atrasado ? 'ATRASADO' : 'ACTIVO'),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class RegistrarPagoPage extends StatefulWidget {
  const RegistrarPagoPage({super.key, required this.prestamo, this.cuota});

  final Prestamo prestamo;
  final Cuota? cuota;

  @override
  State<RegistrarPagoPage> createState() => _RegistrarPagoPageState();
}

class _RegistrarPagoPageState extends State<RegistrarPagoPage> {
  Cuota? seleccion;
  final monto = TextEditingController();
  final fecha = TextEditingController(text: hoyTexto());

  @override
  void initState() {
    super.initState();
    final pend = widget.prestamo.cuotas
        .where((x) => x.saldoPendiente > 0)
        .toList();
    seleccion = widget.cuota ?? (pend.isEmpty ? null : pend.first);
    monto.text = seleccion?.saldoPendiente.toStringAsFixed(2) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.prestamo;
    final c = store.clienteDe(p.clienteId);
    final pendientes = p.cuotas
        .where((x) => x.saldoPendiente > 0)
        .toList();

    return Scaffold(
      appBar: barra('Registrar pago'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CrediColors.vinoOscuro,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'DNI ${c.dni}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'PRÉSTAMO #${p.codigo}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: CrediColors.verdeSuave,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Saldo ${soles(p.saldo)}',
                        style: const TextStyle(
                          color: CrediColors.verde,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Cuotas pendientes',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (pendientes.isEmpty) const Text('No hay cuotas pendientes.'),
          ...pendientes.map((cuota) {
            final sel = seleccion == cuota;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Tarjeta(
                color: sel ? CrediColors.rosaSuave : Colors.white,
                onTap: () => setState(() {
                  seleccion = cuota;
                  monto.text = cuota.saldoPendiente.toStringAsFixed(2);
                }),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${cuota.numero.toString().padLeft(2, '0')} · ${cuota.fecha}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            cuota.estado == EstadoCuota.pagada
                                ? 'PAGADA'
                                : cuota.montoPagado > 0
                                    ? 'ABONO PARCIAL'
                                    : cuota.estado == EstadoCuota.vencida
                                        ? 'VENCIDA'
                                        : 'PENDIENTE',
                            style: const TextStyle(
                              fontSize: 12,
                              color: CrediColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      soles(cuota.saldoPendiente),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            );
          }),
          Campo(
            label: 'Monto recibido',
            controller: monto,
            keyboard: TextInputType.number,
            suffix: 'S/',
          ),
          Campo(
            label: 'Fecha',
            controller: fecha,
            readOnly: true,
            onTap: () async {
              final ahora = DateTime.now();
              final inicial = DateTime.tryParse(
                    fecha.text.split('/').length == 3
                        ? fecha.text.split('/').reversed.join('-')
                        : fecha.text,
                  ) ?? ahora;
              final elegida = await showDatePicker(
                context: context,
                initialDate: inicial.isAfter(ahora) ? ahora : inicial,
                firstDate: DateTime(2020),
                lastDate: ahora,
                helpText: 'Selecciona la fecha del pago',
                confirmText: 'Aceptar',
              );
              if (elegida != null) {
                fecha.text = '${elegida.day.toString().padLeft(2, '0')}/${elegida.month.toString().padLeft(2, '0')}/${elegida.year}';
              }
            },
          ),

          BotonVino(
            texto: 'Registrar pago',
            onPressed: seleccion == null ? null : () async {
              final cuota = seleccion!;
              final m = double.tryParse(monto.text.trim().replaceAll(',', '.'));
              if (m == null || !m.isFinite || m <= 0) {
                aviso(context, 'Ingresa un monto válido mayor que cero');
                return;
              }
              if (cuota.id == null || cuota.id!.isEmpty) {
                aviso(context, 'No se encontró el identificador de la cuota. Actualiza los datos e inténtalo de nuevo.');
                return;
              }
              if (m > cuota.saldoPendiente + 0.001) {
                aviso(context, 'El monto supera el saldo pendiente (${soles(cuota.saldoPendiente)})');
                return;
              }
              final partes = fecha.text.trim().split('/');
              DateTime? fechaElegida;
              if (partes.length == 3) {
                fechaElegida = DateTime.tryParse('${partes[2]}-${partes[1].padLeft(2, '0')}-${partes[0].padLeft(2, '0')}');
              } else {
                fechaElegida = DateTime.tryParse(fecha.text.trim());
              }
              if (fechaElegida == null || fechaElegida.isAfter(DateTime.now().add(const Duration(days: 1)))) {
                aviso(context, 'Ingresa una fecha válida que no sea futura');
                return;
              }
              try {
                await Supabase.instance.client.rpc('registrar_pago_cuota', params: {
                  'p_cuota_id': cuota.id,
                  'p_monto': m,
                  'p_fecha_pago': fechaElegida.toIso8601String(),
                  'p_metodo_pago': 'efectivo',
                  'p_tipo_movimiento': 'abono',
                  'p_observacion': null,
                });
                await _cargarDatosUsuarioIniciales();
                if (!context.mounted) return;
                aviso(context, 'Pago guardado correctamente');
                Navigator.pop(context, true);
              } catch (e) {
                if (!context.mounted) return;
                aviso(context, 'No se pudo registrar el pago: ${e.toString().replaceFirst('Exception: ', '')}');
              }
            },
          ),
        ],
      ),
    );
  }
}

class HistorialPagosPage extends StatelessWidget {
  const HistorialPagosPage({super.key, required this.prestamo});

  final Prestamo prestamo;

  @override
  Widget build(BuildContext context) {
    final movimientos = store.pagos.where((p) => p.prestamoId == prestamo.id).toList();
    final cliente = store.clienteDe(prestamo.clienteId).nombre;
    return Scaffold(
      appBar: barra('Historial de pagos'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '$cliente · #${prestamo.codigo}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (movimientos.isEmpty) const Text('Aún no hay pagos en este préstamo.'),
          ...movimientos.map(
            (pago) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Tarjeta(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${pago.detalle.isEmpty ? 'Pago de cuota' : pago.detalle}\n${pago.fecha}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      soles(pago.monto),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CuotasPage extends StatefulWidget {
  const CuotasPage({super.key});

  @override
  State<CuotasPage> createState() => _CuotasPageState();
}

class _CuotasPageState extends State<CuotasPage> {
  final busqueda = TextEditingController();
  String estado = 'Todas';
  String frecuencia = 'Todas';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final q = busqueda.text.trim().toLowerCase();
        final items = store.cuotasPorCobrar.where((e) {
          final vencida = e.value.estado == EstadoCuota.vencida;
          if (estado == 'Vencidas' && !vencida) return false;
          if (estado == 'Pendientes' && vencida) return false;
          if (frecuencia != 'Todas' && e.key.frecuencia != frecuencia)
            return false;
          if (q.isNotEmpty) {
            final c = store.clienteDe(e.key.clienteId);
            if (!'${c.nombre} ${e.key.codigo}'.toLowerCase().contains(q))
              return false;
          }
          return true;
        }).toList();
        final total = items.fold<double>(0, (s, e) => s + e.value.monto);

        return Scaffold(
          appBar: barra('Cuotas por cobrar'),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: busqueda,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Buscar por cliente o #préstamo',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: q.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(busqueda.clear),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Todas', 'Vencidas', 'Pendientes']
                      .map(
                        (f) => FiltroChip(
                          texto: f,
                          activo: estado == f,
                          onTap: () => setState(() => estado = f),
                        ),
                      )
                      .toList(),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Todas', 'Semanal', 'Quincenal', 'Mensual']
                      .map(
                        (f) => FiltroChip(
                          texto: f,
                          activo: frecuencia == f,
                          onTap: () => setState(() => frecuencia = f),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${items.length} cuotas · ${soles(total)}',
                style: const TextStyle(
                  color: CrediColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'Sin cuotas para este filtro',
                      style: TextStyle(color: CrediColors.muted),
                    ),
                  ),
                ),
              ...items.map((e) {
                final cliente = store.clienteDe(e.key.clienteId);
                final vencida = e.value.estado == EstadoCuota.vencida;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Tarjeta(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RegistrarPagoPage(prestamo: e.key, cuota: e.value),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cliente.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '#${e.key.codigo} · cuota ${e.value.numero} · ${e.value.fecha}',
                                style: const TextStyle(
                                  color: CrediColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              soles(e.value.monto),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            ChipEstado(
                              texto: vencida ? 'VENCIDA' : 'PENDIENTE',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class AvisosPage extends StatefulWidget {
  const AvisosPage({super.key});

  @override
  State<AvisosPage> createState() => _AvisosPageState();
}

class _AvisosPageState extends State<AvisosPage> {
  final busqueda = TextEditingController();
  TipoAviso? tipo;
  bool soloNoLeidas = false;

  IconData _icono(TipoAviso t) {
    switch (t) {
      case TipoAviso.vencida:
        return Icons.error_outline;
      case TipoAviso.porVencer:
        return Icons.schedule;
      case TipoAviso.pago:
        return Icons.check_circle_outline;
    }
  }

  Widget _chip(String texto, bool activo, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(texto),
        selected: activo,
        selectedColor: CrediColors.vinoOscuro,
        labelStyle: TextStyle(
          color: activo ? Colors.white : CrediColors.texto,
          fontWeight: FontWeight.w700,
        ),
        showCheckmark: false,
        onSelected: (_) => onTap(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = busqueda.text.trim().toLowerCase();
    final lista = store.avisos.where((a) {
      if (tipo != null && a.tipo != tipo) return false;
      if (soloNoLeidas && a.leido) return false;
      if (q.isNotEmpty && !a.texto.toLowerCase().contains(q)) return false;
      return true;
    }).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Center(
            child: Text(
              'Notificaciones',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Avisos automáticos de cuotas y confirmaciones de pago.',
            style: TextStyle(color: CrediColors.muted),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: busqueda,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Buscar por cliente o préstamo',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: q.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(busqueda.clear),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('Todos', tipo == null, () => setState(() => tipo = null)),
                _chip(
                  'Vencidas',
                  tipo == TipoAviso.vencida,
                  () => setState(() => tipo = TipoAviso.vencida),
                ),
                _chip(
                  'Por vencer',
                  tipo == TipoAviso.porVencer,
                  () => setState(() => tipo = TipoAviso.porVencer),
                ),
                _chip(
                  'Pagos',
                  tipo == TipoAviso.pago,
                  () => setState(() => tipo = TipoAviso.pago),
                ),
                _chip(
                  'No leídas',
                  soloNoLeidas,
                  () => setState(() => soloNoLeidas = !soloNoLeidas),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (lista.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Sin resultados para este filtro',
                  style: TextStyle(color: CrediColors.muted),
                ),
              ),
            ),
          ...lista.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Tarjeta(
                onTap: () => setState(() => store.marcarLeido(a)),
                child: Row(
                  children: [
                    Icon(_icono(a.tipo), color: CrediColors.vino),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.texto,
                            style: TextStyle(
                              fontWeight: a.leido
                                  ? FontWeight.w400
                                  : FontWeight.w800,
                            ),
                          ),
                          Text(
                            a.fecha,
                            style: const TextStyle(
                              color: CrediColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!a.leido)
                      const Icon(
                        Icons.circle,
                        size: 10,
                        color: CrediColors.vino,
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          BotonVino(
            texto: 'Ver recordatorios',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RecordatoriosPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class RecordatoriosPage extends StatefulWidget {
  const RecordatoriosPage({super.key});

  @override
  State<RecordatoriosPage> createState() => _RecordatoriosPageState();
}

class _RecordatoriosPageState extends State<RecordatoriosPage> {
  final busqueda = TextEditingController();
  String estado = 'Pendientes';
  String? motivo;

  static const motivos = [
    'Cuota próxima a vencer',
    'Cuota vencida',
    'Confirmar pago',
  ];

  Widget _chip(String texto, bool activo, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(texto),
        selected: activo,
        selectedColor: CrediColors.vinoOscuro,
        labelStyle: TextStyle(
          color: activo ? Colors.white : CrediColors.texto,
          fontWeight: FontWeight.w700,
        ),
        showCheckmark: false,
        onSelected: (_) => onTap(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final q = busqueda.text.trim().toLowerCase();
        final lista = store.recordatorios.where((r) {
          if (estado == 'Pendientes' && r.cumplido) return false;
          if (estado == 'Cumplidos' && !r.cumplido) return false;
          if (motivo != null && r.motivo != motivo) return false;
          if (q.isNotEmpty && !r.titulo.toLowerCase().contains(q)) return false;
          return true;
        }).toList();

        return Scaffold(
          appBar: barra('Recordatorios'),
          floatingActionButton: FloatingActionButton(
            backgroundColor: CrediColors.vino,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NuevoRecordatorioPage()),
            ),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: busqueda,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Buscar por cliente o préstamo',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: q.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(busqueda.clear),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Pendientes', 'Cumplidos', 'Todos']
                      .map(
                        (e) => _chip(
                          e,
                          estado == e,
                          () => setState(() => estado = e),
                        ),
                      )
                      .toList(),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip(
                      'Todos los motivos',
                      motivo == null,
                      () => setState(() => motivo = null),
                    ),
                    ...motivos.map(
                      (m) => _chip(
                        m,
                        motivo == m,
                        () => setState(() => motivo = m),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (lista.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'Sin recordatorios para este filtro',
                      style: TextStyle(color: CrediColors.muted),
                    ),
                  ),
                ),
              ...lista.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Tarjeta(
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () async {
                            final usuario = Supabase.instance.client.auth.currentUser;
                            if (usuario == null || r.id == null) {
                              aviso(context, 'No se pudo identificar el recordatorio');
                              return;
                            }
                            final nuevoEstado = r.cumplido ? 'pendiente' : 'cumplido';
                            try {
  final estadoGuardar =
      nuevoEstado == 'cumplido' || nuevoEstado == 'completado'
          ? 'completado'
          : nuevoEstado;

  await Supabase.instance.client
      .from('recordatorios')
      .update({'estado': estadoGuardar})
      .eq('id', r.id!)
      .eq('usuario_id', usuario.id);

  store.alternarCumplido(r);
} catch (e) {
  aviso(context, 'No se pudo actualizar el recordatorio: $e');
}
                          },
                          icon: Icon(
                            r.cumplido
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: r.cumplido
                                ? CrediColors.verde
                                : CrediColors.muted,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.titulo,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  decoration: r.cumplido
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              Text(
                                r.motivo,
                                style: const TextStyle(
                                  color: CrediColors.muted,
                                ),
                              ),
                              Text(
                                '${r.fecha} · ${r.hora}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => store.eliminarRecordatorio(r),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: CrediColors.vino,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class NuevoRecordatorioPage extends StatefulWidget {
  const NuevoRecordatorioPage({super.key});

  @override
  State<NuevoRecordatorioPage> createState() => _NuevoRecordatorioPageState();
}

class _NuevoRecordatorioPageState extends State<NuevoRecordatorioPage> {
  late String prestamoId = store.prestamos.first.id;
  String motivo = 'Cuota próxima a vencer';
  final fecha = TextEditingController(text: '24/09/2026');
  final hora = TextEditingController(text: '09:00 a. m.');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: barra('Nuevo recordatorio'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Cliente / préstamo',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: prestamoId,
            items: store.prestamos.map((p) {
              final n = store
                  .clienteDe(p.clienteId)
                  .nombre
                  .split(' ')
                  .take(2)
                  .join(' ');
              return DropdownMenuItem(
                value: p.id,
                child: Text('$n · #${p.codigo}'),
              );
            }).toList(),
            onChanged: (v) => setState(() => prestamoId = v!),
          ),
          const SizedBox(height: 14),
          const Text('Motivo', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: motivo,
            items: const [
              'Cuota próxima a vencer',
              'Cuota vencida',
              'Confirmar pago',
            ].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) => setState(() => motivo = v!),
          ),
          const SizedBox(height: 14),
          Campo(
            label: 'Fecha de aviso',
            controller: fecha,
            readOnly: true,
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
              );
              if (d != null) {
                fecha.text =
                    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
              }
            },
          ),
          Campo(
            label: 'Hora',
            controller: hora,
            readOnly: true,
            onTap: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (t != null) hora.text = t.format(context);
            },
          ),
          BotonVino(
            texto: 'Programar recordatorio',
            onPressed: () async {
              final usuario = Supabase.instance.client.auth.currentUser;
              if (usuario == null) {
                aviso(context, 'Inicia sesión para guardar el recordatorio');
                return;
              }
              final coincidencias = store.prestamos.where((x) => x.id == prestamoId);
              if (coincidencias.isEmpty) {
                aviso(context, 'Selecciona un préstamo válido');
                return;
              }
              final p = coincidencias.first;
              final nombre = store.clienteDe(p.clienteId).nombre.split(' ').take(2).join(' ');
              final partesFecha = fecha.text.trim().split('/');
              if (partesFecha.length != 3) {
                aviso(context, 'Selecciona una fecha válida');
                return;
              }
              final d = DateTime.tryParse('${partesFecha[2]}-${partesFecha[1]}-${partesFecha[0]}');
              if (d == null) {
                aviso(context, 'Selecciona una fecha válida');
                return;
              }
              final horaMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(hora.text);
              var h = horaMatch == null ? 9 : int.parse(horaMatch.group(1)!);
              final min = horaMatch == null ? 0 : int.parse(horaMatch.group(2)!);
              if (hora.text.toLowerCase().contains('p. m.') && h < 12) h += 12;
              if (hora.text.toLowerCase().contains('a. m.') && h == 12) h = 0;
              final fechaHora = DateTime(d.year, d.month, d.day, h, min);
              try {
                final guardado = await Supabase.instance.client.from('recordatorios').insert({
                  'usuario_id': usuario.id,
                  'cliente_id': p.clienteId,
                  'prestamo_id': p.id,
                  'titulo': '$nombre · #${p.codigo}',
                  'descripcion': motivo,
                  'fecha_recordatorio': fechaHora.toIso8601String(),
                  'estado': 'pendiente',
                }).select('id').single();
                store.agregarRecordatorio(Recordatorio(
                  id: guardado['id'].toString(),
                  prestamoId: p.id,
                  titulo: '$nombre · #${p.codigo}',
                  motivo: motivo,
                  fecha: fecha.text.trim(),
                  hora: hora.text.trim(),
                ));
                if (!mounted) return;
                aviso(context, 'Recordatorio guardado en Supabase');
                Navigator.pop(context);
              } catch (e) {
                if (!mounted) return;
                aviso(context, 'No se pudo guardar el recordatorio: $e');
              }
            },
          ),
        ],
      ),
    );
  }
}

class CobrosPage extends StatefulWidget {
  const CobrosPage({super.key});

  @override
  State<CobrosPage> createState() => _CobrosPageState();
}

class _CobrosPageState extends State<CobrosPage> {
  static const _meses = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  String modo = 'mes';
  DateTimeRange? rango;

  Future<void> _elegirRango() async {
    final h = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(h.year + 1, 12, 31),
      initialDateRange: rango,
      helpText: 'Selecciona el rango de cobros',
      saveText: 'Aplicar',
    );
    if (r != null) {
      setState(() {
        rango = r;
        modo = 'rango';
      });
    }
  }

  Widget _stat(String valor, String etiqueta) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valor,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          Text(
            etiqueta,
            style: const TextStyle(color: CrediColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final h = DateTime.now();
        DateTime? desde;
        DateTime? hasta;
        var periodo = 'Todo el historial';
        if (modo == 'mes') {
          desde = DateTime(h.year, h.month, 1);
          hasta = DateTime(h.year, h.month + 1, 0);
          periodo = '${_meses[h.month - 1]} ${h.year}';
        } else if (modo == 'rango' && rango != null) {
          desde = rango!.start;
          hasta = rango!.end;
          periodo = '${fechaTexto(desde)} – ${fechaTexto(hasta)}';
        }
        final lista = store.pagosEntre(desde, hasta);
        final total = lista.fold<double>(0, (s, p) => s + p.monto);
        final promedio = lista.isEmpty ? 0.0 : total / lista.length;

        return Scaffold(
          appBar: barra('Cobros por periodo'),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FiltroChip(
                      texto: 'Este mes',
                      activo: modo == 'mes',
                      onTap: () => setState(() => modo = 'mes'),
                    ),
                    FiltroChip(
                      texto: modo == 'rango' && rango != null
                          ? periodo
                          : 'Rango de fechas',
                      activo: modo == 'rango',
                      onTap: _elegirRango,
                    ),
                    FiltroChip(
                      texto: 'Todo',
                      activo: modo == 'todo',
                      onTap: () => setState(() => modo = 'todo'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Tarjeta(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      periodo.isEmpty
                          ? ''
                          : periodo[0].toUpperCase() + periodo.substring(1),
                      style: const TextStyle(
                        color: CrediColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      soles(total),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: CrediColors.verde,
                      ),
                    ),
                    const Text(
                      'Total cobrado',
                      style: TextStyle(color: CrediColors.muted),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _stat('${lista.length}', 'Pagos'),
                        _stat(soles(promedio), 'Promedio por pago'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Detalle de cobros',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (lista.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No hay cobros en este periodo',
                      style: TextStyle(color: CrediColors.muted),
                    ),
                  ),
                ),
              ...lista.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Tarjeta(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: CrediColors.verdeSuave,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.payments_outlined,
                            color: CrediColors.verde,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.clienteNombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                p.detalle,
                                style: const TextStyle(
                                  color: CrediColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          soles(p.monto),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ResumenPage extends StatelessWidget {
  const ResumenPage({super.key});

  static const _rojo = Color(0xFFB42318);
  static const _azul = Color(0xFF175CD3);

  Widget _kpi(
    IconData icono,
    Color color,
    Color fondo,
    String valor,
    String etiqueta,
  ) {
    return Expanded(
      child: Tarjeta(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: fondo,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icono, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              valor,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              etiqueta,
              style: const TextStyle(color: CrediColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _leyenda(Color c, String t, int n) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(t)),
          Text('$n', style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final prestamos = store.prestamos;
        final prestado = prestamos.fold<double>(0, (s, p) => s + p.monto);
        final cobrado = store.totalCobrado;
        final saldo = store.porCobrar;
        final totalCartera = cobrado + saldo;
        final recuperado = totalCartera == 0
            ? 0.0
            : (cobrado / totalCartera).clamp(0.0, 1.0);

        final activos = prestamos
            .where((p) => p.estado == EstadoPrestamo.activo)
            .length;
        final atrasados = prestamos
            .where((p) => p.estado == EstadoPrestamo.atrasado)
            .length;
        final cancelados = prestamos
            .where((p) => p.estado == EstadoPrestamo.cancelado)
            .length;

        final vencidas = prestamos
            .expand((p) => p.cuotas)
            .where((c) => c.estado == EstadoCuota.vencida)
            .toList();
        final mora = vencidas.fold<double>(0, (s, c) => s + c.monto);

        final saldos = <String, double>{};
        for (final p in prestamos) {
          if (p.saldo > 0)
            saldos[p.clienteId] = (saldos[p.clienteId] ?? 0) + p.saldo;
        }
        final top =
            (saldos.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value)))
                .take(3)
                .toList();

        return Scaffold(
          appBar: barra('Resumen general'),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: CrediColors.vinoOscuro,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saldo por cobrar',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      soles(saldo),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: recuperado,
                        minHeight: 8,
                        color: const Color(0xFF4ADE80),
                        backgroundColor: Colors.white24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Recuperado ${(recuperado * 100).toStringAsFixed(0)}% · ${soles(cobrado)} de ${soles(totalCartera)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _kpi(
                      Icons.account_balance_wallet_outlined,
                      CrediColors.vino,
                      CrediColors.rosaSuave,
                      soles(prestado),
                      'Monto prestado',
                    ),
                    const SizedBox(width: 10),
                    _kpi(
                      Icons.trending_up,
                      CrediColors.verde,
                      CrediColors.verdeSuave,
                      soles(cobrado),
                      'Cobrado total',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _kpi(
                      Icons.calendar_month_outlined,
                      CrediColors.verde,
                      CrediColors.verdeSuave,
                      soles(store.cobradoMes),
                      'Cobrado este mes',
                    ),
                    const SizedBox(width: 10),
                    _kpi(
                      Icons.warning_amber_rounded,
                      _rojo,
                      CrediColors.rojoSuave,
                      soles(mora),
                      'En mora · ${vencidas.length} cuotas',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Tarjeta(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado de la cartera · ${prestamos.length} préstamos · ${store.clientes.length} clientes',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    if (prestamos.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 10,
                          child: Row(
                            children: [
                              if (activos > 0)
                                Expanded(
                                  flex: activos,
                                  child: Container(color: CrediColors.verde),
                                ),
                              if (atrasados > 0)
                                Expanded(
                                  flex: atrasados,
                                  child: Container(color: _rojo),
                                ),
                              if (cancelados > 0)
                                Expanded(
                                  flex: cancelados,
                                  child: Container(color: _azul),
                                ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    _leyenda(CrediColors.verde, 'Activos', activos),
                    _leyenda(_rojo, 'Atrasados', atrasados),
                    _leyenda(_azul, 'Cancelados', cancelados),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Tarjeta(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mayor saldo pendiente',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    if (top.isEmpty)
                      const Text(
                        'No hay saldos pendientes',
                        style: TextStyle(color: CrediColors.muted),
                      ),
                    ...top.map((e) {
                      final c = store.clienteDe(e.key);
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            AvatarIni(texto: c.iniciales, radio: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                c.nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              soles(e.value),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CobrosPage()),
                ),
                child: const Text('Ver detalle de cobros'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ObservacionPage extends StatefulWidget {
  const ObservacionPage({super.key, required this.prestamo});

  final Prestamo prestamo;

  @override
  State<ObservacionPage> createState() => _ObservacionPageState();
}

class _ObservacionPageState extends State<ObservacionPage> {
  final nota = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: barra('Registrar observación'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Préstamo #${widget.prestamo.codigo}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Deja una nota del acuerdo tomado con el cliente.',
            style: TextStyle(color: CrediColors.muted),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nota,
            maxLines: 5,
            maxLength: 180,
            decoration: const InputDecoration(
              hintText: 'Ejemplo: acordó pagar la cuota el viernes',
            ),
          ),
          const SizedBox(height: 8),
          BotonVino(
            texto: 'Guardar observación',
            onPressed: () {
              if (nota.text.trim().isEmpty) {
                aviso(context, 'Escribe la observación');
                return;
              }
              store.agregarObservacion(widget.prestamo, nota.text.trim());
              aviso(context, 'Observación guardada');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
