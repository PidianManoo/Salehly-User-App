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
            16.height,
            Text(language.lblSubcategories,
                    style: boldTextStyle(size: LABEL_TEXT_SIZE))
                .paddingLeft(16),
            HorizontalList(
              itemCount: list.validate().length,
              padding: EdgeInsets.only(left: 16, right: 16),
              runSpacing: 8,
              spacing: 12,
              itemBuilder: (_, index) {
                CategoryData data = list[index];

                return Observer(
                  builder: (_) {
                    bool isSelected =
                        filterStore.selectedSubCategoryId == index;

                    return GestureDetector(
                      onTap: () {
                        filterStore.setSelectedSubCategory(catId: index);

                        subCategory = data.id;
                        page = 1;

                        appStore.setLoading(true);
                        fetchAllServiceData();

                        setState(() {});
                      },
                      child: SizedBox(
                        width: context.width() / 4 - 20,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Column(
                              children: [
                                16.height,
                                if (index == 0)
                                  Container(
                                    height: CATEGORY_ICON_SIZE,
                                    width: CATEGORY_ICON_SIZE,
                                    decoration: BoxDecoration(
                                        color: context.cardColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: grey)),
                                    alignment: Alignment.center,
                                    child: Text(data.name.validate(),
                                        style: boldTextStyle(size: 12)),
                                  ),
                                if (index != 0)
                                  data.categoryImage.validate().endsWith('.svg')
                                      ? Container(
                                          width: CATEGORY_ICON_SIZE,
                                          height: CATEGORY_ICON_SIZE,
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                              color: context.cardColor,
                                              shape: BoxShape.circle),
                                          child: SvgPicture.network(
                                            data.categoryImage.validate(),
                                            height: CATEGORY_ICON_SIZE,
                                            width: CATEGORY_ICON_SIZE,
                                            color: appStore.isDarkMode
                                                ? Colors.white
                                                : data.color
                                                    .validate(value: '000')
                                                    .toColor(),
                                            placeholderBuilder: (context) =>
                                                PlaceHolderWidget(
                                                    height: CATEGORY_ICON_SIZE,
                                                    width: CATEGORY_ICON_SIZE,
                                                    color: transparentColor),
                                          ),
                                        )
                                      : Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                              color: context.cardColor,
                                              shape: BoxShape.circle),
                                          child: CachedImageWidget(
                                            url: data.categoryImage.validate(),
                                            fit: BoxFit.fitWidth,
                                            width: SUBCATEGORY_ICON_SIZE,
                                            height: SUBCATEGORY_ICON_SIZE,
                                            circle: true,
                                          ),
                                        ),
                                4.height,
                                if (index == 0)
                                  Text(language.lblViewAll,
                                      style: boldTextStyle(size: 12),
                                      textAlign: TextAlign.center,
                                      maxLines: 1),
                                if (index != 0)
                                  Marquee(
                                      child: Text('${data.name.validate()}',
                                          style: boldTextStyle(size: 12),
                                          textAlign: TextAlign.center,
                                          maxLines: 1)),
                              ],
                            ),
                            Positioned(
                              top: 14,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.all(2),
                                decoration: boxDecorationDefault(
                                    color: context.primaryColor),
                                child: Icon(Icons.done,
                                    size: 16, color: Colors.white),
                              ).visible(isSelected),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            16.height,
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
            return GestureDetector(
              onTap: () {
                //ShopDetailScreen(shopId: shopData.id.validate()).launch(context);
                ProviderInfoScreen(providerId: shopData.id.validate())
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
                                      url: shopData.shopAttachment![index].url!
                                              .isNotEmpty
                                          ? shopData.shopAttachment![index].url
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
                            directionMarguee: DirectionMarguee.oneDirection,
                            child: Text(shopData.name.validate(),
                                    style: boldTextStyle())
                                .paddingSymmetric(horizontal: 0))
                        .paddingSymmetric(horizontal: 12),
                    6.height,
                    Row(
                      children: [
                        ImageBorder(
                            src: shopData.profileImage.validate(), height: 30),
                        8.width,
                        // if (widget.serviceData.providerName.validate().isNotEmpty)
                        Text(
                          shopData.providerName.validate(),
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
              ),
            );
            // BlogItemComponent(blogData: snap[index]);
          },
        );
      },
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
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    CustomAppTextField(
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
                      decoration: inputDecoration(context).copyWith(
                        hintText: "${language.lblSearchFor} $setSearchString",
                        prefixIcon:
                            ic_search.iconImage(size: 10).paddingAll(14),
                        hintStyle: secondaryTextStyle(),
                      ),
                    ).expand(),
                    16.width,
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration:
                          boxDecorationDefault(color: context.primaryColor),
                      child: CachedImageWidget(
                        url: ic_filter,
                        height: 26,
                        width: 26,
                        color: Colors.white,
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
                    }, borderRadius: radius())
                  ],
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        isService = true;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      alignment: Alignment.center,
                      decoration: boxDecorationDefault(
                        color: isService
                            ? context.primaryColor
                            : context.cardColor,
                      ),
                      child: Text(language.service,
                              style: boldTextStyle(
                                  size: LABEL_TEXT_SIZE,
                                  color: isService
                                      ? white
                                      : appStore.isDarkMode
                                          ? white
                                          : black))
                          .paddingSymmetric(horizontal: 16),
                    ),
                  ).expand(),
                  12.width,
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        isService = false;
                      });
                    },
                    child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        alignment: Alignment.center,
                        decoration: boxDecorationDefault(
                          color: !isService
                              ? context.primaryColor
                              : context.cardColor,
                        ),
                        child: Text(language.lblShops,
                                style: boldTextStyle(
                                    size: LABEL_TEXT_SIZE,
                                    color: isService
                                        ? appStore.isDarkMode
                                            ? white
                                            : black
                                        : white))
                            .paddingSymmetric(horizontal: 16)),
                  ).expand(),
                ],
              ).paddingSymmetric(horizontal: 16, vertical: 8),
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
                        16.height,
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
