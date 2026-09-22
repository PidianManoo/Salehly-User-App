import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/empty_error_state_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/refund_request_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import 'component/refund_request_item_component.dart';

class RefundRequestListScreen extends StatefulWidget {
  @override
  State<RefundRequestListScreen> createState() =>
      _RefundRequestListScreenState();
}

class _RefundRequestListScreenState extends State<RefundRequestListScreen> {
  Future<List<RefundRequestData>>? future;

  List<RefundRequestData> refundRequestListData = [];

  int page = 1;
  bool isLastPage = false;

  @override
  void initState() {
    super.initState();
    appStore.setLoading(true);
    fetchList();
  }

  void fetchList() {
    future = getRefundRequestList(
      page: page,
      refundRequestListData: refundRequestListData,
      lastPageCallback: (b) {
        isLastPage = b;
      },
    );
    future!.whenComplete(() => appStore.setLoading(false));
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: language.myRefundRequests,
      showLoader: false,
      child: Stack(
        children: [
          SnapHelperWidget<List<RefundRequestData>>(
            future: future,
            loadingWidget: Offstage(),
            onSuccess: (list) {
              return AnimatedListView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                listAnimationType: ListAnimationType.FadeIn,
                fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                itemCount: list.length,
                shrinkWrap: true,
                emptyWidget: appStore.isLoading
                    ? Offstage()
                    : NoDataWidget(
                        title: language.noRefundRequestFound,
                        imageWidget: EmptyStateWidget(),
                      ),
                onNextPage: () {
                  if (!isLastPage) {
                    page++;
                    appStore.setLoading(true);
                    fetchList();
                    setState(() {});
                  }
                },
                onSwipeRefresh: () async {
                  page = 1;
                  fetchList();
                  setState(() {});

                  return await 1.seconds.delay;
                },
                disposeScrollController: true,
                itemBuilder: (context, index) {
                  return RefundRequestItemComponent(data: list[index]);
                },
              );
            },
            errorBuilder: (error) {
              return NoDataWidget(
                title: error,
                imageWidget: ErrorStateWidget(),
                retryText: language.reload,
                onRetry: () {
                  page = 1;
                  appStore.setLoading(true);
                  fetchList();
                  setState(() {});
                },
              );
            },
          ),
          Observer(builder: (_) => LoaderWidget().visible(appStore.isLoading)),
        ],
      ),
    );
  }
}
