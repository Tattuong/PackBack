import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/navigation/app_navigator.dart';
import '../core/pack/pack_logic.dart';
import '../providers/pack_provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_ui.dart';
import '../widgets/bag_art.dart';

class BuildScreen extends StatefulWidget {
  const BuildScreen({super.key, this.tripId, this.kind});

  final String? tripId;
  final TripKind? kind;

  @override
  State<BuildScreen> createState() => _BuildScreenState();
}

class _BuildScreenState extends State<BuildScreen> {
  late final TextEditingController _name;
  late DateTime _start;
  late DateTime _end;
  late TripKind _kind;
  late BagKind _bag;
  var _leaving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: 'Lisbon');
    _start = DateTime(2026, 10, 16);
    _end = DateTime(2026, 10, 19);
    _kind = widget.kind ?? TripKind.city;
    _bag = BagKind.cabin;
    if (widget.tripId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final trip = context.read<PackProvider>().findTrip(widget.tripId!);
        if (trip == null) return;
        setState(() {
          _name.text = trip.name;
          _start = trip.start;
          _end = trip.end;
          _kind = trip.kind;
          _bag = trip.bag;
        });
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _editing => widget.tripId != null;

  void _close([String? id]) {
    if (_leaving) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pop(context, id);
    });
  }

  Future<void> _pickRange() async {
    final startPicked = await showDatePicker(
        context: context,
        initialDate: _start,
        firstDate: DateTime(2024),
        lastDate: DateTime(2032));
    if (startPicked == null || !mounted) return;
    final start = DateTime(startPicked.year, startPicked.month, startPicked.day);
    final endInitial = _end.isBefore(start) ? start : _end;
    final endPicked = await showDatePicker(
        context: context,
        initialDate: endInitial,
        firstDate: start,
        lastDate: DateTime(2032));
    if (!mounted) return;
    setState(() {
      _start = start;
      if (endPicked != null) {
        _end = DateTime(endPicked.year, endPicked.month, endPicked.day);
      } else if (_end.isBefore(start)) {
        _end = start;
      }
    });
  }

  Future<void> _save() async {
    final board = context.read<PackProvider>();
    final title = _name.text.trim();
    if (title.isEmpty) {
      AppToast.show(context, title: 'Add a destination first');
      return;
    }
    if (_editing) {
      final trip = board.findTrip(widget.tripId!);
      if (trip == null) return;
      await board.updateTrip(trip,
          name: title, start: _start, end: _end, kind: _kind, bag: _bag);
      _close(trip.id);
      return;
    }
    if (!board.canAdd) {
      final shop = context.read<ShopProvider>();
      AppToast.show(
        context,
        title:
            AppStrings.t(context, 'needProFlows', {'n': '${shop.maxArchive}'}),
        actionLabel: 'Shop',
        onAction: AppTabs.goShop,
      );
      return;
    }
    final trip = await board.create(
        name: title, start: _start, end: _end, kind: _kind, bag: _bag);
    if (trip == null) return;
    _close(trip.id);
  }

  @override
  Widget build(BuildContext context) {
    final ink = AppColors.inkOf(context);
    final count = PackTemplates.of(_kind).length;
    final days = spanDays(_start, _end);
    return PopScope(
      canPop: _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: FtrBackground(
        child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  children: [
                    Row(
                      children: [
                        const PackMark(),
                        const SizedBox(width: 8),
                        Text('PackBack',
                            style: AppTypography.title(
                                size: 20, context: context)),
                        const Spacer(),
                        IconButton(
                            onPressed: () => _close(),
                            icon: Icon(Icons.close, color: ink)),
                      ],
                    ),
                    Text(
                        _editing
                            ? 'Same trip, new details.'
                            : 'A lighter start.',
                        style:
                            AppTypography.display(size: 32, context: context)),
                    const SizedBox(height: 6),
                    Text(
                      _editing
                          ? 'The checklist stays. Dates and bag can change.'
                          : "Choose your trip. We'll build the checklist.",
                      style: AppTypography.body(size: 15, context: context),
                    ),
                    const SizedBox(height: 18),
                    Text('Destination',
                        style: AppTypography.labelBold(context: context)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'Lisbon',
                        prefixIcon: const Icon(Icons.place_outlined),
                        suffixIcon: IconButton(
                            onPressed: () => _name.clear(),
                            icon: const Icon(Icons.close)),
                        filled: true,
                        fillColor: AppColors.surfaceOf(context),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                BorderSide(color: AppColors.borderOf(context))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                BorderSide(color: AppColors.borderOf(context))),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Material(
                      color: AppColors.surfaceOf(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: AppColors.borderOf(context)),
                      ),
                      child: InkWell(
                        onTap: _pickRange,
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 18),
                              const SizedBox(width: 8),
                              Text(rangeLabel(_start, _end),
                                  style: AppTypography.labelBold(context: context)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                    color: AppColors.primarySoftOf(context),
                                    borderRadius: BorderRadius.circular(20)),
                                child: Text(daysLabel(days),
                                    style: AppTypography.labelBold(
                                        size: 12, context: context)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('Trip type',
                        style: AppTypography.labelBold(context: context)),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.35,
                      children: [
                        for (final kind in TripKind.values)
                          _KindTile(
                              kind: kind,
                              selected: _kind == kind,
                              onTap: () => setState(() => _kind = kind)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text('Your bag',
                        style: AppTypography.labelBold(context: context)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final bag in BagKind.values) ...[
                          if (bag != BagKind.cabin) const SizedBox(width: 8),
                          Expanded(
                              child: _BagTile(
                                  bag: bag,
                                  selected: _bag == bag,
                                  onTap: () => setState(() => _bag = bag))),
                        ],
                      ],
                    ),
                    const SizedBox(height: 18),
                    Material(
                      color: AppColors.surfaceOf(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(color: AppColors.borderOf(context)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Starter checklist',
                                style: AppTypography.labelBold(
                                    size: 16, context: context)),
                            Text('$count suggested items · Editable',
                                style: AppTypography.body(
                                    size: 13, context: context)),
                            const SizedBox(height: 4),
                            const BagArt(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28)),
                  ),
                  child: Text(_editing ? 'Save changes' : 'Create checklist →',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
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

class _KindTile extends StatelessWidget {
  const _KindTile(
      {required this.kind, required this.selected, required this.onTap});

  final TripKind kind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final on = AppColors.onPrimaryOf(context);
    final ink = AppColors.inkOf(context);
    return Material(
      color: selected
          ? AppColors.primaryOf(context)
          : AppColors.surfaceOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: selected
                ? AppColors.primaryOf(context)
                : AppColors.borderOf(context)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(_kindIcon(kind), color: selected ? on : ink, size: 20),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(kindLabel(kind),
                      style: TextStyle(
                          color: selected ? on : ink,
                          fontWeight: FontWeight.w800))),
              if (selected) Icon(Icons.check_circle, color: on, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _BagTile extends StatelessWidget {
  const _BagTile(
      {required this.bag, required this.selected, required this.onTap});

  final BagKind bag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const sun = Color(0xFFF6D34A);
    const sunInk = Color(0xFF1A3328);
    final ink = AppColors.inkOf(context);
    return Material(
      color: selected ? sun : AppColors.surfaceOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? sun : AppColors.borderOf(context)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          child: Column(
            children: [
              Icon(_bagIcon(bag), color: selected ? sunInk : ink),
              const SizedBox(height: 6),
              Text(
                bagLabel(bag),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: selected ? sunInk : ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 12),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: sunInk, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _kindIcon(TripKind kind) => switch (kind) {
      TripKind.city => Icons.location_city_outlined,
      TripKind.beach => Icons.beach_access_outlined,
      TripKind.outdoors => Icons.terrain_outlined,
      TripKind.work => Icons.work_outline,
    };

IconData _bagIcon(BagKind bag) => switch (bag) {
      BagKind.cabin => Icons.luggage_outlined,
      BagKind.backpack => Icons.backpack_outlined,
      BagKind.checked => Icons.card_travel_outlined,
    };
