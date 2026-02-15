import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class RegisteredUsersScreen extends StatefulWidget {
  const RegisteredUsersScreen({super.key});
  @override
  RegisteredUsersScreenState createState() => RegisteredUsersScreenState();
}

class RegisteredUsersScreenState extends State<RegisteredUsersScreen> {
  List<Directory> _folders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final appDir = await getApplicationDocumentsDirectory();
    final usersDir = Directory('${appDir.path}/users');
    if (!await usersDir.exists()) await usersDir.create(recursive: true);
    final list = usersDir.listSync().whereType<Directory>().toList();
    setState(() => _folders = list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recorded Data',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 34, 36, 51),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/arkaplan.png'),
            fit: BoxFit.cover,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child:
            _folders.isEmpty
                ? const Center(
                  child: Text(
                    'No users found!',
                    style: TextStyle(color: Colors.white),
                  ),
                )
                : ListView.builder(
                  itemCount: _folders.length,
                  itemBuilder: (_, i) {
                    final f = _folders[i];
                    final name = f.path.split(Platform.pathSeparator).last;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          // KULLANICI GÖRÜNTÜLEME BUTONU
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              onPressed: () async {
                                final txtFile = File(
                                  '${f.path}/analysis_results.txt',
                                );
                                String analysis;
                                if (await txtFile.exists()) {
                                  analysis = await txtFile.readAsString();
                                } else {
                                  analysis = 'Analysis file not found.';
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => Scaffold(
                                          appBar: AppBar(
                                            title: Text(
                                              name,
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            backgroundColor:
                                                const Color.fromARGB(
                                                  255,
                                                  34,
                                                  36,
                                                  51,
                                                ),
                                            iconTheme: const IconThemeData(
                                              color: Colors.white,
                                            ),
                                          ),
                                          body: SingleChildScrollView(
                                            padding: const EdgeInsets.all(16),
                                            child: Card(
                                              color: const Color.fromARGB(
                                                31,
                                                43,
                                                42,
                                                42,
                                              ),
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                child: Text(
                                                  analysis,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                  ),
                                );
                              },
                              child: Text(name),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // SİLME BUTONU
                          IconButton(
                            icon: const Icon(
                              Icons.delete_forever,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder:
                                    (ctx) => AlertDialog(
                                      title: const Text('Delete'),
                                      content: Text('Delete $name?'),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(ctx, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(ctx, true),
                                          child: const Icon(
                                            Icons.delete_forever,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                              );

                              if (confirm == true) {
                                await f.delete(recursive: true);
                                setState(() => _folders.removeAt(i));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('$name deleted')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
