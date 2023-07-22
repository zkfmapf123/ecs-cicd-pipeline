export class FPEvnet {
  static broadCastChannel = <T, P>(message: T, fns: P[], callerIdentity: (message: T, fn: P) => void) => {
    for (const fn of fns) callerIdentity(message, fn)
  }
}
