import 'dart:developer';
import 'dart:io';
import 'package:expenses_tracker/auth/auth_service.dart';
import 'package:expenses_tracker/auth/bloc/auth_bloc.dart';
import 'package:expenses_tracker/auth/bloc/auth_event.dart';
import 'package:expenses_tracker/cloud/cloud_user_details.dart';
import 'package:expenses_tracker/cloud/firebase_cloud_user_storage.dart';
import 'package:expenses_tracker/constants/colors.dart';
import 'package:expenses_tracker/utilities/generics/get_argument.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class UserDetailsView extends StatefulWidget {
  const UserDetailsView({super.key});

  @override
  State<UserDetailsView> createState() => _UserDetailsViewState();
}

class _UserDetailsViewState extends State<UserDetailsView> {
  File? _image;
  bool? inProcess;
  CloudUserDetails? _userDetails;
  String? url;
  bool _dataInitialized = false;
  late final TextEditingController _nameTextController;
  late final FirebaseCloudUserStorage _userDetailsService;

  @override
  void initState() {
    log('init');
    _nameTextController = TextEditingController();
    _userDetailsService = FirebaseCloudUserStorage();

    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dataInitialized) {
      createOrGetUserDetails(context);
      _dataInitialized = true;
    }
  }

  Future<CloudUserDetails> createOrGetUserDetails(BuildContext context) async {
    final widgetUserDetails = context.getArgument<CloudUserDetails>();
    if (widgetUserDetails != null) {
      log('createUserDetails weszło do petli i zrobilo GET');
      _userDetails = widgetUserDetails;
      _nameTextController.text = widgetUserDetails.name;

      return widgetUserDetails;
    }

    final currentUser = AuthService.firebase().currentUser!;
    final userId = currentUser.id;
    final newUserDetails =
        await _userDetailsService.createNewUserDetails(ownerUserId: userId);
    _userDetails = newUserDetails;
    return newUserDetails;
  }

  void _deleteUserDetailsIfNameIsEmpty() {
    final userDetails = _userDetails;
    if (_nameTextController.text.isEmpty && userDetails == null) {
      _userDetailsService.deleteUserDetails(
          documentId: userDetails!.documentId);
    }
  }

  void _saveUserDetailsIfNameNotEmpty() async {
    final userDetails = _userDetails;
    final name = _nameTextController.text;

    if (name.isNotEmpty && userDetails != null) {
      await _userDetailsService.updateUserDetails(
        documentId: userDetails.documentId,
        name: name,
        url: url!,
        isFirstTime: false,
      );
    }
  }



  @override
  void dispose() {
    log('dispose');
    _saveUserDetailsIfNameNotEmpty();
    _deleteUserDetailsIfNameIsEmpty();
    _nameTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            margin:
                const EdgeInsets.symmetric(horizontal: 50.0, vertical: 75.0),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    AppLocalizations.of(context)!.user_details_view_get_to_know,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(
                  height: 25.0,
                ),
                Center(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(100.0),
                    onTap: () async {
                      final picker = ImagePicker();
                      setState(() {
                        inProcess = true;
                      });
                      final imageFile =
                          await picker.pickImage(source: ImageSource.gallery);

                      setState(() {
                        if (imageFile != null) {
                          _image = File(imageFile.path);
                        }
                        inProcess = false;
                      });
                      //url = await uploadFile(_image!);
                    },
                    child: Container(
                      height: 200,
                      width: 200,
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(100.0),
                        image: _image != null
                            ? DecorationImage(
                                image: FileImage(_image!),
                                fit: BoxFit.cover,
                              )
                            : const DecorationImage(
                                image: AssetImage(
                                  'assets/default_user_icon.png',
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 25.0,
                ),
                TextField(
                  controller: _nameTextController,
                  keyboardType: TextInputType.name,
                  enableSuggestions: false,
                  autocorrect: false,
                  //autofocus: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person),
                    hintText: AppLocalizations.of(context)!
                        .user_details_view_name_hintText,
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                      borderSide: const BorderSide(
                        color: Colors.grey,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                      borderSide: BorderSide(
                        color: ColorConstants.dartMainThemeColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 25.0,
                ),
                SizedBox(
                  width: 225.0,
                  child: FilledButton(
                    // TODO zabawaaaaaa z firestore
                    onPressed: () async {
                      _saveUserDetailsIfNameNotEmpty();
                    },
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!
                          .user_details_view_save_button,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 225.0,
                  child: FilledButton(
                    onPressed: () async {
                      dispose();
                      context.read<AuthBloc>().add(const AuthEventLogOut());
                    },
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                    child: const Text(
                      'logout',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
