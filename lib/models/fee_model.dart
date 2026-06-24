class FeeModel {
  final double totalFees;
  final double paidAmount;
  final List<PaymentHistory> history;
  final DateTime? nextDueDate;
  final double monthlyAmount;

  FeeModel({
    required this.totalFees,
    required this.paidAmount,
    this.history = const [],
    this.nextDueDate,
    this.monthlyAmount = 0.0,
  });

  double get remainingAmount => totalFees - paidAmount;

  bool get isDueSoon {
    if (nextDueDate == null) return false;
    final now = DateTime.now();
    final difference = nextDueDate!.difference(now).inDays;
    return difference >= 0 && difference <= 5; // Alert if due in 5 days
  }

  Map<String, dynamic> toMap() {
    return {
      'totalFees': totalFees,
      'paidAmount': paidAmount,
      'history': history.map((e) => e.toMap()).toList(),
      'nextDueDate': nextDueDate?.toIso8601String(),
      'monthlyAmount': monthlyAmount,
    };
  }

  factory FeeModel.fromMap(Map<String, dynamic> map) {
    return FeeModel(
      totalFees: (map['totalFees'] ?? 0.0).toDouble(),
      paidAmount: (map['paidAmount'] ?? 0.0).toDouble(),
      history: (map['history'] as List? ?? [])
          .map((e) => PaymentHistory.fromMap(e))
          .toList(),
      nextDueDate: map['nextDueDate'] != null ? DateTime.parse(map['nextDueDate']) : null,
      monthlyAmount: (map['monthlyAmount'] ?? 0.0).toDouble(),
    );
  }
}

class PaymentHistory {
  final double amount;
  final DateTime date;
  final String transactionId;
  final String status; // Success, Pending, Failed

  PaymentHistory({
    required this.amount,
    required this.date,
    required this.transactionId,
    this.status = 'Success',
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'date': date.toIso8601String(),
      'transactionId': transactionId,
      'status': status,
    };
  }

  factory PaymentHistory.fromMap(Map<String, dynamic> map) {
    return PaymentHistory(
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: DateTime.parse(map['date']),
      transactionId: map['transactionId'] ?? '',
      status: map['status'] ?? 'Success',
    );
  }
}
