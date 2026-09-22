import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/category_model.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/filter/component/filter_category_component.dart';
import 'package:booking_system_flutter/screens/filter/component/filter_price_component.dart';
import 'package:booking_system_flutter/screens/filter/component/filter_provider_component.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../utils/colors.dart';
import '../../utils/constant.dart';
import 'component/filter_location_component.dart';
import 'component/filter_rating_component.dart';

class _FilterTab {
  final IconData icon;
  final String label;
  final Widget content;

  _FilterTab({required this.icon, required this.label, required this.content});
}

class FilterScreen extends StatefulWidget {
  final bool isFromProvider;
  final bool isFromCategory;

  FilterScreen({this.isFromProvider = true, this.isFromCategory = false});

  @override
  _FilterScreenState createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  int isSelected = 0;

  List<CategoryData> catList = [];
  List<UserData> providerList = [];

  num? minPrice;
  num? maxPrice;

  @override
  void initState() {
    super.initState();
    appStore.setLoading(true);
    afterBuildCreated(() => init());
  }

  void init() async {
    //Get all Provider List
    if (widget.isFromProvider) {
      await getProvider(type: FILTER_PROVIDER).then((value) {
        minPrice = value.min;
        maxPrice = value.max;

        appStore.setLoading(false);

        providerList = value.providerList.validate();
        providerList.forEach((element) {
          if (filterStore.providerId.contains(element.id)) {
            element.isSelected = true;
          }
        });
        setState(() {});
      }).catchError((e) {
        appStore.setLoading(false);

        toast(e.toString());
      });
    }

    // Get all Category List
    if (!widget.isFromCategory) {
      await getCategoryList(CATEGORY_LIST_ALL).then((value) {
        catList = value.categoryList.validate();
        catList.forEach((element) {
          if (filterStore.categoryId.contains(element.id)) {
            element.isSelected = true;
          }
        });
        setState(() {});
      }).catchError((e) {
        toast(e.toString());
      });
    }

    appStore.setLoading(false);
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  void clearFilter() {
    filterStore.clearFilters();
    finish(context, true);
  }

  List<_FilterTab> get _tabs {
    return [
      if (widget.isFromProvider)
        _FilterTab(
          icon: Icons.storefront_outlined,
          label: language.textProvider,
          content: FilterProviderComponent(providerList: providerList),
        ),
      if (!widget.isFromCategory)
        _FilterTab(
          icon: Icons.category_outlined,
          label: language.lblCategory,
          content: FilterCategoryComponent(catList: catList),
        ),
      _FilterTab(
        icon: Icons.sell_outlined,
        label: language.lblPrice,
        content: FilterPriceComponent(
            min: minPrice.validate(), max: maxPrice.validate()),
      ),
      _FilterTab(
        icon: Icons.star_outline_rounded,
        label: language.lblRating,
        content: FilterRatingComponent(),
      ),
      _FilterTab(
        icon: Icons.location_on_outlined,
        label: language.lblLocation,
        content: FilterLocationComponent(),
      ),
    ];
  }

  bool get _hasActiveFilters =>
      filterStore.providerId.validate().isNotEmpty ||
      filterStore.categoryId.validate().isNotEmpty ||
      (filterStore.isPriceMin.validate().isNotEmpty &&
          filterStore.isPriceMax.validate().isNotEmpty) ||
      filterStore.ratingId.validate().isNotEmpty ||
      (filterStore.latitude.validate().isNotEmpty &&
          filterStore.longitude.validate().isNotEmpty);

  Widget _tabChip(
      {required _FilterTab tab,
      required bool selected,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [
                    context.primaryColor,
                    context.primaryColor.withValues(alpha: 0.8)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : context.cardColor,
          borderRadius: radius(24),
          border: Border.all(
              color: selected ? Colors.transparent : context.dividerColor),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: context.primaryColor.withValues(alpha: 0.32),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tab.icon,
                size: 16,
                color: selected ? Colors.white : appTextSecondaryColor),
            6.width,
            Text(
              tab.label,
              style: boldTextStyle(
                size: 13,
                color: selected
                    ? Colors.white
                    : (appStore.isDarkMode
                        ? Colors.white70
                        : appTextSecondaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    final int safeIndex = isSelected < tabs.length ? isSelected : 0;

    return AppScaffold(
      appBarTitle: language.lblFilterBy,
      child: Column(
        children: [
          // ── Tab chip bar ──────────────────────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: context.scaffoldBackgroundColor,
              border: Border(bottom: BorderSide(color: context.dividerColor)),
            ),
            child: SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: tabs.length,
                separatorBuilder: (_, __) => 10.width,
                itemBuilder: (_, index) {
                  return _tabChip(
                    tab: tabs[index],
                    selected: index == safeIndex,
                    onTap: () {
                      if (!appStore.isLoading) {
                        isSelected = index;
                        setState(() {});
                      }
                    },
                  );
                },
              ),
            ),
          ),

          // ── Selected filter panel ────────────────────────────────────
          Expanded(
            child: appStore.isLoading
                ? Center(child: LoaderWidget())
                : AnimatedSwitcher(
                    duration: Duration(milliseconds: 220),
                    child: Padding(
                      key: ValueKey(safeIndex),
                      padding: EdgeInsets.all(16),
                      child: tabs[safeIndex].content,
                    ),
                  ),
          ),

          // ── Bottom action bar ────────────────────────────────────────
          Observer(
            builder: (_) => Container(
              decoration: BoxDecoration(
                color: context.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              width: context.width(),
              padding: EdgeInsets.fromLTRB(16, 14, 16, 20),
              child: Row(
                children: [
                  if (_hasActiveFilters)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: radius(14),
                        border: Border.all(color: context.primaryColor),
                      ),
                      child: AppButton(
                        text: language.lblClearFilter,
                        textColor: context.primaryColor,
                        color: Colors.transparent,
                        elevation: 0,
                        shapeBorder:
                            RoundedRectangleBorder(borderRadius: radius(14)),
                        onTap: () {
                          clearFilter();
                        },
                      ),
                    ).expand(),
                  16.width,
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: radius(14),
                      boxShadow: [
                        BoxShadow(
                          color: context.primaryColor.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: AppButton(
                      text: language.lblApply,
                      textColor: Colors.white,
                      color: context.primaryColor,
                      elevation: 0,
                      shapeBorder:
                          RoundedRectangleBorder(borderRadius: radius(14)),
                      onTap: () {
                        filterStore.categoryId = [];

                        catList.forEach((element) {
                          if (element.isSelected) {
                            filterStore.addToCategoryIdList(
                                prodId: element.id.validate());
                          }
                        });

                        filterStore.providerId = [];

                        providerList.forEach((element) {
                          if (element.isSelected) {
                            filterStore.addToProviderList(
                                prodId: element.id.validate());
                          }
                        });

                        finish(context, true);
                      },
                    ),
                  ).expand(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
