/**
 * Prefer IPv4 for outbound HTTPS (Vercel → AWS ALB). Import only from server layouts.
 */
import dns from 'dns';

dns.setDefaultResultOrder('ipv4first');
