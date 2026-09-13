import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/category_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

class CategorySearchableDropdown extends StatefulWidget {
  final String? labelText;
  final String? hintText;
  final CategoryData? value;
  final void Function(CategoryData?)? onChanged;
  final String? Function(CategoryData?)? validator;
  final bool enabled;
  final Color? dropdownColor;
  final InputDecoration? decoration;
  final Widget? Function(BuildContext, CategoryData)? itemBuilder;
  final String? emptyText;

  const CategorySearchableDropdown({
    Key? key,
    this.labelText,
    this.hintText,
    this.value,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.dropdownColor,
    this.decoration,
    this.itemBuilder,
    this.emptyText,
  }) : super(key: key);

  @override
  _CategorySearchableDropdownState createState() =>
      _CategorySearchableDropdownState();
}

class _CategorySearchableDropdownState
    extends State<CategorySearchableDropdown> {
  late TextEditingController _searchController;
  late List<CategoryData> _allCategories;
  late List<CategoryData> _filteredCategories;
  bool _isOpen = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _textFieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _allCategories = [];
    _filteredCategories = [];
    _updateSearchText();
    _loadCategories();
  }

  @override
  void didUpdateWidget(CategorySearchableDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateSearchText();
        }
      });
    }
  }

  void _updateSearchText() {
    if (widget.value != null) {
      _searchController.text = widget.value?.name ?? '';
    } else {
      _searchController.text = '';
    }
  }

  Future<void> _loadCategories() async {
    appStore.setLoading(true);

    try {
      await getCategoryList(CATEGORY_LIST_ALL).then((value) {
        if (value.categoryList!.isNotEmpty) {
          _allCategories = List.from(value.categoryList.validate());
          _filteredCategories = List.from(_allCategories);
        }
        appStore.setLoading(false);
      });
    } catch (e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    }
  }

  void _filterCategories() {
    if (_searchController.text.isEmpty) {
      _filteredCategories = List.from(_allCategories);
    } else {
      _filteredCategories = _allCategories.where((category) {
        return category.name
            .validate()
            .toLowerCase()
            .contains(_searchController.text.toLowerCase());
      }).toList();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null ||
        !widget.enabled ||
        (_allCategories.isEmpty && !appStore.isLoading)) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: _getTextFieldWidth(),
        child: Observer(builder: (context) {
          return CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, _getTextFieldHeight()),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: 200,
                  minHeight: 0,
                ),
                decoration: BoxDecoration(
                  color:
                      widget.dropdownColor ?? context.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _filteredCategories.isEmpty
                    ? Padding(
                        padding: EdgeInsets.all(16),
                        child: appStore.isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.grey,
                                      ),
                                    ),
                                  ),
                                  8.width,
                                  Text(
                                    'Loading...',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              )
                            : Text(
                                widget.emptyText ?? 'No categories found',
                                style: TextStyle(color: Colors.grey),
                              ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: _filteredCategories.length,
                        itemBuilder: (context, index) {
                          final category = _filteredCategories[index];
                          return InkWell(
                            onTap: () {
                              widget.onChanged?.call(category);
                              _searchController.text = category.name.validate();
                              _hideOverlay();
                              if (mounted) {
                                setState(() {});
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: widget.itemBuilder != null
                                  ? widget.itemBuilder!(context, category)
                                  : Text(
                                      category.name.validate(),
                                      style: primaryTextStyle(),
                                    ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          );
        }),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOpen = false;
  }

  double _getTextFieldWidth() {
    final RenderBox? renderBox =
        _textFieldKey.currentContext?.findRenderObject() as RenderBox?;
    return renderBox?.size.width ?? 200;
  }

  double _getTextFieldHeight() {
    final RenderBox? renderBox =
        _textFieldKey.currentContext?.findRenderObject() as RenderBox?;
    return renderBox?.size.height ?? 50;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _hideOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        key: _textFieldKey,
        controller: _searchController,
        enabled: widget.enabled,
        validator: widget.validator != null
            ? (value) => widget.validator!(widget.value)
            : null,
        decoration: widget.decoration ??
            inputDecoration(
              context,
              labelText: widget.labelText,
              suffixIcon: Icon(
                _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.black,
              ),
            )
        /*  InputDecoration(
              labelText: widget.labelText,
              hintText: widget.hintText,
              suffixIcon: Icon(
                _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.black,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ) */
        ,
        onTap: () {
          if (widget.enabled) {
            if (_isOpen) {
              _hideOverlay();
            } else {
              _isOpen = true;
              _showOverlay();
            }
          }
        },
        onChanged: (value) {
          _filterCategories();
          if (_isOpen) {
            _overlayEntry?.markNeedsBuild();
          }
        },
        onFieldSubmitted: (value) {
          _hideOverlay();
        },
        readOnly: !widget.enabled,
      ),
    );
  }
}
