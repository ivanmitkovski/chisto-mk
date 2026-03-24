import {
  LucideIcon,
  House,
  FileText,
  FileStack,
  Settings,
  Send,
  ClipboardX,
  Search,
  Bell,
  User,
  Map,
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
  LogOut,
  AlertTriangle,
  Calendar,
  Users,
  ScrollText,
  Shield,
  RotateCw,
  Info,
  Copy,
  ExternalLink,
  Plus,
  Minus,
} from 'lucide-react';

export type IconName =
  | 'home'
  | 'document-text'
  | 'document-duplicate'
  | 'setting'
  | 'document-forward'
  | 'clipboard-close'
  | 'magnifying-glass'
  | 'notification-bing'
  | 'user'
  | 'location'
  | 'map'
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
  | 'panel-left-open'
  | 'log-out'
  | 'alert-triangle'
  | 'calendar'
  | 'users'
  | 'scroll-text'
  | 'shield'
  | 'refresh'
  | 'info'
  | 'copy'
  | 'external-link'
  | 'plus'
  | 'minus';

const iconByName: Record<IconName, LucideIcon> = {
  home: House,
  'document-text': FileText,
  'document-duplicate': FileStack,
  setting: Settings,
  'document-forward': Send,
  'clipboard-close': ClipboardX,
  'magnifying-glass': Search,
  'notification-bing': Bell,
  user: User,
  location: MapPin,
  map: Map,
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
  'log-out': LogOut,
  'alert-triangle': AlertTriangle,
  calendar: Calendar,
  users: Users,
  'scroll-text': ScrollText,
  shield: Shield,
  refresh: RotateCw,
  info: Info,
  copy: Copy,
  'external-link': ExternalLink,
  plus: Plus,
  minus: Minus,
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
