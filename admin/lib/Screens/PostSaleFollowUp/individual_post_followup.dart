import 'dart:developer';
import 'dart:io';

import 'package:admin/Controller/post_sale_followup_controller.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

class IndividualPostReportPage extends StatelessWidget {
  final Map<String, dynamic> order;

  IndividualPostReportPage({super.key, required this.order});

  final controller = Get.put(PostSaleFollowupController());
  Future<void> exportOrderToExcel(Map<String, dynamic> order) async {
    try {
      final hasPermission = await controller.checkStoragePermission();
      if (!hasPermission) return;

      final excel = Excel.createExcel();
      final sheet = excel['order'];

      final headers = [
        'Order ID',
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
        'Review Notes',
        'Maker',
      ];

      final values = [
        order['orderId'] ?? '',
        order['name'] ?? '',
        order['phone1'] ?? '',
        order['phone2'] ?? '',
        order['address'] ?? '',
        order['place'] ?? '',
        order['productID'] ?? '',
        order['salesman'] ?? '',
        order['status'] ?? '',
        (order['createdAt'] as DateTime?)?.toString().split('.')[0] ?? '',
        (order['followUpDate'] as DateTime?)?.toString().split('.')[0] ?? '',
        order['nos']?.toString() ?? '',
        order['remark'] ?? '',
        order['followUpNotes'] ?? '',
        order['maker'] ?? '',
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
      final fileName = 'order_${order['orderId'] ?? 'unknown'}_$timestamp.xlsx'
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
  Future<void> exportOrderToPdf(Map<String, dynamic> order) async {
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
                  'Post Order Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 16),
                _pdfRow('Order ID', order['orderId']),
                _pdfRow('Name', order['name']),
                _pdfRow('Primary Phone', order['phone1']),
                if (order['phone2'] != null &&
                    order['phone2'].toString().isNotEmpty)
                  _pdfRow('Secondary Phone', order['phone2']),
                _pdfRow('Address', order['address']),
                _pdfRow('Place', order['place']),
                _pdfRow('Product ID', order['productID']),
                _pdfRow('Salesman', order['salesman']),
                _pdfRow('Salesman', order['maker']),
                _pdfRow('Status', order['status']),
                _pdfRow('Remark Notes', order['followUpNotes']),

                _pdfRow(
                  'Created At',
                  (order['createdAt'] as DateTime?)?.toString().split('.')[0] ??
                      '',
                ),
                _pdfRow(
                  'Follow Up Date',
                  (order['followUpDate'] as DateTime?)?.toString().split(
                        '.',
                      )[0] ??
                      '',
                ),
                _pdfRow('Nos', order['nos']?.toString()),
                if (order['remark'] != null &&
                    order['remark'].toString().isNotEmpty)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(height: 12),
                      pw.Text(
                        'Remark:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(order['remark']),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );

      final dir = Directory('/storage/emulated/0/Download');
      final file = File(
        '${dir.path}/order_${order['orderId']}_${DateTime.now().millisecondsSinceEpoch}.pdf',
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
    final notes = order['followUpNotes'] ?? 'no follow up notes';
    log('Follow Up Notes: $notes');
    log('Order data: ${order.toString()}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Order Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export order',
            onPressed: () => _showExportOptions(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            order['name'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Status Badges
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getOrderStatusColor(
                                  order['order_status'] ?? '',
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                order['order_status'] ?? 'N/A',
                                style: TextStyle(
                                  color: _getOrderStatusTextColor(
                                    order['order_status'] ?? '',
                                  ),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Order ID: ${order['orderId'] ?? 'N/A'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Contact Information
            _buildSectionCard('Contact Information', Icons.contact_page, [
              _buildDetailRow(
                Icons.location_on,
                'Place',
                order['place'] ?? 'N/A',
              ),
              _buildDetailRow(Icons.phone, 'Phone', order['phone1'] ?? 'N/A'),
              if (order['address'] != null &&
                  order['address'].toString().isNotEmpty)
                _buildDetailRow(Icons.home, 'Address', order['address']),
            ]),
            const SizedBox(height: 16),

            // Order Information
            _buildSectionCard('Order Information', Icons.inventory, [
              _buildDetailRow(
                Icons.inventory,
                'Product ID',
                order['productID'] ?? 'N/A',
              ),
              _buildDetailRow(
                Icons.numbers,
                'Quantity',
                order['nos']?.toString() ?? 'N/A',
              ),
              _buildDetailRow(
                Icons.person,
                'Salesman',
                order['salesman'] ?? 'N/A',
              ),
              _buildDetailRow(Icons.person, 'Maker', order['maker'] ?? 'N/A'),
            ]),
            const SizedBox(height: 16),

            // Dates Information
            _buildSectionCard('Dates', Icons.calendar_today, [
              _buildDetailRow(
                Icons.calendar_today,
                'Created',
                order['createdAt'] != null
                    ? DateFormat('MMM dd, yyyy').format(order['createdAt'])
                    : 'N/A',
              ),
              if (order['deliveryDate'] != null)
                _buildDetailRow(
                  Icons.local_shipping,
                  'Delivery Date',
                  DateFormat('MMM dd, yyyy').format(order['deliveryDate']),
                ),
            ]),
            const SizedBox(height: 16),

            // Additional Information
            if (order['remark'] != null &&
                order['remark'].toString().isNotEmpty)
              _buildSectionCard('Additional Information', Icons.note, [
                _buildDetailRow(Icons.note, 'Remark', order['remark']),
              ]),
            const SizedBox(height: 16),

            if (order['followUpNotes'] != null &&
                order['followUpNotes'].toString().trim().isNotEmpty)
              _buildSectionCard('Review Details', Icons.note, [
                _buildDetailRow(
                  Icons.note,
                  'Review Note',
                  order['followUpNotes'],
                ),
              ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // Status color methods (replace with your controller methods)

  // Order status color methods(background)
  Color _getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.yellow.shade100;
      case 'accepted':
        return Colors.green.shade100;
      case 'sent out for delivery':
        return Colors.blue.shade100;
      case 'delivered':
        return Colors.teal.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getOrderStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.grey.shade800;
      case 'accepted':
        return Colors.green.shade800;
      case 'sent out for delivery':
        return Colors.blue.shade800;
      case 'delivered':
        return Colors.teal.shade800;
      default:
        return Colors.grey.shade800;
    }
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
                'Export order As',
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
                      exportOrderToPdf(order);
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
                      exportOrderToExcel(order);
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
