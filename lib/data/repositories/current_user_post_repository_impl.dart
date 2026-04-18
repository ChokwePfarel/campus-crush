


import 'package:dating_app/core/constants/mock_data.dart';
import 'package:dating_app/data/datasources/post_remote_data_source.dart';
import 'package:dating_app/data/models/post_model.dart';
import 'package:dating_app/domain/repositories/current_user_post_repository.dart';

class CurrentUserPostImp implements CurrentUserPostRepository{

  final PostRemoteDataSource remoteDataSource;

  CurrentUserPostImp({required this.remoteDataSource});


  @override
  Future<List<PostModel>> getCurrentUserPost() async {
    return await remoteDataSource.getCurrentUserPost();

  }

}

class MockCurrentUserPostRepositoryImpl implements CurrentUserPostRepository{
  @override
  Future<List<PostModel>> getCurrentUserPost() async {

    return CurrentUserPostMock.demoMyPosts;

  }
}