import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:indie_spot/loading.dart';
import 'package:indie_spot/main.dart';
import 'package:indie_spot/pwdEdit.dart';
import 'package:provider/provider.dart';
import 'package:indie_spot/userModel.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:get/get.dart';

import 'join.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   runApp(
//       ChangeNotifierProvider (
//         create: (context) => UserModel(),
//         child: MyApp(),
//       )
//   );
// }
//
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: '로그인',
//       home: LoginPage(),
//     );
//   }
// }

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final FirebaseFirestore _fs = FirebaseFirestore.instance; // Firestore 인스턴스를 가져옵니다.
  final TextEditingController _email = TextEditingController();
  final TextEditingController _pwd = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
            '로그인',
          style: TextStyle(color: Colors.black),
          textAlign: TextAlign.center,
        ),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Column(
            children: [
              Image.asset(
                'assets/indiespot.png',
                width: 300,
                height: 100,
              ),
              SizedBox(height: 20),
              Container(
                  child: TextField(
                    controller: _email,
                    decoration: InputDecoration(labelText: '이메일'),
                  ),
                width: 300
              ),
              SizedBox(height: 20),
              Container(
                child:  TextField(
                  controller: _pwd,
                  obscureText: true,
                  decoration: InputDecoration(labelText: '비밀번호'),
                ),
                width: 300,
              ),
              SizedBox(height: 50),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(240, 240, 240, 1),
                  side: BorderSide(color: Color.fromRGBO(240, 240, 240, 1)),
                  padding: EdgeInsets.symmetric(horizontal: 90, vertical: 18),
                  elevation: 0.2
                ),
                child: Text(
                    '회원 로그인',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4
                    ),),
              ),
              SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: (){
                      Get.to(
                        PwdEdit(),
                        transition: Transition.noTransition
                      );
                    },
                    child: Text(
                      "비밀번호 변경",
                      style: TextStyle(
                      color: Colors.black,
                        fontSize: 15
                      ),
                    ),
                  ),
                  SizedBox(width: 150),
                  InkWell(
                    onTap: (){
                      Get.to(
                        Join(),
                        transition: Transition.noTransition
                      );
                    },
                    child: Text(
                      "가입하기",
                      style: TextStyle(
                        color: Colors.black,
                          fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _login() async {
    FocusScope.of(context).unfocus();
    String email = _email.text;
    const uniqueKey = 'Indie_spot'; // 비밀번호 추가 암호화를 위해 유니크 키 추가
    final bytes = utf8.encode(_pwd.text + uniqueKey); // 비밀번호와 유니크 키를 바이트로 변환
    final hash = sha512.convert(bytes); // 비밀번호를 sha256을 통해 해시 코드로 변환
    String password = hash.toString();


    if(email.isEmpty || _pwd.text.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이메일과 비밀번호를 입력하세요'),
            dismissDirection: DismissDirection.up,
            behavior: SnackBarBehavior.floating,
        )
      );
       return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return LoadingWidget();
      },
      barrierDismissible: false, // 사용자가 화면을 탭해서 닫는 것을 막습니다.
    );

    final userDocs = await _fs.collection('userList')
        .where('email', isEqualTo: email)
        .where('pwd', isEqualTo: password).get();

    if (userDocs.docs.isNotEmpty) {
      var data = userDocs.docs.first.data();
      if(data['banYn'] == 'Y'){
        if(!context.mounted) return;
        Get.back();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '정지된 계정입니다 \n사유 : ${data['banReason']}',
            ),
          ),
        );
      } else{
        final userId = userDocs.docs[0].id;
        String? artistId;
        CollectionReference artistCollectionRef = _fs.collection('artist');

        QuerySnapshot artistDocs = await artistCollectionRef.get();

        for (QueryDocumentSnapshot artistDoc in artistDocs.docs) {
          // 각 artist 문서에서 team_members 컬렉션 참조
          CollectionReference teamMembersRef = artistDoc.reference.collection('team_members');

          // userId를 사용하여 특정 문서 내에서 검색
          QuerySnapshot teamMembers = await teamMembersRef.where('userId', isEqualTo: userId).get();

          if (teamMembers.docs.isNotEmpty) {
            artistId = artistDoc.id;
          }
        }


        if(!context.mounted) return;

        if (artistId != null) {
          Provider.of<UserModel>(context, listen: false).loginArtist(userId, artistId);
          print('아티스트');
        } else {
          Provider.of<UserModel>(context, listen: false).login(userId);
          print('일반');
        }

        Get.off(
          MyApp(),
          transition: Transition.noTransition
        );
      }
    } else {
      if(!context.mounted) return;
      Get.back();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '이메일과 패스워드를 다시 확인해주세요.',
          ),
        ),
      );
    }
  }
}

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white.withOpacity(0.7), // 배경을 반투명하게 하고 하얀색으로 설정
      body: Center(
        child: CircularProgressIndicator(), // 로딩 표시 방법을 원하는 대로 수정 가능
      ),
    );
  }
}