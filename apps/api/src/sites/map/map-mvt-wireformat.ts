// Minimal MVT protobuf encoder (spec: https://github.com/mapbox/vector-tile-spec)

export interface MvtFeature {
  id: string;
  x: number;
  y: number;
  properties: Record<string, string | number>;
}

export function encodeMvt(layerName: string, features: MvtFeature[]): Buffer {
  if (features.length === 0) {
    return Buffer.alloc(0);
  }

  const keys: string[] = [];
  const values: (string | number)[] = [];
  const keyIndex = new Map<string, number>();
  const valueIndex = new Map<string | number, number>();

  function getKeyIdx(k: string): number {
    if (keyIndex.has(k)) return keyIndex.get(k)!;
    const idx = keys.length;
    keys.push(k);
    keyIndex.set(k, idx);
    return idx;
  }

  function getValueIdx(v: string | number): number {
    if (valueIndex.has(v)) return valueIndex.get(v)!;
    const idx = values.length;
    values.push(v);
    valueIndex.set(v, idx);
    return idx;
  }

  const encodedFeatures: Buffer[] = [];
  for (const f of features) {
    const tags: number[] = [];
    for (const [k, v] of Object.entries(f.properties)) {
      tags.push(getKeyIdx(k), getValueIdx(v));
    }

    const geomCommands = encodePointGeometry(f.x, f.y);
    const featureBuf = encodeFeatureMessage(tags, geomCommands);
    encodedFeatures.push(featureBuf);
  }

  const encodedKeys = keys.map((k) => encodeStringField(3, k));
  const encodedValues = values.map((v) => encodeValueMessage(v));

  const layerContent = Buffer.concat([
    encodeVarintField(15, 2),
    encodeStringField(1, layerName),
    ...encodedFeatures,
    ...encodedKeys,
    ...encodedValues,
    encodeVarintField(5, 4096),
  ]);

  const layerMsg = encodeLengthDelimited(3, layerContent);
  return layerMsg;
}

function encodePointGeometry(x: number, y: number): number[] {
  const cmdMoveTo = (1 & 0x7) | (1 << 3);
  return [cmdMoveTo, zigzag(x), zigzag(y)];
}

function zigzag(n: number): number {
  return (n << 1) ^ (n >> 31);
}

function encodeFeatureMessage(tags: number[], geometry: number[]): Buffer {
  const parts: Buffer[] = [];

  if (tags.length > 0) {
    const tagBytes = encodePackedVarints(tags);
    parts.push(encodeLengthDelimited(2, tagBytes));
  }

  parts.push(encodeVarintField(3, 1));

  const geomBytes = encodePackedVarints(geometry);
  parts.push(encodeLengthDelimited(4, geomBytes));

  const featureContent = Buffer.concat(parts);
  return encodeLengthDelimited(2, featureContent);
}

function encodeValueMessage(v: string | number): Buffer {
  let inner: Buffer;
  if (typeof v === 'string') {
    inner = encodeStringField(1, v);
  } else if (Number.isInteger(v)) {
    if (v >= 0) {
      inner = encodeVarintField(5, v);
    } else {
      inner = encodeSint64Field(6, v);
    }
  } else {
    inner = encodeDoubleField(3, v);
  }
  return encodeLengthDelimited(4, inner);
}

function encodeVarintField(fieldNumber: number, value: number): Buffer {
  const tag = (fieldNumber << 3) | 0;
  return Buffer.concat([encodeVarint(tag), encodeVarint(value)]);
}

function encodeStringField(fieldNumber: number, value: string): Buffer {
  const tag = (fieldNumber << 3) | 2;
  const strBuf = Buffer.from(value, 'utf-8');
  return Buffer.concat([encodeVarint(tag), encodeVarint(strBuf.length), strBuf]);
}

function encodeLengthDelimited(fieldNumber: number, content: Buffer): Buffer {
  const tag = (fieldNumber << 3) | 2;
  return Buffer.concat([encodeVarint(tag), encodeVarint(content.length), content]);
}

function encodePackedVarints(values: number[]): Buffer {
  const parts = values.map((v) => encodeVarint(v));
  return Buffer.concat(parts);
}

function encodeSint64Field(fieldNumber: number, value: number): Buffer {
  const tag = (fieldNumber << 3) | 0;
  const encoded = (value << 1) ^ (value >> 31);
  return Buffer.concat([encodeVarint(tag), encodeVarint(encoded >>> 0)]);
}

function encodeDoubleField(fieldNumber: number, value: number): Buffer {
  const tag = (fieldNumber << 3) | 1;
  const buf = Buffer.alloc(8);
  buf.writeDoubleLE(value, 0);
  return Buffer.concat([encodeVarint(tag), buf]);
}

function encodeVarint(value: number): Buffer {
  const bytes: number[] = [];
  let v = value >>> 0;
  while (v > 0x7f) {
    bytes.push((v & 0x7f) | 0x80);
    v >>>= 7;
  }
  bytes.push(v & 0x7f);
  return Buffer.from(bytes);
}
