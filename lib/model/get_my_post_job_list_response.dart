import 'package:booking_system_flutter/model/pagination_model.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';

class GetPostJobResponse {
  Pagination? pagination;
  List<PostJobData>? myPostJobData;

  GetPostJobResponse({this.pagination, this.myPostJobData});

  GetPostJobResponse.fromJson(dynamic json) {
    pagination = json['pagination'] != null
        ? Pagination.fromJson(json['pagination'])
        : null;
    if (json['data'] != null) {
      myPostJobData = [];
      json['data'].forEach((v) {
        myPostJobData?.add(PostJobData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (pagination != null) {
      map['pagination'] = pagination?.toJson();
    }
    if (myPostJobData != null) {
      map['data'] = myPostJobData?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class PostJobData {
  num? id;
  String? title;
  String? description;
  String? reason;
  num? price;
  num? jobPrice;
  num? providerId;
  num? customerId;
  num? bookingId;
  String? status;
  bool? canBid;
  List<ServiceData>? service;
  String? createdAt;
  bool? pendingByCustomer;
  bool? pendingByProvider;
  bool? acceptedByCustomer;
  bool? rejectedByCustomer;
  String? statusNote;
  String? bidStatus;
  bool? isUrgentBooking;
  String? urgentBookingTime;
  String? extraCharges;

  PostJobData(
      {this.id,
      this.title,
      this.description,
      this.reason,
      this.price,
      this.jobPrice,
      this.providerId,
      this.customerId,
      this.bookingId,
      this.status,
      this.canBid,
      this.service,
      this.createdAt,
      this.pendingByCustomer,
      this.pendingByProvider,
      this.acceptedByCustomer,
      this.rejectedByCustomer,
      this.statusNote,
      this.bidStatus,
      this.isUrgentBooking,
      this.urgentBookingTime,
      this.extraCharges});

  PostJobData.fromJson(dynamic json) {
    id = json['id'];
    title = json['title'];
    description = json['description'];
    reason = json['reason'];
    price = json['price'];
    jobPrice = json['job_price'];
    providerId = json['provider_id'];
    customerId = json['customer_id'];
    bookingId = json['booking_id'];
    status = json['status'];
    canBid = json['can_bid'];
    createdAt = json['created_at'];
    if (json['service'] != null) {
      service = [];
      json['service'].forEach((v) {
        service?.add(ServiceData.fromJson(v));
      });
    }
    pendingByCustomer = json['pending_by_customer'];
    pendingByProvider = json['pending_by_provider'];
    acceptedByCustomer = json['accepted_by_customer'];
    rejectedByCustomer = json['rejected_by_customer'];
    statusNote = json['status_note'];
    bidStatus = json['bid_status'];
    isUrgentBooking = json['IsUrgentbooking'];
    urgentBookingTime = json['urgentBookingTime'];
    extraCharges = json['extraCharges']?.toString();
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['title'] = title;
    map['description'] = description;
    map['reason'] = reason;
    map['price'] = price;
    map['job_price'] = jobPrice;
    map['provider_id'] = providerId;
    map['customer_id'] = customerId;
    map['booking_id'] = bookingId;
    map['status'] = status;
    map['can_bid'] = canBid;
    map['pending_by_customer'] = pendingByCustomer;
    map['pending_by_provider'] = pendingByProvider;
    map['accepted_by_customer'] = acceptedByCustomer;
    map['rejected_by_customer'] = rejectedByCustomer;
    map['status_note'] = statusNote;
    map['bid_status'] = bidStatus;
    map['IsUrgentbooking'] = isUrgentBooking;
    map['urgentBookingTime'] = urgentBookingTime;
    map['extraCharges'] = extraCharges;
    if (service != null) {
      map['service'] = service?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class BidderData {
  int? id;
  int? postRequestId;
  int? providerId;
  num? price;
  num? offerPrice;
  String? duration;
  UserData? provider;
  String? status;
  String? bidStatus;

  BidderData(
      {this.id,
      this.postRequestId,
      this.providerId,
      this.price,
      this.offerPrice,
      this.duration,
      this.provider,
      this.status,
      this.bidStatus});

  BidderData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    postRequestId = json['post_request_id'];
    providerId = json['provider_id'];
    price = json['price'];
    offerPrice = json['counter_offer_price'];
    duration = json['duration'];
    provider = json['provider'] != null
        ? new UserData.fromJson(json['provider'])
        : null;
    status = json['status'];
    bidStatus = json['bid_status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['post_request_id'] = this.postRequestId;
    data['provider_id'] = this.providerId;
    data['price'] = this.price;
    data['counter_offer_price'] = this.offerPrice;
    data['duration'] = this.duration;
    if (this.provider != null) {
      data['provider'] = this.provider!.toJson();
    }
    data['status'] = this.status;
    data['bid_status'] = this.bidStatus;
    return data;
  }
}
