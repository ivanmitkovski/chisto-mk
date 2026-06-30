let impactReceiptFetchTotal = 0;
let prismaP1008Total = 0;

export function recordImpactReceiptFetch(): void {
  impactReceiptFetchTotal += 1;
}

export function recordPrismaP1008Response(): void {
  prismaP1008Total += 1;
}

export function snapshot() {
  return {
    impactReceiptFetchTotal,
    prismaP1008Total,
  };
}

export function getPrismaP1008Total(): number {
  return prismaP1008Total;
}
