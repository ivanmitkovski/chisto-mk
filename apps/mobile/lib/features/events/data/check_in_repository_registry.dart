import 'package:chisto_mobile/features/events/data/in_memory_check_in_repository.dart';
import 'package:chisto_mobile/features/events/domain/repositories/check_in_repository.dart';

class CheckInRepositoryRegistry {
  const CheckInRepositoryRegistry._();

  static final CheckInRepository instance = InMemoryCheckInRepository.instance;
}
