import 'dart:io';

import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/payment_gateway_response.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/widgets/custom_credit_card.dart';
import 'package:flutter/material.dart';
import 'package:moyasar/moyasar.dart';
import 'package:nb_utils/nb_utils.dart';

class ApplePaymentMethods extends StatefulWidget {
  final double amount;
  final PaymentSetting paymentSetting;
  final String description;
  final Map<String, dynamic>? metadata;
  final Function(PaymentResponse)? onSuccess;
  final Function(dynamic)? onError;
  final bool isForAdvancePayment;
  final Function(String txnId)? savePay;

  const ApplePaymentMethods({
    Key? key,
    required this.amount,
    required this.paymentSetting,
    required this.description,
    this.metadata,
    this.onSuccess,
    this.onError,
    required this.isForAdvancePayment,
    this.savePay,
  }) : super(key: key);

  @override
  State<ApplePaymentMethods> createState() => _ApplePaymentMethodsState();
}

class _ApplePaymentMethodsState extends State<ApplePaymentMethods> {
  bool _isLoading = false;
  bool _isValidPaymentConfig = true;
  String _publishableKey = '';
  String _merchantId = '';

  // static const String _publishableKey = 'pk_test_r6eZg85QyduWZ7PNTHT56BFvZpxJgNJ2PqPMDoXA';
  // static const String _merchantId = 'merchant.com.mysr.apple';
  static const String _appName = 'Salehly';

  late final PaymentConfig _paymentConfig;

  @override
  void initState() {
    appStore.setLoading(false);
    super.initState();

    if (widget.paymentSetting.isTest == 1) {
      _publishableKey =
          widget.paymentSetting.testValue?.moyasarKey.validate() ?? '';
      _merchantId =
          widget.paymentSetting.testValue?.moyasarUrl.validate() ?? '';
    } else {
      _publishableKey =
          widget.paymentSetting.liveValue?.moyasarKey.validate() ?? '';
      _merchantId =
          widget.paymentSetting.liveValue?.moyasarUrl.validate() ?? '';
    }

    if (_publishableKey.isEmpty || _merchantId.isEmpty) {
      _isValidPaymentConfig = false;
      return;
    }

    _paymentConfig = PaymentConfig(
      publishableApiKey: _publishableKey,
      amount: (widget.amount * 100).toInt(),
      description: widget.description,
      metadata: widget.metadata ?? {},
      creditCard: CreditCardConfig(saveCard: false, manual: false),
      applePay: ApplePayConfig(
        merchantId: _merchantId,
        label: _appName,
        manual: false,
        saveCard: false,
      ),
      currency: 'SAR',
      supportedNetworks: [
        PaymentNetwork.visa,
        PaymentNetwork.masterCard,
        PaymentNetwork.mada,
        PaymentNetwork.amex
      ],
    );
  }

  void _handlePaymentResult(BuildContext context, dynamic result) {
    setState(() => _isLoading = false);

    if (result is PaymentResponse) {
      _handlePaymentResponse(result);
    } else {
      _handlePaymentError(result);
    }
  }

  void _handlePaymentResponse(PaymentResponse response) {
    switch (response.status) {
      case PaymentStatus.paid:
        _showDialog(
            language.paymentSuccessful,
            language.yourPaymentWasSuccessful,
            Icons.check_circle,
            Colors.green);
        widget.savePay?.call(response.id);
        widget.onSuccess?.call(response);
        break;
      case PaymentStatus.failed:
        _showDialog(language.paymentFailed, language.transactionFailed,
            Icons.error, Colors.red);
        break;
      case PaymentStatus.authorized:
        _showDialog(language.paymentAuthorized,
            language.paymentAuthorizedProcessing, Icons.info, Colors.blue);
        widget.onSuccess?.call(response);
        break;
      default:
        _showDialog(language.unknownStatus, language.unexpectedResponse,
            Icons.warning, Colors.orange);
    }
  }

  void _handlePaymentError(dynamic error) {
    String message = language.unexpectedErrorOccurred;
    if (error is ApiError) message = error.message;
    if (error is AuthError) message = error.message;
    if (error is ValidationError) message = error.message;
    if (error is PaymentCanceledError) message = language.paymentCancelled;
    if (error is UnprocessableTokenError)
      message = language.invalidPaymentToken;
    if (error is TimeoutError) message = language.requestTimedOut;
    if (error is NetworkError) message = language.networkError;
    if (error is UnspecifiedError) message = error.message;

    _showDialog(
        language.paymentError, message, Icons.error_outline, Colors.red);
    widget.onError?.call(error);
  }

  void _showDialog(String title, String content, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(icon, color: color, size: 48),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(language.lblOk),
            style: TextButton.styleFrom(
              foregroundColor: primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isValidPaymentConfig) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Text(language.moyasarKeyNotFound).center(),
      );
    }
    return AppScaffold(
      appBarTitle: widget.isForAdvancePayment
          ? language.advancePayment
          : language.payment,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Payment Methods Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Apple Pay Section (iOS only)
                      if (Platform.isIOS) ...[
                        ApplePay(
                          config: _paymentConfig,
                          onPaymentResult: (result) =>
                              _handlePaymentResult(context, result),
                        ).paddingSymmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        8.height,
                        // Divider
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.grey[300],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                language.orPayWithCard,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.grey[300],
                              ),
                            ),
                          ],
                        ),
                        8.height,
                      ],

                      // Credit Card Section
                      Container(
                        margin:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        width: double.infinity,
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.credit_card,
                                  color: appTextSecondaryColor,
                                  size: 24,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  language.creditOrDebitCard,
                                  style: boldTextStyle(
                                    color: appTextSecondaryColor,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              language.securePaymentWithCard,
                              style: TextStyle(
                                color: appTextSecondaryColor,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 20),
                            CustomCreditCard(
                              locale: appStore.selectedLanguageCode == 'ar'
                                  ? Localization.ar()
                                  : Localization.en(),
                              config: _paymentConfig,
                              onPaymentResult: (result) =>
                                  _handlePaymentResult(context, result),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Security Notice
                  Container(
                    margin: EdgeInsets.all(16),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.security,
                          color: Colors.green[700],
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                language.securePayment,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[800],
                                ),
                              ),
                              Text(
                                language.paymentInfoEncrypted,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
