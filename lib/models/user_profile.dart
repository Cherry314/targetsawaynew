// lib/models/user_profile.dart

class UserProfile {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final List<String> clubs;
  final Map<String, DateTime> clubRenewalDates;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  UserProfile({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.clubs,
    Map<String, DateTime>? clubRenewalDates,
    required this.createdAt,
    this.lastLoginAt,
  }) : clubRenewalDates = _normalizeClubRenewalDates(
          clubs,
          clubRenewalDates,
          createdAt,
        );

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'clubs': clubs,
        'clubRenewalDates': clubRenewalDates.map(
          (club, date) => MapEntry(club, date.toIso8601String()),
        ),
        'createdAt': createdAt.toIso8601String(),
        'lastLoginAt': lastLoginAt?.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['createdAt'] as String);
    final clubs = (json['clubs'] as List<dynamic>).cast<String>();

    return UserProfile(
      uid: json['uid'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      clubs: clubs,
      clubRenewalDates: _parseClubRenewalDates(json['clubRenewalDates']),
      createdAt: createdAt,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
    );
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    List<String>? clubs,
    Map<String, DateTime>? clubRenewalDates,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      clubs: clubs ?? this.clubs,
      clubRenewalDates: clubRenewalDates ?? this.clubRenewalDates,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  static Map<String, DateTime> _parseClubRenewalDates(dynamic value) {
    if (value is! Map) return {};

    final parsedDates = <String, DateTime>{};
    value.forEach((key, rawDate) {
      final clubName = key?.toString();
      if (clubName == null || clubName.trim().isEmpty) return;

      if (rawDate is DateTime) {
        parsedDates[clubName] = rawDate;
      } else if (rawDate is String) {
        final parsed = DateTime.tryParse(rawDate);
        if (parsed != null) parsedDates[clubName] = parsed;
      }
    });

    return parsedDates;
  }

  static Map<String, DateTime> _normalizeClubRenewalDates(
    List<String> clubs,
    Map<String, DateTime>? renewalDates,
    DateTime fallbackDate,
  ) {
    final normalizedDates = <String, DateTime>{};
    for (final club in clubs) {
      normalizedDates[club] = renewalDates?[club] ?? fallbackDate;
    }
    return normalizedDates;
  }
}
