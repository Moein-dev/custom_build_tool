import 'package:example/app_info_model.dart';
import 'package:example/get_app_info.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppInfoModel info = await GetAppInfo.details();

  runApp(
    MyApp(info: info),
  );
}

class MyApp extends StatelessWidget {
  final AppInfoModel info;
  const MyApp({
    Key? key,
    required this.info,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(
        title: 'Custom build tool Example',
        info: info,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final AppInfoModel info;
  const MyHomePage({
    Key? key,
    required this.title,
    required this.info,
  }) : super(
          key: key,
        );

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'this is your app Version:',
            ),
            Text(
              widget.info.appVersion!,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}
