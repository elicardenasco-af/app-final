import { getDb } from "@/lib/db";
import { handle, json, readJson } from "@/lib/http";
import { Validator, MIN_PASSWORD } from "@/lib/validation";
import { hashPassword, requireUser, verifyPassword } from "@/lib/auth";

/** PUT /api/users/me/password — Cambia la contraseña del usuario autenticado. */
export async function PUT(req: Request) {
  return handle(async () => {
    const user = await requireUser(req);
    const body = await readJson(req);
    const currentPassword = typeof body.currentPassword === "string" ? body.currentPassword : "";
    const newPassword = typeof body.newPassword === "string" ? body.newPassword : "";
    const confirmPassword = typeof body.confirmPassword === "string" ? body.confirmPassword : "";

    const v = new Validator()
      .required("currentPassword", currentPassword, "La contraseña actual es obligatoria")
      .required("newPassword", newPassword, "La nueva contraseña es obligatoria")
      .minLength("newPassword", newPassword, MIN_PASSWORD, "La nueva contraseña")
      .required("confirmPassword", confirmPassword, "Debes verificar la contraseña")
      .matches("confirmPassword", newPassword, confirmPassword, "Las contraseñas no coinciden");
    v.throwIfErrors();

    if (!(await verifyPassword(currentPassword, user.password_hash))) {
      v.add("currentPassword", "La contraseña actual es incorrecta").throwIfErrors();
    }

    getDb()
      .prepare("UPDATE users SET password_hash = ?, updated_at = datetime('now') WHERE id = ?")
      .run(await hashPassword(newPassword), user.id);

    return json({ message: "Contraseña actualizada" });
  });
}
