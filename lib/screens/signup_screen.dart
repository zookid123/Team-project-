import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isEmailChecked = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // 이메일 중복 확인 로직 (최신 firebase_auth 호환)
  Future<void> _checkEmailDuplicate() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar('유효한 이메일을 입력해주세요.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // fetchSignInMethodsForEmail이 제거되었으므로,
      // 임시로 가짜 비밀번호로 계정 생성을 시도하여 이메일 존재 여부를 확인합니다.
      // 실제 앱에서는 Cloud Functions 등을 사용하는 것이 더 권장됩니다.
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: 'TemporaryPassword123!', 
      );
      // 생성 성공 시 바로 삭제하여 계정 생성을 취소합니다.
      await FirebaseAuth.instance.currentUser?.delete();
      
      if (!mounted) return;
      _showSnackBar('사용 가능한 이메일입니다!');
      setState(() => _isEmailChecked = true);

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      
      if (e.code == 'email-already-in-use') {
        _showSnackBar('이미 사용 중인 이메일입니다.');
        setState(() => _isEmailChecked = false);
      } else {
        // 기타 오류 (예: weak-password 등)가 발생해도 이메일 자체는 사용 가능하다고 간주
        _showSnackBar('사용 가능한 이메일입니다!');
        setState(() => _isEmailChecked = true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('확인 중 오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    if (!_isEmailChecked) {
      _showSnackBar('이메일 중복 확인을 먼저 해주세요.');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('비밀번호가 일치하지 않습니다.');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showSnackBar('비밀번호는 6자리 이상이어야 합니다.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 이미 중복확인을 통과했으므로 정상 가입 처리
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      if (!mounted) return;
      _showSnackBar('회원가입 성공! 모험을 시작합니다.');
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainHomeScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String message = '오류가 발생했습니다.';
      if (e.code == 'weak-password') {
        message = '비밀번호가 너무 취약합니다.';
      } else if (e.code == 'email-already-in-use') {
        message = '이미 사용 중인 이메일입니다.';
        setState(() => _isEmailChecked = false); // 다시 체크하도록 상태 변경
      }
      if (!mounted) return;
      _showSnackBar(message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white.withAlpha(204),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFFFB7B2), size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF9F5), Color(0xFFB5EAD7)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  Center(
                    child: Stack(
                      children: [
                        Text(
                          '회원가입',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 6
                              ..color = Colors.white,
                          ),
                        ),
                        const Text(
                          '회원가입',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFB5EAD7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // 이메일 입력 + 중복 확인 버튼
                  Row(
                    children: [
                      Expanded(
                        child: _buildRoundedTextField(
                          controller: _emailController,
                          hint: '이메일을 입력해주세요', 
                          icon: Icons.email_rounded,
                          onChanged: (val) => setState(() => _isEmailChecked = false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _checkEmailDuplicate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isEmailChecked ? Colors.grey : const Color(0xFFFFB7B2),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text(_isEmailChecked ? '확인됨' : '중복확인', style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildRoundedTextField(
                    controller: _passwordController,
                    hint: '비밀번호를 입력해주세요', 
                    icon: Icons.lock_rounded, 
                    isPassword: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: const Color(0xFFB5EAD7),
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRoundedTextField(
                    controller: _confirmPasswordController,
                    hint: '비밀번호를 다시 확인해주세요', 
                    icon: Icons.check_circle_rounded, 
                    isPassword: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: const Color(0xFFB5EAD7),
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFB5EAD7).withAlpha(102),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB5EAD7),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                          side: const BorderSide(color: Colors.white, width: 3),
                        ),
                      ),
                      child: _isLoading 
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('가입 완료!', style: TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoundedTextField({
    required TextEditingController controller,
    required String hint, 
    required IconData icon, 
    bool isPassword = false,
    Widget? suffixIcon,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFFB5EAD7)),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        ),
      ),
    );
  }
}
