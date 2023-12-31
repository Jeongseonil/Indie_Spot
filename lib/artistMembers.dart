import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'baseBar.dart';
import 'userModel.dart';
import 'package:provider/provider.dart';

class ArtistMembers extends StatefulWidget {
  final DocumentSnapshot doc;
  final String artistImg;
  final String? _artistIdCheck;

  ArtistMembers(this.doc, this.artistImg, this._artistIdCheck, {super.key});

  @override 
  State<ArtistMembers> createState() => _ArtistMembersStatus();
}

class _ArtistMembersStatus extends State<ArtistMembers> {
  FirebaseFirestore fs = FirebaseFirestore.instance;

  String? _userId;
  String? joinId;
  String? position;
  String? joinDocId;
  bool spyYn = false; // 스파이냐?
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    final userModel = Provider.of<UserModel>(context, listen: false);
    if (!userModel.isLogin) {
    } else {
      _userId = userModel.userId;
    }
  }

  void spyCheck(String spyId) async {
    final CollectionReference artistDoc = fs.collection('artist');


    var artistSnapshot = await artistDoc.get();
    if (artistSnapshot.docs.isNotEmpty) {
      for (QueryDocumentSnapshot artistDoc in artistSnapshot.docs) {
        var teamMembersSnapshot = await artistDoc.reference.collection('team_members').get();

        teamMembersSnapshot.docs.forEach((teamMemberDoc) {
          // 'userId' 필드가 'spyId'와 같은 경우 spyYn을 true로 설정
          if (teamMemberDoc['userId'] == spyId) {
            setState(() {
              print("스파이 아이디 ${teamMemberDoc['userId']}");
              spyYn = true;
            });
          }
        });
      }
    }


    print('Is Spy: $spyYn');
  }


  ////////// 가입 수락 /////////
  void teamAccept() async {

    print("가입수락 클릭! $joinId");
    if(spyYn){
      queryDuplicateAlert("이미 다른 팀에 가입되어있습니다.");
      print("가입이 안됨! $joinId");
    }
    try {

      // "team_members" 컬렉션에 새로운 문서 추가
      await fs.collection('artist')
          .doc(widget.doc.id)
          .collection('team_members')
          .add({
        "position": position,
        "userId": joinId,
        "status": 'N',
        "createtime" : Timestamp.now()
      });

      deleteTeamMembers(joinId!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('완료되었습니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() {
        _artistDetails();
        teamJoinList();
      });
      Navigator.of(context).pop();
    } catch (e) {
      // 에러가 발생한 경우 예외 처리
      queryDuplicateAlert("오류발생 잠시후 다시시도해주세요.");
      // 필요한 예외 처리 로직 추가
    }

  }
  // 가입 승인한 유저의 가입신청내역 삭제
  void deleteTeamMembers(String joinId) async {
    // artist 컬렉션에서 team_members 서브컬렉션 참조
    CollectionReference artistsRef = fs.collection('artist');

    // artist 컬렉션의 모든 문서에 접근
    QuerySnapshot artistsQuery = await artistsRef.get();

    // 각 문서의 team_members 컬렉션에서 userId와 joinId가 일치하는 문서 삭제
    for (QueryDocumentSnapshot artistDoc in artistsQuery.docs) {
      // team_members 서브컬렉션 참조
      CollectionReference teamMembersRef = artistDoc.reference.collection('team_join');

      // team_members 컬렉션에서 userId와 joinId가 일치하는 문서 삭제
      QuerySnapshot teamMembersQuery = await teamMembersRef.where('userId', isEqualTo: joinId).get();

      for (QueryDocumentSnapshot teamMemberDoc in teamMembersQuery.docs) {
        await teamMemberDoc.reference.delete();
      }
    }
    print("삭제완");
  }


  ////////// 가입 거절 /////////
  void teamRefuse() async{
    print("여긴 삭제하는 부분인데 머지");
    // "team_join" 컬렉션에서 문서 삭제
    await fs.collection('artist')
        .doc(widget.doc.id)
        .collection('team_join')
        .doc(joinDocId)
        .delete().then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('완료되었습니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
          setState(() {
            _artistDetails();
            teamJoinList();
          });

        },);
  }

  void _membersDelete(String memberId) async {
    await fs.collection('artist')
        .doc(widget.doc.id)
        .collection('team_members')
        .doc(memberId)
        .delete().then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('완료되었습니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _artistDetails();
        teamJoinList();
      });
      Navigator.of(context).pop();
    },);
  }

  ////////////////////////////////탭1 멤버 리스트/////////////////////////////////////////
  // 탭1 멤버 리스트 멤버관리 수정
  Future<List<Widget>> _artistDetails() async {
    final membersQuerySnapshot = await fs
        .collection('artist')
        .doc(widget.doc.id)
        .collection('team_members')
        .get();

    if (membersQuerySnapshot.docs.isNotEmpty) {
      List<QueryDocumentSnapshot> membersList = membersQuerySnapshot.docs;

      // 'status' 값이 'Y'인 요소들을 추출
      List<QueryDocumentSnapshot> membersWithStatusY = membersList
          .where((member) => member['status'] == 'Y')
          .toList();

      // 'status' 값이 'Y'인 요소들을 맨 위로 위치시키기
      membersList.removeWhere((member) => member['status'] == 'Y');
      membersList.insertAll(0, membersWithStatusY);

      List<Widget> memberWidgets = [];

      for (QueryDocumentSnapshot membersDoc in membersList) {
        String memberPosition = membersDoc['position'];
        String userId = membersDoc['userId'];
        String artistId = membersDoc.id;

        final userDocSnapshot = await fs.collection("userList").doc(userId).get();

        if (userDocSnapshot.exists) {
          String userName = userDocSnapshot['name'];
          String userNick = userDocSnapshot['nick'];
          final userImageCollection =
          await fs.collection('userList').doc(userId).collection('image').get();

          if (userImageCollection.docs.isNotEmpty) {
            String userImage = userImageCollection.docs.first['PATH'];

            Widget memberWidget = ListTile(
              leading: Image.network(userImage),
              title: Row(
                children: [
                  Text(userName),
                  Text(userNick, style: TextStyle(fontSize: 12)),
                ],
              ),
              subtitle: Text(memberPosition),
              trailing: Visibility(
                visible: userId == _userId || widget._artistIdCheck != null, // userId가 _userId와 같을 때만 보이도록 설정
                child: IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(27)),
                      ),
                      context: context,
                      builder: (context) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Center(
                              child: Container(
                                margin: EdgeInsets.only(top: 10, bottom: 20),
                                width: 50,
                                decoration: BoxDecoration(
                                  border: Border.all(width: 2, color: Colors.black54),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 10),
                                    child: TextButton(
                                      onPressed: () {
                                        // 엘럿창을 띄워 수정을 위한 TextEditingController를 사용
                                        TextEditingController _textFieldController = TextEditingController();
                                        _textFieldController.text = memberPosition; // 기존 값을 텍스트 필드에 설정

                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: Text('멤버 수정'),
                                              content: TextField(
                                                controller: _textFieldController,
                                                decoration: InputDecoration(labelText: '포지션'), // 텍스트 필드 레이블 설정
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () async {
                                                    String updatePosition = _textFieldController.text;
                                                    await fs.collection('artist')
                                                        .doc(widget.doc.id)
                                                        .collection('team_members')
                                                        .doc(artistId)
                                                        .update({
                                                      'position': updatePosition,
                                                    }).then((value) {
                                                      setState(() {
                                                        _artistDetails();
                                                        Navigator.of(context).pop();
                                                      });
                                                    },);
                                                  },
                                                  child: Text('수정'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Text('취소'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      style: ButtonStyle(
                                        alignment: Alignment.centerLeft,
                                      ),
                                      child: Row(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(right: 15),
                                            child: Icon(
                                              Icons.edit,
                                              color: Color(0xFF634F52),
                                            ),
                                          ),
                                          Text(
                                            '수정',
                                            style: TextStyle(color: Color(0xFF634F52)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 10),
                                    child: TextButton(
                                      onPressed: () => showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: Text('멤버 탈퇴'),
                                            content: Text('멤버를 팀에서 탈퇴시키겠습니까?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  _membersDelete(artistId);
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text('탈퇴'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  setState(() {});
                                                },
                                                child: Text('취소'),
                                              ),
                                            ],
                                          );
                                        },
                                      ).then((value) => Navigator.of(context).pop()),
                                      style: ButtonStyle(
                                        alignment: Alignment.centerLeft,
                                      ),
                                      child: Row(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(right: 15),
                                            child: Icon(
                                              Icons.delete,
                                              color: Color(0xFF634F52),
                                            ),
                                          ),
                                          Text(
                                            '삭제',
                                            style: TextStyle(color: Color(0xFF634F52)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: Icon(Icons.more_vert, color: Colors.black54, size: 17),
                ),
              ),
            );

            memberWidgets.add(memberWidget);
          }
        }
      }

      return memberWidgets;
    } else {
      return [Container()];
    }
  }

//////////////가입 신청 리스트/////////
  Future<List<Widget>> teamJoinList() async {
    final membersQuerySnapshot = await fs
        .collection('artist')
        .doc(widget.doc.id)
        .collection('team_join')
        .get();
    List<Widget> joinwidgets = [];

    if (membersQuerySnapshot.docs.isNotEmpty) {
      final futures = membersQuerySnapshot.docs.map((joinList) async {
        String title = joinList['title'];
        String content = joinList['content'];
        position = joinList['position'];
        String career = joinList['career'];
        joinId = joinList['userId'];
        joinDocId = joinList.id;

        final userInfo = await fs.collection('userList').doc(joinId).get();
        final userImage = await fs.collection('userList').doc(joinId).collection('image').get();

        // userInfo 및 userImage에서 필드를 가져옴
        String name = userInfo['name'];
        String nick = userInfo['nick'];
        String gender = userInfo['gender'];
        String path = userImage.docs.isNotEmpty ? userImage.docs[0]['PATH'] : ''; // 첫 번째 이미지의 경로 (필요에 따라 수정)

        // ListTile을 생성하고 정보 표시
        Widget widgetList = ListTile(
          leading: Image.network(path), // 이미지 표시
          title: Text(title), // 제목
          subtitle: Text(position!), // 포지션
          trailing: Icon(Icons.info), // 아이콘을 추가하여 탭 가능하게 만듦
          onTap: () {
            // AlertDialog를 표시하여 모든 정보 출력
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  content: Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Image.network(
                            path,
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(height: 16),
                        Center(
                          child: Text(
                            "$title",
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            maxLines: 1, // 최대 1줄로 제한
                            overflow: TextOverflow.ellipsis, // 넘치는 경우 ...으로 표시
                          ),
                        ),
                        SizedBox(height: 12),
                        Text("내용"),
                        SizedBox(height: 8),
                        Container(
                          margin: EdgeInsets.only(left: 10),
                          child: Text('$content',
                            style: TextStyle(fontSize: 16),
                            maxLines: 5, // 최대 2줄로 제한
                            overflow: TextOverflow.ellipsis,),
                        ),
                        SizedBox(height: 12),
                        Text("포지션"),
                        SizedBox(height: 8),
                        Container(
                          margin: EdgeInsets.only(left: 10),
                          child: Text(
                            "$position",
                            style: TextStyle(fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text("경력"),
                        SizedBox(height: 8),
                        Container(
                          margin: EdgeInsets.only(left: 10),
                          child: Text(
                            career,
                            style: TextStyle(fontSize: 16),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          "이름: $name",
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "닉네임: $nick",
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "성별: $gender",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    if (widget._artistIdCheck != null)
                      ElevatedButton(
                        onPressed: () {
                          inputDuplicateAlert("수락하시겠습니까?");
                        },
                        style: ElevatedButton.styleFrom(primary: Colors.green),
                        child: Text("수락"),
                      ),
                    if (widget._artistIdCheck != null)
                      ElevatedButton(
                        onPressed: () {
                          inputDuplicateAlert("거절하시겠습니까?");
                        },
                        style: ElevatedButton.styleFrom(primary: Colors.red),
                        child: Text("거절"),
                      ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(primary: Colors.blue),
                      child: Text("취소"),
                    ),
                  ],
                );
              },
            );



          },
        );

        joinwidgets.add(widgetList);
      }).toList();

      // 병렬로 데이터를 가져와서 대기
      await Future.wait(futures);
    }

    if (joinwidgets.isEmpty) {
      joinwidgets.add(Text('팀 참여 정보 없음'));
    }

    return joinwidgets;
  }


// 엘럿
  void inputDuplicateAlert(String text) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(text),
          actions: <Widget>[
            TextButton(
              child: Text("확인"),
              onPressed: () {
                spyCheck(joinId!);
                text == "수락하시겠습니까?" ? teamAccept() : teamRefuse();
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text("취소"),
              onPressed: () {
                Navigator.of(context).pop(); // 알림 창 닫기
              },
            ),
          ],
        );
      },
    );
  }

  void queryDuplicateAlert(String text) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(text),
          actions: <Widget>[
            TextButton(
              child: Text("확인"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: Builder(
            builder: (context) {
              return IconButton(
                color: Color(0xFFffffff),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: Icon(Icons.arrow_back),
              );
            },
          ),
          title: Center(
            child: Text(
              "팀 관리",
              style:
              TextStyle(color: Color(0xFFffffff), fontWeight: FontWeight.bold),
            ),
          ),
          actions: [
            Builder(
              builder: (context) {
                return IconButton(
                  color: Color(0xFFffffff),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  icon: Icon(Icons.menu),
                );
              },
            )
          ],
          backgroundColor: Color(0xFF233067),
          bottom: TabBar(
            tabs: [
              Tab(text: '멤버'),
              Tab(text: '신청내역'),
            ],
            indicatorColor:Color(0xFF233067),
            unselectedLabelColor: Color(0xFFffffff),
            labelColor: Color(0xFFffffff),
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.normal,
            ),
          ),
          elevation: 1,
        ),
        drawer: MyDrawer(),
        body: TabBarView(
            children: [
              ListView(
                // 소개 탭
                children: [
                  Container(
                    child: FutureBuilder(
                      future: _artistDetails(),
                      builder: (BuildContext context,
                          AsyncSnapshot<dynamic> snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Container();
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else {
                          return Column(
                            children: [
                              Container(
                                padding: EdgeInsets.only(top: 10),
                                margin: EdgeInsets.all(20),
                                child: Column(
                                  children: snapshot.data ?? [Container()],
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  )
                ],
              ),
              ListView(
                // 소개 탭
                children: [
                  Container(
                    child: FutureBuilder(
                      future: teamJoinList(),
                      builder: (BuildContext context,
                          AsyncSnapshot<dynamic> joinListSnap) {
                        if (joinListSnap.connectionState == ConnectionState.waiting) {
                          return Container();
                        } else if (joinListSnap.hasError) {
                          return Text('Error: ${joinListSnap.error}');
                        } else {
                          return Column(
                            children: [
                              Container(
                                padding: EdgeInsets.only(top: 10),
                                margin: EdgeInsets.all(20),
                                child: Column(
                                  children: joinListSnap.data ?? [Container()],
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  )
                ],
              ),
            ]
        ),
      ),
    );
  }
}
