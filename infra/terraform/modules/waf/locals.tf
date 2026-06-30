locals {
  common_tags = merge(var.tags, {
    Module = "waf"
  })

  # Authenticated multipart upload routes (global prefix /v1 on ALB).
  # CRS/SQLi body inspection false-positives on binary image bytes → HTML 403 at the edge.
  multipart_upload_uri_regexes = [
    "^/v1/reports/upload$",
    "^/v1/reports/[^/]+/media$",
    "^/v1/events/[^/]+/after-images$",
    "^/v1/events/[^/]+/evidence$",
    "^/v1/events/[^/]+/chat/upload$",
    "^/v1/sites/[^/]+/resolutions/upload$",
    "^/v1/auth/me/avatar$",
    "^/v1/auth/avatar$",
  ]

  # Managed CRS rules that inspect request bodies (multipart photos trigger false blocks).
  crs_body_rule_count_overrides = [
    "SizeRestrictions_BODY",
    "CrossSiteScripting_BODY",
    "GenericLFI_BODY",
    "GenericRFI_BODY",
  ]
}
