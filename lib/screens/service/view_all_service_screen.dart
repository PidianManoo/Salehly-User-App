import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/screens/booking/provider_info_screen.dart';
import 'package:booking_system_flutter/screens/service/shimmer/view_all_service_shimmer.dart';
import 'package:booking_system_flutter/store/filter_store.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:booking_system_flutter/utils/custom_app_field.dart';

import '../../component/cached_image_widget.dart';
import '../../component/empty_error_state_widget.dart';
import '../../component/image_border_component.dart';
import '../../main.dart';
import '../../model/category_model.dart';
import '../../model/service_data_model.dart';
import '../../model/shop_list_model.dart';
import '../../network/rest_apis.dart';
import '../../utils/colors.dart';
import '../../utils/common.dart';
import '../../utils/constant.dart';
import '../../utils/images.dart';
import '../blog/shimmer/blog_shimmer.dart';
import '../filter/filter_screen.dart';
import '../shop/shop_detail_screen.dart';
import 'component/service_component.dart';

class ViewAllServiceScreen extends StatefulWidget {
  final int? categoryId;
  final String? categoryName;
  final String isFeatured;
  final bool isFromProvider;
  final bool isFromCategory;
  final int? providerId;

  ViewAllServiceScreen({
    this.categoryId,
    this.categoryName = '',
    this.isFeatured = '',
    this.isFromProvider = true,
    this.isFromCategory = false,
    this.providerId,
    Key? key,
  }) : super(key: key);

  @override
  State<ViewAllServiceScreen> createState() => _ViewAllServiceScreenState();
}

class _ViewAllServiceScreenState extends State<ViewAllServiceScreen> {
  Future<List<CategoryData>>? futureCategory;
  List<CategoryData> categoryList = [];

  Future<List<ServiceData>>? futureService;
  List<ServiceData> serviceList = [];

  FocusNode myFocusNode = FocusNode();
  TextEditingController searchCont = TextEditingController();

  int? subCategory;

  int page = 1;
  int shopPage = 1;
  bool isLastPage = false;
  bool isLastPageShop = false;
  bool isService = true;

  Future<List<ShopListData>>? future;
  List<ShopListData> shopList = [];

  @override
  void initState() {
    super.initState();
    init();
    filterStore = FilterStore();
  }

  void init() async {
    fetchAllServiceData();
    await fetchShopList();

    if (widget.categoryId != null) {
      fetchCategoryList();
    }
  }

  fetchShopList() async {
    future = getShopList(
      shopListData: shopList,
      page: shopPage,
      search: searchCont.text,
      categoryId: widget.categoryId != null
          ? widget.categoryId.validate().toString()
          : filterStore.categoryId.join(','),
      providerId: widget.providerId != null
          ? widget.providerId.toString()
          : filterStore.providerId.join(","),
      latitude: filterStore.latitude,
      longitude: filterStore.longitude,
      lastPageCallback: (b) {
        isLastPageShop = b;
      },
    );
    setState(() {});

    // shopList is only mutated once this future resolves — rebuild again
    // then so anything reading its length directly (e.g. the result count)
    // doesn't stay stale until some unrelated tap forces another build.
    try {
      await future;
    } catch (_) {}
    setState(() {});
  }

  void fetchCategoryList() async {
    futureCategory = getSubCategoryListAPI(
      catId: widget.categoryId!,
    );
    setState(() {});
  }

  void fetchAllServiceData() async {
    futureService = searchServiceAPI(
      page: page,
      list: serviceList,
      categoryId: widget.categoryId != null
          ? widget.categoryId.validate().toString()
          : filterStore.categoryId.join(','),
      subCategory: subCategory != null ? subCategory.validate().toString() : '',
      providerId: widget.providerId != null
          ? widget.providerId.toString()
          : filterStore.providerId.join(","),
      isPriceMin: filterStore.isPriceMin,
      isPriceMax: filterStore.isPriceMax,
      ratingId: filterStore.ratingId.join(','),
      search: searchCont.text,
      latitude: appStore.isCurrentLocation
          ? getDoubleAsync(LATITUDE).toString()
          : filterStore.latitude.isNotEmpty
              ? filterStore.latitude
              : "",
      longitude: appStore.isCurrentLocation
          ? getDoubleAsync(LONGITUDE).toString()
          : filterStore.longitude.isNotEmpty
              ? filterStore.longitude
              : "",
      lastPageCallBack: (p0) {
        isLastPage = p0;
      },
      isFeatured: widget.isFeatured,
    );

    setState(() {});

    // serviceList is only mutated once this future resolves — rebuild again
    // then so anything reading its length directly (e.g. the result count)
    // doesn't stay stale until some unrelated tap forces another build.
    try {
      await futureService;
    } catch (_) {}
    setState(() {});
  }

  String get setSearchString {
    if (!widget.categoryName.isEmptyOrNull) {
      return widget.categoryName!;
    } else if (widget.isFeatured == "1") {
      return language.lblFeatured;
    } else {
      return language.allServices;
    }
  }

  Widget subCategoryWidget() {
    return SnapHelperWidget<List<CategoryData>>(
      future: futureCategory,
      initialData: cachedSubcategoryList
          .firstWhere((element) => element?.$1 == widget.categoryId.validate(),
              orElse: () => null)
          ?.$2,
      loadingWidget: Offstage(),
      onSuccess: (list) {
        if (list.length == 1) return Offstage();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            10.height,
            Text(language.lblSubcategories, style: boldTextStyle(size: 13))
                .paddingLeft(16),
            8.height,
            HorizontalList(
              itemCount: list.validate().length,
              padding: EdgeInsets.only(left: 16, right: 16),
              runSpacing: 8,
              spacing: 8,
              itemBuilder: (_, index) {
                CategoryData data = list[index];

                return Observer(
                  builder: (_) {
                    bool isSelected =
                        filterStore.selectedSubCategoryId == index;

                    Widget iconSlot;
                    if (index == 0) {
                      iconSlot = Icon(Icons.apps_rounded,
                          size: 14,
                          color:
                              isSelected ? Colors.white : context.primaryColor);
                    } else if (data.categoryImage.validate().endsWith('.svg')) {
                      iconSlot = SvgPicture.network(
                        data.categoryImage.validate(),
                        height: 14,
                        width: 14,
                        color: isSelected
                            ? Colors.white
                            : (appStore.isDarkMode
                                ? Colors.white
                                : data.color.validate(value: '000').toColor()),
                        placeholderBuilder: (context) => PlaceHolderWidget(
                            height: 14, width: 14, color: transparentColor),
                      );
                    } else {
                      iconSlot = CachedImageWidget(
                        url: data.categoryImage.validate(),
                        fit: BoxFit.cover,
                        width: 14,
                        height: 14,
                        circle: true,
                      );
                    }

                    return GestureDetector(
                      onTap: () {
                        filterStore.setSelectedSubCategory(catId: index);

                        subCategory = data.id;
                        page = 1;

                        appStore.setLoading(true);
                        fetchAllServiceData();

                        setState(() {});
                      },
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        padding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? context.primaryColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? context.primaryColor
                                : context.dividerColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: 13, width: 13, child: iconSlot),
                            6.width,
                            Text(
                              index == 0
                                  ? language.lblViewAll
                                  : data.name.validate(),
                              style: boldTextStyle(
                                size: 12,
                                color: isSelected
                                    ? Colors.white
                                    : (appStore.isDarkMode
                                        ? Colors.white
                                        : appTextPrimaryColor),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            10.height,
          ],
        );
      },
    );
  }

  Widget shopListWidget() {
    return SnapHelperWidget<List<ShopListData>>(
      initialData: cachedShopList,
      future: future,
      loadingWidget: BlogShimmer(),
      errorBuilder: (error) {
        return NoDataWidget(
          title: error,
          imageWidget: ErrorStateWidget(),
          retryText: language.reload,
          onRetry: () {
            shopPage = 1;
            appStore.setLoading(true);

            fetchShopList();
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
              title: language.noShopFound, imageWidget: EmptyStateWidget()),
          shrinkWrap: true,
          onNextPage: () {
            if (!isLastPageShop) {
              shopPage++;
              appStore.setLoading(true);
              fetchShopList();
              setState(() {});
            }
          },
          onSwipeRefresh: () async {
            shopPage = 1;

            fetchShopList();
            setState(() {});

            return await 2.seconds.delay;
          },
          disposeScrollController: true,
          itemBuilder: (BuildContext context, index) {
            var shopData = snap[index];
            final String thumbnailUrl =
                shopData.shopAttachment.validate().isNotEmpty
                    ? shopData.shopAttachment!.first.url.validate()
                    : '';

            // Same compact horizontal-row card language as ServiceComponent,
            // so Services and Shops read as one consistent list style.
            return GestureDetector(
              onTap: () {
                ProviderInfoScreen(providerId: shopData.id.validate())
                    .launch(context);
              },
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 8),
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
                    CachedImageWidget(
                      url: thumbnailUrl,
                      height: 88,
                      width: 88,
                      fit: BoxFit.cover,
                      radius: 13,
                    ),
                    10.width,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shopData.name.validate(),
                            style: boldTextStyle(size: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (shopData.location.validate().isNotEmpty) ...[
                            4.height,
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 13, color: appTextSecondaryColor),
                                3.width,
                                Flexible(
                                  child: Text(
                                    shopData.location.validate(),
                                    style: secondaryTextStyle(size: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          7.height,
                          Row(
                            children: [
                              ImageBorder(
                                  src: shopData.profileImage.validate(),
                                  height: 18),
                              5.width,
                              if (shopData.providerName.validate().isNotEmpty)
                                Flexible(
                                  child: Text(
                                    shopData.providerName.validate(),
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
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool get _hasActiveFilters =>
      filterStore.categoryId.isNotEmpty ||
      filterStore.providerId.isNotEmpty ||
      filterStore.ratingId.isNotEmpty ||
      filterStore.isPriceMin.isNotEmpty ||
      filterStore.isPriceMax.isNotEmpty ||
      (filterStore.latitude.isNotEmpty && filterStore.longitude.isNotEmpty);

  Widget _segmentButton({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [
                    context.primaryColor,
                    context.primaryColor.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: context.primaryColor.withValues(alpha: 0.32),
                    blurRadius: 14,
                    offset: Offset(0, 5),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected
                  ? Colors.white
                  : (appStore.isDarkMode
                      ? Colors.white70
                      : appTextSecondaryColor),
            ),
            7.width,
            Text(
              label,
              style: boldTextStyle(
                size: LABEL_TEXT_SIZE,
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
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    filterStore.clearFilters();
    myFocusNode.dispose();
    filterStore.setSelectedSubCategory(catId: 0);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => hideKeyboard(context),
      child: AppScaffold(
        appBarTitle: setSearchString,
        child: SizedBox(
          height: context.height(),
          width: context.width(),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CustomAppTextField(
                        textFieldType: TextFieldType.OTHER,
                        focus: myFocusNode,
                        controller: searchCont,
                        suffix: CloseButton(
                          onPressed: () {
                            page = 1;
                            shopPage = 1;
                            searchCont.clear();
                            filterStore.setSearch('');
                            appStore.setLoading(true);
                            fetchAllServiceData();
                            fetchShopList();
                            setState(() {});
                          },
                        ).visible(searchCont.text.isNotEmpty),
                        onFieldSubmitted: (s) {
                          page = 1;
                          shopPage = 1;

                          filterStore.setSearch(s);
                          appStore.setLoading(true);

                          fetchAllServiceData();
                          fetchShopList();
                          setState(() {});
                        },
                        decoration:
                            inputDecoration(context, borderRadius: 16).copyWith(
                          hintText: "${language.lblSearchFor} $setSearchString",
                          prefixIcon:
                              ic_search.iconImage(size: 10).paddingAll(14),
                          hintStyle: secondaryTextStyle(),
                        ),
                      ),
                    ).expand(),
                    14.width,
                    Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            context.primaryColor,
                            context.primaryColor.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: context.primaryColor.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CachedImageWidget(
                            url: ic_filter,
                            height: 22,
                            width: 22,
                            color: Colors.white,
                          ),
                          if (_hasActiveFilters)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.amber,
                                  border: Border.all(
                                      color: Colors.white, width: 1.4),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ).onTap(() {
                      hideKeyboard(context);

                      FilterScreen(
                              isFromProvider: widget.isFromProvider,
                              isFromCategory: widget.isFromCategory)
                          .launch(context)
                          .then((value) {
                        if (value != null) {
                          page = 1;
                          shopPage = 1;
                          appStore.setLoading(true);
                          isService = true;
                          fetchAllServiceData();
                          fetchShopList();
                          setState(() {});
                        }
                      });
                    }, borderRadius: radius(16))
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.dividerColor),
                  boxShadow: appStore.isDarkMode
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    _segmentButton(
                      icon: Icons.room_service_outlined,
                      label: language.service,
                      selected: isService,
                      onTap: () => setState(() => isService = true),
                    ).expand(),
                    8.width,
                    _segmentButton(
                      icon: Icons.storefront_outlined,
                      label: language.lblShops,
                      selected: !isService,
                      onTap: () => setState(() => isService = false),
                    ).expand(),
                  ],
                ),
              ),
              if (!appStore.isLoading)
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isService
                            ? '${serviceList.length} ${language.service}'
                            : '${shopList.length} ${language.lblShops}',
                        style: secondaryTextStyle(size: 13),
                      ),
                      if (_hasActiveFilters)
                        GestureDetector(
                          onTap: () {
                            filterStore.clearFilters();
                            page = 1;
                            shopPage = 1;
                            appStore.setLoading(true);
                            fetchAllServiceData();
                            fetchShopList();
                            setState(() {});
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  context.primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: context.primaryColor
                                      .withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.close,
                                    size: 13, color: context.primaryColor),
                                6.width,
                                Text(language.lblClearFilter,
                                    style: boldTextStyle(
                                        size: 12, color: context.primaryColor)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              isService
                  ? AnimatedScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      listAnimationType: ListAnimationType.FadeIn,
                      physics: AlwaysScrollableScrollPhysics(),
                      onSwipeRefresh: () {
                        page = 1;

                        appStore.setLoading(true);
                        fetchAllServiceData();
                        setState(() {});

                        return Future.value(false);
                      },
                      onNextPage: () {
                        if (!isLastPage) {
                          page++;

                          appStore.setLoading(true);
                          fetchAllServiceData();
                          setState(() {});
                        }
                      },
                      children: [
                        if (widget.categoryId != null) subCategoryWidget(),
                        8.height,
                        SnapHelperWidget(
                          future: futureService,
                          loadingWidget: ViewAllServiceShimmer(),
                          errorBuilder: (p0) {
                            return NoDataWidget(
                              title: p0,
                              retryText: language.reload,
                              imageWidget: ErrorStateWidget(),
                              onRetry: () {
                                page = 1;
                                appStore.setLoading(true);

                                fetchAllServiceData();
                                setState(() {});
                              },
                            );
                          },
                          onSuccess: (data) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Text(language.service, style: boldTextStyle(size: LABEL_TEXT_SIZE)).paddingSymmetric(horizontal: 16),
                                AnimatedListView(
                                  itemCount: serviceList.length,
                                  listAnimationType: ListAnimationType.FadeIn,
                                  fadeInConfiguration:
                                      FadeInConfiguration(duration: 2.seconds),
                                  physics: NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  emptyWidget: NoDataWidget(
                                    title: language.lblNoServicesFound,
                                    subTitle: (searchCont.text.isNotEmpty ||
                                            filterStore.providerId.isNotEmpty ||
                                            filterStore.categoryId.isNotEmpty)
                                        ? language.noDataFoundInFilter
                                        : null,
                                    imageWidget: EmptyStateWidget(),
                                  ),
                                  itemBuilder: (_, index) {
                                    return ServiceComponent(
                                      serviceData: serviceList[index],
                                      isFromViewAllService: true,
                                    ).paddingAll(8);
                                  },
                                ).paddingAll(8),
                              ],
                            );
                          },
                        ),
                      ],
                    ).expand()
                  : shopListWidget().expand(),
            ],
          ),
        ),
      ),
    );
  }
}
