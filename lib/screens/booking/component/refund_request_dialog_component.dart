import 'dart:io';

import 'package:booking_system_flutter/component/custom_image_picker.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/model_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:booking_system_flutter/utils/custom_app_field.dart';

/// A card-style dialog for submitting a customer-initiated refund request
/// against a completed booking (POST refund-request-save). Mirrors the
/// premium header + card layout used across the app's other action dialogs,
/// with a required reason field instead of a single-purpose action.
class RefundRequestDialogComponent extends StatefulWidget {
  final int bookingId;

  RefundRequestDialogComponent({required this.bookingId});

  @override
  State<RefundRequestDialogComponent> createState() =>
      _RefundRequestDialogComponentState();
}

class _RefundRequestDialogComponentState
    extends State<RefundRequestDialogComponent> {
  static const int maxAttachments = 5;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController reasonCont = TextEditingController();
  List<File> attachmentFiles = [];

  Future<void> submit() async {
    hideKeyboard(context);

    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      appStore.setLoading(true);

      Map<String, dynamic> request = {
        RefundRequestKey.bookingId: widget.bookingId,
        RefundRequestKey.reason: reasonCont.text.trim(),
      };

      saveRefundRequestMultiPart(request: request, attachments: attachmentFiles)
          .then((res) {
        appStore.setLoading(false);
        finish(context, true);
        toast(res.message.validate());
      }).catchError((e) {
        appStore.setLoading(false);
        toast(e.toString(), print: true);
      });
    }
  }

  Future<void> _pickAttachment() async {
    if (attachmentFiles.length >= maxAttachments) {
      toast(language.maxRefundAttachmentsReached);
      return;
    }

    await showInDialog(
      context,
      contentPadding: EdgeInsets.symmetric(vertical: 16),
      title: Text(language.chooseAction, style: boldTextStyle()),
      builder: (p0) => FilePickerDialog(isSelected: false),
    ).then((file) async {
      if (file == GalleryFileTypes.CAMERA) {
        await getCameraImage().then((value) {
          attachmentFiles.add(value);
          setState(() {});
        });
      } else if (file == GalleryFileTypes.GALLERY) {
        await getMultipleImageSource().then((value) {
          int remainingSlots = maxAttachments - attachmentFiles.length;
          attachmentFiles.addAll(value.take(remainingSlots));
          setState(() {});
        });
      }
    });
  }

  Widget _addAttachmentTile() {
    return GestureDetector(
      onTap: _pickAttachment,
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: context.primaryColor.withValues(alpha: 0.06),
          borderRadius: radius(14),
          border: Border.all(
            color: context.primaryColor.withValues(alpha: 0.28),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined,
                color: context.primaryColor, size: 22),
            6.height,
            Text(language.chooseImages,
                style:
                    secondaryTextStyle(size: 10, color: context.primaryColor),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _attachmentThumb(int index) {
    File file = attachmentFiles[index];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: radius(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius(14),
            child: Image.file(file, width: 84, height: 84, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: GestureDetector(
            onTap: () {
              attachmentFiles.removeAt(index);
              setState(() {});
            },
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: rejected,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.close_rounded, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: radius(20),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────
              Container(
                padding: EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.primaryColor,
                      context.primaryColor.withValues(alpha: 0.8)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: radiusOnly(topLeft: 20, topRight: 20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.assignment_return_outlined,
                          color: Colors.white, size: 18),
                    ),
                    12.width,
                    Text(language.requestRefund,
                            style: boldTextStyle(color: Colors.white, size: 16))
                        .expand(),
                    IconButton(
                      onPressed: () => finish(context),
                      icon: Icon(Icons.close_rounded,
                          color: Colors.white, size: 20),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              // ── Form ──────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(language.refundRequestSubTitle,
                        style: secondaryTextStyle(size: 13)),
                    18.height,
                    CustomAppTextField(
                      textFieldType: TextFieldType.MULTILINE,
                      controller: reasonCont,
                      minLines: 4,
                      maxLines: 6,
                      errorThisFieldRequired: language.requiredText,
                      decoration: inputDecoration(context,
                              labelText: language.refundReason)
                          .copyWith(
                        fillColor: context.scaffoldBackgroundColor,
                        filled: true,
                      ),
                    ),
                    20.height,
                    Row(
                      children: [
                        Icon(Icons.attach_file_rounded,
                            size: 16, color: context.primaryColor),
                        6.width,
                        Text(language.refundAttachmentsLabel,
                                style: boldTextStyle(size: 13))
                            .expand(),
                        Text('${attachmentFiles.length}/$maxAttachments',
                            style: secondaryTextStyle(size: 12)),
                      ],
                    ),
                    10.height,
                    SizedBox(
                      height: 84,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: attachmentFiles.length +
                            (attachmentFiles.length < maxAttachments ? 1 : 0),
                        separatorBuilder: (context, index) => 10.width,
                        itemBuilder: (context, index) {
                          if (index == attachmentFiles.length) {
                            return _addAttachmentTile();
                          }
                          return _attachmentThumb(index);
                        },
                      ),
                    ),
                    22.height,
                    Observer(
                      builder: (_) => Container(
                        decoration: BoxDecoration(
                          borderRadius: radius(14),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  context.primaryColor.withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: AppButton(
                          text: language.send,
                          textColor: Colors.white,
                          color: context.primaryColor,
                          elevation: 0,
                          shapeBorder:
                              RoundedRectangleBorder(borderRadius: radius(14)),
                          width: context.width(),
                          onTap: submit,
                        ),
                      ).visible(!appStore.isLoading, defaultWidget: Loader()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
