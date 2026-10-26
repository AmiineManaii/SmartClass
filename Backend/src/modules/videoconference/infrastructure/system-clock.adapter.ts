import type { ClockPort } from '../domain/clock.port.js';

export class SystemClockAdapter implements ClockPort {
  public now(): Date {
    return new Date();
  }
}
