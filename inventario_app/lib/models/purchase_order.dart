enum PurchaseOrderStatus { draft, requested, received, cancelled }

extension PurchaseOrderStatusX on PurchaseOrderStatus {
  String get code {
    switch (this) {
      case PurchaseOrderStatus.draft:
        return 'draft';
      case PurchaseOrderStatus.requested:
        return 'requested';
      case PurchaseOrderStatus.received:
        return 'received';
      case PurchaseOrderStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case PurchaseOrderStatus.draft:
        return 'Borrador';
      case PurchaseOrderStatus.requested:
        return 'Solicitada';
      case PurchaseOrderStatus.received:
        return 'Recibida';
      case PurchaseOrderStatus.cancelled:
        return 'Cancelada';
    }
  }
}

PurchaseOrderStatus purchaseOrderStatusFromCode(String? code) {
  switch (code) {
    case 'requested':
      return PurchaseOrderStatus.requested;
    case 'received':
      return PurchaseOrderStatus.received;
    case 'cancelled':
      return PurchaseOrderStatus.cancelled;
    case 'draft':
    default:
      return PurchaseOrderStatus.draft;
  }
}

class PurchaseOrder {
  final String id;
  final int providerId;
  final String title;
  final String? details;
  final int units;
  final double amount;
  final PurchaseOrderStatus status;
  final DateTime createdAt;
  final DateTime? expectedAt;

  PurchaseOrder({
    required this.id,
    required this.providerId,
    required this.title,
    this.details,
    required this.units,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.expectedAt,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      id: json['id'] as String? ?? '',
      providerId: (json['provider_id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? 'Orden',
      details: json['details'] as String?,
      units: (json['units'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: purchaseOrderStatusFromCode(json['status'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      expectedAt: json['expected_at'] != null
          ? DateTime.parse(json['expected_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider_id': providerId,
      'title': title,
      'details': details,
      'units': units,
      'amount': amount,
      'status': status.code,
      'created_at': createdAt.toIso8601String(),
      'expected_at': expectedAt?.toIso8601String(),
    };
  }

  PurchaseOrder copyWith({
    String? id,
    int? providerId,
    String? title,
    String? details,
    int? units,
    double? amount,
    PurchaseOrderStatus? status,
    DateTime? createdAt,
    DateTime? expectedAt,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      title: title ?? this.title,
      details: details ?? this.details,
      units: units ?? this.units,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expectedAt: expectedAt ?? this.expectedAt,
    );
  }
}
