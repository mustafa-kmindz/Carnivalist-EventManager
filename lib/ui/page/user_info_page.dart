import 'dart:io';

import 'package:eventmanagement/bloc/user/user_bloc.dart';
import 'package:eventmanagement/bloc/user/user_state.dart';
import 'package:eventmanagement/intl/app_localizations.dart';
import 'package:eventmanagement/main.dart';
import 'package:eventmanagement/model/logindetail/login_detail_response.dart';
import 'package:eventmanagement/utils/extensions.dart';
import 'package:eventmanagement/utils/vars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:network_to_file_image/network_to_file_image.dart';
import 'package:path/path.dart' as Path;

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({Key key}) : super(key: key);

  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  UserBloc _userBloc;
  String name, email, mobile, avatar;
  Future _futureSystemPath;

  final _focusNodePhone = FocusNode();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNoController = TextEditingController();

  final GlobalKey<FormState> _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _userBloc = BlocProvider.of<UserBloc>(context);
    _firstNameController.text = _userBloc.state.userName;
    _emailController.text = _userBloc.state.email;
    _phoneNoController.text = _userBloc.state.mobile;
    avatar = _userBloc.state.profilePicture;
    _futureSystemPath = getSystemDirPath();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: <Widget>[
          _buildErrorReceiverEmptyBloc(),
          _buildTopBgContainer(),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _key,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _firstNameInput(),
                      const SizedBox(height: 16.0),
                      _phoneNoInput(),
                      const SizedBox(height: 16.0),
                      _emailInput(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildUpdateAndLogoutButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorReceiverEmptyBloc() => BlocBuilder<UserBloc, UserState>(
        bloc: _userBloc,
        condition: (prevState, newState) => newState.uiMsg != null,
        builder: (context, state) {
          if (state.uiMsg != null) {
            String errorMsg = state.uiMsg is int
                ? getErrorMessage(state.uiMsg, context)
                : state.uiMsg;
            context.toast(errorMsg);

            state.uiMsg = null;
          }

          return SizedBox.shrink();
        },
      );

  Widget _buildTopBgContainer() {
    return Container(
        child: Stack(
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                  icon: Icon(
                    isPlatformAndroid ? Icons.arrow_back : CupertinoIcons.back,
                    color: Theme.of(context).appBarTheme.iconTheme.color,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  }),
            ),
            Center(
              child: FutureBuilder(
                future: _futureSystemPath,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return SizedBox.shrink();
                  return InkWell(
                      onTap: showImagePickerBottomSheet,
                      child: CircleAvatar(
                        radius: 42,
                        backgroundImage: isValid(avatar)
                            ? avatar.startsWith('data:image/jpeg;base64')
                                ? MemoryImage(Uri.parse(avatar)
                                        .data
                                        ?.contentAsBytes() ??
                                    Uri.parse(userBase64).data.contentAsBytes())
                                : avatar.startsWith('http')
                                    ? NetworkToFileImage(
                                        url: avatar,
                                        file: File(Path.join(
                                            snapshot.data,
                                            'Pictures',
                                            avatar.substring(
                                                avatar.lastIndexOf('/') + 1))),
                                        debug: true,
                                      )
                                    : FileImage(File(avatar))
                            : AssetImage(appIconImage),
                      ));
                },
              ),
            ),
          ],
        ),
        height: 156,
        width: double.infinity,
        decoration: BoxDecoration(
            image: DecorationImage(
          image: AssetImage(headerBackgroundImage),
          fit: BoxFit.fill,
        )));
  }

  _firstNameInput() => widget.inputField(
        _firstNameController,
        labelText: AppLocalizations.of(context).inputHintFirstName,
        labelStyle: Theme.of(context).textTheme.body1,
        validation: (value) =>
            validateName(value, AppLocalizations.of(context)),
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.next,
        nextFocusNode: _focusNodePhone,
      );

  _phoneNoInput() => widget.inputField(
        _phoneNoController,
        labelText: AppLocalizations.of(context).inputHintPhoneNo,
        labelStyle: Theme.of(context).textTheme.body1,
        maxLength: 13,
        validation: (value) =>
            validateMobile(value, AppLocalizations.of(context)),
        keyboardType: TextInputType.phone,
        focusNode: _focusNodePhone,
      );

  _emailInput() => widget.inputField(
        _emailController,
        labelText: AppLocalizations.of(context).inputHintEmail,
        labelStyle: Theme.of(context).textTheme.body1,
        validation: (value) =>
            validateEmail(value, AppLocalizations.of(context)),
        keyboardType: TextInputType.emailAddress,
        enabled: false,
      );

  _buildUpdateAndLogoutButton() {
    return Row(children: <Widget>[
      Expanded(
        child: InkWell(
          onTap: _updateUserProfile,
          child: Container(
            height: 40,
            width: 110.0,
            child: Align(
                alignment: Alignment.center,
                child: Text(
                    AppLocalizations.of(context).btnUpdate.toUpperCase(),
                    style: new TextStyle(color: Colors.white, fontSize: 14.0))),
            decoration: buttonBg(),
          ),
        ),
      ),
      const SizedBox(width: 24.0),
      Expanded(
        child: InkWell(
          onTap: showLogoutConfirmationDialog,
          child: Container(
            height: 40,
            width: 110.0,
            child: Align(
                alignment: Alignment.center,
                child: Text(
                    AppLocalizations.of(context).btnLogout.toUpperCase(),
                    style: new TextStyle(color: Colors.white, fontSize: 14.0))),
            decoration: buttonBg(),
          ),
        ),
      )
    ]);
  }

  void showLogoutConfirmationDialog() {
    AlertDialog alertDialog = AlertDialog(
      title: Text(
        AppLocalizations.of(context).logoutTitle,
        style: Theme.of(context).textTheme.title.copyWith(fontSize: 16.0),
      ),
      content: Text(
        AppLocalizations.of(context).logoutMsg,
        style: Theme.of(context)
            .textTheme
            .title
            .copyWith(fontSize: 16.0, fontWeight: FontWeight.normal),
      ),
      actions: <Widget>[
        FlatButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).btnCancel)),
        FlatButton(
            onPressed: () {
              _userBloc.clearLoginDetails();
              Navigator.pop(context);
              Navigator.of(context).pushNamedAndRemoveUntil(
                  loginRoute, (Route<dynamic> route) => false);
            },
            child: Text(AppLocalizations.of(context).btnLogout)),
      ],
    );

    showDialog(context: context, builder: (context) => alertDialog);
  }

  void showImagePickerBottomSheet() {
    if (isPlatformAndroid)
      showModalBottomSheet(
          context: context, builder: (ctx) => _buildImagePickerView());
    else
      showCupertinoModalPopup(
        context: context,
        builder: (context) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.0),
                topRight: Radius.circular(12.0),
              ),
            ),
            child: _buildImagePickerView(),
          );
        },
      );
  }

  Widget _buildImagePickerView() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
            _openCamera();
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.camera,
                  size: 32.0,
                ),
                Text(AppLocalizations.of(context).labelCamera),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
            _openGallery();
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.filter,
                  size: 32.0,
                ),
                Text(AppLocalizations.of(context).labelGallery),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openCamera() async {
    var image;

    image = await ImagePicker.pickImage(
        source: ImageSource.camera, imageQuality: 80);

    print('Camera Image/Video Path--->${image?.path}');
    if (image != null) {
      await _deleteExistingBanner();
      setState(() {
        avatar = image.path;
      });
    }
  }

  Future<void> _openGallery() async {
    var image;
    image = await ImagePicker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);

    print('Gallery Image/Video Path--->${image?.path}');
    if (image != null) {
      await _deleteExistingBanner();
      setState(() {
        avatar = image.path;
      });
    }
  }

  Future<void> _deleteExistingBanner() async {
    final systemPath = await getSystemDirPath();
    File fileToDelete;
    if (isValid(avatar) && avatar.contains(systemPath)) {
      fileToDelete = File(avatar);
    } else if (avatar.startsWith('http')) {
      fileToDelete = File(Path.join(systemPath, 'Pictures',
          avatar.substring(avatar.lastIndexOf('/') + 1)));
    }

    if (fileToDelete != null) {
      bool exist = await fileToDelete.exists();
      print('fileToDelete.path ${fileToDelete.path} $exist');
      if (exist) fileToDelete.delete();
    }
  }

  _updateUserProfile() {
    FocusScope.of(context).requestFocus(FocusNode());
    if (validateData()) {
      context.showProgress(context);
      _userBloc.updateLoginDetails(_firstNameController.text,
          _emailController.text, _phoneNoController.text, avatar, (results) {
        context.hideProgress(context);
        if (results is LoginDetailResponse) {
          if (results.code == apiCodeSuccess) {
            Navigator.pop(context);
          }
        }
      });
    }
  }

  bool validateData() {
    if (_key.currentState.validate()) {
      return true;
    }
    return false;
  }
}