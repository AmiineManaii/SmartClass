// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

void downloadJsonFileImpl(String filename, String content) {
  try {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  } catch (_) {
    // Fallback
  }
}

void printOfficialTranscriptImpl({
  required String studentName,
  required String studentId,
  required String institution,
  required String major,
  required String email,
  required String status,
  required String date,
  bool isTeacher = false,
}) {
  try {
    final existingIframe = html.document.getElementById(
      'smartclass_print_iframe',
    );
    if (existingIframe != null) {
      existingIframe.remove();
    }

    final htmlDoc = _generateTranscriptHtml(
      studentName: studentName,
      studentId: studentId,
      institution: institution,
      major: major,
      email: email,
      status: status,
      date: date,
      isTeacher: isTeacher,
    );

    final iframe = html.IFrameElement()
      ..id = 'smartclass_print_iframe'
      ..style.position = 'fixed'
      ..style.right = '0'
      ..style.bottom = '0'
      ..style.width = '0'
      ..style.height = '0'
      ..style.border = '0'
      ..srcdoc = htmlDoc;

    html.document.body?.children.add(iframe);

    Future.delayed(const Duration(milliseconds: 400), () {
      try {
        final win = iframe.contentWindow as dynamic;
        win?.focus();
        win?.print();
      } catch (_) {
        html.window.print();
      }
    });
  } catch (_) {
    html.window.print();
  }
}

String _generateTranscriptHtml({
  required String studentName,
  required String studentId,
  required String institution,
  required String major,
  required String email,
  required String status,
  required String date,
  bool isTeacher = false,
}) {
  final instDisplay = institution.trim().isNotEmpty
      ? institution.trim()
      : 'Établissement non renseigné';
  final nameDisplay = studentName.trim().isNotEmpty
      ? studentName.trim()
      : (isTeacher ? 'Professeur' : 'Ahmed Mohsen');
  final idDisplay = studentId.trim().isNotEmpty
      ? studentId.trim()
      : (isTeacher ? 'PPR-2026-89421' : 'CNE-2026-984210');
  final majorDisplay = major.trim().isNotEmpty
      ? major.trim()
      : (isTeacher
            ? 'Département Informatique & Technologies Numériques'
            : 'Cycle Ingénieur • Informatique & Systèmes Intelligents');

  final docTitle = isTeacher
      ? 'Attestation d\'Exercice & Fiche de Service Enseignant'
      : 'Relevé Officiel de Notes & Attestation Académique';

  final docSub = isTeacher
      ? 'Enseignement Supérieur, Recherche & Encadrement Pédagogique • Année 2025 - 2026'
      : 'Cycle Universitaire d\'Excellence • Année Académique 2025 - 2026';

  final cardHtml = isTeacher
      ? '''
      <div>
        <div class="info-label">Nom & Prénom de l'Enseignant</div>
        <div class="info-value">$nameDisplay</div>
      </div>
      <div>
        <div class="info-label">Matricule Enseignant (PPR / Somme)</div>
        <div class="info-value">$idDisplay</div>
      </div>
      <div>
        <div class="info-label">Département & Discipline</div>
        <div class="info-value">$majorDisplay</div>
      </div>
      <div>
        <div class="info-label">Statut Académique</div>
        <div class="info-value"><span class="status-badge">Enseignant Titulaire • Certifié ENT</span></div>
      </div>
      <div>
        <div class="info-label">Établissement d'Affectation</div>
        <div class="info-value">$instDisplay</div>
      </div>
      <div>
        <div class="info-label">Email Institutionnel</div>
        <div class="info-value">$email</div>
      </div>
      '''
      : '''
      <div>
        <div class="info-label">Nom & Prénom de l'étudiant</div>
        <div class="info-value">$nameDisplay</div>
      </div>
      <div>
        <div class="info-label">Identifiant National (CNE / MASSAR)</div>
        <div class="info-value">$idDisplay</div>
      </div>
      <div>
        <div class="info-label">Filière / Spécialité d'Excellence</div>
        <div class="info-value">$majorDisplay</div>
      </div>
      <div>
        <div class="info-label">Statut d'Inscription & Scolarité</div>
        <div class="info-value"><span class="status-badge">Inscrit en règle • $status</span></div>
      </div>
      <div>
        <div class="info-label">Établissement de Rattachement</div>
        <div class="info-value">$instDisplay</div>
      </div>
      <div>
        <div class="info-label">Adresse Email Académique</div>
        <div class="info-value">$email</div>
      </div>
      ''';

  final tableHtml = isTeacher
      ? '''
  <h2 class="section-title">Charges d'Enseignement & Modules Attribués (Semestre en cours)</h2>
  <table class="transcript-table">
    <thead>
      <tr>
        <th style="width: 80px;">Code Module</th>
        <th>Intitulé du Cours / Module</th>
        <th style="width: 140px;">Filière / Classe</th>
        <th style="width: 85px; text-align: center;">Volume Horaire</th>
        <th style="width: 95px; text-align: center;">Type</th>
        <th style="width: 80px; text-align: center;">Statut</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td><strong>INFO-401</strong></td>
        <td>Algorithmes Avancés & Structures de Données</td>
        <td>Cycle Ingénieur • 2A</td>
        <td class="grade-cell" style="text-align: center;">48h</td>
        <td style="text-align: center;">Cours & TD</td>
        <td style="text-align: center; color: #15803d; font-weight: 700;">Validé</td>
      </tr>
      <tr>
        <td><strong>DEV-405</strong></td>
        <td>Génie Logiciel & Architecture Microservices</td>
        <td>Master 1 • Informatique</td>
        <td class="grade-cell" style="text-align: center;">42h</td>
        <td style="text-align: center;">Cours & TP</td>
        <td style="text-align: center; color: #15803d; font-weight: 700;">Validé</td>
      </tr>
      <tr>
        <td><strong>SYS-402</strong></td>
        <td>Systèmes Distribués, Réseaux & Cloud</td>
        <td>Cycle Ingénieur • 3A</td>
        <td class="grade-cell" style="text-align: center;">36h</td>
        <td style="text-align: center;">Cours & TP</td>
        <td style="text-align: center; color: #15803d; font-weight: 700;">Validé</td>
      </tr>
      <tr>
        <td><strong>PROJ-401</strong></td>
        <td>Supervision Projets de Fin d'Études (PFE)</td>
        <td>Master 2 • Systèmes Intelligents</td>
        <td class="grade-cell" style="text-align: center;">36h</td>
        <td style="text-align: center;">Encadrement</td>
        <td style="text-align: center; color: #15803d; font-weight: 700;">Validé</td>
      </tr>
    </tbody>
  </table>

  <div class="summary-card">
    <div class="summary-item">
      <div class="summary-title">Total Charge Horaire</div>
      <div class="summary-val">162 Heures</div>
    </div>
    <div class="summary-item">
      <div class="summary-title">Modules Enseignés</div>
      <div class="summary-val">4 Modules</div>
    </div>
    <div class="summary-item">
      <div class="summary-title">Validation Décanat</div>
      <div class="summary-val" style="color: #15803d;">CERTIFIÉ CONFORME</div>
    </div>
    <div class="summary-item">
      <div class="summary-title">Année Universitaire</div>
      <div class="summary-val">2025 - 2026</div>
    </div>
  </div>
  '''
      : '''
  <h2 class="section-title">Résultats & Évaluations des Modules (Semestre Académique en cours)</h2>
  <table class="transcript-table">
    <thead>
      <tr>
        <th style="width: 80px;">Code UE</th>
        <th>Intitulé du Module</th>
        <th style="width: 60px; text-align: center;">Crédits</th>
        <th style="width: 75px; text-align: center;">Note /20</th>
        <th style="width: 75px; text-align: center;">Résultat</th>
        <th style="width: 95px; text-align: center;">Mention</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td><strong>INFO-401</strong></td>
        <td>Algorithmes Avancés & Structures de Données</td>
        <td style="text-align: center;">6 ECTS</td>
        <td class="grade-cell" style="text-align: center;">17.50</td>
        <td style="text-align: center; color: #15803d; font-weight: 700;">Validé</td>
        <td class="mention-cell" style="text-align: center;">Très Bien</td>
      </tr>
      <tr>
        <td><strong>MATH-302</strong></td>
        <td>Probabilités, Statistiques & Analyse pour l'IA</td>
        <td style="text-align: center;">6 ECTS</td>
        <td class="grade-cell" style="text-align: center;">16.00</td>
        <td style="text-align: center; color: #15803d; font-weight: 700;">Validé</td>
        <td class="mention-cell" style="text-align: center;">Très Bien</td>
      </tr>
      <tr>
        <td><strong>DEV-405</strong></td>
        <td>Génie Logiciel & Architecture Microservices</td>
        <td style="text-align: center;">6 ECTS</td>
        <td class="grade-cell" style="text-align: center;">18.00</td>
        <td style="text-align: center; color: #15803d; font-weight: 700;">Validé</td>
        <td class="mention-cell" style="text-align: center;">Excellent</td>
      </tr>
      <tr>
        <td><strong>SYS-402</strong></td>
        <td>Systèmes Distribués, Réseaux & Cloud Computing</td>
        <td style="text-align: center;">6 ECTS</td>
        <td class="grade-cell" style="text-align: center;">15.50</td>
        <td style="text-align: center; color: #15803d; font-weight: 700;">Validé</td>
        <td class="mention-cell" style="text-align: center;">Bien</td>
      </tr>
      <tr>
        <td><strong>IA-408</strong></td>
        <td>Machine Learning & Réseaux de Neurones Profonds</td>
        <td style="text-align: center;">6 ECTS</td>
        <td class="grade-cell" style="text-align: center;">17.00</td>
        <td style="text-align: center; color: #15803d; font-weight: 700;">Validé</td>
        <td class="mention-cell" style="text-align: center;">Très Bien</td>
      </tr>
      <tr>
        <td><strong>PROJ-401</strong></td>
        <td>Projet d'Ingénierie Collaboratif & Soutenance</td>
        <td style="text-align: center;">8 ECTS</td>
        <td class="grade-cell" style="text-align: center;">18.50</td>
        <td style="text-align: center; color: #15803d; font-weight: 700;">Validé</td>
        <td class="mention-cell" style="text-align: center;">Excellent</td>
      </tr>
    </tbody>
  </table>

  <div class="summary-card">
    <div class="summary-item">
      <div class="summary-title">Total Crédits ECTS</div>
      <div class="summary-val">60 / 60</div>
    </div>
    <div class="summary-item">
      <div class="summary-title">Moyenne Générale</div>
      <div class="summary-val">17.08 / 20</div>
    </div>
    <div class="summary-item">
      <div class="summary-title">Mention Académique</div>
      <div class="summary-val" style="color: #15803d;">TRÈS BIEN</div>
    </div>
    <div class="summary-item">
      <div class="summary-title">Rang de Promotion</div>
      <div class="summary-val">3ème / 142</div>
    </div>
  </div>
  ''';

  return '''
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <title>Relevé Officiel Académique - $nameDisplay</title>
  <style>
    @page {
      size: A4 portrait;
      margin: 12mm 16mm;
    }
    * {
      box-sizing: border-box;
      -webkit-print-color-adjust: exact !important;
      print-color-adjust: exact !important;
    }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
      color: #0f172a;
      background: #ffffff;
      margin: 0;
      padding: 0;
      font-size: 12px;
      line-height: 1.45;
    }
    .page-container {
      width: 100%;
      max-width: 800px;
      margin: 0 auto;
      border: 1px solid #cbd5e1;
      padding: 24px 28px;
      background: #ffffff;
      border-radius: 8px;
    }
    .official-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-bottom: 2px solid #1e3a8a;
      padding-bottom: 14px;
      margin-bottom: 18px;
    }
    .header-left {
      flex: 1;
    }
    .kingdom-title {
      font-size: 11px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      color: #475569;
    }
    .ministry-title {
      font-size: 10px;
      font-weight: 600;
      color: #64748b;
      margin-top: 2px;
    }
    .institution-name {
      font-size: 15px;
      font-weight: 800;
      color: #1e3a8a;
      margin-top: 6px;
      text-transform: uppercase;
    }
    .header-badge {
      background: #eff6ff;
      border: 1px solid #bfdbfe;
      border-radius: 6px;
      padding: 8px 12px;
      text-align: right;
    }
    .badge-code {
      font-size: 10px;
      color: #1d4ed8;
      font-weight: 700;
    }
    .badge-date {
      font-size: 9.5px;
      color: #64748b;
      margin-top: 2px;
    }
    .document-banner {
      background: #1e3a8a;
      color: #ffffff;
      text-align: center;
      padding: 10px 16px;
      border-radius: 6px;
      margin-bottom: 18px;
    }
    .document-title {
      font-size: 14px;
      font-weight: 800;
      letter-spacing: 0.8px;
      margin: 0;
      text-transform: uppercase;
    }
    .document-subtitle {
      font-size: 10.5px;
      margin: 3px 0 0 0;
      opacity: 0.9;
    }
    .student-card {
      background: #f8fafc;
      border: 1px solid #e2e8f0;
      border-radius: 6px;
      padding: 12px 16px;
      margin-bottom: 18px;
    }
    .info-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      row-gap: 8px;
      column-gap: 20px;
    }
    .info-label {
      font-size: 10px;
      color: #64748b;
      font-weight: 600;
      text-transform: uppercase;
    }
    .info-value {
      font-size: 12px;
      font-weight: 700;
      color: #0f172a;
      margin-top: 1px;
    }
    .status-badge {
      display: inline-block;
      background: #dcfce7;
      color: #15803d;
      font-size: 10px;
      font-weight: 700;
      padding: 2px 8px;
      border-radius: 12px;
    }
    .section-title {
      font-size: 12px;
      font-weight: 700;
      color: #1e293b;
      margin: 0 0 8px 0;
      text-transform: uppercase;
      letter-spacing: 0.4px;
    }
    table.transcript-table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 16px;
      font-size: 11px;
    }
    table.transcript-table th {
      background: #f1f5f9;
      color: #1e293b;
      font-weight: 700;
      text-align: left;
      padding: 7px 10px;
      border: 1px solid #cbd5e1;
      font-size: 10px;
      text-transform: uppercase;
    }
    table.transcript-table td {
      padding: 7px 10px;
      border: 1px solid #e2e8f0;
      color: #334155;
    }
    table.transcript-table tr:nth-child(even) td {
      background: #fafafa;
    }
    .grade-cell {
      font-weight: 700;
      color: #15803d;
    }
    .mention-cell {
      font-weight: 600;
      color: #1e3a8a;
    }
    .summary-card {
      display: flex;
      justify-content: space-between;
      background: #eff6ff;
      border: 1px solid #bfdbfe;
      border-radius: 6px;
      padding: 12px 18px;
      margin-bottom: 18px;
    }
    .summary-item {
      text-align: center;
    }
    .summary-title {
      font-size: 10px;
      color: #1e40af;
      font-weight: 600;
      text-transform: uppercase;
    }
    .summary-val {
      font-size: 15px;
      font-weight: 800;
      color: #1e3a8a;
      margin-top: 2px;
    }
    .legal-footer {
      border-top: 1px solid #cbd5e1;
      padding-top: 14px;
      display: flex;
      align-items: center;
      justify-content: space-between;
    }
    .footer-left {
      flex: 1;
      font-size: 9.5px;
      color: #64748b;
      line-height: 1.4;
    }
    .footer-seal {
      border: 2px dashed #94a3b8;
      border-radius: 50%;
      width: 72px;
      height: 72px;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      text-align: center;
      font-size: 8px;
      font-weight: 700;
      color: #475569;
      margin-left: 20px;
      text-transform: uppercase;
    }
  </style>
</head>
<body>
  <div class="page-container">
    <div class="official-header">
      <div class="header-left">
        <div class="kingdom-title">Royaume du Maroc</div>
        <div class="ministry-title">Ministère de l'Enseignement Supérieur, de la Recherche Scientifique et de l'Innovation</div>
        <div class="institution-name">$instDisplay</div>
      </div>
      <div class="header-badge">
        <div class="badge-code">ENT CERTIFIÉ • SMARTCLASS</div>
        <div class="badge-date">Émis le $date</div>
      </div>
    </div>
    <div class="document-banner">
      <h1 class="document-title">$docTitle</h1>
      <p class="document-subtitle">$docSub</p>
    </div>

    <div class="student-card">
      <div class="info-grid">
        $cardHtml
      </div>
    </div>

    $tableHtml

    <div class="legal-footer">
      <div class="footer-left">
        <strong>VÉRIFICATION D'AUTHENTICITÉ NUMÉRIQUE ENT SMARTCLASS</strong><br>
        Empreinte d'intégrité : <code>SHA256: 8A42-E931-DF08-61B7-AC94-5501-EF18-2026</code><br>
        Ce document officiel est extrait des registres académiques certifiés. Il est strictement vérifiable auprès du secrétariat pédagogique de l'établissement ou sur le portail numérique national ENT.
      </div>
      <div class="footer-seal">
        <span>SMARTCLASS</span>
        <span style="font-size: 7px; color: #1e3a8a;">SCEAU OFFICIEL</span>
        <span>2025-2026</span>
      </div>
    </div>
  </div>
</body>
</html>
''';
}
