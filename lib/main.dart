import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:webview_flutter/webview_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    final response = await http.get(Uri.parse(
        'https://m.oh-o2.meiji.ac.jp/OhoMeijiSS/information_top.action'));
    if (response.statusCode == 200) {
      var document = html_parser.parse(response.body);
      var elements = document
          .querySelectorAll('#information-top .informationDetailLinker');
      setState(() {
        _announcements = elements.map((element) {
          var titleElement = element.querySelector('.title p');
          var detailElement = element.querySelector('.content .textGray');
          return Announcement(
            title: titleElement?.text ?? 'No title',
            detail: detailElement?.text ?? 'No detail',
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
            child: Text(announcement.detail),
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
      body: ListView.builder(
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
