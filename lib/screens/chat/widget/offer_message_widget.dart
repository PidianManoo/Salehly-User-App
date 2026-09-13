import 'package:booking_system_flutter/component/app_common_dialog.dart';
import 'package:booking_system_flutter/component/price_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/chat_message_model.dart';
import 'package:booking_system_flutter/model/get_my_post_job_list_response.dart';
import 'package:booking_system_flutter/model/post_job_detail_response.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/jobRequest/components/post_reason_dialog.dart';
import 'package:booking_system_flutter/screens/jobRequest/my_post_detail_screen.dart';
import 'package:booking_system_flutter/services/chat_services.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/model_keys.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';

enum _OfferStatus { pending, accepted, rejected }

class OfferMessageWidget extends StatefulWidget {
  final ChatMessageModel chatItemData;
  final String time;

  OfferMessageWidget({required this.chatItemData, required this.time});

  @override
  State<OfferMessageWidget> createState() => _OfferMessageWidgetState();
}

class _OfferMessageWidgetState extends State<OfferMessageWidget> {
  _OfferStatus _status = _OfferStatus.pending;
  bool _isProcessing = false;
  int? _completedJobs;
  String? _providerJoinedAt;

  @override
  void initState() {
    super.initState();
    print(
        "offerData---> postRequestId: ${widget.chatItemData.postRequestId}, senderId: ${widget.chatItemData.senderId}, offerPrice: ${widget.chatItemData.offerPrice}");

    switch (widget.chatItemData.offerStatus) {
      case 'accepted':
        _status = _OfferStatus.accepted;
        break;
      case 'rejected':
        _status = _OfferStatus.rejected;
        break;
    }

    _loadProviderStats();
  }

  // Silent, best-effort lookup of the offering provider's completed-jobs
  // count for display — failures are swallowed since this is decorative.
  Future<void> _loadProviderStats() async {
    try {
      final res =
          await getPostJobDetail({PostJob.postRequestId: _postRequestId});
      final List<BidderData> bidderList = res.biderData.validate();
      BidderData? bidder;
      for (final b in bidderList) {
        if (b.provider?.uid != null &&
            b.provider!.uid == widget.chatItemData.senderId) {
          bidder = b;
          break;
        }
      }
      if (bidder?.provider != null) {
        setState(() {
          _completedJobs = bidder!.provider!.totalCompletedJobs;
          _providerJoinedAt = bidder.provider!.createdAt;
        });
      }
    } catch (e) {
      log(e);
    }
  }

  Widget _metaInfoChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: textSecondaryColorGlobal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: textSecondaryColorGlobal),
          4.width,
          Text(label, style: secondaryTextStyle(size: 10)),
        ],
      ),
    );
  }

  bool get _isMe => widget.chatItemData.isMe.validate();

  num get _offerPriceNum =>
      num.tryParse(widget.chatItemData.offerPrice.validate()) ?? 0;

  int get _postRequestId =>
      int.tryParse(widget.chatItemData.postRequestId.validate()) ?? 0;

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  void _viewJobDetail() {
    MyPostDetailScreen(
      postRequestId: _postRequestId,
      callback: () {},
      disableCounterOffer: true,
    ).launch(context);
  }

  // Sender and receiver each keep their own copy of a message under
  // messages/{uid}/{otherUid}/{docId} with different doc ids, so the
  // provider's mirror has to be located by its shared createdAt rather than
  // updated directly via chatDocumentReference (which only points at our copy).
  Future<void> _updateOfferStatusInFirestore(String status) async {
    try {
      await widget.chatItemData.chatDocumentReference
          ?.update({'offerStatus': status});

      final senderId = widget.chatItemData.senderId;
      final receiverId = widget.chatItemData.receiverId;
      final createdAt = widget.chatItemData.createdAt;
      if (senderId == null || receiverId == null || createdAt == null) return;

      final query = await fireStore
          .collection(MESSAGES_COLLECTION)
          .doc(senderId)
          .collection(receiverId)
          .where('messageType', isEqualTo: MessageType.offer.name)
          .where('createdAt', isEqualTo: createdAt)
          .limit(1)
          .get();

      for (final doc in query.docs) {
        await doc.reference.update({'offerStatus': status});
      }
    } catch (e) {
      log(e);
    }
  }

  String get _statusLabel {
    switch (_status) {
      case _OfferStatus.accepted:
        return language.accept;
      case _OfferStatus.rejected:
        return language.rejected;
      case _OfferStatus.pending:
        return language.pendingLabel;
    }
  }

  Color get _statusColor {
    switch (_status) {
      case _OfferStatus.accepted:
        return Color(0xFF27AE60);
      case _OfferStatus.rejected:
        return Color(0xFFE74C3C);
      case _OfferStatus.pending:
        return Color(0xFFFFA726);
    }
  }

  IconData get _statusIcon {
    switch (_status) {
      case _OfferStatus.accepted:
        return Icons.check_circle_rounded;
      case _OfferStatus.rejected:
        return Icons.cancel_rounded;
      case _OfferStatus.pending:
        return Icons.schedule_rounded;
    }
  }

  Future<void> _loadBidAndAct({required bool isAccept}) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final num postRequestId =
          num.tryParse(widget.chatItemData.postRequestId.validate()) ?? 0;

      final res = await getPostJobDetail(
          {PostJob.postRequestId: postRequestId});

      if (res.postRequestDetail == null) {
        setState(() => _isProcessing = false);
        toast(language.somethingWentWrong);
        return;
      }

      // senderId on the chat message is the provider's Firebase UID, which
      // lives on BidderData.provider.uid — NOT the numeric BidderData.providerId.
      final List<BidderData> bidderList = res.biderData.validate();
      BidderData? bidder;
      for (final b in bidderList) {
        if (b.provider?.uid != null &&
            b.provider!.uid == widget.chatItemData.senderId) {
          bidder = b;
          break;
        }
      }

      setState(() => _isProcessing = false);

      if (bidder == null) {
        toast(language.somethingWentWrong);
        return;
      }

      if (isAccept) {
        _openAcceptDialog(bidder, res.postRequestDetail!);
      } else {
        _openRejectDialog(bidder, res.postRequestDetail!, res);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      toast(e.toString());
    }
  }

  void _openAcceptDialog(BidderData bidder, PostJobData postJobData) {
    DateTime bookingDate = DateTime.now();
    final rawTime = postJobData.urgentBookingTime.validate();
    if (rawTime.isNotEmpty) {
      try {
        bookingDate = DateTime.parse(rawTime);
      } catch (_) {}
    }

    // Skip the date/description picker (AcceptBidDialog) and go straight to
    // the Yes/No confirmation that _acceptOffer shows.
    _acceptOffer(bidder, postJobData, bookingDate, '');
  }

  Future<void> _acceptOffer(BidderData bidder, PostJobData postJobData,
      DateTime bookingDate, String description) async {
    final String providerName = bidder.provider?.displayName.validate() ?? '';
    final String confirmTitle = providerName.isNotEmpty
        ? '${language.doYouWantToAcceptThisBid} $providerName?'
        : '${language.doYouWantToAcceptThisBid}?';

    // Same second confirmation step used by BidderItemComponent's accept flow.
    showConfirmDialogCustom(
      context,
      negativeText: language.lblNo,
      dialogType: DialogType.CONFIRMATION,
      primaryColor: context.primaryColor,
      title: confirmTitle,
      positiveText: language.lblYes,
      onAccept: (c) async {
        appStore.setLoading(true);
        final num bidPrice = bidder.price.validate() != 0
            ? bidder.price.validate()
            : _offerPriceNum;

        Map request = {
          PostJob.postRequestId: bidder.postRequestId.validate(),
          PostJob.providerId: bidder.providerId.validate(),
          PostJob.bidStatus: JOB_REQUEST_ACCEPTED_BY_CUSTOMER,
          'is_booking': true,
          PostJob.serviceId: postJobData.service.validate().isNotEmpty
              ? postJobData.service!.first.id.validate()
              : 0,
          CommonKeys.date: DateFormat(BOOKING_SAVE_FORMAT).format(bookingDate),
          BookService.amount: bidPrice,
          BookService.totalAmount: bidPrice,
          BookService.quantity: 1,
          PostJob.description: description.trim().isNotEmpty
              ? description.trim()
              : language.counterOffer,
          CommonKeys.type: BOOKING_TYPE_USER_POST_JOB,
          BookService.totalPlatformCommissionAmount: 0,
        };

        await saveBid(request).then((value) {
          appStore.setLoading(false);
          toast(value.message.validate());
          LiveStream().emit(LIVESTREAM_UPDATE_BIDER);
          setState(() => _status = _OfferStatus.accepted);
          _updateOfferStatusInFirestore('accepted');
        }).catchError((e) {
          appStore.setLoading(false);
          toast(e.toString());
        });
      },
    );
  }

  void _openRejectDialog(
      BidderData bidder, PostJobData postJobData, PostJobDetailResponse res) {
    showInDialog(
      context,
      contentPadding: EdgeInsets.zero,
      backgroundColor: context.scaffoldBackgroundColor,
      builder: (context) => AppCommonDialog(
        title: language.holdOrAssignService,
        child: PostReasonDialog(
          data: bidder,
          postRequestId: bidder.postRequestId,
          postJobData: postJobData,
          postJobDetailResponse: res,
        ),
      ),
    ).then((value) {
      if (value != null) {
        setState(() => _status = _OfferStatus.rejected);
        _updateOfferStatusInFirestore('rejected');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMe = _isMe;

    return Container(
      width: 250,
      margin: EdgeInsets.only(
        top: 2,
        bottom: 2,
        left: isMe ? context.width() * 0.18 : 4,
        right: isMe ? 4 : context.width() * 0.18,
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header strip
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.primaryColor,
                  context.primaryColor.withValues(alpha: 0.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.local_offer_rounded, color: Colors.white, size: 15),
                6.width,
                Text(
                  isMe ? language.offerSent : language.offerReceived,
                  style: boldTextStyle(color: Colors.white, size: 13),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Job title
                Text(language.postJobTitle, style: secondaryTextStyle(size: 10)),
                3.height,
                Text(
                  widget.chatItemData.jobTitle.validate(),
                  style: boldTextStyle(size: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_completedJobs != null ||
                    _providerJoinedAt.validate().isNotEmpty) ...[
                  6.height,
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (_completedJobs != null)
                        _metaInfoChip(
                          Icons.task_alt_rounded,
                          '$_completedJobs ${language.completedJobsLabel}',
                        ),
                      if (_providerJoinedAt.validate().isNotEmpty)
                        _metaInfoChip(
                          Icons.calendar_month_rounded,
                          '${language.joinedOnLabel} ${formatBookingDate(_providerJoinedAt, format: 'MMM yyyy')}',
                        ),
                    ],
                  ),
                ],
                10.height,

                /// Offer price
                Text(language.offerPrice, style: secondaryTextStyle(size: 10)),
                3.height,
                PriceWidget(
                  price: _offerPriceNum,
                  color: context.primaryColor,
                  size: 16,
                  isHourlyService: false,
                  isFreeService: false,
                ),
                10.height,

                /// Status badge + time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: _statusColor.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon, size: 11, color: _statusColor),
                          4.width,
                          Text(_statusLabel,
                              style: boldTextStyle(color: _statusColor, size: 10)),
                        ],
                      ),
                    ),
                    Text(widget.time, style: secondaryTextStyle(size: 10)),
                  ],
                ),
                10.height,

                /// View job detail
                GestureDetector(
                  onTap: _viewJobDetail,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: context.primaryColor.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.work_outline_rounded,
                            size: 14, color: context.primaryColor),
                        6.width,
                        Text(
                          language.viewJobDetail,
                          style:
                              boldTextStyle(color: context.primaryColor, size: 12),
                        ),
                      ],
                    ),
                  ),
                ),

                /// Action buttons
                if (!isMe && _status == _OfferStatus.pending) ...[
                  12.height,
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _isProcessing
                              ? null
                              : () => _loadBidAndAct(isAccept: false),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Color(0xFFE74C3C).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Color(0xFFE74C3C).withValues(alpha: 0.3)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              language.reject,
                              style:
                                  boldTextStyle(color: Color(0xFFE74C3C), size: 12),
                            ),
                          ),
                        ),
                      ),
                      8.width,
                      Expanded(
                        child: GestureDetector(
                          onTap: _isProcessing
                              ? null
                              : () => _loadBidAndAct(isAccept: true),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: _isProcessing
                                ? SizedBox(
                                    height: 14,
                                    width: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    language.accept,
                                    style: boldTextStyle(
                                        color: Colors.white, size: 12),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
