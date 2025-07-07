import 'package:admin/Screens/LeadReport/individual_lead_report.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:admin/Controller/lead_report_controller.dart';

class LeadReport extends StatelessWidget {
  LeadReport({super.key});
  final controller = Get.put(LeadReportController());
  @override
  Widget build(BuildContext context) {
    // Calculate visible tiles based on screen height and estimated card height
    final double screenHeight = MediaQuery.of(context).size.height;
    final double appBarHeight = kToolbarHeight;
    final double filterSectionHeight =
        screenHeight * 0.25; // Approx filter height
    final double summaryHeight = screenHeight * 0.06; // Approx summary height
    final double cardHeight =
        screenHeight *
        0.18; // Approx height of each card (increased due to detailed card)
    final int visibleTiles =
        ((screenHeight - appBarHeight - filterSectionHeight - summaryHeight) /
                cardHeight)
            .ceil();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Lead Reports',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export order',
            onPressed: () => _showExportOptions(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => controller.fetchLeads(isRefresh: true),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
            height: filterSectionHeight * 0.8,
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
                    borderRadius: BorderRadius.circular(
                      MediaQuery.of(context).size.width * 0.03,
                    ),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search leads...',
                      hintText: 'Name, Lead ID, Phone, Place, or Salesman',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.04,
                        vertical: MediaQuery.of(context).size.height * 0.015,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.indigo.shade600,
                        size: MediaQuery.of(context).size.width * 0.05,
                      ),
                      suffixIcon: Obx(
                        () => controller.searchQuery.value.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  size:
                                      MediaQuery.of(context).size.width * 0.05,
                                ),
                                onPressed: () =>
                                    controller.searchQuery.value = '',
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    onChanged: (value) => controller.searchQuery.value = value,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                // Filter Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Salesperson Filter
                      Container(
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: MediaQuery.of(context).size.height * 0.06,
                        margin: EdgeInsets.only(
                          right: MediaQuery.of(context).size.width * 0.03,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width * 0.03,
                          ),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Obx(
                          () => DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Salesperson',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width * 0.04,
                                vertical:
                                    MediaQuery.of(context).size.height * 0.01,
                              ),
                              prefixIcon: Icon(
                                Icons.person_rounded,
                                size: MediaQuery.of(context).size.width * 0.05,
                              ),
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
                                    style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                          0.035,
                                    ),
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
                        width: MediaQuery.of(context).size.width * 0.4,
                        height: MediaQuery.of(context).size.height * 0.06,
                        margin: EdgeInsets.only(
                          right: MediaQuery.of(context).size.width * 0.03,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width * 0.03,
                          ),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Obx(
                          () => DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width * 0.04,
                                vertical:
                                    MediaQuery.of(context).size.height * 0.01,
                              ),
                              prefixIcon: Icon(
                                Icons.filter_list_rounded,
                                size: MediaQuery.of(context).size.width * 0.05,
                              ),
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
                                        width:
                                            MediaQuery.of(context).size.width *
                                            0.03,
                                        height:
                                            MediaQuery.of(context).size.width *
                                            0.03,
                                        margin: EdgeInsets.only(
                                          right:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.02,
                                        ),
                                        decoration: BoxDecoration(
                                          color: controller.getStatusColor(
                                            status,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            MediaQuery.of(context).size.width *
                                                0.015,
                                          ),
                                          border: Border.all(
                                            color: controller
                                                .getStatusTextColor(status),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      status,
                                      style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width *
                                            0.035,
                                      ),
                                    ),
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
                        width: MediaQuery.of(context).size.width * 0.4,
                        height: MediaQuery.of(context).size.height * 0.06,
                        margin: EdgeInsets.only(
                          right: MediaQuery.of(context).size.width * 0.03,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width * 0.03,
                          ),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Obx(
                          () => DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Place',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width * 0.04,
                                vertical:
                                    MediaQuery.of(context).size.height * 0.01,
                              ),
                              prefixIcon: Icon(
                                Icons.location_on_rounded,
                                size: MediaQuery.of(context).size.width * 0.05,
                              ),
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
                                    style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                          0.035,
                                    ),
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
                        width: MediaQuery.of(context).size.width * 0.38,
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
                          icon: Icon(
                            Icons.date_range_rounded,
                            size: MediaQuery.of(context).size.width * 0.05,
                          ),
                          label: Obx(
                            () => Text(
                              controller.startDate.value != null
                                  ? 'Date Selected'
                                  : 'Select Date',
                              style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.width * 0.03,
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade50,
                            foregroundColor: Colors.indigo.shade700,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                              vertical:
                                  MediaQuery.of(context).size.height * 0.015,
                              horizontal:
                                  MediaQuery.of(context).size.width * 0.02,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                MediaQuery.of(context).size.width * 0.03,
                              ),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.03),
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
                                  size:
                                      MediaQuery.of(context).size.width * 0.05,
                                ),
                                tooltip: 'Clear Filters',
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Stats Row
          Obx(
            () => Container(
              height: summaryHeight * 1.3,
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.04,
              ),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(
                    'Total',
                    controller.filteredLeads.length.toString(),
                    Colors.blue,
                    context,
                  ),
                  _buildStatCard(
                    'Hot',
                    controller.filteredLeads
                        .where((lead) => lead['status'] == 'HOT')
                        .length
                        .toString(),
                    Colors.red,
                    context,
                  ),
                  _buildStatCard(
                    'Warm',
                    controller.filteredLeads
                        .where((lead) => lead['status'] == 'WARM')
                        .length
                        .toString(),
                    Colors.orange,
                    context,
                  ),
                  _buildStatCard(
                    'Cold',
                    controller.filteredLeads
                        .where((lead) => lead['status'] == 'COLD')
                        .length
                        .toString(),
                    Colors.indigo,
                    context,
                  ),
                ],
              ),
            ),
          ),
          // Content Area
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.paginatedLeads.isEmpty) {
                return _buildShimmerList(context, visibleTiles);
              }

              if (controller.paginatedLeads.isEmpty &&
                  !controller.isLoading.value) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: MediaQuery.of(context).size.width * 0.15,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.02,
                      ),
                      Text(
                        'No leads found',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.045,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.01,
                      ),
                      Text(
                        'Try adjusting your filters',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.035,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: controller.scrollController,
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width * 0.04,
                ),
                itemCount:
                    controller.paginatedLeads.length +
                    (controller.isLoadingMore.value ? visibleTiles : 0),
                itemBuilder: (context, index) {
                  if (index >= controller.paginatedLeads.length) {
                    return _buildShimmerCard(context);
                  }
                  final lead = controller.paginatedLeads[index];
                  return _buildLeadCard(context, lead, controller);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    BuildContext context,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.height * 0.01,
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.05,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.03,
                color: Colors.grey.shade600,
              ),
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
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height * 0.015,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          MediaQuery.of(context).size.width * 0.04,
        ),
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
        borderRadius: BorderRadius.circular(
          MediaQuery.of(context).size.width * 0.04,
        ),
        child: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Profile Avatar
                  CircleAvatar(
                    radius: MediaQuery.of(context).size.width * 0.05,
                    backgroundColor: Colors.indigo.shade100,
                    child: Text(
                      lead['name'].toString().isNotEmpty
                          ? lead['name'].toString()[0].toUpperCase()
                          : 'L',
                      style: TextStyle(
                        color: Colors.indigo.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: MediaQuery.of(context).size.width * 0.04,
                      ),
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                  // Name and Lead ID
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lead['name'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.04,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ID: ${lead['leadId']}',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.03,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.02,
                      vertical: MediaQuery.of(context).size.height * 0.005,
                    ),
                    decoration: BoxDecoration(
                      color: controller.getStatusColor(lead['status']),
                      borderRadius: BorderRadius.circular(
                        MediaQuery.of(context).size.width * 0.03,
                      ),
                      border: Border.all(
                        color: controller.getStatusTextColor(lead['status']),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      lead['status'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.028,
                        fontWeight: FontWeight.bold,
                        color: controller.getStatusTextColor(lead['status']),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.015),
              // Details Grid
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      Icons.phone_rounded,
                      'Phone',
                      lead['phone1'] ?? 'N/A',
                      context,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.person_rounded,
                      'Salesman',
                      lead['salesman'] ?? 'N/A',
                      context,
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      Icons.location_on_rounded,
                      'Place',
                      lead['place'] ?? 'N/A',
                      context,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.calendar_today_rounded,
                      'Created',
                      DateFormat('MMM dd, yyyy').format(lead['createdAt']),
                      context,
                    ),
                  ),
                ],
              ),
              // Follow-up indicator
              if (lead['followUpDate'] != null) ...[
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.02,
                    vertical: MediaQuery.of(context).size.height * 0.005,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(
                      MediaQuery.of(context).size.width * 0.02,
                    ),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: MediaQuery.of(context).size.width * 0.035,
                        color: Colors.amber.shade700,
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.01),
                      Text(
                        'Follow-up: ${DateFormat('MMM dd').format(lead['followUpDate'])}',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.028,
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

  Widget _buildDetailItem(
    IconData icon,
    String label,
    String value,
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: MediaQuery.of(context).size.width * 0.04,
          color: Colors.grey.shade600,
        ),
        SizedBox(width: MediaQuery.of(context).size.width * 0.015),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.025,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.03,
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

  Widget _buildShimmerCard(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.015,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            MediaQuery.of(context).size.width * 0.04,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  CircleAvatar(
                    radius: MediaQuery.of(context).size.width * 0.05,
                    backgroundColor: Colors.grey[300],
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width * 0.4,
                          height: MediaQuery.of(context).size.height * 0.02,
                          color: Colors.white,
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.005,
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.3,
                          height: MediaQuery.of(context).size.height * 0.015,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.15,
                    height: MediaQuery.of(context).size.height * 0.02,
                    color: Colors.white,
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.015),
              // Details Grid
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width * 0.04,
                          height: MediaQuery.of(context).size.width * 0.04,
                          color: Colors.white,
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.015,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width * 0.2,
                                height:
                                    MediaQuery.of(context).size.height * 0.015,
                                color: Colors.white,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.005,
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width * 0.25,
                                height:
                                    MediaQuery.of(context).size.height * 0.015,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width * 0.04,
                          height: MediaQuery.of(context).size.width * 0.04,
                          color: Colors.white,
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.015,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width * 0.2,
                                height:
                                    MediaQuery.of(context).size.height * 0.015,
                                color: Colors.white,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.005,
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width * 0.25,
                                height:
                                    MediaQuery.of(context).size.height * 0.015,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width * 0.04,
                          height: MediaQuery.of(context).size.width * 0.04,
                          color: Colors.white,
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.015,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width * 0.2,
                                height:
                                    MediaQuery.of(context).size.height * 0.015,
                                color: Colors.white,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.005,
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width * 0.25,
                                height:
                                    MediaQuery.of(context).size.height * 0.015,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width * 0.04,
                          height: MediaQuery.of(context).size.width * 0.04,
                          color: Colors.white,
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.015,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width * 0.2,
                                height:
                                    MediaQuery.of(context).size.height * 0.015,
                                color: Colors.white,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.005,
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width * 0.25,
                                height:
                                    MediaQuery.of(context).size.height * 0.015,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildShimmerList(BuildContext context, int visibleTiles) {
    return ListView.builder(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
      itemCount: visibleTiles,
      itemBuilder: (context, index) => _buildShimmerCard(context),
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
                'Export Order As',
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
                      controller.exportToPdf();
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
                      controller.exportToExcel();
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
