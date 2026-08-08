import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:sakenph/features/foreground_widget/functions.dart';
import 'package:provider/provider.dart';

import '../../providers/provider_map_helper.dart';

/// Added to import the backend service to use its functions for querying shortest paths and fetching jeepney routes.
import 'package:sakenph/classes/jeepney_route.dart';
import 'package:sakenph/classes/terminal_class.dart';
import 'package:sakenph/api/backend_service.dart';

/// A floating button that can be dragged around the screen.
/// When pressed, it opens a panel that shows the list of jeepney routes and their visibility status on the map.
class JeepneyRouteFloatingControl extends StatefulWidget {
  const JeepneyRouteFloatingControl({super.key});

  @override
  State<JeepneyRouteFloatingControl> createState() =>
      _JeepneyRouteFloatingControlState();
}

class _JeepneyRouteFloatingControlState
    extends State<JeepneyRouteFloatingControl> {
  bool _isOpen = false;
  Offset _position = const Offset(0, 210);
  double _panelWidth = 280.0;
  double _panelHeight = 320.0;
  _JeepneyPanelSection _selectedSection = _JeepneyPanelSection.jeepneyRoutes;
  Future<List<Terminal>>? _todaTerminalsFuture;

  @override
  void initState() {
    super.initState();
    // Load terminals quickly from backend so the UI can show them immediately.
    // Then run enrichment in the background and update the Future when done.
    _todaTerminalsFuture = fetchTodaTerminals();

    // Start enrichment in background without blocking the UI
    fetchAndEnrichTodaTerminals()
        .then((enriched) {
          if (!mounted) return;
          setState(() {
            // Replace future with already-resolved enriched list so FutureBuilder rebuilds
            _todaTerminalsFuture = Future.value(enriched);
          });
        })
        .catchError((e) {
          // Log and ignore enrichment errors so the UI stays responsive
          // ignore: avoid_print
          print('[TODA] enrichment failed: $e');
        });
  }

  @override
  Widget build(BuildContext context) {
    final routes = context.select<MapHelperProvider, List<JeepneyRoute>>(
      (provider) => provider.jeepneyRoutes,
    );

    final visibleIds = context.select<MapHelperProvider, Set<String>>(
      (provider) => provider.visibleJeepneyRouteIds,
    );

    final isLoading = context.select<MapHelperProvider, bool>(
      (provider) => provider.isLoadingJeepneyRoutes,
    );

    final screenSize = MediaQuery.sizeOf(context);
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;
    const buttonSize = 54.0;
    final panelWidth = _panelWidth.clamp(220.0, screenSize.width - 32.0);
    final panelHeight = _panelHeight.clamp(240.0, screenSize.height - 180.0);

    final defaultX = screenSize.width - buttonSize - 16;
    final currentX = _position.dx == 0 ? defaultX : _position.dx;
    final currentY = _position.dy;

    final clampedX = currentX.clamp(8.0, screenSize.width - buttonSize - 8);
    final clampedY = currentY.clamp(
      90.0,
      screenSize.height - buttonSize - bottomSafeArea - 100,
      // 100 is a buffer to avoid overlapping with the bottom navigation bar
    );

    final panelLeft = (clampedX - panelWidth + buttonSize).clamp(
      8.0,
      screenSize.width - panelWidth - 8,
    );

    return Stack(
      children: [
        Positioned(
          left: panelLeft,
          top: clampedY + buttonSize + 8,
          child: Offstage(
            offstage: !_isOpen,
            child: _JeepneyRouteDropdownPanel(
              routes: routes,
              visibleIds: visibleIds,
              isLoading: isLoading,
              width: panelWidth,
              height: panelHeight,
              selectedSection: _selectedSection,
              todaTerminalsFuture: _todaTerminalsFuture,
              onSectionSelected: (section) {
                setState(() {
                  _selectedSection = section;
                });
              },
              onResize: (deltaX, deltaY) {
                setState(() {
                  _panelWidth = (_panelWidth + deltaX).clamp(
                    220.0,
                    screenSize.width - 32.0,
                  );
                  _panelHeight = (_panelHeight + deltaY).clamp(
                    240.0,
                    screenSize.height - 180.0,
                  );
                });
              },
              onDrag: (deltaX, deltaY) {
                setState(() {
                  _position = Offset(clampedX + deltaX, clampedY + deltaY);
                });
              },
              onClose: () {
                setState(() {
                  _isOpen = false;
                });
              },
            ),
          ),
        ),
        Positioned(
          left: clampedX,
          top: clampedY,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _position = Offset(
                  clampedX + details.delta.dx,
                  clampedY + details.delta.dy,
                );
              });
            },
            onTap: () {
              setState(() {
                _isOpen = !_isOpen;
              });
            },
            child: Material(
              color: const Color.fromARGB(255, 41, 114, 110),
              shape: const CircleBorder(),
              elevation: 5,
              child: SizedBox(
                width: buttonSize,
                height: buttonSize,
                child: Icon(
                  _isOpen ? Icons.close : Icons.alt_route,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A panel that displays a list of jeepney routes with checkboxes to toggle their visibility on the map.
enum _JeepneyPanelSection { jeepneyRoutes, todaTerminals }

class _JeepneyRouteDropdownPanel extends StatefulWidget {
  final List<JeepneyRoute> routes;
  final Set<String> visibleIds;
  final bool isLoading;
  final double width;
  final double height;
  final _JeepneyPanelSection selectedSection;
  final void Function(_JeepneyPanelSection section) onSectionSelected;
  final void Function(double deltaX, double deltaY) onResize;
  final void Function(double deltaX, double deltaY) onDrag;
  final VoidCallback? onClose;
  final Future<List<Terminal>>? todaTerminalsFuture;

  const _JeepneyRouteDropdownPanel({
    required this.routes,
    required this.visibleIds,
    required this.isLoading,
    required this.width,
    required this.height,
    required this.selectedSection,
    required this.todaTerminalsFuture,
    required this.onSectionSelected,
    required this.onResize,
    required this.onDrag,
    this.onClose,
  });

  @override
  State<_JeepneyRouteDropdownPanel> createState() =>
      _JeepneyRouteDropdownPanelState();
}

class _JeepneyRouteDropdownPanelState
    extends State<_JeepneyRouteDropdownPanel> {
  late final ScrollController scrollController;
  bool _ignoreResize = false;
  bool _showAllSelected = true;
  final TextEditingController _terminalSearchController =
      TextEditingController();
  String _terminalSearchQuery = '';

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
  }

  @override
  void dispose() {
    scrollController.dispose();
    _terminalSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleCount = widget.visibleIds.length;
    // ScrollController used for both lists so the scrollbar thumb is draggable/touchable.
    // Note: created here for simplicity; if this widget rebuilds frequently consider
    // hoisting the controller to state to properly dispose it.
    final ScrollController scrollController = this.scrollController;

    return Material(
      color: Colors.white,
      elevation: 6,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: widget.isLoading
                  ? const SizedBox(
                      height: 90,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GestureDetector(
                          onPanUpdate: (details) {
                            widget.onDrag(details.delta.dx, details.delta.dy);
                          },
                          child: Center(
                            child: Container(
                              width: 90,
                              height: 7.5,
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _SectionToggleButton(
                                isSelected:
                                    widget.selectedSection ==
                                    _JeepneyPanelSection.jeepneyRoutes,
                                label: 'Jeepney Routes',
                                onTap: () => widget.onSectionSelected(
                                  _JeepneyPanelSection.jeepneyRoutes,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _SectionToggleButton(
                                isSelected:
                                    widget.selectedSection ==
                                    _JeepneyPanelSection.todaTerminals,
                                label: 'Tricycle Terminals',
                                onTap: () => widget.onSectionSelected(
                                  _JeepneyPanelSection.todaTerminals,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Divider(height: 1, color: Colors.grey.shade700),
                        const SizedBox(height: 6),
                        if (widget.selectedSection ==
                            _JeepneyPanelSection.jeepneyRoutes) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _CompactTextButton(
                                      label: 'Show all',
                                      icon: Icons.visibility,
                                      isSelected: _showAllSelected,
                                      onTap: () {
                                        setState(() => _showAllSelected = true);
                                        context
                                            .read<MapHelperProvider>()
                                            .showAllJeepneyRoutes();
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _CompactTextButton(
                                      label: 'Hide all',
                                      icon: Icons.visibility_off,
                                      isSelected: !_showAllSelected,
                                      onTap: () {
                                        setState(
                                          () => _showAllSelected = false,
                                        );
                                        context
                                            .read<MapHelperProvider>()
                                            .hideAllJeepneyRoutes();
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$visibleCount/${widget.routes.length} Selected Routes',
                                  style: TextStyle(
                                    color: Colors.grey.shade800,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: Colors.black54),
                          const SizedBox(height: 4),
                          Expanded(
                            child: widget.routes.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No routes loaded',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Teal visual indicator clamped to the list area (below the divider)
                                      Container(
                                        width: 12,
                                        padding: const EdgeInsets.only(left: 4),
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          width: 4,
                                          decoration: BoxDecoration(
                                            color: const Color.fromARGB(
                                              255,
                                              48,
                                              143,
                                              138,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // The actual scrollable list takes the remaining space
                                      Expanded(
                                        child: Scrollbar(
                                          controller: scrollController,
                                          interactive: true,
                                          thumbVisibility: true,
                                          radius: const Radius.circular(6),
                                          thickness: 7,
                                          child: ListView.builder(
                                            controller: scrollController,
                                            padding: const EdgeInsets.only(
                                              bottom: 20,
                                            ),
                                            itemCount: widget.routes.length,
                                            itemBuilder: (context, index) {
                                              final route =
                                                  widget.routes[index];
                                              final isVisible = widget
                                                  .visibleIds
                                                  .contains(route.id);

                                              return CheckboxListTile(
                                                dense: true,
                                                visualDensity:
                                                    const VisualDensity(
                                                      vertical: -1,
                                                      horizontal: -4,
                                                    ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 2,
                                                    ),
                                                value: isVisible,
                                                activeColor:
                                                    const Color.fromARGB(
                                                      255,
                                                      41,
                                                      114,
                                                      110,
                                                    ),
                                                checkColor: Colors.white,
                                                secondary: Container(
                                                  width: 18,
                                                  height: 18,
                                                  decoration: BoxDecoration(
                                                    color: Color(
                                                      int.parse(
                                                        route.color
                                                            .replaceFirst(
                                                              '#',
                                                              '0xff',
                                                            ),
                                                      ),
                                                    ),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color:
                                                          Colors.grey.shade200,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                ),
                                                title: Text(
                                                  route.name,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                onChanged: (shouldBeVisible) {
                                                  context
                                                      .read<MapHelperProvider>()
                                                      .setJeepneyRouteVisibility(
                                                        route,
                                                        shouldBeVisible ??
                                                            false,
                                                      );
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ] else ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextField(
                              controller: _terminalSearchController,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color.fromARGB(200, 0, 0, 0),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search by location or name...',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade800,
                                  fontSize: 13,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  size: 18,
                                  color: Colors.grey.shade800,
                                ),
                                suffixIcon: _terminalSearchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.clear,
                                          size: 16,
                                          color: Colors.grey.shade400,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _terminalSearchController.clear();
                                            _terminalSearchQuery = '';
                                          });
                                        },
                                      )
                                    : null,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color.fromARGB(255, 41, 114, 110),
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _terminalSearchQuery = value.toLowerCase();
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: widget.todaTerminalsFuture == null
                                ? const Center(
                                    child: Text(
                                      'No TODA terminal data available',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  )
                                : FutureBuilder<List<Terminal>>(
                                    future: widget.todaTerminalsFuture,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                                      if (snapshot.hasError) {
                                        return Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Text(
                                                  'Failed to load TODA terminals',
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  snapshot.error.toString(),
                                                  style: const TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 11,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }

                                      final allTerminals = snapshot.data ?? [];

                                      List<Terminal> terminals;
                                      if (_terminalSearchQuery.isEmpty) {
                                        terminals = allTerminals;
                                      } else {
                                        final query = _terminalSearchQuery;
                                        final barangayMatches = allTerminals
                                            .where(
                                              (t) => (t.barangay ?? '')
                                                  .toLowerCase()
                                                  .contains(query),
                                            )
                                            .toList();
                                        final nameMatches = allTerminals
                                            .where(
                                              (t) =>
                                                  t.name.toLowerCase().contains(
                                                    query,
                                                  ) &&
                                                  !(t.barangay ?? '')
                                                      .toLowerCase()
                                                      .contains(query),
                                            )
                                            .toList();
                                        terminals = [
                                          ...barangayMatches,
                                          ...nameMatches,
                                        ];
                                      }

                                      if (terminals.isEmpty) {
                                        return Center(
                                          child: Text(
                                            _terminalSearchQuery.isNotEmpty
                                                ? 'No terminals found for "$_terminalSearchQuery"'
                                                : 'No TODA terminals found',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                        );
                                      }

                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Container(
                                            width: 12,
                                            padding: const EdgeInsets.only(
                                              left: 4,
                                            ),
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              width: 4,
                                              decoration: BoxDecoration(
                                                color: const Color.fromARGB(
                                                  255,
                                                  48,
                                                  143,
                                                  138,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Scrollbar(
                                              controller: scrollController,
                                              interactive: true,
                                              thumbVisibility: true,
                                              radius: const Radius.circular(6),
                                              thickness: 7,
                                              child: ListView.separated(
                                                controller: scrollController,
                                                itemCount: terminals.length,
                                                separatorBuilder:
                                                    (context, index) => Divider(
                                                      height: 1,
                                                      color:
                                                          Colors.grey.shade700,
                                                    ),
                                                itemBuilder: (context, index) {
                                                  final terminal =
                                                      terminals[index];
                                                  return ListTile(
                                                    dense: true,
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 4,
                                                        ),
                                                    title: Text(
                                                      terminal.name,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    subtitle: Text(
                                                      terminal.barangay ?? '',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                    onTap: () async {
                                                      // Fly the map to the terminal location first
                                                      try {
                                                        final mapHelper =
                                                            Provider.of<
                                                              MapHelperProvider
                                                            >(
                                                              context,
                                                              listen: false,
                                                            );
                                                        await mapHelper
                                                            .mapWidgetController
                                                            .flyToLoc(
                                                              LatLng(
                                                                terminal
                                                                    .latitude,
                                                                terminal
                                                                    .longitude,
                                                              ),
                                                            );
                                                      } catch (e) {
                                                        print(
                                                          '[TODA] Failed to fly to terminal from list: $e',
                                                        );
                                                      }

                                                      widget.onClose?.call();

                                                      final futureLocationLabel =
                                                          terminal.barangay !=
                                                              null
                                                          ? Future.value(
                                                              terminal.barangay ??
                                                                  'Unknown location',
                                                            )
                                                          : reverseGeocode(
                                                              latitude: terminal
                                                                  .latitude,
                                                              longitude: terminal
                                                                  .longitude,
                                                            );

                                                      // Then show a persistent bottom sheet (non-modal) so UI remains interactive
                                                      late PersistentBottomSheetController
                                                      controller;
                                                      controller = Scaffold.of(context).showBottomSheet(
                                                        (ctx) {
                                                          final theme =
                                                              Theme.of(ctx);
                                                          return Container(
                                                            decoration: BoxDecoration(
                                                              color: theme
                                                                  .colorScheme
                                                                  .surface,
                                                              borderRadius:
                                                                  const BorderRadius.only(
                                                                    topLeft:
                                                                        Radius.circular(
                                                                          24,
                                                                        ),
                                                                    topRight:
                                                                        Radius.circular(
                                                                          24,
                                                                        ),
                                                                  ),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: Colors
                                                                      .black26,
                                                                  blurRadius:
                                                                      18,
                                                                  offset:
                                                                      const Offset(
                                                                        0,
                                                                        -8,
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                            padding:
                                                                EdgeInsets.fromLTRB(
                                                                  20,
                                                                  16,
                                                                  20,
                                                                  16 +
                                                                      MediaQuery.viewPaddingOf(
                                                                        ctx,
                                                                      ).bottom,
                                                                ),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .stretch,
                                                              children: [
                                                                Center(
                                                                  child: Container(
                                                                    width: 40,
                                                                    height: 4,
                                                                    margin:
                                                                        const EdgeInsets.only(
                                                                          bottom:
                                                                              16,
                                                                        ),
                                                                    decoration: BoxDecoration(
                                                                      color: theme
                                                                          .colorScheme
                                                                          .onSurface
                                                                          .withOpacity(
                                                                            0.2,
                                                                          ),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            2,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Row(
                                                                  children: [
                                                                    Expanded(
                                                                      child: Text(
                                                                        terminal
                                                                            .name,
                                                                        style: theme
                                                                            .textTheme
                                                                            .titleMedium
                                                                            ?.copyWith(
                                                                              fontWeight: FontWeight.w700,
                                                                            ),
                                                                      ),
                                                                    ),
                                                                    Container(
                                                                      padding: const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            10,
                                                                        vertical:
                                                                            6,
                                                                      ),
                                                                      decoration: BoxDecoration(
                                                                        color: theme
                                                                            .colorScheme
                                                                            .primary
                                                                            .withOpacity(
                                                                              0.12,
                                                                            ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              12,
                                                                            ),
                                                                      ),
                                                                      child: Text(
                                                                        'TODA',
                                                                        style: theme.textTheme.labelMedium?.copyWith(
                                                                          color: theme
                                                                              .colorScheme
                                                                              .primary,
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                  height: 14,
                                                                ),
                                                                FutureBuilder<
                                                                  String
                                                                >(
                                                                  future:
                                                                      futureLocationLabel,
                                                                  builder:
                                                                      (
                                                                        ctx2,
                                                                        snapshot,
                                                                      ) {
                                                                        final label =
                                                                            snapshot.connectionState ==
                                                                                ConnectionState.waiting
                                                                            ? 'Resolving barangay...'
                                                                            : snapshot.hasError
                                                                            ? 'Unknown location'
                                                                            : snapshot.data ??
                                                                                  'Unknown location';
                                                                        return Row(
                                                                          children: [
                                                                            Icon(
                                                                              Icons.place,
                                                                              size: 18,
                                                                              color: theme.colorScheme.primary,
                                                                            ),
                                                                            const SizedBox(
                                                                              width: 10,
                                                                            ),
                                                                            Expanded(
                                                                              child: Text(
                                                                                label,
                                                                                style: theme.textTheme.bodyMedium,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        );
                                                                      },
                                                                ),
                                                                const SizedBox(
                                                                  height: 20,
                                                                ),
                                                                SizedBox(
                                                                  width: double
                                                                      .infinity,
                                                                  child: ElevatedButton(
                                                                    style: ElevatedButton.styleFrom(
                                                                      shape: RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              14,
                                                                            ),
                                                                      ),
                                                                      padding: const EdgeInsets.symmetric(
                                                                        vertical:
                                                                            14,
                                                                      ),
                                                                    ),
                                                                    onPressed: () =>
                                                                        controller
                                                                            .close(),
                                                                    child:
                                                                        const Text(
                                                                          'Close',
                                                                        ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                        backgroundColor:
                                                            Colors.transparent,
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ],
                    ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (details) {
                  final box = context.findRenderObject() as RenderBox;
                  final local = box.globalToLocal(details.globalPosition);
                  _ignoreResize = local.dx >= box.size.width - 40;
                },
                onPanUpdate: (details) {
                  if (!_ignoreResize) widget.onResize(-details.delta.dx, 0);
                },
                onPanEnd: (_) {
                  _ignoreResize = false;
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeLeftRight,
                  child: Container(width: 24, color: Colors.transparent),
                ),
              ),
            ),
            // Right resize handle moved slightly outside the panel to avoid
            // blocking the vertical scrollbar thumb. This makes the thumb
            // draggable while keeping the resize affordance.
            Positioned(
              right: -12,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (details) {
                  final box = context.findRenderObject() as RenderBox;
                  final local = box.globalToLocal(details.globalPosition);
                  _ignoreResize = local.dx >= box.size.width - 40;
                },
                onPanUpdate: (details) {
                  if (!_ignoreResize) widget.onResize(details.delta.dx, 0);
                },
                onPanEnd: (_) {
                  _ignoreResize = false;
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeLeftRight,
                  child: Container(width: 24, color: Colors.transparent),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 30,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (details) {
                  final box = context.findRenderObject() as RenderBox;
                  final local = box.globalToLocal(details.globalPosition);
                  _ignoreResize = local.dx >= box.size.width - 40;
                },
                onPanUpdate: (details) {
                  if (!_ignoreResize) widget.onResize(0, details.delta.dy);
                },
                onPanEnd: (_) {
                  _ignoreResize = false;
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeUpDown,
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanStart: (details) {
                    final box = context.findRenderObject() as RenderBox;
                    final local = box.globalToLocal(details.globalPosition);
                    _ignoreResize = local.dx >= box.size.width - 40;
                  },
                  onPanUpdate: (details) {
                    if (!_ignoreResize)
                      widget.onResize(details.delta.dx, details.delta.dy);
                  },
                  onPanEnd: (_) {
                    _ignoreResize = false;
                  },
                  child: SizedBox(
                    width: 40,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeUpDown,
                      child: Icon(
                        Icons.drag_handle,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
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

class _SectionToggleButton extends StatelessWidget {
  final bool isSelected;
  final String label;
  final VoidCallback onTap;

  const _SectionToggleButton({
    required this.isSelected,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected
            ? colorScheme.primary.withAlpha(31)
            : Colors.transparent,
        foregroundColor: isSelected
            ? colorScheme.primary
            : Colors.grey.shade800,
        side: BorderSide(
          color: isSelected ? colorScheme.primary : Colors.grey.shade300,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      ),
      onPressed: onTap,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _CompactTextButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CompactTextButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const selectedColor = Color.fromARGB(255, 41, 114, 110);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor.withAlpha(30) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.grey.shade400,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? selectedColor : Colors.grey.shade500,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? selectedColor : Colors.grey.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
