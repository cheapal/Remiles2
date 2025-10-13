import 'package:flutter/foundation.dart';

class AppStateProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _loadingMessage;
  String? _errorMessage;
  bool _isOnboardingComplete = false;
  int _currentOnboardingStep = 0;
  Map<String, dynamic> _temporaryData = {};

  // Getters
  bool get isLoading => _isLoading;
  String? get loadingMessage => _loadingMessage;
  String? get errorMessage => _errorMessage;
  bool get isOnboardingComplete => _isOnboardingComplete;
  int get currentOnboardingStep => _currentOnboardingStep;
  Map<String, dynamic> get temporaryData => Map.unmodifiable(_temporaryData);

  // Loading state management
  void setLoading(bool loading, {String? message}) {
    _isLoading = loading;
    _loadingMessage = message;
    notifyListeners();
  }

  void clearLoading() {
    _isLoading = false;
    _loadingMessage = null;
    notifyListeners();
  }

  // Error state management
  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Onboarding state management
  void setOnboardingComplete(bool complete) {
    _isOnboardingComplete = complete;
    notifyListeners();
  }

  void setCurrentOnboardingStep(int step) {
    _currentOnboardingStep = step;
    notifyListeners();
  }

  void nextOnboardingStep() {
    _currentOnboardingStep++;
    notifyListeners();
  }

  void previousOnboardingStep() {
    if (_currentOnboardingStep > 0) {
      _currentOnboardingStep--;
      notifyListeners();
    }
  }

  void resetOnboarding() {
    _isOnboardingComplete = false;
    _currentOnboardingStep = 0;
    notifyListeners();
  }

  // Temporary data management
  void setTemporaryData(String key, dynamic value) {
    _temporaryData[key] = value;
    notifyListeners();
  }

  void removeTemporaryData(String key) {
    _temporaryData.remove(key);
    notifyListeners();
  }

  void clearTemporaryData() {
    _temporaryData.clear();
    notifyListeners();
  }

  T? getTemporaryData<T>(String key) {
    return _temporaryData[key] as T?;
  }

  // Reset all state
  void reset() {
    _isLoading = false;
    _loadingMessage = null;
    _errorMessage = null;
    _isOnboardingComplete = false;
    _currentOnboardingStep = 0;
    _temporaryData.clear();
    notifyListeners();
  }

  // Utility methods
  void showLoadingWithMessage(String message) {
    setLoading(true, message: message);
  }

  void showError(String error) {
    clearLoading();
    setError(error);
  }

  void showSuccess() {
    clearLoading();
    clearError();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
