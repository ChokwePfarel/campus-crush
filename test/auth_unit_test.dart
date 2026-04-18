import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase/supabase.dart';
import 'package:dating_app/domain/repositories/auth_repository.dart';

// Mock class for AuthRepository
class MockAuthRepository extends Mock implements AuthRepository {}

// Fake AuthResponse for testing
class FakeAuthResponse extends Fake implements AuthResponse {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  group('AuthRepository Unit Tests', () {
    const email = 'test@example.com';
    const password = 'password123';
    const name = 'Test User';

    test('login should call repository with correct email and password', () async {
      // Arrange
      final fakeResponse = FakeAuthResponse();
      when(() => mockAuthRepository.login(any(), any()))
          .thenAnswer((_) async => fakeResponse);

      // Act
      await mockAuthRepository.login(email, password);

      // Assert
      verify(() => mockAuthRepository.login(email, password)).called(1);
    });

    test('signUp should call repository with correct email, password, and name', () async {
      // Arrange
      final fakeResponse = FakeAuthResponse();
      when(() => mockAuthRepository.signUp(any(), any(), any()))
          .thenAnswer((_) async => fakeResponse);

      // Act
      await mockAuthRepository.signUp(email, password, name);

      // Assert
      verify(() => mockAuthRepository.signUp(email, password, name)).called(1);
    });

    test('logout should call repository logout function', () async {
      // Arrange
      when(() => mockAuthRepository.logout()).thenAnswer((_) async => Future.value());

      // Act
      await mockAuthRepository.logout();

      // Assert
      verify(() => mockAuthRepository.logout()).called(1);
    });

    group('currentUser', () {
      test('should return current user when getter is called', () {
        // Arrange
        final fakeUser = User(
          id: '123',
          appMetadata: {},
          userMetadata: {},
          aud: '',
          createdAt: '',
        );
        when(() => mockAuthRepository.currentUser).thenReturn(fakeUser);

        // Act
        final result = mockAuthRepository.currentUser;

        // Assert
        expect(result, fakeUser);
        verify(() => mockAuthRepository.currentUser).called(1);
      });
    });
  });
}
