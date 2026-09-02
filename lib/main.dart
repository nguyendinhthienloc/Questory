import 'package:flutter/material.dart';

import 'app/app_dependencies.dart';
import 'app/main_navigation.dart';
import 'features/destinations/presentation/explore_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QuestoryBootstrap());
}

class QuestoryBootstrap extends StatefulWidget {
  const QuestoryBootstrap({super.key});

  @override
  State<QuestoryBootstrap> createState() => _QuestoryBootstrapState();
}

class _QuestoryBootstrapState extends State<QuestoryBootstrap> {
  late Future<AppDependencies> _dependencies = AppDependencies.create();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppDependencies>(
      future: _dependencies,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const QuestoryApp(home: _StartupLoading());
        }
        if (snapshot.hasError) {
          return QuestoryApp(
            home: _StartupError(
              message: '${snapshot.error}',
              onRetry: () => setState(
                () => _dependencies = AppDependencies.create(),
              ),
            ),
          );
        }
        return QuestoryApp(dependencies: snapshot.data!);
      },
    );
  }
}

class QuestoryApp extends StatelessWidget {
  const QuestoryApp({super.key, this.dependencies, this.home});

  final AppDependencies? dependencies;
  final Widget? home;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Questory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Noto Sans',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B7A75),
          surface: QuestoryColors.paper,
        ),
        useMaterial3: true,
      ),
      home: home ??
          (dependencies == null
              ? const ExploreScreen()
              : MainNavigation(dependencies: dependencies!)),
    );
  }
}

class _StartupLoading extends StatelessWidget {
  const _StartupLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: QuestoryColors.paper,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuestoryColors.paper,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storage_rounded, size: 52),
              const SizedBox(height: 14),
              const Text(
                'Questory could not open local storage',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('TRY AGAIN')),
            ],
          ),
        ),
      ),
    );
  }
}
