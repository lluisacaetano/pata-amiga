// Biblioteca dart:convert: converte texto em bytes (utf8) e bytes em base64.
import 'dart:convert';
// Biblioteca dart:math: Random.secure, para sortear o sal da senha.
import 'dart:math';

// Pacote crypto: calcula o resumo SHA-256 usado para guardar a senha.
import 'package:crypto/crypto.dart';
// Pacote flutter/material: ChangeNotifier, que avisa as telas das mudanças.
import 'package:flutter/material.dart';
// Pacote shared_preferences: guarda dados simples no aparelho (chave e valor).
import 'package:shared_preferences/shared_preferences.dart';

// Arquivo usuario.dart: modelo do usuário e a conversão do perfil salvo.
import '../modelos/usuario.dart';

// Resultado da tentativa de entrar com e-mail e senha
enum ResultadoDoLogin { entrou, semConta, senhaIncorreta }

// Resultado da redefinição de senha pelo e-mail e telefone da conta
enum ResultadoDaRedefinicao {
  redefinida,
  semConta,
  telefoneDiferente,
  mesmaSenha,
}

// Perfil de quem está logado. O perfil fica salvo no aparelho, um por
// e-mail, e a sessão é o e-mail gravado em [_chaveSessao]. A senha nunca é
// guardada: só um resumo SHA-256 dela, com um sal sorteado por conta
class UsuarioProvider extends ChangeNotifier {
  static const _chaveUsuario = 'usuario_perfil:';
  static const _chaveSenha = 'usuario_senha:';
  static const _chaveSessao = 'loggedInEmail';

  Usuario _usuario = Usuario(nome: '', email: '', senha: '', telefone: '');

  Usuario get usuario => _usuario;

  // Há uma sessão aberta quando o perfil atual tem e-mail
  bool get estaLogado => _usuario.email.isNotEmpty;

  // O e-mail sempre em minúsculas e sem espaços, para que "Ana@x.com" e
  // "ana@x.com" sejam a mesma conta
  static String normalizarEmail(String email) => email.trim().toLowerCase();

  // Ao abrir o app, carrega o perfil da sessão salva, se houver
  Future<void> restaurarSessao() async {
    final armazenamento = await SharedPreferences.getInstance();
    final email = armazenamento.getString(_chaveSessao);
    if (email == null) return;
    await carregarUsuario(email);
  }

  // Indica se já existe uma conta salva neste aparelho para o e-mail
  Future<bool> contaExiste(String email) async {
    final armazenamento = await SharedPreferences.getInstance();
    return await _perfilSalvo(armazenamento, normalizarEmail(email)) != null;
  }

  // Cria o perfil de uma conta nova, guarda o resumo da senha (quando
  // informada) e já abre a sessão. Devolve false, sem alterar nada, quando
  // o e-mail já pertence a outra conta, para não sobrescrever o perfil e a
  // senha dela
  Future<bool> registrarUsuario({
    required String nome,
    required String email,
    required String telefone,
    String? senha,
  }) async {
    if (await contaExiste(email)) return false;
    _usuario = Usuario(
      nome: nome.trim(),
      email: normalizarEmail(email),
      senha: '',
      telefone: telefone.trim(),
    );
    notifyListeners();
    await _salvarPerfil();
    if (senha != null) await _guardarSenha(_usuario.email, senha);
    return true;
  }

  // Define uma senha nova para a conta do e-mail, desde que o telefone
  // informado seja o mesmo do perfil (comparando só os dígitos) e a senha
  // nova seja diferente da atual. Não abre a sessão: a pessoa entra depois
  // com a senha nova
  Future<ResultadoDaRedefinicao> redefinirSenha({
    required String email,
    required String telefone,
    required String senha,
  }) async {
    final armazenamento = await SharedPreferences.getInstance();
    final normalizado = normalizarEmail(email);
    final salvo = await _perfilSalvo(armazenamento, normalizado);
    if (salvo == null) return ResultadoDaRedefinicao.semConta;
    String digitos(String texto) => texto.replaceAll(RegExp(r'\D'), '');
    final doPerfil = digitos(Usuario.fromProfileJson(salvo).telefone);
    if (doPerfil.isEmpty || doPerfil != digitos(telefone)) {
      return ResultadoDaRedefinicao.telefoneDiferente;
    }
    final guardada = armazenamento.getString('$_chaveSenha$normalizado');
    if (guardada != null && _confere(senha, guardada)) {
      return ResultadoDaRedefinicao.mesmaSenha;
    }
    await _guardarSenha(normalizado, senha);
    return ResultadoDaRedefinicao.redefinida;
  }

  // Confere e-mail e senha com o perfil salvo no aparelho e, se baterem,
  // abre a sessão. Conta criada antes de a senha ser guardada entra e passa
  // a ter a senha digitada como a sua
  Future<ResultadoDoLogin> entrar(String email, String senha) async {
    final armazenamento = await SharedPreferences.getInstance();
    final normalizado = normalizarEmail(email);
    if (await _perfilSalvo(armazenamento, normalizado) == null) {
      return ResultadoDoLogin.semConta;
    }
    final guardada = armazenamento.getString('$_chaveSenha$normalizado');
    if (guardada == null) {
      await _guardarSenha(normalizado, senha);
    } else if (!_confere(senha, guardada)) {
      return ResultadoDoLogin.senhaIncorreta;
    }
    await carregarUsuario(normalizado);
    return ResultadoDoLogin.entrou;
  }

  // Carrega o perfil salvo para o e-mail (ou um perfil vazio, se não houver)
  // e grava esse e-mail como a sessão atual
  Future<void> carregarUsuario(String email) async {
    final armazenamento = await SharedPreferences.getInstance();
    final normalizado = normalizarEmail(email);
    final salvo = await _perfilSalvo(armazenamento, normalizado);
    _usuario = salvo == null
        ? Usuario(nome: '', email: normalizado, senha: '')
        : Usuario.fromProfileJson(salvo);
    await armazenamento.setString(_chaveSessao, normalizado);
    notifyListeners();
  }

  // Troca nome, telefone e foto do perfil atual e salva no aparelho
  Future<void> atualizarUsuario({
    required String nome,
    required String telefone,
    String? foto,
  }) {
    _usuario = Usuario(
      nome: nome,
      email: _usuario.email,
      senha: _usuario.senha,
      telefone: telefone,
      foto: foto,
    );

    notifyListeners();
    return _salvarPerfil();
  }

  // Encerra a sessão; o perfil continua salvo no aparelho para o próximo
  // login com o mesmo e-mail
  Future<void> encerrarSessao() async {
    final armazenamento = await SharedPreferences.getInstance();
    await armazenamento.remove(_chaveSessao);
    _usuario = Usuario(nome: '', email: '', senha: '');
    notifyListeners();
  }

  // Grava o perfil na chave do e-mail e mantém a sessão nesse e-mail
  Future<void> _salvarPerfil() async {
    if (_usuario.email.isEmpty) return;
    final armazenamento = await SharedPreferences.getInstance();
    await armazenamento.setString(
      '$_chaveUsuario${_usuario.email}',
      _usuario.toProfileJson(),
    );
    await armazenamento.setString(_chaveSessao, _usuario.email);
  }

  // Perfil gravado para o e-mail já normalizado. Um perfil antigo, gravado
  // com maiúsculas no e-mail, é encontrado e passa para a chave nova
  Future<String?> _perfilSalvo(
    SharedPreferences armazenamento,
    String normalizado,
  ) async {
    final chave = '$_chaveUsuario$normalizado';
    final salvo = armazenamento.getString(chave);
    if (salvo != null) return salvo;
    for (final antiga in armazenamento.getKeys()) {
      if (!antiga.startsWith(_chaveUsuario) || antiga.toLowerCase() != chave) {
        continue;
      }
      final perfil = armazenamento.getString(antiga);
      if (perfil == null) continue;
      final usuario = Usuario.fromProfileJson(perfil);
      final convertido = Usuario(
        nome: usuario.nome,
        email: normalizado,
        senha: '',
        telefone: usuario.telefone,
        foto: usuario.foto,
      ).toProfileJson();
      await armazenamento.setString(chave, convertido);
      await armazenamento.remove(antiga);
      return convertido;
    }
    return null;
  }

  // Guarda "sal:resumo" da senha. O sal é sorteado a cada senha nova
  Future<void> _guardarSenha(String email, String senha) async {
    final aleatorio = Random.secure();
    final sal = base64Url.encode(
      List<int>.generate(16, (_) => aleatorio.nextInt(256)),
    );
    final armazenamento = await SharedPreferences.getInstance();
    await armazenamento.setString(
      '$_chaveSenha$email',
      '$sal:${_resumo(sal, senha)}',
    );
  }

  static String _resumo(String sal, String senha) =>
      sha256.convert(utf8.encode('$sal$senha')).toString();

  static bool _confere(String senha, String guardada) {
    final separador = guardada.indexOf(':');
    if (separador < 0) return false;
    final sal = guardada.substring(0, separador);
    return _resumo(sal, senha) == guardada.substring(separador + 1);
  }
}
