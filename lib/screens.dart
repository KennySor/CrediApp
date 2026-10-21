import 'package:flutter/material.dart';
import 'data.dart';
import 'theme.dart';
import 'widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final correo = TextEditingController(text: 'rosa.delgado@prestamosya.pe');
  final clave = TextEditingController(text: '12345678');

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
                child: Text('CA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: CrediColors.texto),
                  children: [
                    TextSpan(text: 'Credi'),
                    TextSpan(text: 'APP', style: TextStyle(color: CrediColors.vino)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text('Gestión y control de préstamos', style: TextStyle(color: CrediColors.muted)),
            ),
            const SizedBox(height: 28),
            Campo(label: 'Correo electrónico', controller: correo, keyboard: TextInputType.emailAddress),
            Campo(label: 'Contraseña', controller: clave, obscure: true),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecuperarPage())),
                child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: CrediColors.vino)),
              ),
            ),
            BotonVino(
              texto: 'Iniciar sesión',
              onPressed: () {
                if (correo.text.trim().isEmpty || clave.text.isEmpty) {
                  aviso(context, 'Ingresa correo y contraseña');
                  return;
                }
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ShellPage()));
              },
            ),
            const SizedBox(height: 18),
            const Center(child: Text('¿No tienes cuenta?', style: TextStyle(color: CrediColors.muted))),
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistroPage())),
              child: const Text('Crear cuenta', style: TextStyle(color: CrediColors.texto, fontWeight: FontWeight.w700)),
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
  final nombre = TextEditingController();
  final correo = TextEditingController();
  final telefono = TextEditingController();
  final clave = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: barra('Crear cuenta'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Campo(label: 'Nombre completo', controller: nombre),
          Campo(label: 'Correo electrónico', controller: correo, keyboard: TextInputType.emailAddress),
          Campo(label: 'Teléfono', controller: telefono, keyboard: TextInputType.phone),
          Campo(label: 'Contraseña', controller: clave, obscure: true),
          const SizedBox(height: 8),
          BotonVino(
            texto: 'Registrar cuenta',
            onPressed: () {
              if (nombre.text.trim().isEmpty || correo.text.trim().isEmpty) {
                aviso(context, 'Completa nombre y correo');
                return;
              }
              store.actualizarPerfil(nombre: nombre.text.trim(), correo: correo.text.trim(), telefono: telefono.text.trim());
              aviso(context, 'Cuenta creada. Inicia sesión');
              Navigator.pop(context);
            },
          ),
        ],
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
          const Text('Te enviaremos un código a tu correo para restablecer la contraseña.', style: TextStyle(color: CrediColors.muted)),
          const SizedBox(height: 16),
          Campo(label: 'Correo electrónico', controller: correo),
          BotonVino(
            texto: 'Enviar código',
            onPressed: () => setState(() => enviado = true),
          ),
          if (enviado) ...[
            const SizedBox(height: 16),
            Campo(label: 'Código recibido', controller: codigo, keyboard: TextInputType.number),
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
  const ShellPage({super.key, this.inicial = 0});

  final int inicial;

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  late int index = widget.inicial;

  @override
  Widget build(BuildContext context) {
    final paginas = [
      const HomePage(),
      const ClientesPage(),
      const PrestamosPage(),
      const AvisosPage(),
      const PerfilPage(),
    ];
    return Scaffold(
      body: paginas[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        height: 68,
        backgroundColor: Colors.white,
        indicatorColor: CrediColors.rosaSuave,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: CrediColors.vino), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people, color: CrediColors.vino), label: 'Clientes'),
          NavigationDestination(icon: Icon(Icons.credit_card_outlined), selectedIcon: Icon(Icons.credit_card, color: CrediColors.vino), label: 'Créditos'),
          NavigationDestination(icon: Icon(Icons.notifications_none), selectedIcon: Icon(Icons.notifications, color: CrediColors.vino), label: 'Avisos'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: CrediColors.vino), label: 'Perfil'),
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
    final proximas = store.prestamos
        .expand((p) => p.cuotas.where((c) => c.estado != EstadoCuota.pagada).map((c) => MapEntry(p, c)))
        .take(3)
        .toList();
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
                    Text('Hola, $primero', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                    const Text('Cartera de préstamos activa', style: TextStyle(color: CrediColors.muted)),
                  ],
                ),
              ),
              const AvatarIni(texto: 'RD', radio: 24),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _resumen(soles(store.cobradoMes), 'Cobrado este mes', CrediColors.verde)),
              const SizedBox(width: 10),
              Expanded(child: _resumen(soles(store.porCobrar), 'Por cobrar', CrediColors.texto)),
            ],
          ),
          const SizedBox(height: 18),
          const Text('Accesos rápidos', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.45,
            children: [
              _acceso(Icons.add, 'Nuevo préstamo', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NuevoPrestamoPage()))),
              _acceso(Icons.payments_outlined, 'Registrar pago', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ElegirPrestamoPagoPage()))),
              _acceso(Icons.person_add_alt, 'Nuevo cliente', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClienteFormPage()))),
              _acceso(Icons.notifications_active_outlined, 'Recordatorios', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecordatoriosPage()))),
            ],
          ),
          const SizedBox(height: 12),
          Tarjeta(
            color: CrediColors.vinoOscuro,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccionBloqueadaPage())),
            child: const Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Transferencias y pagos reales', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      Text('No disponibles en este sistema', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
              const Expanded(child: Text('Cuotas próximas a vencer', style: TextStyle(fontWeight: FontWeight.w800))),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CuotasPage())),
                child: const Text('Ver todas'),
              ),
            ],
          ),
          ...proximas.map((e) {
            final cliente = store.clienteDe(e.key.clienteId);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Tarjeta(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegistrarPagoPage(prestamo: e.key))),
                child: Row(
                  children: [
                    AvatarIni(texto: cliente.iniciales),
                    const SizedBox(width: 10),
                    Expanded(child: Text(cliente.nombre, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text(soles(e.value.monto), style: const TextStyle(fontWeight: FontWeight.w800)),
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
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CobrosPage())),
                  child: const Text('Cobros'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResumenPage())),
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
          Text(valor, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 4),
          Text(etiqueta, style: const TextStyle(color: CrediColors.muted, fontSize: 13)),
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
            const Text('Esta operación está fuera del alcance', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            const Text(
              'CrediAPP no transfiere dinero ni funciona como billetera. Solo permite registrar y controlar préstamos, cuotas y pagos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: CrediColors.muted, height: 1.4),
            ),
            const Spacer(),
            BotonVino(texto: 'Volver al menú', onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  late final nombre = TextEditingController(text: store.nombre);
  late final correo = TextEditingController(text: store.correo);
  late final telefono = TextEditingController(text: store.telefono);

  @override
  Widget build(BuildContext context) {
    final ini = store.nombre.trim().split(' ');
    final sigla = ini.length > 1 ? '${ini.first[0]}${ini[1][0]}'.toUpperCase() : ini.first.substring(0, 1);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(child: Text('Mi perfil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
          const SizedBox(height: 16),
          Center(child: CircleAvatar(radius: 36, backgroundColor: CrediColors.vino, child: Text(sigla, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)))),
          const SizedBox(height: 8),
          Center(child: Text(store.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
          const Center(child: Text('Prestamista', style: TextStyle(color: CrediColors.muted))),
          const SizedBox(height: 18),
          Campo(label: 'Nombre completo', controller: nombre),
          Campo(label: 'Correo electrónico', controller: correo),
          Campo(label: 'Teléfono', controller: telefono, keyboard: TextInputType.phone),
          BotonVino(
            texto: 'Guardar cambios',
            onPressed: () {
              store.actualizarPerfil(nombre: nombre.text.trim(), correo: correo.text.trim(), telefono: telefono.text.trim());
              aviso(context, 'Perfil actualizado');
            },
          ),
          TextButton(
            onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false),
            child: const Text('Cerrar sesión', style: TextStyle(color: CrediColors.vino, fontWeight: FontWeight.w700)),
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
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClienteFormPage())),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          children: [
            const Center(child: Text('Clientes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => q = v),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar por nombre o DNI'),
            ),
            const SizedBox(height: 12),
            Text('${lista.length} clientes', style: const TextStyle(color: CrediColors.muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...lista.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Tarjeta(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HistorialClientePage(cliente: c))),
                    child: Row(
                      children: [
                        AvatarIni(texto: c.iniciales),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text('DNI ${c.dni}', style: const TextStyle(color: CrediColors.muted, fontSize: 12)),
                            ],
                          ),
                        ),
                        ChipEstado(texto: store.estadoCliente(c)),
                      ],
                    ),
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
  late final telefono = TextEditingController(text: widget.cliente?.telefono ?? '');
  late final direccion = TextEditingController(text: widget.cliente?.direccion ?? '');

  bool get editando => widget.cliente != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: barra(editando ? 'Editar cliente' : 'Nuevo cliente'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Campo(label: 'Nombres y apellidos', controller: nombre, readOnly: editando),
          Campo(label: 'Documento (DNI)', controller: dni, keyboard: TextInputType.number, readOnly: editando),
          Campo(label: 'Teléfono', controller: telefono, keyboard: TextInputType.phone),
          Campo(label: 'Dirección', controller: direccion),
          if (editando)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text('El nombre y el documento quedan bloqueados.', style: TextStyle(color: CrediColors.muted, fontSize: 12)),
            ),
          BotonVino(
            texto: editando ? 'Guardar cambios' : 'Guardar cliente',
            onPressed: () {
              if (telefono.text.trim().isEmpty) {
                aviso(context, 'Ingresa el teléfono');
                return;
              }
              if (editando) {
                store.editarCliente(widget.cliente!, telefono: telefono.text.trim(), direccion: direccion.text.trim());
              } else {
                if (nombre.text.trim().isEmpty || dni.text.trim().isEmpty) {
                  aviso(context, 'Completa nombre y DNI');
                  return;
                }
                store.agregarCliente(Cliente(
                  id: 'c${DateTime.now().millisecondsSinceEpoch}',
                  nombre: nombre.text.trim(),
                  dni: dni.text.trim(),
                  telefono: telefono.text.trim(),
                  direccion: direccion.text.trim(),
                ));
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
                      Text(cliente.nombre, style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text('DNI ${cliente.dni}', style: const TextStyle(color: CrediColors.muted)),
                      Text(cliente.telefono, style: const TextStyle(color: CrediColors.muted, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClienteFormPage(cliente: cliente))),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EstadoPrestamosPage(cliente: cliente))),
            child: const Text('Ver estado de préstamos'),
          ),
          const SizedBox(height: 12),
          const Text('Préstamos y comportamiento de pago', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (lista.isEmpty) const Text('Este cliente aún no tiene préstamos.'),
          ...lista.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Tarjeta(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetallePrestamoPage(prestamo: p))),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Préstamo #${p.codigo}', style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text('${p.pagadas}/${p.cuotas.length} cuotas al día', style: const TextStyle(color: CrediColors.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(soles(p.monto), style: const TextStyle(fontWeight: FontWeight.w800)),
                          ChipEstado(texto: etiquetaEstado(p.estado)),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
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
    final alDia = lista.where((p) => p.estado == EstadoPrestamo.activo || p.estado == EstadoPrestamo.cancelado).length;
    final atrasos = lista.where((p) => p.estado == EstadoPrestamo.atrasado).length;
    return Scaffold(
      appBar: barra('Estado de préstamos'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(cliente.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _caja('$alDia', 'Al día / cerrados', CrediColors.verde)),
              const SizedBox(width: 10),
              Expanded(child: _caja('$atrasos', 'Con atraso', const Color(0xFFB42318))),
            ],
          ),
          const SizedBox(height: 12),
          ...lista.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Tarjeta(
                  child: Row(
                    children: [
                      Expanded(child: Text('Préstamo #${p.codigo}')),
                      ChipEstado(texto: etiquetaEstado(p.estado)),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _caja(String n, String t, Color c) {
    return Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(n, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: c)),
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
      final okTexto = cliente.contains(q.toLowerCase()) || p.codigo.contains(q) || etiquetaEstado(p.estado).toLowerCase().contains(q.toLowerCase());
      final okEstado = filtro == 'Todos' ||
          (filtro == 'Activos' && p.estado == EstadoPrestamo.activo) ||
          (filtro == 'Atrasados' && p.estado == EstadoPrestamo.atrasado) ||
          (filtro == 'Cancelados' && p.estado == EstadoPrestamo.cancelado);
      return okTexto && okEstado;
    }).toList();
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: CrediColors.vino,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NuevoPrestamoPage())),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          children: [
            const Center(child: Text('Préstamos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => q = v),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Filtrar por cliente o estado'),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: ['Todos', 'Activos', 'Atrasados', 'Cancelados'].map((f) {
                final sel = filtro == f;
                return ChoiceChip(
                  label: Text(f),
                  selected: sel,
                  selectedColor: CrediColors.vinoOscuro,
                  labelStyle: TextStyle(color: sel ? Colors.white : CrediColors.texto, fontWeight: FontWeight.w600),
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
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetallePrestamoPage(prestamo: p))),
                  child: Row(
                    children: [
                      AvatarIni(texto: c.iniciales),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text('Préstamo #${p.codigo}', style: const TextStyle(color: CrediColors.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(soles(p.estado == EstadoPrestamo.cancelado ? 0 : p.monto), style: const TextStyle(fontWeight: FontWeight.w800)),
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
            items: store.clientes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre))).toList(),
            onChanged: (v) => setState(() => clienteId = v!),
          ),
          const SizedBox(height: 14),
          Campo(label: 'Monto del préstamo', controller: monto, keyboard: TextInputType.number, suffix: 'S/'),
          Campo(label: 'Tasa de interés', controller: tasa, keyboard: TextInputType.number, suffix: '%'),
          Campo(label: 'Número de cuotas', controller: cuotas, keyboard: TextInputType.number),
          const Text('Frecuencia de pago', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: frecuencia,
            items: const ['Semanal', 'Quincenal', 'Mensual'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
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
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CronogramaPage(prestamo: p)));
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
          Text('${cliente.nombre} · #${prestamo.codigo}', style: const TextStyle(fontWeight: FontWeight.w800)),
          Text('${prestamo.frecuencia} · ${soles(prestamo.monto)}', style: const TextStyle(color: CrediColors.muted)),
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
                    Expanded(child: Text('#${c.numero.toString().padLeft(2, '0')} · ${c.fecha}', style: const TextStyle(fontWeight: FontWeight.w700))),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(soles(c.monto), style: const TextStyle(fontWeight: FontWeight.w800)),
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
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegistrarPagoPage(prestamo: prestamo))),
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
    final avance = prestamo.cuotas.isEmpty ? 0.0 : prestamo.pagadas / prestamo.cuotas.length;
    return Scaffold(
      appBar: barra('Detalle del préstamo'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(cliente.nombre, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          Text('Préstamo #${prestamo.codigo}', style: const TextStyle(color: CrediColors.muted)),
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
                _fila('Cuotas pendientes', '${prestamo.cuotas.length - prestamo.pagadas}'),
                const SizedBox(height: 8),
                const Text('Avance'),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(value: avance, minHeight: 8, color: CrediColors.vino, backgroundColor: CrediColors.rosaSuave),
                ),
                const SizedBox(height: 8),
                ChipEstado(texto: etiquetaEstado(prestamo.estado)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          BotonVino(texto: 'Ver cronograma', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CronogramaPage(prestamo: prestamo)))),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HistorialPagosPage(prestamo: prestamo))),
            child: const Text('Historial de pagos'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ObservacionPage(prestamo: prestamo))),
            child: const Text('Registrar observación'),
          ),
          if (prestamo.observaciones.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Observaciones', style: TextStyle(fontWeight: FontWeight.w800)),
            ...prestamo.observaciones.map((o) => Padding(padding: const EdgeInsets.only(top: 8), child: Tarjeta(child: Text(o)))),
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
          Expanded(child: Text(a, style: const TextStyle(color: CrediColors.muted))),
          Text(b, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class ElegirPrestamoPagoPage extends StatelessWidget {
  const ElegirPrestamoPagoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lista = store.prestamos.where((p) => p.estado != EstadoPrestamo.cancelado).toList();
    return Scaffold(
      appBar: barra('Registrar pago'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: lista.map((p) {
          final c = store.clienteDe(p.clienteId);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Tarjeta(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegistrarPagoPage(prestamo: p))),
              child: Row(
                children: [
                  Expanded(child: Text('${c.nombre}\n#${p.codigo}', style: const TextStyle(fontWeight: FontWeight.w700))),
                  Text(soles(p.saldo)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class RegistrarPagoPage extends StatefulWidget {
  const RegistrarPagoPage({super.key, required this.prestamo});

  final Prestamo prestamo;

  @override
  State<RegistrarPagoPage> createState() => _RegistrarPagoPageState();
}

class _RegistrarPagoPageState extends State<RegistrarPagoPage> {
  Cuota? seleccion;
  final monto = TextEditingController(text: '200.00');
  final fecha = TextEditingController(text: '21/09/2026');

  @override
  Widget build(BuildContext context) {
    final p = widget.prestamo;
    final c = store.clienteDe(p.clienteId);
    final pendientes = p.cuotas.where((x) => x.estado != EstadoCuota.pagada).toList();
    seleccion ??= pendientes.isEmpty ? null : pendientes.first;
    return Scaffold(
      appBar: barra('Registrar pago'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: CrediColors.vinoOscuro, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                Text('DNI ${c.dni}', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('PRÉSTAMO #${p.codigo}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: CrediColors.verdeSuave, borderRadius: BorderRadius.circular(12)),
                      child: Text('Saldo ${soles(p.saldo)}', style: const TextStyle(color: CrediColors.verde, fontWeight: FontWeight.w800, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text('Cuotas pendientes', style: TextStyle(fontWeight: FontWeight.w800)),
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
                          Text('#${cuota.numero.toString().padLeft(2, '0')} · ${cuota.fecha}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(cuota.estado == EstadoCuota.vencida ? 'VENCIDA' : 'PENDIENTE', style: const TextStyle(fontSize: 12, color: CrediColors.muted)),
                        ],
                      ),
                    ),
                    Text(soles(cuota.monto), style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            );
          }),
          Campo(label: 'Monto recibido', controller: monto, keyboard: TextInputType.number, suffix: 'S/'),
          Campo(label: 'Fecha', controller: fecha),
          BotonVino(
            texto: 'Registrar pago',
            onPressed: () {
              if (seleccion == null) return;
              final m = double.tryParse(monto.text.replaceAll(',', '.'));
              if (m == null || m <= 0) {
                aviso(context, 'Ingresa un monto válido');
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
    final pagadas = prestamo.cuotas.where((c) => c.estado == EstadoCuota.pagada).toList();
    final cliente = store.clienteDe(prestamo.clienteId).nombre;
    return Scaffold(
      appBar: barra('Historial de pagos'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('$cliente · #${prestamo.codigo}', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          if (pagadas.isEmpty) const Text('Aún no hay pagos en este préstamo.'),
          ...pagadas.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Tarjeta(
                  child: Row(
                    children: [
                      Expanded(child: Text('Cuota #${c.numero.toString().padLeft(2, '0')}\n${c.fecha}', style: const TextStyle(fontWeight: FontWeight.w700))),
                      Text(soles(c.monto), style: const TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class CuotasPage extends StatelessWidget {
  const CuotasPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <MapEntry<Prestamo, Cuota>>[];
    for (final p in store.prestamos) {
      for (final c in p.cuotas.where((x) => x.estado != EstadoCuota.pagada)) {
        items.add(MapEntry(p, c));
      }
    }
    return Scaffold(
      appBar: barra('Cuotas por cobrar'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: items.map((e) {
          final cliente = store.clienteDe(e.key.clienteId);
          final estado = e.value.estado == EstadoCuota.vencida ? 'VENCIDA' : 'PENDIENTE';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Tarjeta(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegistrarPagoPage(prestamo: e.key))),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cliente.nombre, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text('#${e.key.codigo} · cuota ${e.value.numero} · ${e.value.fecha}', style: const TextStyle(color: CrediColors.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(soles(e.value.monto), style: const TextStyle(fontWeight: FontWeight.w800)),
                      ChipEstado(texto: estado),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class AvisosPage extends StatelessWidget {
  const AvisosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final avisosSistema = [
      'Cuota #06 de Rosa Delgado vence el 25/09',
      'Cuota vencida de Luis Flores · préstamo #0210',
      'Pago registrado: Jorge Ramos · S/ 150',
    ];
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Center(child: Text('Notificaciones', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
          const SizedBox(height: 8),
          const Text('Avisos automáticos de cuotas y confirmaciones de pago.', style: TextStyle(color: CrediColors.muted)),
          const SizedBox(height: 12),
          ...avisosSistema.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Tarjeta(
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active_outlined, color: CrediColors.vino),
                      const SizedBox(width: 10),
                      Expanded(child: Text(t)),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 8),
          BotonVino(
            texto: 'Ver recordatorios',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecordatoriosPage())),
          ),
        ],
      ),
    );
  }
}

class RecordatoriosPage extends StatelessWidget {
  const RecordatoriosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: barra('Recordatorios'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: CrediColors.vino,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NuevoRecordatorioPage())),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: store.recordatorios.length,
        itemBuilder: (context, i) {
          final r = store.recordatorios[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Tarjeta(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.titulo, style: const TextStyle(fontWeight: FontWeight.w800)),
                        Text(r.motivo, style: const TextStyle(color: CrediColors.muted)),
                        Text('${r.fecha} · ${r.hora}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => store.eliminarRecordatorio(i),
                    icon: const Icon(Icons.delete_outline, color: CrediColors.vino),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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
          const Text('Cliente / préstamo', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: prestamoId,
            items: store.prestamos.map((p) {
              final n = store.clienteDe(p.clienteId).nombre.split(' ').take(2).join(' ');
              return DropdownMenuItem(value: p.id, child: Text('$n · #${p.codigo}'));
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
          Campo(label: 'Fecha de aviso', controller: fecha),
          Campo(label: 'Hora', controller: hora),
          BotonVino(
            texto: 'Programar recordatorio',
            onPressed: () {
              final p = store.prestamos.firstWhere((x) => x.id == prestamoId);
              final n = store.clienteDe(p.clienteId).nombre.split(' ').take(2).join(' ');
              store.agregarRecordatorio(Recordatorio(
                titulo: '$n · #${p.codigo}',
                motivo: motivo,
                fecha: fecha.text.trim(),
                hora: hora.text.trim(),
              ));
              aviso(context, 'Recordatorio programado');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class CobrosPage extends StatelessWidget {
  const CobrosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final total = store.pagos.fold<double>(0, (s, p) => s + p.monto);
    return Scaffold(
      appBar: barra('Cobros por periodo'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: _chip('Este mes', true)),
              const SizedBox(width: 8),
              Expanded(child: _chip('Rango de fechas', false)),
            ],
          ),
          const SizedBox(height: 12),
          Tarjeta(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(soles(total == 650 ? 4850 : total), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: CrediColors.verde)),
                const Text('Total cobrado', style: TextStyle(color: CrediColors.muted)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text('Detalle de cobros', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...store.pagos.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Tarjeta(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.clienteNombre, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(p.detalle, style: const TextStyle(color: CrediColors.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(soles(p.monto), style: const TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _chip(String t, bool on) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: on ? CrediColors.vinoOscuro : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(t, style: TextStyle(color: on ? Colors.white : CrediColors.texto, fontWeight: FontWeight.w700)),
    );
  }
}

class ResumenPage extends StatelessWidget {
  const ResumenPage({super.key});

  @override
  Widget build(BuildContext context) {
    final prestado = store.prestamos.fold<double>(0, (s, p) => s + p.monto);
    final activos = store.prestamos.where((p) => p.estado == EstadoPrestamo.activo).length;
    final cancelados = store.prestamos.where((p) => p.estado == EstadoPrestamo.cancelado).length;
    return Scaffold(
      appBar: barra('Resumen general'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _dato('Monto prestado', soles(prestado)),
          _dato('Monto cobrado', soles(store.cobradoMes)),
          _dato('Saldo pendiente', soles(store.porCobrar)),
          _dato('Préstamos activos', '$activos'),
          _dato('Préstamos cancelados', '$cancelados'),
        ],
      ),
    );
  }

  Widget _dato(String a, String b) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Tarjeta(
        child: Row(
          children: [
            Expanded(child: Text(a, style: const TextStyle(color: CrediColors.muted))),
            Text(b, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
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
          Text('Préstamo #${widget.prestamo.codigo}', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Deja una nota del acuerdo tomado con el cliente.', style: TextStyle(color: CrediColors.muted)),
          const SizedBox(height: 12),
          TextField(
            controller: nota,
            maxLines: 5,
            maxLength: 180,
            decoration: const InputDecoration(hintText: 'Ejemplo: acordó pagar la cuota el viernes'),
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
