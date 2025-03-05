import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  if (dotenv.env['API_KEY'] == null) {
    throw Exception("Erro: Variáveis de ambiente não carregadas. Verifique o arquivo .env.");
  }

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['API_KEY']!,
      appId: dotenv.env['APP_ID']!,
      messagingSenderId: dotenv.env['MESSAGING_SENDER_ID']!,
      projectId: dotenv.env['PROJECT_ID']!,
      databaseURL: dotenv.env['DATABASE_URL']!,
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _produtos = [];

  TextEditingController _codigoController = TextEditingController();
  TextEditingController _descricaoController = TextEditingController();
  TextEditingController _valorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getProdutos();
  }

  Future<void> _getProdutos() async {
    _database.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        List<Map<String, dynamic>> listaProdutos = [];
        data.forEach((key, value) {
          listaProdutos.add({
            'codigo': value['codigo'],
            'descricao': value['descricao'],
            'valor': value['valor'],
          });
        });

        setState(() {
          _produtos = listaProdutos;
        });
      }
    });
  }



  Future<void> _adicionarProduto() async {
    if (double.tryParse(_valorController.text) == null) {
    return;
    } 
    String id = _database.push().key ?? "0";

      await _database.child(id).set({
        'codigo': _codigoController.text,
        'descricao': _descricaoController.text,
        'valor': double.parse(_valorController.text).toStringAsFixed(2),
      });

      _codigoController.clear();
      _descricaoController.clear();
      _valorController.clear();
      _getProdutos();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Cadastro de Produtos")),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _codigoController,
                decoration: InputDecoration(labelText: "Código do Produto"),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              TextField(
                controller: _descricaoController,
                decoration: InputDecoration(labelText: "Descrição"),
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: 10),
              TextField(
                controller: _valorController,
                decoration: InputDecoration(labelText: "Valor"),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _adicionarProduto,
                child: Text("Adicionar Produto"),
              ),
              SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _produtos.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: ListTile(
                        title: Text(_produtos[index]['descricao']),
                        subtitle: Text("Código: ${_produtos[index]['codigo']} - Valor: R\\${_produtos[index]['valor']}"),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
