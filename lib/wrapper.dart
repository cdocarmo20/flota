import 'package:flutter/material.dart';
import 'widgets/sidebar.dart';
import 'widgets/overlays.dart';

class MainWrapper extends StatelessWidget {
  final Widget child;
  const MainWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: Row(
            children: [
              const CustomSidebar(),
              const VerticalDivider(width: 1, thickness: 0.5),
              Expanded(child: child),
            ],
          ),
        ),
        const LoadingOverlay(),
        const NotificationOverlay(),
      ],
    );
  }
}
