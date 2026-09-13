import 'dart:convert';

import 'package:booking_system_flutter/component/back_widget.dart';
import 'package:booking_system_flutter/component/base_scaffold_body.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/screens/auth/forgot_password_screen.dart';
import 'package:booking_system_flutter/screens/auth/otp_login_screen.dart';
import 'package:booking_system_flutter/screens/auth/sign_up_screen.dart';
import 'package:booking_system_flutter/screens/dashboard/dashboard_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/configs.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/custom_app_field.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../network/rest_apis.dart';
import '../../utils/app_configuration.dart';
import '../language_screen.dart';

class SignInScreen extends StatefulWidget {
  final bool? isFromDashboard;
  final bool? isFromServiceBooking;
  final bool returnExpected;

  SignInScreen(
      {this.isFromDashboard,
      this.isFromServiceBooking,
      this.returnExpected = false});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Phone auth controllers
  TextEditingController numberController = TextEditingController();
  FocusNode _mobileNumberFocus = FocusNode();
  Country selectedCountry = defaultCountry();
  String otpCode = '';
  String verificationId = '';
  ValueNotifier _valueNotifier = ValueNotifier(true);
  bool isCodeSent = false;

  // Email/password controllers (for social options)
  TextEditingController emailCont = TextEditingController();
  TextEditingController passwordCont = TextEditingController();
  FocusNode emailFocus = FocusNode();
  FocusNode passwordFocus = FocusNode();

  bool isRemember = true;
  bool showEmailPasswordForm = false;
  bool isPhoneAuthMode = false; // true for phone auth, false for email auth

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    isRemember = getBoolAsync(IS_REMEMBERED);
    if (isRemember) {
      emailCont.text = getStringAsync(USER_EMAIL);
      passwordCont.text = getStringAsync(USER_PASSWORD);
    }

    // /// For Demo Purpose
    // if (await isIqonicProduct) {
    //   emailCont.text = DEFAULT_EMAIL;
    //   passwordCont.text = DEFAULT_PASS;
    // }
  }

  //region Methods

  // Phone authentication methods
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
      showPhoneCode: true,
      onSelect: (Country country) {
        selectedCountry = country;
        log(jsonEncode(selectedCountry.toJson()));
        setState(() {});
      },
    );
  }

  Future<void> sendOTP() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      hideKeyboard(context);

      appStore.setLoading(true);
      toast(language.sendingOTP);

      try {
        await FirebaseAuth.instance.verifyPhoneNumber(
          timeout: const Duration(seconds: 60),
          phoneNumber:
              "+${selectedCountry.phoneCode}${numberController.text.trim()}",
          verificationCompleted: (PhoneAuthCredential credential) async {
            toast(language.verified);
          },
          verificationFailed: (FirebaseAuthException e) {
            appStore.setLoading(false);
            if (e.code == 'invalid-phone-number') {
              toast(language.theEnteredCodeIsInvalidPleaseTryAgain,
                  print: true);
            } else {
              toast(e.toString(), print: true);
            }
          },
          codeSent: (String _verificationId, int? resendToken) async {
            toast(language.otpCodeIsSentToYourMobileNumber);
            appStore.setLoading(false);
            verificationId = _verificationId;
            if (verificationId.isNotEmpty) {
              OTPLoginScreen(
                      verificationId: verificationId,
                      isFromSignin: true,
                      selectedCountryData: selectedCountry,
                      phoneNumber: numberController.text.trim())
                  .launch(context);
            }
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            FirebaseAuth.instance.signOut();
            isCodeSent = false;
            setState(() {});
          },
        );
      } on Exception catch (e) {
        log(e);
        appStore.setLoading(false);
        toast(e.toString(), print: true);
      }
    }
  }

  Future<void> submitOtp() async {
    log(otpCode);
    if (otpCode.validate().isNotEmpty) {
      if (otpCode.validate().length >= OTP_TEXT_FIELD_LENGTH) {
        hideKeyboard(context);
        appStore.setLoading(true);

        try {
          PhoneAuthCredential credential = PhoneAuthProvider.credential(
              verificationId: verificationId, smsCode: otpCode);
          UserCredential credentials =
              await FirebaseAuth.instance.signInWithCredential(credential);

          Map<String, dynamic> request = {
            'username': numberController.text.trim(),
            'password': numberController.text.trim(),
            'login_type': LOGIN_TYPE_OTP,
            "uid": credentials.user!.uid.validate(),
          };

          try {
            await loginUser(request, isSocialLogin: true)
                .then((loginResponse) async {
              if (loginResponse.isUserExist.validate(value: true)) {
                await saveUserData(loginResponse.userData!);
                await appStore.setLoginType(LOGIN_TYPE_OTP);
                onLoginSuccessRedirection();
              } else {
                appStore.setLoading(false);
                finish(context);
                SignUpScreen(
                  isOTPLogin: true,
                  phoneNumber: numberController.text.trim(),
                  countryCode: selectedCountry.countryCode,
                  uid: credentials.user!.uid.validate(),
                  tokenForOTPCredentials: credential.token,
                ).launch(context);
              }
            }).catchError((e) {
              finish(context);
              toast(e.toString());
              appStore.setLoading(false);
            });
          } catch (e) {
            appStore.setLoading(false);
            toast(e.toString(), print: true);
          }
        } on FirebaseAuthException catch (e) {
          appStore.setLoading(false);
          if (e.code.toString() == 'invalid-verification-code') {
            toast(language.theEnteredCodeIsInvalidPleaseTryAgain, print: true);
          } else {
            toast(e.message.toString(), print: true);
          }
        } on Exception catch (e) {
          appStore.setLoading(false);
          toast(e.toString(), print: true);
        }
      } else {
        toast(language.pleaseEnterValidOTP);
      }
    } else {
      toast(language.pleaseEnterValidOTP);
    }
  }

  // Email/password authentication methods
  void _handleLogin() {
    hideKeyboard(context);
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      _handleLoginUsers();
    }
  }

  void _handleLoginUsers() async {
    hideKeyboard(context);
    Map<String, dynamic> request = {
      'email': emailCont.text.trim(),
      'password': passwordCont.text.trim(),
    };

    appStore.setLoading(true);
    try {
      final loginResponse = await loginUser(request, isSocialLogin: false);

      await saveUserData(loginResponse.userData!);

      await setValue(USER_PASSWORD, passwordCont.text);
      await setValue(IS_REMEMBERED, isRemember);
      await appStore.setLoginType(LOGIN_TYPE_USER);

      authService.verifyFirebaseUser();
      TextInput.finishAutofillContext();

      onLoginSuccessRedirection();
    } catch (e) {
      appStore.setLoading(false);
      toast(e.toString());
    }
  }

  void googleSignIn() async {
    if (!appStore.isLoading) {
      appStore.setLoading(true);
      await authService.signInWithGoogle(context).then((googleUser) async {
        String firstName = '';
        String lastName = '';

        if (googleUser.displayName.validate().split(' ').length >= 1) {
          if (googleUser.displayName?.contains(' ') == true) {
            firstName = googleUser.displayName.splitBefore(' ');
          } else {
            firstName = googleUser.displayName.validate();
          }
        }
        if (googleUser.displayName.validate().split(' ').length >= 2)
          lastName = googleUser.displayName.splitAfter(' ');

        Map<String, dynamic> request = {
          'first_name': firstName,
          'last_name': lastName,
          'email': googleUser.email,
          'username': googleUser.email
              .splitBefore('@')
              .replaceAll('.', '')
              .toLowerCase(),
          // 'password': passwordCont.text.trim(),
          'social_image': googleUser.photoURL,
          'login_type': LOGIN_TYPE_GOOGLE,
        };
        var loginResponse = await loginUser(request, isSocialLogin: true);

        loginResponse.userData!.profileImage = googleUser.photoURL.validate();

        await saveUserData(loginResponse.userData!);
        appStore.setLoginType(LOGIN_TYPE_GOOGLE);

        authService.verifyFirebaseUser();

        onLoginSuccessRedirection();
        appStore.setLoading(false);
      }).catchError((e) {
        appStore.setLoading(false);
        log(e.toString());
        toast(e.toString());
      });
    }
  }

  void appleSign() async {
    if (!appStore.isLoading) {
      appStore.setLoading(true);

      await authService.appleSignIn().then((req) async {
        await loginUser(req, isSocialLogin: true).then((value) async {
          await saveUserData(value.userData!);
          appStore.setLoginType(LOGIN_TYPE_APPLE);

          appStore.setLoading(false);
          authService.verifyFirebaseUser();

          onLoginSuccessRedirection();
        }).catchError((e) {
          appStore.setLoading(false);
          log(e.toString());
          throw e;
        });
      }).catchError((e) {
        appStore.setLoading(false);
        toast(e.toString());
      });
    }
  }

  void toggleEmailPasswordForm() {
    setState(() {
      isPhoneAuthMode = !isPhoneAuthMode;
      showEmailPasswordForm = !isPhoneAuthMode;
    });
  }

  void onLoginSuccessRedirection() {
    afterBuildCreated(() {
      appStore.setLoading(false);
      if (widget.isFromServiceBooking.validate() ||
          widget.isFromDashboard.validate() ||
          widget.returnExpected.validate()) {
        if (widget.isFromDashboard.validate()) {
          push(DashboardScreen(redirectToBooking: true),
              isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
        } else {
          finish(context, true);
        }
      } else {
        DashboardScreen().launch(context,
            isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
      }
    });
  }

//endregion

//region Widgets
  Widget _buildTopWidget() {
    return Row(
      children: [
        Container(
          height: 62,
          width: 62,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.30), width: 1.5),
          ),
          padding: const EdgeInsets.all(10),
          child: Image.asset(imgAppLogo, fit: BoxFit.contain),
        ),
        16.width,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${language.lblLoginTitle}!",
                style: boldTextStyle(size: 22, color: Colors.white),
              ),
              5.height,
              Text(
                language.lblLoginSubTitle,
                style: secondaryTextStyle(size: 12, color: Colors.white.withValues(alpha: 0.80)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneAuthWidget() {
    if (isCodeSent) {
      return AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(24.0),
        child: Column(
          children: [
            // OTP Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.sms_outlined,
                    size: 48,
                    color: primaryColor,
                  ),
                  16.height,
                  Text(
                    language.lblVerificationCode,
                    style: boldTextStyle(size: 20, weight: FontWeight.w600),
                  ),
                  8.height,
                  Text(
                    language.lblOtpSentMessage
                        .replaceAll('{phoneCode}', selectedCountry.phoneCode)
                        .replaceAll('{phoneNumber}', numberController.text),
                    style: secondaryTextStyle(size: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            32.height,
            OTPTextField(
              pinLength: OTP_TEXT_FIELD_LENGTH,
              textStyle: boldTextStyle(size: 18),
              decoration: inputDecoration(context).copyWith(
                counter: Offstage(),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              ),
              onChanged: (s) {
                otpCode = s;
                log(otpCode);
              },
              onCompleted: (pin) {
                otpCode = pin;
                submitOtp();
              },
            ).fit(),
            24.height,
            AppButton(
              onTap: () {
                submitOtp();
              },
              text: language.confirm,
              color: primaryColor,
              textColor: Colors.white,
              width: context.width() - context.navigationBarHeight,
              height: 50,
              textStyle: boldTextStyle(size: 16),
            ),
            16.height,
            TextButton(
              onPressed: () {
                setState(() {
                  isCodeSent = false;
                });
              },
              child: Text(
                language.lblChangePhoneNumber,
                style: boldTextStyle(color: primaryColor, size: 14),
              ),
            ),
          ],
        ),
      );
    } else {
      return Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Country code ...
                  Container(
                    height: 48.0,
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Center(
                      child: ValueListenableBuilder(
                        valueListenable: _valueNotifier,
                        builder: (context, value, child) => Row(
                          children: [
                            Text(selectedCountry.flagEmoji),
                            Text(
                              " +${selectedCountry.phoneCode}",
                              style: primaryTextStyle(size: 12),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: primaryColor,
                            )
                          ],
                        ).paddingOnly(left: 8),
                      ),
                    ),
                  ).onTap(() => changeCountry()).fit(fit: BoxFit.cover),
                  10.width,
                  // Mobile number text field...

                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: CustomAppTextField(
                      controller: numberController,
                      focus: _mobileNumberFocus,
                      textFieldType: TextFieldType.PHONE,
                      decoration: inputDecoration(context).copyWith(
                        hintText:
                            '${language.lblExample}: ${selectedCountry.example}',
                        hintStyle: secondaryTextStyle(),
                      ),
                      autoFocus: true,
                      onFieldSubmitted: (s) {
                        sendOTP();
                      },
                    ).expand(),
                  ),
                ],
              ),
            ),
            15.height,
            AppButton(
              onTap: sendOTP,
              text: language.btnSendOtp,
              color: primaryColor,
              textColor: Colors.white,
              width: context.width() - context.navigationBarHeight,
            ),
            16.height,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(language.doNotHaveAccount, style: secondaryTextStyle()),
                TextButton(
                  onPressed: () {
                    hideKeyboard(context);
                    SignUpScreen().launch(context);
                  },
                  child: Text(
                    language.signUp,
                    style: boldTextStyle(
                      color: primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                if (isAndroid) {
                  if (getStringAsync(PROVIDER_PLAY_STORE_URL).isNotEmpty) {
                    launchUrl(
                        Uri.parse(getStringAsync(PROVIDER_PLAY_STORE_URL)),
                        mode: LaunchMode.externalApplication);
                  } else {
                    launchUrl(
                        Uri.parse(
                            '${getSocialMediaLink(LinkProvider.PLAY_STORE)}$PROVIDER_PACKAGE_NAME'),
                        mode: LaunchMode.externalApplication);
                  }
                } else if (isIOS) {
                  if (getStringAsync(PROVIDER_APPSTORE_URL).isNotEmpty) {
                    commonLaunchUrl(getStringAsync(PROVIDER_APPSTORE_URL));
                  } else {
                    commonLaunchUrl(IOS_LINK_FOR_PARTNER);
                  }
                }
              },
              child: Text(language.lblRegisterAsPartner,
                  style: boldTextStyle(color: primaryColor)),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSocialWidget() {
    if (!appConfigurationStore.socialLoginStatus) return SizedBox.shrink();
    final hasGoogle = appConfigurationStore.googleLoginStatus;
    final hasApple = isIOS && appConfigurationStore.appleLoginStatus;
    if (!hasGoogle && !hasApple) return SizedBox.shrink();
    return Column(
      children: [
        15.height,
        Row(
          children: [
            Divider(color: context.dividerColor, thickness: 1).expand(),
            12.width,
            Text(language.lblOrContinueWith,
                style: secondaryTextStyle(size: 12)),
            12.width,
            Divider(color: context.dividerColor, thickness: 1).expand(),
          ],
        ),
        20.height,
        if (hasGoogle) ...[
          _buildSocialButton(
            onTap: googleSignIn,
            icon: GoogleLogoWidget(size: 20),
            label: language.lblSignInWithGoogle,
          ),
          if (hasApple) 12.height,
        ],
        if (hasApple)
          _buildSocialButton(
            onTap: appleSign,
            icon: Icon(Icons.apple, size: 22, color: context.iconColor),
            label: language.lblSignInWithApple,
          ),
        16.height,
      ],
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onTap,
    required Widget icon,
    required String label,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.dividerColor, width: 1),
        ),
        child: Row(
          children: [
            icon,
            Text(label,
                    style: boldTextStyle(size: 13), textAlign: TextAlign.center)
                .expand(),
          ],
        ),
      ),
    );
  }

  Widget _buildRememberWidget() {
    return Column(
      children: [
        8.height,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RoundedCheckBox(
              borderColor: context.primaryColor,
              checkedColor: context.primaryColor,
              isChecked: isRemember,
              text: language.rememberMe,
              textStyle: secondaryTextStyle(),
              size: 20,
              onTap: (value) async {
                await setValue(IS_REMEMBERED, isRemember);
                isRemember = !isRemember;
                setState(() {});
              },
            ),
            TextButton(
              onPressed: () {
                showInDialog(
                  context,
                  contentPadding: EdgeInsets.zero,
                  dialogAnimation: DialogAnimation.SLIDE_TOP_BOTTOM,
                  builder: (_) => ForgotPasswordScreen(),
                );
              },
              child: Text(
                language.forgotPassword,
                style: boldTextStyle(
                    color: primaryColor, fontStyle: FontStyle.italic),
                textAlign: TextAlign.right,
              ),
            ).flexible(),
          ],
        ),
        14.height,
        Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withValues(alpha: 0.82)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.36),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _handleLogin,
              child: Center(
                child: Text(language.signIn,
                    style: boldTextStyle(size: 16, color: Colors.white)),
              ),
            ),
          ),
        ),
        12.height,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(language.doNotHaveAccount,
                style: secondaryTextStyle(size: 13)),
            4.width,
            GestureDetector(
              onTap: () {
                hideKeyboard(context);
                SignUpScreen().launch(context);
              },
              child: Text(
                language.signUp,
                style: boldTextStyle(size: 13, color: primaryColor),
              ),
            ),
          ],
        ),
        8.height,
        GestureDetector(
          onTap: () {
            if (isAndroid) {
              if (getStringAsync(PROVIDER_PLAY_STORE_URL).isNotEmpty) {
                launchUrl(Uri.parse(getStringAsync(PROVIDER_PLAY_STORE_URL)),
                    mode: LaunchMode.externalApplication);
              } else {
                launchUrl(
                    Uri.parse(
                        '${getSocialMediaLink(LinkProvider.PLAY_STORE)}$PROVIDER_PACKAGE_NAME'),
                    mode: LaunchMode.externalApplication);
              }
            } else if (isIOS) {
              if (getStringAsync(PROVIDER_APPSTORE_URL).isNotEmpty) {
                commonLaunchUrl(getStringAsync(PROVIDER_APPSTORE_URL));
              } else {
                commonLaunchUrl(IOS_LINK_FOR_PARTNER);
              }
            }
          },
          child: Text(
            language.lblRegisterAsPartner,
            style: secondaryTextStyle(size: 12, color: primaryColor),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailPasswordForm() {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          AutofillGroup(
            child: Column(
              children: [
                CustomAppTextField(
                  textFieldType: TextFieldType.EMAIL_ENHANCED,
                  controller: emailCont,
                  focus: emailFocus,
                  nextFocus: passwordFocus,
                  errorThisFieldRequired: language.requiredText,
                  decoration: inputDecoration(context,
                      labelText: language.hintEmailTxt),
                  suffix: ic_message.iconImage(size: 10).paddingAll(14),
                  autoFillHints: [AutofillHints.email],
                ),
                12.height,
                CustomAppTextField(
                  textFieldType: TextFieldType.PASSWORD,
                  controller: passwordCont,
                  focus: passwordFocus,
                  isPassword: true,
                  suffixPasswordVisibleWidget:
                      ic_show.iconImage(size: 10).paddingAll(14),
                  suffixPasswordInvisibleWidget:
                      ic_hide.iconImage(size: 10).paddingAll(14),
                  decoration: inputDecoration(context,
                      labelText: language.hintPasswordTxt),
                  autoFillHints: [AutofillHints.password],
                  isValidationRequired: true,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return language.requiredText;
                    } else if (val.length < 8 || val.length > 12) {
                      return language.passwordLengthShouldBe;
                    }
                    return null;
                  },
                  onFieldSubmitted: (s) {
                    _handleLogin();
                  },
                ),
              ],
            ),
          ),
          _buildRememberWidget(),
        ],
      ),
    );
  }

//endregion

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    if (widget.isFromServiceBooking.validate()) {
      setStatusBarColor(Colors.transparent,
          statusBarIconBrightness: Brightness.dark);
    } else if (widget.isFromDashboard.validate()) {
      setStatusBarColor(Colors.transparent,
          statusBarIconBrightness: Brightness.light);
    } else {
      setStatusBarColor(primaryColor,
          statusBarIconBrightness: Brightness.light);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => hideKeyboard(context),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: context.scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: Navigator.of(context).canPop()
              ? Container(
                  margin: const EdgeInsets.only(left: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: BackWidget(iconColor: Colors.white))
              : null,
          scrolledUnderElevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarIconBrightness: Brightness.light,
            statusBarColor: Colors.transparent,
          ),
          actions: [
            Builder(builder: (ctx) {
              final langs = languageList();
              final cur = langs.firstWhere(
                (l) => l.languageCode == appStore.selectedLanguageCode,
                orElse: () => langs.first,
              );
              return GestureDetector(
                onTap: () => LanguagesScreen().launch(context),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (cur.flag.validate().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Image.asset(cur.flag.validate(),
                              height: 16, width: 24, fit: BoxFit.cover),
                        )
                      else
                        const Icon(Icons.language,
                            color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        cur.languageCode!.toUpperCase(),
                        style: boldTextStyle(size: 12, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
        body: Body(
          child: Stack(
            children: [
              // Gradient background
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: context.height() * 0.32,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor,
                        primaryColor.withValues(alpha: 0.72),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              // Full-height column — no scroll
              Column(
                children: [
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                      child: _buildTopWidget(),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: context.scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.07),
                            blurRadius: 20,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                          child: Observer(builder: (context) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (isPhoneAuthMode)
                                  _buildPhoneAuthWidget()
                                else
                                  _buildEmailPasswordForm(),
                                if (!getBoolAsync(HAS_IN_REVIEW))
                                  _buildSocialWidget(),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
