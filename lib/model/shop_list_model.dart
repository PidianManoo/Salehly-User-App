
class ShopListModel {
   Pagination? pagination;
   List<ShopListData>? data;

  ShopListModel({this.pagination, this.data});

  factory ShopListModel.fromJson(Map<String, dynamic> json) {
    return ShopListModel(
      pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null,
      data: json['data'] != null ? (json['data'] as List).map((i) => ShopListData.fromJson(i)).toList() : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    if (this.pagination != null) {
      data['pagination'] = this.pagination!.toJson();
    }
    return data;
  }
}

class Pagination {
  int totalItems;
  int perPage;
  int currentPage;
  int totalPages;
  int from;
  int to;
  dynamic nextPage;
  dynamic previousPage;

  Pagination({
    this.totalItems = -1,
    this.perPage = -1,
    this.currentPage = -1,
    this.totalPages = -1,
    this.from = -1,
    this.to = -1,
    this.nextPage,
    this.previousPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      totalItems: json['total_items'] is int ? json['total_items'] : -1,
      perPage: json['per_page'] is int ? json['per_page'] : -1,
      currentPage: json['currentPage'] is int ? json['currentPage'] : -1,
      totalPages: json['totalPages'] is int ? json['totalPages'] : -1,
      from: json['from'] is int ? json['from'] : -1,
      to: json['to'] is int ? json['to'] : -1,
      nextPage: json['next_page'],
      previousPage: json['previous_page'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_items': totalItems,
      'per_page': perPage,
      'currentPage': currentPage,
      'totalPages': totalPages,
      'from': from,
      'to': to,
      'next_page': nextPage,
      'previous_page': previousPage,
    };
  }
}

class ShopListData {
   int? id;
   String? name;
   String? description;
   String? businessRegistrationNumber;
   String? location;
   String? contactNumber;
   String? startTime;
   String? endTime;
   String? latitude;
   String? longitude;
   bool? status;
   String? deletedAt;
   List<ShopAttachment>? shopAttachment;
   String? providerName;
   String? profileImage;
   String? createdAt;
   String? updatedAt;

  ShopListData({
    this.id,
    this.name,
    this.description,
    this.businessRegistrationNumber,
    this.location,
    this.contactNumber,
    this.startTime,
    this.endTime,
    this.latitude,
    this.longitude,
    this.status,
    this.deletedAt,
    this.shopAttachment,
    this.providerName,
    this.profileImage,
    this.createdAt,
    this.updatedAt,
  });

  factory ShopListData.fromJson(Map<String, dynamic> json) {
    return ShopListData(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      businessRegistrationNumber: json['business_registration_number'],
      location: json['location'],
      contactNumber: json['contact_number'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      status: json['status'],
      deletedAt: json['deleted_at'],
      shopAttachment: json['shop_attachment'] != null ? (json['shop_attachment'] as List).map((i) => ShopAttachment.fromJson(i)).toList() : null,
      providerName: json['provider_name'],
      profileImage: json['profile_image'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

   Map<String, dynamic> toJson() {
     final Map<String, dynamic> data = new Map<String, dynamic>();
     data['id'] = this.id;
     data['name']  = this.name;
     data['description'] = this.description;
     data['business_registration_number']= this.businessRegistrationNumber;
     data['location'] = this.location;
     data['contact_number'] = this.contactNumber;
     data['start_time'] = this.startTime;
     data['end_time'] = this.endTime;
     data['latitude'] = this.latitude;
     data['longitude'] = this.longitude;
     data['status'] = this.status;
     data['deleted_at'] = this.deletedAt;
     if (this.shopAttachment != null) {
     data['shop_attachment'] = this.shopAttachment!.map((v) => v.toJson()).toList();
     }
    data['provider_name'] = this.providerName;
    data['profile_image'] = this.profileImage;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
     return data;
   }
}

class ShopAttachment {
  int? id;
  String? url;
  String? name;

  ShopAttachment({this.id, this.url, this.name});

  factory ShopAttachment.fromJson(Map<String, dynamic> json) {
    return ShopAttachment(
      id: json['id'],
      url: json['url'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['url'] = this.url;
    data['name'] = this.name;
    return data;
  }
}