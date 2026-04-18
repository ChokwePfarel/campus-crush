import 'package:flutter_test/flutter_test.dart';

import 'package:dating_app/domain/repositories/user_repository.dart';
import 'package:dating_app/domain/entities/privacy_settings_entity.dart';
import 'package:mocktail/mocktail.dart';

//==============================================================================
//Check if the data being sent out is correct
//==============================================================================
//I mock the UserRepository class
class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockUserRepository mockUserRepository;

  // Set up the mock before each test
  setUp(() {
    mockUserRepository = MockUserRepository();
  });

  group('updateUserData', () {
    test('should call updateUserData with correct parameters', () async {
      // Lines that the actor is performing.
      final name = 'Johny Doe';
      final sex = 'Male';
      final bio = 'Hello, I am John.';
      final status = 'Single';
      final residence = 'Res A';
      final university = 'University A';
      final interests = ['Coding', 'Music'];
      final age = 20;
      final privacySettings = PrivacySettingsEntity(
        isProfilePrivate: false,
        isSpottedVisible: true,
        showUniversity: true,
        allowMessageRequests: true,
      );
      final isVerified = true;


      //“If someone calls updateUserData with any values for these named parameters,
      // don’t crash ,just return a completed Future.”
      when(() => mockUserRepository.updateUserData(
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

      //Calling the funtion
      // As an actor, i am giving you this lines, perform them.
      await mockUserRepository.updateUserData(
        name: name,
        sex: sex,
        bio: bio,
        status: status,
        residence: residence,
        university: university,
        interests: interests,
        age: age,
        privacySettings: privacySettings,
        isVerified: isVerified,
      );

      //Check if its called with right parameters and the funtion was called one
      // Did the actor perform the lines ?
      //THIS IS HOW SUPABSE WILL RECIEVE THE DATA
      verify(() => mockUserRepository.updateUserData(
            name: name,
            sex: sex,
            bio: bio,
            status: status,
            residence: residence,
            university: university,
            interests: interests,
            age: age,
            privacySettings: privacySettings,
            isVerified: isVerified,
          )).called(1);
    });
  });
}
