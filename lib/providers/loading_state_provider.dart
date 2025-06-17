import 'package:flutter/foundation.dart';

enum DataLoadingStatus { initial, loading, loaded, error }

class ModuleLoadingState {
  final DataLoadingStatus status;
  final String? message;
  final DateTime lastUpdated;

  ModuleLoadingState({
    this.status = DataLoadingStatus.initial,
    this.message,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  ModuleLoadingState copyWith({
    DataLoadingStatus? status,
    String? message,
    DateTime? lastUpdated,
  }) {
    return ModuleLoadingState(
      status: status ?? this.status,
      message: message ?? this.message,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class LoadingStateProvider with ChangeNotifier {
  final Map<String, ModuleLoadingState> _moduleStates = {};
  bool _isInitializing = true;
  bool _allModulesReady = false;

  LoadingStateProvider() {
    registerModule('auth');
    registerModule('home');
    registerModule('tasks');
    registerModule('projects');
    registerModule('threads');
    registerModule('projectTasks');
  }

  bool get isInitializing => _isInitializing;
  bool get allModulesReady => _allModulesReady;

  Map<String, ModuleLoadingState> get moduleStates => _moduleStates;

  void registerModule(String moduleName) {
    if (!_moduleStates.containsKey(moduleName)) {
      _moduleStates[moduleName] = ModuleLoadingState();
    }
  }

  void setModuleLoading(String moduleName, {String? message}) {
    if (!_moduleStates.containsKey(moduleName)) {
      registerModule(moduleName);
    }

    _moduleStates[moduleName] = _moduleStates[moduleName]!.copyWith(
      status: DataLoadingStatus.loading,
      message: message ?? 'Loading...',
      lastUpdated: DateTime.now(),
    );

    _checkAllModulesStatus();
    notifyListeners();
  }

  void setModuleLoaded(String moduleName, {String? message}) {
    if (!_moduleStates.containsKey(moduleName)) {
      registerModule(moduleName);
    }

    _moduleStates[moduleName] = _moduleStates[moduleName]!.copyWith(
      status: DataLoadingStatus.loaded,
      message: message ?? 'Loaded successfully',
      lastUpdated: DateTime.now(),
    );

    _checkAllModulesStatus();
    notifyListeners();
  }

  void setModuleError(String moduleName, {required String message}) {
    if (!_moduleStates.containsKey(moduleName)) {
      registerModule(moduleName);
    }

    _moduleStates[moduleName] = _moduleStates[moduleName]!.copyWith(
      status: DataLoadingStatus.error,
      message: message,
      lastUpdated: DateTime.now(),
    );

    _checkAllModulesStatus();
    notifyListeners();
  }

  DataLoadingStatus getModuleStatus(String moduleName) {
    if (!_moduleStates.containsKey(moduleName)) {
      return DataLoadingStatus.initial;
    }
    return _moduleStates[moduleName]!.status;
  }

  bool isModuleLoading(String moduleName) {
    return getModuleStatus(moduleName) == DataLoadingStatus.loading;
  }

  bool isModuleLoaded(String moduleName) {
    return getModuleStatus(moduleName) == DataLoadingStatus.loaded;
  }

  bool isModuleError(String moduleName) {
    return getModuleStatus(moduleName) == DataLoadingStatus.error;
  }

  String? getModuleMessage(String moduleName) {
    if (!_moduleStates.containsKey(moduleName)) {
      return null;
    }
    return _moduleStates[moduleName]!.message;
  }

  DateTime? getLastUpdated(String moduleName) {
    if (!_moduleStates.containsKey(moduleName)) {
      return null;
    }
    return _moduleStates[moduleName]!.lastUpdated;
  }

  void _checkAllModulesStatus() {
    // Check if all registered modules are loaded
    bool allLoaded = _moduleStates.values.every(
      (state) => state.status == DataLoadingStatus.loaded,
    );

    bool anyError = _moduleStates.values.any(
      (state) => state.status == DataLoadingStatus.error,
    );

    // All modules are either loaded or in error state (but not loading/initial)
    _allModulesReady =
        _moduleStates.isNotEmpty &&
        !_moduleStates.values.any(
          (state) =>
              state.status == DataLoadingStatus.loading ||
              state.status == DataLoadingStatus.initial,
        );

    // No longer initializing if all modules are ready or any has error
    _isInitializing = !_allModulesReady && !anyError;
  }

  // Force refresh all modules
  void refreshAll() {
    for (var moduleName in _moduleStates.keys) {
      _moduleStates[moduleName] = _moduleStates[moduleName]!.copyWith(
        status: DataLoadingStatus.initial,
      );
    }
    _isInitializing = true;
    _allModulesReady = false;
    notifyListeners();
  }
}
