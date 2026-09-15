import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import '../theme/pixel_colors.dart';
import '../theme/pixel_decorations.dart';
import '../theme/pixel_text.dart';
import '../widgets/pixel_button.dart';
import '../widgets/pixel_toast.dart';

/// Not part of the original prototype — Claude Design's mock had no login
/// screen because it ran against fake in-memory data. A real Supabase
/// backend needs an account, so this adds the minimum sign-in/sign-up
/// screen in the same pixel language as the rest of the app.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _signUp = false;
  bool _busy = false;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      PixelToastHost.of(context).show('이메일과 비밀번호를 입력하세요');
      return;
    }
    setState(() => _busy = true);
    try {
      final auth = ref.read(authRepositoryProvider);
      if (_signUp) {
        final name = _displayName.text.trim().isEmpty ? '이름 없는 독자' : _displayName.text.trim();
        await auth.signUp(email: email, password: password, displayName: name);
        if (mounted) {
          PixelToastHost.of(context).show('가입 완료 · 확인 메일을 확인해주세요');
        }
      } else {
        await auth.signIn(email: email, password: password);
      }
    } catch (e) {
      if (mounted) PixelToastHost.of(context).show('문제가 생겼어요: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PixelColors.canvasSurround,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(20),
            decoration: pixelBox(background: PixelColors.paper, borderWidth: 4, shadowOffset: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('픽셀 책방 일지', style: PixelText.style(size: 18, color: PixelColors.wood)),
                const SizedBox(height: 4),
                Text(
                  _signUp ? '서관에 새 열람증을 만들어요' : '서관 열람증으로 들어가요',
                  style: PixelText.style(size: 11, color: PixelColors.textMuted),
                ),
                const SizedBox(height: 20),
                if (_signUp) ...[
                  _Field(label: '이름', controller: _displayName, hint: '도윤'),
                  const SizedBox(height: 12),
                ],
                _Field(label: '이메일', controller: _email, hint: 'you@example.com'),
                const SizedBox(height: 12),
                _Field(label: '비밀번호', controller: _password, hint: '8자 이상', obscure: true),
                const SizedBox(height: 20),
                PixelButton(
                  background: PixelColors.moss,
                  foreground: PixelColors.mossOnDark,
                  height: 50,
                  shadowOffset: 4,
                  onTap: _submit,
                  child: Text(_busy ? '처리 중…' : (_signUp ? '가입하기' : '들어가기'), style: PixelText.style(size: 13, color: PixelColors.mossOnDark)),
                ),
                const SizedBox(height: 10),
                PixelButton(
                  background: PixelColors.paper,
                  shadowOffset: 0,
                  height: 40,
                  onTap: _busy ? null : () => setState(() => _signUp = !_signUp),
                  child: Text(
                    _signUp ? '이미 열람증이 있어요' : '처음이에요 · 열람증 만들기',
                    style: PixelText.style(size: 11, color: PixelColors.accent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool obscure;

  const _Field({required this.label, required this.controller, required this.hint, this.obscure = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: PixelText.style(size: 11, color: PixelColors.textMuted)),
        const SizedBox(height: 6),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: PixelColors.paper,
            border: Border.all(color: PixelColors.inkBorder, width: kPixelBorder),
          ),
          alignment: Alignment.centerLeft,
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: PixelText.style(size: 12),
            decoration: InputDecoration.collapsed(
              hintText: hint,
              hintStyle: PixelText.style(size: 12, color: PixelColors.paperFaint),
            ),
          ),
        ),
      ],
    );
  }
}
