-- Legacy migration (ordering fix): runs before event_chat_v1_enhancements alphabetically
-- but requires EventChatMessageType + EventChatAttachment from later migrations.
-- Enum extensions and attachment columns are applied in:
--   20260408120000_event_chat_v1_enhancements (creates enum)
--   20260409120000_chat_attachments_location (IMAGE, LOCATION + attachment table)
--   20260409120001_chat_media_types (VIDEO, AUDIO, FILE + duration columns)

SELECT 1;
