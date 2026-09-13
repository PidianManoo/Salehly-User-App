import 'dart:async';

import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/disabled_rating_bar_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/component/price_widget.dart';
import 'package:booking_system_flutter/component/view_all_label_component.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/get_my_post_job_list_response.dart';
import 'package:booking_system_flutter/model/post_job_detail_response.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/booking/provider_info_screen.dart';
import 'package:booking_system_flutter/screens/jobRequest/components/bidder_item_component.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/model_keys.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../component/empty_error_state_widget.dart';
import '../booking/booking_detail_screen.dart';

class MyPostDetailScreen extends StatefulWidget {
  final int postRequestId;
  final PostJobData? postJobData;
  final VoidCallback callback;
  final bool disableCounterOffer;

  MyPostDetailScreen(
      {required this.postRequestId,
      this.postJobData,
      required this.callback,
      this.disableCounterOffer = false});

  @override
  _MyPostDetailScreenState createState() => _MyPostDetailScreenState();
}

class _MyPostDetailScreenState extends State<MyPostDetailScreen> {
  Future<PostJobDetailResponse>? future;
  PostJobDetailResponse? latestData;
  Timer? _autoRefreshTimer;

  int page = 1;
  bool isLastPage = false;

  @override
  void initState() {
    super.initState();

    print("postData${widget.postJobData?.bookingId}");

    LiveStream().on(LIVESTREAM_UPDATE_BIDER, (p0) {
      _silentRefresh();
    });

    init();
    _startAutoRefresh();
  }

  void init() async {
    future = getPostJobDetail(
        {PostJob.postRequestId: widget.postRequestId.validate()});
  }

  // Quietly re-fetches the job detail in the background (no loader flash)
  // so newly placed bids show up in real time.
  Future<void> _silentRefresh() async {
    try {
      final result = await getPostJobDetail(
          {PostJob.postRequestId: widget.postRequestId.validate()});
      if (!mounted) return;
      latestData = result;
      setState(() {});
    } catch (e) {
      log(e);
    }
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      final bookingId = latestData?.postRequestDetail?.bookingId;
      if (bookingId != null && bookingId != 0) {
        timer.cancel();
        return;
      }
      _silentRefresh();
    });
  }

  Widget _infoRow(
      {required IconData icon,
      required String label,
      required Widget value,
      required Color color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
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
    );
  }

  Widget postJobDetailWidget({required PostJobData data}) {
    final bool isUrgent = data.isUrgentBooking == true;
    final Color statusColor = data.status.validate().getJobStatusColor;
    final String statusLabel = data.status.validate().toPostJobStatus();
    final num price = data.status.validate() == JOB_REQUEST_STATUS_ASSIGNED
        ? data.jobPrice.validate()
        : data.price.validate();
    return Container(
      width: context.width(),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status + urgent badges ────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.40)),
                  ),
                  child: Text(statusLabel,
                      style: boldTextStyle(color: statusColor, size: 11)),
                ),
                Spacer(),
                if (isUrgent)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        urgentColor.withValues(alpha: 0.18),
                        urgentColor.withValues(alpha: 0.08),
                      ]),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: urgentColor.withValues(alpha: 0.45)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, size: 13, color: urgentColor),
                        4.width,
                        Text(language.urgentBooking,
                            style: boldTextStyle(color: urgentColor, size: 11)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          14.height,

          // ── Title + description ─────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.title.validate().isNotEmpty)
                  Text(data.title.validate(), style: boldTextStyle(size: 17)),
                if (data.description.validate().isNotEmpty) ...[
                  10.height,
                  Text(language.postJobDescription,
                      style: secondaryTextStyle(size: 11)),
                  4.height,
                  ReadMoreText(
                    data.description.validate(),
                    style: primaryTextStyle(size: 13),
                    colorClickableText: context.primaryColor,
                  ),
                ],
              ],
            ),
          ),
          16.height,
          Divider(
              height: 1, color: context.dividerColor.withValues(alpha: 0.5)),
          16.height,

          // ── Price highlight ──────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withValues(alpha: 0.08),
                    primaryColor.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primaryColor.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.payments_rounded,
                        color: primaryColor, size: 20),
                  ),
                  12.width,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.status.validate() == JOB_REQUEST_STATUS_ASSIGNED
                            ? language.jobPrice
                            : language.estimatedPrice,
                        style: secondaryTextStyle(size: 12),
                      ),
                      4.height,
                      PriceWidget(
                        price: price,
                        isHourlyService: false,
                        color: textPrimaryColorGlobal,
                        isFreeService: false,
                        size: 18,
                        isBoldText: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Booking date ─────────────────────────────────────────────
          if (data.urgentBookingTime.validate().isNotEmpty) ...[
            16.height,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _infoRow(
                icon: Icons.access_time_rounded,
                label: language.bookingDate,
                color: urgentColor,
                value: Text(
                  formatDate(data.urgentBookingTime.validate(),
                      showDateWithTime: true),
                  style: boldTextStyle(size: 13),
                ),
              ),
            ),
          ],

          // ── Extra charges (legacy bookings) ──────────────────────────
          if (isUrgent && data.extraCharges.validate().isNotEmpty) ...[
            14.height,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _infoRow(
                icon: Icons.add_circle_outline_rounded,
                label: language.extraCharges,
                color: urgentColor,
                value: PriceWidget(
                  price: double.tryParse(data.extraCharges.validate()) ?? 0,
                  isHourlyService: false,
                  color: urgentColor,
                  isFreeService: false,
                  size: 14,
                  isBoldText: true,
                ),
              ),
            ),
          ],

          // ── Urgent note banner ────────────────────────────────────────
          if (isUrgent) ...[
            16.height,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: urgentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: urgentColor.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16, color: urgentColor),
                    8.width,
                    Expanded(
                      child: Text(
                        language.urgentExtraChargeNote,
                        style: secondaryTextStyle(size: 12, color: urgentColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          16.height,
        ],
      ),
    );
  }

  Widget postJobServiceWidget({required List<ServiceData> serviceList}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.home_repair_service_rounded,
                size: 16, color: primaryColor),
            6.width,
            Text(language.services,
                style: boldTextStyle(size: LABEL_TEXT_SIZE)),
            8.width,
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${serviceList.length}',
                  style: boldTextStyle(size: 11, color: primaryColor)),
            ),
          ],
        ).paddingOnly(left: 16, right: 16),
        10.height,
        AnimatedListView(
          itemCount: serviceList.length,
          padding: EdgeInsets.symmetric(horizontal: 16),
          shrinkWrap: true,
          listAnimationType: ListAnimationType.FadeIn,
          fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
          itemBuilder: (_, i) {
            ServiceData data = serviceList[i];

            return Container(
              width: context.width(),
              margin: EdgeInsets.only(bottom: 10),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedImageWidget(
                      url: data.attachments.validate().isNotEmpty
                          ? data.attachments!.first.validate()
                          : "",
                      fit: BoxFit.cover,
                      height: 52,
                      width: 52,
                    ),
                  ),
                  12.width,
                  Text(data.categoryName.validate(),
                          style: primaryTextStyle(size: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis)
                      .expand(),
                  8.width,
                  Icon(Icons.chevron_right_rounded,
                      color: textSecondaryColorGlobal, size: 20),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget bidderWidget(List<BidderData> bidderList,
      {required PostJobDetailResponse postJobDetailResponse}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(language.bidder,
                  style: boldTextStyle(size: LABEL_TEXT_SIZE)),
              8.width,
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${bidderList.length}',
                    style: boldTextStyle(size: 11, color: primaryColor)),
              ),
              10.width,
              _LiveBadge(),
              Spacer(),
              if (isViewAllVisible(bidderList))
                GestureDetector(
                  onTap: () {
                    //
                  },
                  child: Text(language.lblViewAll, style: secondaryTextStyle()),
                ),
            ],
          ),
        ),
        10.height,
        AnimatedListView(
          itemCount: bidderList.length,
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          listAnimationType: ListAnimationType.FadeIn,
          fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
          itemBuilder: (_, i) {
            return BidderItemComponent(
              data: bidderList[i],
              postRequestId: widget.postRequestId.validate(),
              postJobData: postJobDetailResponse.postRequestDetail!,
              postJobDetailResponse: postJobDetailResponse,
              disableCounterOffer: widget.disableCounterOffer,
            );
          },
        ),
      ],
    );
  }

  Widget providerWidget(
      List<BidderData> bidderList, PostJobData? postJob, num? providerId) {
    try {
      BidderData? bidderData =
          bidderList.firstWhere((element) => element.providerId == providerId);
      UserData? user = bidderData.provider;

      final bool isRejected =
          postJob?.bidStatus.validate() == JOB_REQUEST_REJECTED_BY_CUSTOMER ||
              postJob?.bidStatus.validate() == JOB_REQUEST_REJECTED_BY_PROVIDER;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          16.height,
          Row(
            children: [
              Icon(Icons.verified_user_rounded, size: 16, color: primaryColor),
              6.width,
              Text(language.assignedProvider,
                  style: boldTextStyle(size: LABEL_TEXT_SIZE)),
            ],
          ),
          12.height,
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              ProviderInfoScreen(providerId: user.id.validate())
                  .launch(context);
            },
            child: Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          primaryColor,
                          primaryColor.withValues(alpha: 0.35),
                        ],
                      ),
                    ),
                    child: CachedImageWidget(
                      url: user!.profileImage.validate(),
                      fit: BoxFit.cover,
                      height: 56,
                      width: 56,
                      circle: true,
                    ),
                  ),
                  12.width,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Marquee(
                        directionMarguee: DirectionMarguee.oneDirection,
                        child: Text(
                          user.displayName.validate(),
                          style: boldTextStyle(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      4.height,
                      if (user.email.validate().isNotEmpty)
                        Marquee(
                          directionMarguee: DirectionMarguee.oneDirection,
                          child: Text(
                            user.email.validate(),
                            style: secondaryTextStyle(size: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (user.providersServiceRating != null) ...[
                        6.height,
                        DisabledRatingBarWidget(
                            rating: user.providersServiceRating.validate(),
                            size: 14),
                      ],
                      if (user.totalCompletedJobs != null ||
                          user.createdAt.validate().isNotEmpty) ...[
                        6.height,
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (user.totalCompletedJobs != null)
                              _metaInfoChip(
                                Icons.task_alt_rounded,
                                '${user.totalCompletedJobs} ${language.completedJobsLabel}',
                              ),
                            if (user.createdAt.validate().isNotEmpty)
                              _metaInfoChip(
                                Icons.calendar_month_rounded,
                                '${language.joinedOnLabel} ${formatBookingDate(user.createdAt, format: 'MMM yyyy')}',
                              ),
                          ],
                        ),
                      ],
                    ],
                  ).expand(),
                  10.width,
                  if (isRejected)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: rejected.withValues(alpha: 0.1),
                        borderRadius: radius(8),
                      ),
                      child: Text(
                        language.rejected,
                        style: boldTextStyle(color: rejected, size: 12),
                      ),
                    )
                  else
                    Icon(Icons.chevron_right_rounded,
                        color: textSecondaryColorGlobal, size: 22),
                ],
              ),
            ),
          ),
        ],
      ).paddingOnly(left: 16, right: 16);
    } catch (e) {
      log(e);
      return Offstage();
    }
  }

  Widget _metaInfoChip(IconData icon, String title) {
    return Row(children: [
      Icon(
        icon,
        size: 15,
      ),
      SizedBox(width: 8),
      Text(
        title,
        style: TextStyle(fontSize: 12),
      )
    ]);
  }

  Widget _bookedBottomPanel({required int bookingId}) {
    return Container(
      width: context.width(),
      padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: context.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded,
                    color: Colors.green, size: 24),
              ),
              12.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(language.jobBookedTitle,
                        style: boldTextStyle(size: 15)),
                    6.height,
                    Text(
                      language.bookingConfirmedMsg,
                      style: secondaryTextStyle(size: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          16.height,
          GestureDetector(
            onTap: () =>
                BookingDetailScreen(bookingId: bookingId).launch(context),
            child: Container(
              height: 52,
              width: context.width(),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.primaryColor,
                    context.primaryColor.withValues(alpha: 0.80),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: context.primaryColor.withValues(alpha: 0.30),
                    blurRadius: 14,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(language.viewBookingDetails,
                      style: boldTextStyle(color: white, size: 15)),
                  8.width,
                  Icon(Icons.arrow_forward_rounded, color: white, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    LiveStream().dispose(LIVESTREAM_UPDATE_BIDER);
    super.dispose();
  }

  Widget _buildContent(PostJobDetailResponse data) {
    return Stack(
      children: [
        AnimatedScrollView(
          padding: EdgeInsets.only(bottom: 180),
          physics: AlwaysScrollableScrollPhysics(),
          listAnimationType: ListAnimationType.FadeIn,
          fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            postJobDetailWidget(data: data.postRequestDetail!).paddingAll(16),
            if (data.postRequestDetail!.service.validate().isNotEmpty) ...[
              postJobServiceWidget(
                  serviceList: data.postRequestDetail!.service.validate()),
              8.height,
            ],
            if (data.postRequestDetail!.providerId != null) ...[
              providerWidget(
                data.biderData.validate(),
                data.postRequestDetail!,
                data.postRequestDetail!.providerId.validate(),
              ),
              8.height,
            ],
            if (data.biderData.validate().isNotEmpty &&
                (data.postRequestDetail!.bookingId == null ||
                    data.postRequestDetail!.bookingId == 0))
              bidderWidget(data.biderData.validate(),
                  postJobDetailResponse: data),
          ],
          onSwipeRefresh: () async {
            page = 1;
            await _silentRefresh();
          },
        ),
        if (data.postRequestDetail!.bookingId != null &&
            data.postRequestDetail!.bookingId != 0)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _bookedBottomPanel(
                bookingId: data.postRequestDetail!.bookingId!.toInt()),
          )
        else if (data.postRequestDetail!.status.validate() ==
                    JOB_REQUEST_STATUS_REQUESTED &&
                data.biderData!.isEmpty ||
            data.postRequestDetail!.status.validate() == counterOfferByCustomer)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              width: context.width(),
              padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
              decoration: BoxDecoration(
                color: context.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.2, color: primaryColor),
                  ),
                  10.width,
                  Text(language.lblWaitingForResponse,
                      style: boldTextStyle(size: 14)),
                ],
              ),
            ),
          )
        else
          SizedBox.shrink(),
        Observer(
            builder: (context) => LoaderWidget().visible(appStore.isLoading))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: language.myPostDetail,
      // Once the first load resolves we render straight from `latestData` so
      // periodic/live-bid refreshes update the UI without flashing the loader.
      child: latestData != null
          ? _buildContent(latestData!)
          : SnapHelperWidget<PostJobDetailResponse>(
              future: future,
              onSuccess: (data) {
                latestData = data;
                return _buildContent(data);
              },
              errorBuilder: (error) {
                return NoDataWidget(
                  title: error,
                  imageWidget: ErrorStateWidget(),
                  retryText: language.reload,
                  onRetry: () {
                    page = 1;
                    appStore.setLoading(true);

                    init();
                    setState(() {});
                  },
                );
              },
              loadingWidget: LoaderWidget(),
            ),
    );
  }
}

// Small pulsing "LIVE" badge used to signal the bidder list auto-refreshes.
class _LiveBadge extends StatefulWidget {
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _controller,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          ),
          4.width,
          Text(language.liveLabel,
              style: boldTextStyle(size: 9, color: Colors.green)),
        ],
      ),
    );
  }
}
