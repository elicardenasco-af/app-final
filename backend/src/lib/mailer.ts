import nodemailer, { type Transporter } from "nodemailer";

/**
 * Envío de correos.
 * - Si hay SMTP configurado en .env.local se usa ese servidor.
 * - Si no, se crea una cuenta de prueba de Ethereal (https://ethereal.email)
 *   y se imprime en consola la URL para ver el correo.
 */

let transporterPromise: Promise<Transporter | null> | null = null;

async function createTransporter(): Promise<Transporter | null> {
  if (process.env.SMTP_HOST) {
    return nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port: Number(process.env.SMTP_PORT || 587),
      secure: process.env.SMTP_SECURE === "true",
      auth: process.env.SMTP_USER ? { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS } : undefined,
    });
  }
  try {
    const account = await nodemailer.createTestAccount();
    console.log(`[mail] SMTP no configurado. Usando cuenta de prueba Ethereal: ${account.user}`);
    return nodemailer.createTransport({
      host: account.smtp.host,
      port: account.smtp.port,
      secure: account.smtp.secure,
      auth: { user: account.user, pass: account.pass },
    });
  } catch (err) {
    console.warn("[mail] No se pudo crear la cuenta de prueba Ethereal:", (err as Error).message);
    return null;
  }
}

function getTransporter() {
  transporterPromise ??= createTransporter();
  return transporterPromise;
}

export async function sendPasswordResetEmail(to: string, nombre: string, link: string) {
  // Siempre se registra el enlace en consola para facilitar las pruebas en desarrollo.
  console.log(`[mail] Enlace de restablecimiento para ${to}: ${link}`);

  const transporter = await getTransporter();
  if (!transporter) return;

  const info = await transporter.sendMail({
    from: process.env.MAIL_FROM || "Tienda App <no-reply@tienda.app>",
    to,
    subject: "Restablece tu contraseña",
    text: `Hola ${nombre},\n\nRecibimos una solicitud para restablecer tu contraseña.\nAbre el siguiente enlace (válido por 1 hora):\n\n${link}\n\nSi no fuiste tú, ignora este correo.`,
    html: `
      <div style="font-family:Arial,sans-serif;max-width:480px;margin:auto">
        <h2 style="color:#0b3d6e">Restablece tu contraseña</h2>
        <p>Hola <b>${escapeHtml(nombre)}</b>,</p>
        <p>Recibimos una solicitud para restablecer tu contraseña. Haz clic en el botón (válido por 1 hora):</p>
        <p><a href="${link}" style="background:#0b3d6e;color:#fff;padding:12px 20px;border-radius:8px;text-decoration:none;display:inline-block">Restablecer contraseña</a></p>
        <p style="color:#666;font-size:13px">Si no fuiste tú, ignora este correo.</p>
      </div>`,
  });

  const preview = nodemailer.getTestMessageUrl(info);
  if (preview) console.log(`[mail] Vista previa del correo: ${preview}`);
}

function escapeHtml(s: string) {
  return s.replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]!);
}
