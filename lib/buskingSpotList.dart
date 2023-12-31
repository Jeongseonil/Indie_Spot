import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:indie_spot/addBuskingSpot.dart';
import 'package:indie_spot/baseBar.dart';
import 'package:indie_spot/spotDetailed.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:indie_spot/userModel.dart';
import 'package:provider/provider.dart';
import 'dialog.dart';

class BuskingZoneList extends StatefulWidget {
  @override
  State<BuskingZoneList> createState() => _BuskingZoneListState();
}

class _BuskingZoneListState extends State<BuskingZoneList> {
  int _currentTabIndex = 0;
  final _searchControl = TextEditingController();
  final List<String> _regions = ['전국', '서울', '부산', '인천', '강원', '경기', '경남', '경북', '광주', '대구', '대전', '울산', '전남', '전북', '제주', '충남', '충북'];


  Query getSelectedCollection(FirebaseFirestore fs) {
    if (_currentTabIndex == 0) {
      return fs.collection('busking_spot');
    } else {
      String selectedRegion = _regions[_currentTabIndex]; // -1을 해서 _regions 리스트에 맞는 값으로 선택
      return fs.collection('busking_spot').where('regions', isEqualTo: selectedRegion);
    }
  }

  Widget _spotList() {

    FirebaseFirestore fs = FirebaseFirestore.instance;
    CollectionReference spots = fs.collection('busking_spot');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            cursorColor: Color(0xFF233067),
            decoration: InputDecoration(
              hintText: '검색',
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF233067))
              ),
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF233067))
              ),
              prefixIcon: Icon(Icons.search, color: Color(0xFF233067),),
            ),
            controller: _searchControl,
            textInputAction: TextInputAction.go,
            onSubmitted: (value) {
              FocusScope.of(context).unfocus();
              setState(() {});
            },
          ),
        ),
        Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getSelectedCollection(fs).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot document = snapshot.data!.docs[index];
                    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                    if (data['spotName'].contains(_searchControl.text)) {
                      return FutureBuilder<QuerySnapshot>(
                        future: spots.doc(document.id).collection('addr').limit(1).get(),
                        builder: (context, addrSnapshot) {
                          if (addrSnapshot.connectionState == ConnectionState.waiting) {
                            return Container(); // 데이터가 로딩 중이면 로딩 표시
                          }
                          if (addrSnapshot.hasError) {
                            return Text('데이터를 불러오는 중 오류가 발생했습니다.');
                          }
                          List<QueryDocumentSnapshot<Map<String, dynamic>>> addr = addrSnapshot.data!.docs as List<QueryDocumentSnapshot<Map<String, dynamic>>>;

                          // 이미지 정보를 가져오는 FutureBuilder 추가
                          return FutureBuilder<QuerySnapshot>(
                            future: spots.doc(document.id).collection('image').limit(1).get(),
                            builder: (context, imageSnapshot) {
                              if (imageSnapshot.connectionState == ConnectionState.waiting) {
                                return Container(); // 데이터가 로딩 중이면 로딩 표시
                              }
                              if (imageSnapshot.hasError) {
                                return Text('이미지를 불러오는 중 오류가 발생했습니다.');
                              }
                              List<QueryDocumentSnapshot<Map<String, dynamic>>> images = imageSnapshot.data!.docs as List<QueryDocumentSnapshot<Map<String, dynamic>>>;

                              // 이미지와 주소를 사용하여 ListTile을 생성
                              return Container(
                                  padding: EdgeInsets.only(bottom: 5, top: 5),
                                  decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 1, color: Color(0xFFEEEEEE)))),
                                  child: ListTile(
                                    visualDensity: VisualDensity(vertical: 4),
                                    title: Text(data['spotName']),
                                    subtitle: Text(addr[0].data()['addr']),
                                    contentPadding: EdgeInsets.only(top: 0, bottom: 15, left: 15, right: 15),
                                    leading: Container(
                                      height: double.infinity,
                                      width: 100,
                                      child: CachedNetworkImage(
                                        imageUrl: images[0].data()['path'], // 이미지 URL
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Center(child: CircularProgressIndicator()), // 이미지 로딩 중에 표시될 위젯
                                        errorWidget: (context, url, error) => Icon(Icons.error), // 이미지 로딩 오류 시 표시될 위젯
                                      ),
                                    ),
                                    trailing: Icon(Icons.chevron_right),
                                    onTap: () {
                                      Get.to(
                                        ()=> SpotDetailed(data, addr, images, document.id),
                                        transition: Transition.noTransition
                                      );
                                    },
                                  ),
                                );
                             },
                          );
                        },
                      );
                    } else {
                      return Container();
                    }
                  },
                );
              },
            )
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: _regions.length,
        child: Scaffold(
            drawer: MyDrawer(),
            backgroundColor: Colors.white,
            appBar: AppBar(
              actions: [
                Builder(
                    builder: (context) {
                      return IconButton(
                          onPressed: (){
                            Scaffold.of(context).openDrawer();
                          },
                          icon: Icon(Icons.menu),color: Colors.white);
                    }
                ),
              ],
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back, // 뒤로가기 아이콘
                  color: Colors.white, // 원하는 색상으로 변경
                ),
                onPressed: () {
                  // 뒤로가기 버튼을 눌렀을 때 수행할 작업
                  Navigator.of(context).pop(); // 이 코드는 화면을 닫는 예제입니다
                },
              ),
              backgroundColor: Color(0xFF233067),
              centerTitle: true,
              title: Text('버스킹존 목록', style: TextStyle(color: Colors.white),),
              bottom: TabBar(
                isScrollable: true,
                indicatorColor: Colors.white,
                tabs: [
                  for(String region in _regions)
                    Tab(
                      child: Text(region, style: TextStyle(color: Colors.white),),
                    )
                ],
                unselectedLabelColor: Colors.black, // 선택되지 않은 탭의 텍스트 색상
                labelColor: Colors.blue,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold, // 선택된 탭의 텍스트 굵기 설정
                ),
                unselectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.normal, // 선택되지 않은 탭의 텍스트 굵기 설정
                ),
                onTap: (value) {
                  setState(() {
                    _currentTabIndex = value; // 탭 선택 변경
                  });
                },
              ),
              elevation: 1,
            ),
          body: _spotList(),
          bottomNavigationBar: MyBottomBar(),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Color(0xFF233067),
            onPressed: (){
              if(Provider.of<UserModel>(context, listen: false).isLogin){
                Get.to(
                    AddBuskingSpot(),
                    transition: Transition.noTransition
                )!.then((value) => setState(() {}));
              } else {
                DialogHelper.showUserRegistrationDialog(context);
              }
            },
            child: Icon(Icons.edit),
          ),
        )
    );
  }
}