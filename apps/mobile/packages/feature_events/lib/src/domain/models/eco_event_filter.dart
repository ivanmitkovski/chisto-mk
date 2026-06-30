enum EcoEventFilter {
  all('All'),
  upcoming('Upcoming'),
  nearby('Nearby'),
  past('Past'),
  myEvents('My Events');

  const EcoEventFilter(this.label);
  final String label;
}
