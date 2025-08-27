// test_connection.dart
import 'package:mongo_dart/mongo_dart.dart';

void main() async {
  // --- ATENÇÃO AQUI ---
  // Cole sua string de conexão COMPLETA e CORRIGIDA dentro das aspas abaixo.
  // Verifique se NÃO há < > ao redor do usuário e senha.

  Db db = Db('mongodb://ferrassini2018:1p4Pmjyp5UpuojdL@ac-3mo8ulh-shard-00-02.ijmat38.mongodb.net:27017,ac-3mo8ulh-shard-00-01.ijmat38.mongodb.net:27017,ac-3mo8ulh-shard-00-00.ijmat38.mongodb.net:27017/test');
  try {
    await db.open(
      secure: true,
    );
    print("✅ CONEXÃO COM O MONGODB BEM SUCEDIDA!");
    print("O problema NÃO está nas suas credenciais ou no acesso por IP.");
  } catch (e) {
    print("❌ FALHA NA CONEXÃO.");
    print("O problema DEFINITIVAMENTE está nas suas credenciais ou no acesso por IP.");
    print("\n--- Detalhes do Erro ---");
    print(e);
    print("----------------------");
  } finally {
    await db.close();
  }

  // Db? db;
  // try {
  //   print("Tentando conectar ao MongoDB Atlas...");
  //   db = await Db.create(connectionString);
  //   await db.open();
  //   print("✅ CONEXÃO COM O MONGODB BEM SUCEDIDA!");
  //   print("O problema NÃO está nas suas credenciais ou no acesso por IP.");
  // } catch (e) {
  //   print("❌ FALHA NA CONEXÃO.");
  //   print("O problema DEFINITIVAMENTE está nas suas credenciais ou no acesso por IP.");
  //   print("\n--- Detalhes do Erro ---");
  //   print(e);
  //   print("----------------------");
  // } finally {
  //   await db?.close();
  // }
}