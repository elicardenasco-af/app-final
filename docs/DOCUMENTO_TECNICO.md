# Documento Técnico — App E-Commerce con Flutter

**Asignatura:** Aplicaciones Móviles — Proyecto final
**Institución:** Corporación Universitaria Minuto de Dios — Ingeniería de Sistemas

---

## 1. Objetivo general

Desarrollar una aplicación móvil de comercio electrónico con **Flutter**, donde los
usuarios puedan registrarse, iniciar sesión, visualizar productos, filtrarlos,
agregarlos al carrito y simular una compra. El backend es una **API REST** propia,
desarrollada con **Next.js** (Node.js).

## 2. Tecnologías

| Capa | Tecnología | Uso |
|------|-----------|-----|
| Frontend | Flutter / Dart | App móvil (Android, iOS; también corre en web/escritorio) |
| Estado | `provider` | `AuthProvider`, `CartProvider`, `NavigationProvider` |
| HTTP | `http` | Consumo de la API REST |
| Almacenamiento seguro | `flutter_secure_storage` | Guarda el JWT (Keychain en iOS / Keystore en Android) |
| Formato | `intl` | Moneda en pesos colombianos (COP) y fechas en español |
| Backend | Next.js 16 (Route Handlers) + TypeScript | API REST bajo `/api` |
| Base de datos | SQLite (módulo nativo `node:sqlite`) | Archivo `backend/data/ecommerce.db` |
| Autenticación | `jose` (JWT HS256) + `bcryptjs` | Firma de tokens y hash de contraseñas |
| Correo | `nodemailer` | Envío del enlace de recuperación de contraseña |

## 3. Arquitectura

```
┌──────────────────────────┐        HTTP/JSON         ┌───────────────────────────┐
│     App Flutter          │  Authorization: Bearer   │   API REST (Next.js)      │
│                          │ ───────────────────────► │                           │
│ Screens (UI)             │                          │ app/api/**/route.ts       │
│   ↓                      │                          │   ↓                       │
│ Providers (estado)       │ ◄─────────────────────── │ lib/ (auth, validación,   │
│   ↓                      │                          │      catálogo, correo)    │
│ Services (ApiClient)     │                          │   ↓                       │
│ TokenStorage (JWT)       │                          │ SQLite (node:sqlite)      │
└──────────────────────────┘                          └───────────────────────────┘
```

### 3.1 Estructura del frontend (`lib/`)

```
lib/
├── main.dart                  # MultiProvider + AuthGate (decide Login o Home según la sesión)
├── config/api_config.dart     # URL base de la API (configurable con --dart-define=API_URL)
├── core/                      # Tema, validadores y formateadores (moneda, fechas)
├── models/                    # User, Product, Category, CartItem, Order, Pricing, PromoBanner
├── services/                  # ApiClient (HTTP + JWT), AuthService, ShopService, TokenStorage
├── providers/                 # AuthProvider, CartProvider, NavigationProvider
├── widgets/                   # Drawer, avatar, campo de contraseña, selector de cantidad, etc.
└── screens/
    ├── auth/                  # Login, Registro, Recuperar contraseña
    ├── home/                  # Home, carrusel de banners, tarjeta de producto
    ├── product/               # Detalle del producto
    ├── cart/                  # Carrito de compras
    ├── profile/               # Perfil y cambio de contraseña
    ├── orders/                # Mis pedidos
    └── main_shell.dart        # Scaffold con Drawer + BottomNavigationBar
```

### 3.2 Estructura del backend (`backend/src/`)

```
backend/src/
├── lib/
│   ├── db.ts          # Conexión SQLite, creación de tablas y datos de ejemplo
│   ├── seed.ts        # Categorías, productos y banners iniciales
│   ├── auth.ts        # Firma/verificación de JWT, hash de contraseñas, requireUser()
│   ├── validation.ts  # Validador con mensajes de error por campo (HTTP 422)
│   ├── catalog.ts     # Mapeo de productos y cálculo de totales (IVA, envío)
│   ├── mailer.ts      # Envío del correo de recuperación
│   └── http.ts        # Respuestas JSON y manejo centralizado de errores
└── app/
    ├── api/…          # Endpoints REST
    └── reset-password # Página web a la que lleva el enlace del correo
```

## 4. Modelo de datos

| Tabla | Campos principales |
|-------|--------------------|
| `users` | id, nombre, apellidos, username (único), email (único), password_hash, avatar_url, created_at, updated_at |
| `revoked_tokens` | jti, expires_at — tokens invalidados al cerrar sesión |
| `password_resets` | user_id, token_hash, expires_at, used — enlaces de recuperación (1 hora, un solo uso) |
| `categories` | id, name |
| `products` | id, name, description, price, image_url, stock, category_id |
| `banners` | id, title, subtitle, image_url — imágenes del carrusel |
| `orders` | id, user_id, subtotal, tax, shipping, total, status, created_at |
| `order_items` | order_id, product_id, name, image_url, unit_price, quantity |

La base de datos se crea y se llena con datos de ejemplo automáticamente en la primera
petición al backend.

## 5. API REST

Base: `http://<host>:3000/api`. Todas las respuestas son JSON. Los errores tienen la
forma `{ "message": "...", "errors": { "campo": "mensaje" } }`.

| Método | Ruta | Auth | Descripción |
|--------|------|:----:|-------------|
| POST | `/auth/register` | — | Registra un usuario (nombre, apellidos, username, email, password, confirmPassword) |
| GET | `/auth/check-username?username=` | — | Verifica si un username está disponible |
| POST | `/auth/login` | — | Inicia sesión con username **o** correo + contraseña; devuelve `{ token, user }` |
| POST | `/auth/logout` | JWT | Revoca el token actual (cierre de sesión) |
| POST | `/auth/forgot-password` | — | Envía al correo el enlace de restablecimiento |
| POST | `/auth/reset-password` | — | Cambia la contraseña usando el token del enlace |
| GET | `/users/me` | JWT | Datos del usuario autenticado |
| PUT | `/users/me` | JWT | Actualiza nombre, apellidos y username |
| PUT | `/users/me/password` | JWT | Cambia la contraseña (pide la actual) |
| GET | `/products?search=&categoryId=` | — | Lista y filtra productos |
| GET | `/products/{id}` | — | Detalle de un producto |
| GET | `/categories` | — | Categorías para los chips de filtro |
| GET | `/banners` | — | Imágenes promocionales del carrusel |
| GET | `/config` | — | Reglas de precio (IVA 19 %, envío) |
| GET | `/orders` | JWT | Historial de pedidos del usuario ("Mis pedidos") |
| POST | `/orders` | JWT | Simula la compra: valida stock, calcula totales y guarda el pedido |

Códigos de estado usados: `200/201` éxito, `400` petición inválida, `401` no autenticado
o credenciales incorrectas, `404` no encontrado, `409` conflicto (username/correo en uso,
stock insuficiente), `422` errores de validación por campo.

## 6. Módulo de autenticación

- **Registro:** el backend valida los campos, verifica que el username y el correo sean
  únicos y guarda la contraseña con hash **bcrypt**.
- **Inicio de sesión:** acepta username o correo. Si las credenciales son correctas,
  devuelve un **JWT** firmado (HS256) con el id del usuario (`sub`), un identificador
  único (`jti`) y fecha de expiración (por defecto 7 días).
- **Manejo de sesión:** la app guarda el JWT en `flutter_secure_storage` y lo envía en
  cada petición en el encabezado `Authorization: Bearer <token>`. Al abrir la app,
  `AuthProvider.restoreSession()` valida el token con `GET /users/me`; si es inválido
  o expiró, se elimina y se muestra el Login.
- **Cierre de sesión:** la app llama a `POST /auth/logout` (el backend registra el `jti`
  como revocado), elimina el JWT del almacenamiento y vuelve al Login.
- **Recuperación de contraseña:**
  1. El usuario ingresa su correo en "¿Olvidaste tu contraseña?".
  2. El backend genera un token aleatorio, guarda solo su hash (SHA-256) con vigencia
     de 1 hora y envía por correo un enlace `…/reset-password?token=…`.
  3. El enlace abre una pantalla para ingresar la nueva contraseña.
  4. Se valida que cumpla los requisitos mínimos (8 caracteres y confirmación). El
     enlace queda invalidado después de usarse.

  Si no se configura SMTP en `backend/.env.local`, se usa una cuenta de prueba de
  Ethereal y el enlace se imprime en la consola del servidor.

## 7. Pantallas

### 7.1 Login
- Campos: username o correo, contraseña con botón mostrar/ocultar.
- Validaciones: campo no vacío, formato de email válido (si contiene `@`), mínimo 6
  caracteres en la contraseña, mensajes de error inline.
- "Iniciar sesión" llama al endpoint y almacena el JWT; "¿Olvidaste tu contraseña?"
  abre el flujo de recuperación; "Crear cuenta" navega al Registro.

### 7.2 Registro
- Campos: nombre, apellidos, username, correo, contraseña, verificar contraseña.
- Validaciones: ningún campo vacío, email válido, username único (verificado en el
  backend), contraseña de mínimo 8 caracteres, contraseñas coincidentes, mensajes de
  error por campo (incluidos los que devuelve el backend).
- "Registrarse" envía los datos y redirige al Login; "Ya tengo cuenta" regresa al Login.

### 7.3 Home
- **Drawer lateral:** header con avatar e información del usuario; opciones Inicio,
  Mis pedidos, Perfil y **Cerrar sesión** (elimina el JWT y redirige al Login).
- **BottomNavigationBar:** Home, Carrito (con contador de ítems) y Perfil.
- **Banner carousel** con auto-scroll cada 4 s y puntos indicadores.
- **Buscador** con ícono de lupa que filtra por nombre en tiempo real.
- **Chips de categorías** desplazables (Todos, Ropa, Electrónica, Hogar, Deportes,
  Accesorios).
- **Grid de 2 columnas** con imagen, nombre y precio; al tocar un producto se abre su
  detalle.

### 7.4 Detalle del producto
Imagen ampliada, nombre, categoría, descripción completa, precio destacado, selector
de cantidad (limitado por el stock), botón "Agregar al carrito" y botón de regreso.

### 7.5 Carrito de compras
- Listado: miniatura, nombre, precio unitario, control de cantidad (+ / −), botón
  eliminar y mensaje amigable cuando el carrito está vacío.
- Resumen: subtotal, **IVA (19 %) calculado automáticamente**, costo de envío
  ($12.000, gratis desde $200.000), **total final destacado** y botón
  **"Proceder al pago"**, que simula la compra con `POST /orders`. El backend vuelve a
  calcular los totales con los precios de la base de datos y descuenta el stock.

### 7.6 Perfil
- Muestra avatar (iniciales si no hay foto), nombre completo, username y correo.
- Campos editables: nombre, apellidos y username, con validaciones al guardar.
- "Guardar cambios" actualiza los datos en el backend (`PUT /users/me`).
- Opción "Cambiar contraseña" (pide la contraseña actual, la nueva y su confirmación).

### 7.7 Mis pedidos
Historial de compras simuladas con fecha, productos, cantidades y total.

## 8. Reglas de validación

| Regla | Login | Registro | Perfil | Nueva contraseña |
|-------|:-----:|:--------:|:------:|:----------------:|
| Campos obligatorios | ✓ | ✓ | ✓ | ✓ |
| Formato de email | ✓ | ✓ | — | — |
| Contraseña mínima | 6 | 8 | — | 8 |
| Contraseñas coinciden | — | ✓ | — | ✓ |
| Username único (backend) | — | ✓ | ✓ | — |

Las validaciones se hacen en la app (respuesta inmediata) y se repiten en el backend
(fuente de verdad); los errores del backend se muestran debajo del campo
correspondiente.

## 9. Seguridad

- Contraseñas almacenadas con hash bcrypt (nunca en texto plano).
- JWT firmado con un secreto configurable (`JWT_SECRET`) y con expiración.
- Tokens revocados al cerrar sesión.
- Tokens de recuperación aleatorios, guardados como hash, de un solo uso y con
  vigencia de 1 hora. La respuesta de "olvidé mi contraseña" es genérica para no
  revelar qué correos están registrados.
- Consultas SQL parametrizadas (sin concatenar datos del usuario).
- Los totales del pedido se calculan en el backend, no se confía en los enviados por
  la app.

## 10. Instalación y ejecución

### Backend
Requisitos: Node.js 22.13 o superior.

```bash
cd backend
npm install
cp .env.example .env.local   # opcional: JWT_SECRET, SMTP, APP_URL
npm run dev                  # http://localhost:3000
```

### App Flutter
```bash
flutter pub get
flutter run
```

| Dispositivo | URL de la API |
|-------------|---------------|
| Emulador Android | `http://10.0.2.2:3000/api` (automático) |
| Simulador iOS / web / escritorio | `http://localhost:3000/api` (automático) |
| Celular físico (misma red Wi-Fi) | `flutter run --dart-define=API_URL=http://IP_DEL_PC:3000/api` |

En Android se habilitó el permiso de Internet y el tráfico HTTP local
(`usesCleartextTraffic`); en iOS, la excepción de ATS para conexiones locales.

## 11. Pruebas

```bash
flutter test
```

- `test/validators_test.dart`: reglas de validación (email, longitudes, coincidencia).
- `test/cart_provider_test.dart`: agregar, cambiar cantidad, eliminar y cálculo de
  subtotal, IVA, envío y total.
- `test/login_screen_test.dart`: prueba de widget de la pantalla de Login (mensajes de
  error inline).

Los endpoints del backend se probaron manualmente con `curl`, incluido el flujo
completo de recuperación (correo → enlace → nueva contraseña → enlace invalidado →
login con la nueva contraseña).

## 12. Entregables

- [x] Código fuente Flutter (`lib/`)
- [x] Código del backend API REST (`backend/`)
- [x] Documento técnico (este archivo)
- [ ] Video demo (3–5 minutos) — debe grabarlo el estudiante
