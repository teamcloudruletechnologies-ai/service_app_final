class UserAccount {
  final int id;
  final String role;
  final String name;
  final String? email;
  final String? phone;
  final String status;
  // Worker-specific fields
  final String? kycStatus;
  final String? serviceType;
  final int? experienceYears;
  final String? city;
  final String? pincode;
  final String? state;
  final String? address;
  final double? rating;

  // True if this account was just auto-created or is missing operational details
  bool get needsOnboarding =>
      name.trim().isEmpty ||
      (role == 'worker' &&
          (serviceType == null ||
              serviceType!.trim().isEmpty));

  const UserAccount({
    required this.id,
    required this.role,
    required this.name,
    this.email,
    this.phone,
    required this.status,
    this.kycStatus,
    this.serviceType,
    this.experienceYears,
    this.city,
    this.pincode,
    this.state,
    this.address,
    this.rating,
  });

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['id'] as int,
      role: json['role'] as String? ?? 'user',
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      status: json['status'] as String? ?? 'active',
      kycStatus: json['kyc_status'] as String? ?? json['kycStatus'] as String?,
      serviceType: json['service_type'] as String? ?? json['serviceType'] as String?,
      experienceYears: json['experience_years'] as int? ?? json['experienceYears'] as int?,
      city: json['city'] as String?,
      pincode: json['pincode'] as String?,
      state: json['state'] as String?,
      address: json['address'] as String?,
      rating: _toDouble(json['rating'], 4.5),
    );
  }
}

class ServiceCategory {
  final int id;
  final String name;
  final String? description;
  final String? iconUrl;
  final String status;

  const ServiceCategory({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    required this.status,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
      status: json['status'] as String? ?? 'active',
    );
  }
}

class ServiceItem {
  final int id;
  final int? categoryId;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? categoryName;
  final double price;
  final String status;
  final double avgRating;
  final int totalReviews;
  final int totalBookings;
  final int estimatedTime;

  const ServiceItem({
    required this.id,
    this.categoryId,
    required this.name,
    this.description,
    this.imageUrl,
    this.categoryName,
    required this.price,
    required this.status,
    this.avgRating = 4.5,
    this.totalReviews = 0,
    this.totalBookings = 0,
    this.estimatedTime = 60,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'] as int,
      categoryId: json['category_id'] as int?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      categoryName: json['category_name'] as String?,
      price: _toDouble(json['price']),
      status: json['status'] as String? ?? 'active',
      avgRating: _toDouble(json['avg_rating'], 4.5),
      totalReviews: json['total_reviews'] as int? ?? 0,
      totalBookings: json['total_bookings'] as int? ?? 0,
      estimatedTime: json['estimated_time'] as int? ?? 60,
    );
  }
}

class BookingItem {
  final int id;
  final int? serviceId;
  final String? serviceName;
  final String? serviceImage;
  final String? workerName;
  final String? workerPhone;
  final String? serviceType;
  final String? userName;
  final String? userPhone;
  final String status;
  final double amount;
  final String? address;
  final String? notes;
  final DateTime? scheduledAt;
  final DateTime createdAt;
  final String? otp;
  final double? workerLat;
  final double? workerLng;
  final double? latitude;
  final double? longitude;

  const BookingItem({
    required this.id,
    this.serviceId,
    this.serviceName,
    this.serviceImage,
    this.workerName,
    this.workerPhone,
    this.serviceType,
    this.userName,
    this.userPhone,
    required this.status,
    required this.amount,
    this.address,
    this.notes,
    this.scheduledAt,
    required this.createdAt,
    this.otp,
    this.workerLat,
    this.workerLng,
    this.latitude,
    this.longitude,
  });

  factory BookingItem.fromJson(Map<String, dynamic> json) {
    return BookingItem(
      id: json['id'] as int,
      serviceId: json['service_id'] as int?,
      serviceName: json['service_name'] as String?,
      serviceImage: json['service_image'] as String?,
      workerName: json['worker_name'] as String?,
      workerPhone: json['worker_phone'] as String?,
      serviceType: json['service_type'] as String?,
      userName: json['user_name'] as String?,
      userPhone: json['user_phone'] as String?,
      status: json['status'] as String? ?? 'pending',
      amount: _toDouble(json['amount']),
      address: json['address'] as String?,
      notes: json['notes'] as String?,
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'] as String)
          : null,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      otp: json['otp']?.toString(),
      workerLat: _toDouble(json['worker_lat']),
      workerLng: _toDouble(json['worker_lng']),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
    );
  }

  bool get canCancel => status == 'pending' || status == 'confirmed';
}

class PagedResult<T> {
  final List<T> items;
  final int total;
  final int page;
  final int limit;

  const PagedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });
}

class ReviewItem {
  final int id;
  final int bookingId;
  final int userId;
  final String userName;
  final int workerId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const ReviewItem({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.userName,
    required this.workerId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    return ReviewItem(
      id: json['id'] as int,
      bookingId: json['booking_id'] as int,
      userId: json['user_id'] as int,
      userName: json['user_name'] as String? ?? 'User',
      workerId: json['worker_id'] as int,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

double _toDouble(dynamic val, [double defaultValue = 0.0]) {
  if (val == null) return defaultValue;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? defaultValue;
  return defaultValue;
}
