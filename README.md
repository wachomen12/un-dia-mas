# 🌅 Un Día Más

Una app de mensajes motivadores diarios. Cálida, en español, para acompañarte **un día a la vez**.

> *"No tienes que estar bien todo el tiempo. Solo hoy basta."*

---

## ✨ Qué hace

- **Frase del día** según la categoría que elijas
- **5 categorías** (Momento difícil, Lograr meta, Necesito calma, Gratitud, Amor propio) con 120 frases cada una
- **🇪🇨 Botón especial** con 80 frases en español ecuatoriano (*mijín, ñaño, ya pues, dale*)
- **Racha tipo Duolingo** con calendario semanal y compartible como imagen
- **9 logros desbloqueables** con confeti
- **Diario diario** con selector de mood (😢 😟 😐 🙂 😊)
- **Gráfica de tu mood** en el tiempo (7/14/30/90 días)
- **Cartas a tu yo futuro** — escribís hoy, te llegan como notificación en la fecha que elijás
- **Notificación diaria** (mañana + noche opcional) en Android
- **Widget de pantalla de inicio** en Android
- **Compartir frase como imagen** estilo Instagram Story
- **Modo oscuro automático**
- **Favoritas** + diario buscable
- **Datos 100% locales** — sin servidor, sin cuentas, sin internet requerido (en Android)

---

## 🛠️ Tecnología

- **Flutter 3.27** / Dart 3.6
- `shared_preferences` para guardar datos locales
- `flutter_local_notifications` + `timezone` para notificaciones
- `home_widget` para el widget de Android
- `fl_chart` para gráficas de mood
- `share_plus` para compartir imágenes
- `google_fonts` (Nunito + Playfair Display)

---

## 🚀 Para abrir / probar

### Versión web (cualquier navegador, también iPhone)

🌐 Si está desplegada: **[abrir Un Día Más](#)** *(reemplaza con tu link)*

Funciona en cualquier navegador moderno (Chrome, Safari, Firefox, Edge). En iPhone, podés **"Agregar a pantalla de inicio"** desde Safari y se comporta como app nativa.

⚠️ En web no funcionan las notificaciones programadas ni el widget. Para esas necesitás la versión Android.

### Versión Android (APK)

Bajá el APK desde [Releases](#) e instalá. Aceptá "fuentes desconocidas" si el sistema te lo pide.

---

## 💻 Para correrla en tu compu

Necesitás Flutter instalado: https://docs.flutter.dev/get-started/install

```bash
git clone https://github.com/TU-USUARIO/un-dia-mas.git
cd un-dia-mas
flutter pub get

# Web
flutter run -d chrome

# Android (con celular conectado o emulador)
flutter run
```

---

## 📦 Generar el APK / web

```bash
# APK release
flutter build apk --release
# El APK queda en build/app/outputs/flutter-apk/app-release.apk

# Web release
flutter build web --release
# Los archivos quedan en build/web/
```

Para **GitHub Pages** (dominio con subpath `/un-dia-mas/`):

```bash
flutter build web --release --base-href "/un-dia-mas/"
```

---

## 🌐 Desplegar la versión web

### Opción A: GitHub Pages (gratis)

1. En tu repo: **Settings → Pages → Source = GitHub Actions**.
2. Creá `.github/workflows/web.yml`:

```yaml
name: Deploy web to Pages
on:
  push:
    branches: [main]
permissions:
  contents: read
  pages: write
  id-token: write
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: flutter build web --release --base-href "/un-dia-mas/"
      - uses: actions/upload-pages-artifact@v3
        with:
          path: build/web
  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - id: deployment
        uses: actions/deploy-pages@v4
```

3. Cada push a `main` regenera y publica la web automáticamente.

### Opción B: Netlify / Vercel (gratis, sin subpath, más simple)

1. Conectá tu repo en https://app.netlify.com o https://vercel.com.
2. Build command: `flutter build web --release`
3. Publish directory: `build/web`
4. Listo, te dan un link público tipo `un-dia-mas.netlify.app`.

### Opción C: Servidor local rápido (para probar)

```bash
cd build/web
python -m http.server 8000
# Abrir http://localhost:8000
```

---

## 📂 Estructura del proyecto

```
lib/
├── main.dart                     # Entry point + tema + inicialización
├── models/                       # Categoria, Mood, Carta
├── data/
│   ├── frases.dart              # 680 frases organizadas por categoría
│   └── logros.dart              # Definición de medallas
├── services/                     # Storage, notificaciones, widget, compartir
├── theme/
│   └── app_theme.dart           # Colores cálidos + light/dark mode
├── widgets/                      # FraseCard, RachaCompacta, StoryCard, Confeti...
└── screens/                      # Home, Racha, Diario, Cartas, Logros, Ajustes...

android/                          # Configuración Android + widget nativo Kotlin
web/                              # HTML + manifest + splash custom
```

---

## 💛 Licencia

MIT — usá la app, copiala, modificala. Solo dejá el crédito si la subís a algún lado.

---

*Creada con cariño en Ecuador 🇪🇨 para acompañar a quien lo necesite, un día a la vez.*
