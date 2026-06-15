import { Fragment, type ReactNode } from "react";

const URL_RE = /(https?:\/\/[^\s<>"{}|\\^`[\]]+)/gi;

function createLinkify(linkKey: { n: number }, linkClassName: string) {
  return function linkify(text: string): ReactNode[] {
    const parts: ReactNode[] = [];
    let last = 0;
    let m: RegExpExecArray | null;
    const re = new RegExp(URL_RE.source, URL_RE.flags);
    while ((m = re.exec(text)) !== null) {
      if (m.index > last) {
        parts.push(text.slice(last, m.index));
      }
      const href = m[1] ?? m[0];
      let display = href;
      let trailing = "";
      while (/[),.;:!?'"\]]$/u.test(display) && display.length > 8) {
        trailing = display.slice(-1) + trailing;
        display = display.slice(0, -1);
      }
      parts.push(
        <a
          key={`L${linkKey.n++}`}
          href={display}
          target="_blank"
          rel="noopener noreferrer"
          className={linkClassName}
        >
          {display}
        </a>,
      );
      if (trailing) parts.push(trailing);
      last = m.index + m[0].length;
    }
    if (last < text.length) {
      parts.push(text.slice(last));
    }
    return parts.length ? parts : [text];
  };
}

const BULLET_LINE = /^[\s]*[•\-*·]\s+(.+)$/;

function isSubsectionHeadingLine(line: string): boolean {
  const t = line.trim();
  if (t.length >= 120) return false;
  if (t.endsWith(":") || t.endsWith(".")) return false;
  return /^\d+\.\d+(\.\d+)*\s+\S/.test(t);
}

function isImplicitListLines(lines: string[]): boolean {
  if (lines.length < 3) return false;
  if (lines.some((l) => BULLET_LINE.test(l))) return false;
  const maxLen = 240;
  if (!lines.every((l) => l.length <= maxLen)) return false;
  return true;
}

const defaultLinkClass =
  "font-medium text-primary underline decoration-primary/40 underline-offset-2 transition-colors hover:decoration-primary";

/**
 * Renders legal copy: paragraphs, bullet lists (• or -), implicit multi-line lists,
 * subsection lines (e.g. 3.1.1 Title) as headings, and autolinked URLs.
 */
export function LegalRichBody({
  body,
  className,
  linkClassName = defaultLinkClass,
}: {
  body: string;
  className?: string;
  /** Classes for auto-linked URLs (e.g. amber tones inside the notice callout). */
  linkClassName?: string;
}) {
  const linkKey = { n: 0 };
  const linkify = createLinkify(linkKey, linkClassName);
  const blocks = body.split(/\n\n+/);
  const nodes: ReactNode[] = [];
  let key = 0;

  for (const rawBlock of blocks) {
    const block = rawBlock.trim();
    if (!block) continue;

    const lines = block.split("\n").map((l) => l.trimEnd());
    const nonEmpty = lines.map((l) => l.trim()).filter(Boolean);

    if (nonEmpty.length === 0) continue;

    // All-bullet block
    if (nonEmpty.length >= 2 && nonEmpty.every((l) => BULLET_LINE.test(l))) {
      nodes.push(
        <ul
          key={key++}
          className="space-y-2.5 border-l-2 border-primary/25 py-1 pl-4 [contain:inline-size]"
        >
          {nonEmpty.map((line, i) => {
            const m = line.match(BULLET_LINE);
            const inner = m?.[1] ?? line.replace(/^[•\-*·]\s+/, "");
            return (
              <li key={i} className="ps-1 text-gray-700 [text-wrap:pretty]">
                <span className="text-primary">•</span>{" "}
                <span className="align-top">{linkify(inner)}</span>
              </li>
            );
          })}
        </ul>,
      );
      continue;
    }

    // Implicit list (e.g. law names, feature lines)
    if (isImplicitListLines(nonEmpty)) {
      nodes.push(
        <ul
          key={key++}
          className="list-outside space-y-1.5 py-1 ps-5 [text-wrap:pretty] marker:text-gray-400"
        >
          {nonEmpty.map((line, i) => (
            <li key={i} className="ps-1 leading-relaxed text-gray-700">
              {linkify(line)}
            </li>
          ))}
        </ul>,
      );
      continue;
    }

    // Subsection heading + remainder in one block
    if (nonEmpty.length >= 2 && isSubsectionHeadingLine(nonEmpty[0]!)) {
      const [head, ...rest] = nonEmpty;
      const restBullets = rest.length >= 2 && rest.every((l) => BULLET_LINE.test(l));
      const restImplicit = isImplicitListLines(rest);

      nodes.push(
        <h3
          key={key++}
          className="scroll-mt-24 text-base font-semibold tracking-tight text-gray-900 md:text-[1.0625rem]"
        >
          {linkify(head)}
        </h3>,
      );

      if (restBullets) {
        nodes.push(
          <ul
            key={key++}
            className="space-y-2 border-l-2 border-primary/25 py-1 pl-4 [contain:inline-size]"
          >
            {rest.map((line, i) => {
              const m = line.match(BULLET_LINE);
              const inner = m?.[1] ?? line.replace(/^[•\-*·]\s+/, "");
              return (
                <li key={i} className="ps-1 text-gray-700 [text-wrap:pretty]">
                  <span className="text-primary">•</span>{" "}
                  <span className="align-top">{linkify(inner)}</span>
                </li>
              );
            })}
          </ul>,
        );
      } else if (restImplicit) {
        nodes.push(
          <ul
            key={key++}
            className="list-outside space-y-1.5 py-1 ps-5 marker:text-gray-400 [text-wrap:pretty]"
          >
            {rest.map((line, i) => (
              <li key={i} className="ps-1 leading-relaxed text-gray-700">
                {linkify(line)}
              </li>
            ))}
          </ul>,
        );
      } else {
        nodes.push(
          <p key={key++} className="leading-relaxed text-gray-700 [text-wrap:pretty]">
            {rest.map((line, i) => (
              <Fragment key={i}>
                {i > 0 ? <br /> : null}
                {linkify(line)}
              </Fragment>
            ))}
          </p>,
        );
      }
      continue;
    }

    // Single-line subsection title only
    if (nonEmpty.length === 1 && isSubsectionHeadingLine(nonEmpty[0]!)) {
      nodes.push(
        <h3
          key={key++}
          className="scroll-mt-24 text-base font-semibold tracking-tight text-gray-900 md:text-[1.0625rem]"
        >
          {linkify(nonEmpty[0]!)}
        </h3>,
      );
      continue;
    }

    // Default: one visual paragraph; single \n inside block → <br />
    const paraLines = lines.map((l) => l.trim()).filter(Boolean);
    if (paraLines.length === 0) continue;
    nodes.push(
      <p key={key++} className="leading-relaxed text-gray-700 [text-wrap:pretty]">
        {paraLines.map((t, i) => (
          <Fragment key={i}>
            {i > 0 ? <br /> : null}
            {linkify(t)}
          </Fragment>
        ))}
      </p>,
    );
  }

  return <div className={className ?? "flex flex-col gap-4"}>{nodes}</div>;
}
