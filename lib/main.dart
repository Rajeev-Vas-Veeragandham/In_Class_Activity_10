import 'package:flutter/material.dart';
import 'database_helper.dart';

final dbHelper = DatabaseHelper();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dbHelper.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SQLite Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> _records = [];
  final TextEditingController _idInsertController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _idController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final allRows = await dbHelper.queryAllRows();
    setState(() {
      _records = allRows;
    });
  }

  Future<void> _insert() async {
    if (_nameController.text.isEmpty || _ageController.text.isEmpty) return;

    final idText = _idInsertController.text.trim();
    int? id = idText.isNotEmpty ? int.tryParse(idText) : null;

    Map<String, dynamic> row = {
      if (id != null) DatabaseHelper.columnId: id,
      DatabaseHelper.columnName: _nameController.text,
      DatabaseHelper.columnAge: int.tryParse(_ageController.text) ?? 0,
    };

    await dbHelper.insert(row);
    _idInsertController.clear();
    _nameController.clear();
    _ageController.clear();
    await _refresh();
  }

  Future<void> _queryById() async {
    if (_idController.text.isEmpty) return;
    int id = int.parse(_idController.text);
    final row = await dbHelper.queryRowById(id);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Record by ID"),
        content: row != null
            ? Text(row.toString())
            : const Text("No record found for that ID."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK")),
        ],
      ),
    );
    _idController.clear();
  }

  Future<void> _deleteAll() async {
    await dbHelper.deleteAll();
    await _refresh();
  }

  Future<void> _updateDialog() async {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final ageController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Update Record"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Enter ID"),
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "New Name"),
            ),
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "New Age"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final id = int.tryParse(idController.text);
              final name = nameController.text;
              final age = int.tryParse(ageController.text);

              if (id != null && name.isNotEmpty && age != null) {
                await dbHelper.update({
                  DatabaseHelper.columnId: id,
                  DatabaseHelper.columnName: name,
                  DatabaseHelper.columnAge: age,
                });
                await _refresh();
                Navigator.pop(context);
              }
            },
            child: const Text("Update"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDialog() async {
    final idController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Record"),
        content: TextField(
          controller: idController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Enter ID to delete"),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final id = int.tryParse(idController.text);
              if (id != null) {
                await dbHelper.delete(id);
                await _refresh();
                Navigator.pop(context);
              }
            },
            child: const Text("Delete"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SQLite Local Database Application'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ✅ New ID input for Insert
            TextField(
              controller: _idInsertController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter ID (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            // Name and Age inputs
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Insert Record"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              onPressed: _insert,
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _idController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter ID to Search',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.search),
                    label: const Text("Find by ID"),
                    onPressed: _queryById,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.delete_forever),
                    label: const Text("Delete All"),
                    onPressed: _deleteAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "All Records",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: _records.isEmpty
                  ? const Center(child: Text("No data available"))
                  : ListView.builder(
                      itemCount: _records.length,
                      itemBuilder: (context, index) {
                        final item = _records[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal,
                              child: Text(item['_id'].toString()),
                            ),
                            title: Text(item['name']),
                            subtitle: Text("Age: ${item['age']}"),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              color: Colors.red,
                              onPressed: () async {
                                await dbHelper.delete(item['_id']);
                                await _refresh();
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      // ✅ Bottom Buttons
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        color: Colors.teal.shade50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBottomButton(Icons.add, 'Insert', _insert),
            _buildBottomButton(Icons.list, 'Query', _refresh),
            _buildBottomButton(Icons.edit, 'Update', _updateDialog),
            _buildBottomButton(Icons.delete, 'Delete', _deleteDialog),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(
      IconData icon, String text, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
