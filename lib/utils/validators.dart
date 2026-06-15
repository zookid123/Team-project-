/// 앱 전반에 사용되는 유효성 검증 유틸리티
/// Firebase 의존 없이 순수 Dart 로직만 포함 → 단위 테스트 가능
class Validators {
  /// 이메일 형식 검사
  /// - 비어있으면 false
  /// - '@' 미포함이면 false
  /// - '@' 앞뒤로 문자가 있어야 true
  static bool isValidEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return false;
    final atIndex = trimmed.indexOf('@');
    if (atIndex <= 0) return false;
    final domain = trimmed.substring(atIndex + 1);
    if (domain.isEmpty || !domain.contains('.')) return false;
    return true;
  }

  /// 비밀번호 길이 검사 (최소 6자)
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  /// 비밀번호 일치 여부 검사
  static bool doPasswordsMatch(String password, String confirm) {
    return password == confirm;
  }

  /// 닉네임 유효성 검사
  /// - 비어있거나 공백만 있으면 false
  /// - 10자 초과이면 false
  static bool isValidNickname(String nickname) {
    final trimmed = nickname.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.length > 10) return false;
    return true;
  }

  /// 회원가입 전체 유효성 검사 결과를 한 번에 반환
  static SignUpValidationResult validateSignUp({
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    if (!isValidEmail(email)) {
      return SignUpValidationResult.failure('유효한 이메일을 입력해주세요.');
    }
    if (!isValidPassword(password)) {
      return SignUpValidationResult.failure('비밀번호는 6자리 이상이어야 합니다.');
    }
    if (!doPasswordsMatch(password, confirmPassword)) {
      return SignUpValidationResult.failure('비밀번호가 일치하지 않습니다.');
    }
    return SignUpValidationResult.success();
  }
}

class SignUpValidationResult {
  final bool isValid;
  final String? errorMessage;

  SignUpValidationResult._({required this.isValid, this.errorMessage});

  factory SignUpValidationResult.success() =>
      SignUpValidationResult._(isValid: true);

  factory SignUpValidationResult.failure(String message) =>
      SignUpValidationResult._(isValid: false, errorMessage: message);
}
