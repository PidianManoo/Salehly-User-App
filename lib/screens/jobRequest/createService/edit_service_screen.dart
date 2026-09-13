import 'dart:convert';
import 'dart:io';
import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/category_searchable_dropdown.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/category_model.dart';
import 'package:booking_system_flutter/model/package_data_model.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/network/network_utils.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/model_keys.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';

class EditServiceScreen extends StatefulWidget {
  final ServiceData data;
  EditServiceScreen({required this.data});
  @override
  _EditServiceScreenState createState() => _EditServiceScreenState();
}

class _EditServiceScreenState extends State<EditServiceScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  ImagePicker picker = ImagePicker();

  List<XFile> imageFiles = [];
  List<Attachments> attachmentsArray = [];

  CategoryData? selectedCategory;

  bool isServiceUpdated = false;

  @override
  void initState() {
    super.initState();
    imageFiles.addAll(
        widget.data.attachments!.map((e) => XFile(e.validate().toString())));
    attachmentsArray.addAll(widget.data.attachmentsArray.validate());

    selectedCategory = CategoryData(
      id: widget.data.categoryId.validate(),
      name: widget.data.categoryName.validate(),
      description: widget.data.description.validate(),
    );
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Future<void> getMultipleFile() async {
    await picker.pickMultiImage().then((value) {
      imageFiles.addAll(value);
      setState(() {});
    });
  }

  //region Update Service
  Future<void> checkValidation() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      hideKeyboard(context);
      final req = await _buildServiceRequest();
      _submitService(req, context);
    }
  }

  //endregion

  //region Service Api Call
  Future<void> _submitService(req, context) async {
    try {
      appStore.setLoading(true);
      await sendMultiPartRequest(
        req,
        onSuccess: (data) async {
          appStore.setLoading(false);
          toast(jsonDecode(data)['message'], print: true);

          finish(context, true);
        },
        onError: (error) {
          toast(error.toString(), print: true);
          appStore.setLoading(false);
        },
      ).catchError((e) {
        appStore.setLoading(false);
        toast(e.toString(), print: true);
      });
    } catch (e) {
      toast(e.toString());
    }
  }

  //endregion

  //region service request
  Future<MultipartRequest> _buildServiceRequest() async {
    MultipartRequest multiPartRequest =
        await getMultiPartRequest('service-save');
    multiPartRequest.fields[CreateService.name] =
        selectedCategory!.name.validate();
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
    multiPartRequest.fields[CreateService.id] =
        widget.data.id.validate().toString();

    List<XFile> localImages = imageFiles
        .where((file) => !file.path.toLowerCase().startsWith('http'))
        .toList();

    multiPartRequest.files.clear();

    if (imageFiles.isEmpty &&
        selectedCategory!.categoryImage.validate().isNotEmpty) {
      // No photo left (none picked, none remaining) — fall back to the
      // category's own image so the service is never left without a picture.
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

    return multiPartRequest;
  }
  //endregion

  Future<void> removeAttachment({required int id}) async {
    appStore.setLoading(true);

    Map req = {
      CommonKeys.type: SERVICE_ATTACHMENT,
      CommonKeys.id: id,
    };

    await deleteImage(req).then((value) {
      attachmentsArray.validate().removeWhere((element) => element.id == id);
      isServiceUpdated = true;
      setState(() {});

      appStore.setLoading(false);
      toast(value.message.validate(), print: true);
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        finish(context, isServiceUpdated);
        return Future.value(false);
      },
      child: AppScaffold(
        appBarTitle: language.updateService,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Photos ──────────────────────────────────────────────────
                _sectionHeader(
                    Icons.photo_library_rounded, language.chooseImages),
                10.height,
                imageFiles.isEmpty ? _emptyImagePicker() : _imageGrid(),
                20.height,

                // ── Category ─────────────────────────────────────────────────
                _sectionHeader(Icons.category_rounded, language.lblCategory),
                10.height,
                CategorySearchableDropdown(
                  labelText: language.lblCategory,
                  hintText: language.selectCategory,
                  value: selectedCategory,
                  emptyText: language.noDataAvailable,
                  validator: (value) {
                    if (value == null) return errorThisFieldRequired;
                    return null;
                  },
                  dropdownColor: context.scaffoldBackgroundColor,
                  onChanged: (CategoryData? value) async {
                    selectedCategory = value;
                    setState(() {});
                  },
                ),
                32.height,

                // ── Submit ────────────────────────────────────────────────────
                GestureDetector(
                  onTap: checkValidation,
                  child: Container(
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          context.primaryColor,
                          context.primaryColor.withValues(alpha: 0.78),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: context.primaryColor.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.save_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        10.width,
                        Text(
                          language.lblUpdate,
                          style: boldTextStyle(color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String label) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: context.primaryColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: context.primaryColor),
        ),
        8.width,
        Text(label, style: boldTextStyle(size: 13)),
      ],
    );
  }

  Widget _emptyImagePicker() {
    return GestureDetector(
      onTap: getMultipleFile,
      child: Container(
        width: context.width(),
        height: 130,
        decoration: BoxDecoration(
          color: context.primaryColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.primaryColor.withValues(alpha: 0.30),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_photo_alternate_rounded,
                  size: 28, color: context.primaryColor),
            ),
            12.height,
            Text(language.chooseImages,
                style: boldTextStyle(color: context.primaryColor, size: 14)),
            4.height,
            Text(language.pleaseAddImage, style: secondaryTextStyle(size: 11)),
          ],
        ),
      ),
    );
  }

  Widget _imageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                color: context.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.primaryColor.withValues(alpha: 0.28),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_rounded,
                      color: context.primaryColor, size: 26),
                  4.height,
                  Text(language.lblAdd,
                      style:
                          boldTextStyle(color: context.primaryColor, size: 11)),
                ],
              ),
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
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.20),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
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
}
