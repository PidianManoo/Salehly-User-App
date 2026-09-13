import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/get_my_post_job_list_response.dart';
import 'package:booking_system_flutter/model/post_job_detail_response.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/jobRequest/components/post_reason_dialog.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/custom_app_field.dart';
import 'package:booking_system_flutter/utils/model_keys.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/app_common_dialog.dart';
import '../../../component/disabled_rating_bar_widget.dart';
import '../../../component/price_widget.dart';
import '../../../utils/colors.dart';
import '../../../utils/common.dart';

class BidderItemComponent extends StatefulWidget {
  final BidderData data;
  final int? postRequestId;
  final PostJobData postJobData;
  final PostJobDetailResponse? postJobDetailResponse;
  final bool disableCounterOffer;

  BidderItemComponent({
    required this.data,
    required this.postRequestId,
    required this.postJobData,
    this.postJobDetailResponse,
    this.disableCounterOffer = false,
  });

  @override
  _BidderItemComponentState createState() => _BidderItemComponentState();
}

class _BidderItemComponentState extends State<BidderItemComponent> {
  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {}

  Future<void> savePostJobReq() async {
    showConfirmDialogCustom(
      context,
      negativeText: language.lblNo,
      dialogType: DialogType.CONFIRMATION,
      primaryColor: context.primaryColor,
      title:
          '${language.doYouWantToAssign} ${widget.data.provider!.displayName.validate()}?',
      positiveText: language.lblYes,
      onAccept: (c) async {
        List<int> serviceList = [];
        if (widget.postJobData.service.validate().isNotEmpty) {
          widget.postJobData.service.validate().forEach((element) {
            serviceList.add(element.id.validate());
          });
        }

        Map request = {
          CommonKeys.id: widget.postRequestId.validate(),
          PostJob.providerId: widget.data.providerId.validate(),
          PostJob.jobPrice: widget.data.price.validate(),
          PostJob.status: JOB_REQUEST_STATUS_ASSIGNED,
          PostJob.serviceId: serviceList,
        };

        appStore.setLoading(true);
        await savePostJob(request).then((value) {
          appStore.setLoading(false);
          toast(value.message.validate());
          finish(context);
          LiveStream().emit(LIVESTREAM_UPDATE_BIDER);
          widget.postJobDetailResponse!.postRequestDetail!.jobPrice =
              widget.data.price.validate();
        }).catchError((e) {
          appStore.setLoading(false);
          log(e.toString());
        });
      },
    );
  }

  bool pressAccept = false;

  void _showAcceptBidDialog() {
    DateTime? prefilledDate;
    final rawTime = widget.postJobData.urgentBookingTime.validate();
    if (rawTime.isNotEmpty) {
      try {
        prefilledDate = DateTime.parse(rawTime);
      } catch (_) {}
    }

    showInDialog(
      context,
      builder: (context) => AcceptBidDialog(
        initialDate: prefilledDate,
        onConfirm: (dateTime, description) async {
          await _handleSubmitClick(
            bookingDate: dateTime,
            description: description,
          );
        },
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    );
  }

  _handleSubmitClick({
    bool? isEditPrice = false,
    String? newPrice,
    DateTime? bookingDate,
    String? description,
  }) async {
    if (isEditPrice == true) {
      // Counter-offer still gets its own confirmation step.
      final String providerName = widget.data.provider!.displayName.validate();
      showConfirmDialogCustom(
        context,
        negativeText: language.lblNo,
        dialogType: DialogType.CONFIRMATION,
        primaryColor: context.primaryColor,
        title: '${language.doYouWantToSendCounterOffer} $providerName?',
        positiveText: language.lblYes,
        onAccept: (c) async {
          await _submitBid(
            isEditPrice: isEditPrice,
            newPrice: newPrice,
            bookingDate: bookingDate,
            description: description,
          );
        },
      );
    } else {
      // Accepting a bid: the date/time dialog the user just submitted IS the
      // confirmation — no need for a second Yes/No prompt on top of it.
      await _submitBid(
        isEditPrice: isEditPrice,
        newPrice: newPrice,
        bookingDate: bookingDate,
        description: description,
      );
    }
  }

  Future<void> _submitBid({
    bool? isEditPrice = false,
    String? newPrice,
    DateTime? bookingDate,
    String? description,
  }) async {
    appStore.setLoading(true);
    final num bidPrice = _hasCounterOffer
        ? widget.data.offerPrice.validate()
        : widget.data.price.validate();
    final num totalAmount = bidPrice;

    Map request = isEditPrice == true
        ? {
            CommonKeys.id: widget.data.id.validate(),
            PostJob.postRequestId: widget.postRequestId.validate(),
            PostJob.providerId: widget.data.providerId.validate(),
            PostJob.counterOfferPrice: newPrice.validate(),
            PostJob.bidStatus: counterOfferByCustomer,
          }
        : {
            PostJob.postRequestId: widget.postRequestId.validate(),
            PostJob.providerId: widget.data.providerId.validate(),
            PostJob.bidStatus: JOB_REQUEST_ACCEPTED_BY_CUSTOMER,
            'is_booking': true,
            PostJob.serviceId:
                widget.postJobData.service.validate().isNotEmpty
                    ? widget.postJobData.service!.first.id.validate()
                    : 0,
            CommonKeys.date: bookingDate != null
                ? DateFormat(BOOKING_SAVE_FORMAT).format(bookingDate)
                : '',
            BookService.amount: bidPrice,
            BookService.totalAmount: totalAmount,
            BookService.quantity: 1,
            PostJob.description: description?.trim().isNotEmpty == true
                ? description!.trim()
                : language.counterOffer,
            CommonKeys.type: BOOKING_TYPE_USER_POST_JOB,
            BookService.totalPlatformCommissionAmount: 0,
          };

    await saveBid(request).then((value) {
      appStore.setLoading(false);
      toast(value.message.validate());
      LiveStream().emit(LIVESTREAM_UPDATE_BIDER);
      widget.postJobDetailResponse!.postRequestDetail!.jobPrice =
          widget.data.price.validate();
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString());
    });
  }

  void _openEditPriceDialog(
      {required bool isCounterOffer, required String initialPrice}) {
    showInDialog(
      context,
      builder: (context) => EditPriceDialog(
        isCounterOffer: isCounterOffer,
        onPriceUpdated: (price) async {
          if (price != null) {
            await _handleSubmitClick(
                isEditPrice: true, newPrice: price.toString());
            setState(() {});
          }
        },
        initialPrice: num.tryParse(initialPrice)?.toString() ?? '',
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    );
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  bool get _isRejected =>
      widget.data.bidStatus.validate() == JOB_REQUEST_REJECTED_BY_PROVIDER ||
      widget.data.bidStatus.validate() == JOB_REQUEST_REJECTED_BY_CUSTOMER;

  bool get _hasCounterOffer =>
      widget.data.offerPrice != null && widget.data.offerPrice.validate() > 0;

  bool get _isAlreadyBooked =>
      widget.postJobData.bookingId != null && widget.postJobData.bookingId != 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          /// ── Header ──────────────────────────────────────────
          _buildHeader(context),

          /// ── Body ────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Bid Price row
                10.height,
                _buildPriceTile(
                  context,
                  label: language.bidPrice,
                  price: widget.data.price.validate(),
                  accentColor: context.primaryColor,
                  // onEditTap: () => _openEditPriceDialog(
                  //   isCounterOffer: false,
                  //   initialPrice: widget.data.price.validate().toString(),
                  // ),
                ),

                if (_hasCounterOffer) ...[
                  10.height,
                  _buildPriceTile(
                    context,
                    label: language.counterOffer,
                    price: widget.data.offerPrice.validate(),
                    accentColor: context.primaryColor,
                    // onEditTap: () => _openEditPriceDialog(
                    //   isCounterOffer: true,
                    //   initialPrice: widget.data.offerPrice.validate().toString(),
                    // ),
                  ),
                ],

                12.height,

                /// Action buttons
                // if (widget.data.bidStatus != JOB_REQUEST_ACCEPTED_BY_PROVIDER)
                if (!_isAlreadyBooked &&
                    widget.data.bidStatus != JOB_REQUEST_ACCEPTED_BY_CUSTOMER &&
                    widget.data.bidStatus != JOB_REQUEST_REJECTED_BY_CUSTOMER &&
                    widget.data.bidStatus != JOB_REQUEST_ACCEPTED_BY_PROVIDER &&
                    widget.data.bidStatus != JOB_REQUEST_REJECTED_BY_PROVIDER &&
                    widget.data.bidStatus != JOB_REQUEST_STATUS_ASSIGNED &&
                    widget.data.bidStatus != JOB_REQUEST_CONFIRMED &&
                    widget.data.bidStatus != counterOfferByCustomer)
                  _buildActionButtons(context),

                /// Rejected label from parent job
                // if (widget.postJobData.bidStatus ==
                //     JOB_REQUEST_REJECTED_BY_CUSTOMER) ...[
                //   Container(
                //     margin: EdgeInsets.only(top: 10),
                //     padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                //     decoration: BoxDecoration(
                //       color: cancelled.withOpacity(0.1),
                //       borderRadius: BorderRadius.circular(20),
                //     ),
                //     child: Text(
                //       language.rejected,
                //       style: boldTextStyle(color: cancelled, size: 12),
                //     ),
                //   ),
                //   if (widget.postJobData.reason.validate().isNotEmpty) ...[
                //     6.height,
                //     Container(
                //       width: context.width(),
                //       padding:
                //           EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                //       decoration: BoxDecoration(
                //         color: cancelled.withOpacity(0.05),
                //         borderRadius: BorderRadius.circular(12),
                //       ),
                //       child: Text(
                //         '${language.reason}: ${widget.postJobData.reason.validate()}',
                //         style: secondaryTextStyle(size: 12),
                //       ),
                //     ),
                //   ],
                // ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.primaryColor.withOpacity(0.13),
            context.primaryColor.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          /// Profile picture
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: context.primaryColor.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: context.primaryColor.withOpacity(0.15),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                )
              ],
            ),
            child: CachedImageWidget(
              url: widget.data.provider!.profileImage.validate(),
              height: 58,
              width: 58,
              fit: BoxFit.cover,
              circle: true,
            ),
          ),

          14.width,

          /// Name + designation + rating
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.data.provider!.displayName.validate(),
                  style: boldTextStyle(size: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.data.provider!.designation
                    .validate()
                    .isNotEmpty) ...[
                  2.height,
                  Text(
                    widget.data.provider!.designation.validate(),
                    style: secondaryTextStyle(size: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                6.height,
                Row(
                  children: [
                    DisabledRatingBarWidget(
                      rating: widget.data.provider!.providersServiceRating
                          .validate(),
                      size: 13,
                    ),
                    6.width,
                    Text(
                      widget.data.provider!.providersServiceRating
                          .validate()
                          .toStringAsFixed(1),
                      style: secondaryTextStyle(size: 12),
                    ),
                  ],
                ),
                if (widget.data.provider!.totalCompletedJobs != null ||
                    widget.data.provider!.createdAt.validate().isNotEmpty) ...[
                  6.height,
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (widget.data.provider!.totalCompletedJobs != null)
                        _metaInfoChip(
                          Icons.task_alt_rounded,
                          '${widget.data.provider!.totalCompletedJobs} ${language.completedJobsLabel}',
                        ),
                      if (widget.data.provider!.createdAt.validate().isNotEmpty)
                        _metaInfoChip(
                          Icons.calendar_month_rounded,
                          '${language.joinedOnLabel} ${formatBookingDate(widget.data.provider!.createdAt, format: 'MMM yyyy')}',
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          /// Status badge or edit icon at top-right
          if (_isRejected)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: rejected.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: rejected.withOpacity(0.3)),
              ),
              child: Text(
                language.rejected,
                style: boldTextStyle(color: rejected, size: 11),
              ),
            )
          else

          /// Eye-catching edit button at top
          if (!_isAlreadyBooked &&
              widget.data.offerPrice == null &&
              widget.data.bidStatus != JOB_REQUEST_ACCEPTED_BY_CUSTOMER &&
              widget.data.bidStatus != JOB_REQUEST_REJECTED_BY_CUSTOMER &&
              widget.data.bidStatus != JOB_REQUEST_ACCEPTED_BY_PROVIDER &&
              widget.data.bidStatus != JOB_REQUEST_REJECTED_BY_PROVIDER &&
              widget.data.bidStatus != JOB_REQUEST_STATUS_ASSIGNED &&
              widget.data.bidStatus != JOB_REQUEST_CONFIRMED &&
              widget.data.bidStatus != counterOfferByCustomer)
            GestureDetector(
              onTap: () => widget.disableCounterOffer
                  ? toast(language.counterOfferNotAllowed)
                  : _openEditPriceDialog(
                      isCounterOffer: true,
                      initialPrice: widget.data.price.validate().toString(),
                    ),
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.primaryColor,
                      context.primaryColor.withOpacity(0.75)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: context.primaryColor.withOpacity(0.35),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(Icons.edit_rounded, color: Colors.white, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  Widget _metaInfoChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: textSecondaryColorGlobal.withOpacity(0.08),
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

  Widget _buildPriceTile(
    BuildContext context, {
    required String label,
    required num price,
    required Color accentColor,
    // required VoidCallback onEditTap,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.sell_rounded, color: accentColor, size: 18),
          ),
          12.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: secondaryTextStyle(size: 11)),
                4.height,
                PriceWidget(
                  price: price,
                  isHourlyService: false,
                  color: accentColor,
                  size: 15,
                  isFreeService: false,
                ),
              ],
            ),
          ),
          // GestureDetector(
          //   onTap: onEditTap,
          //   child: Container(
          //     padding: EdgeInsets.all(6),
          //     decoration: BoxDecoration(
          //       color: accentColor.withOpacity(0.12),
          //       borderRadius: BorderRadius.circular(8),
          //     ),
          //     child: Icon(Icons.edit_rounded, size: 15, color: accentColor),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        /// Accept Button
        Expanded(
          child: GestureDetector(
            onTap: () {
              _showAcceptBidDialog();
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.25),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      color: Colors.white, size: 17),
                  6.width,
                  Text(language.accept,
                      style: boldTextStyle(color: Colors.white, size: 13)),
                ],
              ),
            ),
          ),
        ),

        10.width,

        /// Reject Button
        Expanded(
          child: GestureDetector(
            onTap: () {
              showInDialog(
                context,
                contentPadding: EdgeInsets.zero,
                backgroundColor: context.scaffoldBackgroundColor,
                builder: (context) => AppCommonDialog(
                  title: language.holdOrAssignService,
                  child: PostReasonDialog(
                    data: widget.data,
                    postRequestId: widget.postRequestId,
                    postJobData: widget.postJobData,
                    postJobDetailResponse: widget.postJobDetailResponse,
                  ),
                ),
              ).then((value) async {
                if (value != null) {
                  init();
                  setState(() {});
                }
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.25),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel_outlined, color: Colors.white, size: 17),
                  6.width,
                  Text(language.reject,
                      style: boldTextStyle(color: Colors.white, size: 13)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// ─────────────────────────────────────────────────────────
/// Accept Bid Dialog — description
/// ─────────────────────────────────────────────────────────
class AcceptBidDialog extends StatefulWidget {
  final Future<void> Function(DateTime dateTime, String description) onConfirm;
  final DateTime? initialDate;

  const AcceptBidDialog({required this.onConfirm, this.initialDate, Key? key})
      : super(key: key);

  @override
  State<AcceptBidDialog> createState() => _AcceptBidDialogState();
}

class _AcceptBidDialogState extends State<AcceptBidDialog> {
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    if (mounted) Navigator.pop(context);
    await widget.onConfirm(
      widget.initialDate ?? DateTime.now(),
      _descriptionController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// ── Icon badge ──
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.primaryColor,
                  context.primaryColor.withOpacity(0.7)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: context.primaryColor.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.check_circle_rounded,
                size: 36, color: Colors.white),
          ),

          20.height,

          Text(
            language.acceptBidDialogTitle,
            style: boldTextStyle(size: 22),
            textAlign: TextAlign.center,
          ),

          10.height,

          Text(
            language.acceptBidSubtitle,
            style: secondaryTextStyle(size: 13),
            textAlign: TextAlign.center,
          ),

          24.height,

          /// ── Description field ──
          CustomAppTextField(
            controller: _descriptionController,
            textFieldType: TextFieldType.MULTILINE,
            isValidationRequired: false,
            maxLines: 4,
            minLines: 3,
            decoration: inputDecoration(
              context,
              labelText: language.bookingDescriptionOptional,
              hintText: language.writeHere,
              prefixIcon: Icon(Icons.description_rounded,
                      color: context.primaryColor, size: 20)
                  .paddingAll(12),
              fillColor: appStore.isDarkMode
                  ? context.scaffoldBackgroundColor
                  : context.cardColor,
            ),
            textStyle: primaryTextStyle(size: 14),
          ),

          28.height,

          /// ── Buttons ──
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                      color: context.cardColor,
                    ),
                    alignment: Alignment.center,
                    child: Text(language.lblCancel,
                        style: boldTextStyle(size: 15)),
                  ),
                ),
              ),
              14.width,
              Expanded(
                child: GestureDetector(
                  onTap: _isLoading ? null : _onConfirm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [
                          context.primaryColor,
                          context.primaryColor.withOpacity(0.75)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: context.primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(language.accept,
                            style:
                                boldTextStyle(color: Colors.white, size: 15)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────
/// Edit / Counter-Offer Price Dialog
/// ─────────────────────────────────────────────────────────
class EditPriceDialog extends StatefulWidget {
  final String? initialPrice;
  final bool isCounterOffer;
  final Function(String? price)? onPriceUpdated;

  EditPriceDialog({
    this.initialPrice,
    this.isCounterOffer = false,
    this.onPriceUpdated,
  });

  @override
  State<EditPriceDialog> createState() => _EditPriceDialogState();
}

class _EditPriceDialogState extends State<EditPriceDialog> {
  final TextEditingController priceController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    priceController.text = widget.initialPrice ?? '';
  }

  @override
  void dispose() {
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor = context.primaryColor;

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Icon badge
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor, accentColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.35),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(Icons.edit_rounded, size: 36, color: Colors.white),
            ),

            20.height,

            /// Title — changes when isCounterOffer is true
            Text(
              widget.isCounterOffer ? language.counterOffer : language.bidPrice,
              style: boldTextStyle(size: 22),
              textAlign: TextAlign.center,
            ),

            10.height,

            Text(
              widget.isCounterOffer
                  ? language.enterCounterOfferPrice
                  : language.updateBidPrice,
              textAlign: TextAlign.center,
              style: secondaryTextStyle(size: 13),
            ),

            24.height,

            /// Price field — app-standard CustomAppTextField
            CustomAppTextField(
              controller: priceController,
              textFieldType: TextFieldType.NUMBER,
              isValidationRequired: true,
              errorThisFieldRequired: language.enteramount,
              decoration: inputDecoration(
                context,
                labelText: language.bidPrice,
                prefixIcon:
                    Icon(Icons.sell_rounded, color: accentColor, size: 20)
                        .paddingAll(12),
                fillColor: appStore.isDarkMode
                    ? context.scaffoldBackgroundColor
                    : context.cardColor,
              ),
              textStyle: primaryTextStyle(size: 16),
            ),

            28.height,

            /// Buttons row
            Row(
              children: [
                /// Cancel
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                        color: context.cardColor,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        language.lblNo,
                        style: boldTextStyle(size: 15),
                      ),
                    ),
                  ),
                ),

                14.width,

                /// Submit
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      if (_formKey.currentState!.validate()) {
                        final price = priceController.text.trim();
                        if (price.isEmpty || (num.tryParse(price) ?? 0) <= 0) {
                          toast(language.enteramount);
                          return;
                        }
                        await widget.onPriceUpdated?.call(price);
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          colors: [accentColor, accentColor.withOpacity(0.75)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        language.lblYes,
                        style: boldTextStyle(color: Colors.white, size: 15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
