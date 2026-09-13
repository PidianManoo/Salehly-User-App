import 'package:booking_system_flutter/screens/shop/shimmer/shop_detail_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../component/back_widget.dart';
import '../../component/base_scaffold_widget.dart';
import '../../component/cached_image_widget.dart';
import '../../component/empty_error_state_widget.dart';
import '../../component/image_border_component.dart';
import '../../main.dart';
import '../../model/shop_detail_model.dart';
import '../../network/rest_apis.dart';

class ShopDetailScreen extends StatefulWidget {
  final int shopId;
  ShopDetailScreen({required this.shopId});

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  Future<ShopDetailModel>? future;
  int page = 1;

  @override
  void initState() {
    super.initState();
    setStatusBarColor(transparentColor, delayInMilliSeconds: 1000);
    init();
  }

  void init() async {
    future = getShopDetailApi(shopId: widget.shopId);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: SnapHelperWidget<ShopDetailModel>(
        future: future,
        // initialData: cachedBlogDetail.firstWhere((element) => element?.$1 == widget.blogId.validate(), orElse: () => null)?.$2,
        loadingWidget: ShopDetailShimmer(),
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
        onSuccess: (data) {
          return Stack(
            children: [
              AnimatedScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                listAnimationType: ListAnimationType.FadeIn,
                fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                padding: EdgeInsets.only(bottom: 120),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 375,
                    width: context.width(),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (data.data!.shopAttachment.validate().isNotEmpty)
                          SizedBox(
                            height: 400,
                            width: context.width(),
                            child: CachedImageWidget(
                              url: data.data!.shopAttachment!.first.url
                                  .validate(),
                              fit: BoxFit.cover,
                              height: 400,
                            ),
                          ),

                        // Positioned(
                        //   bottom: 0,
                        //   left: 16,
                        //   right: 16,
                        //   child: Column(
                        //     children: [
                        //       Row(
                        //         children: [
                        //           Wrap(
                        //             spacing: 16,
                        //             runSpacing: 16,
                        //             children: List.generate(
                        //               widget.blogData.attachment!.take(2).length,
                        //                   (i) => Container(
                        //                 decoration: BoxDecoration(border: Border.all(color: white, width: 2), borderRadius: radius()),
                        //                 child: GalleryComponent(
                        //                   images: widget.blogData.attachment.validate().map((e) => e.url.validate()).toList(),
                        //                   index: i,
                        //                   padding: 32,
                        //                   height: 60,
                        //                   width: 60,
                        //                 ),
                        //               ),
                        //             ),
                        //           ),
                        //           16.width,
                        //           if (widget.blogData.attachment!.length > 2)
                        //             Blur(
                        //               borderRadius: radius(),
                        //               padding: EdgeInsets.zero,
                        //               child: Container(
                        //                 height: 60,
                        //                 width: 60,
                        //                 alignment: Alignment.center,
                        //                 decoration: BoxDecoration(border: Border.all(color: white, width: 2), borderRadius: radius()),
                        //                 child: Text('+' '${widget.blogData.attachment!.length - 2}', style: boldTextStyle(color: white)),
                        //               ),
                        //             ).onTap(() {
                        //               GalleryScreen(
                        //                 attachments: widget.blogData.attachment.validate().map((e) => e.url.validate()).toList(),
                        //                 serviceName: widget.blogData.title.validate(),
                        //               ).launch(context, pageRouteAnimation: PageRouteAnimation.Fade, duration: 400.milliseconds).then((value) {
                        //                 setStatusBarColor(transparentColor, delayInMilliSeconds: 1000);
                        //               });
                        //             }),
                        //         ],
                        //       ),
                        //       16.height,
                        //     ],
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                  16.height,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data.data!.name.validate(),
                          style: boldTextStyle(size: 20)),
                      16.height,
                      Row(
                        children: [
                          ImageBorder(
                              src: data.data?.profileImage.validate() ?? "",
                              height: 30),
                          16.width,
                          Marquee(
                                  child: Text(
                                      data.data?.providerName.validate() ?? '',
                                      style: boldTextStyle()))
                              .expand(),
                        ],
                      ),
                      16.height,
                      Text(
                        language.hintDescription,
                        style: boldTextStyle(),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      4.height,
                      ReadMoreText(
                        '${data.data!.description.validate()}',
                        style: secondaryTextStyle(),
                        colorClickableText: context.primaryColor,
                        textAlign: TextAlign.justify,
                      ),
                      8.height,
                      Text(
                        language.lblLocation,
                        style: boldTextStyle(),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      4.height,
                      Text(
                        '${data.data!.location.validate()}',
                        style: secondaryTextStyle(),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      8.height,
                      Text(
                        language.businessRegistrationNumber,
                        style: boldTextStyle(),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      4.height,
                      Text(
                        '${data.data!.businessRegistrationNumber.validate()}',
                        style: secondaryTextStyle(),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      8.height,
                      Text(
                        language.hintContactNumberTxt,
                        style: boldTextStyle(),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      4.height,
                      Text(
                        '${data.data!.contactNumber.validate()}',
                        style: secondaryTextStyle(),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ).paddingSymmetric(horizontal: 16),
                ],
              ),
              Positioned(
                top: context.statusBarHeight + 8,
                left: 10,
                child: Container(
                  child: BackWidget(iconColor: context.iconColor),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.cardColor.withValues(alpha: 0.7)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
