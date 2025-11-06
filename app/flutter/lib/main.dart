// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';

import 'package:ditto_ffi_app/native/ditto_bindings.dart';
import 'package:ditto_ffi_app/native/ditto_db.dart';
import 'package:flutter/material.dart';

import 'native/ditto_loader.dart';

void main() {
  runApp(const DittoDbApp());
}

const dittoBlack = Color(0xFF0a0a0a);
const dittoYellow = Color(0xFFeaf044);
const spacing = 20.0;

class DittoDbApp extends StatelessWidget {
  const DittoDbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ditto Database',
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: dittoYellow,
        ).copyWith(
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: dittoBlack,
              displayColor: dittoBlack,
            ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
              backgroundColor: dittoYellow, foregroundColor: dittoBlack),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: dittoBlack),
        ),
        useMaterial3: true,
      ),
      home: const DefaultPage(),
    );
  }
}

class DefaultPage extends StatefulWidget {
  const DefaultPage({super.key});

  @override
  State<DefaultPage> createState() => _DefaultPageState();
}

class _DefaultPageState extends State<DefaultPage> {
  late final DittoDb _db;
  late final StreamSubscription<String> _changeSubscription;
  final List<String> _keysChanged = <String>[];
  String _initError = '';

  @override
  void initState() {
    super.initState();
    _initError = '';
    _keysChanged.clear();
    try {
      _db = DittoDb(DittoBindings(loadNativeLibrary()));
      _db.open();
      _changeSubscription = _db.subscribe().listen((key) {
        setState(() {
          _keysChanged.insert(0, key);
        });
      });
    } catch (e) {
      setState(() {
        _initError = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _changeSubscription.cancel();
    _db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initError.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ditto Database'),
        ),
        body: Center(
            child: Column(children: [
          Text('Error initializing database',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: spacing),
          Text(_initError, style: Theme.of(context).textTheme.bodyLarge),
        ])),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ditto Database'),
        centerTitle: true,
        actions: [
          Text('Version: ${_db.version()}'),
          const SizedBox(width: spacing * 2)
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(spacing),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Container(
              width: 400,
              padding: const EdgeInsets.all(spacing * 2),
              child: SingleChildScrollView(
                  child: Column(
                children: [
                  DbOperationForm(
                      title: 'Put',
                      showValue: true,
                      onSubmit: (key, value) {
                        try {
                          _db.put(key, Uint8List.fromList(utf8.encode(value)));
                          return 'Key `$key` put ok';
                        } catch (e) {
                          rethrow;
                        }
                      }),
                  const SizedBox(height: spacing * 3),
                  DbOperationForm(
                      title: 'Get',
                      showValue: false,
                      onSubmit: (key, value) {
                        try {
                          final value = utf8.decode(_db.get(key));
                          return 'Key `$key` has value `$value`';
                        } catch (e) {
                          rethrow;
                        }
                      }),
                  const SizedBox(height: spacing * 3),
                  DbOperationForm(
                      title: 'Delete',
                      showValue: false,
                      onSubmit: (key, value) {
                        try {
                          _db.delete(key);
                          return 'Key `$key` deleted ok';
                        } catch (e) {
                          rethrow;
                        }
                      }),
                ],
              )),
            ),
            const Spacer(),
            Container(
                width: 300,
                padding: const EdgeInsets.all(spacing * 2),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Keys changed',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: spacing),
                      Expanded(
                          child: ListView.separated(
                        itemBuilder: (context, index) {
                          return Text(_keysChanged[index],
                              style: Theme.of(context).textTheme.bodyLarge);
                        },
                        separatorBuilder: (context, index) =>
                            Divider(thickness: 0, color: Colors.grey.shade300),
                        itemCount: _keysChanged.length,
                      ))
                    ])),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class DbOperationForm extends StatefulWidget {
  final String title;
  final bool showValue;
  final String Function(String key, String value) onSubmit;

  const DbOperationForm({
    super.key,
    required this.title,
    required this.showValue,
    required this.onSubmit,
  });

  @override
  State<DbOperationForm> createState() => _DbOperationFormState();
}

class _DbOperationFormState extends State<DbOperationForm> {
  final TextEditingController keyController = TextEditingController();
  final TextEditingController valueController = TextEditingController();
  String infoMessage = '';
  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: spacing / 2),
        TextField(
            controller: keyController,
            decoration: const InputDecoration(labelText: 'Key')),
        if (widget.showValue)
          TextField(
              controller: valueController,
              decoration: const InputDecoration(labelText: 'Value')),
        const SizedBox(height: spacing),
        Row(children: [
          const Spacer(),
          TextButton(
              onPressed: () {
                keyController.clear();
                valueController.clear();
                setState(() {
                  infoMessage = '';
                  errorMessage = '';
                });
              },
              child: const Text('Clear')),
          FilledButton(
              onPressed: () {
                try {
                  final info =
                      widget.onSubmit(keyController.text, valueController.text);
                  setState(() {
                    infoMessage = info;
                    errorMessage = '';
                  });
                } catch (e) {
                  setState(() {
                    errorMessage = e.toString();
                    infoMessage = '';
                  });
                }
              },
              child: const Text('Submit')),
        ]),
        const SizedBox(height: spacing / 2),
        if (infoMessage.isEmpty && errorMessage.isEmpty) const Text(''),
        if (infoMessage.isNotEmpty)
          Text(infoMessage, style: Theme.of(context).textTheme.bodyLarge),
        if (errorMessage.isNotEmpty)
          Text(errorMessage,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.red)),
      ],
    );
  }
}
