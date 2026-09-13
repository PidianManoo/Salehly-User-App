import 'dart:convert';

import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/fatoorah_initiate_responce.dart';
import 'package:booking_system_flutter/model/fatoorah_payment_responce.dart';
import 'package:booking_system_flutter/model/payment_gateway_response.dart';
import 'package:booking_system_flutter/network/network_utils.dart';
import 'package:flutter/material.dart';
import 'package:myfatoorah_flutter/myfatoorah_flutter.dart' as mf;
import 'package:nb_utils/nb_utils.dart';

class MyFatoorahService {
  late PaymentSetting paymentSetting;

  // Callbacks
  final Function(String) onSuccess;
  final Function(String) onError;
  final Function(String) onLog;

  String domainUrl = "";
  String apiKey = "";
  bool isTest = false;
  dynamic httpHeader = {};

  late mf.MFApplePayButton mfApplePayButton;

  MyFatoorahService({
    required PaymentSetting paymentSetting,
    required this.onSuccess,
    required this.onError,
    required this.onLog,
  }) {
    isTest = paymentSetting.isTest == 1;
    domainUrl = isTest
        ? paymentSetting.testValue?.fatoorahUrl ?? ''
        : paymentSetting.liveValue?.fatoorahUrl ?? '';
    apiKey = isTest
        ? paymentSetting.testValue?.fatoorahKey.validate().trim() ?? ''
        : paymentSetting.liveValue?.fatoorahKey.validate().trim() ?? '';
    httpHeader = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
  }

  /// Initialize MyFatoorah SDK
  Future<void> initializeSDK() async {
    if (apiKey.isEmpty) {
      onError("ERROR: Missing API Token Key. Get it from: https://myfatoorah.readme.io/docs/test-token");
      return;
    }

    try {
      await mf.MFSDK.init(
        apiKey,
        mf.MFCountry.SAUDIARABIA,
        isTest ? mf.MFEnvironment.TEST : mf.MFEnvironment.LIVE,
      );

      onLog("SUCCESS: MyFatoorah SDK initialized successfully");

      mf.MFApplePayStyle applePayStyle = mf.MFApplePayStyle()
        ..height = 50
        ..hideLoadingIndicator = true;

      mfApplePayButton = mf.MFApplePayButton(
        applePayStyle: applePayStyle,
      );
    } catch (error) {
      onError("ERROR: Failed to initialize MyFatoorah SDK: $error");
    }
  }

  /// Start Apple Pay
  Future<void> startApplePay({required double amount}) async {
    final request = mf.MFExecutePaymentRequest(
      invoiceValue: amount,
      customerEmail: appStore.userEmail,
      customerName: appStore.userFullName,
      mobileCountryCode: appStore.userContactNumber.splitBefore('-'),
      customerMobile: appStore.userContactNumber.splitAfter('-'),
      displayCurrencyIso: mf.MFCurrencyISO.SAUDIARABIA_SAR,
    );

    log("Apple Pay Request: ${request.toJson()}");

    try {
      await mfApplePayButton.applePayPayment(
        request,
        appStore.selectedLanguageCode == 'en' ? mf.MFLanguage.ENGLISH : mf.MFLanguage.ARABIC,
        (invoiceId) {
          onLog("Invoice ID: $invoiceId");
        },
      ).then((result) {
        if (result.invoiceId != null) {
          onSuccess(result.invoiceId.toString());
          toast(language.paymentSuccess);
        } else {
          toast(language.yourPaymentFailedPleaseTryAgain);
        }
      });
    } on mf.MFError catch (error) {
      onError("Apple Pay Error: ${error.message}");
      finish(navigatorKey.currentContext!);
      toast(error.message);
    }
  }

  /// Display Apple Pay Button
  Widget showApplePayButton() {
    return mfApplePayButton;
  }

  /// Initiate Payment
  Future<InitiatePaymentResponse> initiatePayment({
    required double amount,
    required String currencyIso,
  }) async {
    final url = '$domainUrl/InitiatePayment';

    try {
      final response = await buildHttpResponse(
        url,
        request: {'InvoiceAmount': amount, 'CurrencyIso': currencyIso},
        method: HttpMethodType.POST,
        header: httpHeader,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return InitiatePaymentResponse.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to initiate payment: ${response.body}');
      }
    } catch (e) {
      onError("Error initiating payment: $e");
      rethrow;
    }
  }

  /// Execute Payment
  Future<ExecutePaymentResponse> executePayment({
    required int paymentMethodId,
    required double invoiceValue,
    required String customerName,
    required String customerEmail,
    required String callBackUrl,
    required String errorUrl,
    bool autoCapture = false,
    bool bypass3DS = false,
    bool saveToken = false,
  }) async {
    final url = '$domainUrl/ExecutePayment';

    final request = ExecutePaymentRequest(
      paymentMethodId: paymentMethodId,
      invoiceValue: invoiceValue,
      processingDetails: ProcessingDetails(autoCapture: autoCapture),
      customerName: customerName,
      customerEmail: customerEmail,
      bypass3DS: bypass3DS,
      saveToken: saveToken,
      callBackUrl: callBackUrl,
      errorUrl: errorUrl,
    );

    try {
      final response = await buildHttpResponse(
        url,
        request: request.toJson(),
        method: HttpMethodType.POST,
        header: httpHeader,
      );

      final jsonResponse = jsonDecode(response.body);
      return ExecutePaymentResponse.fromJson(jsonResponse);
    } catch (e) {
      onError("Error executing payment: $e");
      rethrow;
    }
  }

  /// Make Direct Payment
  Future<DirectPaymentResponse> makeDirectPayment({
    required String paymentUrl,
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String securityCode,
    required String cardHolderName,
    bool? saveToken,
  }) async {
    final request = DirectPaymentRequest(
      paymentType: 'Card',
      saveToken: saveToken,
      card: CardDetails(
        number: cardNumber,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        securityCode: securityCode,
        cardHolderName: cardHolderName,
      ),
    );

    try {
      final response = await buildHttpResponse(
        paymentUrl,
        request: request.toJson(),
        method: HttpMethodType.POST,
        header: httpHeader,
      );

      final jsonResponse = jsonDecode(response.body);
      return DirectPaymentResponse.fromJson(jsonResponse);
    } catch (e) {
      onError("Error making direct payment: $e");
      rethrow;
    }
  }
}