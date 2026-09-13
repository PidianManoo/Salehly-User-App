import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/screens/booking/booking_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../model/booking_data_model.dart';
import '../../../utils/colors.dart';
import '../../../utils/common.dart';
import '../../../utils/constant.dart';

class PendingBookingComponent extends StatefulWidget {
  final BookingData? upcomingConfirmedBooking;

  PendingBookingComponent({this.upcomingConfirmedBooking});

  @override
  State<PendingBookingComponent> createState() => _PendingBookingComponentState();
}

class _PendingBookingComponentState extends State<PendingBookingComponent> {
  @override
  Widget build(BuildContext context) {
    if (widget.upcomingConfirmedBooking == null) return Offstage();
    if (getBoolAsync('$BOOKING_ID_CLOSED_${widget.upcomingConfirmedBooking!.id}')) return Offstage();
    if (widget.upcomingConfirmedBooking!.status != BOOKING_STATUS_PENDING &&
        widget.upcomingConfirmedBooking!.status != BOOKING_STATUS_ACCEPT) return Offstage();

    final bool isAccepted = widget.upcomingConfirmedBooking!.status == BOOKING_STATUS_ACCEPT;

    return GestureDetector(
      onTap: () => BookingDetailScreen(bookingId: widget.upcomingConfirmedBooking!.id!).launch(context),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor,
              Color.lerp(primaryColor, Colors.indigo.shade900, 0.42)!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: radius(20),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.42),
              blurRadius: 18,
              spreadRadius: 0,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.antiAlias,
          children: [
            // ── Decorative circles ─────────────────────────────────────────
            Positioned(top: -30, right: -20, child: _circle(120, 0.09)),
            Positioned(bottom: -40, right: 40, child: _circle(100, 0.06)),
            Positioned(top: 20, right: 110, child: _circle(10, 0.20)),
            Positioned(bottom: 18, left: 30, child: _circle(7, 0.18)),

            // ── Content ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: status badge + close
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Status pill
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: radius(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: Colors.white.withValues(alpha: 0.6), blurRadius: 5),
                                ],
                              ),
                            ),
                            6.width,
                            Text(
                              isAccepted ? language.accepted : language.lblPending,
                              style: boldTextStyle(color: Colors.white, size: 11)
                                  .copyWith(letterSpacing: 0.4),
                            ),
                          ],
                        ),
                      ),

                      // Close button
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          await setValue('$BOOKING_ID_CLOSED_${widget.upcomingConfirmedBooking!.id}', true);
                          setState(() {});
                        },
                        child: Container(
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close_rounded, color: Colors.white, size: 15),
                        ),
                      ),
                    ],
                  ),

                  16.height,

                  // Service info row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon circle
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.28), width: 1.5),
                        ),
                        child: Icon(Icons.library_add_check_outlined, size: 22, color: Colors.white),
                      ),
                      14.width,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              language.bookingConfirmedMsg,
                              style: primaryTextStyle(
                                color: Colors.white.withValues(alpha: 0.78),
                                size: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            5.height,
                            Text(
                              widget.upcomingConfirmedBooking!.serviceName.validate(),
                              style: boldTextStyle(color: Colors.white, size: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  14.height,

                  // Thin separator
                  Container(height: 1, color: Colors.white.withValues(alpha: 0.20)),

                  12.height,

                  // Footer: date + view detail
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, color: Colors.white.withValues(alpha: 0.80), size: 13),
                      6.width,
                      Expanded(
                        child: Text(
                          formatDate(widget.upcomingConfirmedBooking!.date.validate(), showDateWithTime: true),
                          style: primaryTextStyle(color: Colors.white.withValues(alpha: 0.85), size: 12),
                        ),
                      ),
                      // View detail pill
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          borderRadius: radius(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(language.viewDetail, style: boldTextStyle(color: Colors.white, size: 11)),
                            4.width,
                            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circle(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      );
}
