import 'package:booking_system_flutter/component/base_scaffold_body.dart';
import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/price_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/package_data_model.dart';
import 'package:booking_system_flutter/model/service_detail_response.dart';
import 'package:booking_system_flutter/screens/booking/component/confirm_booking_dialog.dart';
import 'package:booking_system_flutter/screens/map/map_screen.dart';
import 'package:booking_system_flutter/screens/service/service_detail_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:booking_system_flutter/utils/custom_app_field.dart';

import '../../../component/wallet_balance_component.dart';
import '../../../model/booking_amount_model.dart';
import '../../../utils/booking_calculations_logic.dart';
import '../../component/back_widget.dart';
// import '../../component/chat_gpt_loder.dart'; // ChatGPT description assist — disabled for now.
import '../../services/location_service.dart';
import '../../utils/permissions.dart';
import '../service/addons/service_addons_component.dart';
import 'component/booking_slots.dart';
import 'component/coupon_list_screen.dart';
import 'component/custom_date_time_picker.dart';

class BookServiceScreen extends StatefulWidget {
  final ServiceDetailResponse data;
  final BookingPackage? selectedPackage;

  BookServiceScreen({required this.data, this.selectedPackage});

  @override
  _BookServiceScreenState createState() => _BookServiceScreenState();
}

class _BookServiceScreenState extends State<BookServiceScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  CouponData? appliedCouponData;

  BookingAmountModel bookingAmountModel = BookingAmountModel();
  num advancePaymentAmount = 0;

  int itemCount = 1;

  //Service add-on
  double imageHeight = 60;

  TextEditingController addressCont = TextEditingController();
  TextEditingController descriptionCont = TextEditingController();

  TextEditingController dateTimeCont = TextEditingController();
  DateTime currentDateTime = DateTime.now();
  DateTime? selectedDate;
  DateTime? finalDate;
  DateTime? packageExpiryDate;
  TimeOfDay? pickedTime;

  @override
  void initState() {
    super.initState();
    init();

    if (widget.selectedPackage != null &&
        widget.selectedPackage!.endDate.validate().isNotEmpty) {
      packageExpiryDate =
          DateTime.parse(widget.selectedPackage!.endDate.validate());
    }

    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void init() async {
    setPrice();
    try {
      if (widget.data.serviceDetail != null) {
        if (widget.data.serviceDetail!.dateTimeVal != null) {
          if (widget.data.serviceDetail!.isSlotAvailable.validate()) {
            dateTimeCont.text = formatBookingDate(
                widget.data.serviceDetail!.dateTimeVal.validate(),
                format: DATE_FORMAT_1);
            selectedDate = DateTime.parse(
                widget.data.serviceDetail!.dateTimeVal.validate());
            pickedTime = TimeOfDay.fromDateTime(selectedDate!);
          }
          addressCont.text = widget.data.serviceDetail!.address.validate();
        }
      }
    } catch (e) {}
  }

  void _handleSetLocationClick() {
    Permissions.cameraFilesAndLocationPermissionsGranted().then((value) async {
      await setValue(PERMISSION_STATUS, value);

      if (value) {
        String? res = await MapScreen(
                latitude: getDoubleAsync(LATITUDE),
                latLong: getDoubleAsync(LONGITUDE))
            .launch(context);

        addressCont.text = res.validate();
        setState(() {});
      }
    });
  }

  void _handleCurrentLocationClick() {
    Permissions.cameraFilesAndLocationPermissionsGranted().then((value) async {
      await setValue(PERMISSION_STATUS, value);

      if (value) {
        appStore.setLoading(true);

        await getUserLocation().then((value) {
          addressCont.text = value;
          widget.data.serviceDetail!.address = value.toString();
          setState(() {});
        }).catchError((e) {
          log(e);
          // toast(e.toString());
        });

        appStore.setLoading(false);
      }
    }).catchError((e) {
      //
    }).whenComplete(() => appStore.setLoading(false));
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  void setPrice() {
    bookingAmountModel = finalCalculations(
      servicePrice: widget.data.serviceDetail!.price.validate(),
      appliedCouponData: appliedCouponData,
      serviceAddons: serviceAddonStore.selectedServiceAddon,
      discount: widget.data.serviceDetail!.discount.validate(),
      taxes: widget.data.taxes,
      quantity: itemCount,
      selectedPackage: widget.selectedPackage,
      vatPercentage: widget.data.vatPercentage,
      platformCommissionPercentage:
          widget.data.platformCommissionEarningPercentage,
    );

    if (bookingAmountModel.finalSubTotal.isNegative) {
      appliedCouponData = null;
      setPrice();

      toast(language.youCannotApplyThisCoupon);
    } else {
      advancePaymentAmount = (bookingAmountModel.finalGrandTotalAmount *
          (widget.data.serviceDetail!.advancePaymentPercentage.validate() / 100)
              .toStringAsFixed(appConfigurationStore.priceDecimalPoint)
              .toDouble());
    }
    setState(() {});
  }

  String get platformCommissionLabel => bookingAmountModel
              .platformCommissionPercentage !=
          0
      ? '${language.platformCommission} (${bookingAmountModel.platformCommissionPercentage.toStringAsFixed(0)}%)'
      : language.platformCommission;

  void applyCoupon({bool isApplied = false}) async {
    hideKeyboard(context);
    if (widget.data.serviceDetail != null &&
        widget.data.serviceDetail!.id != null) {
      var value = await CouponsScreen(
              serviceId: widget.data.serviceDetail!.id!.toInt(),
              servicePrice: bookingAmountModel.finalTotalServicePrice,
              appliedCouponData: appliedCouponData)
          .launch(context);
      if (value != null) {
        if (value is bool && !value) {
          appliedCouponData = null;
        } else if (value is CouponData) {
          appliedCouponData = value;
        } else {
          appliedCouponData = null;
        }
        setPrice();
      }
    }
  }

  void selectDateAndTime(BuildContext context) async {
    if (packageExpiryDate != null &&
        currentDateTime.isAfter(packageExpiryDate!)) {
      return toast(language.packageIsExpired);
    }

    final DateTime? result = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomDateTimePickerSheet(
        firstDate: currentDateTime,
        lastDate: packageExpiryDate ?? currentDateTime.add(30.days),
        initialDate: selectedDate,
        initialTime: pickedTime,
      ),
    );

    if (result != null) {
      finalDate = result;

      DateTime now = DateTime.now().subtract(1.minutes);
      if (result.isToday &&
          finalDate!.millisecondsSinceEpoch < now.millisecondsSinceEpoch) {
        return toast(language.selectedOtherBookingTime);
      }

      selectedDate = DateTime(result.year, result.month, result.day);
      pickedTime = TimeOfDay(hour: result.hour, minute: result.minute);
      widget.data.serviceDetail?.dateTimeVal = finalDate.toString();
      dateTimeCont.text =
          "${formatBookingDate(selectedDate.toString(), format: DATE_FORMAT_3)} ${pickedTime?.format(context).toString()}";
      setState(() {});
    }
  }

  void handleDateTimePick() {
    hideKeyboard(context);
    if (widget.data.serviceDetail!.isSlot == 1) {
      showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        shape: RoundedRectangleBorder(
            borderRadius:
                radiusOnly(topLeft: defaultRadius, topRight: defaultRadius)),
        builder: (_) {
          return DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.65,
            maxChildSize: 1,
            builder: (context, scrollController) => BookingSlotsComponent(
              data: widget.data,
              showAppbar: true,
              scrollController: scrollController,
              onApplyClick: () {
                setState(() {});
              },
            ),
          );
        },
      );
    } else {
      selectDateAndTime(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(
        widget.selectedPackage == null
            ? language.bookTheService
            : language.bookPackage,
        textColor: Colors.white,
        color: context.primaryColor,
        backWidget: BackWidget(),
      ),
      body: Body(
        showLoader: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.selectedPackage == null)
                    _sectionHeader(
                        Icons.room_service_outlined, language.service),
                  if (widget.selectedPackage == null) 8.height,
                  if (widget.selectedPackage == null) serviceWidget(context),

                  packageWidget(),

                  addressAndDescriptionWidget(context),

                  _sectionHeader(
                      Icons.description_outlined, language.hintDescription),
                  8.height,
                  CustomAppTextField(
                    textFieldType: TextFieldType.MULTILINE,
                    controller: descriptionCont,
                    maxLines: 10,
                    minLines: 3,
                    isValidationRequired: false,
                    // ChatGPT description assist — disabled for now, not in use.
                    // enableChatGPT: appConfigurationStore.chatGPTStatus,
                    // promptFieldInputDecorationChatGPT:
                    //     inputDecoration(context).copyWith(
                    //   hintText: language.writeHere,
                    //   fillColor: context.scaffoldBackgroundColor,
                    //   filled: true,
                    //   hintStyle: primaryTextStyle(),
                    // ),
                    // testWithoutKeyChatGPT: appConfigurationStore.testWithoutKey,
                    // loaderWidgetForChatGPT: const ChatGPTLoadingWidget(),
                    onFieldSubmitted: (s) {
                      widget.data.serviceDetail!.bookingDescription = s;
                    },
                    onChanged: (s) {
                      widget.data.serviceDetail!.bookingDescription = s;
                    },
                    decoration: inputDecoration(context).copyWith(
                      fillColor: context.cardColor,
                      filled: true,
                      hintText: language.lblEnterDescription,
                      hintStyle: secondaryTextStyle(),
                    ),
                  ),

                  /// Only active status package display
                  if (serviceAddonStore.selectedServiceAddon
                      .validate()
                      .isNotEmpty)
                    AddonComponent(
                      isFromBookingLastStep: true,
                      serviceAddon: serviceAddonStore.selectedServiceAddon,
                      onSelectionChange: (v) {
                        serviceAddonStore.setSelectedServiceAddon(v);
                        setPrice();
                      },
                    ),

                  buildBookingSummaryWidget(),

                  16.height,

                  priceWidget(),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Observer(builder: (context) {
                        return WalletBalanceComponent().visible(
                            appConfigurationStore.isEnableUserWallet &&
                                widget.data.serviceDetail!.isFixedService);
                      }),
                      16.height,
                      _sectionHeader(
                          Icons.info_outline_rounded, language.disclaimer),
                      Text(language.disclaimerContent,
                          style: secondaryTextStyle()),
                    ],
                  ).paddingSymmetric(vertical: 16),

                  36.height,

                  Container(
                    decoration: BoxDecoration(
                      borderRadius: radius(16),
                      boxShadow: [
                        BoxShadow(
                          color: context.primaryColor.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        AppButton(
                          color: context.primaryColor,
                          shapeBorder:
                              RoundedRectangleBorder(borderRadius: radius(16)),
                          elevation: 0,
                          text: widget.data.serviceDetail!.isAdvancePayment &&
                                  !widget.data.serviceDetail!.isFreeService &&
                                  widget.data.serviceDetail!.isFixedService
                              ? language.advancePayment
                              : language.confirm,
                          textColor: Colors.white,
                          onTap: () {
                            if (widget.data.serviceDetail!.isOnSiteService &&
                                addressCont.text.isEmpty &&
                                widget.data.serviceDetail!.dateTimeVal
                                    .validate()
                                    .isEmpty) {
                              toast(language.pleaseEnterAddressAnd);
                            } else if (widget
                                    .data.serviceDetail!.isOnSiteService &&
                                addressCont.text.isEmpty) {
                              toast(language.pleaseEnterYourAddress);
                            } else if ((widget.data.serviceDetail!.isSlot !=
                                        1 &&
                                    widget.data.serviceDetail!.dateTimeVal
                                        .validate()
                                        .isEmpty) ||
                                (widget.data.serviceDetail!.isSlot == 1 &&
                                    (widget.data.serviceDetail!.bookingSlot ==
                                            null ||
                                        widget.data.serviceDetail!.bookingSlot
                                            .validate()
                                            .isEmpty))) {
                              toast(language.pleaseSelectBookingDate);
                            } else {
                              widget.data.serviceDetail!.address =
                                  addressCont.text;
                              showInDialog(
                                context,
                                barrierDismissible: false,
                                builder: (p0) {
                                  return ConfirmBookingDialog(
                                    data: widget.data,
                                    bookingPrice: bookingAmountModel
                                        .finalGrandTotalAmount,
                                    selectedPackage: widget.selectedPackage,
                                    qty: itemCount,
                                    couponCode: appliedCouponData?.code,
                                    bookingAmountModel: BookingAmountModel(
                                        finalCouponDiscountAmount:
                                            bookingAmountModel
                                                .finalCouponDiscountAmount,
                                        finalDiscountAmount: bookingAmountModel
                                            .finalDiscountAmount,
                                        finalSubTotal:
                                            bookingAmountModel.finalSubTotal,
                                        finalTotalServicePrice:
                                            bookingAmountModel
                                                .finalTotalServicePrice,
                                        finalTotalTax: !widget.data
                                                .serviceDetail!.isFreeService
                                            ? bookingAmountModel.finalTotalTax
                                            : 0,
                                        totalPlatformCommissionAmount:
                                            bookingAmountModel
                                                .totalPlatformCommissionAmount),
                                  );
                                },
                              );
                            }
                          },
                        ).expand(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: context.primaryColor.withValues(alpha: 0.1),
            borderRadius: radius(8),
          ),
          child: Icon(icon, size: 15, color: context.primaryColor),
        ),
        8.width,
        Text(title, style: boldTextStyle(size: LABEL_TEXT_SIZE)),
      ],
    );
  }

  Widget addressFieldWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        16.height,
        _sectionHeader(Icons.location_on_outlined, language.lblYourAddress),
        8.height,
        CustomAppTextField(
          textFieldType: TextFieldType.MULTILINE,
          controller: addressCont,
          maxLines: 3,
          minLines: 3,
          onFieldSubmitted: (s) {
            widget.data.serviceDetail!.address = s;
          },
          decoration: inputDecoration(
            context,
            prefixIcon: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ic_location.iconImage(size: 22).paddingOnly(top: 0),
              ],
            ),
          ).copyWith(
            fillColor: context.cardColor,
            filled: true,
            hintText: language.lblEnterYourAddress,
            hintStyle: secondaryTextStyle(),
          ),
        ),
        8.height,
        Row(
          children: [
            Flexible(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.08),
                  borderRadius: radius(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_outlined, size: 15, color: primaryColor),
                    6.width,
                    Flexible(
                      child: Text(language.lblChooseFromMap,
                          style: boldTextStyle(color: primaryColor, size: 12),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ).onTap(_handleSetLocationClick),
            ),
            10.width,
            Flexible(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.08),
                  borderRadius: radius(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.my_location_rounded,
                        size: 15, color: primaryColor),
                    6.width,
                    Flexible(
                      child: Text(language.lblUseCurrentLocation,
                          style: boldTextStyle(color: primaryColor, size: 12),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ).onTap(_handleCurrentLocationClick),
            ),
          ],
        ),
      ],
    );
  }

  Widget addressAndDescriptionWidget(BuildContext context) {
    return Column(
      children: [
        if (widget.data.serviceDetail!.isOnSiteService)
          addressFieldWidget()
        else if ((widget.selectedPackage != null &&
            !widget.selectedPackage!.isAllServiceOnline))
          addressFieldWidget()
        else if ((widget.selectedPackage != null &&
                widget.selectedPackage!.isAllServiceOnline) &&
            widget.data.serviceDetail!.isOnlineService)
          Text(language.noteAddressIsNot, style: secondaryTextStyle())
              .paddingTop(16),
        16.height.visible(!widget.data.serviceDetail!.isOnSiteService),
      ],
    );
  }

  Widget serviceWidget(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: radius(18),
        border: appStore.isDarkMode
            ? Border.all(color: context.dividerColor)
            : null,
        boxShadow: appStore.isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      width: context.width(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CachedImageWidget(
            url: widget.data.serviceDetail!.attachments.validate().isNotEmpty
                ? widget.data.serviceDetail!.attachments!.first.validate()
                : '',
            height: 72,
            width: 72,
            fit: BoxFit.cover,
            radius: 14,
          ),
          14.width,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.data.serviceDetail!.name.validate(),
                  style: boldTextStyle()),
              4.height,
              if ((convertToHourMinute(
                      widget.data.serviceDetail!.duration.validate()))
                  .isNotEmpty)
                Text(
                    '${language.duration} (${convertToHourMinute(widget.data.serviceDetail!.duration.validate())})',
                    style: secondaryTextStyle()),
              16.height,
              if (widget.data.serviceDetail!.isFixedService)
                Container(
                  height: 40,
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.08),
                    borderRadius: radius(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.remove_circle_rounded,
                              size: 22, color: context.primaryColor)
                          .onTap(
                        () {
                          if (itemCount != 1) itemCount--;
                          setPrice();
                        },
                      ),
                      16.width,
                      Text(itemCount.toString(), style: boldTextStyle()),
                      16.width,
                      Icon(Icons.add_circle_rounded,
                              size: 22, color: context.primaryColor)
                          .onTap(
                        () {
                          itemCount++;
                          setPrice();
                        },
                      ),
                    ],
                  ),
                )
            ],
          ).expand(),
        ],
      ),
    );
  }

  Widget priceWidget() {
    if (!widget.data.serviceDetail!.isFreeService)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.selectedPackage == null) 16.height,
          if (widget.selectedPackage == null)
            Container(
              padding: EdgeInsets.only(left: 16, top: 8, bottom: 8, right: 8),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: radius(16),
                border: appStore.isDarkMode
                    ? Border.all(color: context.dividerColor)
                    : null,
                boxShadow: appStore.isDarkMode
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: ic_coupon_prefix.iconImage(
                        color: Colors.green, size: 16),
                  ),
                  10.width,
                  Text(language.lblCoupon, style: primaryTextStyle()).expand(),
                  8.width,
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor:
                          context.primaryColor.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(borderRadius: radius(20)),
                      padding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: () {
                      if (appliedCouponData != null) {
                        showConfirmDialogCustom(
                          context,
                          dialogType: DialogType.DELETE,
                          title: language.doYouWantTo,
                          positiveText: language.lblDelete,
                          negativeText: language.lblCancel,
                          onAccept: (p0) {
                            appliedCouponData = null;
                            setPrice();
                            setState(() {});
                          },
                        );
                      } else {
                        applyCoupon();
                      }
                    },
                    child: Text(
                      appliedCouponData != null
                          ? language.lblRemoveCoupon
                          : language.applyCoupon,
                      style:
                          boldTextStyle(color: context.primaryColor, size: 13),
                    ),
                  )
                ],
              ),
            ),
          24.height,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionHeader(Icons.receipt_long_outlined, language.priceDetail),
            ],
          ),
          16.height,
          Container(
            padding: EdgeInsets.all(16),
            width: context.width(),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: radius(18),
              border: appStore.isDarkMode
                  ? Border.all(color: context.dividerColor)
                  : null,
              boxShadow: appStore.isDarkMode
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
            ),
            child: Column(
              children: [
                /// Service or Package Price
                Row(
                  children: [
                    Text(language.lblPrice, style: secondaryTextStyle(size: 14))
                        .expand(),
                    16.width,
                    if (widget.selectedPackage != null)
                      PriceWidget(
                          price: bookingAmountModel.finalTotalServicePrice,
                          color: textPrimaryColorGlobal,
                          isBoldText: true)
                    else if (!widget.data.serviceDetail!.isHourlyService)
                      Marquee(
                        child: Row(
                          children: [
                            PriceWidget(
                                price:
                                    widget.data.serviceDetail!.price.validate(),
                                size: 12,
                                isBoldText: false,
                                color: textSecondaryColorGlobal),
                            Text(' * $itemCount  = ',
                                style: secondaryTextStyle()),
                            PriceWidget(
                                price:
                                    bookingAmountModel.finalTotalServicePrice,
                                color: textPrimaryColorGlobal),
                          ],
                        ),
                      )
                    else
                      PriceWidget(
                          price: bookingAmountModel.finalTotalServicePrice,
                          color: textPrimaryColorGlobal,
                          isBoldText: true)
                  ],
                ),

                /// Fix Discount on Base Price
                if (widget.data.serviceDetail!.discount.validate() != 0 &&
                    widget.selectedPackage == null)
                  Column(
                    children: [
                      Divider(height: 26, color: context.dividerColor),
                      Row(
                        children: [
                          Text(language.lblDiscount,
                              style: secondaryTextStyle(size: 14)),
                          Text(
                            " (${widget.data.serviceDetail!.discount.validate()}% ${language.lblOff.toLowerCase()})",
                            style: boldTextStyle(color: Colors.green),
                          ).expand(),
                          16.width,
                          PriceWidget(
                            price: bookingAmountModel.finalDiscountAmount,
                            color: Colors.green,
                            isBoldText: true,
                          ),
                        ],
                      ),
                    ],
                  ),

                /// Coupon Discount on Base Price
                if (widget.selectedPackage == null)
                  Column(
                    children: [
                      if (appliedCouponData != null)
                        Divider(height: 26, color: context.dividerColor),
                      if (appliedCouponData != null)
                        Row(
                          children: [
                            Row(
                              children: [
                                Text(language.lblCoupon,
                                    style: secondaryTextStyle(size: 14)),
                                Text(
                                  " (${appliedCouponData!.code})",
                                  style: boldTextStyle(
                                      color: primaryColor, size: 14),
                                ).onTap(() {
                                  applyCoupon(
                                      isApplied: appliedCouponData!.code
                                          .validate()
                                          .isNotEmpty);
                                }).expand(),
                              ],
                            ).expand(),
                            PriceWidget(
                              price:
                                  bookingAmountModel.finalCouponDiscountAmount,
                              color: Colors.green,
                              isBoldText: true,
                            ),
                          ],
                        ),
                    ],
                  ),

                /// Show Service Add-on Price
                if (serviceAddonStore.selectedServiceAddon
                    .validate()
                    .isNotEmpty)
                  Column(
                    children: [
                      Divider(height: 26, color: context.dividerColor),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(language.serviceAddOns,
                                  style: secondaryTextStyle(size: 14))
                              .flexible(fit: FlexFit.loose),
                          16.width,
                          PriceWidget(
                              price: bookingAmountModel.finalServiceAddonAmount,
                              color: textPrimaryColorGlobal)
                        ],
                      ),
                    ],
                  ),

                /// Show Subtotal, Total Amount and Apply Discount, Coupon if service is Fixed or Hourly
                if (widget.selectedPackage == null)
                  Column(
                    children: [
                      Divider(height: 26, color: context.dividerColor),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(language.lblSubTotal,
                                  style: secondaryTextStyle(size: 14))
                              .flexible(fit: FlexFit.loose),
                          16.width,
                          PriceWidget(
                              price: bookingAmountModel.finalSubTotal,
                              color: textPrimaryColorGlobal),
                        ],
                      ),
                    ],
                  ),

                /// Tax Amount Applied on Price
                // Column(
                //   children: [
                //     Divider(height: 26, color: context.dividerColor),
                //     Row(
                //       children: [
                //         Row(
                //           children: [
                //             Text(language.lblTax,
                //                     style: secondaryTextStyle(size: 14))
                //                 .expand(),
                //             if (widget.data.taxes.validate().isNotEmpty)
                //               Icon(Icons.info_outline_rounded,
                //                       size: 20, color: context.primaryColor)
                //                   .onTap(
                //                 () {
                //                   showModalBottomSheet(
                //                     context: context,
                //                     builder: (_) {
                //                       return AppliedTaxListBottomSheet(
                //                           taxes: widget.data.taxes.validate(),
                //                           subTotal:
                //                               bookingAmountModel.finalSubTotal);
                //                     },
                //                   );
                //                 },
                //               ),
                //           ],
                //         ).expand(),
                //         16.width,
                //         PriceWidget(
                //             price: bookingAmountModel.finalTotalTax,
                //             color: Colors.red,
                //             isBoldText: true),
                //       ],
                //     ),
                //   ],
                // ),

                /// VAT applied on the booking amount (dynamic, per-service)
                if (bookingAmountModel.vatAmount != 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(height: 26, color: context.dividerColor),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                                  language.vatLabel(
                                      bookingAmountModel.vatPercentage),
                                  style: secondaryTextStyle(size: 14))
                              .expand(),
                          16.width,
                          PriceWidget(
                              price: bookingAmountModel.vatAmount,
                              color: Colors.red,
                              isBoldText: true),
                        ],
                      ),
                      12.height,
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.primaryColor.withValues(alpha: 0.06),
                          borderRadius: radius(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 16, color: context.primaryColor),
                            8.width,
                            Text(
                              language.saudiVatNote(
                                  bookingAmountModel.vatPercentage,
                                  bookingAmountModel
                                      .platformCommissionPercentage),
                              style: secondaryTextStyle(size: 11),
                            ).expand(),
                          ],
                        ),
                      ),
                    ],
                  ),

                /// platform commission
                Column(
                  children: [
                    Divider(height: 26, color: context.dividerColor),
                    Row(
                      children: [
                        Row(
                          children: [
                            Text(platformCommissionLabel,
                                    style: secondaryTextStyle(size: 14))
                                .expand(),
                          ],
                        ).expand(),
                        16.width,
                        PriceWidget(
                            price: bookingAmountModel
                                .totalPlatformCommissionAmount,
                            color: Colors.red,
                            isBoldText: true),
                      ],
                    ),
                  ],
                ),

                /// Final Amount
                Column(
                  children: [
                    Divider(height: 26, color: context.dividerColor),
                    Container(
                      width: context.width(),
                      padding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withValues(alpha: 0.08),
                        borderRadius: radius(14),
                      ),
                      child: Row(
                        children: [
                          Text(language.totalAmount,
                                  style: boldTextStyle(size: 14))
                              .expand(),
                          PriceWidget(
                            price: bookingAmountModel.finalGrandTotalAmount,
                            color: primaryColor,
                            size: 18,
                          )
                        ],
                      ),
                    ),
                  ],
                ),

                /// Advance Payable Amount if it is required by Service Provider
                if (widget.data.serviceDetail!.isAdvancePayment &&
                    widget.data.serviceDetail!.isFixedService &&
                    !widget.data.serviceDetail!.isFreeService)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(height: 26, color: context.dividerColor),
                      Row(
                        children: [
                          Row(
                            children: [
                              Text(language.advancePayAmount,
                                  style: secondaryTextStyle(size: 14)),
                              Text(
                                  " (${widget.data.serviceDetail!.advancePaymentPercentage.validate().toString()}%)  ",
                                  style: boldTextStyle(color: Colors.green)),
                            ],
                          ).expand(),
                          PriceWidget(
                              price: advancePaymentAmount, color: primaryColor),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          )
        ],
      );

    return Offstage();
  }

  Widget buildDateWidget() {
    if (widget.data.serviceDetail!.isSlotAvailable) {
      return Text(widget.data.serviceDetail!.dateTimeVal.validate(),
          style: boldTextStyle(size: 12));
    }
    return Text(
        formatBookingDate(widget.data.serviceDetail!.dateTimeVal.validate(),
            format: DATE_FORMAT_3),
        style: boldTextStyle(size: 12));
  }

  Widget buildTimeWidget() {
    if (widget.data.serviceDetail!.bookingSlot == null) {
      return Text(
          formatBookingDate(widget.data.serviceDetail!.dateTimeVal.validate(),
              format: HOUR_12_FORMAT),
          style: boldTextStyle(size: 12));
    }
    return Text(
        TimeOfDay(
          hour: widget.data.serviceDetail!.bookingSlot
              .validate()
              .splitBefore(':')
              .split(":")
              .first
              .toInt(),
          minute: widget.data.serviceDetail!.bookingSlot
              .validate()
              .splitBefore(':')
              .split(":")
              .last
              .toInt(),
        ).format(context),
        style: boldTextStyle(size: 12));
  }

  Widget buildBookingSummaryWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        16.height,
        _sectionHeader(
            Icons.event_available_outlined, language.bookingDateAndSlot),
        16.height,
        widget.data.serviceDetail!.dateTimeVal == null
            ? GestureDetector(
                onTap: () async {
                  handleDateTimePick();
                },
                child: DottedBorderWidget(
                  color: context.primaryColor,
                  radius: 16,
                  child: Container(
                    width: context.width(),
                    padding: EdgeInsets.symmetric(vertical: 18),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.05),
                      borderRadius: radius(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: context.primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: ic_calendar.iconImage(
                              size: 22, color: context.primaryColor),
                        ),
                        8.height,
                        Text(language.chooseDateTime,
                            style: boldTextStyle(
                                size: 13, color: context.primaryColor)),
                      ],
                    ),
                  ),
                ),
              )
            : Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: radius(18),
                  border: appStore.isDarkMode
                      ? Border.all(color: context.dividerColor)
                      : null,
                  boxShadow: appStore.isDarkMode
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                ),
                width: context.width(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withValues(alpha: 0.1),
                        borderRadius: radius(12),
                      ),
                      child: Icon(Icons.event_available_rounded,
                          color: context.primaryColor, size: 22),
                    ),
                    14.width,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text("${language.lblDate}: ",
                                style: secondaryTextStyle()),
                            buildDateWidget(),
                          ],
                        ),
                        8.height,
                        Row(
                          children: [
                            Text("${language.lblTime}: ",
                                style: secondaryTextStyle()),
                            buildTimeWidget(),
                          ],
                        ),
                      ],
                    ).expand(),
                    IconButton(
                      icon: ic_edit_square.iconImage(size: 18),
                      visualDensity: VisualDensity.compact,
                      onPressed: () async {
                        handleDateTimePick();
                      },
                    )
                  ],
                ),
              ),
      ],
    );
  }

  Widget packageWidget() {
    if (widget.selectedPackage != null)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.card_giftcard_outlined, language.package),
          16.height,
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: radius(18),
              border: appStore.isDarkMode
                  ? Border.all(color: context.dividerColor)
                  : null,
              boxShadow: appStore.isDarkMode
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
            ),
            width: context.width(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CachedImageWidget(
                      url: widget.selectedPackage!.imageAttachments
                              .validate()
                              .isNotEmpty
                          ? widget.selectedPackage!.imageAttachments!.first
                              .validate()
                          : '',
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                      radius: 14,
                    ),
                    14.width,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Marquee(
                            child: Text(widget.selectedPackage!.name.validate(),
                                style: boldTextStyle())),
                        4.height,
                        Text(
                            "${language.services}: ${widget.selectedPackage!.serviceList.validate().map((e) => e.name).join(", ")}",
                            style: secondaryTextStyle()),
                      ],
                    ).expand(),
                  ],
                ),
              ],
            ),
          ),
        ],
      );

    return Offstage();
  }
}
