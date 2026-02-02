// Project imports:
import 'package:cv_tech/data/models/base/base_model.dart';
import 'package:cv_tech/core/utils/image_url_helper.dart';

class UserModel extends BaseModel {
  final String firstName;
  final String lastName;
  final String userName;
  final String email;
  final String? image;
  final String? cover;
  final String? bio;
  final String? city;
  final String? address;
  final String? professionalTitle;
  final int? postalCode;
  final String? phone;
  final String? website;
  final String? location;
  final int coins;
  final String? professionalStatus;
  final String? previousDomain;
  final String? currentDomain;
  final String? professionalCategory;
  final String? keywords;

  const UserModel({
    super.id,
    required this.firstName,
    required this.lastName,
    required this.userName,
    required this.email,
    this.image,
    this.cover,
    this.bio,
    this.city,
    this.address,
    this.professionalTitle,
    this.postalCode,
    this.phone,
    this.website,
    this.location,
    this.coins = 0,
    this.professionalStatus,
    this.previousDomain,
    this.currentDomain,
    this.professionalCategory,
    this.keywords,
  });

  String get fullName => '$firstName $lastName';
  
  /// Obtenir l'URL complète de l'image de profil (version synchrone avec cache)
  String? get imageUrl => ImageUrlHelper.getImageUrlSync(image, id);
  
  /// Obtenir l'URL complète de l'image de couverture (version synchrone avec cache)
  String? get coverUrl => ImageUrlHelper.getCoverUrlSync(cover, id);

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      if (value.isEmpty) return null;
      return int.tryParse(value);
    }
    return null;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString(),
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      userName: json['userName'] ?? '',
      email: json['email'] ?? '',
      image: json['image'],
      cover: json['cover'],
      bio: json['bio'],
      city: json['city'],
      address: json['adress'] ?? json['address'],
      professionalTitle: json['professionalTitle'],
      postalCode: _parseInt(json['postalCode']),
      phone: json['phone'],
      website: json['website'],
      location: json['location'],
      coins: _parseInt(json['coins']) ?? 0,
      professionalStatus: json['professionalStatus'],
      previousDomain: json['previousDomain'],
      currentDomain: json['currentDomain'],
      professionalCategory: json['professionalCategory'],
      keywords: json['keywords'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'firstName': firstName,
      'lastName': lastName,
      'userName': userName,
      'email': email,
      'image': image,
      'cover': cover,
      'bio': bio,
      'city': city,
      'adress': address,
      'professionalTitle': professionalTitle,
      'postalCode': postalCode,
      'phone': phone,
      'website': website,
      'location': location,
      'coins': coins,
      'professionalStatus': professionalStatus,
      'previousDomain': previousDomain,
      'currentDomain': currentDomain,
      'professionalCategory': professionalCategory,
      'keywords': keywords,
    };
  }

  UserModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? userName,
    String? email,
    String? image,
    String? cover,
    String? bio,
    String? city,
    String? address,
    String? professionalTitle,
    int? postalCode,
    String? phone,
    String? website,
    String? location,
    int? coins,
    String? professionalStatus,
    String? previousDomain,
    String? currentDomain,
    String? professionalCategory,
    String? keywords,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      image: image ?? this.image,
      cover: cover ?? this.cover,
      bio: bio ?? this.bio,
      city: city ?? this.city,
      address: address ?? this.address,
      professionalTitle: professionalTitle ?? this.professionalTitle,
      postalCode: postalCode ?? this.postalCode,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      location: location ?? this.location,
      coins: coins ?? this.coins,
      professionalStatus: professionalStatus ?? this.professionalStatus,
      previousDomain: previousDomain ?? this.previousDomain,
      currentDomain: currentDomain ?? this.currentDomain,
      professionalCategory: professionalCategory ?? this.professionalCategory,
      keywords: keywords ?? this.keywords,
    );
  }
}
