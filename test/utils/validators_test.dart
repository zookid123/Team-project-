import 'package:flutter_test/flutter_test.dart';
import 'package:app_project/utils/validators.dart';

void main() {
  // ──────────────────────────────────────────
  // 이메일 유효성 검사
  // ──────────────────────────────────────────
  group('Validators.isValidEmail', () {
    test('should_return_true_when_email_is_valid', () {
      expect(Validators.isValidEmail('user@example.com'), isTrue);
      expect(Validators.isValidEmail('dungeon@log.co.kr'), isTrue);
    });

    test('should_return_false_when_email_is_empty', () {
      expect(Validators.isValidEmail(''), isFalse);
      expect(Validators.isValidEmail('   '), isFalse);
    });

    test('should_return_false_when_email_has_no_at_sign', () {
      expect(Validators.isValidEmail('userexample.com'), isFalse);
    });

    test('should_return_false_when_email_starts_with_at', () {
      expect(Validators.isValidEmail('@example.com'), isFalse);
    });

    test('should_return_false_when_domain_has_no_dot', () {
      expect(Validators.isValidEmail('user@examplecom'), isFalse);
    });
  });

  // ──────────────────────────────────────────
  // 비밀번호 길이 검사
  // ──────────────────────────────────────────
  group('Validators.isValidPassword', () {
    test('should_return_true_when_password_is_6_or_more_chars', () {
      expect(Validators.isValidPassword('abc123'), isTrue);
      expect(Validators.isValidPassword('longpassword!'), isTrue);
    });

    test('should_return_false_when_password_is_less_than_6_chars', () {
      expect(Validators.isValidPassword('abc'), isFalse);
      expect(Validators.isValidPassword(''), isFalse);
    });

    test('should_return_false_when_password_is_exactly_5_chars', () {
      // 경계값: 5자는 실패
      expect(Validators.isValidPassword('12345'), isFalse);
    });

    test('should_return_true_when_password_is_exactly_6_chars', () {
      // 경계값: 6자는 성공
      expect(Validators.isValidPassword('123456'), isTrue);
    });
  });

  // ──────────────────────────────────────────
  // 비밀번호 일치 검사
  // ──────────────────────────────────────────
  group('Validators.doPasswordsMatch', () {
    test('should_return_true_when_passwords_are_identical', () {
      expect(Validators.doPasswordsMatch('password1', 'password1'), isTrue);
    });

    test('should_return_false_when_passwords_differ', () {
      expect(Validators.doPasswordsMatch('password1', 'password2'), isFalse);
    });

    test('should_return_false_when_one_password_is_empty', () {
      expect(Validators.doPasswordsMatch('password1', ''), isFalse);
    });
  });

  // ──────────────────────────────────────────
  // 닉네임 유효성 검사
  // ──────────────────────────────────────────
  group('Validators.isValidNickname', () {
    test('should_return_true_when_nickname_is_valid', () {
      expect(Validators.isValidNickname('용사123'), isTrue);
      expect(Validators.isValidNickname('a'), isTrue);
    });

    test('should_return_false_when_nickname_is_empty', () {
      expect(Validators.isValidNickname(''), isFalse);
    });

    test('should_return_false_when_nickname_is_only_whitespace', () {
      expect(Validators.isValidNickname('   '), isFalse);
    });

    test('should_return_false_when_nickname_exceeds_10_chars', () {
      // 경계값: 11자는 실패
      expect(Validators.isValidNickname('12345678901'), isFalse);
    });

    test('should_return_true_when_nickname_is_exactly_10_chars', () {
      // 경계값: 10자는 성공
      expect(Validators.isValidNickname('1234567890'), isTrue);
    });
  });

  // ──────────────────────────────────────────
  // 회원가입 통합 검증
  // ──────────────────────────────────────────
  group('Validators.validateSignUp', () {
    test('should_return_success_when_all_inputs_are_valid', () {
      final result = Validators.validateSignUp(
        email: 'hero@dungeon.com',
        password: 'abc123',
        confirmPassword: 'abc123',
      );
      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('should_return_failure_when_email_is_invalid', () {
      final result = Validators.validateSignUp(
        email: 'notanemail',
        password: 'abc123',
        confirmPassword: 'abc123',
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('이메일'));
    });

    test('should_return_failure_when_password_is_too_short', () {
      final result = Validators.validateSignUp(
        email: 'hero@dungeon.com',
        password: '123',
        confirmPassword: '123',
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('6자리'));
    });

    test('should_return_failure_when_passwords_do_not_match', () {
      final result = Validators.validateSignUp(
        email: 'hero@dungeon.com',
        password: 'abc123',
        confirmPassword: 'xyz789',
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('일치'));
    });
  });
}
