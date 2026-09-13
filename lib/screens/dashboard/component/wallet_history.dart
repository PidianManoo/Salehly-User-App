import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/extensions/num_extenstions.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/base_scaffold_widget.dart';
import '../../../component/empty_error_state_widget.dart';
import '../../../component/loader_widget.dart';
import '../../../model/user_wallet_history.dart';
import '../../../network/rest_apis.dart';
import '../../../utils/common.dart';
import '../../wallet/component/wallet_card.dart';
import 'wallet_history_shimmer.dart';

class UserWalletHistoryScreen extends StatefulWidget {
  const UserWalletHistoryScreen({Key? key}) : super(key: key);

  @override
  State<UserWalletHistoryScreen> createState() =>
      _UserWalletHistoryScreenState();
}

class _UserWalletHistoryScreenState extends State<UserWalletHistoryScreen> {
  Future<List<WalletDataElement>>? future;

  List<WalletDataElement> walletHistoryList = [];
  int page = 1;
  bool isLastPage = false;
  num availableBalance = 0;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    future = getUserWalletHistory(
      page,
      walletDataList: walletHistoryList,
      availableBalance: (p0) {
        availableBalance = p0;
      },
      lastPageCallBack: (p) {
        isLastPage = p;
      },
    );
  }

  bool _isDebit(WalletDataElement data) {
    return data.activityData == null ||
        data.activityData!.transactionType.isEmptyOrNull ||
        data.activityData!.transactionType
            .toLowerCase()
            .contains(PAYMENT_STATUS_DEBIT);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: language.walletHistory,
      showLoader: false,
      child: Stack(
        children: [
          SnapHelperWidget<List<WalletDataElement>>(
            initialData: cachedWalletHistoryList,
            future: future,
            loadingWidget: WalletHistoryShimmer(),
            onSuccess: (snap) {
              return AnimatedScrollView(
                children: [
                  20.height,
                  WalletCard(
                    availableBalance: availableBalance,
                    callback: (value) {
                      if (value ?? false) {
                        init();
                        setState(() {});
                      }
                    },
                  ),
                  28.height,
                  if (snap.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            width: 3,
                            height: 18,
                            decoration: BoxDecoration(
                              color: context.primaryColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          10.width,
                          Text(
                            language.walletHistory,
                            style: boldTextStyle(size: 15),
                          ),
                        ],
                      ),
                    ),
                    14.height,
                  ],
                  AnimatedListView(
                    physics: NeverScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    listAnimationType: ListAnimationType.FadeIn,
                    fadeInConfiguration:
                        FadeInConfiguration(duration: 400.milliseconds),
                    itemCount: snap.length,
                    emptyWidget: NoDataWidget(
                      title: language.noDataAvailable,
                      imageWidget: EmptyStateWidget(),
                    ),
                    shrinkWrap: true,
                    disposeScrollController: true,
                    itemBuilder: (BuildContext context, index) {
                      WalletDataElement data = snap[index];
                      final isDebit = _isDebit(data);
                      final txColor =
                          isDebit ? Colors.red.shade600 : const Color(0xFF00968A);
                      final txBgColor = isDebit
                          ? Colors.red.withOpacity(0.08)
                          : const Color(0xFF00968A).withOpacity(0.08);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.045),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(width: 4, color: txColor),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 14),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 46,
                                          height: 46,
                                          decoration: BoxDecoration(
                                            color: txBgColor,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: Image.asset(
                                              isDebit
                                                  ? ic_diagonal_right_up_arrow
                                                  : ic_diagonal_left_down_arrow,
                                              height: 20,
                                              width: 20,
                                              color: txColor,
                                            ),
                                          ),
                                        ),
                                        12.width,
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              if (data.activityMessage
                                                  .validate()
                                                  .isNotEmpty)
                                                Text(
                                                  data.activityMessage
                                                      .validate(),
                                                  style:
                                                      boldTextStyle(size: 13),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              6.height,
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.access_time_rounded,
                                                    size: 11,
                                                    color: appTextSecondaryColor,
                                                  ),
                                                  4.width,
                                                  Expanded(
                                                    child: Text(
                                                      formatDate(data.datetime,
                                                          showDateWithTime:
                                                              true),
                                                      style: secondaryTextStyle(
                                                          size: 11),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        12.width,
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${isDebit ? '-' : '+'}${data.activityData!.creditDebitAmount.validate().toPriceFormat()}',
                                              style: boldTextStyle(
                                                color: txColor,
                                                size: 14,
                                                fontFamily:
                                                    saudiRiyalsFontFamily,
                                              ),
                                            ),
                                            6.height,
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color: txBgColor,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                isDebit
                                                    ? language.debit
                                                    : language.credit,
                                                style: secondaryTextStyle(
                                                  size: 10,
                                                  color: txColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  20.height,
                ],
                onNextPage: () {
                  if (!isLastPage) {
                    page++;
                    init();
                    setState(() {});
                  }
                },
                onSwipeRefresh: () async {
                  page = 1;
                  init();
                  setState(() {});
                  return await 2.seconds.delay;
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
                  init();
                  setState(() {});
                },
              );
            },
          ),
          Observer(
            builder: (_) =>
                LoaderWidget().visible(appStore.isLoading && page != 1),
          ),
        ],
      ),
    );
  }
}
