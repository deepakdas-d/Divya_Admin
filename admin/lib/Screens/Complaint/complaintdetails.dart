import 'package:admin/Controller/complaint_details_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ComplaintDetailPage extends StatelessWidget {
  final Map<String, dynamic> complaintData;

  const ComplaintDetailPage({super.key, required this.complaintData});

  @override
  Widget build(BuildContext context) {
    // Initialize GetX controller
    final controller = Get.put(ComplaintDetailController());
    controller.initializeData(complaintData);

    return Scaffold(
      // AppBar with title and refresh action
      appBar: AppBar(
        title: const Text('Complaint Details'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            // Refresh the UI using GetX's rebuild mechanism
            onPressed: () => controller.update(),
          ),
        ],
      ),
      // SingleChildScrollView for scrollable content
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildComplaintDetailsCard(controller, context),
            const SizedBox(height: 16),
            _buildResponseSection(controller, context),
            const SizedBox(height: 16),
            _buildPreviousResponses(controller, context),
          ],
        ),
      ),
    );
  }

  // Widget to display complaint details in a card
  Widget _buildComplaintDetailsCard(
    ComplaintDetailController controller,
    context,
  ) {
    // Format timestamp for display
    final createdAt = complaintData['timestamp'] != null
        ? DateFormat(
            'dd MMM yyyy, hh:mm a',
          ).format((complaintData['timestamp'] as Timestamp).toDate())
        : 'N/A';

    final priority = complaintData['priority'] ?? 1;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Complaint Details',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                _buildPriorityChip(priority),
              ],
            ),
            const Divider(height: 24),
            _buildDetailRow('ID', complaintData['complaintId'] ?? 'N/A'),
            _buildDetailRow('Category', complaintData['category'] ?? 'N/A'),
            _buildDetailRow('Customer Name', complaintData['name'] ?? 'N/A'),
            _buildDetailRow('Email', complaintData['email'] ?? 'N/A'),
            _buildDetailRow(
              'User Role',
              complaintData['userRole'] ?? 'Unknown',
            ),
            _buildDetailRow('Created At', createdAt),
            const SizedBox(height: 16),
            const Text(
              'Complaint Description:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                complaintData['complaint'] ?? 'N/A',
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget to display a detail row with label and value
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey.shade700)),
          ),
        ],
      ),
    );
  }

  // Widget to display priority chip based on priority level
  Widget _buildPriorityChip(int priority) {
    Color color;
    String text;

    switch (priority) {
      case 1:
        color = Colors.green;
        text = 'Low Priority';
        break;
      case 2:
        color = Colors.orange;
        text = 'Medium Priority';
        break;
      case 3:
        color = Colors.red;
        text = 'High Priority';
        break;
      default:
        color = Colors.grey;
        text = 'Unknown Priority';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Widget to display response input section
  Widget _buildResponseSection(ComplaintDetailController controller, context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Response',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 16),
            // Status dropdown with reactive state
            Obx(
              () => DropdownButtonFormField<String>(
                value: controller.selectedStatus.value,
                decoration: InputDecoration(
                  labelText: 'Update Status',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
                items: ['pending', 'in-progress', 'resolved', 'closed']
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (value) => controller.selectedStatus.value = value!,
              ),
            ),
            const SizedBox(height: 16),
            // Response text field
            TextField(
              controller: controller.responseController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Response Message',
                hintText: 'Enter your response to this complaint...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            // Submit button with loading state
            Obx(
              () => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.submitResponse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submit Response',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget to display previous responses from Firestore
  Widget _buildPreviousResponses(
    ComplaintDetailController controller,
    context,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Response History',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              ),
            ),
            const SizedBox(height: 16),
            // StreamBuilder to fetch and display responses in real-time
            StreamBuilder<QuerySnapshot>(
              stream: controller.firestore
                  .collection('complaint_responses')
                  .where('complaintId', isEqualTo: complaintData['complaintId'])
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text(
                    'No responses yet.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  );
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final timestamp = data['timestamp'] != null
                        ? DateFormat(
                            'dd MMM yyyy, hh:mm a',
                          ).format((data['timestamp'] as Timestamp).toDate())
                        : 'N/A';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.admin_panel_settings,
                                size: 16,
                                color: Colors.blue.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Admin Response', // Display user ID
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                timestamp,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data['response'] ?? 'No response text',
                            style: const TextStyle(fontSize: 14),
                          ),
                          if (data['statusChanged'] == true) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Status updated to: ${data['newStatus']?.toUpperCase() ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
