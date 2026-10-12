import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/pack/pack_logic.dart';
import '../providers/pack_provider.dart';
import '../widgets/ad_banner_slot.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_ui.dart';
import '../widgets/bag_art.dart';
import '../widgets/coin_balance_chip.dart';
import 'build_screen.dart';
import 'home/settings_screen.dart';
import 'trip_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _tab = 0;
  String? _tripId;

  Future<void> _newTrip({TripKind? kind}) async {
    final id = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => BuildScreen(kind: kind)));
    if (!mounted || id == null) return;
    setState(() {
      _tripId = id;
      _tab = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final openTrip = _tab == 0 && _tripId != null;
    return PopScope(
      canPop: !openTrip,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && openTrip) setState(() => _tripId = null);
      },
      child: FtrBackground(
        child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: switch (_tab) {
                  1 => _TemplatesTab(onUse: (kind) => _newTrip(kind: kind)),
                  2 => const SettingsScreen(embedded: true),
                  _ => openTrip
                      ? TripView(
                          tripId: _tripId!,
                          onClose: () => setState(() => _tripId = null))
                      : _TripsTab(
                          onOpen: (id) => setState(() => _tripId = id),
                          onCreate: () => _newTrip(),
                        ),
                },
              ),
              const AdBannerSlot(),
              _Nav(
                  index: _tab,
                  onSelect: (index) => setState(() => _tab = index)),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _TripsTab extends StatelessWidget {
  const _TripsTab({required this.onOpen, required this.onCreate});

  final ValueChanged<String> onOpen;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final board = context.watch<PackProvider>();
    final rows = board.trips;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      children: [
        const _Header(),
        const SizedBox(height: 16),
        Text('Your trips',
            style: AppTypography.display(size: 30, context: context)),
        const SizedBox(height: 6),
        Text('Pack what you take. Check it again before you leave.',
            style: AppTypography.body(size: 15, context: context)),
        const SizedBox(height: 16),
        if (rows.isEmpty)
          Text(
              'No trip yet. Start with a place, then tick only what goes in the bag.',
              style: AppTypography.body(size: 15, context: context))
        else
          for (final trip in rows) ...[
            _TripCard(
                trip: trip,
                items: board.itemsOf(trip.id),
                onTap: () => onOpen(trip.id)),
            const SizedBox(height: 12),
          ],
        const SizedBox(height: 4),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add),
          label: const Text('New trip',
              style: TextStyle(fontWeight: FontWeight.w800)),
          style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26))),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const PackMark(),
        const SizedBox(width: 8),
        Text('PackBack',
            style: AppTypography.title(size: 20, context: context)),
        const Spacer(),
        const CoinBalanceChip(variant: CoinChipVariant.header),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard(
      {required this.trip, required this.items, required this.onTap});

  final PackTrip trip;
  final List<PackItem> items;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final packed = PackMath.packedCount(items);
    final total = items.length;
    final left = PackMath.stillOut(items);
    return Material(
      color: AppColors.surfaceOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.borderOf(context)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(kindLabel(trip.kind).toUpperCase(),
                  style: AppTypography.labelBold(size: 11, context: context)
                      .copyWith(letterSpacing: 0.8)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                      child: Text(trip.name,
                          style:
                              AppTypography.title(size: 24, context: context))),
                  const Icon(Icons.chevron_right),
                ],
              ),
              Text(
                  '${rangeLabel(trip.start, trip.end)} · ${bagLabel(trip.bag)}',
                  style: AppTypography.body(size: 13, context: context)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : packed / total,
                  minHeight: 6,
                  color: AppColors.primaryOf(context),
                  backgroundColor: AppColors.primarySoftOf(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                left == 0
                    ? '$packed of $total packed'
                    : '$packed of $total packed · $left to bring back',
                style: AppTypography.body(size: 12, context: context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplatesTab extends StatelessWidget {
  const _TemplatesTab({required this.onUse});

  final ValueChanged<TripKind> onUse;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        Text('Templates',
            style: AppTypography.display(size: 30, context: context)),
        const SizedBox(height: 6),
        Text(
            'A starting list for the kind of day. You still tick what you actually take.',
            style: AppTypography.body(size: 15, context: context)),
        const SizedBox(height: 16),
        for (final kind in TripKind.values) ...[
          _TemplateCard(kind: kind, onUse: () => onUse(kind)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.kind, required this.onUse});

  final TripKind kind;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final count = PackTemplates.of(kind).length;
    return Material(
      color: AppColors.surfaceOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.borderOf(context)),
      ),
      child: InkWell(
        onTap: onUse,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Icon(_templateIcon(kind), color: AppColors.inkOf(context)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kindLabel(kind),
                        style: AppTypography.labelBold(
                            size: 16, context: context)),
                    Text('$count suggested items',
                        style: AppTypography.body(size: 13, context: context)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _templateIcon(TripKind kind) => switch (kind) {
      TripKind.city => Icons.location_city_outlined,
      TripKind.beach => Icons.beach_access_outlined,
      TripKind.outdoors => Icons.terrain_outlined,
      TripKind.work => Icons.work_outline,
    };

class _Nav extends StatelessWidget {
  const _Nav({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    const labels = ['Trips', 'Templates', 'Settings'];
    const icons = [
      Icons.luggage_outlined,
      Icons.list_alt_outlined,
      Icons.settings_outlined
    ];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 4),
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: InkWell(
                  onTap: () => onSelect(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icons[i],
                            color: index == i
                                ? AppColors.primaryOf(context)
                                : AppColors.mutedInk(context)),
                        const SizedBox(height: 2),
                        Text(
                          labels[i],
                          style: TextStyle(
                            fontWeight:
                                index == i ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 12,
                            color: index == i
                                ? AppColors.inkOf(context)
                                : AppColors.mutedInk(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
