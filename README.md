# poli-images-back

## Como executar a aplicação

## Pré-requisitos
* MongoDB (local ou Atlas)

1. Clone o repositório
```
https://github.com/PoliImages/poli-images-back.git
```

2. Instale as dependências
```
dart pub get
```
## Configurando o .env
3. Configure as variáveis de ambiente

Crie um arquivo .env na pasta backend com as seguintes variáveis:

```
MONGODB_URI=sua_conexao_mongodb
GEMINI_API_KEY=sua_chave_API
```

4. Execute a aplicação
```
dart run bin/poli_images_back.dart
```