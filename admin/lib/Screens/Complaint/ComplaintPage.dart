import 'package:admin/Controller/complaint_controller.dart';
import 'package:admin/Screens/Complaint/complaintdetails.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ComplaintPage extends StatelessWidget {
  const ComplaintPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ComplaintController controller = Get.put(ComplaintController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Management'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          _buildFilterSection(controller),
          Expanded(child: _buildComplaintsList(controller)),
        ],
      ),
    );
  }

  Widget _buildFilterSection(ComplaintController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            onChanged: (value) => controller.searchQuery.value = value,
            decoration: InputDecoration(
              hintText: 'Search complaints...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filter dropdowns
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(
              () => Row(
                children: [
                  _buildFilterDropdown(
                    'Status',
                    controller.selectedStatus.value,
                    controller.statusOptions,
                    (value) => controller.selectedStatus.value = value!,
                  ),
                  const SizedBox(width: 12),
                  _buildFilterDropdown(
                    'Priority',
                    controller.selectedPriority.value,
                    controller.priorityOptions,
                    (value) => controller.selectedPriority.value = value!,
                  ),
                  const SizedBox(width: 12),
                  _buildFilterDropdown(
                    'Category',
                    controller.selectedCategory.value,
                    controller.categoryOptions,
                    (value) => controller.selectedCategory.value = value!,
                  ),
                  const SizedBox(width: 12),
                  _buildFilterDropdown(
                    'Role',
                    controller.selectedRole.value,
                    controller.roleOptions,
                    (value) => controller.selectedRole.value = value!,
                  ),
                  const SizedBox(width: 12),
                  // Clear filters button
                  ElevatedButton(
                    onPressed: () => controller.clearFilters(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.grey.shade700,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('Clear', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: options.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                _getDropdownLabel(label, option),
                style: const TextStyle(fontSize: 12),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          isDense: true,
        ),
      ),
    );
  }

  String _getDropdownLabel(String filterType, String option) {
    if (option == 'All') {
      return '$filterType: All';
    }

    if (filterType == 'Priority') {
      switch (option) {
        case '1':
          return 'Low (1)';
        case '2':
          return 'Medium (2)';
        case '3':
          return 'High (3)';
        default:
          return option;
      }
    }

    return option;
  }

  Widget _buildComplaintsList(ComplaintController controller) {
    return Obx(
      () => StreamBuilder<QuerySnapshot>(
        stream: controller.getFilteredComplaints(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(fontSize: 18, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No complaints found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: controller.enrichComplaintsWithUserData(
              snapshot.data!.docs,
            ),
            builder: (context, enrichedSnapshot) {
              if (enrichedSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (enrichedSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading data: ${enrichedSnapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              final complaints = enrichedSnapshot.data ?? [];
              final filteredComplaints = controller.applyTextSearch(complaints);

              if (filteredComplaints.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No complaints match your filters',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredComplaints.length,
                itemBuilder: (context, index) {
                  return _buildComplaintCard(filteredComplaints[index]);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> data) {
    final createdAt = data['timestamp'] != null
        ? DateFormat(
            'dd MMM yyyy, hh:mm a',
          ).format((data['timestamp'] as Timestamp).toDate())
        : 'N/A';

    final priority = data['priority'] ?? 1;
    final status = data['status'] ?? 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToComplaintDetail(data),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data['category'] ?? 'No category',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  _buildPriorityChip(priority),
                  const SizedBox(width: 8),
                  _buildStatusChip(status),
                ],
              ),
              const SizedBox(height: 12),

              // User info
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    data['name'] ?? 'N/A',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.badge, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    data['userRole'] ?? 'Unknown',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Complaint preview
              Text(
                data['complaint'] ?? 'N/A',
                style: TextStyle(color: Colors.grey.shade800),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Footer
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    createdAt,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    'Tap to view details',
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(int priority) {
    Color color;
    String text;

    switch (priority) {
      case 1:
        color = Colors.green;
        text = 'Low';
        break;
      case 2:
        color = Colors.orange;
        text = 'Medium';
        break;
      case 3:
        color = Colors.red;
        text = 'High';
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color:
              color, // Fixed: Use calculated color instead of Colors.yellowAccent
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'in-progress':
        color = Colors.blue;
        break;
      case 'resolved':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _navigateToComplaintDetail(Map<String, dynamic> complaintData) {
    Get.to(() => ComplaintDetailPage(complaintData: complaintData));
  }
}
