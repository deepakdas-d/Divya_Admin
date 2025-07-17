import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

class HomeController extends GetxController {
  RxInt totalsalescount = 0.obs;
  RxInt totalordercount = 0.obs;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    totalSalescount();
    totalOrdercount();
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
}
