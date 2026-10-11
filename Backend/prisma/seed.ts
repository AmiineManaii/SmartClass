/**
 * Demo seed for admin screens (idempotent: exits early when present).
 *
 * Creates: 1 ADMIN, 2 teachers, 3 students, 1 class with members and one
 * teacher assignment, a week of timetable slots and 2 fraud reports.
 * Run with: npm run db:seed  (uses tsx, no new dependency)
 */
import argon2 from 'argon2';
import pg from 'pg';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const prisma = new PrismaClient({ adapter: new PrismaPg(pool) });

const at = (base: Date, dayOffset: number, hour: number, minute: number): Date => {
  const date = new Date(base.getTime() + dayOffset * 24 * 60 * 60 * 1000);
  date.setUTCHours(hour, minute, 0, 0);
  return date;
};

const mondayOfCurrentWeek = (): Date => {
  const now = new Date();
  const monday = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  const shift = (monday.getUTCDay() + 6) % 7;
  monday.setUTCDate(monday.getUTCDate() - shift);
  return monday;
};

const main = async (): Promise<void> => {
  const existingAdmin = await prisma.user.findFirst({ where: { role: 'ADMIN' } });
  if (existingAdmin) {
    console.log(`Seed skipped: ADMIN ${existingAdmin.email} already exists.`);
    return;
  }

  const passwordHash = await argon2.hash('Admin123!', { type: argon2.argon2id });

  const admin = await prisma.user.create({
    data: {
      email: 'admin@smartclass.local',
      passwordHash,
      firstName: 'Admin',
      lastName: 'SmartClass',
      role: 'ADMIN',
      emailVerified: true,
      onboardingCompleted: true,
    },
  });

  const teacherHash = await argon2.hash('Teacher123!', { type: argon2.argon2id });
  const teachers = await Promise.all(
    [
      { email: 'amine.mansouri@univ-smartclass.fr', firstName: 'Amine', lastName: 'Mansouri' },
      { email: 'laurent.valette@univ-smartclass.fr', firstName: 'Laurent', lastName: 'Valette' },
    ].map((teacher) =>
      prisma.user.create({
        data: {
          ...teacher,
          passwordHash: teacherHash,
          role: 'TEACHER',
          emailVerified: true,
          onboardingCompleted: true,
        },
      }),
    ),
  );

  const studentHash = await argon2.hash('Student123!', { type: argon2.argon2id });
  const students = await Promise.all(
    [
      { email: 'salma.idrissi@univ-smartclass.fr', firstName: 'Salma', lastName: 'Idrissi' },
      { email: 'karim.bennani@univ-smartclass.fr', firstName: 'Karim', lastName: 'Bennani' },
      { email: 'yasmine.belkacem@univ-smartclass.fr', firstName: 'Yasmine', lastName: 'Belkacem' },
    ].map((student) =>
      prisma.user.create({
        data: {
          ...student,
          passwordHash: studentHash,
          role: 'STUDENT',
          emailVerified: true,
          onboardingCompleted: true,
        },
      }),
    ),
  );

  const group = await prisma.classGroup.create({
    data: {
      name: 'Informatique 3A',
      level: 'LICENCE',
      department: 'Informatique',
      capacity: 35,
      description: 'Promotion Licence 3 Informatique 2024-2025',
      status: 'PUBLISHED',
      referentId: teachers[0]?.id,
    },
  });

  await prisma.groupMember.createMany({
    data: students.map((student) => ({ classGroupId: group.id, userId: student.id })),
  });

  if (teachers[0]) {
    await prisma.teacherAssignment.create({
      data: {
        classGroupId: group.id,
        teacherId: teachers[0].id,
        subject: 'Développement Mobile & Cross-Platform',
        weeklyHours: '4h/semaine',
      },
    });
  }

  const monday = mondayOfCurrentWeek();
  await prisma.timetableSlot.createMany({
    data: [
      {
        classGroupId: group.id,
        title: 'Développement Mobile & Cross-Platform',
        subtitle: 'Architecture MVVM & cycle de vie des interfaces tactiles',
        kind: 'CM',
        startsAt: at(monday, 0, 8, 0),
        endsAt: at(monday, 0, 10, 0),
        teacherId: teachers[0]?.id,
        room: 'Salle 102',
        statusNotes: ['Confirmé • Appel non clôturé'],
      },
      {
        classGroupId: group.id,
        title: 'Bases de Données Réparties',
        subtitle: 'Partitionnement horizontal & clusters PostgreSQL',
        kind: 'TP',
        startsAt: at(monday, 0, 10, 15),
        endsAt: at(monday, 0, 12, 15),
        room: 'Salle 204',
        statusNotes: ['Séance validée & matériel réservé', 'Groupe complet'],
      },
    ],
  });

  await prisma.fraudReport.create({
    data: {
      title: 'Suspicion de Fraude - QCM Mathématiques',
      context: 'Examen Partiel Semestre 6 • Durée 60 min',
      severity: 'HIGH',
      status: 'UNTREATED',
      studentId: students[0]?.id,
      studentName: 'Salma M.',
      studentCode: '#ETU-8921',
      classGroupId: group.id,
      className: 'Licence 3 Informatique 3A',
      findings: [
        'Perte de focus écran x5 & tentative copier-coller (Presse-papier)',
        'Détection IA webcam : regard hors écran prolongé (> 45s)',
      ],
      occurredAt: new Date(),
    },
  });

  console.log(`Seed done: admin=${admin.email} group=${group.name}`);
};

main()
  .catch((error: unknown) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(() => {
    void prisma.$disconnect().finally(() => {
      void pool.end();
    });
  });
