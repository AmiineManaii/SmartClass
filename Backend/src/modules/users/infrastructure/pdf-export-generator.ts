import crypto from 'node:crypto';
import PDFDocument from 'pdfkit';
import QRCode from 'qrcode';
import type { UserExportData } from '../domain/export-data.port.js';

export class PdfExportGenerator {
  public async generatePdf(data: UserExportData): Promise<Buffer> {
    const qrBuffer = await this.generateQrCode(data);
    const integrityHash = this.computeIntegrityHash(data);

    return new Promise<Buffer>((resolve, reject) => {
      try {
        const doc = new PDFDocument({
          size: 'A4',
          margin: 36,
          bufferPages: true,
          info: {
            Title: `SmartClass_Export_${data.user.lastName}_${data.user.firstName}`,
            Author: 'SmartClass Academic Platform',
            Subject: 'RGPD Article 20 Data Portability Export',
            Creator: 'SmartClass PDF Engine',
          },
        });

        const buffers: Buffer[] = [];
        doc.on('data', (chunk) => buffers.push(chunk));
        doc.on('end', () => resolve(Buffer.concat(buffers)));
        doc.on('error', (err) => reject(err));

        const pageWidth = 595.28;
        const pageHeight = 841.89;
        const margin = 36;
        const contentWidth = pageWidth - margin * 2; // 523.28

        // ──────────────────────────────────────────────────────────────────
        // 1. Top Decorative Header Banner
        // ──────────────────────────────────────────────────────────────────
        doc.rect(margin, margin, contentWidth, 68).fill('#1E3A8A');

        doc.fillColor('#FFFFFF').fontSize(8).font('Helvetica-Bold');
        doc.text('RÉPUBLIQUE / ENSEIGNEMENT SUPÉRIEUR ET RECHERCHE NUMÉRIQUE', margin + 14, margin + 10, {
          width: contentWidth - 110,
        });

        doc.fillColor('#BFDBFE').fontSize(7.5).font('Helvetica');
        doc.text('SMARTCLASS CAMPUS DIGITALE • ATTESTATION D\'INVENTAIRE & PORTABILITÉ DES DONNÉES (RGPD)', margin + 14, margin + 22, {
          width: contentWidth - 110,
        });

        doc.fillColor('#FFFFFF').fontSize(12).font('Helvetica-Bold');
        doc.text('EXTRAIT DU REGISTRE PERSONNEL & ACADÉMIQUE', margin + 14, margin + 35, {
          width: contentWidth - 110,
        });

        doc.fillColor('#93C5FD').fontSize(7).font('Helvetica');
        const exportDateFormatted = new Date(data.exportedAt).toLocaleString('fr-FR', {
          dateStyle: 'full',
          timeStyle: 'medium',
        });
        doc.text(`Document officiel généré le : ${exportDateFormatted}`, margin + 14, margin + 52);

        // QR Code in header
        doc.image(qrBuffer, margin + contentWidth - 62, margin + 4, {
          width: 58,
          height: 58,
        });

        doc.y = margin + 78;

        // ──────────────────────────────────────────────────────────────────
        // 2. Identity & Account Overview Card
        // ──────────────────────────────────────────────────────────────────
        const cardY = doc.y;
        const cardHeight = 84;
        doc.roundedRect(margin, cardY, contentWidth, cardHeight, 6)
          .fillAndStroke('#F8FAFC', '#CBD5E1');

        const roleLabel = (data.user.role ?? 'UTILISATEUR').toUpperCase();
        let roleBadgeColor = '#2563EB';
        let roleBadgeBg = '#EFF6FF';
        if (roleLabel === 'ADMIN') {
          roleBadgeColor = '#7C3AED';
          roleBadgeBg = '#F5F3FF';
        } else if (roleLabel === 'TEACHER') {
          roleBadgeColor = '#059669';
          roleBadgeBg = '#ECFDF5';
        }

        // Full name + role badge
        doc.fillColor('#0F172A').fontSize(13).font('Helvetica-Bold');
        doc.text(`${data.user.firstName} ${data.user.lastName}`, margin + 14, cardY + 12);

        // Role badge
        const badgeX = margin + 14 + doc.widthOfString(`${data.user.firstName} ${data.user.lastName}`) + 12;
        doc.roundedRect(badgeX, cardY + 10, 80, 16, 4).fillAndStroke(roleBadgeBg, roleBadgeColor);
        doc.fillColor(roleBadgeColor).fontSize(8).font('Helvetica-Bold');
        doc.text(roleLabel, badgeX + 6, cardY + 14, { width: 68, align: 'center' });

        // Metadata Grid inside card
        const col1X = margin + 14;
        const col2X = margin + contentWidth / 2;
        const gridY1 = cardY + 36;
        const gridY2 = cardY + 54;
        const gridY3 = cardY + 68;

        doc.fillColor('#64748B').fontSize(7.5).font('Helvetica');
        doc.text('Adresse email institutionnelle :', col1X, gridY1);
        doc.fillColor('#0F172A').font('Helvetica-Bold').fontSize(8.5);
        doc.text(data.user.email, col1X + 130, gridY1);

        doc.fillColor('#64748B').fontSize(7.5).font('Helvetica');
        doc.text('Identifiant unique (UUID) :', col1X, gridY2);
        doc.fillColor('#0F172A').font('Helvetica-Bold').fontSize(7.5);
        doc.text(data.user.id, col1X + 130, gridY2);

        doc.fillColor('#64748B').fontSize(7.5).font('Helvetica');
        doc.text('Statut du compte :', col2X, gridY1);
        doc.fillColor('#15803D').font('Helvetica-Bold').fontSize(8.5);
        doc.text(`${data.user.status} (Email vérifié: ${data.user.emailVerified ? 'OUI' : 'NON'})`, col2X + 85, gridY1);

        doc.fillColor('#64748B').fontSize(7.5).font('Helvetica');
        doc.text('Authentification 2FA :', col2X, gridY2);
        doc.fillColor(data.user.twoFactorEnabled ? '#15803D' : '#D97706').font('Helvetica-Bold').fontSize(8.5);
        doc.text(data.user.twoFactorEnabled ? 'ACTIVÉE (Sécurisé)' : 'NON ACTIVÉE', col2X + 85, gridY2);

        doc.fillColor('#64748B').fontSize(7.5).font('Helvetica');
        doc.text(`Inscrit le : ${new Date(data.user.createdAt).toLocaleDateString('fr-FR')}`, col1X, gridY3);
        doc.text(`Dernière mise à jour : ${new Date(data.user.updatedAt).toLocaleDateString('fr-FR')}`, col2X, gridY3);

        doc.y = cardY + cardHeight + 14;

        // ──────────────────────────────────────────────────────────────────
        // 3. Admin-Specific Platform Statistics (if Admin)
        // ──────────────────────────────────────────────────────────────────
        if (roleLabel === 'ADMIN' && data.platformStats) {
          this.renderSectionHeader(doc, 'VUE D\'ENSEMBLE DE LA PLATEFORME (STATISTIQUES GLOBALES)', margin, contentWidth);
          const statsY = doc.y;
          const statBoxWidth = (contentWidth - 20) / 3;
          const statBoxHeight = 36;

          const stats = [
            { label: 'Utilisateurs inscrits', val: data.platformStats.totalUsers.toString(), color: '#1E3A8A' },
            { label: 'Étudiants actifs', val: data.platformStats.totalStudents.toString(), color: '#2563EB' },
            { label: 'Enseignants certifiés', val: data.platformStats.totalTeachers.toString(), color: '#059669' },
            { label: 'Administrateurs système', val: data.platformStats.totalAdmins.toString(), color: '#7C3AED' },
            { label: 'Groupes & Promotions', val: data.platformStats.totalGroups.toString(), color: '#D97706' },
            { label: 'Cours & Modules créés', val: data.platformStats.totalCourses.toString(), color: '#0284C7' },
          ];

          stats.forEach((st, idx) => {
            const row = Math.floor(idx / 3);
            const col = idx % 3;
            const bx = margin + col * (statBoxWidth + 10);
            const by = statsY + row * (statBoxHeight + 8);

            doc.roundedRect(bx, by, statBoxWidth, statBoxHeight, 4).fillAndStroke('#F1F5F9', '#E2E8F0');
            doc.fillColor(st.color).fontSize(13).font('Helvetica-Bold');
            doc.text(st.val, bx + 10, by + 6);
            doc.fillColor('#64748B').fontSize(7.5).font('Helvetica');
            doc.text(st.label, bx + 10, by + 22);
          });

          doc.y = statsY + 2 * (statBoxHeight + 8) + 10;
        }

        // ──────────────────────────────────────────────────────────────────
        // 4. Group Memberships Section
        // ──────────────────────────────────────────────────────────────────
        this.renderSectionHeader(doc, 'GROUPES, PROMOTIONS & CLASSES RATTACHÉES', margin, contentWidth);

        if (data.groups.length === 0) {
          doc.fillColor('#64748B').fontSize(8).font('Helvetica-Oblique');
          doc.text('Aucun groupe académique actuellement assigné à ce compte.', margin + 4, doc.y);
          doc.y += 12;
        } else {
          const headers = ['Nom du Groupe / Promotion', 'Niveau', 'Département', 'Année', 'Date d\'adhésion'];
          const colWidths = [150, 80, 140, 70, 83.28];
          const rows = data.groups.map((g) => [
            g.groupName,
            g.level,
            g.department ?? 'Général',
            g.academicYear ?? '-',
            new Date(g.joinedAt).toLocaleDateString('fr-FR'),
          ]);
          this.renderTable(doc, margin, contentWidth, headers, colWidths, rows);
        }

        doc.y += 10;

        // ──────────────────────────────────────────────────────────────────
        // 5. Role-Specific Section: Courses or Teacher Assignments
        // ──────────────────────────────────────────────────────────────────
        if (roleLabel === 'TEACHER' || roleLabel === 'ADMIN') {
          // Teacher assignments
          if (data.assignments && data.assignments.length > 0) {
            this.renderSectionHeader(doc, 'AFFECTATIONS PÉDAGOGIQUES & CHARGES D\'ENSEIGNEMENT', margin, contentWidth);
            const headers = ['Classe / Promotion', 'Discipline / Matière', 'Charge Hebdo', 'Affecté le'];
            const colWidths = [180, 160, 90, 93.28];
            const rows = data.assignments.map((a) => [
              a.groupName,
              a.subject,
              a.weeklyHours ?? 'Selon emploi du temps',
              new Date(a.assignedAt).toLocaleDateString('fr-FR'),
            ]);
            this.renderTable(doc, margin, contentWidth, headers, colWidths, rows);
            doc.y += 10;
          }

          // Authored courses
          if (data.authoredCourses && data.authoredCourses.length > 0) {
            this.renderSectionHeader(doc, 'COURS & RESSOURCES PÉDAGOGIQUES PUBLIÉS', margin, contentWidth);
            const headers = ['Titre du cours', 'Matière', 'Niveau', 'Sections', 'Statut', 'Date de création'];
            const colWidths = [170, 90, 70, 50, 65, 78.28];
            const rows = data.authoredCourses.map((c) => [
              c.title,
              c.subject ?? '-',
              c.level,
              `${c.sectionsCount} chap.`,
              c.status,
              new Date(c.createdAt).toLocaleDateString('fr-FR'),
            ]);
            this.renderTable(doc, margin, contentWidth, headers, colWidths, rows);
            doc.y += 10;
          }
        } else {
          // Student enrolled courses
          if (data.enrolledCourses && data.enrolledCourses.length > 0) {
            this.renderSectionHeader(doc, 'COURS & PROGRAMMES PÉDAGOGIQUES SUIVIS', margin, contentWidth);
            const headers = ['Titre du cours', 'Discipline', 'Niveau', 'Difficulté', 'Sections', 'Statut'];
            const colWidths = [180, 95, 70, 75, 45, 58.28];
            const rows = data.enrolledCourses.map((c) => [
              c.title,
              c.subject ?? 'Tronc Commun',
              c.level,
              c.difficulty,
              `${c.sectionsCount} chap.`,
              c.status,
            ]);
            this.renderTable(doc, margin, contentWidth, headers, colWidths, rows);
            doc.y += 10;
          }
        }

        // ──────────────────────────────────────────────────────────────────
        // 6. Timetable Schedule (if any)
        // ──────────────────────────────────────────────────────────────────
        if (data.timetable.length > 0) {
          if (doc.y > pageHeight - 160) {
            doc.addPage();
          }
          this.renderSectionHeader(doc, 'EMPLOI DU TEMPS & SÉANCES ACADÉMIQUES RÉCENTES', margin, contentWidth);
          const headers = ['Séance / Cours', 'Type', 'Début', 'Fin', 'Salle', 'Groupe'];
          const colWidths = [150, 55, 85, 85, 60, 88.28];
          const rows = data.timetable.slice(0, 10).map((s) => [
            s.title,
            s.kind,
            new Date(s.startsAt).toLocaleString('fr-FR', { dateStyle: 'short', timeStyle: 'short' }),
            new Date(s.endsAt).toLocaleString('fr-FR', { timeStyle: 'short' }),
            s.room ?? 'En ligne',
            s.groupName,
          ]);
          this.renderTable(doc, margin, contentWidth, headers, colWidths, rows);
          doc.y += 10;
        }

        // ──────────────────────────────────────────────────────────────────
        // 7. Security & Activity Audit Log Section (Last 12 entries)
        // ──────────────────────────────────────────────────────────────────
        if (doc.y > pageHeight - 160) {
          doc.addPage();
        }
        this.renderSectionHeader(doc, 'TRAÇABILITÉ DE SÉCURITÉ & AUDIT TRAIL (DERNIÈRES ACTIVITÉS)', margin, contentWidth);

        if (data.recentAuditLogs.length === 0) {
          doc.fillColor('#64748B').fontSize(8).font('Helvetica-Oblique');
          doc.text('Aucune opération d\'audit enregistrée pour ce compte.', margin + 4, doc.y);
          doc.y += 12;
        } else {
          const headers = ['Action enregistrée', 'Type de ressource', 'ID Cible', 'Horodatage'];
          const colWidths = [180, 110, 110, 123.28];
          const rows = data.recentAuditLogs.slice(0, 10).map((l) => [
            l.action,
            l.targetType,
            l.targetId ? l.targetId.slice(0, 14) + '...' : '-',
            new Date(l.createdAt).toLocaleString('fr-FR', { dateStyle: 'short', timeStyle: 'medium' }),
          ]);
          this.renderTable(doc, margin, contentWidth, headers, colWidths, rows);
        }

        // ──────────────────────────────────────────────────────────────────
        // 8. Footer (Page numbers, Cryptographic Hash, Legal RGPD Notice)
        // ──────────────────────────────────────────────────────────────────
        const range = doc.bufferedPageRange();
        for (let i = range.start; i < range.start + range.count; i++) {
          doc.switchToPage(i);

          const footerY = pageHeight - 44;
          doc.rect(margin, footerY - 4, contentWidth, 0.5).fill('#CBD5E1');

          doc.fillColor('#64748B').fontSize(6.5).font('Helvetica');
          doc.text(
            `SMARTCLASS RGPD ART. 20 • Empreinte SHA256: ${integrityHash.slice(0, 32)}... | Émis pour ${data.user.email}`,
            margin,
            footerY + 2,
            { width: contentWidth - 80 },
          );

          doc.text(
            'Document authentifié et scellé électroniquement par la plateforme SmartClass. Valeur probante d\'attestation de données personnelles.',
            margin,
            footerY + 11,
            { width: contentWidth - 80 },
          );

          doc.fillColor('#1E3A8A').font('Helvetica-Bold').fontSize(7.5);
          doc.text(`Page ${i + 1} / ${range.count}`, margin + contentWidth - 70, footerY + 4, {
            width: 70,
            align: 'right',
          });
        }

        doc.end();
      } catch (err) {
        reject(err);
      }
    });
  }

  private renderSectionHeader(
    doc: PDFKit.PDFDocument,
    title: string,
    x: number,
    width: number,
  ): void {
    if (doc.y > 750) {
      doc.addPage();
    }
    const y = doc.y;
    doc.rect(x, y, 3, 12).fill('#1E3A8A');
    doc.fillColor('#0F172A').fontSize(9).font('Helvetica-Bold');
    doc.text(title, x + 8, y + 1);
    doc.y = y + 16;
  }

  private renderTable(
    doc: PDFKit.PDFDocument,
    x: number,
    totalWidth: number,
    headers: string[],
    colWidths: number[],
    rows: string[][],
  ): void {
    const rowHeight = 16;
    let curY = doc.y;

    if (curY + (rows.length + 1) * rowHeight > 780 && rows.length > 5) {
      // Check if we need a new page before drawing
      doc.addPage();
      curY = 40;
    }

    // Header row
    doc.rect(x, curY, totalWidth, rowHeight).fill('#1E293B');
    let curX = x;
    doc.fillColor('#FFFFFF').fontSize(7).font('Helvetica-Bold');
    for (let i = 0; i < headers.length; i++) {
      const headerText = headers[i] ?? '';
      const colWidth = colWidths[i] ?? 50;
      doc.text(headerText, curX + 4, curY + 4, {
        width: colWidth - 8,
        ellipsis: true,
      });
      curX += colWidth;
    }

    curY += rowHeight;

    // Body rows
    for (let r = 0; r < rows.length; r++) {
      if (curY > 780) {
        doc.addPage();
        curY = 40;
      }

      const isEven = r % 2 === 0;
      doc.rect(x, curY, totalWidth, rowHeight).fill(isEven ? '#FFFFFF' : '#F8FAFC');
      doc.rect(x, curY, totalWidth, rowHeight).stroke('#E2E8F0');

      curX = x;
      doc.fillColor('#334155').fontSize(7).font('Helvetica');
      const row = rows[r] ?? [];
      for (let c = 0; c < row.length; c++) {
        const cellText = row[c] ?? '';
        const colWidth = colWidths[c] ?? 50;
        doc.text(cellText, curX + 4, curY + 4, {
          width: colWidth - 8,
          ellipsis: true,
        });
        curX += colWidth;
      }
      curY += rowHeight;
    }

    doc.y = curY + 4;
  }

  private async generateQrCode(data: UserExportData): Promise<Buffer> {
    const payload = JSON.stringify({
      issuer: 'SmartClass Campus Numérique',
      rgpdArt: 20,
      userId: data.user.id,
      email: data.user.email,
      role: data.user.role,
      exportedAt: data.exportedAt,
    });

    return QRCode.toBuffer(payload, {
      width: 120,
      margin: 1,
      color: {
        dark: '#1E3A8A',
        light: '#FFFFFF',
      },
    });
  }

  private computeIntegrityHash(data: UserExportData): string {
    const normalized = JSON.stringify({
      user: data.user,
      groups: data.groups,
      assignments: data.assignments,
      authoredCourses: data.authoredCourses,
      enrolledCourses: data.enrolledCourses,
      exportedAt: data.exportedAt,
    });

    return crypto.createHash('sha256').update(normalized).digest('hex');
  }
}
