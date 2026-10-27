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
  main.dart         # entrada de la app
  theme.dart        # colores y tema CrediAPP
  data.dart         # modelos y datos demo
  widgets.dart      # componentes reutilizables
  screens.dart      # pantallas del prototipo
  auth_service.dart # Control TDD (reglas RF001/RF002/RF003)
test/
  auth_service_test.dart  # CP del Excel (Arrange-Act-Assert)
```

## TDD (como el ejemplo de la profesora)

Misma idea que `tdd-cajero/flutter-dart`:

1. **Service (Control)** = reglas de negocio
2. **Repository (DAO)** = acceso a datos
3. **FakeRepository** = falso en memoria (solo tests)
4. Cada test ≈ filas del Excel `Casos_de_Prueba_RF001_RF050...`

### Archivos TDD

```text
lib/
  auth_service.dart
  tdd/
    tdd_common.dart
    recuperacion_service.dart   # RF004-RF005
    cliente_service.dart        # RF006-RF011
    prestamo_service.dart       # RF012-RF024 + RF049-RF050
    pago_service.dart           # RF025-RF037
    recordatorio_service.dart   # RF038-RF043
    panel_service.dart          # RF044-RF048
test/
  auth_service_test.dart
  tdd/all_rf_tdd_test.dart
```

Correr todos los tests TDD:

```bash
flutter test test/auth_service_test.dart test/tdd/all_rf_tdd_test.dart
```

## Curso

Universidad Tecnológica del Perú  
Curso Integrador I: Sistemas - Software  
Grupo 2
