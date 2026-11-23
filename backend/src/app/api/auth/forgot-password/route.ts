import crypto from "node:crypto";
import { getDb } from "@/lib/db";
import { handle, json, readJson } from "@/lib/http";
import { Validator, str } from "@/lib/validation";
import { sha256, type UserRow } from "@/lib/auth";
import { sendPasswordResetEmail } from "@/lib/mailer";

const RESET_TTL_MS = 60 * 60 * 1000; // 1 hora

/** POST /api/auth/forgot-password — Envía al correo un enlace de restablecimiento. */
export async function POST(req: Request) {
  return handle(async () => {
    const body = await readJson(req);
    const email = str(body.email).toLowerCase();

    new Validator().required("email", email, "El correo es obligatorio").email("email", email).throwIfErrors();

    const db = getDb();
    const user = db.prepare("SELECT * FROM users WHERE email = ?").get(email) as UserRow | undefined;

    if (user) {
      const token = crypto.randomBytes(32).toString("hex");
      db.prepare("UPDATE password_resets SET used = 1 WHERE user_id = ? AND used = 0").run(user.id);
      db.prepare("INSERT INTO password_resets (user_id, token_hash, expires_at) VALUES (?, ?, ?)").run(
        user.id,
        sha256(token),
        Date.now() + RESET_TTL_MS,
      );

      const host = req.headers.get("x-forwarded-host") ?? req.headers.get("host");
      const proto = req.headers.get("x-forwarded-proto") ?? "http";
      const baseUrl = process.env.APP_URL || (host ? `${proto}://${host}` : new URL(req.url).origin);
      const link = `${baseUrl}/reset-password?token=${token}`;
      try {
        await sendPasswordResetEmail(user.email, user.nombre, link);
      } catch (err) {
        console.error("[mail] Error enviando el correo:", err);
      }
    }

    // Respuesta genérica para no revelar qué correos están registrados.
    return json({
      message: "Si el correo está registrado, recibirás un enlace para restablecer tu contraseña.",
    });
  });
}
