import { HTMLAttributes } from 'react';
import styles from './card.module.css';

type CardPadding = 'sm' | 'md';
type CardElement = 'section' | 'article' | 'div';

export type CardProps = HTMLAttributes<HTMLElement> & {
  as?: CardElement;
  padding?: CardPadding;
};

const paddingClassByName: Record<CardPadding, string> = {
  sm: styles.paddingSm,
  md: styles.paddingMd,
};

export function Card({ as = 'section', padding = 'md', className, children, ...rest }: CardProps) {
  const Component = as;
  const resolvedClassName = [styles.card, paddingClassByName[padding], className ?? ''].join(' ').trim();

  return (
    <Component {...rest} className={resolvedClassName}>
      {children}
    </Component>
  );
}
