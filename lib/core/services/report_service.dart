import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/ticket/domain/entities/ticket.dart';

class ReportService {
  static pw.Document buildTicketReport(List<Ticket> tickets) {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => pw.Header(
          level: 0,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Laporan Tiket Helpdesk', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.Text(dateFormat.format(now)),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'Halaman ${context.pageNumber} dari ${context.pagesCount}',
            style: const pw.TextStyle(color: PdfColors.grey, fontSize: 10),
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 10),
          pw.Text('Ringkasan Statistik:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', tickets.length.toString()),
              _buildStatItem('Pending', tickets.where((t) => t.status == 'open' || t.status == 'assign').length.toString()),
              _buildStatItem('Proses', tickets.where((t) => t.status == 'on progress').length.toString()),
              _buildStatItem('Selesai', tickets.where((t) => t.status == 'close').length.toString()),
            ],
          ),
          pw.SizedBox(height: 30),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headers: ['ID', 'Judul', 'Status', 'Pembuat', 'Tgl Dibuat'],
            data: List.from(tickets).map((t) => [
              t.id.substring(0, 8),
              t.title,
              t.status.toUpperCase(),
              t.creatorName,
              DateFormat('dd/MM/yy').format(t.createdAt),
            ]).toList(),
          ),
        ],
      ),
    );
    return pdf;
  }

  static Future<void> generateAndPrintTicketReport(List<Ticket> tickets) async {
    final pdf = buildTicketReport(tickets);
    final now = DateTime.now();
    
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_Helpdesk_${DateFormat('yyyyMMdd').format(now)}.pdf',
    );
  }

  static pw.Widget _buildStatItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
        pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}
