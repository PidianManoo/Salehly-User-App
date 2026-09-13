// ignore_for_file: must_be_immutable

import 'dart:io';
import 'dart:math';

import 'package:booking_system_flutter/component/price_widget.dart';
import 'package:booking_system_flutter/services/apple_payment_method.dart';
import 'package:booking_system_flutter/services/flutter_wave_service_new.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/extensions/num_extenstions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:booking_system_flutter/utils/custom_app_field.dart';

import '../../component/app_common_dialog.dart';
import '../../component/base_scaffold_widget.dart';
import '../../component/empty_error_state_widget.dart';
import '../../main.dart';
import '../../model/fatoorah_initiate_responce.dart';
import '../../model/fatoorah_payment_responce.dart';
import '../../model/payment_gateway_response.dart';
import '../../network/rest_apis.dart';
import '../../services/airtel_money/airtel_money_service.dart';
import '../../services/cinet_pay_services_new.dart';
import '../../services/midtrans_service.dart';
import '../../services/myfatoorah/card_screen.dart';
import '../../services/myfatoorah/myfatoorah_service.dart';
import '../../services/paypal_service.dart';
import '../../services/paystack_service.dart';
import '../../services/phone_pe/phone_pe_service.dart';
import '../../services/razorpay_service_new.dart';
import '../../services/sadad_services_new.dart';
import '../../services/stripe_service_new.dart';
import '../../utils/app_configuration.dart';
import '../../utils/colors.dart';
import '../../utils/configs.dart';
import '../../utils/constant.dart';
import '../../utils/images.dart';
import '../auth/edit_profile_screen.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final String currencySymbol;
  final bool isLeftPosition;

  CurrencyInputFormatter(
      {required this.currencySymbol, required this.isLeftPosition});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text;

    // Remove any existing currency symbols
    newText = newText.replaceAll(currencySymbol, '');

    // Remove any non-digit characters
    newText = newText.replaceAll(RegExp(r'[^\d]'), '');

    // If empty, return empty
    if (newText.isEmpty) {
      return TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Format with currency symbol
    String formattedText;
    if (isLeftPosition) {
      formattedText = '$currencySymbol$newText';
    } else {
      formattedText = '$newText$currencySymbol';
    }

    // Calculate cursor position
    int cursorPosition = newValue.selection.baseOffset;
    if (isLeftPosition) {
      // If currency is on left, adjust cursor position
      if (newValue.text.length > oldValue.text.length) {
        cursorPosition = newValue.selection.baseOffset + currencySymbol.length;
      } else {
        cursorPosition = newValue.selection.baseOffset;
      }
    } else {
      // If currency is on right, cursor position stays the same
      cursorPosition = newValue.selection.baseOffset;
    }

    // Ensure cursor position is within bounds
    cursorPosition = cursorPosition.clamp(0, formattedText.length);

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}

class UserWalletBalanceScreen extends StatefulWidget {
  bool isBackScreen;
  UserWalletBalanceScreen({Key? key, this.isBackScreen = false})
      : super(key: key);

  @override
  State<UserWalletBalanceScreen> createState() =>
      _UserWalletBalanceScreenState();
}

class _UserWalletBalanceScreenState extends State<UserWalletBalanceScreen> {
  Future<List<PaymentSetting>>? future;

  TextEditingController walletAmountCont = TextEditingController();
  FocusNode walletAmountFocus = FocusNode();

  List<int> defaultAmounts = [150, 200, 500, 1000, 5000, 10000];
  PaymentSetting? currentPaymentMethod;
  List<PaymentMethod> fatoorahPaymentList = [];

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    future = getPaymentGateways(requireCOD: false, requireWallet: false).then(
      (value) {
        currentPaymentMethod = value
            .where((element) => element.type == PAYMENT_METHOD_MOYASAR)
            .firstOrNull;
        return value;
      },
    );

    appStore.setUserWalletAmount();
  }

  // Helper method to extract numeric value from formatted currency text
  double getNumericAmount() {
    String text = walletAmountCont.text;
    // Remove currency symbols
    if (isSaudiRiyalsSymbol) {
      text = text.replaceAll(saudiRiyalsNewSymbol, '');
    } else {
      text = text.replaceAll(appConfigurationStore.currencySymbol, '');
    }
    // Remove any non-digit characters except decimal point
    text = text.replaceAll(RegExp(r'[^\d.]'), '');
    return text.isEmpty ? 0.0 : double.tryParse(text) ?? 0.0;
  }

  void _handleClick() async {
    if (currentPaymentMethod == null) {
      return toast(language.pleaseChooseAnyOnePayment);
    } else if (getNumericAmount() == 0) {
      return toast(language.theAmountShouldBeEntered);
    }

    if (currentPaymentMethod!.type == PAYMENT_METHOD_STRIPE) {
      StripeServiceNew stripeServiceNew = StripeServiceNew(
        paymentSetting: currentPaymentMethod!,
        totalAmount: getNumericAmount(),
        onComplete: (p0) {
          Map req = {
            "amount": getNumericAmount(),
            "transaction_type": PAYMENT_METHOD_STRIPE,
            "transaction_id": p0['transaction_id']
          };

          walletTopUpApi(request: req);
        },
      );

      stripeServiceNew.stripePay().catchError((e) {
        appStore.setLoading(false);
        toast(e);
      });
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_RAZOR) {
      RazorPayServiceNew razorPayServiceNew = RazorPayServiceNew(
        paymentSetting: currentPaymentMethod!,
        totalAmount: getNumericAmount(),
        onComplete: (p0) {
          log(p0);
          Map req = {
            "amount": getNumericAmount(),
            "transaction_type": PAYMENT_METHOD_RAZOR,
            "transaction_id": p0['orderId']
          };

          walletTopUpApi(request: req);
        },
      );
      razorPayServiceNew.razorPayCheckout().catchError((e) {
        appStore.setLoading(false);
        toast(e);
      });
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_MOYASAR) {
      appStore.setLoading(true);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ApplePaymentMethods(
              amount: getNumericAmount(), // 50 SAR
              paymentSetting: currentPaymentMethod!,
              description: 'Test Payment',
              metadata: {
                'booking_id': '${appStore.userId.validate()}',
              },
              isForAdvancePayment: false,
              savePay: (txnId) {
                Map req = {
                  "amount": getNumericAmount(),
                  "transaction_type": PAYMENT_METHOD_MOYASAR,
                  "transaction_id": txnId,
                };
                walletTopUpApi(request: req);
              }),
        ),
      );
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_FLUTTER_WAVE) {
      FlutterWaveServiceNew flutterWaveServiceNew = FlutterWaveServiceNew();

      flutterWaveServiceNew.checkout(
        paymentSetting: currentPaymentMethod!,
        totalAmount: getNumericAmount(),
        onComplete: (p0) {
          Map req = {
            "amount": getNumericAmount(),
            "transaction_type": PAYMENT_METHOD_FLUTTER_WAVE,
            "transaction_id": p0['transaction_id']
          };

          walletTopUpApi(request: req);
        },
      );
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_CINETPAY) {
      List<String> supportedCurrencies = ["XOF", "XAF", "CDF", "GNF", "USD"];

      if (!supportedCurrencies.contains(appConfigurationStore.currencyCode)) {
        toast(language.cinetPayNotSupportedMessage);
        return;
      } else if (getNumericAmount() < 100) {
        return toastSaudiRiyals(
            '${language.totalAmountShouldBeMoreThan} ${100.toPriceFormat()}');
      } else if (getNumericAmount() > 1500000) {
        return toastSaudiRiyals(
            '${language.totalAmountShouldBeLessThan} ${1500000.toPriceFormat()}');
      }

      CinetPayServicesNew cinetPayServices = CinetPayServicesNew(
        paymentSetting: currentPaymentMethod!,
        totalAmount: getNumericAmount(),
        onComplete: (p0) {
          Map req = {
            "amount": getNumericAmount(),
            "transaction_type": PAYMENT_METHOD_CINETPAY,
            "transaction_id": p0['transaction_id']
          };

          walletTopUpApi(request: req);
        },
      );

      cinetPayServices.payWithCinetPay(context: context).catchError((e) {
        appStore.setLoading(false);
        toast(e);
      });
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_SADAD_PAYMENT) {
      SadadServicesNew sadadServices = SadadServicesNew(
        paymentSetting: currentPaymentMethod!,
        totalAmount: getNumericAmount(),
        remarks: language.topUpWallet,
        onComplete: (p0) {
          Map req = {
            "amount": getNumericAmount(),
            "transaction_type": PAYMENT_METHOD_SADAD_PAYMENT,
            "transaction_id": p0['transaction_id'],
          };

          walletTopUpApi(request: req);
        },
      );

      sadadServices.payWithSadad(context).catchError((e) {
        appStore.setLoading(false);
        toast(e);
      });
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_PAYPAL) {
      PayPalService.paypalCheckOut(
        context: context,
        paymentSetting: currentPaymentMethod!,
        totalAmount: getNumericAmount(),
        onComplete: (p0) {
          log('PayPalService onComplete: $p0');
          Map req = {
            "amount": getNumericAmount(),
            "transaction_type": PAYMENT_METHOD_PAYPAL,
            "transaction_id": p0['transaction_id']
          };
          walletTopUpApi(request: req);
        },
      );
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_AIRTEL) {
      showInDialog(
        context,
        contentPadding: EdgeInsets.zero,
        barrierDismissible: false,
        builder: (context) {
          return AppCommonDialog(
            title: language.airtelMoneyPayment,
            child: AirtelMoneyDialog(
              amount: getNumericAmount(),
              paymentSetting: currentPaymentMethod!,
              reference: APP_NAME,
              bookingId: appStore.userId.validate().toInt(),
              onComplete: (res) {
                log('RES: $res');
                Map req = {
                  "amount": getNumericAmount(),
                  "transaction_type": PAYMENT_METHOD_AIRTEL,
                  "transaction_id": res['transaction_id']
                };
                walletTopUpApi(request: req);
              },
            ),
          );
        },
      ).then((value) => appStore.setLoading(false));
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_PAYSTACK) {
      PayStackService paystackServices = PayStackService();
      appStore.setLoading(true);
      await paystackServices.init(
        context: context,
        currentPaymentMethod: currentPaymentMethod!,
        loderOnOFF: (p0) {
          appStore.setLoading(p0);
        },
        totalAmount: getNumericAmount(),
        bookingId: appStore.userId.validate().toInt(),
        onComplete: (res) {
          log('RES: $res');
          Map req = {
            "amount": getNumericAmount(),
            "transaction_type": PAYMENT_METHOD_PAYSTACK,
            "transaction_id": res['transaction_id']
          };
          walletTopUpApi(request: req);
        },
      );
      await Future.delayed(const Duration(seconds: 1));
      appStore.setLoading(false);
      paystackServices.checkout().catchError((e) {
        appStore.setLoading(false);
        toast(e);
      });
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_MIDTRANS) {
      MidtransService midtransService = MidtransService();
      appStore.setLoading(true);
      await midtransService.initialize(
        currentPaymentMethod: currentPaymentMethod!,
        totalAmount: getNumericAmount(),
        loaderOnOFF: (p0) {
          appStore.setLoading(p0);
        },
        onComplete: (res) {
          log('RES: $res');
          Map req = {
            "amount": getNumericAmount(),
            "transaction_type": PAYMENT_METHOD_MIDTRANS,
            "transaction_id": res['transaction_id']
          };
          walletTopUpApi(request: req);
        },
      );
      await Future.delayed(const Duration(seconds: 1));
      appStore.setLoading(false);
      midtransService.midtransPaymentCheckout().catchError((e) {
        appStore.setLoading(false);
        toast(e);
      });
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_PHONEPE) {
      PhonePeServices peServices = PhonePeServices(
        paymentSetting: currentPaymentMethod!,
        totalAmount: getNumericAmount(),
        onComplete: (res) {
          log('RES: $res');
          Map req = {
            "amount": getNumericAmount(),
            "transaction_type": PAYMENT_METHOD_PHONEPE,
            "transaction_id": res['transaction_id']
          };
          walletTopUpApi(request: req);
        },
      );

      peServices.phonePeCheckout(context).catchError((e) {
        appStore.setLoading(false);
        toast(e);
      });
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_MYFATOORAH) {
      if (appStore.userContactNumber.isEmpty) {
        toast("Please add your phone number in your profile details.");
        EditProfileScreen().launch(context);
        return;
      }
      try {
        MyFatoorahService mfService = MyFatoorahService(
            paymentSetting: currentPaymentMethod!,
            onSuccess: (id) {
              log('RES: $res');
              Map req = {
                "amount": getNumericAmount(),
                "transaction_type": PAYMENT_METHOD_MYFATOORAH,
                "transaction_id": id.isNotEmpty ? id : Random().nextInt(1000)
              };
              walletTopUpApi(request: req);
            },
            onError: (String) {},
            onLog: (String) {});

        appStore.setLoading(true);
        await mfService.initializeSDK().then(
          (value) async {
            mfService.startApplePay(amount: getNumericAmount());
          },
        );
        await Future.delayed(Duration(seconds: 2));

        mfService
            .initiatePayment(
          amount: getNumericAmount(),
          currencyIso: "SAR",
        )
            .then((value) {
          fatoorahPaymentList = value.data?.paymentMethods ?? [];

          fatoorahPaymentList
              .removeWhere((element) => element.paymentMethodId == 13);
          setState(() {});
          appStore.setLoading(false);
          _showPaymentOptions(amount: getNumericAmount(), mfService: mfService);
        });
      } catch (e) {
        appStore.setLoading(false);

        toast(e.toString());
      }
    }
  }

  String getPaymentMethodIcon(String value) {
    if (value == PAYMENT_METHOD_STRIPE) {
      return stripe_logo;
    } else if (value == PAYMENT_METHOD_RAZOR) {
      return razorpay_logo;
    } else if (value == PAYMENT_METHOD_MOYASAR) {
      return moyasar_logo;
    } else if (value == PAYMENT_METHOD_CINETPAY) {
      return cinetpay_logo;
    } else if (value == PAYMENT_METHOD_FLUTTER_WAVE) {
      return flutter_wave_logo;
    } else if (value == PAYMENT_METHOD_SADAD_PAYMENT) {
      return "";
    } else if (value == PAYMENT_METHOD_PAYPAL) {
      return paypal_logo;
    } else if (value == PAYMENT_METHOD_AIRTEL) {
      return airtel_logo;
    } else if (value == PAYMENT_METHOD_PAYSTACK) {
      return paystack_logo;
    } else if (value == PAYMENT_METHOD_PHONEPE) {
      return phonepe_logo;
    } else if (value == PAYMENT_METHOD_MYFATOORAH) {
      return myfatoorah_logo;
    }

    return '';
  }

  walletTopUpApi({required Map request}) {
    walletTopUp(request).then((value) {
      if (widget.isBackScreen) {
        finish(context, true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: language.myWallet,
      child: Stack(
        children: [
          AnimatedScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            listAnimationType: ListAnimationType.None,
            onSwipeRefresh: () {
              appStore.setUserWalletAmount();

              return 1.seconds.delay;
            },
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: context.width(),
                    padding: EdgeInsets.all(16),
                    color: context.cardColor,
                    child: Row(
                      children: [
                        Text(language.balance,
                                style:
                                    boldTextStyle(color: context.primaryColor))
                            .expand(),
                        Observer(
                            builder: (context) => PriceWidget(
                                price: appStore.userWalletAmount,
                                size: 16,
                                isBoldText: true,
                                color: Colors.green)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      16.height,
                      Text(language.topUpWallet,
                          style: boldTextStyle(size: LABEL_TEXT_SIZE)),
                      8.height,
                      Text(language.topUpAmountQuestion,
                          style: secondaryTextStyle()),
                      Container(
                        width: context.width(),
                        margin: EdgeInsets.symmetric(vertical: 20),
                        padding: EdgeInsets.all(24),
                        // decoration: BoxDecoration(
                        //   color: Colors.white,
                        //   borderRadius: BorderRadius.circular(16),
                        //   border: Border.all(color: primaryColor),
                        //   boxShadow: [
                        //     BoxShadow(
                        //       color: primaryColor.withAlpha(50),
                        //       blurRadius: 10,
                        //       offset: Offset(0, 2),
                        //     ),
                        //   ],
                        // ),
                        child: Column(
                          children: [
                            // Amount Input Field
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: walletAmountFocus.hasFocus
                                      ? context.primaryColor
                                      : Colors.grey[300]!,
                                  width: walletAmountFocus.hasFocus ? 2 : 1,
                                ),
                              ),
                              child: CustomAppTextField(
                                textFieldType: TextFieldType.NUMBER,
                                controller: walletAmountCont,
                                focus: walletAmountFocus,
                                textAlign: TextAlign.center,
                                textStyle: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: saudiRiyalsFontFamily,
                                ),
                                inputFormatters: [
                                  CurrencyInputFormatter(
                                    currencySymbol: isSaudiRiyalsSymbol
                                        ? saudiRiyalsNewSymbol
                                        : appConfigurationStore.currencySymbol,
                                    isLeftPosition: isCurrencyPositionLeft,
                                  ),
                                ],
                                onTap: () {
                                  if (walletAmountCont.text == '0' ||
                                      walletAmountCont.text.isEmpty) {
                                    walletAmountCont.selection = TextSelection(
                                        baseOffset: isCurrencyPositionLeft
                                            ? (isSaudiRiyalsSymbol
                                                ? saudiRiyalsNewSymbol.length
                                                : appConfigurationStore
                                                    .currencySymbol.length)
                                            : 0,
                                        extentOffset: isCurrencyPositionLeft
                                            ? (isSaudiRiyalsSymbol
                                                ? saudiRiyalsNewSymbol.length
                                                : appConfigurationStore
                                                    .currencySymbol.length)
                                            : 0);
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: isCurrencyPositionLeft
                                      ? '${isSaudiRiyalsSymbol ? saudiRiyalsNewSymbol : appConfigurationStore.currencySymbol}0'
                                      : '0${isSaudiRiyalsSymbol ? saudiRiyalsNewSymbol : appConfigurationStore.currencySymbol}',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 24,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: saudiRiyalsFontFamily,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 16),
                                ),
                                onChanged: (value) {
                                  setState(() {});
                                },
                              ),
                            ),

                            32.height,

                            // Quick Amount Selection Grid
                            GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 2.2,
                              ),
                              itemCount: defaultAmounts.length,
                              itemBuilder: (context, index) {
                                // Create formatted amount for comparison
                                String formattedAmount = isCurrencyPositionLeft
                                    ? '${isSaudiRiyalsSymbol ? saudiRiyalsNewSymbol : appConfigurationStore.currencySymbol}${defaultAmounts[index].toString()}'
                                    : '${defaultAmounts[index].toString()}${isSaudiRiyalsSymbol ? saudiRiyalsNewSymbol : appConfigurationStore.currencySymbol}';
                                final isSelected =
                                    formattedAmount == walletAmountCont.text;
                                return Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? context.primaryColor
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? context.primaryColor
                                          : Colors.grey[300]!,
                                      width: 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: context.primaryColor
                                                  .withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: Offset(0, 2),
                                            ),
                                          ]
                                        : [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.05),
                                              blurRadius: 4,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () {
                                        // Format the amount with currency symbol
                                        String formattedAmount = isCurrencyPositionLeft
                                            ? '${isSaudiRiyalsSymbol ? saudiRiyalsNewSymbol : appConfigurationStore.currencySymbol}${defaultAmounts[index].toString()}'
                                            : '${defaultAmounts[index].toString()}${isSaudiRiyalsSymbol ? saudiRiyalsNewSymbol : appConfigurationStore.currencySymbol}';
                                        walletAmountCont.text = formattedAmount;
                                        setState(() {});
                                      },
                                      child: Container(
                                        // padding: EdgeInsets.symmetric(
                                        //     horizontal: 12, vertical: 12),
                                        child: Center(
                                          child: Text(
                                            isCurrencyPositionLeft
                                                ? '${isSaudiRiyalsSymbol ? saudiRiyalsNewSymbol : appConfigurationStore.currencySymbol}${defaultAmounts[index].toString().formatNumberWithComma()}'
                                                : '${defaultAmounts[index].toString().formatNumberWithComma()}${isSaudiRiyalsSymbol ? saudiRiyalsNewSymbol : appConfigurationStore.currencySymbol}',
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.grey[700],
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: saudiRiyalsFontFamily,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      16.height,
                      Text(language.paymentMethod,
                          style: boldTextStyle(size: LABEL_TEXT_SIZE)),
                      4.height,
                      Text(language.selectYourPaymentMethodToAddBalance,
                          style: secondaryTextStyle()),
                      4.height,
                      SnapHelperWidget<List<PaymentSetting>>(
                        future: future,
                        onSuccess: (list) {
                          return AnimatedWrap(
                            itemCount: list.length,
                            listAnimationType: ListAnimationType.FadeIn,
                            fadeInConfiguration:
                                FadeInConfiguration(duration: 2.seconds),
                            spacing: 8,
                            runSpacing: 16,
                            itemBuilder: (context, index) {
                              if (list.isEmpty)
                                return NoDataWidget(
                                  title: language.lblNoPayments,
                                  imageWidget: EmptyStateWidget(),
                                );
                              PaymentSetting value = list[index];
                              if (value.status.validate() == 0)
                                return Offstage();
                              String icon =
                                  getPaymentMethodIcon(value.type.validate());

                              return Stack(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 8),
                                    child: Container(
                                      width: context.width() * 0.240,
                                      height: 60,
                                      padding: EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 8),
                                      decoration: boxDecorationDefault(
                                        borderRadius: radius(8),
                                        border: Border.all(color: primaryColor),
                                      ),
                                      alignment: Alignment.center,
                                      child: icon.isNotEmpty
                                          ? Image.asset(icon)
                                          : Text(value.type.validate(),
                                              style: primaryTextStyle()),
                                    ).onTap(() {
                                      currentPaymentMethod = value;

                                      setState(() {});
                                    }),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      padding: currentPaymentMethod == value
                                          ? EdgeInsets.all(2)
                                          : EdgeInsets.zero,
                                      decoration: boxDecorationDefault(
                                          color: context.primaryColor),
                                      child: currentPaymentMethod == value
                                          ? Icon(Icons.done,
                                              size: 16, color: Colors.white)
                                          : Offstage(),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      100.height,
                    ],
                  ).paddingSymmetric(horizontal: 16),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: AppButton(
              width: context.width(),
              height: 16,
              color: context.primaryColor,
              text: language.proceedToPayment,
              textStyle: boldTextStyle(color: white),
              onTap: () async {
                hideKeyboard(context);
                _handleClick();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> executePayment({
    required MyFatoorahService mfService,
    required int paymentMethodId,
    required double amount,
    required String paymentMethodCode,
  }) async {
    appStore.setLoading(true);

    try {
      final response = await mfService.executePayment(
        paymentMethodId: paymentMethodId,
        invoiceValue: amount,
        customerName: appStore.userFullName,
        customerEmail: appStore.userEmail,
        callBackUrl: '${DOMAIN_URL}/success', // Ensure proper URL formatting
        errorUrl: '${DOMAIN_URL}/error',
      );

      appStore.setLoading(false);

      if (response.isSuccess && response.data != null) {
        if (response.data!.isDirectPayment) {
          // Show credit card form for direct payment methods
          _showCreditCardForm(
            amount: amount,
            mfService: mfService,
            executePaymentData: response.data!,
            paymentMethodCode: paymentMethodCode,
          );
        }
      } else {
        toast(language.yourPaymentFailedPleaseTryAgain);
      }
    } catch (e) {
      appStore.setLoading(false);
      log('Error during payment execution: $e');
      toast(language.yourPaymentFailedPleaseTryAgain);
    }
  }

  int _selectedPaymentMethod = -1;
  PaymentMethod? currentFatoorahPayment;

  void _showPaymentOptions({
    required MyFatoorahService mfService,
    required double amount,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          language.lblPaymentOptions,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const Divider(height: 1),
                  // Payment Options List
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: fatoorahPaymentList.length,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (BuildContext context, int index) {
                      var data = fatoorahPaymentList[index];

                      // Skip unsupported payment methods
                      if (!Platform.isIOS &&
                          data.paymentMethodCode == "ap" &&
                          !data.isDirectPayment) {
                        return const Offstage();
                      }

                      return buildPaymentOption(
                        index: index,
                        icon: data.imageUrl,
                        title: data.paymentMethodEn.capitalizeEachWord(),
                        currentValue: _selectedPaymentMethod,
                        onChanged: (value) {
                          setModalState(() {
                            _selectedPaymentMethod = value!;
                            currentFatoorahPayment = data;
                          });
                        },
                      );
                    },
                  ),
                  // Confirm Button
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: currentFatoorahPayment?.paymentMethodId == 11
                        ? GestureDetector(
                            onTap: () => finish(context),
                            child: Container(
                              height: 50,
                              child: mfService.showApplePayButton(),
                            ),
                          )
                        : AppButton(
                            onTap: () {
                              if (currentFatoorahPayment == null) {
                                toast(language.chooseAnyOnePayment);
                                return;
                              }

                              appStore.setLoading(true);
                              executePayment(
                                mfService: mfService,
                                amount: amount,
                                paymentMethodCode:
                                    currentFatoorahPayment?.paymentMethodCode ??
                                        '',
                                paymentMethodId:
                                    currentFatoorahPayment?.paymentMethodId ??
                                        1,
                              );
                            },
                            width: double.infinity,
                            color: primaryColor,
                            padding: EdgeInsets.zero,
                            height: 50,
                            text: language.lblContinue,
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCreditCardForm(
      {required MyFatoorahService mfService,
      required ExecutePaymentData executePaymentData,
      required double amount,
      required String paymentMethodCode}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        log('currentFatoorahPayment!.paymentMethodEn: ${currentFatoorahPayment!.paymentMethodEn}');
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Stack(
            alignment: AlignmentDirectional.bottomCenter,
            children: [
              CreditCardFormBottomSheet(
                paymentMethodCode: paymentMethodCode,
                mfService: mfService,
                amount: amount,
                executePaymentData: executePaymentData,
                onComplete: (id) {
                  log('RES: $res');
                  Map req = {
                    "amount": getNumericAmount(),
                    "transaction_type": PAYMENT_METHOD_MYFATOORAH,
                    "transaction_id":
                        id.isNotEmpty ? id : Random().nextInt(1000)
                  };
                  walletTopUpApi(request: req);
                },
                onCancel: (p0) {
                  finish(context);
                  toast(language.lblTransactionCancelled);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
