/**
 * Merges duplicate EVENT_CHAT inbox rows per (userId, groupKey).
 * Keeps the newest row (by createdAt), sums messageCount, archives duplicates.
 *
 * Usage: npm run merge:event-chat-inbox
 */
import { NotificationType, PrismaClient } from '../src/generated/prisma';

const prisma = new PrismaClient();

function parseMessageCount(data: unknown): number {
  if (data == null || typeof data !== 'object' || Array.isArray(data)) {
    return 1;
  }
  const raw = (data as Record<string, unknown>)['messageCount'];
  if (typeof raw === 'number' && Number.isFinite(raw)) {
    return Math.max(1, Math.floor(raw));
  }
  if (typeof raw === 'string') {
    const parsed = Number(raw);
    if (Number.isFinite(parsed)) {
      return Math.max(1, Math.floor(parsed));
    }
  }
  return 1;
}

async function main() {
  const rows = await prisma.userNotification.findMany({
    where: {
      type: NotificationType.EVENT_CHAT,
      archivedAt: null,
      groupKey: { not: null },
    },
    orderBy: { createdAt: 'desc' },
    select: {
      id: true,
      userId: true,
      groupKey: true,
      title: true,
      body: true,
      threadKey: true,
      data: true,
      createdAt: true,
      isRead: true,
    },
  });

  const buckets = new Map<string, typeof rows>();
  for (const row of rows) {
    const key = `${row.userId}::${row.groupKey}`;
    const list = buckets.get(key) ?? [];
    list.push(row);
    buckets.set(key, list);
  }

  let mergedGroups = 0;
  let archivedRows = 0;

  for (const [, groupRows] of buckets) {
    if (groupRows.length <= 1) {
      continue;
    }
    const keeper = groupRows[0];
    const duplicates = groupRows.slice(1);
    let totalCount = parseMessageCount(keeper.data);
    for (const dup of duplicates) {
      totalCount += parseMessageCount(dup.data);
    }

    const keeperData =
      keeper.data != null && typeof keeper.data === 'object' && !Array.isArray(keeper.data)
        ? { ...(keeper.data as Record<string, unknown>) }
        : {};
    keeperData['messageCount'] = totalCount;

    await prisma.userNotification.update({
      where: { id: keeper.id },
      data: {
        data: keeperData,
        isRead: groupRows.every((r) => r.isRead),
      },
    });

    const dupIds = duplicates.map((d) => d.id);
    if (dupIds.length > 0) {
      await prisma.userNotification.updateMany({
        where: { id: { in: dupIds } },
        data: { archivedAt: new Date() },
      });
    }

    mergedGroups += 1;
    archivedRows += dupIds.length;
  }

  console.log(
    `merge-event-chat-inbox: ${mergedGroups} groups merged, ${archivedRows} duplicate rows archived`,
  );
}

main()
  .catch((err: unknown) => {
    console.error(err);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
