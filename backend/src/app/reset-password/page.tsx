import { Suspense } from "react";
import ResetPasswordForm from "./ResetPasswordForm";

export const metadata = { title: "Restablecer contraseña" };

export default function ResetPasswordPage() {
  return (
    <main className="container">
      <div className="card">
        <Suspense>
          <ResetPasswordForm />
        </Suspense>
      </div>
    </main>
  );
}
