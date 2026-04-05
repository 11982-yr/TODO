import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const TodoPage(),
    );
  }
}

class Todo {
  final int id;
  final String title;
  final bool done;

  Todo({
    required this.id,
    required this.title,
    required this.done,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      title: json['title'],
      done: json['done'],
    );
  }
}

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final TextEditingController _controller = TextEditingController();

  // Android emulator:
  // static const String baseUrl = 'http://10.0.2.2:8000';

  // iOS simulator / desktop:
  static const String baseUrl = 'http://127.0.0.1:8000';

  List<Todo> todos = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchTodos();
  }

  Future<void> fetchTodos() async {
    setState(() => loading = true);
    final res = await http.get(Uri.parse('$baseUrl/todos'));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      setState(() {
        todos = data.map((e) => Todo.fromJson(e)).toList();
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  Future<void> addTodo() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final res = await http.post(
      Uri.parse('$baseUrl/todos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': text}),
    );

    if (res.statusCode == 200) {
      _controller.clear();
      fetchTodos();
    }
  }

  Future<void> toggleTodo(Todo todo) async {
    final res = await http.put(
      Uri.parse('$baseUrl/todos/${todo.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'done': !todo.done}),
    );

    if (res.statusCode == 200) {
      fetchTodos();
    }
  }

  Future<void> deleteTodo(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/todos/$id'));
    if (res.statusCode == 200) {
      fetchTodos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todo App')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Add a task',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: addTodo,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: todos.length,
                      itemBuilder: (context, index) {
                        final todo = todos[index];
                        return Card(
                          child: ListTile(
                            leading: Checkbox(
                              value: todo.done,
                              onChanged: (_) => toggleTodo(todo),
                            ),
                            title: Text(
                              todo.title,
                              style: TextStyle(
                                decoration: todo.done
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => deleteTodo(todo.id),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
