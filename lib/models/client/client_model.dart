class ClientModel {
  final String uid;
  final String name;
  final String? phone;
  final String? profileImageBase64;

  const ClientModel({
    required this.uid,
    required this.name,
    this.phone,
    this.profileImageBase64,
  });

  /// Firestore: clients/{uid}
  /// Supports different possible field names to avoid crashes if your schema differs slightly.
  factory ClientModel.fromFirestore(String uid, Map<String, dynamic> data) {
    String pickName() {
      final candidates = [
        data['name'],
        data['fullName'],
        data['displayName'],
        data['clientName'],
      ];
      for (final v in candidates) {
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return 'Client';
    }

    String? pickPhone() {
      final v = data['phone'];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      return null;
    }

    String? pickProfileImage() {
      final candidates = [
        data['profileImageBase64'],
        data['profileImage'],
        data['avatarBase64'],
      ];
      for (final v in candidates) {
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return null;
    }

    return ClientModel(
      uid: uid,
      name: pickName(),
      phone: pickPhone(),
      profileImageBase64: pickProfileImage(),
    );
  }
}
