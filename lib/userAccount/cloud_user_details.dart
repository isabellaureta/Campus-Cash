import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'cloud_user_constants.dart';

@immutable
class CloudUserDetails {
  final String documentId;
  final String ownerUserId;
  final String name;
  final String url;
  final bool isFirstTime;

  CloudUserDetails({
    required this.documentId,
    required this.ownerUserId,
    required this.name,
    required this.url,
    required this.isFirstTime,
  });

  factory CloudUserDetails.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return CloudUserDetails(
      documentId: snapshot.id,
      ownerUserId: data['user_id'],
      name: data['name'],
      url: data['url'],
      isFirstTime: data['isFirstTime'],
    );
  }
}
