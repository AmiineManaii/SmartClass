export interface AdminOverviewCounts {
  total: number;
  newThisMonth: number;
}

export interface AdminOverviewTeachers extends AdminOverviewCounts {
  /** Percentage of ACTIVE teacher accounts (0-100). */
  activePct: number;
}

export interface AdminOverviewFrauds {
  untreated: number;
  inProgress: number;
  closed: number;
  resolvedThisMonth: number;
}

export interface AdminOverview {
  students: AdminOverviewCounts;
  teachers: AdminOverviewTeachers;
  classes: AdminOverviewCounts;
  /** Total student enrolments across all classes. */
  enrollments: number;
  frauds: AdminOverviewFrauds;
}
