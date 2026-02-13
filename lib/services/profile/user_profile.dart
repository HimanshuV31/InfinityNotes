import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String firstName;
  final String? lastName;
  final String? photoUrl;
  final String? dob;    // yyyy-MM-dd
  final String? gender; // 'male' | 'female' | 'other' | 'prefer_not_to_say'

  const UserProfile({
    required this.firstName,
    this.lastName,
    this.photoUrl,
    this.dob,
    this.gender,
  });

  factory UserProfile.empty() => const UserProfile(firstName: '');

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      firstName: (map['firstName'] as String?)?.trim() ?? '',
      lastName: (map['lastName'] as String?)?.trim(),
      photoUrl: map['photoUrl'] as String?,
      dob: map['dob'] as String?,
      gender: map['gender'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName.trim(),
      if (lastName != null && lastName!.trim().isNotEmpty)
        'lastName': lastName!.trim(),
      if (photoUrl != null && photoUrl!.isNotEmpty) 'photoUrl': photoUrl,
      if (dob != null && dob!.isNotEmpty) 'dob': dob,
      if (gender != null && gender!.isNotEmpty) 'gender': gender,
    };
  }

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? photoUrl,
    String? dob,
    String? gender,
  }) {
    return UserProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      photoUrl: photoUrl ?? this.photoUrl,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
    );
  }

  @override
  List<Object?> get props => [firstName, lastName, photoUrl, dob, gender];
}
extension UserProfileNameX on UserProfile {
  String get fullName {
    if (lastName == null || lastName!.trim().isEmpty) {
      return firstName;
    }
    return '$firstName ${lastName!.trim()}';
  }
}
