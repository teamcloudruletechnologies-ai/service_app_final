import 'dart:convert';

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
  final int? credits;

  // True if this account was just auto-created (name is empty)
  bool get needsOnboarding => name.trim().isEmpty;

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
    this.credits,
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
      credits: json['credits'] as int? ?? 0,
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

class SubServiceItem {
  final dynamic id;
  final String name;
  final double price;
  final int estimatedTime;
  final String? imageUrl;

  const SubServiceItem({
    required this.id,
    required this.name,
    required this.price,
    this.estimatedTime = 45,
    this.imageUrl,
  });

  factory SubServiceItem.fromJson(Map<String, dynamic> json) {
    final rawImg = json['image_url'] as String? ?? json['image'] as String?;
    return SubServiceItem(
      id: json['id'],
      name: json['name'] as String? ?? '',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : (double.tryParse(json['price']?.toString() ?? '0') ?? 0.0),
      estimatedTime: (json['estimated_time'] is num) ? (json['estimated_time'] as num).toInt() : (int.tryParse(json['estimated_time']?.toString() ?? '45') ?? 45),
      imageUrl: (rawImg != null && rawImg.trim().isNotEmpty) ? rawImg.trim() : null,
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
  final List<SubServiceItem> subServices;

  double get basePrice => price;

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
    this.subServices = const [],
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    List<SubServiceItem> parsedSubs = [];
    if (json['sub_services'] != null) {
      try {
        final raw = json['sub_services'];
        final List list = raw is String ? (raw.isNotEmpty ? List.from(jsonDecode(raw)) : []) : (raw is List ? raw : []);
        parsedSubs = list.map((e) => SubServiceItem.fromJson(Map<String, dynamic>.from(e))).toList();
      } catch (_) {}
    }

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
      subServices: parsedSubs,
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

class BannerItem {
  final int id;
  final String? title;
  final String imageUrl;
  final String? linkUrl;
  final String status;

  const BannerItem({
    required this.id,
    this.title,
    required this.imageUrl,
    this.linkUrl,
    required this.status,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      id: json['id'] as int,
      title: json['title'] as String?,
      imageUrl: json['image_url'] as String? ?? '',
      linkUrl: json['link_url'] as String?,
      status: json['status'] as String? ?? 'active',
    );
  }
}

class NearbyWorker {
  final int id;
  final String name;
  final String? serviceType;
  final int experienceYears;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final double? distance;
  final String? photoUrl;
  final double rating;

  const NearbyWorker({
    required this.id,
    required this.name,
    this.serviceType,
    required this.experienceYears,
    this.phone,
    this.latitude,
    this.longitude,
    this.distance,
    this.photoUrl,
    required this.rating,
  });

  factory NearbyWorker.fromJson(Map<String, dynamic> json) {
    return NearbyWorker(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      serviceType: json['service_type'] as String?,
      experienceYears: json['experience_years'] as int? ?? 0,
      phone: json['phone'] as String?,
      latitude: _toNullableDouble(json['current_lat']),
      longitude: _toNullableDouble(json['current_lng']),
      distance: _toNullableDouble(json['distance']),
      photoUrl: json['photo_url'] as String?,
      rating: _toDouble(json['rating'], 4.5),
    );
  }
}

class LocationPickerResult {
  final String address;
  final List<NearbyWorker> workers;
  final double? latitude;
  final double? longitude;

  const LocationPickerResult({
    required this.address,
    required this.workers,
    this.latitude,
    this.longitude,
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

class NotificationItem {
  final int id;
  final String title;
  final String message;
  final String? type;
  bool read;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    this.type,
    this.read = false,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String?,
      read: json['read'] == true,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

double? _toNullableDouble(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val);
  return null;
}

class SupportTicket {
  final int id;
  final String ticketNumber;
  final int userId;
  final int? bookingId;
  final int? categoryId;
  final String? categoryName;
  final String subject;
  final String description;
  final String status;
  final String priority;
  final String? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TicketMessage> messages;

  SupportTicket({
    required this.id,
    required this.ticketNumber,
    required this.userId,
    this.bookingId,
    this.categoryId,
    this.categoryName,
    required this.subject,
    required this.description,
    required this.status,
    required this.priority,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    List<TicketMessage> msgs = [];
    if (json['messages'] is List) {
      msgs = (json['messages'] as List)
          .map((m) => TicketMessage.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    return SupportTicket(
      id: json['id'] as int,
      ticketNumber: json['ticket_number'] as String? ?? 'SUP-000000',
      userId: json['user_id'] as int,
      bookingId: json['booking_id'] as int?,
      categoryId: json['category_id'] as int?,
      categoryName: json['category_name'] as String?,
      subject: json['subject'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'Open',
      priority: json['priority'] as String? ?? 'Medium',
      lastMessage: json['last_message'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
      messages: msgs,
    );
  }
}

class TicketMessage {
  final int id;
  final int ticketId;
  final String senderType;
  final int senderId;
  final String? senderName;
  final String message;
  final bool isInternalNote;
  final String? attachmentUrl;
  final DateTime createdAt;

  TicketMessage({
    required this.id,
    required this.ticketId,
    required this.senderType,
    required this.senderId,
    this.senderName,
    required this.message,
    this.isInternalNote = false,
    this.attachmentUrl,
    required this.createdAt,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'] as int,
      ticketId: json['ticket_id'] as int,
      senderType: json['sender_type'] as String? ?? 'user',
      senderId: json['sender_id'] as int,
      senderName: json['sender_display_name'] as String? ?? json['sender_name'] as String?,
      message: json['message'] as String? ?? '',
      isInternalNote: json['is_internal_note'] == true,
      attachmentUrl: json['attachment_url'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class SupportFaq {
  final int id;
  final String category;
  final String question;
  final String answer;
  final int sortOrder;

  SupportFaq({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
    this.sortOrder = 0,
  });

  factory SupportFaq.fromJson(Map<String, dynamic> json) {
    return SupportFaq(
      id: json['id'] as int,
      category: json['category'] as String? ?? 'General',
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}

class SupportPolicy {
  final int id;
  final String slug;
  final String title;
  final String content;
  final DateTime updatedAt;

  SupportPolicy({
    required this.id,
    required this.slug,
    required this.title,
    required this.content,
    required this.updatedAt,
  });

  factory SupportPolicy.fromJson(Map<String, dynamic> json) {
    return SupportPolicy(
      id: json['id'] as int,
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

