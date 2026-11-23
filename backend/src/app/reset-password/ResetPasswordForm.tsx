"use client";

import { useState, type FormEvent } from "react";
import { useSearchParams } from "next/navigation";

const MIN_PASSWORD = 8;

type Errors = { password?: string; confirmPassword?: string };

/** Pantalla a la que redirige el enlace del correo para ingresar la nueva contraseña. */
export default function ResetPasswordForm() {
  const token = useSearchParams().get("token") ?? "";
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [show, setShow] = useState(false);
  const [errors, setErrors] = useState<Errors>({});
  const [status, setStatus] = useState<{ type: "error" | "success"; text: string } | null>(null);
  const [loading, setLoading] = useState(false);

  function validate(): Errors {
    const e: Errors = {};
    if (!password) e.password = "La contraseña es obligatoria";
    else if (password.length < MIN_PASSWORD) e.password = `Debe tener mínimo ${MIN_PASSWORD} caracteres`;
    if (!confirmPassword) e.confirmPassword = "Confirma la contraseña";
    else if (password !== confirmPassword) e.confirmPassword = "Las contraseñas no coinciden";
    return e;
  }

  async function onSubmit(ev: FormEvent) {
    ev.preventDefault();
    setStatus(null);
    const e = validate();
    setErrors(e);
    if (Object.keys(e).length) return;

    setLoading(true);
    try {
      const res = await fetch("/api/auth/reset-password", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ token, password, confirmPassword }),
      });
      const data = await res.json();
      if (res.ok) {
        setStatus({ type: "success", text: data.message });
        setPassword("");
        setConfirmPassword("");
      } else {
        setErrors(data.errors ?? {});
        setStatus({ type: "error", text: data.message });
      }
    } catch {
      setStatus({ type: "error", text: "No se pudo conectar con el servidor" });
    } finally {
      setLoading(false);
    }
  }

  if (!token) {
    return (
      <>
        <h1>Enlace inválido</h1>
        <p className="muted">El enlace de recuperación no es válido. Solicita uno nuevo desde la app.</p>
      </>
    );
  }

  const done = status?.type === "success";

  return (
    <form onSubmit={onSubmit} noValidate>
      <h1>Nueva contraseña</h1>
      <p className="muted">Ingresa tu nueva contraseña (mínimo {MIN_PASSWORD} caracteres).</p>

      <label htmlFor="password">Nueva contraseña</label>
      <div className="field">
        <input
          id="password"
          type={show ? "text" : "password"}
          value={password}
          className={errors.password ? "invalid" : ""}
          onChange={(e) => setPassword(e.target.value)}
          disabled={done}
        />
        <button type="button" className="toggle" onClick={() => setShow(!show)}>
          {show ? "Ocultar" : "Mostrar"}
        </button>
      </div>
      {errors.password && <div className="error">{errors.password}</div>}

      <label htmlFor="confirmPassword">Confirmar contraseña</label>
      <div className="field">
        <input
          id="confirmPassword"
          type={show ? "text" : "password"}
          value={confirmPassword}
          className={errors.confirmPassword ? "invalid" : ""}
          onChange={(e) => setConfirmPassword(e.target.value)}
          disabled={done}
        />
      </div>
      {errors.confirmPassword && <div className="error">{errors.confirmPassword}</div>}

      {status && <div className={`alert ${status.type}`}>{status.text}</div>}

      {!done && (
        <button className="primary" type="submit" disabled={loading}>
          {loading ? "Guardando..." : "Guardar contraseña"}
        </button>
      )}
      {done && <p className="muted" style={{ marginTop: 16 }}>Ya puedes volver a la app e iniciar sesión.</p>}
    </form>
  );
}
