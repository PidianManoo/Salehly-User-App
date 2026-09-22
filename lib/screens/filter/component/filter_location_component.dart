import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../main.dart';
import '../../../services/location_service.dart';
import '../../../store/place_search_store.dart';
import '../../../utils/common.dart';
import '../custom_aheadtext_feild.dart';

class FilterLocationComponent extends StatefulWidget {
  const FilterLocationComponent({super.key});

  @override
  State<FilterLocationComponent> createState() =>
      _FilterLocationComponentState();
}

class _FilterLocationComponentState extends State<FilterLocationComponent> {
  PlaceSearchStore placeStore = PlaceSearchStore();

  final destinationAddressController = TextEditingController();
  final destinationAddressFocusNode = FocusNode();

  String destinationAddress = '';

  _handleTap(LatLng point, {String address = ''}) async {
    appStore.setLoading(true);

    if (address.isEmpty) {
      destinationAddressController.text =
          await buildFullAddressFromLatLong(point.latitude, point.longitude)
              .catchError((e) {
        log(e);
      });
    } else {
      destinationAddressController.text = address;
    }
    destinationAddress = destinationAddressController.text;

    appStore.setLoading(false);
    setState(() {});
  }

  @override
  void initState() {
    destinationAddressController.text = filterStore.locationName.validate();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(language.lblLocation, style: boldTextStyle(size: 14)),
        16.height,
        Container(
          decoration: BoxDecoration(
            borderRadius: radius(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: AheadTextField(
            controller: destinationAddressController,
            store: placeStore,
            onSelected: (val) async {
              await convertAddressToLatLong(val).then((value) {
                if (value != null) {
                  _handleTap(LatLng(value.latitude, value.longitude),
                      address: val);
                  filterStore.setLatitude(value.latitude.toString());
                  filterStore.setLongitude(value.longitude.toString());
                  filterStore.setLocationName(val.toString());
                } else {
                  toast(errorSomethingWentWrong);
                }
              }).catchError((Error) {
                toast(errorSomethingWentWrong);
              });
            },
            hintText: language.lblEnterYourAddress,
            suggestionStyle: primaryTextStyle(size: 13),
            textStyle: primaryTextStyle(),
            decoration: inputDecoration(
              context,
              borderRadius: 14,
              prefixIcon: Icon(Icons.location_on_outlined,
                      color: context.primaryColor, size: 20)
                  .paddingAll(14),
            ),
          ),
        ),
        if (destinationAddress.isNotEmpty ||
            filterStore.locationName.validate().isNotEmpty) ...[
          16.height,
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.06),
              borderRadius: radius(14),
              border: Border.all(
                  color: context.primaryColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.place_rounded,
                    color: context.primaryColor, size: 20),
                10.width,
                Text(
                  destinationAddressController.text,
                  style: secondaryTextStyle(size: 13),
                ).expand(),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
