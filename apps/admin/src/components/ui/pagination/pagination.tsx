'use client';

import { ChevronLeft, ChevronRight } from 'lucide-react';
import styles from './pagination.module.css';

type PaginationProps = {
  totalPages: number;
  currentPage: number;
  onPageChange: (page: number) => void;
  className?: string;
};

type PageItem = number | 'ellipsis-left' | 'ellipsis-right';

function pageItems(totalPages: number, currentPage: number): PageItem[] {
  if (totalPages <= 7) {
    return Array.from({ length: totalPages }, (_, index) => index + 1);
  }

  if (currentPage <= 3) {
    return [1, 2, 3, 4, 'ellipsis-right', totalPages];
  }

  if (currentPage >= totalPages - 2) {
    return [1, 'ellipsis-left', totalPages - 3, totalPages - 2, totalPages - 1, totalPages];
  }

  return [1, 'ellipsis-left', currentPage - 1, currentPage, currentPage + 1, 'ellipsis-right', totalPages];
}

export function Pagination({ totalPages, currentPage, onPageChange, className }: PaginationProps) {
  const rootClassName = [styles.root, className ?? ''].join(' ').trim();
  const items = pageItems(totalPages, currentPage);

  return (
    <nav className={rootClassName} aria-label="Pagination">
      <button
        type="button"
        className={styles.item}
        onClick={() => onPageChange(currentPage - 1)}
        disabled={currentPage <= 1}
        aria-label="Previous page"
      >
        <ChevronLeft size={14} />
      </button>

      {items.map((item, index) => {
        if (item === 'ellipsis-left' || item === 'ellipsis-right') {
          return (
            <span key={`${item}-${index}`} className={`${styles.item} ${styles.ellipsis}`} aria-hidden>
              ...
            </span>
          );
        }

        return (
          <button
            key={item}
            type="button"
            className={`${styles.item} ${item === currentPage ? styles.active : ''}`}
            onClick={() => onPageChange(item)}
            aria-current={item === currentPage ? 'page' : undefined}
          >
            {item}
          </button>
        );
      })}

      <button
        type="button"
        className={styles.item}
        onClick={() => onPageChange(currentPage + 1)}
        disabled={currentPage >= totalPages}
        aria-label="Next page"
      >
        <ChevronRight size={14} />
      </button>
    </nav>
  );
}
