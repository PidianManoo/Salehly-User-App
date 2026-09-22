import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/booking_detail_model.dart';
import 'package:booking_system_flutter/screens/booking/component/price_common_widget.dart';
import 'package:booking_system_flutter/screens/wallet/user_wallet_balance_screen.dart';
import 'package:booking_system_flutter/services/apple_payment_method.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/extensions/num_extenstions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../component/app_common_dialog.dart';
import '../../component/base_scaffold_widget.dart';
import '../../component/empty_error_state_widget.dart';
import '../../component/wallet_balance_component.dart';
import '../../model/fatoorah_initiate_responce.dart';
import '../../model/fatoorah_payment_responce.dart';
import '../../model/payment_gateway_response.dart';
import '../../network/rest_apis.dart';
import '../../services/airtel_money/airtel_money_service.dart';
import '../../services/cinet_pay_services_new.dart';
import '../../services/flutter_wave_service_new.dart';
import '../../services/midtrans_service.dart';
import '../../services/myfatoorah/card_screen.dart';
import '../../services/myfatoorah/myfatoorah_service.dart';
import '../../services/paypal_service.dart';
import '../../services/paystack_service.dart';
import '../../services/phone_pe/phone_pe_service.dart';
import '../../services/razorpay_service_new.dart';
import '../../services/sadad_services_new.dart';
import '../../services/stripe_service_new.dart';
import '../../utils/configs.dart';
import '../../utils/model_keys.dart';
import '../dashboard/dashboard_screen.dart';

class PaymentScreen extends StatefulWidget {
  final BookingDetailResponse bookings;
  final bool isForAdvancePayment;

  PaymentScreen({required this.bookings, this.isForAdvancePayment = false});

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Future<List<PaymentSetting>>? future;

  PaymentSetting? currentPaymentMethod;

  num totalAmount = 0;
  num? advancePaymentAmount;

  @override
  void initState() {
    super.initState();
    init();

    if (widget.bookings.service!.isAdvancePayment &&
        widget.bookings.service!.isFixedService &&
        !widget.bookings.service!.isFreeService &&
        widget.bookings.bookingDetail!.bookingPackage == null) {
      if (widget.bookings.bookingDetail!.paidAmount.validate() == 0) {
        advancePaymentAmount =
            widget.bookings.bookingDetail!.totalAmount.validate() *
                widget.bookings.service!.advancePaymentPercentage.validate() /
                100;
        totalAmount = widget.bookings.bookingDetail!.totalAmount.validate() *
            widget.bookings.service!.advancePaymentPercentage.validate() /
            100;
      } else {
        totalAmount = widget.bookings.bookingDetail!.totalAmount.validate() -
            widget.bookings.bookingDetail!.paidAmount.validate();
      }
    } else {
      totalAmount = widget.bookings.bookingDetail!.totalAmount.validate();
    }

    log(totalAmount);
  }

  void init() async {
    log("ISaDVANCE${widget.isForAdvancePayment}");
    future = getPaymentGateways(requireCOD: !widget.isForAdvancePayment);
    setState(() {});
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Future<void> _handleClick() async {
    appStore.setLoading(true);
    if (currentPaymentMethod!.type == PAYMENT_METHOD_COD) {
      savePay(
          paymentMethod: PAYMENT_METHOD_COD,
          paymentStatus: SERVICE_PAYMENT_STATUS_PENDING);
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_STRIPE) {
      StripeServiceNew stripeServiceNew = StripeServiceNew(
        paymentSetting: currentPaymentMethod!,
        totalAmount: totalAmount,
        onComplete: (p0) {
          savePay(
            paymentMethod: PAYMENT_METHOD_STRIPE,
            paymentStatus: widget.isForAdvancePayment
                ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                : SERVICE_PAYMENT_STATUS_PAID,
            txnId: p0['transaction_id'],
          );
        },
      );

      stripeServiceNew.stripePay().catchError((e) {
        appStore.setLoading(false);
        toast(e);
      });
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_RAZOR) {
      RazorPayServiceNew razorPayServiceNew = RazorPayServiceNew(
        paymentSetting: currentPaymentMethod!,
        totalAmount: totalAmount,
        onComplete: (p0) {
          savePay(
            paymentMethod: PAYMENT_METHOD_RAZOR,
            paymentStatus: widget.isForAdvancePayment
                ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                : SERVICE_PAYMENT_STATUS_PAID,
            txnId: p0['paymentId'],
          );
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
              amount: totalAmount.toDouble(), // 50 SAR
              paymentSetting: currentPaymentMethod!,
              description: 'Test Payment',
              metadata: {
                'booking_id': widget.bookings.bookingDetail!.id.validate(),
                'service_id':
                    widget.bookings.bookingDetail!.serviceId.validate(),
              },
              isForAdvancePayment: widget.isForAdvancePayment,
              savePay: (txnId) {
                savePay(
                  txnId: txnId,
                  paymentMethod: PAYMENT_METHOD_MOYASAR,
                  paymentStatus: widget.isForAdvancePayment
                      ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                      : SERVICE_PAYMENT_STATUS_PAID,
                );
              },
              onSuccess: (response) {
                print('${language.paymentSuccessful}: ${response.id}');
                print(
                    'Moyasar full response: ${jsonEncode(response.toJson())}');
                // Handle successful payment
              },
              onError: (error) {
                print('${language.paymentError}: $error');
                // Handle payment
              }),
        ),
      );
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_FLUTTER_WAVE) {
      FlutterWaveServiceNew flutterWaveServiceNew = FlutterWaveServiceNew();

      flutterWaveServiceNew.checkout(
        paymentSetting: currentPaymentMethod!,
        totalAmount: totalAmount,
        onComplete: (p0) {
          savePay(
            paymentMethod: PAYMENT_METHOD_FLUTTER_WAVE,
            paymentStatus: widget.isForAdvancePayment
                ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                : SERVICE_PAYMENT_STATUS_PAID,
            txnId: p0['transaction_id'],
          );
        },
      );
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_CINETPAY) {
      List<String> supportedCurrencies = ["XOF", "XAF", "CDF", "GNF", "USD"];

      if (!supportedCurrencies.contains(appConfigurationStore.currencyCode)) {
        toast(language.cinetPayNotSupportedMessage);
        return;
      } else if (totalAmount < 100) {
        return toast(
            '${language.totalAmountShouldBeMoreThan} ${100.toPriceFormat()}');
      } else if (totalAmount > 1500000) {
        return toast(
            '${language.totalAmountShouldBeLessThan} ${1500000.toPriceFormat()}');
      }

      CinetPayServicesNew cinetPayServices = CinetPayServicesNew(
        paymentSetting: currentPaymentMethod!,
        totalAmount: totalAmount,
        onComplete: (p0) {
          savePay(
            paymentMethod: PAYMENT_METHOD_CINETPAY,
            paymentStatus: widget.isForAdvancePayment
                ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                : SERVICE_PAYMENT_STATUS_PAID,
            txnId: p0['transaction_id'],
          );
        },
      );

      cinetPayServices.payWithCinetPay(context: context).catchError((e) {
        appStore.setLoading(false);
        toast(e);
      });
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_SADAD_PAYMENT) {
      SadadServicesNew sadadServices = SadadServicesNew(
        paymentSetting: currentPaymentMethod!,
        totalAmount: totalAmount,
        remarks: language.topUpWallet,
        onComplete: (p0) {
          savePay(
            paymentMethod: PAYMENT_METHOD_SADAD_PAYMENT,
            paymentStatus: widget.isForAdvancePayment
                ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                : SERVICE_PAYMENT_STATUS_PAID,
            txnId: p0['transaction_id'],
          );
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
        totalAmount: totalAmount,
        onComplete: (p0) {
          log('PayPalService onComplete: $p0');
          savePay(
            paymentMethod: PAYMENT_METHOD_PAYPAL,
            paymentStatus: widget.isForAdvancePayment
                ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                : SERVICE_PAYMENT_STATUS_PAID,
            txnId: p0['transaction_id'],
          );
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
              amount: totalAmount,
              reference: APP_NAME,
              paymentSetting: currentPaymentMethod!,
              bookingId: widget.bookings.bookingDetail != null
                  ? widget.bookings.bookingDetail!.id.validate()
                  : 0,
              onComplete: (res) {
                log('RES: $res');
                savePay(
                  paymentMethod: PAYMENT_METHOD_AIRTEL,
                  paymentStatus: widget.isForAdvancePayment
                      ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                      : SERVICE_PAYMENT_STATUS_PAID,
                  txnId: res['transaction_id'],
                );
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
        totalAmount: totalAmount.toDouble(),
        bookingId: widget.bookings.bookingDetail != null
            ? widget.bookings.bookingDetail!.id.validate()
            : 0,
        onComplete: (res) {
          savePay(
            paymentMethod: PAYMENT_METHOD_PAYSTACK,
            paymentStatus: widget.isForAdvancePayment
                ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                : SERVICE_PAYMENT_STATUS_PAID,
            txnId: res["transaction_id"],
          );
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
        totalAmount: totalAmount,
        serviceId: widget.bookings.bookingDetail != null
            ? widget.bookings.bookingDetail!.serviceId.validate()
            : 0,
        serviceName: widget.bookings.bookingDetail != null
            ? widget.bookings.bookingDetail!.serviceName.validate()
            : '',
        servicePrice: widget.bookings.bookingDetail != null
            ? widget.bookings.bookingDetail!.amount.validate()
            : 0,
        loaderOnOFF: (p0) {
          appStore.setLoading(p0);
        },
        onComplete: (res) {
          savePay(
            paymentMethod: PAYMENT_METHOD_MIDTRANS,
            paymentStatus: widget.isForAdvancePayment
                ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                : SERVICE_PAYMENT_STATUS_PAID,
            txnId: res["transaction_id"],
          );
        },
      );
      await Future.delayed(const Duration(seconds: 1));
      appStore.setLoading(false);
      midtransService.midtransPaymentCheckout().catchError((e) {
        appStore.setLoading(false);
        toast(e);
      });
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_PHONEPE) {
      appStore.setLoading(false);
      PhonePeServices peServices = PhonePeServices(
        paymentSetting: currentPaymentMethod!,
        totalAmount: totalAmount.toDouble(),
        bookingId: widget.bookings.bookingDetail != null
            ? widget.bookings.bookingDetail!.id.validate()
            : 0,
        onComplete: (res) {
          log('RES: $res');
          savePay(
            paymentMethod: PAYMENT_METHOD_PHONEPE,
            paymentStatus: widget.isForAdvancePayment
                ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                : SERVICE_PAYMENT_STATUS_PAID,
            txnId: res["transaction_id"],
          );
        },
      );

      peServices.phonePeCheckout(context).catchError((e) {
        appStore.setLoading(false);
        toast(e);
      });
    }
    /*else if (currentPaymentMethod!.type == PAYMENT_METHOD_MYFATOORAH) {
      if (appStore.userContactNumber.isEmpty) {
        toast(language.lblAddPhoneNumberToProfile);
        EditProfileScreen().launch(context);
      }
      try {
        MyFatoorahService mfService = MyFatoorahService(
            paymentSetting: currentPaymentMethod!,
            onSuccess: (String id) {
              savePay(
                paymentMethod: PAYMENT_METHOD_MYFATOORAH,
                paymentStatus: widget.isForAdvancePayment
                    ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                    : SERVICE_PAYMENT_STATUS_PAID,
                txnId: id.isNotEmpty ? id : Random().nextInt(10000).toString(),
              );
            },
            onError: (value) {
              print('value: ${value}');
            },
            onLog: (value) {});
        appStore.setLoading(true);

        await mfService.initializeSDK().then(
              (value) async {
            mfService.startApplePay(amount: totalAmount.toDouble());
          },
        );
        await Future.delayed(Duration(seconds: 2));

        mfService
            .initiatePayment(
          amount: totalAmount.toDouble(),
          currencyIso: mf.MFCurrencyISO.SAUDIARABIA_SAR,
        )
            .then((value) {
          fatoorahPaymentList = value.data?.paymentMethods ?? [];
          fatoorahPaymentList
              .removeWhere((element) => element.paymentMethodId == 13);
          setState(() {});
          appStore.setLoading(false);
          _showPaymentOptions(
              amount: totalAmount.toDouble(), mfService: mfService);
        });
      } catch (e) {
        toast(e.toString());
      }
    }*/

    else if (currentPaymentMethod!.type == PAYMENT_METHOD_FROM_WALLET) {
      savePay(
        paymentMethod: PAYMENT_METHOD_FROM_WALLET,
        paymentStatus: widget.isForAdvancePayment
            ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
            : SERVICE_PAYMENT_STATUS_PAID,
        txnId: '',
      );
    } else {
      // No branch above matched this gateway's type (e.g. MyFatoorah, whose
      // handler is commented out above) — without this, the loading
      // spinner set at the top of this method would spin forever with no
      // way for the user to recover except backing out of the screen.
      appStore.setLoading(false);
      toast(language.somethingWentWrong);
    }
  }

  void savePay(
      {String txnId = '',
      String paymentMethod = '',
      String paymentStatus = ''}) async {
    Map request = {
      CommonKeys.bookingId: widget.bookings.bookingDetail!.id.validate(),
      CommonKeys.customerId: appStore.userId,
      CouponKeys.discount: widget.bookings.service!.discount,
      BookingServiceKeys.totalAmount: totalAmount,
      CommonKeys.dateTime:
          DateFormat(BOOKING_SAVE_FORMAT).format(DateTime.now()),
      CommonKeys.txnId: txnId != ''
          ? txnId
          : "#${widget.bookings.bookingDetail!.id.validate()}",
      CommonKeys.paymentStatus: paymentStatus,
      CommonKeys.paymentMethod: paymentMethod,
    };

    if (widget.bookings.service != null &&
        widget.bookings.service!.isAdvancePayment &&
        widget.bookings.service!.isFixedService &&
        !widget.bookings.service!.isFreeService &&
        widget.bookings.bookingDetail!.bookingPackage == null) {
      request[AdvancePaymentKey.advancePaymentAmount] =
          advancePaymentAmount ?? widget.bookings.bookingDetail!.paidAmount;

      if ((widget.bookings.bookingDetail!.paymentStatus == null ||
              widget.bookings.bookingDetail!.paymentStatus !=
                  SERVICE_PAYMENT_STATUS_ADVANCE_PAID ||
              widget.bookings.bookingDetail!.paymentStatus !=
                  SERVICE_PAYMENT_STATUS_PAID) &&
          (widget.bookings.bookingDetail!.paidAmount == null ||
              widget.bookings.bookingDetail!.paidAmount.validate() <= 0)) {
        // TODO: check this condition  widget.bookings.bookingPackage?.id == -1
        request[CommonKeys.paymentStatus] = SERVICE_PAYMENT_STATUS_ADVANCE_PAID;
      } else if (widget.bookings.bookingDetail!.paymentStatus ==
          SERVICE_PAYMENT_STATUS_ADVANCE_PAID) {
        request[CommonKeys.paymentStatus] = SERVICE_PAYMENT_STATUS_PAID;
      }
    }

    appStore.setLoading(true);
    savePayment(request).then((value) {
      appStore.setLoading(false);
      push(DashboardScreen(redirectToBooking: true),
          isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
    }).catchError((e) {
      toast(e.toString());
      appStore.setLoading(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: language.payment,
      child: Stack(
        children: [
          AnimatedScrollView(
            listAnimationType: ListAnimationType.FadeIn,
            fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(bottom: 110),
            onSwipeRefresh: () async {
              if (!appStore.isLoading) init();
              return await 1.seconds.delay;
            },
            children: [
              // ── Amount header card ───────────────────────────────────────
              Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.primaryColor,
                      context.primaryColor.withValues(alpha: 0.72),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: context.primaryColor.withValues(alpha: 0.32),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          language.totalAmount,
                          style: secondaryTextStyle(
                              color: Colors.white.withValues(alpha: 0.80),
                              size: 13),
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '#${widget.bookings.bookingDetail!.id.validate()}',
                            style: secondaryTextStyle(
                                color: Colors.white, size: 11),
                          ),
                        ),
                      ],
                    ),
                    10.height,
                    Text(
                      totalAmount.toPriceFormat(),
                      style: boldTextStyle(
                          color: Colors.white,
                          size: 32,
                          fontFamily: saudiRiyalsFontFamily),
                    ),
                    if (widget.bookings.service?.name.validate().isNotEmpty ==
                        true) ...[
                      10.height,
                      Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.20),
                      ),
                      10.height,
                      Row(
                        children: [
                          Icon(Icons.home_repair_service_rounded,
                              color: Colors.white.withValues(alpha: 0.75),
                              size: 14),
                          6.width,
                          Text(
                            widget.bookings.service!.name.validate(),
                            style: secondaryTextStyle(
                                color: Colors.white.withValues(alpha: 0.82),
                                size: 13),
                          ).expand(),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // ── Price breakdown card ─────────────────────────────────────
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: appStore.isDarkMode ? 0.20 : 0.06),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: PriceCommonWidget(
                  bookingDetail: widget.bookings.bookingDetail!,
                  serviceDetail: widget.bookings.service!,
                  taxes: widget.bookings.bookingDetail!.taxes.validate(),
                  couponData: widget.bookings.couponData,
                  bookingPackage: widget.bookings.bookingDetail!.bookingPackage,
                  postRequestDetail: widget.bookings.postRequestDetail,
                ),
              ),

              20.height,

              // ── Payment method section header ────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.payment_rounded,
                          size: 16, color: context.primaryColor),
                    ),
                    10.width,
                    Text(language.lblChoosePaymentMethod,
                        style: boldTextStyle(size: LABEL_TEXT_SIZE)),
                  ],
                ),
              ),
              12.height,

              // ── Payment method cards ─────────────────────────────────────
              SnapHelperWidget<List<PaymentSetting>>(
                future: future,
                onSuccess: (list) {
                  return AnimatedListView(
                    itemCount: list.length,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    listAnimationType: ListAnimationType.FadeIn,
                    fadeInConfiguration:
                        FadeInConfiguration(duration: 2.seconds),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    emptyWidget: NoDataWidget(
                      title: language.noPaymentMethodFound,
                      imageWidget: EmptyStateWidget(),
                    ),
                    itemBuilder: (context, index) {
                      PaymentSetting value = list[index];
                      if (value.status.validate() == 0) return Offstage();
                      final bool isSelected = currentPaymentMethod == value;
                      return GestureDetector(
                        onTap: () {
                          currentPaymentMethod = value;
                          setState(() {});
                        },
                        child: AnimatedContainer(
                          duration: 200.milliseconds,
                          margin: EdgeInsets.only(bottom: 10),
                          padding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? context.primaryColor.withValues(alpha: 0.06)
                                : context.cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? context.primaryColor
                                  : context.dividerColor.withValues(alpha: 0.5),
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                    alpha: isSelected ? 0.06 : 0.04),
                                blurRadius: isSelected ? 10 : 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? context.primaryColor
                                          .withValues(alpha: 0.12)
                                      : context.scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _paymentMethodIcon(value.type.validate()),
                                  size: 20,
                                  color: isSelected
                                      ? context.primaryColor
                                      : textSecondaryColorGlobal,
                                ),
                              ),
                              12.width,
                              Text(value.title.validate(),
                                      style: primaryTextStyle())
                                  .expand(),
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? context.primaryColor
                                        : context.dividerColor,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? Center(
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: context.primaryColor,
                                          ),
                                        ),
                                      )
                                    : SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              // ── Wallet balance ───────────────────────────────────────────
              if (appConfigurationStore.isEnableUserWallet)
                WalletBalanceComponent()
                    .paddingSymmetric(vertical: 8, horizontal: 16),
            ],
          ),

          // ── Sticky Pay Now button ────────────────────────────────────────
          if (!appStore.isLoading)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 28),
                decoration: BoxDecoration(
                  color: context.scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: () async {
                    appStore.setLoading(false);
                    if (currentPaymentMethod == null) {
                      return toast(language.chooseAnyOnePayment);
                    }

                    if (currentPaymentMethod!.type == PAYMENT_METHOD_COD ||
                        currentPaymentMethod!.type ==
                            PAYMENT_METHOD_FROM_WALLET) {
                      if (currentPaymentMethod!.type ==
                          PAYMENT_METHOD_FROM_WALLET) {
                        appStore.setLoading(true);
                        num walletBalance = await getUserWalletBalance();
                        appStore.setLoading(false);
                        if (walletBalance >= totalAmount) {
                          showConfirmDialogCustom(
                            context,
                            dialogType: DialogType.CONFIRMATION,
                            title:
                                "${language.lblPayWith} ${currentPaymentMethod!.title.validate()}?",
                            primaryColor: primaryColor,
                            positiveText: language.lblYes,
                            negativeText: language.lblCancel,
                            onAccept: (p0) => _handleClick(),
                          );
                        } else {
                          toast(language.insufficientBalanceMessage);
                          if (appConfigurationStore.onlinePaymentStatus) {
                            showConfirmDialogCustom(
                              context,
                              dialogType: DialogType.CONFIRMATION,
                              title: language.doYouWantToTopUpYourWallet,
                              positiveText: language.lblYes,
                              negativeText: language.lblNo,
                              cancelable: false,
                              primaryColor: context.primaryColor,
                              onAccept: (p0) {
                                pop();
                                push(UserWalletBalanceScreen());
                              },
                              onCancel: (p0) => pop(),
                            );
                          }
                        }
                      } else {
                        showConfirmDialogCustom(
                          context,
                          dialogType: DialogType.CONFIRMATION,
                          title:
                              "${language.lblPayWith} ${currentPaymentMethod!.title.validate()}?",
                          primaryColor: primaryColor,
                          positiveText: language.lblYes,
                          negativeText: language.lblCancel,
                          onAccept: (p0) => _handleClick(),
                        );
                      }
                    } else {
                      _handleClick().catchError((e) {
                        appStore.setLoading(false);
                        toast(e.toString());
                      });
                    }
                  },
                  child: Container(
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          context.primaryColor,
                          context.primaryColor.withValues(alpha: 0.78),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: context.primaryColor.withValues(alpha: 0.38),
                          blurRadius: 14,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                        10.width,
                        Text(
                          "${language.lblPayNow}  ${totalAmount.toPriceFormat()}",
                          style: boldTextStyle(
                            color: Colors.white,
                            size: 16,
                            fontFamily: saudiRiyalsFontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _paymentMethodIcon(String type) {
    switch (type) {
      case PAYMENT_METHOD_COD:
        return Icons.money_rounded;
      case PAYMENT_METHOD_FROM_WALLET:
        return Icons.account_balance_wallet_rounded;
      case PAYMENT_METHOD_STRIPE:
        return Icons.credit_card_rounded;
      case PAYMENT_METHOD_RAZOR:
        return Icons.currency_rupee_rounded;
      case PAYMENT_METHOD_PAYPAL:
        return Icons.account_balance_rounded;
      case PAYMENT_METHOD_FLUTTER_WAVE:
        return Icons.waves_rounded;
      case PAYMENT_METHOD_AIRTEL:
        return Icons.phone_android_rounded;
      case PAYMENT_METHOD_PAYSTACK:
        return Icons.payments_rounded;
      case PAYMENT_METHOD_MIDTRANS:
        return Icons.swap_horiz_rounded;
      case PAYMENT_METHOD_PHONEPE:
        return Icons.phone_iphone_rounded;
      case PAYMENT_METHOD_MYFATOORAH:
        return Icons.receipt_long_rounded;
      case PAYMENT_METHOD_MOYASAR:
        return Icons.paid_rounded;
      case PAYMENT_METHOD_SADAD_PAYMENT:
        return Icons.store_rounded;
      case PAYMENT_METHOD_CINETPAY:
        return Icons.movie_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  int _selectedPaymentMethod = -1;
  PaymentMethod? currentFatoorahPayment;
  List<PaymentMethod> fatoorahPaymentList = [];

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

  void _showCreditCardForm({
    required MyFatoorahService mfService,
    required ExecutePaymentData executePaymentData,
    required double amount,
    required String paymentMethodCode,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: CreditCardFormBottomSheet(
            mfService: mfService,
            amount: amount,
            executePaymentData: executePaymentData,
            paymentMethodCode: paymentMethodCode,
            onComplete: (id) {
              savePay(
                paymentMethod: PAYMENT_METHOD_MOYASAR,
                paymentStatus: widget.isForAdvancePayment
                    ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                    : SERVICE_PAYMENT_STATUS_PAID,
                txnId: id.isNotEmpty ? id : Random().nextInt(10000).toString(),
              );
            },
            onCancel: (p0) {
              finish(context);
              toast(language.lblTransactionCancelled);
            },
          ),
        );
      },
    );
  }
}
