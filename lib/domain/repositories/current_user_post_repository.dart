

import 'package:dating_app/data/models/post_model.dart';

abstract class CurrentUserPostRepository{
  Future<List<PostModel>> getCurrentUserPost();
}

