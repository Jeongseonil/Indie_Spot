import 'package:flutter/material.dart';


// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   if (message.notification != null && message.notification!.body != null) {
//     print("백그라운드 메시지 처리 => ${message.notification!.body}");
//   } else{
//     print("백그라운드 메시지 처리 오류");
//   }
// }
//
// void initializeNotification() async {
//   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//
//   final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//   await flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<
//           AndroidFlutterLocalNotificationsPlugin>()
//       ?.createNotificationChannel(const AndroidNotificationChannel(
//           'high_importance_channel', 'high_importance_notification',
//           importance: Importance.max));
//
//   await flutterLocalNotificationsPlugin.initialize(const InitializationSettings(
//     android: AndroidInitializationSettings("@mipmap/ic_launcher"),
//   ));
//
//   await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
//     alert: true,
//     badge: true,
//     sound: true
//   );
// }
//
// Future<void> main() async {
//
//   FirebaseOptions firebaseOptions = FirebaseOptions(
//     appId: '1:747945249445:android:585efff7364ef9166c5b4c',
//     apiKey: 'AIzaSyBAEerXfvy9qSD_etVmxm4ymhj8bP8q9Qc',
//     messagingSenderId: '747945249445',
//     projectId: 'indiespot-7d691',
//     storageBucket: 'gs://indiespot-7d691.appspot.com', // 시발 이거 어딨어
//   );
//
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: firebaseOptions,
//   );
//   initializeNotification();
//   runApp(MaterialApp(
//     title: 'Flutter Demo',
//     theme: ThemeData(
//       primaryColor: Colors.blue,
//     ),
//     home: LcsTest(),
//   ));
// }
//
//
// class LcsTest extends StatefulWidget {
//   const LcsTest({super.key});
//
//   @override
//   State<LcsTest> createState() => _LcsTestState();
// }
//
// class _LcsTestState extends State<LcsTest> {
//   var messageString = "";
//
//   void getMyDeviceToken() async {
//     final token = await FirebaseMessaging.instance.getToken();
//     print("내 디바이스 토큰 => $token");
//   }
//
//   @override
//   void initState() {
//     getMyDeviceToken();
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) async{
//       RemoteNotification? notification = message.notification;
//
//       if(notification != null){
//         FlutterLocalNotificationsPlugin().show(
//             notification.hashCode,
//             notification.title,
//             notification.body,
//             const NotificationDetails(
//               android: AndroidNotificationDetails(
//                   'high_importance_channel',
//                   'high_importance_notification',
//                   importance: Importance.max,
//               ),
//             ),
//         );
//         setState(() {
//           messageString = message.notification!.body!;
//           print("Foreground 메시지 수신: $messageString");
//         });
//       }
//     });
//     super.initState();
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("되라 알림 제발"),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text("메시지 내용 => $messageString"),
//           ],
//         ),
//       ),
//     );
//   }
//
//}

import 'loading.dart'; // 로딩 테스트


class LcsTest extends StatelessWidget {
  const LcsTest({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Loading Spinner Example'),
          actions: [
            IconButton(
                onPressed: (){
                  Navigator.of(context).pop();
                },
                icon: Icon(Icons.arrow_back)
            ),
          ],
        ),
        body: Center(
          child: LoadingWidget(), // 로딩 스피너 위젯 호출
        ),
      ),
    );
  }
}
