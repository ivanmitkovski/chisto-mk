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
  CircleAlert,
  CircleCheck,
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
  Megaphone,
  Trophy,
  SlidersHorizontal,
  MailX,
  Webhook,
  UserCog,
  Download,
  Newspaper,
  Heading2,
  List,
  Image,
  Images,
  Video,
  Code2,
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
  | 'alert-circle'
  | 'check-circle'
  | 'calendar'
  | 'users'
  | 'scroll-text'
  | 'shield'
  | 'refresh'
  | 'info'
  | 'copy'
  | 'external-link'
  | 'plus'
  | 'minus'
  | 'megaphone'
  | 'trophy'
  | 'sliders'
  | 'mail-x'
  | 'webhook'
  | 'user-cog'
  | 'download'
  | 'newspaper'
  | 'heading'
  | 'list'
  | 'image'
  | 'gallery'
  | 'video'
  | 'code';

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
  'alert-circle': CircleAlert,
  'check-circle': CircleCheck,
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
  megaphone: Megaphone,
  trophy: Trophy,
  sliders: SlidersHorizontal,
  'mail-x': MailX,
  webhook: Webhook,
  'user-cog': UserCog,
  download: Download,
  newspaper: Newspaper,
  heading: Heading2,
  list: List,
  image: Image,
  gallery: Images,
  video: Video,
  code: Code2,
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
