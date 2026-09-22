import 'package:booking_system_flutter/component/price_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/refund_request_model.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class RefundRequestItemComponent extends StatelessWidget {
  final RefundRequestData data;

  RefundRequestItemComponent({required this.data});

  Color _statusColor() {
    switch (data.status.validate().toLowerCase()) {
      case 'approved':
      case 'accepted':
      case 'refunded':
      case 'completed':
        return accept;
      case 'rejected':
      case 'declined':
        return rejected;
      case 'pending':
      default:
        return hold;
    }
  }

  String _statusLabel() {
    final status = data.status.validate();
    return status.isEmpty ? language.lblPending : status.capitalizeFirstLetter();
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _statusColor();
    final bool isRejected = data.status.validate().toLowerCase() == 'rejected' || data.status.validate().toLowerCase() == 'declined';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: radius(16),
        border: appStore.isDarkMode ? Border.all(color: context.dividerColor) : null,
        boxShadow: appStore.isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.assignment_return_outlined, color: context.primaryColor, size: 20),
              ),
              12.width,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.serviceName.validate().isNotEmpty ? data.serviceName.validate() : language.refundForBooking,
                    style: boldTextStyle(size: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  3.height,
                  Text(
                    '${language.refundForBooking} #${data.bookingId.validate()}',
                    style: secondaryTextStyle(size: 11),
                  ),
                ],
              ).expand(),
              8.width,
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: radius(20),
                ),
                child: Text(_statusLabel(), style: boldTextStyle(size: 11, color: statusColor)),
              ),
            ],
          ),
          if (data.reason.validate().isNotEmpty) ...[
            10.height,
            Text(
              data.reason.validate(),
              style: secondaryTextStyle(size: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (isRejected && data.rejectReason.validate().isNotEmpty) ...[
            8.height,
            Container(
              width: context.width(),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: rejected.withValues(alpha: 0.08),
                borderRadius: radius(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: rejected),
                  6.width,
                  Text(
                    data.rejectReason.validate(),
                    style: secondaryTextStyle(size: 12, color: rejected),
                  ).expand(),
                ],
              ),
            ),
          ],
          10.height,
          Divider(height: 1, color: context.dividerColor),
          10.height,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (data.createdAt.validate().isNotEmpty)
                Text(formatDate(data.createdAt.validate()), style: secondaryTextStyle(size: 11)),
              if (data.refundAmount != null)
                PriceWidget(
                  price: data.refundAmount.validate(),
                  size: 14,
                  color: context.primaryColor,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
