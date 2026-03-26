import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class LoginScreen extends StatefulWidget {
  final void Function(String token) onLogin;

  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _controller = TextEditingController();
  String? _error;
  bool _loading = false;

  Future<void> _handleConnect() async {
    final key = _controller.text.trim();
    if (key.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await web.window.fetch(
        '/items/'.toJS,
        web.RequestInit(
          method: 'GET',
          headers: {'Authorization': 'Bearer $key'}.jsify() as JSObject,
        ),
      ).toDart;

      if (!response.ok) {
        setState(() {
          _error = 'Invalid API key';
          _loading = false;
        });
        return;
      }

      web.window.localStorage.setItem('api_key', key);
      widget.onLogin(key);
    } catch (_) {
      setState(() {
        _error = 'Could not reach the server';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('LMS API Key',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  const Text('Enter your LMS API key to connect.'),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _controller,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Token',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _handleConnect(),
                    enabled: !_loading,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _handleConnect,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Connect'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
