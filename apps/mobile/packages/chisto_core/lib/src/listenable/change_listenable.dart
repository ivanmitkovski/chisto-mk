/// Pure-Dart listener contract (Flutter-free alternative to [Listenable]).
abstract class ChangeListenable {
  void addListener(void Function() listener);

  void removeListener(void Function() listener);
}
