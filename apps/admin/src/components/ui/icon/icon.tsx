import {
  LucideIcon,
  House,
  FileText,
  Settings,
  Send,
  ClipboardX,
  Search,
  Bell,
  User,
  MapPin,
  Check,
  Trash2,
  ChevronLeft,
  ChevronRight,
  ChevronUp,
  ChevronDown,
  ArrowUpDown,
  Menu,
  X,
  PanelLeftClose,
  PanelLeftOpen,
} from 'lucide-react';

export type IconName =
  | 'home'
  | 'document-text'
  | 'setting'
  | 'document-forward'
  | 'clipboard-close'
  | 'magnifying-glass'
  | 'notification-bing'
  | 'user'
  | 'location'
  | 'check'
  | 'trash'
  | 'chevron-left'
  | 'chevron-right'
  | 'chevron-up'
  | 'chevron-down'
  | 'arrow-up-down'
  | 'menu'
  | 'x'
  | 'panel-left-close'
  | 'panel-left-open';

const iconByName: Record<IconName, LucideIcon> = {
  home: House,
  'document-text': FileText,
  setting: Settings,
  'document-forward': Send,
  'clipboard-close': ClipboardX,
  'magnifying-glass': Search,
  'notification-bing': Bell,
  user: User,
  location: MapPin,
  check: Check,
  trash: Trash2,
  'chevron-left': ChevronLeft,
  'chevron-right': ChevronRight,
  'chevron-up': ChevronUp,
  'chevron-down': ChevronDown,
  'arrow-up-down': ArrowUpDown,
  menu: Menu,
  x: X,
  'panel-left-close': PanelLeftClose,
  'panel-left-open': PanelLeftOpen,
};

type IconProps = {
  name: IconName;
  size?: number;
  className?: string;
  strokeWidth?: number;
};

export function Icon({ name, size = 18, className, strokeWidth = 2 }: IconProps) {
  const IconComponent = iconByName[name];

  return <IconComponent size={size} className={className} strokeWidth={strokeWidth} aria-hidden />;
}
