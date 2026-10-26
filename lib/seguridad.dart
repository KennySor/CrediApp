import 'dart:math';
import 'package:flutter/material.dart';
import 'data.dart';
import 'theme.dart';
import 'widgets.dart';

class SeguridadPage extends StatelessWidget {
  const SeguridadPage({super.key});

  Widget _opcion(BuildContext context, IconData icono, String titulo, String sub, Widget destino) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Tarjeta(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => destino)),
        child: Row(
          children: [
            Icon(icono, color: CrediColors.vino),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(sub, style: const TextStyle(color: CrediColors.muted, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: barra('Seguridad'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _opcion(context, Icons.lock_reset, 'Cambiar contraseña',
              'Requiere tu contraseña actual', const CambiarClavePage()),
          _opcion(context, Icons.alternate_email, 'Cambiar correo electrónico',
              'Requiere contraseña y código de verificación', const CambiarCorreoPage()),
        ],
      ),
    );
  }
}

class CambiarClavePage extends StatefulWidget {
  const CambiarClavePage({super.key});

  @override
  State<CambiarClavePage> createState() => _CambiarClavePageState();
}

class _CambiarClavePageState extends State<CambiarClavePage> {
  final _form = GlobalKey<FormState>();
  final actual = TextEditingController();
  final nueva = TextEditingController();
  final repite = TextEditingController();
  bool ver = false;
  int intentos = 0;

  int _fuerza(String v) {
    var s = 0;
    if (v.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(v)) s++;
    if (RegExp(r'\d').hasMatch(v)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(v)) s++;
    return s;
  }

  void _guardar() {
    if (!_form.currentState!.validate()) return;
    if (!store.claveCorrecta(actual.text)) {
      setState(() => intentos++);
      aviso(context, intentos >= 3
          ? 'Demasiados intentos. Intenta más tarde.'
          : 'La contraseña actual es incorrecta');
      return;
    }
    store.cambiarClave(nueva.text);
    aviso(context, 'Contraseña actualizada');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final f = _fuerza(nueva.text);
    const colores = [Colors.grey, Colors.red, Colors.orange, Colors.amber, CrediColors.verde];
    const textos = ['', 'Débil', 'Regular', 'Buena', 'Fuerte'];
    final ojo = IconButton(
      icon: Icon(ver ? Icons.visibility_off : Icons.visibility),
      onPressed: () => setState(() => ver = !ver),
    );
    return Scaffold(
      appBar: barra('Cambiar contraseña'),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Campo(
              label: 'Contraseña actual',
              controller: actual,
              obscure: !ver,
              suffixIcon: ojo,
              validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu contraseña actual' : null,
            ),
            Campo(
              label: 'Nueva contraseña',
              controller: nueva,
              obscure: !ver,
              onChanged: (_) => setState(() {}),
              validator: (v) => vClaveNueva(v) ?? (v == actual.text ? 'Debe ser distinta a la actual' : null),
            ),
            if (nueva.text.isNotEmpty) ...[
              LinearProgressIndicator(value: f / 4, color: colores[f], backgroundColor: const Color(0xFFE5E7EB)),
              const SizedBox(height: 4),
              Text('Seguridad: ${textos[f]}', style: const TextStyle(color: CrediColors.muted, fontSize: 12)),
              const SizedBox(height: 14),
            ],
            Campo(
              label: 'Confirmar nueva contraseña',
              controller: repite,
              obscure: !ver,
              validator: (v) => v != nueva.text ? 'Las contraseñas no coinciden' : null,
            ),
            BotonVino(texto: 'Actualizar contraseña', onPressed: intentos >= 3 ? null : _guardar),
          ],
        ),
      ),
    );
  }
}

class CambiarCorreoPage extends StatefulWidget {
  const CambiarCorreoPage({super.key});

  @override
  State<CambiarCorreoPage> createState() => _CambiarCorreoPageState();
}

class _CambiarCorreoPageState extends State<CambiarCorreoPage> {
  final _form = GlobalKey<FormState>();
  final clave = TextEditingController();
  final nuevo = TextEditingController();
  final codigo = TextEditingController();
  String? _enviado;

  void _enviar() {
    if (!_form.currentState!.validate()) return;
    if (!store.claveCorrecta(clave.text)) {
      aviso(context, 'La contraseña es incorrecta');
      return;
    }
    setState(() => _enviado = (100000 + Random().nextInt(900000)).toString());
    aviso(context, 'Código enviado (demo): $_enviado');
  }

  void _confirmar() {
    if (codigo.text.trim() != _enviado) {
      aviso(context, 'Código incorrecto');
      return;
    }
    store.cambiarCorreo(nuevo.text.trim());
    aviso(context, 'Correo actualizado');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final paso2 = _enviado != null;
    return Scaffold(
      appBar: barra('Cambiar correo'),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Campo(label: 'Correo actual', controller: TextEditingController(text: store.correo), locked: true),
            Campo(
              label: 'Contraseña actual',
              controller: clave,
              obscure: true,
              locked: paso2,
              validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
            ),
            Campo(
              label: 'Nuevo correo electrónico',
              controller: nuevo,
              keyboard: TextInputType.emailAddress,
              locked: paso2,
              validator: (v) => vCorreo(v) ??
                  (v!.trim().toLowerCase() == store.correo.toLowerCase() ? 'Es el mismo correo actual' : null),
            ),
            if (!paso2) BotonVino(texto: 'Enviar código de verificación', onPressed: _enviar),
            if (paso2) ...[
              Campo(label: 'Código de verificación (6 dígitos)', controller: codigo, keyboard: TextInputType.number),
              BotonVino(texto: 'Confirmar cambio', onPressed: _confirmar),
            ],
          ],
        ),
      ),
    );
  }
}