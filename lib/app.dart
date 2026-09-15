import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/env.dart';
import 'screens/app_shell.dart';
import 'screens/auth_screen.dart';
import 'state/providers.dart';
import 'theme/pixel_colors.dart';
import 'theme/pixel_text.dart';
import 'widgets/pixel_toast.dart';

class PixelBookJournalApp extends StatelessWidget {
  const PixelBookJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '픽셀 책방 일지',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Galmuri11',
        scaffoldBackgroundColor: PixelColors.phoneBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: PixelColors.wood,
          surface: PixelColors.phoneBg,
        ),
      ),
      home: PixelToastHost(
        child: Env.isConfigured ? const _AuthGate() : const _MissingConfigScreen(),
      ),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    return userId == null ? const AuthScreen() : const AppShell();
  }
}

class _MissingConfigScreen extends StatelessWidget {
  const _MissingConfigScreen();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: PixelColors.canvasSurround,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Supabase 설정이 필요해요', style: PixelText.style(size: 15, color: PixelColors.accentPale)),
              const SizedBox(height: 12),
              Text(
                'SUPABASE_URL / SUPABASE_ANON_KEY 를 --dart-define 으로 넘겨서 실행하세요.\n자세한 방법은 README.md를 확인하세요.',
                textAlign: TextAlign.center,
                style: PixelText.style(size: 11, color: PixelColors.paperTaupe, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
