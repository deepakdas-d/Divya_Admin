import 'package:admin/Controller/order_report_controller.dart';
import 'package:admin/Screens/Orders/individual_order_report.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class OrderReport extends StatelessWidget {
  final OrderReportController controller = Get.put(OrderReportController());

  OrderReport({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Reports'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Obx(
            () => IconButton(
              onPressed: controller.isExporting.value
                  ? null
                  : controller.exportToExcel,
              icon: controller.isExporting.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.download),
              tooltip: 'Export to Excel',
            ),
          ),
          IconButton(
            onPressed: controller.clearFilters,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear Filters',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.fetchOrders,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: (value) => controller.searchQuery.value = value,
                  decoration: InputDecoration(
                    hintText:
                        'Search by name, order ID, phone, salesman, or place...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Filter Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Status Filter
                      Obx(
                        () => _buildFilterDropdown(
                          context: context,
                          label: 'Status',
                          value: controller.statusFilter.value,
                          items: [
                            'All',
                            'pending',
                            'accepted',
                            'inprogress',
                            'sent out for delivery',
                            'delivered',
                          ],
                          onChanged: controller.setStatusFilter,
                        ),
                      ),

                      const SizedBox(width: 12),
                      // Place Filter
                      Obx(
                        () => _buildFilterDropdown(
                          context: context,

                          label: 'Place',
                          value: controller.placeFilter.value.isEmpty
                              ? null
                              : controller.placeFilter.value,
                          items: ['All', ...controller.availablePlaces],
                          onChanged: controller.setPlaceFilter,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Salesperson Filter
                      Obx(
                        () => _buildFilterDropdown(
                          context: context,
                          label: 'Salesperson',
                          value: controller.salespersonFilter.value.isEmpty
                              ? null
                              : controller.salespersonFilter.value,
                          items: ['All', ...controller.availableSalespeople],
                          onChanged: controller.setSalespersonFilter,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Date Range Filter
                      _buildDateRangeFilter(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Summary Section
          Obx(
            () => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Orders: ${controller.filteredOrders.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (controller.filteredOrders.isNotEmpty)
                    Text(
                      'Page ${controller.currentPage.value + 1} of ${controller.totalPages.value}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                ],
              ),
            ),
          ),
          // Orders List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.filteredOrders.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No orders found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.paginatedOrders.length,
                itemBuilder: (context, index) {
                  final order = controller.paginatedOrders[index];
                  return _buildOrderCard(order, context);
                },
              );
            }),
          ),
          // Pagination
          Obx(
            () => controller.totalPages.value > 1
                ? _buildPagination()
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required BuildContext context,
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return SizedBox(
      width: MediaQuery.of(context).size.height * 0.21,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item, // keep 'All' as is
            child: Text(item),
          );
        }).toList(),

        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDateRangeFilter() {
    return Container(
      width: 180,
      child: InkWell(
        onTap: () async {
          final DateTimeRange? picked = await showDateRangePicker(
            context: Get.context!,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            initialDateRange:
                controller.startDate.value != null &&
                    controller.endDate.value != null
                ? DateTimeRange(
                    start: controller.startDate.value!,
                    end: controller.endDate.value!,
                  )
                : null,
          );
          controller.setDateRange(picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Row(
            children: [
              const Icon(Icons.date_range, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Obx(
                  () => Text(
                    controller.startDate.value != null &&
                            controller.endDate.value != null
                        ? '${DateFormat('MMM dd').format(controller.startDate.value!)} - ${DateFormat('MMM dd').format(controller.endDate.value!)}'
                        : 'Date Range',
                    style: TextStyle(
                      color: controller.startDate.value != null
                          ? Colors.black
                          : Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () {
          // Navigate to individual order report page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IndividualOrderReportPage(order: order),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Order Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['name'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${order['orderId'] ?? 'N/A'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order['place'] ?? 'N/A',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Status and Arrow
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: controller.getStatusColor(order['status'] ?? ''),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order['status'] ?? 'N/A',
                      style: TextStyle(
                        color: controller.getStatusTextColor(
                          order['status'] ?? '',
                        ),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildDetailRow(IconData icon, String label, String value) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 4),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Icon(icon, size: 16, color: Colors.grey.shade600),
  //         const SizedBox(width: 8),
  //         Expanded(
  //           child: RichText(
  //             text: TextSpan(
  //               style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
  //               children: [
  //                 TextSpan(
  //                   text: '$label: ',
  //                   style: const TextStyle(fontWeight: FontWeight.w500),
  //                 ),
  //                 TextSpan(text: value),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Button
          ElevatedButton.icon(
            onPressed: controller.currentPage.value > 0
                ? controller.previousPage
                : null,
            icon: const Icon(Icons.chevron_left, size: 18),
            label: const Text('Previous'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          // Page Numbers
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < controller.totalPages.value; i++)
                  if (i < 5 ||
                      (i >= controller.currentPage.value - 2 &&
                          i <= controller.currentPage.value + 2))
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      child: GestureDetector(
                        onTap: () => controller.goToPage(i),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: i == controller.currentPage.value
                                ? Colors.blue.shade600
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue.shade600),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: i == controller.currentPage.value
                                    ? Colors.white
                                    : Colors.blue.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
          // Next Button
          ElevatedButton.icon(
            onPressed:
                controller.currentPage.value < controller.totalPages.value - 1
                ? controller.nextPage
                : null,
            icon: const Icon(Icons.chevron_right, size: 18),
            label: const Text('Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}
