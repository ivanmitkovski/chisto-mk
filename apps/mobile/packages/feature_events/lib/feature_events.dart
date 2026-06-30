/// Events feature — cleanup discovery, detail, chat, organizer tooling.
library;

export 'src/application/events_providers.dart';
export 'src/data/chat/chat_client_message_id.dart';
export 'src/data/event_site_resolver.dart';
export 'src/domain/models/eco_event.dart';
export 'src/domain/models/eco_event_enums.dart';
export 'src/domain/repositories/events_repository.dart';
export 'src/presentation/navigation/events_navigation.dart';
export 'src/presentation/navigation/events_routes.dart';
export 'src/presentation/screens/events_feed_screen.dart';
export 'src/presentation/utils/events_localized_strings.dart';

const String featureEventsPackageVersion = '0.0.1';
