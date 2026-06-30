/// User profile, avatar, points history, and weekly rankings.
library;

export 'src/domain/models/profile_user.dart';
export 'src/domain/repositories/profile_repository.dart';
export 'src/presentation/navigation/profile_actions_handler.dart';
export 'src/presentation/providers/profile_avatar_notifier.dart';
export 'src/presentation/providers/profile_providers.dart';
export 'src/presentation/screens/profile_screen.dart';
export 'src/presentation/widgets/profile_primary_action_bar.dart';

const String featureProfilePackageVersion = '0.0.1';
