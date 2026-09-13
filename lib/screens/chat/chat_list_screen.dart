import 'dart:convert';

import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:booking_system_flutter/screens/auth/sign_in_screen.dart';
import 'package:booking_system_flutter/screens/chat/widget/user_item_widget.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../component/base_scaffold_widget.dart';
import '../../component/empty_error_state_widget.dart';

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late final bool _isLoggedIn;
  Stream<QuerySnapshot>? _chatStream;

  @override
  void initState() {
    super.initState();
    _isLoggedIn =
        FirebaseAuth.instance.currentUser != null && appStore.uid.isNotEmpty;
    if (_isLoggedIn) {
      // Cache the stream once — never recreated on rebuild, so no full-list flicker
      _chatStream = chatServices
          .fetchChatListQuery(userId: appStore.uid)
          .limit(PER_PAGE_CHAT_LIST_COUNT)
          .snapshots();
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: language.lblChat,
      child: _isLoggedIn ? _buildChatList() : _buildNotConnected(),
    );
  }

  Widget _buildChatList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LoaderWidget();
        }
        if (snapshot.hasError) {
          return NoDataWidget(
            title: snapshot.error.toString(),
            imageWidget: ErrorStateWidget(),
          );
        }
        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return NoDataWidget(
            title: language.noConversation,
            subTitle: language.noConversationSubTitle,
            imageWidget: EmptyStateWidget(),
          ).paddingSymmetric(horizontal: 16);
        }
        return ListView.separated(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(top: 8, bottom: 16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => 10.height,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final uid = UserData.fromJson(data).uid.validate();
            // ValueKey isolates each row — only the changed item rebuilds
            return RepaintBoundary(
              key: ValueKey(uid),
              child: UserItemWidget(userUid: uid),
            );
          },
        );
      },
    );
  }

  Widget _buildNotConnected() {
    return NoDataWidget(
      title: language.youAreNotConnectedWithChatServer,
      subTitle: language.NotConnectedWithChatServerMessage,
      onRetry: () async {
        if (!appStore.isLoggedIn) {
          SignInScreen().launch(context);
        } else {
          appStore.setLoading(true);
          await authService.verifyFirebaseUser().then((_) {
            setState(() {});
          }).catchError((e) {
            toast(e.toString());
          });
          appStore.setLoading(false);
        }
      },
      retryText: language.connect,
      imageWidget: EmptyStateWidget(),
    ).paddingSymmetric(horizontal: 16);
  }
}
