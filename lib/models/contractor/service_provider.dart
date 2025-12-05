class ServiceProviderModel {
  final String id;
  final String firstName;
  final String lastName;
  final String gender;
  final String email;
  final String phone;
  final String address1;
  final String address2;
  final String city;
  final List<String> languages;
  final List<String> skills;
  final String? profileImageUrl;

  ServiceProviderModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.email,
    required this.phone,
    required this.address1,
    required this.address2,
    required this.city,
    required this.languages,
    required this.skills,
    this.profileImageUrl,
  });

  factory ServiceProviderModel.fromFirestore(
      String id, Map<String, dynamic> data) {
    return ServiceProviderModel(
      id: id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      gender: data['gender'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      address1: data['address1'] ?? '',
      address2: data['address2'] ?? '',
      city: data['city'] ?? '',
      languages: List<String>.from(data['languages'] ?? []),
      skills: (data['skills'] ?? [])
          .map<String>((e) => e['skill'].toString())
          .toList(),
      profileImageUrl: data['profileImage'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "firstName": firstName,
      "lastName": lastName,
      "gender": gender,
      "email": email,
      "phone": phone,
      "address1": address1,
      "address2": address2,
      "city": city,
      "languages": languages,
      "skills": skills.map((e) => {"skill": e}).toList(),
      "updatedAt": DateTime.now(),
    };
  }
}
