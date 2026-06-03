# Un Día Más — Instrucciones para compilar tu APK

Ya tienes TODO el código de la app escrito. Solo faltan 3 cosas: instalar Flutter, generar las carpetas de Android, y compilar el APK.

---

## 1. Instalar Flutter (una sola vez)

1. Descarga Flutter desde: https://docs.flutter.dev/get-started/install/windows
2. Descomprime el ZIP en `C:\flutter`
3. Agrega `C:\flutter\bin` al PATH de Windows (busca "Editar variables de entorno" → Path → Nuevo).
4. Instala Android Studio desde: https://developer.android.com/studio (necesario para el SDK de Android).
5. Abre PowerShell y corre:
   ```
   flutter doctor --android-licenses
   ```
   Acepta todo con `y`.
6. Verifica con:
   ```
   flutter doctor
   ```
   Debes ver palomitas verdes en Flutter y Android toolchain.

---

## 2. Generar las carpetas de Android para este proyecto

Abre PowerShell en la carpeta del proyecto:

```powershell
cd "C:\Users\bryan\OneDrive - ULEAM\Escritorio\aplicacion movil de motivacion"
flutter create . --project-name un_dia_mas --org com.undiamas --platforms=android
flutter pub get
```

Esto crea las carpetas `android/`, `windows/`, etc. **No toca el código en `lib/`** (que es el que ya escribí).

---

## 3. Agregar permisos a Android

Abre el archivo `android/app/src/main/AndroidManifest.xml`. Dentro de `<manifest>`, **antes** de `<application>`, agrega estas líneas:

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
```

Y **dentro** de `<application>`, agrega estos `<receiver>` (al final, antes de `</application>`):

```xml
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```

Y configura el SDK mínimo. Abre `android/app/build.gradle` (o `build.gradle.kts`) y busca `minSdkVersion`/`minSdk`. Ponlo en `21` si está más bajo.

En el mismo archivo, busca `compileSdkVersion`/`compileSdk` y ponlo en `34` (o el más reciente).

---

## 4. Probar la app

Conecta tu celular Android por USB (con depuración USB activada — Ajustes → Acerca del teléfono → toca 7 veces "Número de compilación" → vuelve atrás → Opciones de desarrollador → activar Depuración USB).

```powershell
flutter run
```

Tu app debería abrirse en tu celular.

---

## 5. Generar el APK final

```powershell
flutter build apk --release
```

El APK queda en:
```
build\app\outputs\flutter-apk\app-release.apk
```

Cópialo a tu celular, ábrelo, dale "Instalar". ¡Listo!

---

## Estructura del código que ya está escrito

```
lib/
  main.dart                              ← arranque de la app
  models/
    categoria.dart                       ← las 3 categorías
  data/
    frases.dart                          ← 90 frases (30 por categoría)
  theme/
    app_theme.dart                       ← colores y tipografía
  services/
    storage_service.dart                 ← guarda categoría, hora, racha
    notification_service.dart            ← notificación diaria
    share_service.dart                   ← convierte frase en imagen
  widgets/
    frase_card.dart                      ← la tarjeta bonita de la frase
  screens/
    onboarding_categoria_screen.dart     ← pantalla "¿qué estás viviendo?"
    onboarding_hora_screen.dart          ← pantalla "¿a qué hora?"
    home_screen.dart                     ← pantalla principal
    ajustes_screen.dart                  ← cambiar categoría u hora después
```

---

## Si algo falla

- **"flutter no se reconoce como comando"** → Reinicia PowerShell después de agregar el PATH.
- **`flutter pub get` falla** → Revisa que tengas internet y que `pubspec.yaml` no se haya modificado.
- **La notificación no llega** → En tu celular, ve a Ajustes → Apps → Un Día Más → Notificaciones → activa todo. En Android 12+ también activa "Alarmas y recordatorios".
- **El APK no instala** → En tu celular activa "Instalar de fuentes desconocidas".
