import 'package:booking_system_flutter/component/disabled_rating_bar_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class FilterRatingComponent extends StatefulWidget {
  @override
  State<FilterRatingComponent> createState() => _FilterRatingComponentState();
}

class _FilterRatingComponentState extends State<FilterRatingComponent> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(5, (i) {
        int index = 4 - i; // reversed: 5 stars first
        bool isSelected = filterStore.ratingId.contains(index + 1);

        return AnimatedContainer(
          duration: Duration(milliseconds: 200),
          margin: EdgeInsets.only(bottom: 10),
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              DisabledRatingBarWidget(rating: (index + 1).toDouble(), size: 20)
                  .expand(),
              12.width,
              Text('${(index + 1)}', style: boldTextStyle(size: 14)),
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
          int selectedIndex = index + 1;

          if (!filterStore.ratingId.contains(selectedIndex)) {
            filterStore.ratingId.add(selectedIndex);
          } else {
            filterStore.ratingId
                .removeWhere((element) => element == selectedIndex);
          }
          setState(() {});
        });
      }),
    );
  }
}
