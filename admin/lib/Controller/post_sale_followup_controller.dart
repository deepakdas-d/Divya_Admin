import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

// Controller
class PostSaleFollowupController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable variables
  final RxList<Map<String, dynamic>> allOrders = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredOrders =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> paginatedOrders =
      <Map<String, dynamic>>[].obs;

  final RxString statusFilter = 'All'.obs;
  final RxString placeFilter = ''.obs; // Place filter
  final RxString salespersonFilter = ''.obs; // Salesperson filter
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isDataLoaded = false.obs;
  final RxBool isExporting = false.obs;

  // Status options
  final List<String> statusOptions = [
    'pending',
    'accepted',
    'inprogress',
    'sent out for delivery',
    'delivered',
  ];

  // Filter options
  final RxList<String> availablePlaces = <String>[].obs;
  final RxList<String> availableSalespeople = <String>[].obs;

  // Pagination variables
  final RxInt currentPage = 0.obs;
  final int itemsPerPage = 15;
  final RxInt totalPages = 0.obs;
  final RxBool isLoadingMore = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchOrders();

    // Listen to search query changes with debounce
    debounce(
      searchQuery,
      (_) => filterOrders(),
      time: const Duration(milliseconds: 500),
    );
  }

  Future<String> getSalesmanName(String? uid) async {
    if (uid == null || uid.isEmpty) return 'N/A';
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final name = doc.data()?['name'];
        return name ?? 'Unknown';
      } else {
        return 'Not Found';
      }
    } catch (e) {
      log('Error fetching user for $uid: $e');
      return 'Error';
    }
  }

  Future<void> fetchOrders() async {
    try {
      isLoading.value = true;
      QuerySnapshot orderSnapshot = await _firestore
          .collection('Orders')
          .where('order_status', isEqualTo: 'delivered')
          .get();
      List<Map<String, dynamic>> tempOrders = [];
      Set<String> placesSet = <String>{};
      Set<String> salespeopleSet = <String>{};

      for (var doc in orderSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String? salesmanID = data['salesmanID'];
        final String salesmanName = await getSalesmanName(salesmanID);

        tempOrders.add({
          'address': data['address'] ?? '',
          'createdAt':
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'deliveryDate': (data['deliveryDate'] as Timestamp?)?.toDate(),
          'followUpDate': (data['followUpDate'] as Timestamp?)?.toDate(),
          'makerId': data['makerId'] ?? '',
          'name': data['name'] ?? '',
          'nos': data['nos'] ?? 0,
          'orderId': data['orderId'] ?? '',
          'order_status': data['order_status'] ?? '',
          'phone1': data['phone1'] ?? '',
          'phone2': data['phone2'] ?? '',
          'place': data['place'] ?? '',
          'productID': data['productID'] ?? '',
          'remark': data['remark'] ?? '',
          'salesman': salesmanName,
          'status': data['status'] ?? '',
        });

        // Collect unique places and salespeople for filter options
        final place = data['place']?.toString().trim();
        if (place != null && place.isNotEmpty) {
          placesSet.add(place);
        }
        if (salesmanName.isNotEmpty && salesmanName != 'N/A') {
          salespeopleSet.add(salesmanName);
        }
      }

      // Sort by creation date (newest first)
      tempOrders.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));

      allOrders.value = tempOrders;

      // Update filter options
      availablePlaces.value = placesSet.toList()..sort();
      availableSalespeople.value = salespeopleSet.toList()..sort();

      filterOrders();
      isDataLoaded.value = true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch orders: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void filterOrders() {
    List<Map<String, dynamic>> filtered = allOrders.where((order) {
      bool matches = true;

      // Filter by status (using the new status options)
      if (statusFilter.value.isNotEmpty && statusFilter.value != 'All') {
        matches = matches && order['order_status'] == statusFilter.value;
      }

      // Place filter
      if (placeFilter.value.isNotEmpty && placeFilter.value != 'All') {
        matches = matches && order['place'] == placeFilter.value;
      }

      // Salesperson filter
      if (salespersonFilter.value.isNotEmpty &&
          salespersonFilter.value != 'All') {
        matches = matches && order['salesman'] == salespersonFilter.value;
      }

      if (startDate.value != null) {
        matches = matches && order['createdAt'].isAfter(startDate.value!);
      }

      if (endDate.value != null) {
        matches =
            matches &&
            order['createdAt'].isBefore(
              endDate.value!.add(const Duration(days: 1)),
            );
      }

      if (searchQuery.value.isNotEmpty) {
        final query = searchQuery.value.toLowerCase();
        matches =
            matches &&
            (order['name'].toString().toLowerCase().contains(query) ||
                order['orderId'].toString().toLowerCase().contains(query) ||
                order['phone1'].toString().toLowerCase().contains(query) ||
                order['salesman'].toString().toLowerCase().contains(query) ||
                order['place'].toString().toLowerCase().contains(query));
      }

      return matches;
    }).toList();

    filteredOrders.value = filtered;
    currentPage.value = 0;
    updatePagination();
  }

  void updatePagination() {
    totalPages.value = (filteredOrders.length / itemsPerPage).ceil();
    final startIndex = currentPage.value * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(
      0,
      filteredOrders.length,
    );

    paginatedOrders.value = filteredOrders.sublist(startIndex, endIndex);
  }

  void nextPage() {
    if (currentPage.value < totalPages.value - 1) {
      currentPage.value++;
      updatePagination();
    }
  }

  void previousPage() {
    if (currentPage.value > 0) {
      currentPage.value--;
      updatePagination();
    }
  }

  void goToPage(int page) {
    if (page >= 0 && page < totalPages.value) {
      currentPage.value = page;
      updatePagination();
    }
  }

  void setStatusFilter(String? status) {
    statusFilter.value = status ?? '';
    filterOrders();
  }

  void setPlaceFilter(String? place) {
    placeFilter.value = place ?? '';
    filterOrders();
  }

  void setSalespersonFilter(String? salesperson) {
    salespersonFilter.value = salesperson ?? '';
    filterOrders();
  }

  void setDateRange(DateTimeRange? range) {
    startDate.value = range?.start;
    endDate.value = range?.end;
    filterOrders();
  }

  void clearFilters() {
    statusFilter.value = 'All';
    placeFilter.value = 'All';
    salespersonFilter.value = 'All';
    startDate.value = null;
    endDate.value = null;
    searchQuery.value = '';
    filterOrders();
  }

  Future<bool> checkStoragePermission() async {
    if (!Platform.isAndroid) return true;

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 30) {
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) return true;
    } else {
      final status = await Permission.storage.request();
      if (status.isGranted) return true;
    }

    Get.snackbar(
      'Permission Required',
      'Storage permission required. Please enable it in settings.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      mainButton: TextButton(
        onPressed: openAppSettings,
        child: const Text(
          'Open Settings',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );

    return false;
  }

  Future<void> exportToExcel() async {
    try {
      isExporting.value = true;

      bool hasPermission = await checkStoragePermission();
      if (!hasPermission) return;

      final excel = Excel.createExcel();
      final sheet = excel['Orders'];

      final headers = [
        'Order ID',
        'Customer Name',
        'Address',
        'Place',
        'Phone1',
        'Phone2',
        'Product ID',
        'Salesman',
        'Status',
        'Order Status',
        'Created At',
        'Delivery Date',
        'Follow Up Date',
        'Nos',
        'Remark',
        'Maker ID',
      ];

      final columnWidths = [
        15,
        20,
        30,
        20,
        15,
        15,
        15,
        15,
        15,
        20, // Increased width for order status
        20,
        20,
        20,
        10,
        25,
        25,
      ];

      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, columnWidths[i].toDouble());
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          fontSize: 12,
          backgroundColorHex: ExcelColor.blue200,
          horizontalAlign: HorizontalAlign.Center,
        );
      }

      for (int rowIndex = 0; rowIndex < filteredOrders.length; rowIndex++) {
        final order = filteredOrders[rowIndex];
        final rowData = [
          order['orderId'] ?? '',
          order['name'] ?? '',
          order['address'] ?? '',
          order['place'] ?? '',
          order['phone1'] ?? '',
          order['phone2'] ?? '',
          order['productID'] ?? '',
          order['salesman'] ?? '',
          order['status'] ?? '',
          order['order_status'] ?? '',
          (order['createdAt'] as DateTime?)?.toString().split('.')[0] ?? '',
          (order['deliveryDate'] as DateTime?)?.toString().split('.')[0] ?? '',
          (order['followUpDate'] as DateTime?)?.toString().split('.')[0] ?? '',
          order['nos']?.toString() ?? '',
          order['remark'] ?? '',
          order['makerId'] ?? '',
        ];

        for (int colIndex = 0; colIndex < rowData.length; colIndex++) {
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(
              columnIndex: colIndex,
              rowIndex: rowIndex + 1,
            ),
          );
          cell.value = TextCellValue(rowData[colIndex]);

          // Updated status coloring for column 8 (status field)
          if (colIndex == 8) {
            final status = order['status'];
            cell.cellStyle = CellStyle(
              backgroundColorHex: status == 'delivered'
                  ? ExcelColor.green200
                  : status == 'accepted'
                  ? ExcelColor.lightGreen200
                  : status == 'inprogress'
                  ? ExcelColor.yellow200
                  : status == 'sent out for delivery'
                  ? ExcelColor.orange200
                  : status == 'pending'
                  ? ExcelColor.red200
                  : ExcelColor.white,
            );
          }

          // Updated order status coloring for column 9 (order_status field)
          if (colIndex == 9) {
            final orderStatus = order['order_status'];
            cell.cellStyle = CellStyle(
              backgroundColorHex: orderStatus == 'delivered'
                  ? ExcelColor.green200
                  : orderStatus == 'accepted'
                  ? ExcelColor.lightGreen200
                  : orderStatus == 'inprogress'
                  ? ExcelColor.yellow200
                  : orderStatus == 'sent out for delivery'
                  ? ExcelColor.orange200
                  : orderStatus == 'pending'
                  ? ExcelColor.red200
                  : ExcelColor.white,
            );
          }
        }
      }

      final summaryRow = filteredOrders.length + 2;
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow),
          )
          .value = TextCellValue(
        'Total Orders: ${filteredOrders.length}',
      );

      final timestamp = DateTime.now().toString().split('.')[0];
      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 0,
              rowIndex: summaryRow + 1,
            ),
          )
          .value = TextCellValue(
        'Generated on: $timestamp',
      );

      final bytes = excel.encode();
      if (bytes == null) throw 'Excel encode failed';

      final downloadsDir = Directory('/storage/emulated/0/Download');
      final file = File(
        '${downloadsDir.path}/orders_data_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      );

      await file.writeAsBytes(bytes);

      Get.snackbar(
        'Success',
        'Excel file saved to Downloads folder',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Export failed: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isExporting.value = false;
    }
  }

  // Updated status color methods
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green.shade100;
      case 'accepted':
        return Colors.lightGreen.shade100;
      case 'inprogress':
        return Colors.yellow.shade100;
      case 'sent out for delivery':
        return Colors.orange.shade100;
      case 'pending':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green.shade800;
      case 'accepted':
        return Colors.lightGreen.shade800;
      case 'inprogress':
        return Colors.yellow.shade800;
      case 'sent out for delivery':
        return Colors.orange.shade800;
      case 'pending':
        return Colors.red.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  // Updated order status color methods
  Color getOrderStatusColor(String orderStatus) {
    switch (orderStatus.toLowerCase()) {
      case 'delivered':
        return Colors.green.shade100;
      case 'accepted':
        return Colors.lightGreen.shade100;
      case 'inprogress':
        return Colors.yellow.shade100;
      case 'sent out for delivery':
        return Colors.orange.shade100;
      case 'pending':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color getOrderStatusTextColor(String orderStatus) {
    switch (orderStatus.toLowerCase()) {
      case 'delivered':
        return Colors.green.shade800;
      case 'accepted':
        return Colors.lightGreen.shade800;
      case 'inprogress':
        return Colors.yellow.shade800;
      case 'sent out for delivery':
        return Colors.orange.shade800;
      case 'pending':
        return Colors.red.shade800;
      default:
        return Colors.grey.shade800;
    }
  }
}
