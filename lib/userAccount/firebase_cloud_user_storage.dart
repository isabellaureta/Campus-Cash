import 'package:cloud_firestore/cloud_firestore.dart';
import 'cloud_user_constants.dart';
import 'cloud_user_details.dart';
import 'cloud_user_exceptions.dart';

class FirebaseCloudUserStorage {
  final userDetails = FirebaseFirestore.instance.collection('userDetails');

  // singleton
  static final FirebaseCloudUserStorage _shared = FirebaseCloudUserStorage._sharedInstance();
  FirebaseCloudUserStorage._sharedInstance();
  factory FirebaseCloudUserStorage() => _shared;

  Stream<Iterable<CloudUserDetails>> allUserDetails({required String ownerUserId}) =>
      userDetails.where(ownerUserIdFieldName, isEqualTo: ownerUserId).snapshots().map((event) =>
          event.docs.map((doc) => CloudUserDetails.fromSnapshot(doc)));

  Future<CloudUserDetails> createNewUserDetails({required String ownerUserId}) async {
    final document = await userDetails.add({
      ownerUserIdFieldName: ownerUserId,
      nameFieldName: '',
      urlFieldName: '',
      isFirstTimeFieldName: true,
    });
    final fetchedUserDetails = await document.get();
    return CloudUserDetails.fromSnapshot(fetchedUserDetails);
  }

  Future<void> deleteUserDetails({required String documentId}) async {
    try {
      await userDetails.doc(documentId).delete();
    } catch (e) {
      throw CouldNotDeleteUserDetailsException();
    }
  }

  Future<void> updateUserDetails({
    required String documentId,
    required String name,
    required String url,
    required bool isFirstTime,
  }) async {
    try {
      await userDetails.doc(documentId).update({
        nameFieldName: name,
        urlFieldName: url,
        isFirstTimeFieldName: isFirstTime,
      });
    } catch (e) {
      throw CouldNotUpdateUserDetailsException();
    }
  }
}
