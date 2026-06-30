import {
  registerDecorator,
  ValidationOptions,
  ValidatorConstraint,
  ValidatorConstraintInterface,
  ValidationArguments,
} from 'class-validator';

const WEAK_PATTERNS = [
  /^(.)\1{7,}$/,
  /^12345678$/,
  /^password$/i,
  /^password1$/i,
  /^qwerty123$/i,
  /^abc12345$/i,
  /^letmein\d*$/i,
  /^welcome\d*$/i,
  /^admin123$/i,
  /^changeme$/i,
];

@ValidatorConstraint({ name: 'IsStrongPassword', async: false })
export class IsStrongPasswordConstraint implements ValidatorConstraintInterface {
  validate(value: unknown, _args: ValidationArguments): boolean {
    if (typeof value !== 'string') return false;
    const s = value.trim();
    if (s.length < 8 || s.length > 72) return false;
    if (!/\d/.test(s) || !/[A-Za-z]/.test(s)) return false;
    const lower = s.toLowerCase();
    for (const pattern of WEAK_PATTERNS) {
      if (pattern.test(lower)) return false;
    }
    return true;
  }

  defaultMessage(_args: ValidationArguments): string {
    return 'Password is too weak. Use a mix of letters and numbers and avoid common patterns.';
  }
}

export function IsStrongPassword(validationOptions?: ValidationOptions) {
  return function (object: object, propertyName: string) {
    registerDecorator({
      target: object.constructor,
      propertyName,
      options: validationOptions ?? {},
      constraints: [],
      validator: IsStrongPasswordConstraint,
    });
  };
}
