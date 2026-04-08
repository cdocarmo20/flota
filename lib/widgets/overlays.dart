import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/app_state.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: loadingNotifier,
      builder:
          (context, loading, _) =>
              loading
                  ? BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      color: Colors.black12,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  )
                  : const SizedBox.shrink(),
    );
  }
}

class NotificationOverlay extends StatelessWidget {
  const NotificationOverlay({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: alertNotifier,
      builder:
          (context, msg, _) =>
              msg == null
                  ? const SizedBox.shrink()
                  : Positioned(
                    top: 20,
                    right: 20,
                    child: Material(
                      elevation: 10,
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.indigo,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          msg,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
    );
  }
}
