import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/receipt_studio/presentation/receipt_studio_page.dart';

class ReceiptStudioApp extends StatelessWidget {
  const ReceiptStudioApp({super.key});

  static final GoRouter _router = GoRouter(
    initialLocation: AppSection.workspace.path,
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, state) => AppSection.workspace.path,
      ),
      for (final section in AppSection.values)
        GoRoute(
          path: section.path,
          pageBuilder: (context, state) => NoTransitionPage<void>(
            key: const ValueKey('receipt-studio-shell'),
            child: ReceiptStudioPage(section: section),
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Receipt Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF18181B),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F7F8),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF18181B),
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF18181B),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Color(0xFF3F3F46),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            borderSide: BorderSide(color: Color(0xFFE4E4E7)),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            borderSide: BorderSide(color: Color(0xFFE4E4E7)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            borderSide: BorderSide(color: Color(0xFF18181B), width: 1.4),
          ),
          filled: true,
          fillColor: const Color(0xFFFCFCFD),
          labelStyle: const TextStyle(color: Color(0xFF71717A)),
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0.5,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
            side: BorderSide(color: Color(0xFFE4E4E7)),
          ),
        ),
        dividerColor: const Color(0xFFE4E4E7),
      ),
      routerConfig: _router,
    );
  }
}

enum AppSection {
  workspace(
    path: '/workspace',
    title: 'Workspace',
    subtitle: 'Edit receipts and preview PDF output in real time',
    icon: CupertinoIcons.square_grid_2x2,
  ),
  vault(
    path: '/vault',
    title: 'Receipt Vault',
    subtitle: 'Manage saved receipts and workspace snapshots',
    icon: CupertinoIcons.archivebox,
  ),
  templates(
    path: '/templates',
    title: 'Templates',
    subtitle: 'Reuse payee and payer templates',
    icon: CupertinoIcons.bookmark,
  );

  const AppSection({
    required this.path,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String path;
  final String title;
  final String subtitle;
  final IconData icon;
}
