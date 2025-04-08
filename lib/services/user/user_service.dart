import 'package:arena_x/core/constants/firestore_constants.dart';
import 'package:arena_x/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService{
  final _usersCollection = FirebaseFirestore.instance.collection(FirestoreConstants.usersCollection)
      .withConverter(fromFirestore: UserModel.fromFirestore, toFirestore: (UserModel user, _) => user.toFirestore());

  Stream<UserModel> getUserStream(String userId) {
    if(userId.isEmpty){
      return Stream.value(UserModel.error);
    }
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (!doc.exists) {
        return UserModel.error;
      }
      return doc.data()!;
    });
  }

  Future<UserModel> getUserData(String userId) async {
    try {
      final docSnapshot = await _usersCollection.doc(userId).get();
      if(docSnapshot.exists) {
        return docSnapshot.data() ?? UserModel.error;

      }else{
        return UserModel.error;
      }
    } catch (e) {
      print('Error getting user data: $e');
      return UserModel.error;
    }

  }
}