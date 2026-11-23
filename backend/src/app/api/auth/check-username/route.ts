import { getDb } from "@/lib/db";
import { handle, json, HttpError } from "@/lib/http";

/** GET /api/auth/check-username?username=xxx — Verifica si el username está disponible. */
export async function GET(req: Request) {
  return handle(async () => {
    const username = new URL(req.url).searchParams.get("username")?.trim() ?? "";
    if (!username) throw new HttpError(400, "El parámetro username es obligatorio");
    const exists = getDb().prepare("SELECT 1 FROM users WHERE username = ?").get(username);
    return json({ username, available: !exists });
  });
}
