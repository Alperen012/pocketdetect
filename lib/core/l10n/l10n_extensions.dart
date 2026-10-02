import 'package:flutter/widgets.dart';
import 'package:mobile_yolo/l10n/generated/app_localizations.dart';

import '../models/category_group.dart';
import '../models/resolution_profile.dart';

/// Convenient access to [AppLocalizations] from any [BuildContext].
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Localized labels for [ResolutionProfile].
extension LocalizedResolutionProfile on ResolutionProfile {
  String localizedLabel(AppLocalizations l10n) {
    return switch (id) {
      'fast' => l10n.resolutionFast,
      'balanced' => l10n.resolutionBalanced,
      'quality' => l10n.resolutionQuality,
      'max' => l10n.resolutionMax,
      _ => label,
    };
  }

  String localizedDisplayLabel(AppLocalizations l10n) =>
      '${localizedLabel(l10n)} (${size}x$size)';
}

/// Localized labels for [CategoryGroup].
extension LocalizedCategoryGroup on CategoryGroup {
  String localizedLabel(AppLocalizations l10n) {
    return switch (id) {
      'vehicles' => l10n.categoryVehicles,
      'transport_infra' => l10n.categoryTransportInfra,
      'animals' => l10n.categoryAnimals,
      'electronics' => l10n.categoryElectronics,
      'furniture' => l10n.categoryFurniture,
      'clothing' => l10n.categoryClothing,
      'sports' => l10n.categorySports,
      'kitchen' => l10n.categoryKitchen,
      'food' => l10n.categoryFood,
      'home_appliances' => l10n.categoryHomeAppliances,
      'household' => l10n.categoryHousehold,
      'plants' => l10n.categoryPlants,
      _ => label,
    };
  }
}
