import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/disabled_rating_bar_widget.dart';
import 'package:booking_system_flutter/component/image_border_component.dart';
import 'package:booking_system_flutter/component/price_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/screens/booking/provider_info_screen.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_4/component/service_dashboard_component_4.dart';
import 'package:booking_system_flutter/screens/service/service_detail_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../newDashboard/dashboard_1/component/service_dashboard_component_1.dart';
import '../../newDashboard/dashboard_2/component/service_dashboard_component_2.dart';
import '../../newDashboard/dashboard_3/component/service_dashboard_component_3.dart';

class ServiceComponent extends StatefulWidget {
  final ServiceData serviceData;
  final double? width;
  final bool? isBorderEnabled;
  final VoidCallback? onUpdate;
  final bool isFavouriteService;
  final bool isFromDashboard;
  final bool isFromViewAllService;
  final bool isFromServiceDetail;

  ServiceComponent({
    required this.serviceData,
    this.width,
    this.isBorderEnabled,
    this.isFavouriteService = false,
    this.onUpdate,
    this.isFromDashboard = false,
    this.isFromViewAllService = false,
    this.isFromServiceDetail = false,
  });

  @override
  ServiceComponentState createState() => ServiceComponentState();
}

class ServiceComponentState extends State<ServiceComponent> {
  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    //
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    Widget buildServiceComponent() {
      return Observer(builder: (context) {
        if (appConfigurationStore.userDashboardType == DASHBOARD_1) {
          return ServiceDashboardComponent1(
            serviceData: widget.serviceData,
            width: widget.width != null
                ? widget.width
                : widget.isFromViewAllService
                    ? null
                    : 280,
            isFavouriteService: widget.isFavouriteService,
            isBorderEnabled: widget.isBorderEnabled,
            isFromDashboard: widget.isFromDashboard,
            onUpdate: () {
              widget.onUpdate?.call();
            },
          );
        } else if (appConfigurationStore.userDashboardType == DASHBOARD_2) {
          return ServiceDashboardComponent2(
            serviceData: widget.serviceData,
            width: widget.width != null
                ? widget.width
                : widget.isFromViewAllService
                    ? null
                    : 280,
            isFavouriteService: widget.isFavouriteService,
            isBorderEnabled: widget.isBorderEnabled,
            isFromDashboard: widget.isFromDashboard,
            onUpdate: () {
              widget.onUpdate?.call();
            },
          );
        } else if (appConfigurationStore.userDashboardType == DASHBOARD_3) {
          return ServiceDashboardComponent3(
            serviceData: widget.serviceData,
            isFavouriteService: widget.isFavouriteService,
            isBorderEnabled: widget.isBorderEnabled,
            isFromDashboard: widget.isFromDashboard,
            width: widget.width != null
                ? widget.width
                : widget.isFromViewAllService
                    ? null
                    : 280,
            onUpdate: () {
              widget.onUpdate?.call();
            },
          );
        } else if (appConfigurationStore.userDashboardType == DASHBOARD_4) {
          return ServiceDashboardComponent4(
            serviceData: widget.serviceData,
            isFavouriteService: widget.isFavouriteService,
            isBorderEnabled: widget.isBorderEnabled,
            width: widget.width != null
                ? widget.width
                : widget.isFromViewAllService
                    ? null
                    : 280,
            isFromDashboard: widget.isFromDashboard,
            onUpdate: () {
              widget.onUpdate?.call();
            },
          );
        } else {
          final String thumbnailUrl = widget.isFavouriteService
              ? (widget.serviceData.serviceAttachments.validate().isNotEmpty
                  ? widget.serviceData.serviceAttachments!.first.validate()
                  : '')
              : (widget.serviceData.attachments.validate().isNotEmpty
                  ? widget.serviceData.attachments!.first.validate()
                  : '');

          final String tag =
              widget.serviceData.subCategoryName.validate().isNotEmpty
                  ? widget.serviceData.subCategoryName.validate()
                  : widget.serviceData.categoryName.validate();

          // A compact horizontal list-row card — thumbnail + info side by
          // side — instead of a tall photo-on-top card, so a full list of
          // services reads as a scannable list rather than a stack of
          // oversized tiles.
          return Container(
            width: widget.width,
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: radius(16),
              border: Border.all(
                  color: appStore.isDarkMode
                      ? context.dividerColor
                      : context.dividerColor.withValues(alpha: 0.6)),
              boxShadow: appStore.isDarkMode
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CachedImageWidget(
                      url: thumbnailUrl,
                      height: 88,
                      width: 88,
                      fit: BoxFit.cover,
                      radius: 13,
                    ),
                    if (widget.serviceData.isOnlineService)
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                            border: Border.all(
                                color: context.cardColor, width: 1.6),
                          ),
                        ),
                      ),
                    if (widget.isFavouriteService)
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          padding: EdgeInsets.all(5),
                          decoration: boxDecorationWithShadow(
                              boxShape: BoxShape.circle,
                              backgroundColor: context.cardColor),
                          child: widget.serviceData.isFavourite == 1
                              ? ic_fill_heart.iconImage(
                                  color: favouriteColor, size: 13)
                              : ic_heart.iconImage(
                                  color: unFavouriteColor, size: 13),
                        ).onTap(() async {
                          if (widget.serviceData.isFavourite != 0) {
                            widget.serviceData.isFavourite = 1;
                            setState(() {});

                            await removeToWishList(
                                    serviceId: widget.serviceData.serviceId
                                        .validate()
                                        .toInt())
                                .then((value) {
                              if (!value) {
                                widget.serviceData.isFavourite = 1;
                                setState(() {});
                              }
                            });
                          } else {
                            widget.serviceData.isFavourite = 0;
                            setState(() {});

                            await addToWishList(
                                    serviceId: widget.serviceData.serviceId
                                        .validate()
                                        .toInt())
                                .then((value) {
                              if (!value) {
                                widget.serviceData.isFavourite = 1;
                                setState(() {});
                              }
                            });
                          }
                          widget.onUpdate?.call();
                        }),
                      ),
                  ],
                ),
                10.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tag.isNotEmpty)
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.primaryColor.withValues(alpha: 0.1),
                            borderRadius: radius(6),
                          ),
                          child: Text(
                            tag.toUpperCase(),
                            style: boldTextStyle(
                                size: 10, color: context.primaryColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      4.height,
                      Text(
                        widget.serviceData.name.validate(),
                        style: boldTextStyle(size: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      5.height,
                      DisabledRatingBarWidget(
                          rating: widget.serviceData.totalRating.validate(),
                          size: 11),
                      7.height,
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                ImageBorder(
                                    src: widget.serviceData.providerImage
                                        .validate(),
                                    height: 18),
                                5.width,
                                if (widget.serviceData.providerName
                                    .validate()
                                    .isNotEmpty)
                                  Flexible(
                                    child: Text(
                                      widget.serviceData.providerName
                                          .validate(),
                                      style: secondaryTextStyle(
                                          size: 11,
                                          color: appStore.isDarkMode
                                              ? Colors.white
                                              : appTextSecondaryColor),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ).onTap(() async {
                              if (widget.serviceData.providerId !=
                                  appStore.userId.validate()) {
                                await ProviderInfoScreen(
                                        providerId: widget
                                            .serviceData.providerId
                                            .validate())
                                    .launch(context);
                                setStatusBarColor(Colors.transparent);
                              }
                            }),
                          ),
                          6.width,
                          PriceWidget(
                            price: widget.serviceData.price.validate(),
                            isHourlyService: widget.serviceData.isHourlyService,
                            size: 14,
                            isFreeService: widget.serviceData.type.validate() ==
                                SERVICE_TYPE_FREE,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      });
    }

    return GestureDetector(
      onTap: () {
        hideKeyboard(context);
        ServiceDetailScreen(
          serviceId: widget.isFavouriteService
              ? widget.serviceData.serviceId.validate().toInt()
              : widget.serviceData.id.validate(),
        ).launch(context).then((value) {
          setStatusBarColor(context.primaryColor);
          widget.onUpdate?.call();
        });
      },
      child: buildServiceComponent(),
    );
  }
}
