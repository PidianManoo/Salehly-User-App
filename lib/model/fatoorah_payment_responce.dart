

class MyFatoorahPaymentResponse {
    String? invoiceUrl;
    String? customerReference;
    num? invoiceId;

    MyFatoorahPaymentResponse({
        this.invoiceUrl,
        this.customerReference,
        this.invoiceId,
    });

    factory MyFatoorahPaymentResponse.fromMap(Map<String, dynamic> json) => MyFatoorahPaymentResponse(
        invoiceUrl: json["InvoiceURL"],
        customerReference: json["CustomerReference"],
        invoiceId: json["InvoiceId"],
    );

    Map<String, dynamic> toMap() => {
        "InvoiceURL": invoiceUrl,
        "CustomerReference": customerReference,
        "InvoiceId": invoiceId,
    };
}


class ExecutePaymentRequest {
  final int paymentMethodId;
  final double invoiceValue;
  final ProcessingDetails processingDetails;
  final String customerName;
  final String customerEmail;
  final bool bypass3DS;
  final bool saveToken;
  final String callBackUrl;
  final String errorUrl;

  ExecutePaymentRequest({
    required this.paymentMethodId,
    required this.invoiceValue,
    required this.processingDetails,
    required this.customerName,
    required this.customerEmail,
    required this.bypass3DS,
    required this.saveToken,
    required this.callBackUrl,
    required this.errorUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'PaymentMethodId': paymentMethodId,
      'invoiceValue': invoiceValue,
      'ProcessingDetails': processingDetails.toJson(),
      'CustomerName': customerName,
      'CustomerEmail': customerEmail,
      'Bypass3DS': bypass3DS,
      'SaveToken': saveToken,
      'CallBackUrl': callBackUrl,
      'ErrorUrl': errorUrl,
    };
  }
}

class ProcessingDetails {
  final bool autoCapture;

  ProcessingDetails({
    required this.autoCapture,
  });

  Map<String, dynamic> toJson() {
    return {
      'AutoCapture': autoCapture,
    };
  }
}

// ExecutePayment Response Models
class ExecutePaymentResponse {
  final bool isSuccess;
  final String? message;
  final List<ValidationError>? validationErrors;
  final ExecutePaymentData? data;

  ExecutePaymentResponse({
    required this.isSuccess,
    this.message,
    this.validationErrors,
    this.data,
  });

  factory ExecutePaymentResponse.fromJson(Map<String, dynamic> json) {
    return ExecutePaymentResponse(
      isSuccess: json['IsSuccess'] ?? false,
      message: json['Message'],
      validationErrors: json['ValidationErrors'] != null
          ? (json['ValidationErrors'] as List)
              .map((error) => ValidationError.fromJson(error))
              .toList()
          : null,
      data: json['Data'] != null ? ExecutePaymentData.fromJson(json['Data']) : null,
    );
  }
}

class ValidationError {
  final String name;
  final String error;

  ValidationError({
    required this.name,
    required this.error,
  });

  factory ValidationError.fromJson(Map<String, dynamic> json) {
    return ValidationError(
      name: json['Name'] ?? '',
      error: json['Error'] ?? '',
    );
  }
}

class ExecutePaymentData {
  final int invoiceId;
  final bool isDirectPayment;
  final String paymentURL;
  final String? customerReference;
  final String? userDefinedField;
  final String recurringId;

  ExecutePaymentData({
    required this.invoiceId,
    required this.isDirectPayment,
    required this.paymentURL,
    this.customerReference,
    this.userDefinedField,
    required this.recurringId,
  });

  factory ExecutePaymentData.fromJson(Map<String, dynamic> json) {
    return ExecutePaymentData(
      invoiceId: json['InvoiceId'] ?? 0,
      isDirectPayment: json['IsDirectPayment'] ?? false,
      paymentURL: json['PaymentURL'] ?? '',
      customerReference: json['CustomerReference'],
      userDefinedField: json['UserDefinedField'],
      recurringId: json['RecurringId'] ?? '',
    );
  }
}

// Direct Payment Models
class DirectPaymentRequest {
  final String paymentType;
  final bool? saveToken;
  // final int paymentMethodId;
  final CardDetails card;

  DirectPaymentRequest({
    required this.paymentType,
    this.saveToken,
    // required this.paymentMethodId,
    required this.card,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'PaymentType': paymentType,
      // 'PaymentMethodId': paymentMethodId,
      'Card': card.toJson(),
    };
    
    if (saveToken != null) {
      data['SaveToken'] = saveToken;
    }
    
    return data;
  }
}

class CardDetails {
  final String number;
  final String expiryMonth;
  final String expiryYear;
  final String securityCode;
  final String cardHolderName;

  CardDetails({
    required this.number,
    required this.expiryMonth,
    required this.expiryYear,
    required this.securityCode,
    required this.cardHolderName,
  });

  Map<String, dynamic> toJson() {
    return {
      'Number': number,
      'ExpiryMonth': expiryMonth,
      'ExpiryYear': expiryYear,
      'SecurityCode': securityCode,
      'CardHolderName': cardHolderName,
    };
  }
}

class DirectPaymentResponse {
  final bool isSuccess;
  final String? message;
  final List<ValidationError>? validationErrors;
  final DirectPaymentData? data;

  DirectPaymentResponse({
    required this.isSuccess,
    this.message,
    this.validationErrors,
    this.data,
  });

  factory DirectPaymentResponse.fromJson(Map<String, dynamic> json) {
    return DirectPaymentResponse(
      isSuccess: json['IsSuccess'] ?? false,
      message: json['Message'],
      validationErrors: json['ValidationErrors'] != null
          ? (json['ValidationErrors'] as List)
              .map((error) => ValidationError.fromJson(error))
              .toList()
          : null,
      data: json['Data'] != null ? DirectPaymentData.fromJson(json['Data']) : null,
    );
  }
}

class DirectPaymentData {
  final String status;
  final String? errorCode;
  final String? errorMessage;
  final String paymentId;
  final String? token;
  final String? recurringId;
  final String paymentURL;
  final CardInfo? cardInfo;

  DirectPaymentData({
    required this.status,
    this.errorCode,
    this.errorMessage,
    required this.paymentId,
    this.token,
    this.recurringId,
    required this.paymentURL,
    this.cardInfo,
  });

  factory DirectPaymentData.fromJson(Map<String, dynamic> json) {
    return DirectPaymentData(
      status: json['Status'] ?? '',
      errorCode: json['ErrorCode'],
      errorMessage: json['ErrorMessage'],
      paymentId: json['PaymentId'] ?? '',
      token: json['Token'],
      recurringId: json['RecurringId'],
      paymentURL: json['PaymentURL'] ?? '',
      cardInfo: json['CardInfo'] != null ? CardInfo.fromJson(json['CardInfo']) : null,
    );
  }
}

class CardInfo {
  // Add card info properties as needed
  
  CardInfo();
  
  factory CardInfo.fromJson(Map<String, dynamic> json) {
    return CardInfo();
  }
}