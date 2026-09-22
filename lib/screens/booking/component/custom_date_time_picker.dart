import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';

/// A fully custom, card-based date + time picker shown as a bottom sheet —
/// used instead of the native showDatePicker/showTimePicker dialogs so the
/// booking flow gets a single, on-brand picking experience with its own
/// entrance animation, month calendar grid, and time-slot chips.
class CustomDateTimePickerSheet extends StatefulWidget {
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? initialDate;
  final TimeOfDay? initialTime;

  const CustomDateTimePickerSheet({
    Key? key,
    required this.firstDate,
    required this.lastDate,
    this.initialDate,
    this.initialTime,
  }) : super(key: key);

  @override
  State<CustomDateTimePickerSheet> createState() =>
      _CustomDateTimePickerSheetState();
}

class _CustomDateTimePickerSheetState extends State<CustomDateTimePickerSheet>
    with SingleTickerProviderStateMixin {
  late DateTime _visibleMonth;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _selectedTime = widget.initialTime;

    final base = _selectedDate ?? widget.firstDate;
    _visibleMonth = DateTime(base.year, base.month);

    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isDateInRange(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    final min = DateTime(
        widget.firstDate.year, widget.firstDate.month, widget.firstDate.day);
    final max = DateTime(
        widget.lastDate.year, widget.lastDate.month, widget.lastDate.day);
    return !day.isBefore(min) && !day.isAfter(max);
  }

  List<DateTime?> _daysInGrid() {
    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leadingEmpty = firstOfMonth.weekday % 7; // Sunday-start grid
    List<DateTime?> cells = List.filled(leadingEmpty, null, growable: true);
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(_visibleMonth.year, _visibleMonth.month, d));
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  List<TimeOfDay> _generateTimeSlots() {
    List<TimeOfDay> slots = [];
    for (int h = 6; h <= 22; h++) {
      slots.add(TimeOfDay(hour: h, minute: 0));
      if (h != 22) slots.add(TimeOfDay(hour: h, minute: 30));
    }
    return slots;
  }

  bool _isTimeDisabled(TimeOfDay t) {
    if (_selectedDate == null) return false;
    final now = DateTime.now();
    if (!_isSameDay(_selectedDate!, now)) return false;
    final candidate = DateTime(_selectedDate!.year, _selectedDate!.month,
        _selectedDate!.day, t.hour, t.minute);
    return candidate.isBefore(now);
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy', appStore.selectedLanguageCode)
        .format(_visibleMonth);
    final firstMonth = DateTime(widget.firstDate.year, widget.firstDate.month);
    final lastMonth = DateTime(widget.lastDate.year, widget.lastDate.month);
    final canGoPrev = _visibleMonth.isAfter(firstMonth);
    final canGoNext = _visibleMonth.isBefore(lastMonth);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: context.scaffoldBackgroundColor,
                borderRadius: radiusOnly(topLeft: 24, topRight: 24),
              ),
              child: Column(
                children: [
                  10.height,
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: context.dividerColor, borderRadius: radius(4)),
                  ),
                  12.height,
                  Row(
                    children: [
                      16.width,
                      Text(language.chooseDateTime,
                              style: boldTextStyle(size: 17))
                          .expand(),
                      IconButton(
                        icon:
                            Icon(Icons.close_rounded, color: context.iconColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                      4.width,
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCalendarCard(monthLabel, canGoPrev, canGoNext),
                          20.height,
                          _buildTimeSection(),
                          20.height,
                        ],
                      ),
                    ),
                  ),
                  _buildFooter(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _navButton(IconData icon, bool enabled, VoidCallback onTap) {
    final child = Container(
      height: 34,
      width: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: enabled
            ? context.primaryColor.withValues(alpha: 0.1)
            : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Icon(icon,
          size: 20,
          color: enabled ? context.primaryColor : context.dividerColor),
    );
    return enabled ? child.onTap(onTap) : child;
  }

  Widget _buildCalendarCard(String monthLabel, bool canGoPrev, bool canGoNext) {
    return Container(
      padding: const EdgeInsets.all(14),
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
        children: [
          Row(
            children: [
              _navButton(Icons.chevron_left_rounded, canGoPrev, () {
                setState(() => _visibleMonth =
                    DateTime(_visibleMonth.year, _visibleMonth.month - 1));
              }),
              Expanded(
                child: Center(
                  child: Text(monthLabel, style: boldTextStyle(size: 15)),
                ),
              ),
              _navButton(Icons.chevron_right_rounded, canGoNext, () {
                setState(() => _visibleMonth =
                    DateTime(_visibleMonth.year, _visibleMonth.month + 1));
              }),
            ],
          ),
          10.height,
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d, style: secondaryTextStyle(size: 11)),
                      ),
                    ))
                .toList(),
          ),
          8.height,
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildDayGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayGrid() {
    final cells = _daysInGrid();
    return GridView.builder(
      key: ValueKey(_visibleMonth),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cells.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
      itemBuilder: (_, i) {
        final day = cells[i];
        if (day == null) return const SizedBox();

        final inRange = _isDateInRange(day);
        final isSelected =
            _selectedDate != null && _isSameDay(_selectedDate!, day);
        final isToday = _isSameDay(DateTime.now(), day);

        return Padding(
          padding: const EdgeInsets.all(3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        context.primaryColor,
                        context.primaryColor.withValues(alpha: 0.8)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected
                  ? null
                  : (isToday
                      ? context.primaryColor.withValues(alpha: 0.08)
                      : Colors.transparent),
              border: isToday && !isSelected
                  ? Border.all(color: context.primaryColor, width: 1.2)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: context.primaryColor.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: boldTextStyle(
                size: 13,
                color: isSelected
                    ? Colors.white
                    : (!inRange
                        ? context.dividerColor
                        : (isToday ? primaryColor : textPrimaryColorGlobal)),
              ),
            ),
          ),
        ).onTap(inRange ? () => setState(() => _selectedDate = day) : null);
      },
    );
  }

  Widget _buildTimeSection() {
    final slots = _generateTimeSlots();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(language.lblTime, style: boldTextStyle(size: 14)),
        10.height,
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: slots.map((t) {
            final disabled = _isTimeDisabled(t);
            final isSelected = _selectedTime != null &&
                _selectedTime!.hour == t.hour &&
                _selectedTime!.minute == t.minute;

            final chip = AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          context.primaryColor,
                          context.primaryColor.withValues(alpha: 0.8)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected
                    ? null
                    : (disabled
                        ? context.dividerColor.withValues(alpha: 0.15)
                        : context.cardColor),
                borderRadius: radius(12),
                border: Border.all(
                    color:
                        isSelected ? Colors.transparent : context.dividerColor),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: context.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                t.format(context),
                style: boldTextStyle(
                  size: 12,
                  color: isSelected
                      ? Colors.white
                      : (disabled
                          ? context.dividerColor
                          : textPrimaryColorGlobal),
                ),
              ),
            );

            return disabled
                ? chip
                : chip.onTap(() => setState(() => _selectedTime = t));
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final canConfirm = _selectedDate != null && _selectedTime != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: context.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius(14),
            boxShadow: canConfirm
                ? [
                    BoxShadow(
                      color: context.primaryColor.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: AppButton(
            color: canConfirm ? context.primaryColor : context.dividerColor,
            shapeBorder: RoundedRectangleBorder(borderRadius: radius(14)),
            elevation: 0,
            width: context.width(),
            text: language.confirm,
            textColor: Colors.white,
            onTap: () {
              if (!canConfirm) {
                toast(language.lblSelectDate);
                return;
              }
              Navigator.pop(
                context,
                DateTime(
                    _selectedDate!.year,
                    _selectedDate!.month,
                    _selectedDate!.day,
                    _selectedTime!.hour,
                    _selectedTime!.minute),
              );
            },
          ),
        ),
      ),
    );
  }
}
