import { getDb, transaction } from "@/lib/db";
import { handle, json, readJson, HttpError } from "@/lib/http";
import { Validator, str, MIN_PASSWORD } from "@/lib/validation";
import { hashPassword, sha256 } from "@/lib/auth";

type ResetRow = { id: number; user_id: number; expires_at: number; used: number };

/** POST /api/auth/reset-password — Establece una nueva contraseña con el token recibido por correo. */
export async function POST(req: Request) {
  return handle(async () => {
    const body = await readJson(req);
    const token = str(body.token);
    const password = typeof body.password === "string" ? body.password : "";
    const confirmPassword = typeof body.confirmPassword === "string" ? body.confirmPassword : "";

    new Validator()
      .required("token", token, "El token es obligatorio")
      .required("password", password, "La contraseña es obligatoria")
      .minLength("password", password, MIN_PASSWORD, "La contraseña")
      .required("confirmPassword", confirmPassword, "Debes verificar la contraseña")
      .matches("confirmPassword", password, confirmPassword, "Las contraseñas no coinciden")
      .throwIfErrors();

    const reset = getDb()
      .prepare("SELECT * FROM password_resets WHERE token_hash = ?")
      .get(sha256(token)) as ResetRow | undefined;

    if (!reset || reset.used || reset.expires_at < Date.now()) {
      throw new HttpError(400, "El enlace no es válido o ya expiró. Solicita uno nuevo.");
    }

    const passwordHash = await hashPassword(password);
    transaction((db) => {
      db.prepare("UPDATE users SET password_hash = ?, updated_at = datetime('now') WHERE id = ?").run(
        passwordHash,
        reset.user_id,
      );
      db.prepare("UPDATE password_resets SET used = 1 WHERE id = ?").run(reset.id);
    });

    return json({ message: "Contraseña actualizada. Ya puedes iniciar sesión." });
  });
}
