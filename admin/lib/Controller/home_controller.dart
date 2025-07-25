import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

class HomeController extends GetxController {
  RxInt totalsalescount = 0.obs;
  RxInt totalordercount = 0.obs;
  RxList<FlSpot> yearlySalesSpots = <FlSpot>[].obs;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    totalSalescount();
    totalOrdercount();
    fetchYearlySalesData();
  }

  //Count of Order Delivered
  Future<void> totalSalescount() async {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final firstDayOfNextMonth = DateTime(now.year, now.month + 1, 1);
    try {
      final totalsales = await _firestore
          .collection("Orders")
          .where('order_status', isEqualTo: "delivered")
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth),
          )
          .where(
            'createdAt',
            isLessThan: Timestamp.fromDate(firstDayOfNextMonth),
          )
          .get();
      totalsalescount.value = totalsales.size;
    } catch (e) {
      log("Error fetching monthly data: $e");
      SnackBar(content: Text(e.toString()));
    }
  }

  //count of Orders
  Future<void> totalOrdercount() async {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final firstDayOfNextMonth = DateTime(now.year, now.month + 1, 1);
    try {
      final totalsales = await _firestore
          .collection("Orders")
          .where('order_status', isNotEqualTo: "delivered") //  only inequality
          // .where('Cancel', isEqualTo: false) //  boolean exact match
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth),
          )
          .where(
            'createdAt',
            isLessThan: Timestamp.fromDate(firstDayOfNextMonth),
          )
          .get();

      totalordercount.value = totalsales.size;
    } catch (e) {
      log("Error fetching monthly data: $e");
      SnackBar(content: Text(e.toString()));
    }
  }

  Future<void> fetchYearlySalesData() async {
    try {
      final now = DateTime.now();
      final currentYear = now.year;
      List<FlSpot> tempSpots = [];

      for (int i = 1; i <= 12; i++) {
        final start = DateTime(currentYear, i, 1);
        final end = (i < 12)
            ? DateTime(currentYear, i + 1, 1)
            : DateTime(currentYear + 1, 1, 1);

        final snapshot = await _firestore
            .collection("Orders")
            .where('order_status', isEqualTo: 'delivered')
            .where(
              'createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start),
            )
            .where('createdAt', isLessThan: Timestamp.fromDate(end))
            .get();

        final count = snapshot.size.toDouble();
        tempSpots.add(FlSpot((i - 1).toDouble(), count)); // Always add
      }

      yearlySalesSpots.value = tempSpots;
    } catch (e) {
      log("Error fetching yearly sales data: $e");
    }
  }
}
