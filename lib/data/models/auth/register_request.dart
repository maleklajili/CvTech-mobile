class RegisterRequest {
  final String firstName;
  final String lastName;
  final String userName;
  final String email;
  final String password;
  final String? bio;
  final String? city;
  final String? address;
  final String? professionalTitle;
  final int? postalCode;
  final String? phone;
  final String? website;
  final String? location;

  const RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.userName,
    required this.email,
    required this.password,
    this.bio,
    this.city,
    this.address,
    this.professionalTitle,
    this.postalCode,
    this.phone,
    this.website,
    this.location,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'userName': userName,
      'email': email,
      'password': password,
      'bio': bio ?? '',
      'city': city ?? '',
      'adress': address ?? '',
      'professionalTitle': professionalTitle ?? '',
      'postalCode': postalCode ?? 0,
      'phone': phone ?? '',
      'website': website ?? '',
      'location': location ?? '',
      'fullName': '$firstName $lastName',
      'coins': 0,
    };
  }
}
