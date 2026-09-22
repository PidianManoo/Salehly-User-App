class RefundRequestData {
  int? id;
  int? bookingId;
  String? serviceName;
  String? reason;
  num? refundAmount;
  String? status;
  String? rejectReason;
  String? createdAt;

  RefundRequestData({
    this.id,
    this.bookingId,
    this.serviceName,
    this.reason,
    this.refundAmount,
    this.status,
    this.rejectReason,
    this.createdAt,
  });

  RefundRequestData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    bookingId = json['booking_id'];
    serviceName = json['service_name'];
    reason = json['reason'];
    refundAmount = json['refund_amount'];
    status = json['request_status'];
    rejectReason = json['reject_reason'];
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['booking_id'] = bookingId;
    data['service_name'] = serviceName;
    data['reason'] = reason;
    data['refund_amount'] = refundAmount;
    data['request_status'] = status;
    data['reject_reason'] = rejectReason;
    data['created_at'] = createdAt;
    return data;
  }
}
