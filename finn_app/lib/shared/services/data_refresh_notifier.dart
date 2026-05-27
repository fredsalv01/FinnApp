import 'package:flutter/foundation.dart';

/// Notifier global para forzar refresh de pantallas cuando los datos
/// (gastos, metas, aportes, perfil) cambian desde otra pantalla.
class DataRefreshNotifier extends ChangeNotifier {
  static final DataRefreshNotifier _instance = DataRefreshNotifier._();
  factory DataRefreshNotifier() => _instance;
  DataRefreshNotifier._();

  void refresh() => notifyListeners();
}
