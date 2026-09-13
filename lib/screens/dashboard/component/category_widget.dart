import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/category_model.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../newDashboard/dashboard_3/component/category_dashboard_component_3.dart';
import '../../newDashboard/dashboard_4/component/category_dashboard_component_4.dart';

class CategoryWidget extends StatelessWidget {
  final CategoryData categoryData;
  final double? width;
  final bool? isFromCategory;
  final bool isRectangle;

  CategoryWidget({
    required this.categoryData,
    this.width,
    this.isFromCategory,
    this.isRectangle = false,
  });

  Widget buildDefaultComponent(BuildContext context) {
    final double cardWidth = width ?? context.width() / 4 - 20;
    final double boxSize = cardWidth * 0.82;
    final double iconSize = boxSize * 0.50;

    final Color iconColor = appStore.isDarkMode
        ? Colors.white
        : categoryData.color.validate(value: '4285F4').toColor();

    final Widget iconWidget = categoryData.categoryImage.validate().endsWith('.svg')
        ? SvgPicture.network(
            categoryData.categoryImage.validate(),
            height: iconSize,
            width: iconSize,
            color: iconColor,
            placeholderBuilder: (_) => PlaceHolderWidget(
              height: iconSize,
              width: iconSize,
              color: transparentColor,
            ),
          )
        : CachedImageWidget(
            url: categoryData.categoryImage.validate(),
            fit: BoxFit.contain,
            width: iconSize,
            height: iconSize,
            placeHolderImage: '',
          );

    return SizedBox(
      width: cardWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon box
          Container(
            width: boxSize,
            height: boxSize,
            decoration: BoxDecoration(
              color: appStore.isDarkMode
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.white,
              borderRadius: radius(18),
              border: Border.all(
                color: appStore.isDarkMode
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.grey.shade200,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                      alpha: appStore.isDarkMode ? 0.22 : 0.09),
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(child: iconWidget),
          ),

          10.height,

          // Name
          Text(
            categoryData.name.validate(),
            style: boldTextStyle(size: 11),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget categoryComponent() {
      return Observer(builder: (context) {
        if (appConfigurationStore.userDashboardType == DASHBOARD_1) {
          return buildDefaultComponent(context);
        } else if (appConfigurationStore.userDashboardType == DASHBOARD_2) {
          return buildDefaultComponent(context);
        } else if (appConfigurationStore.userDashboardType == DASHBOARD_3) {
          return CategoryDashboardComponent3(
              categoryData: categoryData, width: context.width() / 4 - 20);
        } else if (appConfigurationStore.userDashboardType == DASHBOARD_4) {
          return CategoryDashboardComponent4(categoryData: categoryData);
        } else {
          return buildDefaultComponent(context);
        }
      });
    }

    return categoryComponent();
  }
}
