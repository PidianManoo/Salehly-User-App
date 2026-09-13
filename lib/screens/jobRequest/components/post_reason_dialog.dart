import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/get_my_post_job_list_response.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:booking_system_flutter/utils/custom_app_field.dart';
import '../../../model/post_job_detail_response.dart';
import '../../../network/rest_apis.dart';
import '../../../utils/constant.dart';
import '../../../utils/model_keys.dart';

class PostReasonDialog extends StatefulWidget {
  final BidderData data;
  final int? postRequestId;
  final PostJobData postJobData;
  final PostJobDetailResponse? postJobDetailResponse;
  PostReasonDialog({required this.data, required this.postRequestId, required this.postJobData, this.postJobDetailResponse});

  @override
  State<PostReasonDialog> createState() => _PostReasonDialogState();
}

class _PostReasonDialogState extends State<PostReasonDialog> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController _textFieldReason = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: context.width(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  16.height,
                  Form(
                    key: formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: CustomAppTextField(
                      controller: _textFieldReason,
                      textFieldType: TextFieldType.MULTILINE,
                      decoration: inputDecoration(context, labelText: language.enterReason, fillColor: appStore.isDarkMode ? context.scaffoldBackgroundColor : context.cardColor),
                      minLines: 4,
                      maxLines: 10,
                    ),
                  ),
                  24.height,
                  AppButton(
                    color: primaryColor,
                    height: 40,
                    text: language.btnSubmit,
                    textStyle: boldTextStyle(color: Colors.white),
                    width: context.width() - context.navigationBarHeight,
                    onTap: () {
                      // submit();
                      _handleSubmitClick();
                    },
                  ),
                  8.height,
                ],
              ).paddingAll(16)
            ],
          ),
        ),
        Observer(
          builder: (context) => LoaderWidget().withSize(height: 80, width: 80).visible(appStore.isLoading),
        )
      ],
    );
  }

  Future<void> submit() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
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
        PostJob.status: JOB_REQUEST_STATUS_REJECTED,
        PostJob.serviceId: serviceList,
        PostJob.rejectionReason : _textFieldReason.text.validate()
      };

      appStore.setLoading(true);

      await savePostJob(request).then((value) {
        appStore.setLoading(false);
        toast(value.message.validate());

        finish(context);
        LiveStream().emit(LIVESTREAM_UPDATE_BIDER);
        widget.postJobDetailResponse!.postRequestDetail!.jobPrice = widget.data.price.validate();
      }).catchError((e) {
        appStore.setLoading(false);
        log(e.toString());
      });
    }
  }

  void _handleSubmitClick() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
    appStore.setLoading(true);
    Map request = {
      CommonKeys.id: widget.data.id.validate(),
      PostJob.postRequestId: widget.postRequestId.validate(),
      PostJob.providerId: widget.data.providerId.validate(),
      PostJob.jobPrice: widget.data.price.validate(),
      PostJob.bidStatus: JOB_REQUEST_REJECTED_BY_CUSTOMER,
      PostJob.rejectionReason: _textFieldReason.text.validate()
    };

    saveBid(request).then((value) {
      appStore.setLoading(false);

      toast(value.message.validate());
      finish(context, true);
      LiveStream().emit(LIVESTREAM_UPDATE_BIDER);
      widget.postJobDetailResponse!.postRequestDetail!.jobPrice = widget.data.price.validate();
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString());
    });
    }
  }
}
