# Security policy

## Reporting a vulnerability

Email **info@ekohab.mk** with:

- Description of the issue and affected surface (API, admin, landing, mobile)
- Steps to reproduce
- Impact assessment (data exposure, auth bypass, etc.)

Do not open public GitHub issues for security findings.

We aim to acknowledge reports within **5 business days**. There is no public bug bounty program.

## Supported versions

| Surface | Supported |
|---------|-----------|
| Production (`main`) | Yes: api.chisto.mk, admin.chisto.mk, chisto.mk, App Store build |
| `develop` | Best-effort during active development |
| Older releases | Not supported |

## Scope

In scope: Chisto.mk API, admin panel, marketing site, and mobile apps operated by Ekohab.

Out of scope: third-party services (AWS, Firebase, Twilio, etc.). Report those to the respective vendor.
