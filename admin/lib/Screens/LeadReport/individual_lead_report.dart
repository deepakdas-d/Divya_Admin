// Individual Lead Detail Page
// import 'dart:developer';

import 'package:admin/Controller/lead_report_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(lead['name'] ?? 'Lead Details'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
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
}
