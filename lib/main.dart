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
  await flutterLocalNotificationsPlugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings()));
  await _requestPermissions();
}

Future<void> _requestPermissions() async {
  if (Platform.isIOS) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  } else if (Platform.isAndroid) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  if (!(await service.isRunning())) {
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        autoStart: true,
        onStart: onStart,
        isForegroundMode: true,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: iosBackground,
      ),
    );
  }
}

Future<void> _showNotification(final String tile, final String body) async {
  await flutterLocalNotificationsPlugin.show(
    notificationId++,
    tile,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
          'SwitchboxNotificationChannel', 'Switchbox Notification Channel',
          channelDescription: 'Notification Channel for Switchbox',
          importance: Importance.max,
          priority: Priority.high),
      iOS: DarwinNotificationDetails(),
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  DartPluginRegistrant.ensureInitialized();

  pollForNotifications();
}

void pollForNotifications() {
  print('starting polling...');
  Stream.periodic(const Duration(seconds: 2)).asyncMap((_) async {
    return "Notification message";
  }).listen((notification) {
    print('showing notification...');
    _showNotification("Notification title...",notification);
  });
}

@pragma("vm:enry-point")
Future<bool> iosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  pollForNotifications();

  return true;
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
          'You should receive many notifications, even when closing the app.',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black),
          textAlign: TextAlign.center,
        ),
      )
    );
  }
}
