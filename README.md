# Tienda App — E-Commerce con Flutter + API REST (Next.js)

Proyecto final de Aplicaciones Móviles. App de comercio electrónico donde los usuarios
pueden registrarse, iniciar sesión, ver y filtrar productos, agregarlos al carrito y
simular una compra.

| Parte    | Tecnología                     | Carpeta     |
|----------|--------------------------------|-------------|
| Frontend | Flutter (Dart)                 | `lib/`      |
| Backend  | Next.js 16 (API REST, TypeScript) | `backend/` |
| Docs     | Documento técnico              | `docs/`     |

## 1. Ejecutar el backend

Requisitos: Node.js 22.13 o superior (usa el módulo nativo `node:sqlite`).

```bash
cd backend
npm install
cp .env.example .env.local   # opcional: JWT_SECRET, SMTP, APP_URL
npm run dev                  # http://localhost:3000
```

La base de datos SQLite (`backend/data/ecommerce.db`) se crea y se llena con productos
de ejemplo automáticamente en la primera petición.

## 2. Ejecutar la app Flutter

```bash
flutter pub get
flutter run
```

URL de la API por defecto:

- Emulador Android: `http://10.0.2.2:3000/api`
- Simulador iOS / web / escritorio: `http://localhost:3000/api`
- Celular físico (misma red Wi-Fi que el PC):
  `flutter run --dart-define=API_URL=http://IP_DE_TU_PC:3000/api`

## 3. Recuperación de contraseña

Si no configuras SMTP en `backend/.env.local`, el backend usa una cuenta de prueba de
[Ethereal](https://ethereal.email) e imprime en la consola el enlace de restablecimiento
y la URL para ver el correo. El enlace abre la pantalla `/reset-password` del backend.

## 4. Pruebas

```bash
flutter test
```

Ver más detalles en [docs/DOCUMENTO_TECNICO.md](docs/DOCUMENTO_TECNICO.md).
