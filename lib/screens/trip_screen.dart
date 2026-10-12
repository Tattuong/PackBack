import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/constants/app_colors.dart';
import '../core/pack/pack_logic.dart';
import '../models/shop_item.dart';
import '../providers/pack_provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_ui.dart';
import '../widgets/bag_art.dart';
import 'build_screen.dart';

class TripView extends StatefulWidget {
  const TripView({super.key, required this.tripId, required this.onClose});

  final String tripId;
  final VoidCallback onClose;

  @override
  State<TripView> createState() => _TripViewState();
}

class _TripViewState extends State<TripView> {
  final _page = PageController();
  var _index = 0;
  var _awake = false;
  var _onlyLeft = false;
  final _open = <ItemGroup>{ItemGroup.essentials, ItemGroup.tech};
  ItemGroup? _group;
  ItemPlace? _place;
  var _showDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (context.read<ShopProvider>().featureOn(ShopCatalog.featAwake)) {
        _awake = true;
        await WakelockPlus.enable();
      }
    });
  }

  @override
  void dispose() {
    if (_awake) WakelockPlus.disable();
    _page.dispose();
    super.dispose();
  }

  Future<void> _tick() async {
    if (!mounted) return;
    if (context.read<ShopProvider>().featureOn(ShopCatalog.featSound)) {
      await HapticFeedback.selectionClick();
    }
  }

  void _go(int index) {
    if (_index == index) return;
    setState(() => _index = index);
    _page.animateToPage(index,
        duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final board = context.watch<PackProvider>();
    final trip = board.findTrip(widget.tripId);
    if (trip == null) {
      return Center(
          child: Text('This trip is gone.',
              style: AppTypography.body(context: context)));
    }
    final items = board.itemsOf(trip.id);
    final packed = PackMath.packedCount(items);
    final done = PackMath.accountedCount(items);
    final left = PackMath.stillOut(items);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
          child: Row(
            children: [
              IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.arrow_back)),
              Expanded(
                child: Text(
                  trip.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: AppTypography.labelBold(size: 13, context: context)
                      .copyWith(letterSpacing: 1.4),
                ),
              ),
              IconButton(
                  onPressed: () => _menu(trip),
                  icon: const Icon(Icons.more_horiz)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_index == 0 ? 'Ready to go?' : 'Bring it all back.',
                  style: AppTypography.display(size: 30, context: context)),
              const SizedBox(height: 4),
              Text(
                _index == 0
                    ? '${rangeLabel(trip.start, trip.end)} · ${bagLabel(trip.bag)}'
                    : 'Check your belongings before you leave.',
                style: AppTypography.body(size: 14, context: context),
              ),
              const SizedBox(height: 12),
              _DirectionSwitch(index: _index, onChanged: _go),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: PageView(
            controller: _page,
            onPageChanged: (index) => setState(() => _index = index),
            children: [
              _PackPage(
                items: items,
                packed: packed,
                onlyLeft: _onlyLeft,
                group: _group,
                open: _open,
                onGroup: (group) => setState(() => _group = group),
                onToggleSection: (group) => setState(() {
                  if (!_open.add(group)) _open.remove(group);
                }),
                onOnlyLeft: () => setState(() {
                  _onlyLeft = !_onlyLeft;
                  if (_onlyLeft) _open.addAll(ItemGroup.values);
                }),
                onCheck: (item) async {
                  await _tick();
                  await context
                      .read<PackProvider>()
                      .setPacked(item.id, !item.packed);
                },
                onOpen: (item) => _actions(trip, item),
                onAdd: () => _add(trip.id),
              ),
              _ReturnPage(
                trip: trip,
                items: items,
                done: done,
                left: left,
                place: _place,
                showDone: _showDone,
                onPlace: (place) => setState(() => _place = place),
                onToggleDone: () => setState(() => _showDone = !_showDone),
                onCheck: (item) async {
                  await _tick();
                  final next = item.back == ReturnMark.pending
                      ? ReturnMark.confirmed
                      : ReturnMark.pending;
                  await context.read<PackProvider>().setReturn(item.id, next);
                },
                onOpen: (item) => _actions(trip, item),
                onFinish: () async {
                  await context.read<PackProvider>().finishReturn(trip.id);
                  if (context.mounted) {
                    AppToast.show(context, title: 'Return check finished');
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _menu(PackTrip trip) async {
    final action = await _optionSheet<String>(context, (sheet) => [
          ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit trip'),
              onTap: () => Navigator.pop(sheet, 'edit')),
          ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete trip'),
              onTap: () => Navigator.pop(sheet, 'delete')),
        ]);
    if (!mounted || action == null) return;
    if (action == 'edit') {
      await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => BuildScreen(tripId: trip.id)));
      return;
    }
    await context.read<PackProvider>().deleteTrip(trip.id);
    widget.onClose();
  }

  Future<void> _add(String tripId) async {
    final draft = await showDialog<_ItemDraft>(
        context: context, builder: (_) => const _AddItemDialog());
    if (!mounted || draft == null) return;
    await context.read<PackProvider>().addItem(tripId,
        name: draft.name,
        group: draft.group,
        place: draft.place,
        hold: draft.hold);
  }

  Future<void> _actions(PackTrip trip, PackItem item) async {
    final board = context.read<PackProvider>();
    final others = board.trips.where((row) => row.id != trip.id).toList();
    final action = await _optionSheet<String>(context, (sheet) => [
          ListTile(
            title: Text(item.packed ? 'Unpack' : 'Mark packed'),
            onTap: () =>
                Navigator.pop(sheet, item.packed ? 'unpack' : 'pack'),
          ),
          ListTile(
              title: const Text('Brought back'),
              onTap: () => Navigator.pop(sheet, 'confirmed')),
          ListTile(
              title: const Text('Used up'),
              onTap: () => Navigator.pop(sheet, 'used')),
          ListTile(
              title: const Text('Left behind'),
              onTap: () => Navigator.pop(sheet, 'left')),
          ListTile(
              title: const Text('Move to another bag'),
              onTap: () => Navigator.pop(sheet, 'move')),
          ListTile(
            title: Text(item.hold == ItemHold.borrowed
                ? 'Mark as personal'
                : 'Mark as borrowed'),
            onTap: () => Navigator.pop(sheet, 'hold'),
          ),
          ListTile(
              title: const Text('Remove'),
              onTap: () => Navigator.pop(sheet, 'delete')),
        ]);
    if (!mounted || action == null) return;
    final pack = context.read<PackProvider>();
    switch (action) {
      case 'pack':
        await pack.setPacked(item.id, true);
      case 'unpack':
        await pack.setPacked(item.id, false);
      case 'confirmed':
        await pack.setReturn(item.id, ReturnMark.confirmed);
      case 'used':
        await pack.setReturn(item.id, ReturnMark.usedUp);
      case 'left':
        await pack.setReturn(item.id, ReturnMark.left);
      case 'hold':
        await pack.setHold(
            item.id,
            item.hold == ItemHold.borrowed
                ? ItemHold.personal
                : ItemHold.borrowed);
      case 'delete':
        await pack.deleteItem(item.id);
      case 'move':
        if (others.isEmpty) {
          AppToast.show(context, title: 'Add another trip before moving this');
          return;
        }
        final target = await _optionSheet<String>(context, (sheet) => [
              for (final row in others)
                ListTile(
                    title: Text(row.name),
                    subtitle: Text(bagLabel(row.bag)),
                    onTap: () => Navigator.pop(sheet, row.id)),
            ]);
        if (!mounted || target == null) return;
        await pack.moveItem(item.id, target);
    }
  }
}

Future<T?> _optionSheet<T>(
  BuildContext context,
  List<Widget> Function(BuildContext sheet) tiles,
) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) {
      final maxHeight = MediaQuery.sizeOf(sheet).height * 0.72;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: ListView(
            shrinkWrap: true,
            children: tiles(sheet),
          ),
        ),
      );
    },
  );
}

class _DirectionSwitch extends StatelessWidget {
  const _DirectionSwitch({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(
        children: [
          Expanded(
              child: _Lane(
                  label: 'Pack',
                  icon: Icons.luggage_outlined,
                  selected: index == 0,
                  onTap: () => onChanged(0))),
          Icon(Icons.swap_horiz_rounded,
              color: AppColors.mutedInk(context), size: 18),
          Expanded(
              child: _Lane(
                  label: 'Bring back',
                  icon: Icons.assignment_return_outlined,
                  selected: index == 1,
                  onTap: () => onChanged(1))),
        ],
      ),
    );
  }
}

class _Lane extends StatelessWidget {
  const _Lane(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const sun = Color(0xFFF6D34A);
    const sunInk = Color(0xFF1A3328);
    final ink = AppColors.inkOf(context);
    return Material(
      color: selected ? sun : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? sunInk : ink),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: selected ? sunInk : ink)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackPage extends StatelessWidget {
  const _PackPage({
    required this.items,
    required this.packed,
    required this.onlyLeft,
    required this.group,
    required this.open,
    required this.onGroup,
    required this.onToggleSection,
    required this.onOnlyLeft,
    required this.onCheck,
    required this.onOpen,
    required this.onAdd,
  });

  final List<PackItem> items;
  final int packed;
  final bool onlyLeft;
  final ItemGroup? group;
  final Set<ItemGroup> open;
  final ValueChanged<ItemGroup?> onGroup;
  final ValueChanged<ItemGroup> onToggleSection;
  final VoidCallback onOnlyLeft;
  final ValueChanged<PackItem> onCheck;
  final ValueChanged<PackItem> onOpen;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final total = items.length;
    final left = total - packed;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        children: [
          Row(
            children: [
              Text('$packed of $total packed',
                  style: AppTypography.labelBold(size: 15, context: context)),
              const Spacer(),
              Text('$left remaining',
                  style: AppTypography.body(size: 13, context: context)),
            ],
          ),
          const SizedBox(height: 6),
          _Bar(value: PackMath.percent(packed, total)),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              primary: false,
              children: [
                _FilterChip(
                    label: 'All',
                    selected: group == null,
                    onTap: () => onGroup(null)),
                for (final row in [
                  ItemGroup.essentials,
                  ItemGroup.clothes,
                  ItemGroup.tech,
                  ItemGroup.toiletries
                ])
                  _FilterChip(
                      label: groupLabel(row),
                      selected: group == row,
                      onTap: () => onGroup(row)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: _sections(context),
            ),
          ),
          Row(
            children: [
              TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Add item')),
              const Spacer(),
              TextButton(
                  onPressed: onOnlyLeft,
                  child: Text(onlyLeft ? 'Show all' : 'Review remaining')),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _sections(BuildContext context) {
    final visibleGroups = group == null ? ItemGroup.values : [group!];
    final combined = group == null &&
        !onlyLeft &&
        !open.contains(ItemGroup.clothes) &&
        !open.contains(ItemGroup.toiletries);
    final widgets = <Widget>[];
    for (final section in visibleGroups) {
      if (combined &&
          (section == ItemGroup.clothes || section == ItemGroup.toiletries)) {
        if (section == ItemGroup.clothes) widgets.add(_foldedGroups(context));
        continue;
      }
      widgets.addAll(_section(context, section));
    }
    return widgets;
  }

  Widget _foldedGroups(BuildContext context) {
    final clothes = PackMath.groupCount(items, ItemGroup.clothes);
    final toiletries = PackMath.groupCount(items, ItemGroup.toiletries);
    return InkWell(
      onTap: () {
        onToggleSection(ItemGroup.clothes);
        onToggleSection(ItemGroup.toiletries);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const PackGlyph(icon: 'shirt'),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Clothes ${clothes.$1}/${clothes.$2} · Toiletries ${toiletries.$1}/${toiletries.$2}',
                style: AppTypography.labelBold(size: 15, context: context),
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.mutedInk(context)),
          ],
        ),
      ),
    );
  }

  List<Widget> _section(BuildContext context, ItemGroup section) {
    final rows = items
        .where((item) => item.group == section && (!onlyLeft || !item.packed))
        .toList();
    if (rows.isEmpty && group != null) {
      return [
        Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text('Nothing in this group.',
                style: AppTypography.body(context: context)))
      ];
    }
    if (rows.isEmpty) return const [];
    final counts = PackMath.groupCount(items, section);
    final expanded = group != null || open.contains(section);
    return [
      InkWell(
        onTap: group == null ? () => onToggleSection(section) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Text(groupLabel(section).toUpperCase(),
                  style: AppTypography.labelBold(size: 12, context: context)
                      .copyWith(letterSpacing: 0.8)),
              const Spacer(),
              Text('${counts.$1}/${counts.$2}',
                  style: AppTypography.body(size: 12, context: context)),
              Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 18),
            ],
          ),
        ),
      ),
      if (expanded)
        for (final item in rows)
          _PackRow(
              item: item,
              onCheck: () => onCheck(item),
              onOpen: () => onOpen(item)),
    ];
  }
}

class _PackRow extends StatelessWidget {
  const _PackRow(
      {required this.item, required this.onCheck, required this.onOpen});

  final PackItem item;
  final VoidCallback onCheck;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            PackGlyph(icon: item.icon),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style:
                          AppTypography.labelBold(size: 15, context: context)),
                  if (item.hold == ItemHold.borrowed)
                    Text('Borrowed',
                        style: AppTypography.body(size: 12, context: context)),
                ],
              ),
            ),
            PackCheck(on: item.packed, onTap: onCheck),
          ],
        ),
      ),
    );
  }
}

class _ReturnPage extends StatelessWidget {
  const _ReturnPage({
    required this.trip,
    required this.items,
    required this.done,
    required this.left,
    required this.place,
    required this.showDone,
    required this.onPlace,
    required this.onToggleDone,
    required this.onCheck,
    required this.onOpen,
    required this.onFinish,
  });

  final PackTrip trip;
  final List<PackItem> items;
  final int done;
  final int left;
  final ItemPlace? place;
  final bool showDone;
  final ValueChanged<ItemPlace?> onPlace;
  final VoidCallback onToggleDone;
  final ValueChanged<PackItem> onCheck;
  final ValueChanged<PackItem> onOpen;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final filtered =
        items.where((item) => place == null || item.place == place).toList();
    final pending =
        filtered.where((item) => item.back == ReturnMark.pending).toList()
          ..sort((a, b) {
            const order = ['Phone charger', 'Sunglasses'];
            final ai = order.indexOf(a.name);
            final bi = order.indexOf(b.name);
            if (ai >= 0 && bi >= 0) return ai.compareTo(bi);
            return a.order.compareTo(b.order);
          });
    final settled =
        filtered.where((item) => item.back != ReturnMark.pending).toList();
    final total = items.length;
    final ready = PackMath.canFinish(items) && !trip.broughtBack;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$done / $total',
                  style: AppTypography.display(size: 40, context: context)),
              const Spacer(),
              if (left > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                      color: const Color(0xFFE07A3D),
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.fact_check_outlined,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                          left == 1 ? '1 left to check' : '$left left to check',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('items accounted for',
                style: AppTypography.body(size: 13, context: context)),
          ),
          const SizedBox(height: 8),
          _Bar(value: PackMath.percent(done, total)),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              primary: false,
              children: [
                _FilterChip(
                    label: 'All places',
                    selected: place == null,
                    onTap: () => onPlace(null)),
                for (final row in const [ItemPlace.room, ItemPlace.bathroom])
                  _FilterChip(
                      label: placeLabel(row),
                      selected: place == row,
                      onTap: () => onPlace(row)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                if (items.isEmpty)
                  Text('Add an item, then check it before you leave.',
                      style: AppTypography.body(context: context))
                else ...[
                  if (pending.isNotEmpty) ...[
                    Text('STILL TO CHECK (${pending.length})',
                        style:
                            AppTypography.labelBold(size: 12, context: context)
                                .copyWith(letterSpacing: 0.6)),
                    const SizedBox(height: 8),
                    for (final item in pending)
                      _ReturnCard(
                          item: item,
                          onCheck: () => onCheck(item),
                          onOpen: () => onOpen(item)),
                  ],
                  if (settled.isNotEmpty)
                    Material(
                      color: AppColors.primarySoftOf(context),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: onToggleDone,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: AppColors.primaryOf(context)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(
                                      '${settled.length} items confirmed',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primaryOf(context)))),
                              Icon(
                                  showDone
                                      ? Icons.expand_less
                                      : Icons.chevron_right,
                                  color: AppColors.primaryOf(context)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (showDone)
                    for (final item in settled)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: PackGlyph(icon: item.icon),
                        title: Text(item.name),
                        subtitle: Text(item.hold == ItemHold.borrowed
                            ? 'Borrowed · ${returnLabel(item.back)}'
                            : returnLabel(item.back)),
                        onTap: () => onOpen(item),
                      ),
                ],
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: AppColors.mutedInk(context)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Packed items are not automatically marked as returned.',
                        style: AppTypography.body(size: 12, context: context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: ready ? onFinish : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              disabledBackgroundColor: AppColors.primarySoftOf(context),
              disabledForegroundColor: AppColors.mutedInk(context),
            ),
            child: Text(
                trip.broughtBack
                    ? 'Return check finished'
                    : 'Finish return check',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          if (!trip.broughtBack && left > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                left == 1
                    ? 'Confirm the remaining item to finish.'
                    : 'Confirm the remaining $left items to finish.',
                style: AppTypography.body(size: 12, context: context),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReturnCard extends StatelessWidget {
  const _ReturnCard(
      {required this.item, required this.onCheck, required this.onOpen});

  final PackItem item;
  final VoidCallback onCheck;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final hint = item.hint.isEmpty
        ? 'Look around ${placeLabel(item.place).toLowerCase()} before you leave.'
        : item.hint;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surfaceOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE07A3D), width: 1.2),
        ),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                PackGlyph(icon: item.icon, color: const Color(0xFFE07A3D)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: AppTypography.labelBold(
                              size: 15, context: context)),
                      Text(
                        item.hold == ItemHold.borrowed
                            ? 'Borrowed · $hint'
                            : hint,
                        style: AppTypography.body(size: 12, context: context),
                      ),
                    ],
                  ),
                ),
                PackCheck(on: false, onTap: onCheck),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 8,
              color: AppColors.primaryOf(context),
              backgroundColor: AppColors.primarySoftOf(context),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$value%',
            style: AppTypography.labelBold(size: 12, context: context)),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final on = AppColors.onPrimaryOf(context);
    final ink = AppColors.inkOf(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected
            ? AppColors.primaryOf(context)
            : AppColors.surfaceOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
              color: selected
                  ? AppColors.primaryOf(context)
                  : AppColors.borderOf(context)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: selected ? on : ink)),
          ),
        ),
      ),
    );
  }
}

class _ItemDraft {
  const _ItemDraft(
      {required this.name,
      required this.group,
      required this.place,
      required this.hold});

  final String name;
  final ItemGroup group;
  final ItemPlace place;
  final ItemHold hold;
}

class _AddItemDialog extends StatefulWidget {
  const _AddItemDialog();

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _name = TextEditingController();
  var _group = ItemGroup.essentials;
  var _place = ItemPlace.room;
  var _hold = ItemHold.personal;
  var _leaving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _close([_ItemDraft? draft]) {
    if (_leaving) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pop(context, draft);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: AlertDialog(
        title: const Text('Add item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Item name'),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              DropdownButton<ItemGroup>(
                isExpanded: true,
                value: _group,
                items: [
                  for (final group in ItemGroup.values)
                    DropdownMenuItem(
                        value: group, child: Text(groupLabel(group)))
                ],
                onChanged: (value) => setState(() => _group = value ?? _group),
              ),
              DropdownButton<ItemPlace>(
                isExpanded: true,
                value: _place,
                items: [
                  for (final place in ItemPlace.values)
                    DropdownMenuItem(
                        value: place, child: Text(placeLabel(place)))
                ],
                onChanged: (value) => setState(() => _place = value ?? _place),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Borrowed'),
                value: _hold == ItemHold.borrowed,
                onChanged: (value) => setState(() =>
                    _hold = value ? ItemHold.borrowed : ItemHold.personal),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => _close(), child: const Text('Cancel')),
          TextButton(onPressed: _submit, child: const Text('Add')),
        ],
      ),
    );
  }

  void _submit() {
    final title = _name.text.trim();
    if (title.isEmpty) return;
    _close(_ItemDraft(name: title, group: _group, place: _place, hold: _hold));
  }
}
