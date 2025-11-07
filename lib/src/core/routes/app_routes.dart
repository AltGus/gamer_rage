// core/routes/app_routes.dart

import 'package:flutter/material.dart';
import 'package:gamer_rage/src/presentation/pages/app_shell.dart';
import 'package:gamer_rage/src/presentation/pages/login_page.dart';
import 'package:gamer_rage/src/presentation/pages/register_page.dart';
import 'package:gamer_rage/src/presentation/pages/home_page.dart';
import 'package:gamer_rage/src/presentation/pages/notifications_page.dart';
import 'package:gamer_rage/src/presentation/pages/search_results_page.dart';

class AppRoutes {
  // Rotas de Autenticação
  static const String login = '/login';
  static const String register = '/register';

  // Rotas Principais
  static const String appShell = '/appShell';
  static const String home = '/home';
  static const String notifications = '/notifications';

  // Rotas de Conteúdo
  static const String gameDetails = '/gameDetails';
  static const String search = '/search';

  /// Mapa com as rotas nomeadas do app
  static Map<String, WidgetBuilder> defineRoutes() {
    return {
      // 🔐 Autenticação
      login: (context) => const LoginPage(),
      register: (context) => const RegisterPage(),

      // 🧭 Estrutura principal do app
      appShell: (context) => const AppShell(),

      // 🏠 Páginas internas
      home: (context) => const AppShell(),
      notifications: (context) => const AppShell(),

      // 🔍 Página de busca (recebe argumento da SearchBar)
      search: (context) {
        final query = ModalRoute.of(context)!.settings.arguments as String;
        return SearchResultsPage(query: query);
      },
    };
  }
}
