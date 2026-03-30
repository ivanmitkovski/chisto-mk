import { describe, expect, it } from "vitest";
import {
  validateContactForm,
  validateEmail,
  validatePhone,
  validateRequired,
} from "./validators";

describe("validateEmail", () => {
  it("rejects empty", () => {
    expect(validateEmail("")).toEqual({ field: "email", code: "required" });
    expect(validateEmail("   ")).toEqual({ field: "email", code: "required" });
  });

  it("rejects invalid format", () => {
    expect(validateEmail("not-an-email")).toEqual({ field: "email", code: "invalidEmail" });
  });

  it("accepts typical address", () => {
    expect(validateEmail("a@b.co")).toBeNull();
    expect(validateEmail("  user@example.com  ")).toBeNull();
  });
});

describe("validatePhone", () => {
  it("requires value", () => {
    expect(validatePhone("")).toEqual({ field: "phone", code: "required" });
  });

  it("rejects too-short pattern", () => {
    expect(validatePhone("123")).toEqual({ field: "phone", code: "invalidPhone" });
  });

  it("accepts plausible numbers", () => {
    expect(validatePhone("+389 70 123 456")).toBeNull();
    expect(validatePhone("(02) 311-2345")).toBeNull();
  });
});

describe("validateRequired", () => {
  it("flags empty fullName", () => {
    expect(validateRequired("fullName", "")).toEqual({ field: "fullName", code: "required" });
  });
});

describe("validateContactForm", () => {
  it("returns multiple field errors", () => {
    const errors = validateContactForm({
      fullName: "",
      phone: "",
      email: "bad",
      message: "",
    });
    expect(errors.map((e) => e.field).sort()).toEqual(["email", "fullName", "message", "phone"]);
  });

  it("passes valid payload", () => {
    expect(
      validateContactForm({
        fullName: "Test User",
        phone: "+38970111222",
        email: "test@example.com",
        message: "Hello",
      }),
    ).toHaveLength(0);
  });
});
