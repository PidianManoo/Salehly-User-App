import 'package:booking_system_flutter/component/app_common_dialog.dart';
import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/image_border_component.dart';
import 'package:booking_system_flutter/component/price_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/booking_data_model.dart';
import 'package:booking_system_flutter/screens/booking/component/edit_booking_service_dialog.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/model_keys.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../model/service_detail_response.dart';
import '../../../network/rest_apis.dart';
import 'booking_slots.dart';

class BookingItemComponent extends StatefulWidget {
  final BookingData bookingData;

  BookingItemComponent({required this.bookingData});

  @override
  State<BookingItemComponent> createState() => _BookingItemComponentState();
}

class _BookingItemComponentState extends State<BookingItemComponent> {
  Widget _buildEditBookingWidget() {
    if (widget.bookingData.status == BookingStatusKeys.pending &&
        isDateTimeAfterNow) {
      return Container(
        decoration: BoxDecoration(
          color: context.primaryColor.withValues(alpha: 0.1),
          borderRadius: radius(8),
        ),
        child: IconButton(
          padding: EdgeInsets.all(6),
          constraints: const BoxConstraints(),
          style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          icon: ic_edit_square.iconImage(size: 16),
          visualDensity: VisualDensity.compact,
          onPressed: () async {
            ServiceDetailResponse res = await getServiceDetails(
              serviceId: widget.bookingData.serviceId.validate(),
              customerId: appStore.userId,
              fromBooking: true,
            );

            if (widget.bookingData.isSlotBooking) {
              showModalBottomSheet(
                backgroundColor: Colors.transparent,
                context: context,
                isScrollControlled: true,
                isDismissible: true,
                shape: RoundedRectangleBorder(
                    borderRadius: radiusOnly(
                        topLeft: defaultRadius, topRight: defaultRadius)),
                builder: (_) {
                  return DraggableScrollableSheet(
                    initialChildSize: 0.65,
                    minChildSize: 0.65,
                    maxChildSize: 1,
                    builder: (context, scrollController) =>
                        BookingSlotsComponent(
                      data: res,
                      bookingData: widget.bookingData,
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
              showInDialog(
                context,
                contentPadding: EdgeInsets.zero,
                hideSoftKeyboard: true,
                backgroundColor: context.cardColor,
                builder: (p0) {
                  return AppCommonDialog(
                    title: language.lblUpdateDateAndTime,
                    child: EditBookingServiceDialog(data: widget.bookingData),
                  );
                },
              );
            }
          },
        ),
      );
    }
    return Offstage();
  }

  String buildTimeWidget({required BookingData bookingDetail}) {
    if (bookingDetail.bookingSlot == null) {
      return formatDate(bookingDetail.date.validate(), isTime: true);
    }
    return formatDate(
      getSlotWithDate(
          date: bookingDetail.date.validate(),
          slotTime: bookingDetail.bookingSlot.validate()),
      isTime: true,
    );
  }

  Widget _buildUrgentBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            urgentColor.withValues(alpha: 0.18),
            urgentColor.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: radius(20),
        border: Border.all(color: urgentColor.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 10, color: urgentColor),
          3.width,
          Text(language.urgentBooking,
              style: boldTextStyle(color: urgentColor, size: 10)),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: radius(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(text, style: boldTextStyle(color: color, size: 10)),
    );
  }

  Widget _buildInfoRow(
      {required IconData icon, required String label, required Widget value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.08),
              borderRadius: radius(8),
            ),
            child: Icon(icon, size: 13, color: context.primaryColor),
          ),
          10.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: secondaryTextStyle(size: 11)),
                3.height,
                value,
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor =
        widget.bookingData.status.validate().getPaymentStatusBackgroundColor;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: appStore.isDarkMode ? context.cardColor : Colors.white,
        borderRadius: radius(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: appStore.isDarkMode ? 0.18 : 0.07),
            blurRadius: 14,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service image with status dot
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: radius(12),
                      child: widget.bookingData.isPackageBooking
                          ? CachedImageWidget(
                              url: widget.bookingData.bookingPackage!
                                      .imageAttachments
                                      .validate()
                                      .isNotEmpty
                                  ? widget.bookingData.bookingPackage!
                                      .imageAttachments
                                      .validate()
                                      .first
                                      .validate()
                                  : "",
                              height: 92,
                              width: 92,
                              fit: BoxFit.cover,
                            )
                          : CachedImageWidget(
                              url: widget.bookingData.serviceAttachments
                                      .validate()
                                      .isNotEmpty
                                  ? widget.bookingData.serviceAttachments!.first
                                      .validate()
                                  : '',
                              fit: BoxFit.cover,
                              width: 92,
                              height: 92,
                            ),
                    ),
                    Positioned(
                      top: 7,
                      right: 7,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: statusColor.withValues(alpha: 0.4),
                                blurRadius: 4)
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                12.width,
                // Right info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          _buildBadge('#${widget.bookingData.id.validate()}',
                              context.primaryColor),
                          _buildBadge(
                              widget.bookingData.status
                                  .validate()
                                  .toBookingStatus(),
                              statusColor),
                          if (widget.bookingData.isPostJob)
                            _buildBadge(language.postJob, context.primaryColor),
                          if (widget.bookingData.isPackageBooking)
                            _buildBadge(language.package, Colors.orange),
                          if (widget.bookingData.isUrgentBooking == true)
                            _buildUrgentBadge(),
                        ],
                      ),
                      10.height,
                      // Service name
                      Text(
                        widget.bookingData.isPackageBooking
                            ? widget.bookingData.bookingPackage!.name.validate()
                            : widget.bookingData.serviceName.validate(),
                        style: boldTextStyle(size: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      8.height,
                      // Price
                      if (widget.bookingData.bookingPackage != null)
                        PriceWidget(
                          price: widget.bookingData.totalAmount.validate(),
                          color: primaryColor,
                        )
                      else
                        Row(
                          children: [
                            Flexible(
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 4,
                                children: [
                                  PriceWidget(
                                    isFreeService: widget.bookingData.type ==
                                        SERVICE_TYPE_FREE,
                                    price: widget.bookingData.totalAmount
                                        .validate(),
                                    color: primaryColor,
                                  ),
                                  if (widget.bookingData.isHourlyService)
                                    PriceWidget(
                                      price:
                                          widget.bookingData.amount.validate(),
                                      color: textSecondaryColorGlobal,
                                      isHourlyService: true,
                                      size: 12,
                                      isBoldText: false,
                                    ),
                                  if (widget.bookingData.discount.validate() !=
                                      0)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green
                                            .withValues(alpha: 0.12),
                                        borderRadius: radius(6),
                                      ),
                                      child: Text(
                                        '${widget.bookingData.discount!}% ${language.lblOff}',
                                        style: boldTextStyle(
                                            size: 10, color: Colors.green),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            4.width,
                            _buildEditBookingWidget(),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Details ─────────────────────────────────────────────────────────
          Container(
            margin: EdgeInsets.symmetric(horizontal: 12),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: appStore.isDarkMode
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.grey.shade50,
              borderRadius: radius(12),
              border: Border.all(
                  color: context.dividerColor.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.bookingData.address.validate().isNotEmpty) ...[
                  _buildInfoRow(
                    icon: Icons.location_on_outlined,
                    label: language.hintAddress,
                    value: Text(
                      widget.bookingData.address.validate(),
                      style: boldTextStyle(size: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Divider(
                      height: 12,
                      color: context.dividerColor.withValues(alpha: 0.5)),
                ],
                _buildInfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: '${language.lblDate} & ${language.lblTime}',
                  value: Text(
                    "${formatDate(widget.bookingData.date.validate())} ${language.at} ${buildTimeWidget(bookingDetail: widget.bookingData)}",
                    style: boldTextStyle(size: 12),
                  ),
                ),
                if (widget.bookingData.paymentStatus != null &&
                    (widget.bookingData.status == BookingStatusKeys.complete ||
                        widget.bookingData.status ==
                            BookingStatusKeys.cancelled ||
                        widget.bookingData.status ==
                            BookingStatusKeys.pending ||
                        widget.bookingData.paymentStatus ==
                            SERVICE_PAYMENT_STATUS_ADVANCE_PAID ||
                        widget.bookingData.paymentStatus ==
                            SERVICE_PAYMENT_STATUS_PAID ||
                        widget.bookingData.paymentStatus ==
                            PENDING_BY_ADMIN)) ...[
                  if ((widget.bookingData.paymentStatus ==
                              SERVICE_PAYMENT_STATUS_PAID ||
                          widget.bookingData.paymentStatus ==
                              PENDING_BY_ADMIN) ||
                      getPaymentStatusText(widget.bookingData.paymentStatus,
                              widget.bookingData.paymentMethod)
                          .isNotEmpty) ...[
                    Divider(
                        height: 12,
                        color: context.dividerColor.withValues(alpha: 0.5)),
                    _buildInfoRow(
                      icon: Icons.payment_outlined,
                      label: language.paymentStatus,
                      value: Text(
                        buildPaymentStatusWithMethod(
                          widget.bookingData.paymentStatus.validate(),
                          widget.bookingData.paymentMethod.validate(),
                        ),
                        style: boldTextStyle(size: 12, color: statusColor),
                      ),
                    ),
                  ] else if (widget.bookingData.paymentStatus == null &&
                      (widget.bookingData.status == BookingStatusKeys.pending ||
                          widget.bookingData.status ==
                              BookingStatusKeys.cancelled ||
                          widget.bookingData.status ==
                              BookingStatusKeys.complete)) ...[
                    Divider(
                        height: 12,
                        color: context.dividerColor.withValues(alpha: 0.5)),
                    _buildInfoRow(
                      icon: Icons.payment_outlined,
                      label: language.paymentStatus,
                      value: Text(
                        widget.bookingData.status.validate().toBookingStatus(),
                        style: boldTextStyle(size: 12, color: statusColor),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),

          // ── Provider / Handyman ──────────────────────────────────────────────
          Container(
            margin: EdgeInsets.all(12),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.primaryColor.withValues(alpha: 0.06),
                  context.primaryColor.withValues(alpha: 0.02),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: radius(12),
              border: Border.all(
                  color: context.primaryColor.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                ImageBorder(
                  src: widget.bookingData.handyman!.isEmpty
                      ? widget.bookingData.providerImage.validate()
                      : widget.bookingData.isProviderAndHandymanSame
                          ? widget.bookingData.providerImage.validate()
                          : widget.bookingData.handyman!.first.handyman!
                              .handymanImage
                              .validate(),
                  height: 44,
                ),
                12.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.bookingData.handyman!.isEmpty
                                  ? widget.bookingData.providerName.validate()
                                  : widget.bookingData.isProviderAndHandymanSame
                                      ? widget.bookingData.providerName
                                          .validate()
                                      : widget.bookingData.handyman!.first
                                          .handyman!.displayName
                                          .validate(),
                              style: boldTextStyle(size: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          4.width,
                          ImageIcon(AssetImage(ic_verified),
                                  size: 14, color: Colors.green)
                              .visible(
                            widget.bookingData.handyman!.isEmpty
                                ? widget.bookingData.providerIsVerified
                                        .validate() ==
                                    1
                                : widget.bookingData.isProviderAndHandymanSame
                                    ? widget.bookingData.providerIsVerified
                                            .validate() ==
                                        1
                                    : widget.bookingData.handyman!.first
                                            .handyman!.isVerifyHandyman
                                            .validate() ==
                                        1,
                          ),
                        ],
                      ),
                      4.height,
                      Text(
                        widget.bookingData.handyman!.isEmpty
                            ? language.textProvider
                            : language.textHandyman,
                        style: secondaryTextStyle(size: 11),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: context.primaryColor.withValues(alpha: 0.4),
                    size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get isDateTimeAfterNow {
    try {
      if (widget.bookingData.bookingSlot != null) {
        final bookingDateTimeForTimeSlots =
            widget.bookingData.date.validate().split(" ").isNotEmpty
                ? widget.bookingData.date.validate().split(" ").first
                : "";
        final bookingTimeForTimeSlots =
            widget.bookingData.bookingSlot.validate();
        return DateTime.parse(
                bookingDateTimeForTimeSlots + " " + bookingTimeForTimeSlots)
            .isAfter(DateTime.now());
      } else {
        return DateTime.parse(widget.bookingData.date.validate())
            .isAfter(DateTime.now());
      }
    } catch (e) {
      log('E: $e');
    }
    return false;
  }
}
