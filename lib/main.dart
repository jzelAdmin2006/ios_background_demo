import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

int notificationId = 1;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const App());
  Future.wait([initializeService(), initNotifications()]);
}

Future<void> initNotifications() async {
  var initializationSettingsAndroid = AndroidInitializationSettings('mipmap/ic_launcher');
  var initializationSettingsIOS = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) {
        // Handle notification received while app in foreground
      });

  var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      autoStart: true,
      onStart: onStart,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStartForIOS,
      onBackground: iosBackgroundTask,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  pollForNotifications(service);
}

@pragma('vm:entry-point')
void onStartForIOS(ServiceInstance service) {
  pollForNotifications(service);
}

@pragma('vm:entry-point')
Future<bool> iosBackgroundTask(ServiceInstance service) async {
  if (Platform.isIOS) {
    WidgetsFlutterBinding.ensureInitialized();
    pollForNotifications(service);
  }
  return true;
}

void pollForNotifications(ServiceInstance service) {
  service.on('stop').listen((event) {
    print('Stopping background service...');
    service.stopSelf();
  });
  print('starting polling...');

  Timer.periodic(const Duration(seconds: 30), (timer) async {
    // Customize this section with your notification logic
    print('showing notification...');
    await flutterLocalNotificationsPlugin.show(
      notificationId++,
      'Background Notification',
      'This is a background notification',
      NotificationDetails(
        android: AndroidNotificationDetails(
            'channel id', 'channel name', channelDescription: 'channel description'),
        iOS: DarwinNotificationDetails(),
      ),
    );
  });
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Background service is running',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
