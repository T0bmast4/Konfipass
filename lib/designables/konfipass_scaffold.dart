import 'package:flutter/material.dart';
import 'package:konfipass/designables/konfipass_appbar.dart';

class KonfipassScaffold extends StatelessWidget {
  final Widget child;
  final int selectedIndex;

  const KonfipassScaffold({
    super.key,
    required this.child,
    this.selectedIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final bool isExpanded = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: KonfipassAppbar(),
      ),
      body: Row(
        children: [
          NavigationRail(
            extended: isExpanded,
            selectedIndex: selectedIndex,
            onDestinationSelected: (_) {},
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: Text('Termine'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.qr_code_scanner_outlined),
                selectedIcon: Icon(Icons.qr_code_scanner),
                label: Text('Scanner'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
