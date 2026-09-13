import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/price_widget.dart';
import 'package:booking_system_flutter/model/get_my_post_job_list_response.dart';
import 'package:booking_system_flutter/screens/jobRequest/my_post_detail_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../main.dart';
import '../../../network/rest_apis.dart';

class MyPostRequestItemComponent extends StatefulWidget {
  final PostJobData data;
  final Function(bool) callback;
  final void Function(List<PostJobData>) apiUpdate;

  MyPostRequestItemComponent(
      {required this.data, required this.callback, required this.apiUpdate});

  @override
  _MyPostRequestItemComponentState createState() =>
      _MyPostRequestItemComponentState();
}

class _MyPostRequestItemComponentState
    extends State<MyPostRequestItemComponent> {
  Future<void> deletePost(num id) async {
    widget.callback.call(true);
    appStore.setLoading(true);

    await deletePostRequest(id: id.validate()).then((value) async {
      toast(value.message.validate());
      widget.callback.call(false);
      setState(() {});
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    });
  }

  void _confirmDelete() {
    showConfirmDialogCustom(
      context,
      dialogType: DialogType.DELETE,
      title: '${language.deleteMessage}?',
      positiveText: language.lblYes,
      negativeText: language.lblNo,
      onAccept: (p0) {
        ifNotTester(() async {
          await deletePost(widget.data.id.validate());
          widget.apiUpdate.call(postJobList);
        });
        setState(() {});
      },
    );
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor = widget.data.status.validate().getJobStatusColor;
    final String statusLabel = widget.data.status.validate().toPostJobStatus();
    final String imageUrl = (widget.data.service.validate().isNotEmpty &&
            widget.data.service.validate().first.attachments.validate().isNotEmpty)
        ? widget.data.service.validate().first.attachments.validate().first.validate()
        : '';
    final num price = widget.data.status.validate() == JOB_REQUEST_STATUS_ASSIGNED
        ? widget.data.jobPrice.validate()
        : widget.data.price.validate();
    final bool isUrgent = widget.data.isUrgentBooking == true;
    final bool isDark = appStore.isDarkMode;

    return Container(
      margin: EdgeInsets.only(top: 8, bottom: 4, left: 16, right: 16),
      decoration: BoxDecoration(
        color: isDark ? context.cardColor : Colors.white,
        borderRadius: radius(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.045),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.07),
            blurRadius: 22,
            spreadRadius: -6,
            offset: Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            MyPostDetailScreen(
              postJobData: widget.data,
              postRequestId: widget.data.id.validate().toInt(),
              callback: () => widget.callback.call(true),
            ).launch(context);
          },
          splashColor: primaryColor.withValues(alpha: 0.06),
          highlightColor: primaryColor.withValues(alpha: 0.03),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Main row ─────────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service image
                    ClipRRect(
                      borderRadius: radius(16),
                      child: CachedImageWidget(
                        url: imageUrl,
                        height: 76,
                        width: 76,
                        fit: BoxFit.cover,
                        radius: 16,
                      ),
                    ),
                    14.width,

                    // Info column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title + chevron affordance
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.data.title.validate(),
                                  style: boldTextStyle(size: 15, letterSpacing: -0.2),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              6.width,
                              Icon(
                                CupertinoIcons.chevron_forward,
                                size: 15,
                                color: textSecondaryColorGlobal.withValues(alpha: 0.45),
                              ),
                            ],
                          ),
                          8.height,

                          // Status + urgent chips
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _StatusChip(color: statusColor, label: statusLabel),
                              if (isUrgent) _UrgentChip(label: language.urgentBooking),
                            ],
                          ),
                          10.height,

                          // Price
                          PriceWidget(
                            price: price,
                            color: primaryColor,
                            size: 17,
                            isBoldText: true,
                            isHourlyService: false,
                            isFreeService: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                14.height,

                // ── Fading divider ──────────────────────────────────────────
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        context.dividerColor.withValues(alpha: 0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                12.height,

                // ── Booking time + extra charges (urgent) ─────────────────────
                if (widget.data.urgentBookingTime.validate().isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(CupertinoIcons.time, size: 14, color: urgentColor),
                      6.width,
                      Expanded(
                        child: Text(
                          formatDate(widget.data.urgentBookingTime.validate(), showDateWithTime: true),
                          style: secondaryTextStyle(size: 12),
                        ),
                      ),
                      if (isUrgent && widget.data.extraCharges.validate().isNotEmpty) ...[
                        8.width,
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: urgentColor.withValues(alpha: 0.08),
                            borderRadius: radius(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.add_circled, size: 12, color: urgentColor),
                              4.width,
                              PriceWidget(
                                price: double.tryParse(widget.data.extraCharges.validate()) ?? 0,
                                color: urgentColor,
                                size: 11,
                                isBoldText: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  10.height,
                ],

                // ── Footer: ID · created date  +  delete ───────────────────────
                Row(
                  children: [
                    Icon(CupertinoIcons.number, size: 13, color: textSecondaryColorGlobal),
                    3.width,
                    Text(
                      '${widget.data.id.validate()}',
                      style: secondaryTextStyle(size: 12),
                    ),
                    8.width,
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: textSecondaryColorGlobal.withValues(alpha: 0.5),
                      ),
                    ),
                    8.width,
                    Icon(CupertinoIcons.calendar, size: 13, color: textSecondaryColorGlobal),
                    6.width,
                    Expanded(
                      child: Text(
                        formatDate(widget.data.createdAt.validate()),
                        style: secondaryTextStyle(size: 12),
                      ),
                    ),

                    // Delete button
                    _DeleteButton(onTap: _confirmDelete),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Small reusable pieces ──────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final Color color;
  final String label;

  const _StatusChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: radius(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          6.width,
          Text(label, style: boldTextStyle(color: color, size: 10)),
        ],
      ),
    );
  }
}

class _UrgentChip extends StatelessWidget {
  final String label;

  const _UrgentChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [urgentColor, urgentColor.withValues(alpha: 0.75)],
        ),
        borderRadius: radius(20),
        boxShadow: [
          BoxShadow(
            color: urgentColor.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.bolt_fill, size: 11, color: white),
          4.width,
          Text(label, style: boldTextStyle(color: white, size: 10)),
        ],
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final VoidCallback onTap;

  const _DeleteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(CupertinoIcons.delete, size: 16, color: Colors.red),
        ),
      ),
    );
  }
}
