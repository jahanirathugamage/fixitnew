class ProviderDetailsModel {
  final String providerUid;

  final String firstName;
  final String lastName;

  final List<EducationItem> education;
  final List<CertificationItem> certifications;
  final List<JobExperienceItem> jobExperience;

  final int? yearsExperience;
  final String? mainSkillName;

  final double? rating;
  final double? cancellationPercent;

  // Needed for conditional sections + avatar
  final List<String> languages;
  final List<String> categories;
  final String? profileImageBase64;

  ProviderDetailsModel({
    required this.providerUid,
    required this.firstName,
    required this.lastName,
    required this.education,
    required this.certifications,
    required this.jobExperience,
    required this.yearsExperience,
    required this.mainSkillName,
    required this.rating,
    required this.cancellationPercent,
    required this.languages,
    required this.categories,
    required this.profileImageBase64,
  });

  String get fullName => ('$firstName $lastName').trim().isEmpty
      ? 'Service Provider'
      : ('$firstName $lastName').trim();

  static ProviderDetailsModel fromFirestore(
    String uid,
    Map<String, dynamic> data,
  ) {
    final firstName = (data['firstName'] ?? '').toString().trim();
    final lastName = (data['lastName'] ?? '').toString().trim();

    final skill0 = _firstSkillMap(data['skills']);

    final yearsExperience = _toIntNullable(skill0?['experience']);
    final mainSkillNameRaw = (skill0?['name'] ?? '').toString().trim();
    final mainSkillName = mainSkillNameRaw.isEmpty ? null : mainSkillNameRaw;

    final education = _readListMap(skill0?['education'])
        .map(EducationItem.fromMap)
        .toList();

    final certifications = _readListMap(skill0?['certifications'])
        .map(CertificationItem.fromMap)
        .toList();

    final jobExperience = _readListMap(skill0?['jobExperience'])
        .map(JobExperienceItem.fromMap)
        .toList();

    final rating = _toDoubleNullable(data['rating'] ?? data['avgRating']);
    final cancellationPercent = _toDoubleNullable(
      data['cancellationPercent'] ?? data['cancellationRate'],
    );

    final languages = (data['languages'] is List)
        ? (data['languages'] as List)
            .map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList()
        : <String>[];

    final categories = (data['categories'] is List)
        ? (data['categories'] as List)
            .map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList()
        : <String>[];

    final profileImageBase64 = (data['profileImageBase64'] ?? '').toString().trim();
    final profileImageBase64OrNull =
        profileImageBase64.isEmpty ? null : profileImageBase64;

    return ProviderDetailsModel(
      providerUid: uid,
      firstName: firstName,
      lastName: lastName,
      education: education,
      certifications: certifications,
      jobExperience: jobExperience,
      yearsExperience: yearsExperience,
      mainSkillName: mainSkillName,
      rating: rating,
      cancellationPercent: cancellationPercent,
      languages: languages,
      categories: categories,
      profileImageBase64: profileImageBase64OrNull,
    );
  }

  static Map<String, dynamic>? _firstSkillMap(dynamic v) {
    if (v is List && v.isNotEmpty && v.first is Map) {
      final m = v.first as Map;
      return m.map((k, val) => MapEntry(k.toString(), val));
    }
    return null;
  }

  static List<Map<String, dynamic>> _readListMap(dynamic v) {
    if (v is List) {
      return v
          .whereType<Map>()
          .map((m) => m.map((k, val) => MapEntry(k.toString(), val)))
          .toList();
    }
    return [];
  }

  static int? _toIntNullable(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? _toDoubleNullable(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

class EducationItem {
  final String institutionName;
  final String fieldOfStudy;
  final String startDate;
  final String endDate;

  EducationItem({
    required this.institutionName,
    required this.fieldOfStudy,
    required this.startDate,
    required this.endDate,
  });

  factory EducationItem.fromMap(Map<String, dynamic> m) {
    return EducationItem(
      institutionName: (m['institutionName'] ?? '').toString(),
      fieldOfStudy: (m['fieldOfStudy'] ?? '').toString(),
      startDate: (m['startDate'] ?? '').toString(),
      endDate: (m['endDate'] ?? '').toString(),
    );
  }

  String get period {
    final s = startDate.trim();
    final e = endDate.trim();
    if (s.isEmpty && e.isEmpty) return '';
    if (s.isNotEmpty && e.isNotEmpty) return '$s - $e';
    return s.isNotEmpty ? s : e;
  }
}

class CertificationItem {
  final String title;
  final String issuer;
  final String issued;

  CertificationItem({
    required this.title,
    required this.issuer,
    required this.issued,
  });

  factory CertificationItem.fromMap(Map<String, dynamic> m) {
    final title = (m['title'] ?? m['name'] ?? m['certificationName'] ?? '')
        .toString();
    final issuer =
        (m['issuer'] ?? m['institutionName'] ?? m['issuedBy'] ?? '').toString();
    final issued = (m['issued'] ?? m['issuedDate'] ?? m['year'] ?? '').toString();

    return CertificationItem(
      title: title,
      issuer: issuer,
      issued: issued,
    );
  }
}

class JobExperienceItem {
  final String companyName;
  final String position;
  final String startDate;
  final String endDate;

  JobExperienceItem({
    required this.companyName,
    required this.position,
    required this.startDate,
    required this.endDate,
  });

  factory JobExperienceItem.fromMap(Map<String, dynamic> m) {
    return JobExperienceItem(
      companyName: (m['companyName'] ?? '').toString(),
      position: (m['position'] ?? '').toString(),
      startDate: (m['startDate'] ?? '').toString(),
      endDate: (m['endDate'] ?? '').toString(),
    );
  }

  String get period {
    final s = startDate.trim();
    final e = endDate.trim();
    if (s.isEmpty && e.isEmpty) return '';
    if (s.isNotEmpty && e.isNotEmpty) return '$s - $e';
    return s.isNotEmpty ? s : e;
  }
}
  