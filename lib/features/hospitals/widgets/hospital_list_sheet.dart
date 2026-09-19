import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../models/real_hospital.dart';
import '../providers/real_hospitals_provider.dart';
import 'hospital_card.dart';

class HospitalListSheet extends StatelessWidget {
  const HospitalListSheet({
    super.key,
    required this.hospitalsData,
    required this.status,
    required this.onHospitalTapped,
    required this.onGetDirections,
    this.errorMessage,
    this.onRetry,
  });

  final List<Map<String, dynamic>> hospitalsData;
  final RealHospitalsStatus status;
  final String? errorMessage;
  final void Function(RealHospital hospital) onHospitalTapped;
  final void Function(RealHospital hospital) onGetDirections;

  /// Optional only so existing call sites/tests that never hit an error
  /// don't have to supply one — the sheet's own error state below gates on
  /// this being non-null in practice (status == error implies a real fetch
  /// happened, which always sets a retry-capable caller).
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.1,
      maxChildSize: 0.8,
      snap: true,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 0),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Nearby Hospitals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
              Expanded(child: _buildBody(scrollController)),
            ],
          ),
        );
      },
    );
  }

  /// Every real fetch status gets its own message here — previously only
  /// "loaded + empty" was handled, so a failed fetch (status == error, thus
  /// also an empty hospitalsData) fell through to a zero-item ListView:
  /// just the "Nearby Hospitals" title over blank space, with no
  /// indication anything had gone wrong or was still in flight.
  Widget _buildBody(ScrollController scrollController) {
    switch (status) {
      case RealHospitalsStatus.idle:
      case RealHospitalsStatus.loading:
        return const _SheetMessage(
          icon: null,
          showSpinner: true,
          title: 'Loading nearby hospitals…',
        );
      case RealHospitalsStatus.error:
        return _SheetMessage(
          icon: Icons.wifi_off,
          title: 'Couldn’t load nearby hospitals.',
          message: errorMessage ?? 'Check your connection and try again.',
          onRetry: onRetry,
        );
      case RealHospitalsStatus.loaded:
        if (hospitalsData.isEmpty) {
          return const _SheetMessage(
            icon: Icons.location_off_outlined,
            title: 'No nearby hospitals found.',
            message: 'Try expanding your search area.',
          );
        }
        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          itemCount: hospitalsData.length,
          itemBuilder: (context, index) {
            final data = hospitalsData[index];
            final hospital = data['hospital'] as RealHospital;
            final distanceKm = data['distanceKm'] as double;

            return HospitalCard(
              name: hospital.name,
              address: hospital.address,
              distanceKm: distanceKm,
              onTap: () => onHospitalTapped(hospital),
              actionLabel: 'Get Directions',
              onActionPressed: () => onGetDirections(hospital),
            );
          },
        );
    }
  }
}

class _SheetMessage extends StatelessWidget {
  const _SheetMessage({
    this.icon,
    this.showSpinner = false,
    required this.title,
    this.message,
    this.onRetry,
  });

  final IconData? icon;
  final bool showSpinner;
  final String title;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    // The sheet can be dragged as short as 10% of the screen — this content
    // (icon/spinner + title + message + retry button) doesn't always fit
    // that short, so it needs to scroll rather than overflow, same as any
    // other content that might exceed the sheet's current height.
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSpinner)
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              )
            else if (icon != null)
              Icon(icon, size: 36, color: AppColors.faint),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.faint),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onRetry,
                child: const Text(
                  'Try again',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
