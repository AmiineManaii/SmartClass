export type FraudSeverity = 'LOW' | 'MEDIUM' | 'HIGH';

export type FraudStatus = 'UNTREATED' | 'IN_PROGRESS' | 'CLOSED';

export interface FraudStudent {
  id: string;
  name: string;
  code: string | null;
}

export interface FraudClass {
  id: string;
  name: string;
}

export interface FraudReportView {
  id: string;
  title: string;
  context: string | null;
  severity: FraudSeverity;
  status: FraudStatus;
  student: FraudStudent | null;
  classGroup: FraudClass | null;
  findings: string[];
  reason: string | null;
  resolution: string | null;
  occurredAt: Date;
  createdAt: Date;
}

export interface FraudSummary {
  untreated: number;
  inProgress: number;
  closed: number;
  resolvedThisMonth: number;
}
