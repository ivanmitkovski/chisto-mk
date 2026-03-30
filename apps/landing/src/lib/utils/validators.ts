export type FieldErrorCode = "required" | "invalidEmail" | "invalidPhone";

export interface FieldError {
  field: keyof ContactFormData;
  code: FieldErrorCode;
}

export function validateEmail(value: string): FieldError | null {
  const trimmed = value.trim();
  if (!trimmed) return { field: "email", code: "required" };
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(trimmed)) return { field: "email", code: "invalidEmail" };
  return null;
}

export function validateRequired(field: keyof ContactFormData, value: string): FieldError | null {
  if (!value.trim()) return { field, code: "required" };
  return null;
}

export function validatePhone(phone: string): FieldError | null {
  if (!phone.trim()) return { field: "phone", code: "required" };
  if (!/^[+\d\s()-]{7,20}$/.test(phone)) return { field: "phone", code: "invalidPhone" };
  return null;
}

export interface ContactFormData {
  fullName: string;
  phone: string;
  email: string;
  message: string;
}

export function validateContactForm(data: ContactFormData): FieldError[] {
  const errors: FieldError[] = [];

  const nameErr = validateRequired("fullName", data.fullName);
  if (nameErr) errors.push(nameErr);

  const phoneErr = validatePhone(data.phone);
  if (phoneErr) errors.push(phoneErr);

  const emailErr = validateEmail(data.email);
  if (emailErr) errors.push(emailErr);

  const msgErr = validateRequired("message", data.message);
  if (msgErr) errors.push(msgErr);

  return errors;
}
