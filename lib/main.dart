import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_html/flutter_html.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oh-o! Meiji',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ログイン'),
      ),
      body: WebView(
        initialUrl: 'https://oh-o2.meiji.ac.jp/portal/sso',
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          _controller = webViewController;
        },
        navigationDelegate: (NavigationRequest request) {
          if (request.url == 'https://oh-o2.meiji.ac.jp/portal/oh-o_meiji/') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Announcement> _announcements = [];
  String _sourceUrl =
      'https://m.oh-o2.meiji.ac.jp/OhoMeijiSS/information_top.action';

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    final response = await http.get(Uri.parse(_sourceUrl));
    if (response.statusCode == 200) {
      setState(() {
        var document = response.body;
        var elements = document
            .split('<div class="informationDetailLinker list-box clearfix">');
        _announcements = elements.skip(1).map((element) {
          var titleStart = element.indexOf('<div class="title"><span><p') +
              '<div class="title"><span><p style="overflow: hidden;white-space:nowrap;text-overflow:ellipsis;font-weight:normal;">'
                  .length;
          var titleEnd = element.indexOf('</p>', titleStart);
          var detailStart = element.indexOf(
                  '<div class="content clearfix text"><p class="textGray">') +
              '<div class="content clearfix text"><p class="textGray">'.length;
          var detailEnd = element.indexOf('</p>', detailStart);
          var title = element.substring(titleStart, titleEnd).trim();
          var detail = element.substring(detailStart, detailEnd).trim();
          return Announcement(
            title: title,
            detail: detail,
          );
        }).toList();
      });
    }
  }

  void _showAnnouncementDetail(Announcement announcement) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(announcement.title),
          content: SingleChildScrollView(
            child: Html(data: announcement.detail),
          ),
          actions: [
            TextButton(
              child: Text('閉じる'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    Center(child: Text('ホーム')),
    Center(child: Text('時間割')),
    Center(child: Text('グループ')),
    Center(child: Text('設定')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ホーム'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _announcements.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_announcements[index].title),
                  onTap: () {
                    _showAnnouncementDetail(_announcements[index]);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text('取得元URL: $_sourceUrl'),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: '時間割',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'グループ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}

class Announcement {
  final String title;
  final String detail;

  Announcement({required this.title, required this.detail});
}
