import 'dart:ui';
import 'package:dating_app/data/models/like_model.dart';
import 'package:dating_app/data/models/post_model.dart';
import 'package:dating_app/data/models/comment_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/privacy_settings_model.dart';


//-------------------------------------------------------------------------USERS
class MockData {
  static final List<UserModel> mockUsers = [
    UserModel(
      id: 'u1',
      name: 'Alice Johnson',
      age: 22,
      sex: 'Female',
      university: 'university of the western cape',
      residence: 'North Hall',
      status: 'looking',
      major: 'Computer Science',
      bio: 'Loves coding and hiking on weekends!',
      profileImageUrl: 'https://i.pravatar.cc/300?u=bob',
      imageUrls: [
        'https://i.pravatar.cc/300?u=bob1',
      ],
      interests: ['Coding', 'Hiking', 'Coffee'],
      isVerified: true,
      privacySettings: PrivacySettingsModel(
        isProfilePrivate: true,
        isSpottedVisible: true,
        showUniversity: true,
        allowMessageRequests: true,
      ),
      profileStatus: 'clean'
    ),
    UserModel(
      profileStatus: 'clean',

      id: 'u2',
      name: 'Bob Smith',
      age: 24,
      sex: 'Male',
      university: 'University of the Western Cape',
      residence: 'South Hall',
      status: 'taken',
      major: 'Business Administration',
      bio: 'Traveler and foodie. Always looking for the next adventure.',
      profileImageUrl: 'https://i.pravatar.cc/300?u=alice',
      imageUrls: [
        'https://i.pravatar.cc/300?u=alice1',
        'https://i.pravatar.cc/300?u=alice2',
      ],
      interests: ['Traveling', 'Food', 'Movies'],
      isVerified: false,
      privacySettings: PrivacySettingsModel(
        isProfilePrivate: false,
        isSpottedVisible: false,
        showUniversity: true,
        allowMessageRequests: false,
      ),
    ),
  ];
}


//---------------------------------------------------------------------COMMENSTS
class CommentMock {
  static final List<CommentModel> mockComments = [
    CommentModel(
      id: 'c1',
      repliersName: 'Bob Smith',
      postId: '1',
      userId: 'u2',
      text: 'I know exactly who you mean! She is literally so nice ',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    CommentModel(
      id: 'c2',
      repliersName: 'Alice Johnson',
      postId: '1',
      userId: 'u1',
      text: 'Omg stop, you should definitely talk to her!',
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
      replies: [
        CommentModel(
          id: 'c3',
          repliersName: 'Bob Smith',
          postId: '1',
          userId: 'u2',
          text: 'I\'m too shy for that lol',
          createdAt: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      ],
    ),
  ];
}


//--------------------------------------------------------------------------POST
class PostMock {
  static final List<PostModel> mockPosts = [
    PostModel(
      id: '1',
      userId: '',
      authorName: 'Alice Johnson',
      content: 'There\'s this girl in my Econ lecture who always sits by the window. She laughs at everything the lecturer says even when it\'s not funny, and honestly it\'s the best part of my week 💘',
      university: 'University of the Western Cape',
      postType: 'crush',
      createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
      isAnonymous: true,
      likeCount: 47,
      commentCount: 2, recipientId: 'u_mock_001', isNormalPost: false,
    ),
    PostModel(
      id: '2',
      userId: 'u2',
      authorName: 'Bob Smith',
      content: 'Red hoodie, white Air Forces, carrying a black JanSport. Come say hi if you see me ',
      university: 'University of the Western Cape',
      postType: 'spotted',
      createdAt: DateTime.now().subtract(const Duration(minutes: 34)),
      expiresAt: DateTime.now().add(const Duration(hours: 2)),
      locationTag: 'Main Library',
      isAnonymous: false,
      likeCount: 23,
      commentCount: 0, recipientId: 'u_mock_001', isNormalPost: false,
    ),
    PostModel(
      id: '3',
      userId: 'u3',
      authorName: 'Anonymous',
      content: 'I genuinely cried watching a pigeon eat a chip outside the cafeteria today. Finals season has broken me completely.',
      university: 'University of the Western Cape',
      postType: 'confession',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      isAnonymous: true,
      likeCount: 134,
      commentCount: 5,
      backgroundColor: const Color(0xFF6C63FF), recipientId: '', isNormalPost: true,
    ),
  ];
}

class SpottedMock {
  static final List<PostModel> mockSpotted = [
    PostModel(
      id: 's1',
      userId: 'u1',
      authorName: 'Alice Johnson',
      content: 'Red hoodie, white Air Forces, black JanSport. Come say hi ',
      postType: 'spotted',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      expiresAt: DateTime.now().add(const Duration(hours: 2)),
      locationTag: 'Main Library',
      isAnonymous: false,
      university: 'University of the Western Cape',
      likeCount: 12,
      commentCount: 1, recipientId: '', isNormalPost: true,
    ),
    PostModel(
      id: 's2',
      userId: 'u2',
      authorName: 'Bob Smith',
      content: 'Olive cargo pants, white crop, gold hoops ',
      postType: 'spotted',
      createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
      expiresAt: DateTime.now().add(const Duration(hours: 1, minutes: 40)),
      locationTag: 'Main Library',
      isAnonymous: false,
      university: 'University of the Western Cape',
      likeCount: 8,
      commentCount: 3, recipientId: '', isNormalPost: true,

    ),
  ];
}


//------------------------------------------------------------------CURRENT USER
class MockCurrentUser {
  final currentUserMock = UserModel(
    profileStatus: 'clean',

    id: 'u_mock_001',
    name: 'Ayanda Dlamini',
    coins: 15,
    age: 21,
    sex: 'female',
    university: 'University of the Western Cape',
    residence: 'Faranani Res',
    status: 'Undergraduate',
    major: 'Psychology',
    bio: 'Third year Psych student  | UWC forever  | Iced coffee addict ',
    profileImageUrl: 'https://i.pravatar.cc/300?u=ayanda',
    imageUrls: [
      'https://i.pravatar.cc/300?u=ayanda1',
      'https://i.pravatar.cc/300?u=ayanda2',
    ],
    interests: ['Music', 'Reading', 'Hiking'],
    isVerified: true,
    privacySettings: PrivacySettingsModel(
      isProfilePrivate: false,
      isSpottedVisible: true,
      showUniversity: true,
      allowMessageRequests: true,
    ),
  );
}


//-------------------------------------------------------------CURRENT USER POST
class CurrentUserPostMock {
  static final demoMyPosts = [
    PostModel(
      id: '1',
      userId: 'u_mock_001',
      authorName: 'Ayanda Dlamini',
      content: 'There\'s this guy in my Stats lecture who always saves me a seat. I\'ve never said thank you properly and it\'s been 3 months 💘',
      university: 'University of the Western Cape',
      postType: 'crush',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isAnonymous: true,
      likeCount: 47,
      commentCount: 8, recipientId: '', isNormalPost: true,

    ),
    PostModel(
      id: 'p2',
      userId: 'u_mock_001',
      authorName: 'Ayanda Dlamini',
      content: 'Olive green cargo pants, white crop top, gold hoops. Sitting near the window at the Student Centre Café ☕',
      university: 'University of the Western Cape',
      postType: 'spotted',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      expiresAt: DateTime.now().subtract(const Duration(hours: 2)),
      locationTag: 'Student Centre Café',
      isAnonymous: false,
      likeCount: 23,
      commentCount: 4, recipientId: '', isNormalPost: true,

    ),
  ];
}

//----------------------------------------------------------------------COMMENTS
class CommentsMock {

 static final List<CommentModel> demoComments = [
    CommentModel(
      id: 'c1', repliersName: 'Ayanda D.', postId: '1', userId: 'u1',
      text: 'This is so relatable  I feel this on a spiritual level',
      createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
    ),
    CommentModel(
      id: 'c2', repliersName: 'Anonymous', postId: '1', userId: 'u2',
      text: 'Just go talk to them!! Life is short ',
      createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
      replies: [
        CommentModel(
          id: 'c2r1', repliersName: 'Lerato M.', postId: 'p1', userId: 'u3',
          text: 'Easier said than done lol ',
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
          parentCommentId: 'c2',
        ),
        CommentModel(
          id: 'c2r2', repliersName: 'Anonymous', postId: '1', userId: 'u4',
          text: 'Seriously though, just say hi!',
          createdAt: DateTime.now().subtract(const Duration(minutes: 7)),
          parentCommentId: 'c2',
        ),
      ],
    ),
    CommentModel(
      id: 'c3', repliersName: 'Sipho K.', postId: '1', userId: 'u5',
      text: 'UWC love stories hit different ',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    CommentModel(
      id: 'c4', repliersName: 'Anonymous', postId: '1', userId: 'u6',
      text: 'Could this be about me? ',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];
}


//-------------------------------------------------------------------------LIKES
 class LikesMock {
static final mockLikes = [
  LikeModel(
    id: 'l_001',
    postId: '1',
    userId: 'u_001',
    likedByName: 'Ayanda Dlamini',
    createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
  ),
  LikeModel(
    id: 'l_002',
    postId: '1',
    userId: 'u_002',
    likedByName: 'Lerato Mokoena',
    createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
  ),
  LikeModel(
    id: 'l_003',
    postId: '1',
    userId: 'u_003',
    likedByName: 'Sipho Khumalo',
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  LikeModel(
    id: 'l_004',
    postId: '1',
    userId: 'u_004',
    likedByName: 'Nomvula Petersen',
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
  ),
  LikeModel(
    id: 'l_005',
    postId: '1',
    userId: 'u_005',
    likedByName: 'Thabo Nkosi',
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
  ),
];}
