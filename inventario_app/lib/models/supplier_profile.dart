class SupplierProfile {
  final int providerId;
  final String? contactName;
  final String? email;
  final String? address;
  final String? notes;

  SupplierProfile({
    required this.providerId,
    this.contactName,
    this.email,
    this.address,
    this.notes,
  });

  factory SupplierProfile.fromJson(Map<String, dynamic> json) {
    return SupplierProfile(
      providerId: (json['provider_id'] as num?)?.toInt() ?? 0,
      contactName: json['contact_name'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider_id': providerId,
      'contact_name': contactName,
      'email': email,
      'address': address,
      'notes': notes,
    };
  }
}
