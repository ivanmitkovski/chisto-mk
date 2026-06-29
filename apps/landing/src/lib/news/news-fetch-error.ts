export class NewsFetchError extends Error {
  constructor(message = 'Failed to load news') {
    super(message);
    this.name = 'NewsFetchError';
  }
}
