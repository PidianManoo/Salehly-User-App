class InitiatePaymentResponse {
  final bool isSuccess;
  final String message;
  final List<String>? validationErrors;
  final PaymentData? data;

  InitiatePaymentResponse({
    required this.isSuccess,
    required this.message,
    this.validationErrors,
    this.data,
  });

  factory InitiatePaymentResponse.fromJson(Map<String, dynamic> json) {
    return InitiatePaymentResponse(
      isSuccess: json['IsSuccess'] ?? false,
      message: json['Message'] ?? '',
      validationErrors: json['ValidationErrors'] != null
          ? List<String>.from(json['ValidationErrors'])
          : null,
      data: json['Data'] != null ? PaymentData.fromJson(json['Data']) : null,
    );
  }
}

class PaymentData {
  final List<PaymentMethod> paymentMethods;

  PaymentData({required this.paymentMethods});

  factory PaymentData.fromJson(Map<String, dynamic> json) {
    return PaymentData(
      paymentMethods: (json['PaymentMethods'] as List)
          .map((method) => PaymentMethod.fromJson(method))
          .toList(),
    );
  }
}

class PaymentMethod {
  final int paymentMethodId;
  final String paymentMethodAr;
  final String paymentMethodEn;
  final String paymentMethodCode;
  final bool isDirectPayment;
  final double serviceCharge;
  final double totalAmount;
  final String currencyIso;
  final String imageUrl;
  final bool isEmbeddedSupported;
  final String paymentCurrencyIso;

  PaymentMethod({
    required this.paymentMethodId,
    required this.paymentMethodAr,
    required this.paymentMethodEn,
    required this.paymentMethodCode,
    required this.isDirectPayment,
    required this.serviceCharge,
    required this.totalAmount,
    required this.currencyIso,
    required this.imageUrl,
    required this.isEmbeddedSupported,
    required this.paymentCurrencyIso,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      paymentMethodId: json['PaymentMethodId'] ?? 0,
      paymentMethodAr: json['PaymentMethodAr'] ?? '',
      paymentMethodEn: json['PaymentMethodEn'] ?? '',
      paymentMethodCode: json['PaymentMethodCode'] ?? '',
      isDirectPayment: json['IsDirectPayment'] ?? false,
      serviceCharge: (json['ServiceCharge'] ?? 0.0).toDouble(),
      totalAmount: (json['TotalAmount'] ?? 0.0).toDouble(),
      currencyIso: json['CurrencyIso'] ?? '',
      imageUrl: json['ImageUrl'] ?? '',
      isEmbeddedSupported: json['IsEmbeddedSupported'] ?? false,
      paymentCurrencyIso: json['PaymentCurrencyIso'] ?? '',
    );
  }
}