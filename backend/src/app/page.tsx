import fs from "node:fs";
import path from "node:path";

// Se evalúa en cada visita para detectar si ya se generó el APK.
export const dynamic = "force-dynamic";

const APK_PATH = path.join(process.cwd(), "public", "downloads", "TiendaApp.apk");

function apkInfo() {
  try {
    const stat = fs.statSync(APK_PATH);
    return {
      sizeMb: (stat.size / 1024 / 1024).toFixed(1),
      date: stat.mtime.toLocaleString("es-CO", { dateStyle: "medium", timeStyle: "short" }),
    };
  } catch {
    return null;
  }
}

const endpoints: [string, string, string][] = [
  ["POST", "/api/auth/register", "Registro de usuario"],
  ["GET", "/api/auth/check-username?username=", "Verifica username único"],
  ["POST", "/api/auth/login", "Inicio de sesión (devuelve JWT)"],
  ["POST", "/api/auth/logout", "Cierre de sesión (JWT)"],
  ["POST", "/api/auth/forgot-password", "Envía enlace de recuperación"],
  ["POST", "/api/auth/reset-password", "Restablece la contraseña"],
  ["GET", "/api/users/me", "Perfil del usuario (JWT)"],
  ["PUT", "/api/users/me", "Actualiza perfil (JWT)"],
  ["PUT", "/api/users/me/password", "Cambia contraseña (JWT)"],
  ["GET", "/api/banners", "Banners del carrusel"],
  ["GET", "/api/categories", "Categorías"],
  ["GET", "/api/products?search=&categoryId=", "Listado / filtro de productos"],
  ["GET", "/api/products/:id", "Detalle de producto"],
  ["GET", "/api/config", "Reglas de IVA y envío"],
  ["GET", "/api/orders", "Mis pedidos (JWT)"],
  ["POST", "/api/orders", "Simula la compra (JWT)"],
];

export default function Home() {
  const apk = apkInfo();
  return (
    <main className="container" style={{ maxWidth: 640 }}>
      <div className="card" style={{ marginBottom: 20 }}>
        <h1>Descargar Tienda App</h1>
        {apk ? (
          <>
            <p className="muted">
              Instalador para Android (APK, {apk.sizeMb} MB · generado el {apk.date}).
            </p>
            <a className="button primary" href="/downloads/TiendaApp.apk" download>
              Descargar app
            </a>
            <ol className="steps">
              <li>Abre esta página desde el navegador del celular, conectado a la misma red Wi-Fi que el PC.</li>
              <li>Toca <b>Descargar app</b> y abre el archivo descargado.</li>
              <li>Si Android lo pide, permite <b>instalar apps de origen desconocido</b> para el navegador.</li>
              <li>Mantén el backend encendido en el PC mientras usas la app.</li>
            </ol>
          </>
        ) : (
          <p className="muted">
            Aún no se ha generado el instalador. En el PC ejecuta <code>./scripts/build_apk.sh</code>.
          </p>
        )}
      </div>

      <div className="card">
        <h1>Tienda App — API REST</h1>
        <p className="muted">Backend en Next.js para la aplicación Flutter.</p>
        <table>
          <tbody>
            {endpoints.map(([method, path, desc]) => (
              <tr key={method + path}>
                <td><b>{method}</b></td>
                <td><code>{path}</code></td>
                <td>{desc}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </main>
  );
}
