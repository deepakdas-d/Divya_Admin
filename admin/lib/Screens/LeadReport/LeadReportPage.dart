import 'package:admin/Controller/lead_report_controller.dart';
import 'package:admin/Screens/LeadReport/individual_lead_report.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class LeadReport extends StatelessWidget {
  const LeadReport({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LeadReportController());

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Lead Reports',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Obx(
            () => IconButton(
              icon: controller.isExporting.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.download_rounded),
              onPressed: controller.isExporting.value
                  ? null
                  : controller.exportToExcel,
              tooltip: 'Export to Excel',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.fetchLeads,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Enhanced Filter Section
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search leads...',
                      hintText: 'Name, Lead ID, Phone, Place, or Salesman',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.indigo.shade600,
                      ),
                      suffixIcon: Obx(
                        () => controller.searchQuery.value.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () =>
                                    controller.searchQuery.value = '',
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    onChanged: (value) => controller.searchQuery.value = value,
                  ),
                ),
                const SizedBox(height: 16),

                // First Filter Row - Status and Place
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Salesperson Filter
                      Container(
                        width: 220,
                        height: 48,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Obx(
                          () => DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Salesperson',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              prefixIcon: Icon(Icons.person_rounded),
                            ),
                            value: controller.salespersonFilter.value.isEmpty
                                ? null
                                : controller.salespersonFilter.value,
                            items: [
                              const DropdownMenuItem(
                                value: '',
                                child: Text('All Salespeople'),
                              ),
                              ...controller.availableSalespeople.map((
                                salesperson,
                              ) {
                                return DropdownMenuItem(
                                  value: salesperson,
                                  child: Text(
                                    salesperson,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                            ],
                            onChanged: controller.setSalespersonFilter,
                          ),
                        ),
                      ),

                      // Status Filter
                      Container(
                        width: 180,
                        height: 48,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Obx(
                          () => DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              prefixIcon: Icon(Icons.filter_list_rounded),
                            ),
                            value: controller.statusFilter.value.isEmpty
                                ? null
                                : controller.statusFilter.value,
                            items: ['All', 'HOT', 'WARM', 'COLD'].map((status) {
                              return DropdownMenuItem(
                                value: status == 'All' ? '' : status,
                                child: Row(
                                  children: [
                                    if (status != 'All')
                                      Container(
                                        width: 12,
                                        height: 12,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: controller.getStatusColor(
                                            status,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: controller
                                                .getStatusTextColor(status),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                    Text(status),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: controller.setStatusFilter,
                          ),
                        ),
                      ),

                      // Place Filter
                      Container(
                        width: 180,
                        height: 48,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Obx(
                          () => DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Place',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              prefixIcon: Icon(Icons.location_on_rounded),
                            ),
                            value: controller.placeFilter.value.isEmpty
                                ? null
                                : controller.placeFilter.value,
                            items: [
                              const DropdownMenuItem(
                                value: '',
                                child: Text('All Places'),
                              ),
                              ...controller.availablePlaces.map((place) {
                                return DropdownMenuItem(
                                  value: place,
                                  child: Text(
                                    place,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                            ],
                            onChanged: controller.setPlaceFilter,
                          ),
                        ),
                      ),

                      // Date Range Button
                      SizedBox(
                        width: 170,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: Colors.indigo.shade700,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            controller.setDateRange(picked);
                          },
                          icon: const Icon(Icons.date_range_rounded),
                          label: Obx(
                            () => Text(
                              controller.startDate.value != null
                                  ? 'Date Selected'
                                  : 'Select Date',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade50,
                            foregroundColor: Colors.indigo.shade700,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Clear Filters Button
                      Obx(
                        () =>
                            (controller.statusFilter.value.isNotEmpty ||
                                controller.placeFilter.value.isNotEmpty ||
                                controller.salespersonFilter.value.isNotEmpty ||
                                controller.startDate.value != null ||
                                controller.searchQuery.value.isNotEmpty)
                            ? IconButton(
                                onPressed: controller.clearFilters,
                                icon: Icon(
                                  Icons.clear_all_rounded,
                                  color: Colors.red.shade600,
                                ),
                                tooltip: 'Clear Filters',
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // Stats Row
          Obx(
            () => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(
                    'Total',
                    controller.filteredLeads.length.toString(),
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'Hot',
                    controller.filteredLeads
                        .where((lead) => lead['status'] == 'HOT')
                        .length
                        .toString(),
                    Colors.red,
                  ),
                  _buildStatCard(
                    'Warm',
                    controller.filteredLeads
                        .where((lead) => lead['status'] == 'WARM')
                        .length
                        .toString(),
                    Colors.orange,
                  ),
                  _buildStatCard(
                    'Cold',
                    controller.filteredLeads
                        .where((lead) => lead['status'] == 'COLD')
                        .length
                        .toString(),
                    Colors.indigo,
                  ),
                ],
              ),
            ),
          ),

          // Content Area
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value &&
                  !controller.isDataLoaded.value) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Loading leads...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              if (!controller.isDataLoaded.value) {
                return const Center(child: Text('No data available'));
              }

              if (controller.filteredLeads.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No leads found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your filters',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  // Lead List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: controller.paginatedLeads.length,
                      itemBuilder: (context, index) {
                        final lead = controller.paginatedLeads[index];
                        return _buildLeadCard(context, lead, controller);
                      },
                    ),
                  ),

                  // Pagination Controls
                  if (controller.totalPages.value > 1)
                    _buildPaginationControls(controller),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadCard(
    BuildContext context,
    Map<String, dynamic> lead,
    LeadReportController controller,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Get.to(() => LeadDetailPage(lead: lead));
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Profile Avatar
                  CircleAvatar(
                    backgroundColor: Colors.indigo.shade100,
                    child: Text(
                      lead['name'].toString().isNotEmpty
                          ? lead['name'].toString()[0].toUpperCase()
                          : 'L',
                      style: TextStyle(
                        color: Colors.indigo.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name and Lead ID
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lead['name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ID: ${lead['leadId']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: controller.getStatusColor(lead['status']),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: controller.getStatusTextColor(lead['status']),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      lead['status'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: controller.getStatusTextColor(lead['status']),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Details Grid
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      Icons.phone_rounded,
                      'Phone',
                      lead['phone1'] ?? 'N/A',
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.person_rounded,
                      'Salesman',
                      lead['salesman'] ?? 'N/A',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      Icons.location_on_rounded,
                      'Place',
                      lead['place'] ?? 'N/A',
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.calendar_today_rounded,
                      'Created',
                      DateFormat('MMM dd, yyyy').format(lead['createdAt']),
                    ),
                  ),
                ],
              ),

              // Follow-up indicator
              if (lead['followUpDate'] != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: Colors.amber.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Follow-up: ${DateFormat('MMM dd').format(lead['followUpDate'])}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.amber.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationControls(LeadReportController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Obx(
        () => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Previous Button
            ElevatedButton.icon(
              onPressed: controller.currentPage.value > 0
                  ? controller.previousPage
                  : null,
              icon: const Icon(Icons.chevron_left_rounded),
              label: const Text('Previous'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                foregroundColor: Colors.grey.shade700,
                elevation: 0,
              ),
            ),

            // Page Info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Page ${controller.currentPage.value + 1} of ${controller.totalPages.value}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.indigo.shade700,
                ),
              ),
            ),

            // Next Button
            ElevatedButton.icon(
              onPressed:
                  controller.currentPage.value < controller.totalPages.value - 1
                  ? controller.nextPage
                  : null,
              icon: const Icon(Icons.chevron_right_rounded),
              label: const Text('Next'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade100,
                foregroundColor: Colors.indigo.shade700,
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
