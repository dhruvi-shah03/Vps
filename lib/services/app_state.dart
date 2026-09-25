import 'package:flutter/material.dart';
import '../core/config/app_config.dart';
import '../core/error/app_exceptions.dart';
import '../models/app_models.dart';
import '../repositories/interfaces/app_repositories.dart';
import '../repositories/mock/mock_repositories.dart';
import '../repositories/odoo/odoo_repositories.dart';
import 'odoo_client.dart';
import 'report_service.dart';
import '../core/storage/secure_storage_service.dart';

class AppState extends ChangeNotifier {
  static AppState? _instance;
  static AppState get instance => _instance ??= AppState();

  final OdooClient odooClient = OdooClient(
    baseUrl: AppConfig.odooBaseUrl,
    dbName: AppConfig.odooDatabase,
  );

  late final ReportService reportService = ReportService(odooClient);

  bool isOdooBackend = true; // Default to live Odoo backend

  // Repositories
  late AuthRepository authRepository;
  late MahatmaRepository mahatmaRepository;
  late ViharRepository viharRepository;
  late ViharRouteRepository viharRouteRepository;
  late SamudayRepository samudayRepository;
  late DistrictRepository districtRepository;
  late DistrictInchargeRepository districtInchargeRepository;
  late StateRepository stateRepository;
  late SalutationRepository salutationRepository;
  late UserRepository userRepository;
  late VillageRepository villageRepository;

  // Live state cache
  UserModel? currentUser;
  List<Mahatma> mahatmas = [];
  List<Vihar> vihars = [];
  List<ViharRoute> routes = [];
  List<Samuday> samudays = [];
  List<District> districts = [];
  List<Village> villages = [];
  List<DistrictIncharge> incharges = [];
  List<StateModel> states = [];
  List<Salutation> salutations = [];
  List<UserModel> users = [];

  bool isLoading = false;
  String? lastErrorMessage;
  bool isDarkMode = false;
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

  AppState() {
    _instance = this;
    _initRepositories();
    if (odooClient.isAuthenticated) {
      loadAllData();
    }
  }

  void _initRepositories() {
    if (isOdooBackend) {
      authRepository = OdooAuthRepository(odooClient);
      mahatmaRepository = OdooMahatmaRepository(odooClient);
      viharRepository = OdooViharRepository(odooClient);
      viharRouteRepository = OdooViharRouteRepository(odooClient);
      samudayRepository = OdooSamudayRepository(odooClient);
      districtRepository = OdooDistrictRepository(odooClient);
      districtInchargeRepository = OdooDistrictInchargeRepository(odooClient);
      stateRepository = OdooStateRepository(odooClient);
      salutationRepository = OdooSalutationRepository(odooClient);
      userRepository = OdooUserRepository(odooClient);
      villageRepository = OdooVillageRepository(odooClient);
    } else {
      authRepository = MockAuthRepository();
      mahatmaRepository = MockMahatmaRepository();
      viharRepository = MockViharRepository();
      viharRouteRepository = MockViharRouteRepository();
      samudayRepository = MockSamudayRepository();
      districtRepository = MockDistrictRepository();
      districtInchargeRepository = MockDistrictInchargeRepository();
      stateRepository = MockStateRepository();
      salutationRepository = MockSalutationRepository();
      userRepository = MockUserRepository();
      villageRepository = MockVillageRepository();
    }
  }

  void toggleBackendMode(bool live) {
    isOdooBackend = live;
    _initRepositories();
    loadAllData();
  }

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    themeModeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  /// Load all data directly from backend without silent mock fallback
  Future<void> loadAllData() async {
    isLoading = true;
    lastErrorMessage = null;
    notifyListeners();

    try {
      try {
        currentUser = await authRepository.getCurrentUser();
      } catch (e) {
        debugPrint('[AppState] getCurrentUser error: $e');
      }
      
      // Load all lists concurrently with independent error guards
      final results = await Future.wait([
        mahatmaRepository.getMahatmas().catchError((e) {
          debugPrint('[AppState] getMahatmas error: $e');
          return <Mahatma>[];
        }),
        viharRepository.getVihars().catchError((e) {
          debugPrint('[AppState] getVihars error: $e');
          return <Vihar>[];
        }),
        viharRouteRepository.getViharRoutes().catchError((e) {
          debugPrint('[AppState] getViharRoutes error: $e');
          return <ViharRoute>[];
        }),
        samudayRepository.getSamudays().catchError((e) {
          debugPrint('[AppState] getSamudays error: $e');
          return <Samuday>[];
        }),
        districtRepository.getDistricts().catchError((e) {
          debugPrint('[AppState] getDistricts error: $e');
          return <District>[];
        }),
        districtInchargeRepository.getDistrictIncharges().catchError((e) {
          debugPrint('[AppState] getDistrictIncharges error: $e');
          return <DistrictIncharge>[];
        }),
        stateRepository.getStates().catchError((e) {
          debugPrint('[AppState] getStates error: $e');
          return <StateModel>[];
        }),
        salutationRepository.getSalutations().catchError((e) {
          debugPrint('[AppState] getSalutations error: $e');
          return <Salutation>[];
        }),
        userRepository.getUsers().catchError((e) {
          debugPrint('[AppState] getUsers error: $e');
          return <UserModel>[];
        }),
        villageRepository.getVillages().catchError((e) {
          debugPrint('[AppState] getVillages error: $e');
          return <Village>[];
        }),
      ]);

      mahatmas = results[0] as List<Mahatma>;
      vihars = results[1] as List<Vihar>;
      routes = results[2] as List<ViharRoute>;
      samudays = results[3] as List<Samuday>;
      districts = results[4] as List<District>;
      incharges = results[5] as List<DistrictIncharge>;
      states = results[6] as List<StateModel>;
      salutations = results[7] as List<Salutation>;
      users = results[8] as List<UserModel>;
      villages = results[9] as List<Village>;

      // Cross-link vihars and routes to ensure startLocation, endLocation and routes are populated
      for (int i = 0; i < vihars.length; i++) {
        final v = vihars[i];
        List<ViharRoute> currentRoutes = List.from(v.routes);
        if (currentRoutes.isEmpty) {
          final matchingRoutes = routes.where((r) => r.viharId == v.id).toList();
          if (matchingRoutes.isNotEmpty) {
            currentRoutes = matchingRoutes;
          }
        }
        String sLoc = v.startLocation;
        String eLoc = v.endLocation;
        if (sLoc.isEmpty && currentRoutes.isNotEmpty) {
          sLoc = currentRoutes.first.fromLocation;
        }
        if (eLoc.isEmpty && currentRoutes.isNotEmpty) {
          eLoc = currentRoutes.last.toLocation;
        }
        vihars[i] = v.copyWith(
          routes: currentRoutes,
          startLocation: sLoc,
          endLocation: eLoc,
        );
      }

      final viharMap = {for (var v in vihars) v.id: v};
      for (int i = 0; i < routes.length; i++) {
        final r = routes[i];
        if (r.viharName.isEmpty && viharMap.containsKey(r.viharId)) {
          routes[i] = r.copyWith(viharName: viharMap[r.viharId]!.mahatmaName);
        }
      }

      lastErrorMessage = null;
    } on OdooException catch (e) {
      lastErrorMessage = e.userFriendlyMessage;
    } catch (e) {
      lastErrorMessage = 'Failed to load data: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- Auth Actions ---
  Future<void> initSession() async {
    odooClient.restoreSession();
    if (odooClient.isAuthenticated) {
      currentUser = await authRepository.getCurrentUser();
      loadAllData();
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    isLoading = true;
    lastErrorMessage = null;
    notifyListeners();

    try {
      final success = await authRepository.login(username, password);
      if (success) {
        currentUser = await authRepository.getCurrentUser();
        await loadAllData();
        return true;
      } else {
        lastErrorMessage = 'Invalid credentials.';
        return false;
      }
    } on OdooException catch (e) {
      lastErrorMessage = e.userFriendlyMessage;
      return false;
    } catch (e) {
      lastErrorMessage = 'Authentication failed: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await authRepository.logout();
    await SecureStorageService.clearSession();
    currentUser = null;
    mahatmas.clear();
    vihars.clear();
    routes.clear();
    notifyListeners();
  }

  // --- Mahatma CRUD ---
  Future<void> addMahatma(Mahatma m) async {
    final cleanCode = m.code.trim().toLowerCase();
    if (cleanCode.isNotEmpty && mahatmas.any((x) => x.code.trim().toLowerCase() == cleanCode)) {
      throw Exception('Mahatma code "${m.code}" already exists. Code must be unique.');
    }
    await mahatmaRepository.addMahatma(m);
    await refreshMahatmas();
  }

  Future<void> updateMahatma(Mahatma m) async {
    final cleanCode = m.code.trim().toLowerCase();
    if (cleanCode.isNotEmpty && mahatmas.any((x) => x.id != m.id && x.code.trim().toLowerCase() == cleanCode)) {
      throw Exception('Mahatma code "${m.code}" already exists. Code must be unique.');
    }
    await mahatmaRepository.updateMahatma(m);
    await refreshMahatmas();
  }

  Future<void> deleteMahatma(String id) async {
    await mahatmaRepository.deleteMahatma(id);
    await refreshMahatmas();
  }

  Future<void> refreshMahatmas() async {
    mahatmas = await mahatmaRepository.getMahatmas();
    notifyListeners();
  }

  // --- Vihar CRUD ---
  Future<void> addVihar(Vihar v) async {
    await viharRepository.addVihar(v);
    await refreshVihars();
    await refreshRoutes();
  }

  Future<void> updateVihar(Vihar v) async {
    final idx = vihars.indexWhere((x) => x.id == v.id);
    if (idx != -1) {
      vihars[idx] = v;
      notifyListeners();
    }
    try {
      await viharRepository.updateVihar(v);
    } catch (e) {
      debugPrint('[AppState] updateVihar error: $e');
    }
    await refreshVihars();
    await refreshRoutes();
  }

  Future<void> deleteVihar(String id) async {
    vihars.removeWhere((v) => v.id == id);
    routes.removeWhere((r) => r.viharId == id);
    notifyListeners();
    try {
      await viharRepository.deleteVihar(id);
    } finally {
      await refreshVihars();
      await refreshRoutes();
    }
  }

  Future<void> refreshVihars() async {
    vihars = await viharRepository.getVihars();
    for (int i = 0; i < vihars.length; i++) {
      final v = vihars[i];
      List<ViharRoute> currentRoutes = List.from(v.routes);
      if (currentRoutes.isEmpty) {
        final matchingRoutes = routes.where((r) => r.viharId == v.id).toList();
        if (matchingRoutes.isNotEmpty) {
          currentRoutes = matchingRoutes;
        }
      }
      String sLoc = v.startLocation;
      String eLoc = v.endLocation;
      if (sLoc.isEmpty && currentRoutes.isNotEmpty) {
        sLoc = currentRoutes.first.fromLocation;
      }
      if (eLoc.isEmpty && currentRoutes.isNotEmpty) {
        eLoc = currentRoutes.last.toLocation;
      }
      vihars[i] = v.copyWith(
        routes: currentRoutes,
        startLocation: sLoc,
        endLocation: eLoc,
      );
    }
    notifyListeners();
  }

  // --- Vihar Route CRUD ---
  Future<void> addViharRoute(ViharRoute r) async {
    await viharRouteRepository.addViharRoute(r);
    await refreshRoutes();
  }

  Future<void> updateViharRoute(ViharRoute r) async {
    await viharRouteRepository.updateViharRoute(r);
    await refreshRoutes();
  }

  Future<void> deleteViharRoute(String id) async {
    routes.removeWhere((r) => r.id == id);
    for (int i = 0; i < vihars.length; i++) {
      if (vihars[i].routes.any((r) => r.id == id)) {
        vihars[i] = vihars[i].copyWith(
          routes: vihars[i].routes.where((r) => r.id != id).toList(),
        );
      }
    }
    notifyListeners();
    try {
      await viharRouteRepository.deleteViharRoute(id);
    } finally {
      await refreshRoutes();
      await refreshVihars();
    }
  }

  Future<void> refreshRoutes() async {
    routes = await viharRouteRepository.getViharRoutes();
    final viharMap = {for (var v in vihars) v.id: v};
    for (int i = 0; i < routes.length; i++) {
      final r = routes[i];
      if (r.viharName.isEmpty && viharMap.containsKey(r.viharId)) {
        routes[i] = r.copyWith(viharName: viharMap[r.viharId]!.mahatmaName);
      }
    }
    for (int i = 0; i < vihars.length; i++) {
      final v = vihars[i];
      if (v.routes.isEmpty || v.startLocation.isEmpty || v.endLocation.isEmpty) {
        final matchingRoutes = routes.where((r) => r.viharId == v.id).toList();
        if (matchingRoutes.isNotEmpty) {
          vihars[i] = v.copyWith(
            routes: v.routes.isEmpty ? matchingRoutes : v.routes,
            startLocation: v.startLocation.isNotEmpty ? v.startLocation : matchingRoutes.first.fromLocation,
            endLocation: v.endLocation.isNotEmpty ? v.endLocation : matchingRoutes.last.toLocation,
          );
        }
      }
    }
    notifyListeners();
  }

  // --- Master Data CRUD ---
  Future<void> addSamuday(Samuday s) async {
    await samudayRepository.addSamuday(s);
    samudays = await samudayRepository.getSamudays();
    notifyListeners();
  }

  Future<void> updateSamuday(Samuday s) async {
    await samudayRepository.updateSamuday(s);
    samudays = await samudayRepository.getSamudays();
    notifyListeners();
  }

  Future<void> deleteSamuday(String id) async {
    await samudayRepository.deleteSamuday(id);
    samudays = await samudayRepository.getSamudays();
    notifyListeners();
  }

  Future<void> addDistrict(District d) async {
    await districtRepository.addDistrict(d);
    districts = await districtRepository.getDistricts();
    notifyListeners();
  }

  Future<void> updateDistrict(District d) async {
    await districtRepository.updateDistrict(d);
    districts = await districtRepository.getDistricts();
    notifyListeners();
  }

  Future<void> deleteDistrict(String id) async {
    await districtRepository.deleteDistrict(id);
    districts = await districtRepository.getDistricts();
    notifyListeners();
  }

  Future<void> addDistrictIncharge(DistrictIncharge di) async {
    await districtInchargeRepository.addDistrictIncharge(di);
    incharges = await districtInchargeRepository.getDistrictIncharges();
    notifyListeners();
  }

  Future<void> updateDistrictIncharge(DistrictIncharge di) async {
    await districtInchargeRepository.updateDistrictIncharge(di);
    incharges = await districtInchargeRepository.getDistrictIncharges();
    notifyListeners();
  }

  Future<void> deleteDistrictIncharge(String id) async {
    await districtInchargeRepository.deleteDistrictIncharge(id);
    incharges = await districtInchargeRepository.getDistrictIncharges();
    notifyListeners();
  }

  Future<void> addState(StateModel s) async {
    await stateRepository.addState(s);
    states = await stateRepository.getStates();
    notifyListeners();
  }

  Future<void> updateState(StateModel s) async {
    await stateRepository.updateState(s);
    states = await stateRepository.getStates();
    notifyListeners();
  }

  Future<void> deleteState(String id) async {
    await stateRepository.deleteState(id);
    states = await stateRepository.getStates();
    notifyListeners();
  }

  Future<void> addSalutation(Salutation s) async {
    await salutationRepository.addSalutation(s);
    salutations = await salutationRepository.getSalutations();
    notifyListeners();
  }

  Future<void> updateSalutation(Salutation s) async {
    await salutationRepository.updateSalutation(s);
    salutations = await salutationRepository.getSalutations();
    notifyListeners();
  }

  Future<void> deleteSalutation(String id) async {
    await salutationRepository.deleteSalutation(id);
    salutations = await salutationRepository.getSalutations();
    notifyListeners();
  }

  Future<void> addUser(UserModel u) async {
    await userRepository.addUser(u);
    users = await userRepository.getUsers();
    notifyListeners();
  }

  Future<void> updateUser(UserModel u) async {
    await userRepository.updateUser(u);
    users = await userRepository.getUsers();
    notifyListeners();
  }

  Future<void> deleteUser(String id) async {
    await userRepository.deleteUser(id);
    users = await userRepository.getUsers();
    notifyListeners();
  }

  // --- Villages ---
  Future<void> refreshVillages() async {
    try {
      if (districts.isEmpty) {
        districts = await districtRepository.getDistricts();
      }
      final fetched = await villageRepository.getVillages();
      villages = fetched;
      notifyListeners();
    } catch (e) {
      debugPrint('[AppState] refreshVillages error: $e');
    }
  }

  Future<void> addVillage(Village v) async {
    await villageRepository.addVillage(v);
    villages = await villageRepository.getVillages();
    notifyListeners();
  }

  Future<void> updateVillage(Village v) async {
    await villageRepository.updateVillage(v);
    villages = await villageRepository.getVillages();
    notifyListeners();
  }

  Future<void> deleteVillage(String id) async {
    await villageRepository.deleteVillage(id);
    villages = await villageRepository.getVillages();
    notifyListeners();
  }

  // --- Reports ---
  Future<List<int>> downloadReport(int viharId, ViharReportLanguage lang) async {
    return await reportService.fetchViharReport(viharId: viharId, language: lang);
  }

  Future<List<int>> downloadRouteReport({
    required List<int> routeIds,
    required ViharReportLanguage lang,
    List<ViharRoute>? routesForFallback,
  }) async {
    return await reportService.fetchRouteReport(
      routeIds: routeIds,
      language: lang,
      routesForFallback: routesForFallback ?? routes,
      vihars: vihars,
      mahatmas: mahatmas,
    );
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    try {
      final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
      if (scope?.notifier != null) {
        return scope!.notifier!;
      }
    } catch (_) {}
    return AppState.instance;
  }

  static AppState? maybeOf(BuildContext context) {
    try {
      final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
      return scope?.notifier ?? AppState._instance;
    } catch (_) {
      return AppState._instance;
    }
  }
}
