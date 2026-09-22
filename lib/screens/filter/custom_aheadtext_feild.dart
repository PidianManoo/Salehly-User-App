// ahead_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../store/place_search_store.dart';

class AheadTextField extends StatefulWidget {
  final String hintText;
  final TextEditingController? controller;
  final Function(String)? onSelected;
  final InputDecoration? decoration;
  final TextStyle? textStyle;
  final TextStyle? suggestionStyle;
  final PlaceSearchStore store;

  const AheadTextField({
    super.key,
    this.hintText = 'Search',
    this.controller,
    this.onSelected,
    this.decoration,
    this.textStyle,
    this.suggestionStyle,
    required this.store,
  });

  @override
  State<AheadTextField> createState() => _AheadTextFieldState();
}

class _AheadTextFieldState extends State<AheadTextField> {
  late TextEditingController _controller;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final FocusNode _focusNode = FocusNode();
  late ReactionDisposer _suggestionReaction;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode.addListener(_handleFocusChange);

    // React to changes in suggestions
    _suggestionReaction = reaction(
      (_) => widget.store.hasSuggestions,
      (hasSuggestions) {
        // if (_focusNode.hasFocus) {
        //   _showOverlay();
        // } else {
        //   _hideOverlay();
        // }
        _showOverlay();
      },
    );
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _suggestionReaction();
    _hideOverlay();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _hideOverlay();
    } else if (widget.store.hasSuggestions) {
      _showOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 5.0),
          child: Material(
            elevation: 8.0,
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10.0),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: 200,
                minWidth: size.width,
              ),
              child: Observer(
                builder: (_) {
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: widget.store.suggestions.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        dense: true,
                        minLeadingWidth: 10,
                        contentPadding: const EdgeInsets.only(
                          bottom: 0,
                          top: 0,
                          left: 10,
                          right: 10,
                        ),
                        leading: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 18,
                        ),
                        title: Text(
                          widget.store.suggestions[index],
                          style: widget.suggestionStyle ??
                              boldTextStyle(
                                size: 10,
                                weight: FontWeight.w300,
                              ),
                        ),
                        onTap: () {
                          _controller.text = widget.store.suggestions[index];
                          _controller.selection = TextSelection.fromPosition(
                            TextPosition(offset: _controller.text.length),
                          );
                          widget.onSelected
                              ?.call(widget.store.suggestions[index]);
                          _hideOverlay();
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    // widget.decoration/textStyle/hintText used to be accepted but silently
    // ignored here — the field always rendered its own hardcoded style
    // (including a hint that always said "Search" regardless of hintText,
    // and black borders that didn't adapt to dark mode) no matter what a
    // caller passed in.
    final InputDecoration baseDecoration =
        widget.decoration ?? const InputDecoration();

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        maxLines: 1,
        minLines: 1,
        autofocus: false,
        style: widget.textStyle ?? primaryTextStyle(),
        decoration: baseDecoration.copyWith(
          hintText: widget.hintText,
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _controller.clear();
                    widget.store.setSearchText('');
                    widget.store.getSuggestions('');
                    setState(() {});
                  },
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: Colors.grey,
                  ),
                  constraints: BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                )
              : baseDecoration.suffixIcon,
        ),
        onChanged: (value) {
          widget.store.setSearchText(value);
          widget.store.getSuggestions(value);
        },
      ),
    );
  }
}
