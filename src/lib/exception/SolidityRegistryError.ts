export class SolidityRegistryError extends Error {
  public constructor(error: unknown) {
    const message = error instanceof Error ? error.message : String(error);
    super(message);
    this.name = 'SolidityRegistryError';

    if (error instanceof Error) {
      this.stack = (this.stack ?? '') + '\n originalErrorStack: ' + (error.stack ?? '');
    }

    Object.setPrototypeOf(this, SolidityRegistryError.prototype);
  }
}

