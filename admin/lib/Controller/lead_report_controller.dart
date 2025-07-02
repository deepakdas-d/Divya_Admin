import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

// Controller
class LeadReportController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable variables
  final RxList<Map<String, dynamic>> allLeads = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredLeads =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> paginatedLeads =
      <Map<String, dynamic>>[].obs;

  final RxString statusFilter = ''.obs;
  final RxString placeFilter = ''.obs; // New place filter
  final RxString salespersonFilter = ''.obs; // New salesperson filter
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isDataLoaded = false.obs;
  final RxBool isExporting = false.obs;

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
    fetchLeads();

    // Listen to search query changes with debounce
    debounce(
      searchQuery,
      (_) => filterLeads(),
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

  Future<void> fetchLeads() async {
    try {
      isLoading.value = true;
      QuerySnapshot leadSnapshot = await _firestore.collection('Leads').get();
      List<Map<String, dynamic>> tempLeads = [];
      Set<String> placesSet = <String>{};
      Set<String> salespeopleSet = <String>{};

      for (var doc in leadSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String? salesmanID = data['salesmanID'];
        final String salesmanName = await getSalesmanName(salesmanID);

        tempLeads.add({
          'address': data['address'] ?? '',
          'createdAt':
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'followUpDate':
              (data['followUpDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'isArchived': data['isArchived'] ?? false,
          'leadId': data['leadId'] ?? '',
          'name': data['name'] ?? '',
          'nos': data['nos'] ?? '',
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
      tempLeads.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));

      allLeads.value = tempLeads;

      // Update filter options
      availablePlaces.value = placesSet.toList()..sort();
      availableSalespeople.value = salespeopleSet.toList()..sort();

      filterLeads();
      isDataLoaded.value = true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch leads: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void filterLeads() {
    List<Map<String, dynamic>> filtered = allLeads.where((lead) {
      bool matches = true;

      if (statusFilter.value.isNotEmpty && statusFilter.value != 'All') {
        matches = matches && lead['status'] == statusFilter.value;
      }

      // Place filter
      if (placeFilter.value.isNotEmpty && placeFilter.value != 'All') {
        matches = matches && lead['place'] == placeFilter.value;
      }

      // Salesperson filter
      if (salespersonFilter.value.isNotEmpty &&
          salespersonFilter.value != 'All') {
        matches = matches && lead['salesman'] == salespersonFilter.value;
      }

      if (startDate.value != null) {
        matches = matches && lead['createdAt'].isAfter(startDate.value!);
      }

      if (endDate.value != null) {
        matches =
            matches &&
            lead['createdAt'].isBefore(
              endDate.value!.add(const Duration(days: 1)),
            );
      }

      if (searchQuery.value.isNotEmpty) {
        final query = searchQuery.value.toLowerCase();
        matches =
            matches &&
            (lead['name'].toString().toLowerCase().contains(query) ||
                lead['leadId'].toString().toLowerCase().contains(query) ||
                lead['phone1'].toString().toLowerCase().contains(query) ||
                lead['salesman'].toString().toLowerCase().contains(query) ||
                lead['place'].toString().toLowerCase().contains(query));
      }

      return matches;
    }).toList();

    filteredLeads.value = filtered;
    currentPage.value = 0;
    updatePagination();
  }

  void updatePagination() {
    totalPages.value = (filteredLeads.length / itemsPerPage).ceil();
    final startIndex = currentPage.value * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, filteredLeads.length);

    paginatedLeads.value = filteredLeads.sublist(startIndex, endIndex);
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
    filterLeads();
  }

  void setPlaceFilter(String? place) {
    placeFilter.value = place ?? '';
    filterLeads();
  }

  void setSalespersonFilter(String? salesperson) {
    salespersonFilter.value = salesperson ?? '';
    filterLeads();
  }

  void setDateRange(DateTimeRange? range) {
    startDate.value = range?.start;
    endDate.value = range?.end;
    filterLeads();
  }

  void clearFilters() {
    statusFilter.value = '';
    placeFilter.value = '';
    salespersonFilter.value = '';
    startDate.value = null;
    endDate.value = null;
    searchQuery.value = '';
    filterLeads();
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
      final sheet = excel['Leads'];

      final headers = [
        'Lead ID',
        'Name',
        'Address',
        'Place',
        'Phone1',
        'Phone2',
        'Product ID',
        'Salesman',
        'Status',
        'Created At',
        'Follow Up Date',
        'Nos',
        'Remark',
        'Archived',
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
        20,
        20,
        10,
        25,
        10,
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

      for (int rowIndex = 0; rowIndex < filteredLeads.length; rowIndex++) {
        final lead = filteredLeads[rowIndex];
        final rowData = [
          lead['leadId'] ?? '',
          lead['name'] ?? '',
          lead['address'] ?? '',
          lead['place'] ?? '',
          lead['phone1'] ?? '',
          lead['phone2'] ?? '',
          lead['productID'] ?? '',
          lead['salesman'] ?? '',
          lead['status'] ?? '',
          (lead['createdAt'] as DateTime?)?.toString().split('.')[0] ?? '',
          (lead['followUpDate'] as DateTime?)?.toString().split('.')[0] ?? '',
          lead['nos']?.toString() ?? '',
          lead['remark'] ?? '',
          (lead['isArchived'] ?? false) ? 'Yes' : 'No',
        ];

        for (int colIndex = 0; colIndex < rowData.length; colIndex++) {
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(
              columnIndex: colIndex,
              rowIndex: rowIndex + 1,
            ),
          );
          cell.value = TextCellValue(rowData[colIndex]);

          if (colIndex == 8) {
            final status = lead['status'];
            cell.cellStyle = CellStyle(
              backgroundColorHex: status == 'WARM'
                  ? ExcelColor.green200
                  : status == 'HOT'
                  ? ExcelColor.yellow200
                  : status == 'COLD'
                  ? ExcelColor.red200
                  : ExcelColor.white,
            );
          }

          if (colIndex == 13) {
            final isArchived = lead['isArchived'] ?? false;
            cell.cellStyle = CellStyle(
              backgroundColorHex: isArchived
                  ? ExcelColor.grey300
                  : ExcelColor.white,
            );
          }
        }
      }

      final summaryRow = filteredLeads.length + 2;
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow),
          )
          .value = TextCellValue(
        'Total Leads: ${filteredLeads.length}',
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
        '${downloadsDir.path}/leads_data_${DateTime.now().millisecondsSinceEpoch}.xlsx',
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

  Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'HOT':
        return Colors.red.shade100;
      case 'WARM':
        return Colors.orange.shade100;
      case 'COLD':
        return Colors.blue.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color getStatusTextColor(String status) {
    switch (status.toUpperCase()) {
      case 'HOT':
        return Colors.red.shade800;
      case 'WARM':
        return Colors.orange.shade800;
      case 'COLD':
        return Colors.blue.shade800;
      default:
        return Colors.grey.shade800;
    }
  }
}
