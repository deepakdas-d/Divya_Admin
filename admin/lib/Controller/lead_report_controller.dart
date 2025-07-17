import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/widgets.dart' as pw;
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
  final RxString placeFilter = ''.obs;
  final RxString salespersonFilter = ''.obs;
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isDataLoaded = false.obs;
  final RxBool isExporting = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMoreData = true.obs;

  // Filter options
  final RxList<String> availablePlaces = <String>[].obs;
  final RxList<String> availableSalespeople = <String>[].obs;

  // Pagination and lazy loading variables
  final int itemsPerPage = 15;
  DocumentSnapshot? _lastDocument;
  final ScrollController scrollController = ScrollController();

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

    // Add scroll listener for infinite scrolling
    scrollController.addListener(_scrollListener);
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  void _scrollListener() {
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore.value &&
        hasMoreData.value) {
      fetchMoreLeads();
    }
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

  Future<void> fetchLeads({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        _lastDocument = null;
        allLeads.clear();
        hasMoreData.value = true;
      }

      isLoading.value = true;
      Query<Map<String, dynamic>> query = _firestore
          .collection('Leads')
          .orderBy('createdAt', descending: true)
          .limit(itemsPerPage);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      QuerySnapshot<Map<String, dynamic>> leadSnapshot = await query.get();

      if (leadSnapshot.docs.isEmpty) {
        hasMoreData.value = false;
        isLoading.value = false;
        return;
      }

      List<Map<String, dynamic>> tempLeads = [];
      Set<String> placesSet = <String>{};
      Set<String> salespeopleSet = <String>{};

      for (var doc in leadSnapshot.docs) {
        final data = doc.data();
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
          'customerId': data['customerId'],
        });

        final place = data['place']?.toString().trim();
        if (place != null && place.isNotEmpty) {
          placesSet.add(place);
        }
        if (salesmanName.isNotEmpty && salesmanName != 'N/A') {
          salespeopleSet.add(salesmanName);
        }
      }

      _lastDocument = leadSnapshot.docs.last;
      allLeads.addAll(tempLeads);

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

  Future<void> fetchMoreLeads() async {
    if (!hasMoreData.value || isLoadingMore.value) return;

    try {
      isLoadingMore.value = true;
      await fetchLeads();
    } finally {
      isLoadingMore.value = false;
    }
  }

  void filterLeads() {
    List<Map<String, dynamic>> filtered = allLeads.where((lead) {
      bool matches = true;

      if (statusFilter.value.isNotEmpty && statusFilter.value != 'All') {
        matches = matches && lead['status'] == statusFilter.value;
      }

      if (placeFilter.value.isNotEmpty && placeFilter.value != 'All') {
        matches = matches && lead['place'] == placeFilter.value;
      }

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
    paginatedLeads.value = filtered;
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
        'CustomerID',
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
          lead['customerId'] ?? "",
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

  Future<void> exportToPdf() async {
    try {
      final hasPermission = await checkStoragePermission();
      if (!hasPermission) return;

      final pdf = pw.Document();

      for (var lead in filteredLeads) {
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
                  _pdfRow('Lead ID', lead['leadId'] ?? ''),
                  _pdfRow('Name', lead['name'] ?? ''),
                  _pdfRow('CustomerID', lead['customerId'] ?? ''),
                  _pdfRow('Primary Phone', lead['phone1'] ?? ''),
                  if (lead['phone2'] != null &&
                      lead['phone2'].toString().isNotEmpty)
                    _pdfRow('Secondary Phone', lead['phone2']),
                  _pdfRow('Address', lead['address'] ?? ''),
                  _pdfRow('Place', lead['place'] ?? ''),
                  _pdfRow('Product ID', lead['productID'] ?? ''),
                  _pdfRow('Salesman', lead['salesman'] ?? ''),
                  _pdfRow('Status', lead['status'] ?? ''),
                  _pdfRow(
                    'Created At',
                    (lead['createdAt'] as DateTime?)?.toString().split(
                          '.',
                        )[0] ??
                        '',
                  ),
                  _pdfRow(
                    'Follow Up Date',
                    (lead['followUpDate'] as DateTime?)?.toString().split(
                          '.',
                        )[0] ??
                        '',
                  ),
                  _pdfRow('Nos', lead['nos']?.toString() ?? ''),
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
                  _pdfRow(
                    'Archived',
                    (lead['isArchived'] ?? false) ? 'Yes' : 'No',
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Add summary page
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Summary',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text('Total Leads: ${filteredLeads.length}'),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Generated on: ${DateTime.now().toString().split('.')[0]}',
                ),
              ],
            ),
          ),
        ),
      );

      final dir = Directory('/storage/emulated/0/Download');
      final file = File(
        '${dir.path}/leads_data_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      Get.snackbar(
        'Success',
        'Leads PDF exported to Downloads folder',
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
