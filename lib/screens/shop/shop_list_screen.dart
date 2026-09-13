import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/screens/shop/shop_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../component/base_scaffold_widget.dart';
import '../../component/cached_image_widget.dart';
import '../../component/empty_error_state_widget.dart';
import '../../component/image_border_component.dart';
import '../../component/loader_widget.dart';
import '../../model/shop_list_model.dart';
import '../../network/rest_apis.dart';
import '../../utils/colors.dart';
import '../blog/shimmer/blog_shimmer.dart';

class ShopListScreen extends StatefulWidget {
  const ShopListScreen({super.key});

  @override
  State<ShopListScreen> createState() => _ShopListScreenState();
}

class _ShopListScreenState extends State<ShopListScreen> {
  Future<List<ShopListData>>? future;
  int page = 1;
  bool isLastPage = false;
  List<ShopListData> shopList = [];

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    future = getShopList(
      shopListData: shopList,
      page: page,
      latitude: filterStore.latitude,
      longitude: filterStore.longitude,
      lastPageCallback: (b) {
        isLastPage = b;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // return AppScaffold(
    //   appBarTitle: 'All Shop',
    //   child:
    return Stack(
        children: [
          SnapHelperWidget<List<ShopListData>>(
            initialData: cachedShopList,
            future: future,
            loadingWidget: BlogShimmer(),
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
            onSuccess: (snap) {
              return AnimatedListView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                listAnimationType: ListAnimationType.FadeIn,
                fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                itemCount: snap.length,
                emptyWidget: NoDataWidget(
                    title: language.noBlogsFound,
                    imageWidget: EmptyStateWidget()),
                shrinkWrap: true,
                onNextPage: () {
                  if (!isLastPage) {
                    page++;
                    appStore.setLoading(true);

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
                disposeScrollController: true,
                itemBuilder: (BuildContext context, index) {
                  var shopData = snap[index];
                  return GestureDetector(
                    onTap: () {
                      ShopDetailScreen(shopId: shopData.id.validate())
                          .launch(context);
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                      decoration: boxDecorationWithRoundedCorners(
                        borderRadius: radius(),
                        backgroundColor: context.cardColor,
                        border: appStore.isDarkMode
                            ? Border.all(color: context.dividerColor)
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 205,
                            width: context.width(),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                if (shopData.shopAttachment!.isNotEmpty) ...[
                                  ...List.generate(
                                      shopData.shopAttachment!.length,
                                      (index) => CachedImageWidget(
                                            url: shopData
                                                    .shopAttachment!.isNotEmpty
                                                ? shopData
                                                    .shopAttachment![index].url
                                                    .toString()
                                                : '',
                                            fit: BoxFit.cover,
                                            height: 180,
                                            width: context.width(),
                                            circle: false,
                                          ).cornerRadiusWithClipRRectOnly(
                                              topRight: defaultRadius.toInt(),
                                              topLeft: defaultRadius.toInt()))
                                ] else
                                  CachedImageWidget(
                                    url: '',
                                    fit: BoxFit.cover,
                                    height: 180,
                                    width: context.width(),
                                    circle: false,
                                  ).cornerRadiusWithClipRRectOnly(
                                      topRight: defaultRadius.toInt(),
                                      topLeft: defaultRadius.toInt())
                              ],
                            ),
                          ),
                          Marquee(
                                  directionMarguee:
                                      DirectionMarguee.oneDirection,
                                  child: Text(shopData.name.validate(),
                                          style: boldTextStyle())
                                      .paddingSymmetric(horizontal: 0))
                              .paddingSymmetric(horizontal: 12),
                          6.height,
                          Row(
                            children: [
                              ImageBorder(
                                  src: 'http://192.168.1.4:8000/storage/4/felix.png',
                                  height: 30),
                              8.width,
                              // if (widget.serviceData.providerName.validate().isNotEmpty)
                              Text('Felix Harris',
                                style: secondaryTextStyle(
                                    size: 12,
                                    color: appStore.isDarkMode
                                        ? Colors.white
                                        : appTextSecondaryColor),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ).expand()
                            ],
                          ).paddingSymmetric(horizontal: 12, vertical: 12)
                        ],
                      ),
                      // Row(
                      //   crossAxisAlignment: CrossAxisAlignment.start,
                      //   children: [
                      //  if (shopData.shopAttachment!.isNotEmpty)...[
                      //     ...List.generate(shopData.shopAttachment!.length,
                      //             (index) => CachedImageWidget(
                      //                  url: shopData.shopAttachment!.isNotEmpty ? shopData.shopAttachment![index].url.toString() : '',
                      //                  fit: BoxFit.cover,
                      //                  height: 80,
                      //                  width: 80,
                      //                  radius: defaultRadius,
                      //                  ))
                      //  ]
                      // else
                      //   CachedImageWidget(
                      //   url: '',
                      //   fit: BoxFit.cover,
                      //   height: 80,
                      //   width: 80,
                      //   radius: defaultRadius,
                      // ),
                      //     16.width,
                      //     Column(
                      //       crossAxisAlignment: CrossAxisAlignment.start,
                      //       children: [
                      //         Text(
                      //           shopData.name.validate(),
                      //           style: boldTextStyle(size: 14),
                      //           maxLines: 2,
                      //           overflow: TextOverflow.ellipsis,
                      //         ),
                      //         6.height,
                      //         Text(
                      //           shopData.description.validate(),
                      //           style: boldTextStyle(size: 14),
                      //           maxLines: 2,
                      //           overflow: TextOverflow.ellipsis,
                      //         ),
                      //         // Row(
                      //         //   children: [
                      //         //     Row(
                      //         //       children: [
                      //         //         ImageBorder(
                      //         //           src: widget.blogData!.authorImage.validate(),
                      //         //           height: 30,
                      //         //         ),
                      //         //         8.width,
                      //         //         Column(
                      //         //           crossAxisAlignment: CrossAxisAlignment.start,
                      //         //           children: [
                      //         //             Text(widget.blogData!.authorName.validate(), style: primaryTextStyle(size: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                      //         //             2.height,
                      //         //             Text(widget.blogData!.publishDate.validate(), style: secondaryTextStyle(size: 10)),
                      //         //           ],
                      //         //         ).expand(),
                      //         //       ],
                      //         //     ).expand(),
                      //         //     Row(
                      //         //       mainAxisAlignment: MainAxisAlignment.end,
                      //         //       children: [
                      //         //         Icon(Icons.remove_red_eye, size: 14, color: context.iconColor),
                      //         //         4.width,
                      //         //         Text('${widget.blogData!.totalViews.validate()} ', style: secondaryTextStyle()),
                      //         //         Text(language.views, style: secondaryTextStyle(), maxLines: 1, overflow: TextOverflow.ellipsis),
                      //         //       ],
                      //         //     )
                      //         //   ],
                      //         // ),
                      //       ],
                      //     ).expand(),
                      //     // Row(
                      //     //   children: [
                      //     //     ImageBorder(src: widget.serviceData.providerImage.validate(), height: 30),
                      //     //     8.width,
                      //     //     if (widget.serviceData.providerName.validate().isNotEmpty)
                      //     //       Text(
                      //     //         widget.serviceData.providerName.validate(),
                      //     //         style: secondaryTextStyle(size: 12, color: appStore.isDarkMode ? Colors.white : appTextSecondaryColor),
                      //     //         maxLines: 2,
                      //     //         overflow: TextOverflow.ellipsis,
                      //     //       ).expand()
                      //     //   ],
                      //     // )
                      //   ],
                      // ),
                    ),
                  );
                  // BlogItemComponent(blogData: snap[index]);
                },
              );
            },
          ),
          Observer(builder: (_) => LoaderWidget().visible(appStore.isLoading)),
        ],
    );
  }
}
