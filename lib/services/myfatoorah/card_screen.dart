import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/services/myfatoorah/myfatoorah_payment_screen.dart';
import 'package:booking_system_flutter/services/myfatoorah/myfatoorah_service.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/extensions/num_extenstions.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../model/fatoorah_payment_responce.dart';

class CreditCardFormBottomSheet extends StatefulWidget {
  final MyFatoorahService mfService;
  final String paymentMethodCode;
  final double amount;
  final ExecutePaymentData executePaymentData;
  final Function(String) onComplete;
  final Function(bool) onCancel;
  const CreditCardFormBottomSheet({
    Key? key,
    required this.mfService,
    required this.amount,
    required this.paymentMethodCode,
    required this.executePaymentData,
    required this.onCancel,
    required this.onComplete,
  }) : super(key: key);

  @override
  _CreditCardFormBottomSheetState createState() =>
      _CreditCardFormBottomSheetState();
}

class _CreditCardFormBottomSheetState extends State<CreditCardFormBottomSheet> {
  final _cardNumberController = TextEditingController();
  final _cvvController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cardHolderController = TextEditingController();
  // bool _rememberCard = true;

  // Validation errors
  String? _cardNumberError;
  String? _cvvError;
  String? _expiryError;
  String? _cardHolderError;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cvvController.dispose();
    _expiryController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  // Validate all form fields
  bool _validateForm() {
    bool isValid = true;

    // Validate card number
    if (!isValidCardNumber(_cardNumberController.text)) {
      setState(() {
        _cardNumberError = language.lblEnterValidCardNumber;
      });
      isValid = false;
    } else {
      setState(() {
        _cardNumberError = null;
      });
    }

    // Validate CVV
    if (!isValidCVV(_cvvController.text)) {
      setState(() {
        _cvvError = language.lblEnterValidCVV;
      });
      isValid = false;
    } else {
      setState(() {
        _cvvError = null;
      });
    }

    // Validate expiry date
    if (!isValidExpiry(_expiryController.text)) {
      setState(() {
        _expiryError = language.lblEnterValidExpiry;
      });
      isValid = false;
    } else {
      setState(() {
        _expiryError = null;
      });
    }

    // Validate cardholder name
    if (!isValidCardHolder(_cardHolderController.text)) {
      setState(() {
        _cardHolderError = language.lblEnterCardholderName;
      });
      isValid = false;
    } else {
      setState(() {
        _cardHolderError = null;
      });
    }

    return isValid;
  }

  Future<void> _processCardPayment() async {
    appStore.setLoading(true);

    try {
      final response = await widget.mfService.makeDirectPayment(
        paymentUrl: widget.executePaymentData.paymentURL,
        cardNumber: _cardNumberController.text.removeAllWhiteSpace(),
        expiryMonth: _expiryController.text.splitBefore('/'),
        expiryYear: _expiryController.text.splitAfter('/'),
        securityCode: _cvvController.text,
        cardHolderName: _cardHolderController.text,
      );

      appStore.setLoading(false);
      if (response.isSuccess && response.data != null) {
        if (response.data?.status == 'Success') {
          // For some payment methods, you may need to redirect to the payment URL
          _navigateToPaymentWebView(response.data!.paymentURL);
        } else {
          // _errorMessage = response.data!.errorMessage ?? 'Payment processing failed';
        }
      }
    } catch (e) {
      appStore.setLoading(false);
      toast(e.toString());
    }
  }

  void _navigateToPaymentWebView(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyFatoorahPaymentScreen(
          checkOutUrl: url,
          onComplete: (p0) {
            // Handle payment success
            finish(context);
            finish(context);
            widget.onComplete(p0);
            toast(language.yourPaymentHasBeenMadeSuccessfully);
          },
          onCancel: (p0) {
            widget.onCancel.call(true);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IgnorePointer(
          ignoring: appStore.isLoading,
          child: Container(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          language.lblCreditDebitCard,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Form content
                ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  children: [
                    // Card Holder Name
                    buildCardFormField(
                      label: language.lblCardholderName,
                      hintText: 'John Smith',
                      controller: _cardHolderController,
                      keyboardType: TextInputType.name,
                      errorText: _cardHolderError,
                      onChanged: (value) {
                        if (_cardHolderError != null) {
                          setState(() {
                            _cardHolderError = isValidCardHolder(value)
                                ? null
                                : language.lblEnterCardholderName;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Card Number Field
                    buildCardFormField(
                      label: language.lblCardNumber,
                      hintText: '1234 5678 9012 3456',
                      controller: _cardNumberController,
                      keyboardType: TextInputType.number,
                      errorText: _cardNumberError,
                      onChanged: (value) {
                        final formattedValue = formatCardNumber(value);
                        if (formattedValue != value) {
                          _cardNumberController.value = TextEditingValue(
                            text: formattedValue,
                            selection: TextSelection.collapsed(
                                offset: formattedValue.length),
                          );
                        }
                        if (_cardNumberError != null) {
                          setState(() {
                            _cardNumberError = isValidCardNumber(formattedValue)
                                ? null
                                : language.lblEnterValidCardNumber;
                          });
                        }
                      },
                      maxLength: 19, // 16 digits + 3 spaces
                      suffixIcon: SizedBox(
                        width: 1,
                        child: Image.asset(
                          widget.paymentMethodCode == 'vm'
                              ? myfatoorah_vm
                              : myfatoorah_mada,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // CVV and Expiry in a row
                    Row(
                      children: [
                        Expanded(
                          child: buildCardFormField(
                            label: language.lblCVV,
                            hintText: '123',
                            controller: _cvvController,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            errorText: _cvvError,
                            onChanged: (value) {
                              if (_cvvError != null) {
                                setState(() {
                                  _cvvError = isValidCVV(value)
                                      ? null
                                      : language.lblEnterValidCVV;
                                });
                              }
                            },
                            maxLength: 4,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: buildCardFormField(
                            label: language.lblExpiry,
                            hintText: 'MM/YY',
                            controller: _expiryController,
                            keyboardType: TextInputType.number,
                            errorText: _expiryError,
                            onChanged: (value) {
                              final formattedValue = formatExpiry(value);
                              log('formattedValue: ${formattedValue}');
                              if (formattedValue != value) {
                                _expiryController.value = TextEditingValue(
                                  text: formattedValue,
                                  selection: TextSelection.collapsed(
                                      offset: formattedValue.length),
                                );
                              }
                              if (_expiryError != null) {
                                setState(() {
                                  _expiryError = isValidExpiry(formattedValue)
                                      ? null
                                      : language.lblInvalidExpiryDate;
                                });
                              }
                            },
                            maxLength: 5, // MM/YY format
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Add Card Button
                    AppButton(
                      color: primaryColor,
                      onTap: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        if (_validateForm()) {
                          // Process card data
                          // Navigator.pop(context);
                          _processCardPayment();
                        }
                      },
                      child: Text(
                        "${language.lblPayNow} ${widget.amount.toPriceFormat()}",
                        style: primaryTextStyle(
                          color: white,
                          fontFamily: saudiRiyalsFontFamily,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Security note
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            language.lblSecurePaymentInfo,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Observer(
            builder: (context) => LoaderWidget()
                .withSize(height: 80, width: 80)
                .visible(appStore.isLoading))
      ],
    );
  }
}
