// Individual Lead Detail Page

import 'dart:io';
import 'package:admin/Controller/lead_report_controller.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

class LeadDetailPage extends StatelessWidget {
  final Map<String, dynamic> lead;

  LeadDetailPage({super.key, required this.lead});

  final controller = Get.put(LeadReportController());
  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'HOT':
        return Colors.red;
      case 'WARM':
        return Colors.orange;
      case 'COLD':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> exportLeadToExcel(Map<String, dynamic> lead) async {
    try {
      final hasPermission = await controller.checkStoragePermission();
      if (!hasPermission) return;

      final excel = Excel.createExcel();
      final sheet = excel['Lead'];

      final headers = [
        'Lead ID',
        'Name',
        'Primary Phone',
        'Secondary Phone',
        'Address',
        'Place',
        'Product ID',
        'Salesman',
        'Status',
        'Created At',
        'Follow Up Date',
        'Nos',
        'Remark',
      ];

      final values = [
        lead['leadId'] ?? '',
        lead['name'] ?? '',
        lead['phone1'] ?? '',
        lead['phone2'] ?? '',
        lead['address'] ?? '',
        lead['place'] ?? '',
        lead['productID'] ?? '',
        lead['salesman'] ?? '',
        lead['status'] ?? '',
        (lead['createdAt'] as DateTime?)?.toString().split('.')[0] ?? '',
        (lead['followUpDate'] as DateTime?)?.toString().split('.')[0] ?? '',
        lead['nos']?.toString() ?? '',
        lead['remark'] ?? '',
      ];

      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 20.0);
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = TextCellValue(
          headers[i],
        );

        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1))
            .value = TextCellValue(
          values[i],
        );
      }

      final timestamp = DateTime.now().toString().split('.')[0];
      final fileName = 'lead_${lead['leadId'] ?? 'unknown'}_$timestamp.xlsx'
          .replaceAll(':', '-');

      final downloadsDir = Directory('/storage/emulated/0/Download');
      final file = File('${downloadsDir.path}/$fileName');

      final bytes = excel.encode();
      if (bytes == null) throw 'Excel encode failed';

      await file.writeAsBytes(bytes);

      Get.snackbar(
        'Success',
        'Excel exported to Downloads as $fileName',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Export Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  //pdf download
  Future<void> exportLeadToPdf(Map<String, dynamic> lead) async {
    try {
      final hasPermission = await controller.checkStoragePermission();
      if (!hasPermission) return;

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Lead Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 16),
                _pdfRow('Lead ID', lead['leadId']),
                _pdfRow('Name', lead['name']),
                _pdfRow('Primary Phone', lead['phone1']),
                if (lead['phone2'] != null &&
                    lead['phone2'].toString().isNotEmpty)
                  _pdfRow('Secondary Phone', lead['phone2']),
                _pdfRow('Address', lead['address']),
                _pdfRow('Place', lead['place']),
                _pdfRow('Product ID', lead['productID']),
                _pdfRow('Salesman', lead['salesman']),
                _pdfRow('Status', lead['status']),
                _pdfRow(
                  'Created At',
                  (lead['createdAt'] as DateTime?)?.toString().split('.')[0] ??
                      '',
                ),
                _pdfRow(
                  'Follow Up Date',
                  (lead['followUpDate'] as DateTime?)?.toString().split(
                        '.',
                      )[0] ??
                      '',
                ),
                _pdfRow('Nos', lead['nos']?.toString()),
                if (lead['remark'] != null &&
                    lead['remark'].toString().isNotEmpty)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(height: 12),
                      pw.Text(
                        'Remark:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(lead['remark']),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );

      final dir = Directory('/storage/emulated/0/Download');
      final file = File(
        '${dir.path}/lead_${lead['leadId']}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      Get.snackbar(
        'Success',
        'PDF exported to Downloads folder',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Export Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  pw.Widget _pdfRow(String label, dynamic value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value?.toString() ?? '')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(lead['name'] ?? 'Lead Details'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export Lead',
            onPressed: () => _showExportOptions(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lead Header Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            lead['name'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(lead['status'] ?? ''),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            lead['status'] ?? 'N/A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lead ID: ${lead['leadId'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (lead['isArchived'] == true)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'ARCHIVED',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Contact Information
            _buildSectionCard('Contact Information', Icons.contact_phone, [
              _buildDetailRow('Primary Phone', lead['phone1'] ?? 'N/A'),
              if (lead['phone2'] != null &&
                  lead['phone2'].toString().isNotEmpty)
                _buildDetailRow('Secondary Phone', lead['phone2']),
              _buildDetailRow('Address', lead['address'] ?? 'N/A'),
              _buildDetailRow('Place', lead['place'] ?? 'N/A'),
            ]),

            const SizedBox(height: 16),

            // Business Information
            _buildSectionCard('Business Information', Icons.business, [
              _buildDetailRow('Product ID', lead['productID'] ?? 'N/A'),
              _buildDetailRow('Salesman Name', lead['salesman']),
              _buildDetailRow('Numbers', lead['nos']?.toString() ?? 'N/A'),
            ]),

            const SizedBox(height: 16),

            // Timeline Information
            _buildSectionCard('Timeline', Icons.schedule, [
              _buildDetailRow(
                'Created Date',
                lead['createdAt'] != null
                    ? DateFormat(
                        'MMM dd, yyyy - HH:mm',
                      ).format(lead['createdAt'])
                    : 'N/A',
              ),
              _buildDetailRow(
                'Follow Up Date',
                lead['followUpDate'] != null
                    ? DateFormat(
                        'MMM dd, yyyy - HH:mm',
                      ).format(lead['followUpDate'])
                    : 'N/A',
              ),
            ]),

            const SizedBox(height: 16),

            // Remarks Section
            if (lead['remark'] != null && lead['remark'].toString().isNotEmpty)
              _buildSectionCard('Remarks', Icons.note, [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    lead['remark'],
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ]),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Export Lead As',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('PDF'),
                    onPressed: () {
                      Navigator.pop(context);
                      exportLeadToPdf(lead);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.grid_on),
                    label: const Text('Excel'),
                    onPressed: () {
                      Navigator.pop(context);
                      exportLeadToExcel(lead);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
