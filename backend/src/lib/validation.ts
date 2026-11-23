import { HttpError, type FieldErrors } from "./http";

export const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
export const USERNAME_REGEX = /^[^\s@]+$/; // sin espacios ni "@" (para distinguirlo del correo al iniciar sesión)

export const MIN_LOGIN_PASSWORD = 6; // Pantalla de Login: mínimo 6 caracteres
export const MIN_PASSWORD = 8; // Registro / cambio / recuperación: mínimo 8 caracteres

export function str(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

/** Valida campos y lanza 422 con los mensajes por campo. */
export class Validator {
  errors: FieldErrors = {};

  required(field: string, value: string, message: string) {
    if (!value) this.errors[field] ??= message;
    return this;
  }

  email(field: string, value: string) {
    if (value && !EMAIL_REGEX.test(value)) this.errors[field] ??= "Formato de correo inválido";
    return this;
  }

  username(field: string, value: string) {
    if (value && !USERNAME_REGEX.test(value)) this.errors[field] ??= "El username no puede tener espacios ni @";
    return this;
  }

  minLength(field: string, value: string, min: number, label: string) {
    if (value && value.length < min) this.errors[field] ??= `${label} debe tener mínimo ${min} caracteres`;
    return this;
  }

  matches(field: string, a: string, b: string, message: string) {
    if (b && a !== b) this.errors[field] ??= message;
    return this;
  }

  add(field: string, message: string) {
    this.errors[field] ??= message;
    return this;
  }

  throwIfErrors(status = 422) {
    if (Object.keys(this.errors).length > 0) {
      throw new HttpError(status, "Hay errores en los datos enviados", this.errors);
    }
  }
}
