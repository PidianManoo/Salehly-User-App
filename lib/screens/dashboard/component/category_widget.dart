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
    final double boxSize = cardWidth * 0.86;
    // The icon backdrop — a soft gradient circle tinted with the category's
    // own color — gives the icon a "designed" home to sit in instead of
    // floating in a mostly-empty white square.
    final double backdropSize = boxSize * 0.82;
    // Sized relative to the backdrop so the artwork reads clearly instead
    // of looking small and adrift inside its card.
    final double iconSize = backdropSize * 0.74;

    final Color tintColor =
        categoryData.color.validate(value: '4285F4').toColor();

    final Widget iconWidget =
        categoryData.categoryImage.validate().endsWith('.svg')
            ? SvgPicture.network(
                categoryData.categoryImage.validate(),
                height: iconSize,
                width: iconSize,
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
              borderRadius: radius(20),
              border: Border.all(
                color: appStore.isDarkMode
                    ? Colors.white.withValues(alpha: 0.10)
                    : tintColor.withValues(alpha: 0.12),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: appStore.isDarkMode
                      ? Colors.black.withValues(alpha: 0.28)
                      : tintColor.withValues(alpha: 0.18),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: SizedBox(
                width: backdropSize,
                height: backdropSize,
                child: Center(child: iconWidget),
              ),
            ),
          ),

          12.height,

          // Name
          Text(
            categoryData.name.validate(),
            style: boldTextStyle(
              size: 12,
              letterSpacing: 0.1,
              color: appStore.isDarkMode ? Colors.white : Colors.black87,
            ),
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
