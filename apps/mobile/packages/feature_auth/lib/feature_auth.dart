/// Auth feature — domain, data, application, presentation.
library;

export 'src/application/initial_route_controller.dart';
export 'src/application/splash_session_controller.dart';
export 'src/data/api_auth_repository.dart';
export 'src/data/user_home_location_store.dart';
export 'src/domain/models/auth_session_dtos.dart';
export 'src/domain/models/register_result.dart';
export 'src/domain/ports/auth_push_port.dart';
export 'src/domain/refresh_outcome.dart';
export 'src/domain/repositories/auth_repository.dart';
export 'src/presentation/constants/auth_error_messages.dart';
export 'src/presentation/eula_acceptance_flow.dart';
export 'src/presentation/utils/auth_guard_ui.dart';

const String featureAuthPackageVersion = '0.0.1';
