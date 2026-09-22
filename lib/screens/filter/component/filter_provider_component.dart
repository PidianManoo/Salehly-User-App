import 'package:booking_system_flutter/component/image_border_component.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/empty_error_state_widget.dart';

class FilterProviderComponent extends StatefulWidget {
  final List<UserData> providerList;

  FilterProviderComponent({required this.providerList});

  @override
  State<FilterProviderComponent> createState() =>
      _FilterProviderComponentState();
}

class _FilterProviderComponentState extends State<FilterProviderComponent> {
  @override
  Widget build(BuildContext context) {
    if (widget.providerList.isEmpty) {
      return NoDataWidget(
        title: language.noProviderFound,
        imageWidget: EmptyStateWidget(),
      );
    }

    return AnimatedListView(
      slideConfiguration: sliderConfigurationGlobal,
      itemCount: widget.providerList.length,
      listAnimationType: ListAnimationType.FadeIn,
      fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        UserData data = widget.providerList[index];
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
              ImageBorder(
                src: data.profileImage.validate(),
                height: 46,
              ),
              12.width,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(data.displayName.validate(),
                              style: boldTextStyle(size: 14))
                          .flexible(),
                      4.width,
                      Image.asset(
                        ic_star_fill,
                        color: getRatingBarColor(
                            data.providersServiceRating.validate().toInt(),
                            showRedForZeroRating: true),
                        height: 12,
                      ),
                    ],
                  ),
                  3.height,
                  if (data.totalBooking.validate() != 0)
                    Text(
                        '${language.basedOn} ${data.totalBooking} ${language.services}',
                        style: secondaryTextStyle(size: 12)),
                  Text(
                    '${language.lblMemberSince} ${DateFormat(YEAR).format(DateTime.parse(data.createdAt.validate()))}',
                    style: secondaryTextStyle(size: 11),
                  ),
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
