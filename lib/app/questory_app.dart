import 'package:flutter/material.dart';

import '../core/contracts/story_repository.dart';
import '../core/fixtures/fake_story_services.dart';
import 'presentation/questory_demo_shell.dart';
import 'questory_theme.dart';

class QuestoryStoryDemoApp extends StatefulWidget {
  const QuestoryStoryDemoApp({super.key, this.storyRepository});

  final StoryRepository? storyRepository;

  @override
  State<QuestoryStoryDemoApp> createState() => _QuestoryStoryDemoAppState();
}

class _QuestoryStoryDemoAppState extends State<QuestoryStoryDemoApp> {
  late final StoryRepository _storyRepository;

  @override
  void initState() {
    super.initState();
    _storyRepository = widget.storyRepository ?? FakeStoryRepository();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Questory',
      debugShowCheckedModeBanner: false,
      theme: buildQuestoryTheme(),
      home: QuestoryDemoShell(repository: _storyRepository),
    );
  }
}
