class ShopDetailModel {
  bool? success;
  String? message;
  ShopData? data;

  ShopDetailModel({this.success, this.message, this.data});

  ShopDetailModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? new ShopData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class ShopData {
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
  String? createdAt;
  String? updatedAt;
  String? providerName;
  String? profileImage;

  ShopData(
      {this.id,
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
        this.createdAt,
        this.updatedAt,
        this.providerName,
        this.profileImage});

  ShopData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    businessRegistrationNumber = json['business_registration_number'];
    location = json['location'];
    contactNumber = json['contact_number'];
    startTime = json['start_time'];
    endTime = json['end_time'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    status = json['status'];
    deletedAt = json['deleted_at'];
    if (json['shop_attachment'] != null) {
      shopAttachment = <ShopAttachment>[];
      json['shop_attachment'].forEach((v) {
        shopAttachment!.add(new ShopAttachment.fromJson(v));
      });
    }
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    providerName =  json['provider_name'];
    profileImage = json['profile_image'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['description'] = this.description;
    data['business_registration_number'] = this.businessRegistrationNumber;
    data['location'] = this.location;
    data['contact_number'] = this.contactNumber;
    data['start_time'] = this.startTime;
    data['end_time'] = this.endTime;
    data['latitude'] = this.latitude;
    data['longitude'] = this.longitude;
    data['status'] = this.status;
    data['deleted_at'] = this.deletedAt;
    if (this.shopAttachment != null) {
      data['shop_attachment'] =
          this.shopAttachment!.map((v) => v.toJson()).toList();
    }
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['provider_name'] = this.providerName;
    data['profile_image'] = this.profileImage;
    return data;
  }
}

class ShopAttachment {
  int? id;
  String? url;
  String? name;

  ShopAttachment({this.id, this.url, this.name});

  ShopAttachment.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    url = json['url'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['url'] = this.url;
    data['name'] = this.name;
    return data;
  }
}