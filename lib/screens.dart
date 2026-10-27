import 'package:flutter/material.dart';
import 'data.dart';
import 'theme.dart';
import 'widgets.dart';
import 'seguridad.dart';
import 'auth_repository.dart';
import 'auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

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

  _timerBloqueo = Timer.periodic(
    const Duration(seconds: 1),
    (timer) {
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
    },
  );
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

          final resultado = await authService.iniciarSesion(
            correo: correo.text,
            clave: clave.text,
          );

          if (!mounted) return;

          switch (resultado.estado) {
           case EstadoLogin.exitoso:
  _intentosFallidos = 0;
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => ShellPage(token: resultado.token),
    ),
  );
  break;

            case EstadoLogin.credencialesIncorrectas:
              clave.clear();
              _intentosFallidos++;

              final usuario = await authRepository.buscarPorCorreo(
                correo.text,
              );

              if (!mounted) return;

              if (_intentosFallidos >= 5 ||
                  (usuario != null &&
                      usuario.intentosFallidos >= 5)) {
                _iniciarBloqueo();
                aviso(context, 'Cuenta bloqueada por 20 segundos');
              } else {
                aviso(context, 'Correo o contraseña incorrectos');
              }
              break;

            case EstadoLogin.intentosExcedidos:
              clave.clear();
              _iniciarBloqueo();
              aviso(context, 'Cuenta bloqueada por 20 segundos');
              break;

            case EstadoLogin.errorServidor:
              aviso(context, 'Error de conexión. Inténtalo nuevamente.');
              break;
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
      final resultado = await authService.registrar(
        nombre: nombre.text,
        correo: correo.text,
        clave: clave.text,
      );

      if (!mounted) return;

      switch (resultado.estado) {
        case EstadoRegistro.exitoso:
          store.actualizarPerfil(
            nombre: nombre.text.trim(),
            telefono: telefono.text.trim(),
          );
          store.cambiarCorreo(correo.text.trim().toLowerCase());
          store.cambiarClave(clave.text);

          try {
            await _eliminarBorrador();
          } catch (_) {
            // La cuenta ya se registró; un fallo al limpiar no la revierte.
          }

          if (!mounted) return;

          final messenger = ScaffoldMessenger.of(context);
          Navigator.pop(context);
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Cuenta creada correctamente. Inicia sesión.'),
            ),
          );
          break;

        case EstadoRegistro.correoDuplicado:
          aviso(context, resultado.mensaje);
          break;

        case EstadoRegistro.datosInvalidos:
          aviso(context, resultado.mensaje);
          break;

        case EstadoRegistro.errorConexion:
          aviso(context, resultado.mensaje);
          break;
      }
    } catch (_) {
      if (mounted) {
        aviso(context, 'No se pudo crear la cuenta. Inténtalo nuevamente.');
      }
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
    final primero = store.nombre.split(' ').first;

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
  late final nombre = TextEditingController(text: store.nombre);
  late final telefono = TextEditingController(text: store.telefono);
  late final correo = TextEditingController(text: store.correo);

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

  if (widget.token == null) {
    aviso(context, 'No se encontró la sesión activa');
    return;
  }

  final resultado = await authService.cerrarSesion(widget.token!);

  if (!mounted) return;

  if (resultado.estado == EstadoCierreSesion.exitoso) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  } else {
    aviso(context, resultado.mensaje);
  }
}

  @override
  Widget build(BuildContext context) {
    final ini = store.nombre.trim().split(' ');
    final sigla = ini.length > 1
        ? '${ini.first[0]}${ini[1][0]}'.toUpperCase()
        : ini.first.substring(0, 1);
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

  @override
  Widget build(BuildContext context) {
    final lista = store.clientes.where((c) {
      final t = q.toLowerCase();
      return c.nombre.toLowerCase().contains(t) || c.dni.contains(t);
    }).toList();
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: CrediColors.vino,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ClienteFormPage()),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          children: [
            const Center(
              child: Text(
                'Clientes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => q = v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar por nombre o DNI',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${lista.length} clientes',
              style: const TextStyle(
                color: CrediColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...lista.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Tarjeta(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HistorialClientePage(cliente: c),
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
                              'DNI ${c.dni}',
                              style: const TextStyle(
                                color: CrediColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ChipEstado(texto: store.estadoCliente(c)),
                    ],
                  ),
                ),
              ),
            ),
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
          ),
          Campo(
            label: 'Documento (DNI)',
            controller: dni,
            keyboard: TextInputType.number,
            readOnly: editando,
          ),
          Campo(
            label: 'Teléfono',
            controller: telefono,
            keyboard: TextInputType.phone,
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
            onPressed: () {
              if (telefono.text.trim().isEmpty) {
                aviso(context, 'Ingresa el teléfono');
                return;
              }
              if (editando) {
                store.editarCliente(
                  widget.cliente!,
                  telefono: telefono.text.trim(),
                  direccion: direccion.text.trim(),
                );
              } else {
                if (nombre.text.trim().isEmpty || dni.text.trim().isEmpty) {
                  aviso(context, 'Completa nombre y DNI');
                  return;
                }
                store.agregarCliente(
                  Cliente(
                    id: 'c${DateTime.now().millisecondsSinceEpoch}',
                    nombre: nombre.text.trim(),
                    dni: dni.text.trim(),
                    telefono: telefono.text.trim(),
                    direccion: direccion.text.trim(),
                  ),
                );
              }
              aviso(context, 'Cliente guardado');
              Navigator.pop(context);
            },
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
          (filtro == 'Cancelados' && p.estado == EstadoPrestamo.cancelado);
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
              children: ['Todos', 'Activos', 'Atrasados', 'Cancelados'].map((
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
            ...lista.map((p) {
              final c = store.clienteDe(p.clienteId);
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

class NuevoPrestamoPage extends StatefulWidget {
  const NuevoPrestamoPage({super.key});

  @override
  State<NuevoPrestamoPage> createState() => _NuevoPrestamoPageState();
}

class _NuevoPrestamoPageState extends State<NuevoPrestamoPage> {
  String clienteId = store.clientes.first.id;
  final monto = TextEditingController(text: '800.00');
  final tasa = TextEditingController(text: '5');
  final cuotas = TextEditingController(text: '4');
  String frecuencia = 'Semanal';
  final fecha = TextEditingController(text: '21/09/2026');

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
            items: store.clientes
                .map(
                  (c) => DropdownMenuItem(value: c.id, child: Text(c.nombre)),
                )
                .toList(),
            onChanged: (v) => setState(() => clienteId = v!),
          ),
          const SizedBox(height: 14),
          Campo(
            label: 'Monto del préstamo',
            controller: monto,
            keyboard: TextInputType.number,
            suffix: 'S/',
          ),
          Campo(
            label: 'Tasa de interés',
            controller: tasa,
            keyboard: TextInputType.number,
            suffix: '%',
          ),
          Campo(
            label: 'Número de cuotas',
            controller: cuotas,
            keyboard: TextInputType.number,
          ),
          const Text(
            'Frecuencia de pago',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: frecuencia,
            items: const [
              'Semanal',
              'Quincenal',
              'Mensual',
            ].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
            onChanged: (v) => setState(() => frecuencia = v!),
          ),
          const SizedBox(height: 14),
          Campo(label: 'Fecha de emisión', controller: fecha),
          BotonVino(
            texto: 'Registrar préstamo',
            onPressed: () {
              final m = double.tryParse(monto.text.replaceAll(',', '.'));
              final t = double.tryParse(tasa.text.replaceAll(',', '.'));
              final n = int.tryParse(cuotas.text);
              if (m == null || t == null || n == null || n <= 0) {
                aviso(context, 'Revisa monto, tasa y cuotas');
                return;
              }
              final p = store.registrarPrestamo(
                clienteId: clienteId,
                monto: m,
                tasa: t,
                nCuotas: n,
                frecuencia: frecuencia,
                fecha: fecha.text.trim(),
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => CronogramaPage(prestamo: p)),
              );
            },
          ),
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
    final cliente = store.clienteDe(prestamo.clienteId);
    return Scaffold(
      appBar: barra('Cronograma de pagos'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${cliente.nombre} · #${prestamo.codigo}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          Text(
            '${prestamo.frecuencia} · ${soles(prestamo.monto)}',
            style: const TextStyle(color: CrediColors.muted),
          ),
          const SizedBox(height: 12),
          ...prestamo.cuotas.map((c) {
            final estado = c.estado == EstadoCuota.pagada
                ? 'PAGADA'
                : c.estado == EstadoCuota.vencida
                ? 'VENCIDA'
                : 'PENDIENTE';
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
                        Text(
                          soles(c.monto),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        ChipEstado(texto: estado),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          BotonVino(
            texto: 'Registrar pago',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RegistrarPagoPage(prestamo: prestamo),
              ),
            ),
          ),
        ],
      ),
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
        .where((x) => x.estado != EstadoCuota.pagada)
        .toList();
    seleccion = widget.cuota ?? (pend.isEmpty ? null : pend.first);
    monto.text = seleccion?.monto.toStringAsFixed(2) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.prestamo;
    final c = store.clienteDe(p.clienteId);
    final pendientes = p.cuotas
        .where((x) => x.estado != EstadoCuota.pagada)
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
                  monto.text = cuota.monto.toStringAsFixed(2);
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
                            cuota.estado == EstadoCuota.vencida
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
                      soles(cuota.monto),
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
          Campo(label: 'Fecha', controller: fecha),

          BotonVino(
            texto: 'Registrar pago',
            onPressed: seleccion == null
                ? null
                : () {
                    final m = double.tryParse(monto.text.replaceAll(',', '.'));
                    if (m == null || m <= 0) {
                      aviso(context, 'Ingresa un monto válido');
                      return;
                    }
                    if (m < seleccion!.monto) {
                      aviso(
                        context,
                        'El monto es menor a la cuota (${soles(seleccion!.monto)})',
                      );
                      return;
                    }
                    store.registrarPago(p, seleccion!, m, fecha.text.trim());
                    aviso(context, 'Pago registrado');
                    Navigator.pop(context);
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
    final pagadas = prestamo.cuotas
        .where((c) => c.estado == EstadoCuota.pagada)
        .toList();
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
          if (pagadas.isEmpty) const Text('Aún no hay pagos en este préstamo.'),
          ...pagadas.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Tarjeta(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Cuota #${c.numero.toString().padLeft(2, '0')}\n${c.fecha}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      soles(c.monto),
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
                          onPressed: () => store.alternarCumplido(r),
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
            onPressed: () {
              final p = store.prestamos.firstWhere((x) => x.id == prestamoId);
              final n = store
                  .clienteDe(p.clienteId)
                  .nombre
                  .split(' ')
                  .take(2)
                  .join(' ');
              store.agregarRecordatorio(
                Recordatorio(
                  titulo: '$n · #${p.codigo}',
                  motivo: motivo,
                  fecha: fecha.text.trim(),
                  hora: hora.text.trim(),
                ),
              );
              aviso(context, 'Recordatorio programado');
              Navigator.pop(context);
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
                      periodo[0].toUpperCase() + periodo.substring(1),
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
