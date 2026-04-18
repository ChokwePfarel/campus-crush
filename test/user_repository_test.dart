import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dating_app/data/repositories/user_repository_impl.dart';
import 'package:dating_app/data/datasources/user_remote_data_source.dart';
import 'package:dating_app/domain/entities/privacy_settings_entity.dart';
import 'package:dating_app/data/models/privacy_settings_model.dart';

class MockUserRemoteDataSource extends Mock implements UserRemoteDataSource {}

class FakePrivacySettingsModel extends Fake implements PrivacySettingsModel {}

void main() {
  late UserRepositoryImpl userRepository;
  late MockUserRemoteDataSource mockRemoteDataSource;

  setUpAll(() {
    registerFallbackValue(FakePrivacySettingsModel());
  });

  setUp(() {
    mockRemoteDataSource = MockUserRemoteDataSource();
    userRepository = UserRepositoryImpl(remoteDataSource: mockRemoteDataSource);
  });

  group('updateUserData', () {
    const tName = 'John Doe';
    const tSex = 'male';
    const tBio = 'Bio test';
    const tStatus = 'Single';
    const tResidence = 'Residence A';
    const tUniversity = 'University A';
    const tInterests = ['Coding', 'Music'];
    const tAge = 25;
    final tPrivacySettings = PrivacySettingsEntity(
      isProfilePrivate: true,
      isSpottedVisible: false,
      showUniversity: true,
      allowMessageRequests: false,
    );
    const tIsVerified = true;

    test('should call remote data source updateUserData with correct parameters', () async {
      // Arrange
      when(() => mockRemoteDataSource.updateUserData(
            name: any(named: 'name'),
            sex: any(named: 'sex'),
            bio: any(named: 'bio'),
            status: any(named: 'status'),
            residence: any(named: 'residence'),
            university: any(named: 'university'),
            interests: any(named: 'interests'),
            age: any(named: 'age'),
            privacySettings: any(named: 'privacySettings'),
            isVerified: any(named: 'isVerified'),
          )).thenAnswer((_) async => Future.value());

      // Act
      await userRepository.updateUserData(
        name: tName,
        sex: tSex,
        bio: tBio,
        status: tStatus,
        residence: tResidence,
        university: tUniversity,
        interests: tInterests,
        age: tAge,
        privacySettings: tPrivacySettings,
        isVerified: tIsVerified,
      );

      // Assert
      verify(() => mockRemoteDataSource.updateUserData(
            name: tName,
            sex: tSex,
            bio: tBio,
            status: tStatus,
            residence: tResidence,
            university: tUniversity,
            interests: tInterests,
            age: tAge,
            privacySettings: any(named: 'privacySettings'),
            isVerified: tIsVerified,
          )).called(1);
    });


   group('updateUserData Error Handling', () {
    test('should throw exception when remote data source fails', () async {
      // Arrange
      when(() => mockRemoteDataSource.updateUserData(
            name: any(named: 'name'),
            sex: any(named: 'sex'),
            bio: any(named: 'bio'),
            status: any(named: 'status'),
            residence: any(named: 'residence'),
            university: any(named: 'university'),
            interests: any(named: 'interests'),
            age: any(named: 'age'),
            privacySettings: any(named: 'privacySettings'),
            isVerified: any(named: 'isVerified'),
          )).thenThrow(Exception('Update failed'));

      // Act & Assert
      expect(
        () => userRepository.updateUserData(
          name: tName,
          sex: tSex,
          bio: tBio,
          status: tStatus,
          residence: tResidence,
          university: tUniversity,
          interests: tInterests,
          age: tAge,
          privacySettings: tPrivacySettings,
          isVerified: tIsVerified,
        ),
        throwsException,
      );
    });
  });
  });
}
