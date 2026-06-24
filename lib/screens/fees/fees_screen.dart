import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../models/fee_model.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  bool _isProcessing = false;

  Future<void> _handlePayment(String uid, DatabaseService db, double amount) async {
    setState(() => _isProcessing = true);
    try {
      await db.processPayment(uid, amount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment Successful!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment Failed"), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<UserAuthProvider>(context);
    final db = DatabaseService();
    final student = auth.studentModel;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: _ambientGlow(const Color(0xFFFF5252).withOpacity(0.1), 300),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: StreamBuilder<FeeModel>(
                    stream: (student?.uid == null || student!.uid.startsWith('debug'))
                        ? Stream.value(FeeModel(totalFees: 50000, paidAmount: 0, monthlyAmount: 5000))
                        : db.getFees(student.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFFFF5252)));
                      }
                      
                      final fees = snapshot.data ?? FeeModel(totalFees: 50000, paidAmount: 0, monthlyAmount: 5000);

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. PAYMENT ACTION CARD
                            _buildPaymentActionCard(student?.uid ?? '', db, fees),
                            
                            const SizedBox(height: 10),
                            if (fees.isDueSoon) _buildDueAlert(fees),
                            
                            const Padding(
                              padding: EdgeInsets.fromLTRB(5, 30, 0, 15),
                              child: Text(
                                "PAYMENT HISTORY",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            
                            // 2. TRANSACTION LOG
                            fees.history.isEmpty
                                ? _buildEmptyState()
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: fees.history.length,
                                    itemBuilder: (context, index) {
                                      return _buildTransactionTile(fees.history[index]);
                                    },
                                  ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          ),
          const Text(
            "Fees & Payments",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildDueAlert(FeeModel fees) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEB),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFFF5252).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Upcoming Due",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFFD32F2F)),
                ),
                Text(
                  "Installment of ₹${fees.monthlyAmount} is due on ${DateFormat('MMM d').format(fees.nextDueDate!)}",
                  style: TextStyle(color: Colors.red[900], fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentActionCard(String uid, DatabaseService db, FeeModel fees) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Colors.black, Color(0xFFFF5252)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.5, 0.5],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          children: [
            const Text(
              "OUTSTANDING BALANCE",
              style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Text(
              "₹${fees.remainingAmount.toStringAsFixed(0)}",
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: -1),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("MONTHLY FEE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey)),
                    Text("₹${fees.monthlyAmount.toStringAsFixed(0)}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black)),
                  ],
                ),
                ElevatedButton(
                  onPressed: _isProcessing ? null : () => _handlePayment(uid, db, fees.monthlyAmount),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    elevation: 10,
                    shadowColor: Colors.black.withOpacity(0.4),
                  ),
                  child: _isProcessing 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("PAY NOW", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(PaymentHistory h) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Paid ₹${h.amount.toStringAsFixed(0)}",
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                Text(
                  DateFormat('MMM d, yyyy • hh:mm a').format(h.date),
                  style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w600),
                ),
                Text(
                  "ID: ${h.transactionId}",
                  style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Text(
            "SUCCESS",
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.history_rounded, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 15),
          Text(
            "No payments recorded yet.",
            style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _ambientGlow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}
