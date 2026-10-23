import 'file_download_helper_stub.dart'
    if (dart.library.html) 'file_download_helper_web.dart';

void downloadJsonFile(String filename, String content) {
  downloadJsonFileImpl(filename, content);
}

void downloadBytesFile(String filename, List<int> bytes, String mimeType) {
  downloadBytesFileImpl(filename, bytes, mimeType);
}

void openPdfInNewTab(List<int> bytes, {String title = 'Document SmartClass'}) {
  openPdfInNewTabImpl(bytes, title);
}

void printOfficialTranscript({
  required String studentName,
  required String studentId,
  required String institution,
  required String major,
  required String email,
  required String status,
  required String date,
  bool isTeacher = false,
}) {
  printOfficialTranscriptImpl(
    studentName: studentName,
    studentId: studentId,
    institution: institution,
    major: major,
    email: email,
    status: status,
    date: date,
    isTeacher: isTeacher,
  );
}
