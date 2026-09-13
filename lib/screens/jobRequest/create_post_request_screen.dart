import 'dart:async';
import 'dart:io';

import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/category_searchable_dropdown.dart';
// import 'package:booking_system_flutter/component/chat_gpt_loder.dart'; // ChatGPT description assist — disabled for now.
import 'package:booking_system_flutter/component/empty_error_state_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/category_model.dart';
import 'package:booking_system_flutter/model/package_data_model.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/network/network_utils.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/jobRequest/createService/edit_service_screen.dart';
import 'package:booking_system_flutter/screens/map/map_screen.dart';
import 'package:booking_system_flutter/services/location_service.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/custom_app_field.dart';
import 'package:booking_system_flutter/utils/model_keys.dart';
import 'package:booking_system_flutter/utils/permissions.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';

class CreatePostRequestScreen extends StatefulWidget {
  @override
  _CreatePostRequestScreenState createState() =>
      _CreatePostRequestScreenState();
}

class _CreatePostRequestScreenState extends State<CreatePostRequestScreen>
    with SingleTickerProviderStateMixin {
  // ─── Job form ───────────────────────────────────────────────────────────────
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController postTitleCont = TextEditingController();
  TextEditingController descriptionCont = TextEditingController();
  TextEditingController priceCont = TextEditingController();
  TextEditingController addressCont = TextEditingController();
  TextEditingController urgentBookingTimeCont = TextEditingController();
  DateTime? _selectedBookingDateTime;

  FocusNode descriptionFocus = FocusNode();
  FocusNode priceFocus = FocusNode();

  bool _isUrgentBooking = false;
  bool _showBookingTimeError = false;

  List<ServiceData> myServiceList = [];
  List<ServiceData> selectedServiceList = [];

  // ─── Add/Edit service (folded in from the old CreateServiceScreen) ──────────
  ImagePicker picker = ImagePicker();
  List<XFile> imageFiles = [];
  List<Attachments> attachmentsArray = [];
  CategoryData? selectedCategory;

  // ────────────────────────────────────────────────────────────────────────────

  static const _cardRadius = 20.0;
  static const _fieldIconColor1 = Color(0xFF6C63FF);
  static const _fieldIconColor2 = Color(0xFF00968A);
  static const _fieldIconColor3 = Color(0xFFFF6B35);
  static const _fieldIconColor4 = Color(0xFFEA2F2F);
  static const _darkBlue = Color(0xFF1E5BA8);

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  // ─── Data loading ────────────────────────────────────────────────────────────

  Future<void> init() async {
    appStore.setLoading(true);
    await getMyServiceList().then((value) {
      appStore.setLoading(false);
      if (value.userServices != null) {
        myServiceList = value.userServices.validate();
      }
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString());
    });
    setState(() {});
  }

  // ─── Combined submit: saves the add/edit-service form (if used) then the job ──

  Future<void> _submitAll() async {
    hideKeyboard(context);
    if (!formKey.currentState!.validate()) return;
    formKey.currentState!.save();

    if (_selectedBookingDateTime == null) {
      setState(() => _showBookingTimeError = true);
      return;
    }

    final bool isAddingOrEditingService = selectedCategory != null;

    if (!isAddingOrEditingService && selectedServiceList.isEmpty) {
      toast(language.createPostJobWithoutSelectService);
      return;
    }

    appStore.setLoading(true);
    try {
      if (isAddingOrEditingService) {
        await _saveServiceForm();
      }

      List<int> serviceList =
          selectedServiceList.map((e) => e.id.validate()).toList();

      Map request = {
        PostJob.postTitle: postTitleCont.text.validate(),
        PostJob.description: descriptionCont.text.validate(),
        PostJob.serviceId: serviceList,
        PostJob.price: priceCont.text.validate(),
        PostJob.status: JOB_REQUEST_STATUS_REQUESTED,
        PostJob.latitude: appStore.latitude,
        PostJob.longitude: appStore.longitude,
        if (_isUrgentBooking) 'IsUrgentbooking': _isUrgentBooking,
        if (_selectedBookingDateTime != null)
          'urgentBookingTime': _selectedBookingDateTime!.toIso8601String(),
      };

      final value = await savePostJob(request);
      appStore.setLoading(false);
      toast(value.message.validate());
      finish(context, true);
    } catch (e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    }
  }

  // ─── Service delete ──────────────────────────────────────────────────────────

  void deleteService(ServiceData data) {
    appStore.setLoading(true);
    deleteServiceRequest(data.id.validate()).then((value) {
      appStore.setLoading(false);
      toast(value.message.validate());
      selectedServiceList.removeWhere((s) => s.id == data.id);
      init();
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    });
  }

  // ─── Edit an existing service (separate screen) ─────────────────────────────

  Future<void> _editService(ServiceData data) async {
    bool? res = await EditServiceScreen(data: data).launch(context);
    if (res ?? false) init();
  }

  // ─── Add new service (inline, folded in from the old CreateServiceScreen) ──

  Future<void> getMultipleFile() async {
    await picker.pickMultiImage().then((value) {
      imageFiles.addAll(value);
      setState(() {});
    });
  }

  void _resetServiceForm() {
    imageFiles = [];
    attachmentsArray = [];
    selectedCategory = null;
  }

  Future<void> _saveServiceForm() async {
    MultipartRequest multiPartRequest = await getMultiPartRequest('service-save');
    multiPartRequest.fields[CreateService.name] = selectedCategory!.name.validate();
    multiPartRequest.fields[CreateService.description] =
        selectedCategory!.description.validate();
    multiPartRequest.fields[CreateService.type] = SERVICE_TYPE_FIXED;
    multiPartRequest.fields[CreateService.price] = '0';
    multiPartRequest.fields[CreateService.addedBy] =
        appStore.userId.toString().validate();
    multiPartRequest.fields[CreateService.providerId] =
        appStore.userId.toString();
    multiPartRequest.fields[CreateService.categoryId] =
        selectedCategory!.id.toString();
    multiPartRequest.fields[CreateService.status] = '1';
    multiPartRequest.fields[CreateService.duration] = "0";

    List<XFile> localImages = imageFiles
        .where((file) => !file.path.toLowerCase().startsWith('http'))
        .toList();

    if (localImages.isEmpty &&
        selectedCategory!.categoryImage.validate().isNotEmpty) {
      // No photo was manually picked — fall back to the category's own image
      // so the service is never left without a picture.
      try {
        final response =
            await get(Uri.parse(selectedCategory!.categoryImage.validate()));
        if (response.statusCode.isSuccessful()) {
          multiPartRequest.files.add(MultipartFile.fromBytes(
            '${CreateService.serviceAttachment}0',
            response.bodyBytes,
            filename: 'category_image.jpg',
          ));
          multiPartRequest.fields[CreateService.attachmentCount] = '1';
        } else {
          multiPartRequest.fields[CreateService.attachmentCount] = '0';
        }
      } catch (e) {
        multiPartRequest.fields[CreateService.attachmentCount] = '0';
      }
    } else {
      await Future.forEach<XFile>(localImages, (file) async {
        int index = localImages.indexOf(file);
        final multipartFile = await MultipartFile.fromPath(
          '${CreateService.serviceAttachment}$index',
          file.path,
        );
        multiPartRequest.files.add(multipartFile);
      });

      multiPartRequest.fields[CreateService.attachmentCount] =
          localImages.length.toString();
    }

    multiPartRequest.headers.addAll(buildHeaderTokens());

    final completer = Completer<void>();
    await sendMultiPartRequest(
      multiPartRequest,
      onSuccess: (data) {
        completer.complete();
      },
      onError: (error) {
        completer.completeError(error.toString());
      },
    );
    await completer.future;

    final existingIds = Set<num>.from(myServiceList.map((s) => s.id.validate()));
    await getMyServiceList().then((value) {
      if (value.userServices != null) myServiceList = value.userServices.validate();
    });

    final newServices =
        myServiceList.where((s) => !existingIds.contains(s.id.validate()));
    if (newServices.isNotEmpty) {
      final newService = newServices.first;
      if (!selectedServiceList.any((s) => s.id == newService.id)) {
        selectedServiceList.add(newService);
      }
    }

    _resetServiceForm();
  }

  Future<void> removeAttachment({required int id}) async {
    appStore.setLoading(true);

    Map req = {
      CommonKeys.type: SERVICE_ATTACHMENT,
      CommonKeys.id: id,
    };

    await deleteImage(req).then((value) {
      attachmentsArray.removeWhere((element) => element.id == id);
      appStore.setLoading(false);
      toast(value.message.validate(), print: true);
      setState(() {});
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    });
  }

  void _confirmRemoveImage(int i, String filePath, bool isNetwork) {
    showConfirmDialogCustom(
      context,
      dialogType: DialogType.DELETE,
      positiveText: language.lblDelete,
      negativeText: language.lblCancel,
      primaryColor: context.primaryColor,
      onAccept: (p0) {
        if (isNetwork) {
          final existing = attachmentsArray.firstWhere(
            (element) => element.url == filePath,
            orElse: () => Attachments(id: 0, url: filePath),
          );
          removeAttachment(id: existing.id.validate());
          attachmentsArray.remove(existing);
          imageFiles.removeAt(i);
        } else {
          imageFiles.removeWhere((e) => e.path == filePath);
          attachmentsArray.removeWhere((e) => e.url == filePath);
        }
        setState(() {});
      },
    );
  }

  // ─── Location helpers ────────────────────────────────────────────────────────

  void _handleSetLocationClick() {
    Permissions.cameraFilesAndLocationPermissionsGranted().then((value) async {
      await setValue(PERMISSION_STATUS, value);
      if (value) {
        final res = await MapScreen(
          latitude: getDoubleAsync(LATITUDE),
          latLong: getDoubleAsync(LONGITUDE),
        ).launch(context);
        if (res != null) {
          addressCont.text = res;
          setState(() {});
        }
      }
    });
  }

  void _handleCurrentLocationClick() {
    Permissions.cameraFilesAndLocationPermissionsGranted().then((value) async {
      await setValue(PERMISSION_STATUS, value);
      if (value) {
        appStore.setLoading(true);
        await getUserLocation().then((v) {
          addressCont.text = v;
          setState(() {});
        }).catchError((e) {
          log(e);
          toast(e.toString());
        });
        appStore.setLoading(false);
      }
    }).catchError((_) {});
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => hideKeyboard(context),
      child: AppScaffold(
        appBarTitle: language.newPostJobRequest,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildJobDetailsCard(),
                  _buildAddEditServiceCard(),
                  _buildServicesCard(),
                ],
              ),
            ),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  // ─── Job details card ────────────────────────────────────────────────────────

  Widget _buildJobDetailsCard() {
    return _card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.work_outline_rounded,
            title: language.newPostJobRequest,
            iconColor: primaryColor,
          ),
          Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Column(
                children: [
                  _iconField(
                    icon: Icons.title_rounded,
                    iconColor: _fieldIconColor1,
                    child: CustomAppTextField(
                      controller: postTitleCont,
                      onChanged: (_) {
                        if (urgentBookingTimeCont.text.isEmpty &&
                            postTitleCont.text.isNotEmpty) {
                          _showBookingTimeError = true;
                          setState(() {});
                        }
                      },
                      textFieldType: TextFieldType.NAME,
                      errorThisFieldRequired: language.requiredText,
                      nextFocus: descriptionFocus,
                      decoration:
                          _decoration(context, label: language.postJobTitle),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _iconField(
                    icon: Icons.description_outlined,
                    iconColor: _fieldIconColor2,
                    child: CustomAppTextField(
                      controller: descriptionCont,
                      textFieldType: TextFieldType.MULTILINE,
                      maxLines: 3,
                      onChanged: (_) {
                        if (urgentBookingTimeCont.text.isEmpty) {
                          _showBookingTimeError = true;
                          setState(() {});
                        }
                      },
                      focus: descriptionFocus,
                      isValidationRequired: false,
                      nextFocus: priceFocus,
                      // ChatGPT description assist — disabled for now, not in use.
                      // enableChatGPT: appConfigurationStore.chatGPTStatus,
                      // promptFieldInputDecorationChatGPT:
                      //     inputDecoration(context).copyWith(
                      //   hintText: language.writeHere,
                      //   fillColor: context.scaffoldBackgroundColor,
                      //   filled: true,
                      // ),
                      // testWithoutKeyChatGPT:
                      //     appConfigurationStore.testWithoutKey,
                      // loaderWidgetForChatGPT: const ChatGPTLoadingWidget(),
                      decoration: _decoration(context,
                          label: language.postJobDescription),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _iconField(
                    icon: Icons.payments_outlined,
                    iconColor: _fieldIconColor3,
                    child: CustomAppTextField(
                      textFieldType: TextFieldType.PHONE,
                      controller: priceCont,
                      onChanged: (_) {
                        if (urgentBookingTimeCont.text.isEmpty) {
                          _showBookingTimeError = true;
                          setState(() {});
                        }
                      },
                      focus: priceFocus,
                      errorThisFieldRequired: language.requiredText,
                      decoration: _decoration(context, label: language.price),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      validator: (s) {
                        if (s!.isEmpty) return errorThisFieldRequired;
                        if (s.toDouble() <= 0)
                          return language.priceAmountValidationMessage;
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  _iconField(
                    icon: Icons.location_on_outlined,
                    iconColor: _fieldIconColor4,
                    child: CustomAppTextField(
                      textFieldType: TextFieldType.MULTILINE,
                      controller: addressCont,
                      onChanged: (_) {
                        if (urgentBookingTimeCont.text.isEmpty) {
                          _showBookingTimeError = true;
                          setState(() {});
                        }
                      },
                      decoration: _decoration(context,
                          label: language.lblEnterYourAddress),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _locationBtn(
                        icon: Icons.map_outlined,
                        label: language.lblChooseFromMap,
                        onTap: _handleSetLocationClick,
                      ).expand(),
                      const SizedBox(width: 10),
                      _locationBtn(
                        icon: Icons.my_location_rounded,
                        label: language.lblUseCurrentLocation,
                        onTap: _handleCurrentLocationClick,
                      ).expand(),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildBookingTimeField(),
                  const SizedBox(height: 14),
                  _buildUrgentBookingToggle(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Services card ───────────────────────────────────────────────────────────

  Widget _buildServicesCard() {
    return _card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.home_repair_service_outlined,
            title: language.services,
            iconColor: _fieldIconColor1,
          ),

          // ── Service list ────────────────────────────────────────────────
          if (myServiceList.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                '${myServiceList.length} ${language.services}',
                style: secondaryTextStyle(size: 12),
              ),
            ),
            ...myServiceList
                .asMap()
                .entries
                .map((e) => _buildServiceCard(e.value)),
            const SizedBox(height: 8),
          ],

          if (myServiceList.isEmpty && !appStore.isLoading)
            NoDataWidget(
              imageWidget: EmptyStateWidget(),
              title: language.noServiceAdded,
              imageSize: const Size(90, 90),
            ).paddingSymmetric(vertical: 16),
        ],
      ),
    );
  }

  // ─── Service list card ───────────────────────────────────────────────────────

  Widget _buildServiceCard(ServiceData data) {
    final bool selected = selectedServiceList.any((e) => e.id == data.id);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.fromLTRB(16, 5, 16, 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected
            ? primaryColor.withValues(alpha: 0.05)
            : context.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? primaryColor.withValues(alpha: 0.35) : borderColor,
          width: selected ? 1.5 : 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.1),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: Row(
        children: [
          // Thumbnail with selection badge
          Stack(
            children: [
              CachedImageWidget(
                url: data.attachments.validate().isNotEmpty
                    ? data.attachments!.first.validate()
                    : '',
                fit: BoxFit.cover,
                height: 62,
                width: 62,
                radius: 12,
              ),
              if (selected)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: white, width: 1.5),
                    ),
                    child: Icon(Icons.check, size: 9, color: white),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Category
          Expanded(
            child: Text(
              data.categoryName.validate(),
              style: boldTextStyle(size: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),

          // Edit / Delete icons
          Column(
            children: [
              _iconAction(
                icon: Icons.edit_outlined,
                color: _fieldIconColor2,
                onTap: () => _editService(data),
              ),
              const SizedBox(height: 5),
              _iconAction(
                icon: Icons.delete_outline_rounded,
                color: redColor,
                onTap: () => showConfirmDialogCustom(
                  context,
                  dialogType: DialogType.DELETE,
                  title: language.lblDelete,
                  positiveText: language.lblDelete,
                  negativeText: language.lblCancel,
                  onAccept: (_) => deleteService(data),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),

          // Select / Remove button
          GestureDetector(
            onTap: () {
              if (selected) {
                selectedServiceList.remove(data);
              } else {
                selectedServiceList.add(data);
              }
              setState(() {});
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                gradient: selected
                    ? null
                    : LinearGradient(
                        colors: [primaryColor, _darkBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: selected ? redColor.withValues(alpha: 0.1) : null,
                borderRadius: BorderRadius.circular(10),
                border: selected
                    ? Border.all(color: redColor.withValues(alpha: 0.35))
                    : null,
              ),
              child: Text(
                selected ? language.remove : language.add,
                style: boldTextStyle(
                  color: selected ? redColor : white,
                  size: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Add service card (inline, folded in from the old CreateServiceScreen) ─

  Widget _buildAddEditServiceCard() {
    return _card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              icon: Icons.add_business_outlined,
              title: language.addService,
              iconColor: _fieldIconColor2,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  imageFiles.isEmpty ? _emptyImagePicker() : _imageGrid(),
                  const SizedBox(height: 16),
                  CategorySearchableDropdown(
                    labelText: language.lblCategory,
                    hintText: language.selectCategory,
                    value: selectedCategory,
                    emptyText: language.noDataAvailable,
                    dropdownColor: context.scaffoldBackgroundColor,
                    onChanged: (CategoryData? value) {
                      selectedCategory = value;
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyImagePicker() {
    return GestureDetector(
      onTap: getMultipleFile,
      child: Container(
        width: context.width(),
        height: 110,
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.30),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_rounded, size: 26, color: primaryColor),
            const SizedBox(height: 8),
            Text(language.chooseImages,
                style: boldTextStyle(color: primaryColor, size: 13)),
          ],
        ),
      ),
    );
  }

  Widget _imageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: imageFiles.length + 1,
      itemBuilder: (context, i) {
        if (i == imageFiles.length) {
          return GestureDetector(
            onTap: getMultipleFile,
            child: Container(
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.28),
                  width: 1.5,
                ),
              ),
              child: Icon(Icons.add_photo_alternate_rounded,
                  color: primaryColor, size: 24),
            ),
          );
        }

        final filePath = imageFiles[i].path;
        final isNetwork = filePath.startsWith('http');

        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isNetwork
                  ? CachedImageWidget(
                      url: filePath, height: double.infinity, fit: BoxFit.cover)
                  : Image.file(File(filePath), fit: BoxFit.cover),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _confirmRemoveImage(i, filePath, isNetwork),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Urgent booking ──────────────────────────────────────────────────────────

  Widget _buildUrgentBookingToggle() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _isUrgentBooking
            ? urgentColor.withValues(alpha: 0.07)
            : context.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isUrgentBooking
              ? urgentColor.withValues(alpha: 0.45)
              : borderColor,
          width: _isUrgentBooking ? 1.5 : 1,
        ),
        boxShadow: _isUrgentBooking
            ? [
                BoxShadow(
                  color: urgentColor.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                )
              ]
            : [],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: urgentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.bolt_rounded, size: 18, color: urgentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  language.urgentBooking,
                  style: boldTextStyle(size: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  _isUrgentBooking
                      ? language.urgentExtraChargeNote
                      : language.priorityServiceWithAdditionalCharge,
                  style: secondaryTextStyle(
                      size: 11, color: _isUrgentBooking ? urgentColor : null),
                ),
              ],
            ),
          ),
          Switch(
            value: _isUrgentBooking,
            onChanged: (val) {
              setState(() {
                _isUrgentBooking = val;
              });
            },
            activeColor: urgentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingTimeField() {
    return _iconField(
      icon: Icons.access_time_rounded,
      iconColor: _showBookingTimeError ? Colors.red : primaryColor,
      child: CustomAppTextField(
        controller: urgentBookingTimeCont,
        textFieldType: TextFieldType.NAME,
        isValidationRequired: false,
        readOnly: true,
        onTap: () async {
          final now = DateTime.now();
          final date = await showDatePicker(
            context: context,
            initialDate: now,
            firstDate: now,
            lastDate: now.add(const Duration(days: 365)),
          );
          if (date != null && mounted) {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (time != null) {
              final dt = DateTime(
                  date.year, date.month, date.day, time.hour, time.minute);
              _selectedBookingDateTime = dt;
              _showBookingTimeError = false;
              urgentBookingTimeCont.text =
                  '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${time.format(context)}';
              setState(() {});
            }
          }
        },
        decoration: _decoration(context, label: language.bookingDate).copyWith(
          errorText: _showBookingTimeError ? language.requiredText : null,
          errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
        ),
      ),
    );
  }

  // ─── Submit button ───────────────────────────────────────────────────────────

  Widget _buildSubmitButton() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
        decoration: BoxDecoration(
          color: context.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.09),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: _submitAll,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, _darkBlue],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.42),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send_rounded, color: white, size: 20),
                const SizedBox(width: 8),
                Text(
                  language.save,
                  style: boldTextStyle(color: white, size: 16),
                ),
                if (selectedServiceList.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${selectedServiceList.length}',
                      style: boldTextStyle(color: white, size: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Reusable helpers ────────────────────────────────────────────────────────

  Widget _card({required Widget child, EdgeInsets? margin}) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required Color iconColor,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title, style: boldTextStyle(size: 16)),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _iconField({
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 15),
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: child),
      ],
    );
  }

  Widget _locationBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: primaryColor.withValues(alpha: 0.25), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: primaryColor),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: boldTextStyle(color: primaryColor, size: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }

  InputDecoration _decoration(BuildContext context, {required String label}) {
    return inputDecoration(context, labelText: label).copyWith(
      fillColor: context.scaffoldBackgroundColor,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
