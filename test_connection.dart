// test_connection.dart
import 'package:mongo_dart/mongo_dart.dart';

void main() async {
  // --- ATENÇÃO AQUI ---
  // Cole sua string de conexão COMPLETA e CORRIGIDA dentro das aspas abaixo.
  // Verifique se NÃO há < > ao redor do usuário e senha.
  var connectionString = "mongodb+srv://ferrassini2018:1p4Pmjyp5UpuojdL@poliimages.ijmat38.mongodb.net/?retryWrites=true&w=majority";

  Db? db;
  try {
    print("Tentando conectar ao MongoDB Atlas...");
    db = await Db.create(connectionString);
    await db.open();
    print("✅ CONEXÃO COM O MONGODB BEM SUCEDIDA!");
    print("O problema NÃO está nas suas credenciais ou no acesso por IP.");
  } catch (e) {
    print("❌ FALHA NA CONEXÃO.");
    print("O problema DEFINITIVAMENTE está nas suas credenciais ou no acesso por IP.");
    print("\n--- Detalhes do Erro ---");
    print(e);
    print("----------------------");
  } finally {
    await db?.close();
  }
}