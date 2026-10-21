# CrediAPP

Aplicación móvil Flutter para el **Sistema de Gestión y Control de Préstamos (SGCP / STCP)**.

Prototipo funcional basado en las pantallas del Avance de Proyecto Final 2 (Grupo 2 - UTP).

## Qué incluye

- Login, crear cuenta y recuperar contraseña
- Menú principal / cartera
- Clientes, historial y estado de préstamos
- Préstamos, cronograma, detalle y observaciones
- Registro de pagos, cuotas por cobrar e historial
- Recordatorios y notificaciones
- Cobros por periodo y resumen general
- Perfil y cierre de sesión

Los datos son locales en memoria (demo académica, sin backend).

## Requisitos

- Flutter SDK 3.x
- Android SDK (para APK) o Chrome (para vista web)

## Cómo ejecutar

```bash
cd crediapp
flutter pub get
flutter run
```

En Chrome:

```bash
flutter run -d chrome
```

## Generar APK

```bash
flutter build apk --release
```

El APK queda en:

`build/app/outputs/flutter-apk/app-release.apk`

## Demo

- Correo: `rosa.delgado@prestamosya.pe`
- Contraseña: cualquiera (ej. `12345678`)

## Estructura principal

```text
lib/
  main.dart      # entrada de la app
  theme.dart     # colores y tema CrediAPP
  data.dart      # modelos y datos demo
  widgets.dart   # componentes reutilizables
  screens.dart   # pantallas del prototipo
```

## Curso

Universidad Tecnológica del Perú  
Curso Integrador I: Sistemas - Software  
Grupo 2
