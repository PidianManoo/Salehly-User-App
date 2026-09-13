import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  String? uid;
  String? senderId;
  String? receiverId;
  String? photoUrl;
  List<String>? attachmentfiles;
  String? messageType;
  bool? isMe;
  bool? isMessageRead;
  String? message;
  int? createdAt;
  Timestamp? createdAtTime;
  Timestamp? updatedAtTime;
  DocumentReference? chatDocumentReference;

  // Offer message fields
  String? offerPrice;
  String? jobTitle;
  String? postRequestId;
  String? offerStatus;

  ChatMessageModel({
    this.uid,
    this.senderId,
    this.createdAtTime,
    this.updatedAtTime,
    this.receiverId,
    this.createdAt,
    this.message,
    this.isMessageRead,
    this.photoUrl,
    this.attachmentfiles,
    this.messageType,
    this.chatDocumentReference,
    this.offerPrice,
    this.jobTitle,
    this.postRequestId,
    this.offerStatus,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      uid: json['uid'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      message: json['message'],
      isMessageRead: json['isMessageRead'],
      photoUrl: json['photoUrl'],
      attachmentfiles: json['attachmentfiles'] is List ? List<String>.from(json['attachmentfiles'].map((x) => x)) : [],
      messageType: json['messageType'],
      createdAt: json['createdAt'],
      createdAtTime: json['createdAtTime'],
      updatedAtTime: json['updatedAtTime'],
      offerPrice: json['offerPrice']?.toString(),
      jobTitle: json['jobTitle']?.toString(),
      postRequestId: json['postRequestId']?.toString(),
      offerStatus: json['offerStatus']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.uid != null) data['uid'] = this.uid;
    if (this.createdAt != null) data['createdAt'] = this.createdAt;
    if (this.message != null) data['message'] = this.message;
    if (this.senderId != null) data['senderId'] = this.senderId;
    if (this.isMessageRead != null) data['isMessageRead'] = this.isMessageRead;
    if (this.receiverId != null) data['receiverId'] = this.receiverId;
    if (this.photoUrl != null) data['photoUrl'] = this.photoUrl;
    if (this.attachmentfiles != null) data['attachmentfiles'] = this.attachmentfiles?.map((e) => e).toList();
    if (this.createdAtTime != null) data['createdAtTime'] = this.createdAtTime;
    if (this.updatedAtTime != null) data['updatedAtTime'] = this.updatedAtTime;
    if (this.messageType != null) data['messageType'] = this.messageType;
    if (this.offerPrice != null) data['offerPrice'] = this.offerPrice;
    if (this.jobTitle != null) data['jobTitle'] = this.jobTitle;
    if (this.postRequestId != null) data['postRequestId'] = this.postRequestId;
    if (this.offerStatus != null) data['offerStatus'] = this.offerStatus;
    return data;
  }
}
