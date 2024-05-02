import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expenses_tracker/cloud/cloud_user_constants.dart';
import 'package:flutter/material.dart';

@immutable
class CloudUserDetails {
  final String documentId;
  final String ownerUserId;
  final String name;
  final String url;
  final bool isFirstTime;

  const CloudUserDetails({
    required this.documentId,
    required this.ownerUserId,
    required this.name,
    required this.url,
    required this.isFirstTime,
  });

  CloudUserDetails.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot)
      : documentId = snapshot.id,
        ownerUserId = snapshot.data()![ownerUserIdFieldName],
        name = snapshot.data()![nameFieldName] as String,
        url = snapshot.data()![urlFieldName] as String,
        isFirstTime = snapshot.data()![isFirstTimeFieldName];
}
