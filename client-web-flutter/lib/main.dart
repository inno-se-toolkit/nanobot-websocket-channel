import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'chat_screen.dart';
import 'login_screen.dart';

void main() {
  runApp(const ChatbotApp());
}

class ChatbotApp extends StatefulWidget {
  const ChatbotApp({super.key});

  @override
  State<ChatbotApp> createState() => _ChatbotAppState();
}

class _ChatbotAppState extends State<ChatbotApp> {
  String _token = '';

  @override
  void initState() {
    super.initState();
    _token = web.window.localStorage.getItem('api_key') ?? '';
  }

  void _handleLogin(String token) {
    setState(() => _token = token);
  }

  void _handleDisconnect() {
    web.window.localStorage.removeItem('api_key');
    setState(() => _token = '');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LMS Chatbot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: _token.isEmpty
          ? LoginScreen(onLogin: _handleLogin)
          : ChatScreen(
              apiKey: _token,
              onDisconnect: _handleDisconnect,
            ),
    );
  }
}
