import { Transform } from 'class-transformer';

/** Avoid implicit `"false"` → true coercion from enableImplicitConversion. */
export function StrictBoolean(): PropertyDecorator {
  return Transform(({ value }) => {
    if (value === true || value === false) return value;
    if (value === 'true' || value === 1 || value === '1') return true;
    if (value === 'false' || value === 0 || value === '0') return false;
    return value;
  });
}
