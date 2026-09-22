import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/city_list_model.dart';
import 'package:booking_system_flutter/model/country_list_model.dart';
import 'package:booking_system_flutter/model/login_model.dart';
import 'package:booking_system_flutter/model/state_list_model.dart';
import 'package:booking_system_flutter/network/network_utils.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/model_keys.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:booking_system_flutter/utils/custom_app_field.dart';

import '../../utils/configs.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  File? imageFile;
  XFile? pickedFile;

  List<CountryListResponse> countryList = [];
  List<StateListResponse> stateList = [];
  List<CityListResponse> cityList = [];

  CountryListResponse? selectedCountry;
  StateListResponse? selectedState;
  CityListResponse? selectedCity;

  TextEditingController fNameCont = TextEditingController();
  TextEditingController lNameCont = TextEditingController();
  TextEditingController emailCont = TextEditingController();
  TextEditingController userNameCont = TextEditingController();
  TextEditingController mobileCont = TextEditingController();
  TextEditingController addressCont = TextEditingController();

  FocusNode fNameFocus = FocusNode();
  FocusNode lNameFocus = FocusNode();
  FocusNode emailFocus = FocusNode();
  FocusNode userNameFocus = FocusNode();
  FocusNode mobileFocus = FocusNode();

  ValueNotifier _valueNotifier = ValueNotifier(true);

  int countryId = 0;
  int stateId = 0;
  int cityId = 0;

  Country selectedCountryCode = defaultCountry();

  bool isEmailVerified = getBoolAsync(IS_EMAIL_VERIFIED);

  bool showRefresh = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    afterBuildCreated(() {
      appStore.setLoading(true);
    });

    countryId = getIntAsync(COUNTRY_ID);
    stateId = getIntAsync(STATE_ID);
    cityId = getIntAsync(CITY_ID);

    fNameCont.text = appStore.userFirstName;
    lNameCont.text = appStore.userLastName;
    emailCont.text = appStore.userEmail;
    userNameCont.text = appStore.userName;
    mobileCont.text = appStore.userContactNumber.split("-").last;
    countryId = appStore.countryId;
    stateId = appStore.stateId;
    cityId = appStore.cityId;
    addressCont.text = appStore.address;
    // Look up the real country (with a valid ISO code) that matches the
    // saved dial code, instead of fabricating a Country with the phone
    // number in place of the country code — that broke the flag emoji,
    // which is derived from the country code.
    String savedPhoneCode = appStore.userContactNumber.split("-").first;
    selectedCountryCode =
        CountryService().findByPhoneCode(savedPhoneCode) ?? defaultCountry();

    userDetailAPI();

    if (getIntAsync(COUNTRY_ID) != 0) {
      await getCountry();

      setState(() {});
    } else {
      await getCountry();
    }
  }

  //region Logic
  String buildMobileNumber() {
    if (mobileCont.text.isEmpty) {
      return '';
    } else {
      return '${selectedCountryCode.phoneCode}-${mobileCont.text.trim()}';
    }
  }

  Future<void> userDetailAPI() async {
    await getUserDetail(appStore.userId).then((value) {
      isEmailVerified = value.emailVerified.validate().getBoolInt();
      setValue(IS_EMAIL_VERIFIED, isEmailVerified);
      setState(() {});
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString());
    });
  }

  Future<void> getCountry() async {
    await getCountryList().then((value) async {
      countryList.clear();
      countryList.addAll(value);

      if (value.any((element) => element.id == getIntAsync(COUNTRY_ID))) {
        selectedCountry = value
            .firstWhere((element) => element.id == getIntAsync(COUNTRY_ID));
      }

      setState(() {});
      await getStates(getIntAsync(COUNTRY_ID));
    }).catchError((e) {
      toast('$e', print: true);
    });
    appStore.setLoading(false);
  }

  Future<void> getStates(int countryId) async {
    appStore.setLoading(true);
    await getStateList({UserKeys.countryId: countryId}).then((value) async {
      stateList.clear();
      stateList.addAll(value);

      if (value.any((element) => element.id == getIntAsync(STATE_ID))) {
        selectedState =
            value.firstWhere((element) => element.id == getIntAsync(STATE_ID));
      }

      setState(() {});
      if (getIntAsync(STATE_ID) != 0) {
        await getCity(getIntAsync(STATE_ID));
      }
    }).catchError((e) {
      toast('$e', print: true);
    });
    appStore.setLoading(false);
  }

  Future<void> getCity(int stateId) async {
    appStore.setLoading(true);

    await getCityList({UserKeys.stateId: stateId}).then((value) async {
      cityList.clear();
      cityList.addAll(value);

      if (value.any((element) => element.id == getIntAsync(CITY_ID))) {
        selectedCity =
            value.firstWhere((element) => element.id == getIntAsync(CITY_ID));
      }

      setState(() {});
    }).catchError((e) {
      toast('$e', print: true);
    });
    appStore.setLoading(false);
  }

  Future<void> update() async {
    hideKeyboard(context);

    MultipartRequest multiPartRequest =
        await getMultiPartRequest('update-profile');
    multiPartRequest.fields[UserKeys.id] = appStore.userId.toString();
    multiPartRequest.fields[UserKeys.firstName] = fNameCont.text;
    multiPartRequest.fields[UserKeys.lastName] = lNameCont.text;
    multiPartRequest.fields[UserKeys.userName] = userNameCont.text;
    // multiPartRequest.fields[UserKeys.userType] = appStore.loginType;
    multiPartRequest.fields[UserKeys.contactNumber] = buildMobileNumber();
    multiPartRequest.fields[UserKeys.email] = emailCont.text;
    multiPartRequest.fields[UserKeys.countryId] = countryId.toString();
    multiPartRequest.fields[UserKeys.stateId] = stateId.toString();
    multiPartRequest.fields[UserKeys.cityId] = cityId.toString();
    multiPartRequest.fields[CommonKeys.address] = addressCont.text;
    multiPartRequest.fields[UserKeys.displayName] =
        '${fNameCont.text.validate() + " " + lNameCont.text.validate()}';
    if (imageFile != null) {
      multiPartRequest.files.add(
          await MultipartFile.fromPath(UserKeys.profileImage, imageFile!.path));
    }

    multiPartRequest.headers.addAll(buildHeaderTokens());
    appStore.setLoading(true);

    sendMultiPartRequest(
      multiPartRequest,
      onSuccess: (data) async {
        appStore.setLoading(false);
        if (data != null) {
          if ((data as String).isJson()) {
            LoginResponse res = LoginResponse.fromJson(jsonDecode(data));

            if (FirebaseAuth.instance.currentUser != null) {
              userService.updateDocument({
                'profile_image': res.userData!.profileImage.validate(),
                'updated_at': Timestamp.now().toDate().toString(),
              }, FirebaseAuth.instance.currentUser!.uid);
            }

            saveUserData(res.userData!);
            finish(context);
            toast(res.message.validate().capitalizeFirstLetter());
          }
        }
      },
      onError: (error) {
        toast(error.toString(), print: true);
        appStore.setLoading(false);
      },
    ).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    });
  }

  void _getFromGallery() async {
    pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (pickedFile != null) {
      imageFile = File(pickedFile!.path);
      setState(() {});
    }
  }

  _getFromCamera() async {
    pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (pickedFile != null) {
      imageFile = File(pickedFile!.path);
      setState(() {});
    }
  }

  Future<void> verifyEmail() async {
    appStore.setLoading(true);

    await verifyUserEmail(emailCont.text).then((value) async {
      isEmailVerified = value.isEmailVerified.validate().getBoolInt();

      toast(value.message);

      await setValue(IS_EMAIL_VERIFIED, isEmailVerified);
      setState(() {});
      appStore.setLoading(false);
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString());
    });
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      backgroundColor: context.cardColor,
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SettingItemWidget(
              title: language.lblGallery,
              leading: Icon(Icons.image, color: primaryColor),
              onTap: () {
                _getFromGallery();
                finish(context);
              },
            ),
            Divider(color: context.dividerColor),
            SettingItemWidget(
              title: language.camera,
              leading: Icon(Icons.camera, color: primaryColor),
              onTap: () {
                _getFromCamera();
                finish(context);
              },
            ),
          ],
        ).paddingAll(16.0);
      },
    );
  }

  Future<void> changeCountry() async {
    showCountryPicker(
      context: context,
      countryListTheme: CountryListThemeData(
        textStyle: secondaryTextStyle(color: textSecondaryColorGlobal),
        searchTextStyle: primaryTextStyle(),
        inputDecoration: InputDecoration(
          labelText: language.search,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: const Color(0xFF8C98A8).withValues(alpha: 0.2),
            ),
          ),
        ),
      ),

      showPhoneCode:
          true, // optional. Shows phone code before the country name.
      onSelect: (Country country) {
        selectedCountryCode = country;
        setState(() {});
      },
    );
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: context.primaryColor.withValues(alpha: 0.1),
            borderRadius: radius(8),
          ),
          child: Icon(icon, size: 15, color: context.primaryColor),
        ),
        8.width,
        Text(title, style: boldTextStyle(size: LABEL_TEXT_SIZE)),
      ],
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: context.width(),
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: radius(18),
        border: appStore.isDarkMode
            ? Border.all(color: context.dividerColor)
            : null,
        boxShadow: appStore.isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(icon, title),
          16.height,
          child,
        ],
      ),
    );
  }

  Widget _profileHeader() {
    return Container(
      width: context.width(),
      padding: EdgeInsets.fromLTRB(20, 28, 20, 26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.primaryColor.withValues(alpha: 0.14),
            context.primaryColor.withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: imageFile != null
                    ? Image.file(
                        imageFile!,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      ).cornerRadiusWithClipRRect(48)
                    : Observer(
                        builder: (_) => CachedImageWidget(
                          url: appStore.userProfileImage,
                          height: 96,
                          width: 96,
                          fit: BoxFit.cover,
                          radius: 48,
                        ),
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        primaryColor,
                        primaryColor.withValues(alpha: 0.85)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                        color: context.scaffoldBackgroundColor, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(AntDesign.camera, color: Colors.white, size: 14),
                ).onTap(() async {
                  _showBottomSheet(context);
                }),
              ).visible(!isLoginTypeGoogle && !isLoginTypeApple),
            ],
          ),
          16.height,
          AnimatedBuilder(
            animation: Listenable.merge([fNameCont, lNameCont]),
            builder: (_, __) {
              final fullName = '${fNameCont.text} ${lNameCont.text}'.trim();
              return Text(
                fullName.isEmpty ? language.editProfile : fullName,
                style: boldTextStyle(size: 18),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
          AnimatedBuilder(
            animation: userNameCont,
            builder: (_, __) => userNameCont.text.isEmpty
                ? const SizedBox()
                : Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '@${userNameCont.text}',
                      style: secondaryTextStyle(size: 12),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emailVerifyChip() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (isEmailVerified ? Colors.green : Colors.amber)
            .withValues(alpha: 0.12),
        borderRadius: radius(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isEmailVerified && !showRefresh)
            ic_pending.iconImage(color: Colors.amber, size: 13)
          else
            Icon(
              isEmailVerified ? Icons.check_circle : Icons.refresh,
              color: isEmailVerified ? Colors.green : Colors.grey,
              size: 14,
            ),
          5.width,
          Text(
            isEmailVerified ? language.verified : language.verifyEmail,
            style: boldTextStyle(
              size: 12,
              color: isEmailVerified ? Colors.green : Colors.amber.shade800,
            ),
          ),
        ],
      ),
    ).onTap(() {
      verifyEmail();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: language.editProfile,
      child: RefreshIndicator(
        onRefresh: () async {
          return await userDetailAPI();
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _profileHeader(),
                20.height,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _sectionCard(
                        icon: Icons.person_outline_rounded,
                        title: language.personalInfo,
                        child: Column(
                          children: [
                            CustomAppTextField(
                              textFieldType: TextFieldType.NAME,
                              controller: fNameCont,
                              focus: fNameFocus,
                              errorThisFieldRequired: language.requiredText,
                              nextFocus: lNameFocus,
                              enabled: !isLoginTypeApple,
                              decoration: inputDecoration(context,
                                      labelText: language.hintFirstNameTxt)
                                  .copyWith(
                                      fillColor:
                                          context.scaffoldBackgroundColor),
                              suffix: ic_profile2
                                  .iconImage(size: 10)
                                  .paddingAll(14),
                            ),
                            12.height,
                            CustomAppTextField(
                              textFieldType: TextFieldType.NAME,
                              controller: lNameCont,
                              focus: lNameFocus,
                              errorThisFieldRequired: language.requiredText,
                              nextFocus: userNameFocus,
                              enabled: !isLoginTypeApple,
                              decoration: inputDecoration(context,
                                      labelText: language.hintLastNameTxt)
                                  .copyWith(
                                      fillColor:
                                          context.scaffoldBackgroundColor),
                              suffix: ic_profile2
                                  .iconImage(size: 10)
                                  .paddingAll(14),
                            ),
                            12.height,
                            CustomAppTextField(
                              textFieldType: TextFieldType.NAME,
                              controller: userNameCont,
                              focus: userNameFocus,
                              enabled: false,
                              errorThisFieldRequired: language.requiredText,
                              nextFocus: emailFocus,
                              decoration: inputDecoration(context,
                                      labelText: language.hintUserNameTxt)
                                  .copyWith(
                                      fillColor:
                                          context.scaffoldBackgroundColor),
                              suffix: ic_profile2
                                  .iconImage(size: 10)
                                  .paddingAll(14),
                            ),
                            12.height,
                            CustomAppTextField(
                              textFieldType: TextFieldType.EMAIL_ENHANCED,
                              controller: emailCont,
                              focus: emailFocus,
                              nextFocus: mobileFocus,
                              errorThisFieldRequired: language.requiredText,
                              decoration: inputDecoration(context,
                                      labelText: language.hintEmailTxt)
                                  .copyWith(
                                      fillColor:
                                          context.scaffoldBackgroundColor),
                              suffix:
                                  ic_message.iconImage(size: 10).paddingAll(14),
                              autoFillHints: [AutofillHints.email],
                              onFieldSubmitted: (email) async {
                                if (emailCont.text.isNotEmpty)
                                  await verifyEmail();
                              },
                            ),
                            10.height,
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _emailVerifyChip(),
                            ),
                          ],
                        ),
                      ),
                      _sectionCard(
                        icon: Icons.call_outlined,
                        title: language.hintContactNumberTxt,
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Country code ...
                              Container(
                                height: 56.0,
                                decoration: BoxDecoration(
                                  color: context.scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(
                                      color: context.dividerColor, width: 1),
                                ),
                                child: Center(
                                  child: ValueListenableBuilder(
                                    valueListenable: _valueNotifier,
                                    builder: (context, value, child) => Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (selectedCountryCode
                                            .countryCode.isNotEmpty)
                                          Text(selectedCountryCode.flagEmoji,
                                              style:
                                                  primaryTextStyle(size: 18)),
                                        6.width,
                                        Text(
                                          "+${selectedCountryCode.phoneCode.replaceAll("+", "")}",
                                          style: boldTextStyle(size: 13),
                                        ),
                                        Icon(Icons.arrow_drop_down,
                                            color: context.iconColor),
                                      ],
                                    ).paddingSymmetric(horizontal: 10),
                                  ),
                                ),
                              ).onTap(() => changeCountry()),
                              10.width,
                              // Mobile number text field...
                              Expanded(
                                child: CustomAppTextField(
                                  textFieldType: isAndroid
                                      ? TextFieldType.PHONE
                                      : TextFieldType.NAME,
                                  controller: mobileCont,
                                  focus: mobileFocus,
                                  enabled: !isLoginTypeOTP,
                                  isValidationRequired: false,
                                  errorThisFieldRequired: language.requiredText,
                                  decoration: inputDecoration(context,
                                          hintText:
                                              '${language.hintContactNumberTxt}')
                                      .copyWith(
                                    hintStyle: secondaryTextStyle(),
                                  ),
                                  maxLength: 15,
                                  buildCounter: (_,
                                          {required int currentLength,
                                          required bool isFocused,
                                          required int? maxLength}) =>
                                      Offstage(),
                                  suffix: ic_calling
                                      .iconImage(size: 10)
                                      .paddingAll(14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _sectionCard(
                        icon: Icons.map_outlined,
                        title: language.lblLocation,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                DropdownButtonFormField<CountryListResponse>(
                                  decoration: inputDecoration(context,
                                          labelText: language.selectCountry)
                                      .copyWith(
                                          fillColor:
                                              context.scaffoldBackgroundColor),
                                  isExpanded: true,
                                  value: selectedCountry,
                                  dropdownColor: context.cardColor,
                                  items:
                                      countryList.map((CountryListResponse e) {
                                    return DropdownMenuItem<
                                        CountryListResponse>(
                                      value: e,
                                      child: Text(
                                        e.name!,
                                        style: primaryTextStyle(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged:
                                      (CountryListResponse? value) async {
                                    hideKeyboard(context);
                                    countryId = value!.id!;
                                    selectedCountry = value;
                                    selectedState = null;
                                    selectedCity = null;
                                    getStates(value.id!);

                                    setState(() {});
                                  },
                                ).expand(),
                                8.width.visible(stateList.isNotEmpty),
                                if (stateList.isNotEmpty)
                                  DropdownButtonFormField<StateListResponse>(
                                    decoration: inputDecoration(context,
                                            labelText: language.selectState)
                                        .copyWith(
                                            fillColor: context
                                                .scaffoldBackgroundColor),
                                    isExpanded: true,
                                    dropdownColor: context.cardColor,
                                    value: selectedState,
                                    items: stateList.map((StateListResponse e) {
                                      return DropdownMenuItem<
                                          StateListResponse>(
                                        value: e,
                                        child: Text(
                                          e.name!,
                                          style: primaryTextStyle(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged:
                                        (StateListResponse? value) async {
                                      hideKeyboard(context);
                                      selectedCity = null;
                                      selectedState = value;
                                      stateId = value!.id!;
                                      await getCity(value.id!);
                                      setState(() {});
                                    },
                                  ).expand(),
                              ],
                            ),
                            if (cityList.isNotEmpty) ...[
                              12.height,
                              DropdownButtonFormField<CityListResponse>(
                                decoration: inputDecoration(context,
                                        labelText: language.selectCity)
                                    .copyWith(
                                        fillColor:
                                            context.scaffoldBackgroundColor),
                                isExpanded: true,
                                value: selectedCity,
                                dropdownColor: context.cardColor,
                                items: cityList.map((CityListResponse e) {
                                  return DropdownMenuItem<CityListResponse>(
                                    value: e,
                                    child: Text(e.name!,
                                        style: primaryTextStyle(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (CityListResponse? value) async {
                                  hideKeyboard(context);
                                  selectedCity = value;
                                  cityId = value!.id!;
                                  setState(() {});
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      _sectionCard(
                        icon: Icons.home_outlined,
                        title: language.lblYourAddress,
                        child: CustomAppTextField(
                          controller: addressCont,
                          textFieldType: TextFieldType.MULTILINE,
                          maxLines: 5,
                          decoration: inputDecoration(context,
                                  labelText: language.hintAddress)
                              .copyWith(
                                  fillColor: context.scaffoldBackgroundColor),
                          suffix:
                              ic_location.iconImage(size: 10).paddingAll(14),
                          isValidationRequired: false,
                        ),
                      ),
                      8.height,
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: radius(16),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  context.primaryColor.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: AppButton(
                          color: primaryColor,
                          shapeBorder:
                              RoundedRectangleBorder(borderRadius: radius(16)),
                          elevation: 0,
                          width: context.width(),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline,
                                  color: Colors.white, size: 18),
                              8.width,
                              Text(language.save,
                                  style: boldTextStyle(color: white)),
                            ],
                          ),
                          onTap: () {
                            ifNotTester(() {
                              update();
                            });
                          },
                        ),
                      ),
                      24.height,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
