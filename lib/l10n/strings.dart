import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../models/app_enums.dart';
import '../models/notification_prefs.dart';
import '../providers/detail_layout_controller.dart';
import '../models/season_state.dart';
import '../providers/settings_controller.dart';
import 'copy_service.dart';

/// Interface texts in Italian and English. They change instantly when
/// the user changes language (everything is rebuilt through SettingsController).
///
/// Texts live in `data/ui_copy.json` (copied to assets/data/), which
/// is edited with the Admin Studio: only the keys remain here,
/// read through [CopyService]. The typed class stays as a facade, so
/// the analyzer flags a missing getter and the tests check that every key
/// used exists in the file.
class S {
  const S(this.lang);
  final AppLanguage lang;

  String _c(String key, [Map<String, Object?> params = const {}]) =>
      CopyService.t(key, lang: lang, params: params);

  static S of(BuildContext context) =>
      S(context.select<SettingsController, AppLanguage>((s) => s.language));

  // --- Mesi ---------------------------------------------------------------
  String monthName(int i) => _c('common.month.${i % 12 + 1}');
  String monthShort(int i) => _c('common.month_short.${i % 12 + 1}');
  String monthInitial(int i) => _c('common.month_initial.${i % 12 + 1}');

  // --- Generali -------------------------------------------------------------
  String get appTitle => _c('common.app_title');
  String get tabPeakSeason => _c('common.tab_peak_season');
  String get tabShopping => _c('common.tab_shopping');
  String get tabSettings => _c('common.tab_settings');
  String get close => _c('common.close');
  String get cancel => _c('common.cancel');
  String get reset => _c('common.reset');

  // --- Home -----------------------------------------------------------------
  String get filterAll => _c('home.filter_all');
  String get filterAllChip => _c('home.filter_all_chip');
  String get fruit => _c('home.fruit');
  String get vegetables => _c('home.vegetables');
  String get shoppingFilter => _c('home.shopping_filter');
  String get favoritesFilter => _c('home.favorites_filter');
  String get advancedFilters => _c('home.advanced_filters');
  String get searchHint =>
      _c('home.search_hint');
  String get search => _c('home.search');
  String get today => _c('home.today');
  String viewModeLabel(HomeViewMode m) => switch (m) {
        HomeViewMode.grid => _c('home.view_mode_label.grid'),
        HomeViewMode.list => _c('home.view_mode_label.list'),
        HomeViewMode.calendar => _c('home.view_mode_label.calendar'),
      };
  String get changeView => _c('home.change_view');
  String pulse(int peak, int inSeason) => _c('home.pulse', {'peak': peak, 'inSeason': inSeason});
  String get legend => _c('home.legend');
  String get noResults => _c('home.no_results');
  String get noResultsHint => _c('home.no_results_hint');
  String get clearFilters => _c('home.clear_filters');
  String get hiddenVisible => _c('home.hidden_visible');
  String get dopOnlyChip => _c('home.dop_only_chip');
  String noDataSection(int n) =>
      _c('home.no_data_section', {'n': n});
  String get noDataSectionHint => _c('home.no_data_section_hint');
  String get includeNoData => _c('home.include_no_data');
  String get includeNoDataSub => _c('home.include_no_data_sub');
  String get noDataChip => _c('home.no_data_chip');
  String referenceCalendar(String zone) =>
      _c('home.reference_calendar', {'zone': zone});
  String get referenceNote =>
      _c('home.reference_note');
  String get italyNational => _c('home.italy_national');
  String resultsCount(int n) => _c('home.results_count', {'n': n});

  // --- Filtri avanzati ----------------------------------------------------
  String get categoriesTitle => _c('filters.categories_title');
  String seasonStatesTitle(String month) =>
      _c('filters.season_states_title', {'month': month});
  String get qualityTitle => _c('filters.quality_title');
  String get dopOnly => _c('filters.dop_only');
  String get dopOnlySub => _c('filters.dop_only_sub');
  String get hiddenTitle => _c('filters.hidden_title');
  String get showHidden =>
      _c('filters.show_hidden');
  String showHiddenSub(int n) => _c('filters.show_hidden_sub', {'n': n});

  String category(FoodCategory c) => switch (c) {
        FoodCategory.verdura => _c('filters.category.verdura'),
        FoodCategory.frutta => _c('filters.category.frutta'),
        FoodCategory.erbeSpezie => _c('filters.category.erbe_spezie'),
        FoodCategory.funghi => _c('filters.category.funghi'),
        FoodCategory.cereali => _c('filters.category.cereali'),
      };

  String state(SeasonState s) => switch (s) {
        SeasonState.primizie => _c('filters.state.primizie'),
        SeasonState.inSeason => _c('filters.state.in_season'),
        SeasonState.peakSeason => _c('filters.state.peak_season'),
        SeasonState.endOfSeason => _c('filters.state.end_of_season'),
        SeasonState.outOfSeason => _c('filters.state.out_of_season'),
        SeasonState.notApplicable =>
          _c('filters.state.not_applicable'),
        SeasonState.unknown => _c('filters.state.unknown'),
      };

  String get unknownTitle => _c('home.unknown_title');
  String get unknownDescription => _c('home.unknown_description');
  String get unknownShort => _c('home.unknown_short');
  String get approxNote => _c('home.approx_note');

  // --- Card / azioni ------------------------------------------------------
  String get addToList => _c('actions.add_to_list');
  String get removeFromList => _c('actions.remove_from_list');
  String get addFavorite => _c('actions.add_favorite');
  String get removeFavorite => _c('actions.remove_favorite');
  String get dislike => _c('actions.dislike');
  String get undislike => _c('actions.undislike');
  String get favorite => _c('actions.favorite');
  String get inList => _c('actions.in_list');
  String get addedToList => _c('actions.added_to_list');
  String get removedFromList => _c('actions.removed_from_list');
  String hiddenSnack(String name) =>
      _c('actions.hidden_snack', {'name': name});
  String get undo => _c('actions.undo');

  // --- Lista spesa ----------------------------------------------------------
  String get shoppingTitle => _c('shopping_list.shopping_title');
  String shoppingCount(int n) =>
      n == 1 ? _c('shopping_list.shopping_count.one') : _c('shopping_list.shopping_count.other', {'n': n});
  String get shoppingEmpty => _c('shopping_list.shopping_empty');
  String get shoppingEmptyHint => _c('shopping_list.shopping_empty_hint');
  String get clearList => _c('shopping_list.clear_list');
  String get clearListConfirm =>
      _c('shopping_list.clear_list_confirm');
  String get whatToLookFor => _c('shopping_list.what_to_look_for');
  String shoppingCounter(int toBuy, int inCart) =>
      _c('shopping_list.shopping_counter', {'items': shoppingCount(toBuy), 'inCart': inCart});
  String inCartHeader(int n) => _c('shopping_list.in_cart_header', {'n': n});
  String get clearCompleted => _c('shopping_list.clear_completed');
  String get addFoodHint => _c('shopping_list.add_food_hint');
  String get doneShoppingTitle => _c('shopping_list.done_shopping_title');
  String get doneShoppingSub => _c('shopping_list.done_shopping_sub');
  String get grossWeightCalc => _c('shopping_list.gross_weight_calc');
  String get netWeight => _c('shopping_list.net_weight');
  String get grossToBuy => _c('shopping_list.gross_to_buy');
  String edibleYield(int pct) => _c('shopping_list.edible_yield', {'pct': pct});
  String get storageTipsButton => _c('shopping_list.storage_tips_button');

  // --- Impostazioni -------------------------------------------------------
  String get language => _c('settings.language');
  String get theme => _c('settings.theme');
  String get themeLight => _c('settings.theme_light');
  String get themeDark => _c('settings.theme_dark');
  String get themeSystem => _c('settings.theme_system');
  String get frostTitle => _c('settings.frost_title');
  String get frostSub => _c('settings.frost_sub');
  String get frostNone => _c('settings.frost_none');
  String get frostStrong => _c('settings.frost_strong');
  String get paletteTitle => _c('settings.palette_title');
  String paletteName(BackdropPalette p) => switch (p) {
        BackdropPalette.green => _c('settings.palette_name.green'),
        BackdropPalette.greenTeal => _c('settings.palette_name.green_teal'),
        BackdropPalette.custom => _c('settings.palette_name.custom'),
        BackdropPalette.none => _c('settings.palette_name.none'),
      };
  String get zoneArctic => _c('settings.zone_arctic');
  String get mapNote => _c('settings.map_note');
  String get climateZone => _c('settings.climate_zone');
  String get climateZoneSub => _c('settings.climate_zone_sub');
  String zone(ClimaticZone z) => switch (z) {
        ClimaticZone.mediterranean => _c('settings.zone.mediterranean'),
        ClimaticZone.continental => _c('settings.zone.continental'),
        ClimaticZone.atlantic => _c('settings.zone.atlantic'),
        ClimaticZone.boreal => _c('settings.zone.boreal'),
        ClimaticZone.mountain => _c('settings.zone.mountain'),
        ClimaticZone.pannonian => _c('settings.zone.pannonian'),
      };
  /// Country name (the database stores them in English, like EUFIC). If
  /// missing from the texts, the English name is kept.
  String country(String en) {
    final key = 'settings.country.${en.toLowerCase().replaceAll(' ', '_')}';
    return CopyService.has(key) ? _c(key) : en;
  }

  String get macroArea => _c('settings.macro_area');
  String get macroAreaSub => _c('settings.macro_area_sub');
  String area(ItalyMacroArea a) => switch (a) {
        ItalyMacroArea.nord => _c('settings.area.nord'),
        ItalyMacroArea.centro => _c('settings.area.centro'),
        ItalyMacroArea.sudIsole => _c('settings.area.sud_isole'),
        ItalyMacroArea.euficMediterranean =>
          _c('settings.area.eufic_mediterranean'),
      };
  String get approxSetting =>
      _c('settings.approx_setting');
  String get approxSettingSub => _c('settings.approx_setting_sub');
  String get notifications => _c('settings.notifications');
  String get peakNotif => _c('settings.peak_notif');
  String get peakNotifSub => _c('settings.peak_notif_sub');
  String peakNotifMode(PeakNotifMode m) => switch (m) {
        PeakNotifMode.off => _c('settings.peak_notif_mode.off'),
        PeakNotifMode.favorites => _c('settings.peak_notif_mode.favorites'),
        PeakNotifMode.allExceptDisliked =>
          _c('settings.peak_notif_mode.all_except_disliked'),
      };
  String get shoppingModeTitle => _c('settings.shopping_mode_title');
  String get shoppingModeSub => _c('settings.shopping_mode_sub');
  String get shoppingModeListOption => _c('settings.shopping_mode_list_option');
  String shoppingModeListMode(ShoppingNotifListMode m) => switch (m) {
        ShoppingNotifListMode.highlight => _c('settings.shopping_mode_list_mode.highlight'),
        ShoppingNotifListMode.onlyList =>
          _c('settings.shopping_mode_list_mode.only_list'),
      };
  String get storageTipsWhen => _c('settings.storage_tips_when');
  String get storageTipsNow => _c('settings.storage_tips_now');
  String get storageTipsLater => _c('settings.storage_tips_later');
  String minutesShort(int m) => _c('settings.minutes_short', {'m': m});
  String get storageTipsDelayNote => _c('settings.storage_tips_delay_note');
  String get storageAfterShopping =>
      _c('settings.storage_after_shopping');
  String get storageAfterShoppingSub => _c('settings.storage_after_shopping_sub');
  String get shoppingModeOn => _c('settings.shopping_mode_on');
  String get shoppingModeOff => _c('settings.shopping_mode_off');
  String get shoppingModeActivated => _c('settings.shopping_mode_activated');
  String get notifPermissionDenied => _c('settings.notif_permission_denied');
  String get notifUnsupported => _c('settings.notif_unsupported');

  // --- Notification texts -------------------------------------------------
  String notifSeasonTitle(String month) => _c('notifications.notif_season_title', {'month': month});
  String notifListTitle(int inSeason, int total) => _c('notifications.notif_list_title', {'inSeason': inSeason, 'total': total});
  String get notifClose => _c('notifications.notif_close');
  String get notifStorageTitle => _c('notifications.notif_storage_title');
  String get notifStorageBody => _c('notifications.notif_storage_body');
  String notifPeakTitle(String month) =>
      _c('notifications.notif_peak_title', {'month': month});
  String get notifChannelShopping => _c('notifications.notif_channel_shopping');
  String get notifChannelPeak => _c('notifications.notif_channel_peak');
  String get notifChannelTips => _c('notifications.notif_channel_tips');
  String get lineList => _c('notifications.line_list');
  String get lineMore => _c('notifications.line_more');

  // --- Pagina conservazione -----------------------------------------------
  String get storageTipsTitle => _c('storage_tips.storage_tips_title');
  String get storageTipsIntro => _c('storage_tips.storage_tips_intro');
  String get storageTipsSearch => _c('storage_tips.storage_tips_search');
  String get storageTipsEmptyList => _c('storage_tips.storage_tips_empty_list');
  String get storageGuideIntro => _c('storage_tips.storage_guide_intro');
  String get storageSearchAll =>
      _c('storage_tips.storage_search_all');
  String get storageSearchAllSub => _c('storage_tips.storage_search_all_sub');
  String get ethyleneAlertTitle =>
      _c('storage_tips.ethylene_alert_title');
  String get ethyleneAlertIntro => _c('storage_tips.ethylene_alert_intro');
  String get ethyleneReleases => _c('storage_tips.ethylene_releases');
  String storageGroup(String? loc) => switch (loc) {
        'frigorifero' => _c('storage_tips.storage_group.frigorifero'),
        'temperatura_ambiente' => _c('storage_tips.storage_group.temperatura_ambiente'),
        'luogo_fresco_buio' => _c('storage_tips.storage_group.luogo_fresco_buio'),
        _ => _c('storage_tips.storage_group.other'),
      };
  String idealTemp(String range) => _c('storage_tips.ideal_temp', {'range': range});
  String chillingAlert(String? temp) => temp == null
      ? _c('storage_tips.chilling_alert')
      : _c('storage_tips.chilling_alert_with_temp', {'temp': temp});
  String get fromYourList => _c('storage_tips.from_your_list');
  String get otherFoods => _c('storage_tips.other_foods');
  String get openFullSheet => _c('storage_tips.open_full_sheet');

  String get about => _c('settings.about');
  String get sustainableDiet => _c('settings.sustainable_diet');
  String get sustainableDietSub =>
      _c('settings.sustainable_diet_sub');
  String get keyPoints => _c('settings.key_points');
  String get source => _c('settings.source');
  String databaseVersion(String v, int n) =>
      _c('settings.database_version', {'v': v, 'n': n});

  // --- Scheda alimento ----------------------------------------------------
  String get storage => _c('detail.storage');
  String get ripening => _c('detail.ripening');
  String get seasonCalendar => _c('detail.season_calendar');
  String get photo => _c('detail.photo');
  String get learnMore => _c('detail.learn_more');
  String get sources => _c('detail.sources');
  String get seeAlso => _c('detail.see_also');

  // --- Product page sections ----------------------------------------------
  String sectionTitle(DetailSection d) => switch (d) {
        DetailSection.calendar => seasonCalendar,
        DetailSection.varieties => secVarieties,
        DetailSection.buyStore => secBuyStore,
        DetailSection.nutrition => secNutrition,
        DetailSection.sustainability => secSustainability,
        DetailSection.garden => secGarden,
        DetailSection.curiosities => secCuriosities,
        DetailSection.recipes => secRecipes,
        DetailSection.links => secLinks,
      };
  String sectionMode(SectionMode m) => switch (m) {
        SectionMode.open => _c('settings.section_mode.open'),
        SectionMode.collapsed => _c('settings.section_mode.collapsed'),
        SectionMode.hidden => _c('settings.section_mode.hidden'),
      };
  String familyCount(int n, String month) => _c('detail.family_count', {'n': n, 'month': month});
  String get secFoodPage => _c('settings.sec_food_page');
  String get detailSections => _c('settings.detail_sections');
  String get detailSectionsSub => _c('settings.detail_sections_sub');
  String get detailSectionsHint => _c('settings.detail_sections_hint');
  String get restoreDefaults => _c('settings.restore_defaults');
  String get secVarieties => _c('detail.sec_varieties');
  String get secBuyStore =>
      _c('detail.sec_buy_store');
  String get secNutrition => _c('detail.sec_nutrition');
  String get secSustainability => _c('detail.sec_sustainability');
  String get secGarden => _c('detail.sec_garden');
  String get secCuriosities => _c('detail.sec_curiosities');
  String get secLinks => _c('detail.sec_links');
  String get curveBasisTitle => _c('detail.curve_basis_title');
  String get secRecipes => _c('detail.sec_recipes');
  String get recipesSoon =>
      _c('detail.recipes_soon');
  String get notableVarieties => _c('detail.notable_varieties');
  String get dopIgp => _c('detail.dop_igp');
  String patCount(int n, int regions) => _c('detail.pat_count', {'n': n, 'regions': regions});
  String get ripeningSpeedUp => _c('detail.ripening_speed_up');
  String get ripeningSlowDown => _c('detail.ripening_slow_down');
  String get whereToStore => _c('detail.where_to_store');
  String get howLong => _c('detail.how_long');
  String get roomTemp => _c('detail.room_temp');
  String get fridge => _c('detail.fridge');
  String get freezer => _c('detail.freezer');
  String days(String v) => _c('detail.days', {'v': v});
  String months(String v) => _c('detail.months', {'v': v});
  String get untilRipe => _c('detail.until_ripe');
  String get perishability => _c('detail.perishability');
  String get keepAwayFrom => _c('detail.keep_away_from');
  String get per100g => _c('detail.per100g');
  String get carbs => _c('detail.carbs');
  String get sugars => _c('detail.sugars');
  String get proteins => _c('detail.proteins');
  String get fats => _c('detail.fats');
  String get fiber => _c('detail.fiber');
  String get nutritionClaims => _c('detail.nutrition_claims');
  String get vitaminsMinerals =>
      _c('detail.vitamins_minerals');
  String get carbonFootprint => _c('detail.carbon_footprint');
  String get waterFootprint => _c('detail.water_footprint');
  String timesLowerBeef(int c) =>
      _c('detail.times_lower_beef', {'c': c});
  String get sowing => _c('detail.sowing');
  String get harvest => _c('detail.harvest');
  String get antiWaste => _c('detail.anti_waste');
  String get curiosities => _c('detail.curiosities');
  String get otherCategories => _c('home.category_other');
  String carbonTag(String level) => _c('home.tag_carbon', {'level': level});
  String waterTag(String level) => _c('home.tag_water', {'level': level});
  String get seedbedSowing => _c('detail.seedbed_sowing');
  String get directSowing => _c('detail.direct_sowing');
  String get transplant => _c('detail.transplant');
  String get paletteTopColor => _c('settings.palette_top_color');
  String get paletteBottomColor => _c('settings.palette_bottom_color');
  String appVersionLabel(String v) => _c('settings.app_version', {'v': v});
  String get githubApp => _c('settings.github_app');
  String get githubAppSub => _c('settings.github_app_sub');
  String get githubDatabase => _c('settings.github_database');
  String get githubDatabaseSub => _c('settings.github_database_sub');
  String get licenseTitle => _c('settings.license_title');
  String get licenseSub => _c('settings.license_sub');
}

extension StringsX on BuildContext {
  S get s => S.of(this);
}
