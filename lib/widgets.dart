import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';

class Campo extends StatelessWidget {
  const Campo({
    super.key,
    required this.label,
    required this.controller,
    this.obscure = false,
    this.keyboard,
    this.suffix,
    this.readOnly = false,
    this.onTap,
    this.locked = false,
    this.validator,
    this.suffixIcon,
    this.onChanged,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboard;
  final String? suffix;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool locked;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: CrediColors.texto)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboard,
            inputFormatters: inputFormatters,
            readOnly: readOnly || locked,
            onTap: onTap,
            validator: validator,
            onChanged: onChanged,
            style: TextStyle(color: locked ? CrediColors.muted : CrediColors.texto),
            decoration: InputDecoration(
              suffixText: suffix,
              suffixIcon: locked ? const Icon(Icons.lock_outline, size: 20) : suffixIcon,
              fillColor: locked ? const Color(0xFFEEF0F4) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class BotonVino extends StatelessWidget {
  const BotonVino({super.key, required this.texto, required this.onPressed});

  final String texto;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: CrediColors.vino,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onPressed,
        child: Text(texto, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class ChipEstado extends StatelessWidget {
  const ChipEstado({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final atrasado = texto.contains('ATRAS') || texto.contains('VENC');
    final cancelado = texto.contains('CANCEL') || texto.contains('SIN');
    final color = atrasado
        ? const Color(0xFFB42318)
        : cancelado
            ? const Color(0xFF175CD3)
            : CrediColors.verde;
    final fondo = atrasado
        ? const Color(0xFFFEE4E2)
        : cancelado
            ? const Color(0xFFE8F0FE)
            : CrediColors.verdeSuave;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(20)),
      child: Text(texto, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}

class AvatarIni extends StatelessWidget {
  const AvatarIni({super.key, required this.texto, this.radio = 22});

  final String texto;
  final double radio;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radio,
      backgroundColor: CrediColors.vinoOscuro,
      child: Text(texto, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }
}

class Tarjeta extends StatelessWidget {
  const Tarjeta({super.key, required this.child, this.onTap, this.color});

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(14), child: child),
      ),
    );
  }
}

PreferredSizeWidget barra(String titulo, {List<Widget>? actions}) {
  return AppBar(
    backgroundColor: CrediColors.fondo,
    foregroundColor: CrediColors.texto,
    elevation: 0,
    centerTitle: true,
    title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
    actions: actions,
  );
}

void aviso(BuildContext context, String mensaje) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
}

class FiltroChip extends StatelessWidget {
  const FiltroChip({super.key, required this.texto, required this.activo, required this.onTap});

  final String texto;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(texto),
        selected: activo,
        selectedColor: CrediColors.vinoOscuro,
        labelStyle: TextStyle(color: activo ? Colors.white : CrediColors.texto, fontWeight: FontWeight.w700),
        showCheckmark: false,
        onSelected: (_) => onTap(),
      ),
    );
  }
}