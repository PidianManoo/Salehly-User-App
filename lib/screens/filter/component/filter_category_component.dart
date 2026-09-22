import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/category_model.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/empty_error_state_widget.dart';
import '../../../component/image_border_component.dart';

class FilterCategoryComponent extends StatefulWidget {
  final List<CategoryData> catList;

  FilterCategoryComponent({required this.catList});

  @override
  State<FilterCategoryComponent> createState() =>
      _FilterCategoryComponentState();
}

class _FilterCategoryComponentState extends State<FilterCategoryComponent> {
  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    //
  }

  @override
  Widget build(BuildContext context) {
    if (widget.catList.isEmpty) {
      return NoDataWidget(
        title: language.noCategoryFound,
        imageWidget: EmptyStateWidget(),
      );
    }

    return AnimatedListView(
      itemCount: widget.catList.length,
      slideConfiguration: sliderConfigurationGlobal,
      listAnimationType: ListAnimationType.FadeIn,
      fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        CategoryData data = widget.catList[index];
        final bool isSelected = data.isSelected;

        return AnimatedContainer(
          duration: Duration(milliseconds: 200),
          margin: EdgeInsets.only(bottom: 10),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? context.primaryColor.withValues(alpha: 0.06)
                : context.cardColor,
            borderRadius: radius(14),
            border: Border.all(
              color: isSelected
                  ? context.primaryColor
                  : context.dividerColor.withValues(alpha: 0.5),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: ImageBorder(
                  src: data.categoryImage.validate(),
                  height: 32,
                ),
              ),
              12.width,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.name.validate(), style: boldTextStyle(size: 14)),
                  3.height,
                  Text('${data.services} ${language.service}',
                      style: secondaryTextStyle(size: 12)),
                ],
              ).expand(),
              10.width,
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? context.primaryColor : Colors.transparent,
                  border: Border.all(
                      color: isSelected
                          ? context.primaryColor
                          : context.dividerColor,
                      width: 2),
                ),
                child: isSelected
                    ? Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            ],
          ),
        ).onTap(() {
          data.isSelected = !data.isSelected;
          setState(() {});
        });
      },
    );
  }
}
