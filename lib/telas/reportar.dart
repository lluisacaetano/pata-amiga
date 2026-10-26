// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote flutter/services: Clipboard e PlatformException.
import 'package:flutter/services.dart';
// Pacote image_picker: abre a câmera ou a galeria para escolher fotos.
import 'package:image_picker/image_picker.dart';
// Pacote provider: compartilha estado entre as telas e as reconstrói.
import 'package:provider/provider.dart';
// Pacote share_plus: abre o compartilhamento do sistema (WhatsApp etc.).
import 'package:share_plus/share_plus.dart';

// Arquivo racas.dart: raças de cachorro e de gato e a busca na lista.
import '../dados/racas.dart';
// Arquivo estado_pata_amiga.dart: ONGs carregadas, para a escolha do destino.
import '../estado/estado_pata_amiga.dart';
// Arquivo denuncia.dart: modelo da denúncia, tipo e protocolo.
import '../modelos/denuncia.dart';
// Arquivo etapa_do_historico.dart: primeira etapa do histórico da denúncia.
import '../modelos/etapa_do_historico.dart';
// Arquivo ong.dart: a organização que recebe a denúncia.
import '../modelos/ong.dart';
// Arquivo texto.dart: comMaiuscula, para as opções das escolhas.
import '../modelos/texto.dart';
// Arquivo usuario_provider.dart: dados de quem denuncia, na identificada.
import '../provider/usuario_provider.dart';
// Arquivo denuncia_service.dart: serviço que registra a denúncia na API.
import '../services/denuncia_service.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';
// Arquivo barra_inferior.dart: barra de navegação inferior.
import '../widgets/barra_inferior.dart';
// Arquivo foto_animal.dart: exibição das miniaturas das fotos escolhidas.
import '../widgets/foto_animal.dart';
// Arquivo mapa_de_local.dart: centro de Formiga, ponto inicial do mapa.
import '../widgets/mapa_de_local.dart';
// Arquivo mascaras.dart: telefone da organização formatado.
import '../widgets/mascaras.dart';
// Arquivo proteger_alteracoes.dart: aviso ao sair sem salvar.
import '../widgets/proteger_alteracoes.dart';
// Arquivo selecao_com_busca.dart: seleção da raça com campo de busca.
import '../widgets/selecao_com_busca.dart';
// Arquivo seletor_de_local.dart: escolha do local no mapa.
import '../widgets/seletor_de_local.dart';
// Arquivo minhas_denuncias.dart: lista das denúncias recebidas.
import 'minhas_denuncias.dart';

// Formulário de denúncia de maus-tratos. Mostra o que diz a lei e pede a
// organização que recebe a denúncia, se ela é anônima, o animal (espécie,
// porte, sexo e, se souber, a raça), o tipo, a descrição,
// o local, a data (opcional) e as fotos. A denúncia chega à organização pelo
// app; ao registrar, exibe o protocolo e oferece também o envio pelo
// WhatsApp da organização.
//
// [servico] permite injetar um serviço falso nos testes.
class ReportarScreen extends StatefulWidget {
  final DenunciaService? servico;

  const ReportarScreen({super.key, this.servico});

  @override
  State<ReportarScreen> createState() => _ReportarScreenState();
}

// Aba Reportar da barra inferior. Para quem faz parte de uma organização que
// recebe denúncias, mostra a lista das denúncias recebidas, com o botão "+"
// para registrar uma nova; para os demais, abre direto o formulário
class AbaReportar extends StatelessWidget {
  const AbaReportar({super.key});

  @override
  Widget build(BuildContext context) {
    final email = context.watch<UsuarioProvider?>()?.usuario.email ?? '';
    final ong = PataAmigaScope.ouvindo(context)?.ongDe(email);
    if (ong != null && ong.recebeDenuncias) {
      return MinhasDenuncias(organizacao: ong);
    }
    return const ReportarScreen();
  }
}

// Limite de fotos por denúncia
const _maximoDeFotos = 5;

class _ReportarScreenState extends State<ReportarScreen> {
  late final _servico = widget.servico ?? DenunciaService();
  final _seletorDeFotos = ImagePicker();
  final _descricao = TextEditingController();
  final _rolagem = ScrollController();

  TipoDeDenuncia? _tipo;
  // O animal: espécie, porte e sexo obrigatórios; a raça é opcional
  String? _especie;
  String? _porte;
  String? _sexo;
  String? _raca;
  final _buscaDaRaca = TextEditingController();
  DateTime? _data;
  final List<XFile> _fotos = [];
  LocalEscolhido _local = (ponto: centroDeFormiga, rua: '', bairro: '');
  bool _tentou = false;
  bool _enviando = false;
  // Organização escolhida em "Enviar para"; nula até a escolha
  Ong? _escolhida;
  // Anônima: a organização não recebe nome, telefone nem e-mail de quem
  // denuncia
  bool _anonima = true;

  // As organizações que recebem denúncias, em ordem alfabética
  List<Ong> _organizacoes(BuildContext context) =>
      (PataAmigaScope.ouvindo(context)?.ongs ?? const <Ong>[])
          .where((ong) => ong.recebeDenuncias)
          .toList()
        ..sort((a, b) => a.nome.compareTo(b.nome));

  // A organização de destino: a escolhida ou, quando só uma recebe
  // denúncias, essa
  Ong? _destino(List<Ong> organizacoes) =>
      _escolhida ?? (organizacoes.length == 1 ? organizacoes.single : null);

  @override
  void dispose() {
    _descricao.dispose();
    _buscaDaRaca.dispose();
    _rolagem.dispose();
    super.dispose();
  }

  // Indica se há algo preenchido. Controla o aviso de sair sem salvar, que
  // não aparece durante o envio
  bool get _alterado =>
      !_enviando &&
      (_tipo != null ||
          _especie != null ||
          _porte != null ||
          _sexo != null ||
          _descricao.text.trim().isNotEmpty ||
          _fotos.isNotEmpty ||
          _data != null);

  // Todos os campos obrigatórios preenchidos (a data é opcional)
  bool get _completo =>
      _destino(_organizacoes(context)) != null &&
      _especie != null &&
      _porte != null &&
      _sexo != null &&
      _tipo != null &&
      _descricao.text.trim().isNotEmpty &&
      _local.rua.trim().isNotEmpty &&
      _local.bairro.trim().isNotEmpty &&
      _fotos.isNotEmpty;

  // Abre o calendário; não permite datas futuras
  Future<void> _escolherData() async {
    final hoje = DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: _data ?? hoje,
      firstDate: DateTime(2000),
      lastDate: DateTime(hoje.year, hoje.month, hoje.day),
      helpText: 'Quando aconteceu?',
    );
    if (data != null && mounted) setState(() => _data = data);
  }

  // Abre a galeria e adiciona fotos até completar o limite; as excedentes
  // são descartadas
  Future<void> _adicionarFotos() async {
    final vagas = _maximoDeFotos - _fotos.length;
    if (vagas <= 0) return;
    try {
      final escolhidas = await _seletorDeFotos.pickMultiImage(
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (!mounted || escolhidas.isEmpty) return;
      setState(() => _fotos.addAll(escolhidas.take(vagas)));
    } on PlatformException {
      _avisar('Não foi possível abrir a galeria neste aparelho.');
    }
  }

  // Mostra uma mensagem curta, substituindo a que estiver na tela
  void _avisar(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  // Valida o formulário e registra a denúncia. Se faltar algo, marca os
  // campos com erro e rola para o topo. Se registrar, mostra a folha com o
  // protocolo e fecha a tela ao concluir
  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();
    setState(() => _tentou = true);
    if (_enviando) return;
    if (!_completo) {
      _rolagem.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }
    setState(() => _enviando = true);
    final agora = DateTime.now();
    final destino = _destino(_organizacoes(context))!;
    final usuario = context.read<UsuarioProvider?>()?.usuario;
    try {
      final registrada = await _servico.registrar(
        Denuncia(
          ongId: destino.id,
          protocolo: Denuncia.novoProtocolo(agora),
          tipo: _tipo!,
          descricao: _descricao.text.trim(),
          especie: _especie!,
          porte: _porte!,
          sexo: _sexo!,
          raca: _raca ?? '',
          rua: _local.rua,
          bairro: _local.bairro,
          latitude: _local.ponto.latitude,
          longitude: _local.ponto.longitude,
          ocorridaEm: _data,
          fotos: [for (final foto in _fotos) foto.path],
          // Na anônima, nem o registro nem a mensagem levam dados de quem
          // denunciou
          anonima: _anonima,
          denuncianteNome: usuario?.nome ?? '',
          denuncianteTelefone: usuario?.telefone ?? '',
          denuncianteEmail: usuario?.email ?? '',
          registradaEm: agora,
          historico: [
            EtapaDoHistorico(
              situacao: SituacaoDaDenuncia.recebida.name,
              observacao: 'Denúncia registrada pelo app.',
              em: agora,
            ),
          ],
        ),
      );
      if (!mounted) return;
      final navegador = Navigator.of(context);
      await showModalBottomSheet<void>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        // Permite que a folha ultrapasse a altura padrão e role, o que é
        // necessário com fonte ampliada
        isScrollControlled: true,
        backgroundColor: context.cores.cartao,
        showDragHandle: true,
        builder: (_) =>
            _DenunciaRegistrada(denuncia: registrada, organizacao: destino),
      );
      // Denúncia registrada: a tela fecha sem o aviso de alterações
      navegador.pop();
    } catch (_) {
      // Qualquer falha (rede, resposta inesperada da API) destrava o botão,
      // para a pessoa poder tentar de novo
      if (!mounted) return;
      setState(() => _enviando = false);
      _avisar('Não foi possível registrar a denúncia agora. Tente de novo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final organizacoes = _organizacoes(context);
    final destino = _destino(organizacoes);
    final semDestino = _tentou && destino == null;
    final semTipo = _tentou && _tipo == null;
    final semEspecie = _tentou && _especie == null;
    final semPorte = _tentou && _porte == null;
    final semSexo = _tentou && _sexo == null;
    final semDescricao = _tentou && _descricao.text.trim().isEmpty;
    final semLocal =
        _tentou && (_local.rua.trim().isEmpty || _local.bairro.trim().isEmpty);
    final semFoto = _tentou && _fotos.isEmpty;
    return ProtegerAlteracoes(
      alterado: () => _alterado,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: context.cores.fundo,
          leadingWidth: 64,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Voltar',
              color: context.cores.principal,
              onPressed: () => Navigator.maybePop(context),
            ),
          ),
          centerTitle: true,
          title: Text(
            'DENUNCIAR MAUS-TRATOS',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: context.cores.principal,
            ),
          ),
        ),
        body: ListView(
          controller: _rolagem,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const _OQueDizALei(),
            _Cartao(
              icone: Icons.send_outlined,
              titulo: 'Envio',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Rotulo('Enviar para'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<Ong>(
                    initialValue: destino,
                    isDense: true,
                    isExpanded: true,
                    decoration: _caixa(context, null, comErro: semDestino),
                    hint: Text(
                      organizacoes.isEmpty
                          ? 'Nenhuma organização disponível'
                          : 'Escolher a organização',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.cores.textoFraco,
                      ),
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: context.cores.textoFraco,
                    ),
                    dropdownColor: context.cores.cartao,
                    style: TextStyle(fontSize: 15, color: context.cores.texto),
                    items: [
                      for (final ong in organizacoes)
                        DropdownMenuItem(
                          value: ong,
                          child: Text(
                            ong.nome,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (ong) => setState(() => _escolhida = ong),
                  ),
                  if (semDestino)
                    const _Recado('Campo obrigatório', erro: true)
                  else if (organizacoes.isEmpty)
                    const _Recado(
                      'Nenhuma organização recebe denúncias pelo app no '
                      'momento.',
                    ),
                  const SizedBox(height: 10),
                  // Sobre o cartão colorido, a chave precisa de um Material
                  // próprio para pintar o efeito do toque
                  Material(
                    type: MaterialType.transparency,
                    child: SwitchListTile(
                      value: _anonima,
                      onChanged: (valor) => setState(() => _anonima = valor),
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: context.cores.principal,
                      title: const Text(
                        'Denunciar de forma anônima',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        _anonima
                            ? 'A organização não recebe seu nome nem seu '
                                  'telefone.'
                            : 'A organização recebe seu nome, telefone e '
                                  'e-mail para falar com você.',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.cores.textoFraco,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _Cartao(
              icone: Icons.pets_outlined,
              titulo: 'Sobre o animal',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _Selecao(
                          rotulo: 'Espécie',
                          opcoes: especiesDaDenuncia,
                          valor: _especie,
                          comErro: semEspecie,
                          aoEscolher: (especie) => setState(() {
                            // A raça escolhida é de uma espécie só
                            if (especie != _especie) {
                              _raca = null;
                              _buscaDaRaca.clear();
                            }
                            _especie = especie;
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Selecao(
                          rotulo: 'Porte',
                          opcoes: portesDaDenuncia,
                          valor: _porte,
                          comErro: semPorte,
                          aoEscolher: (porte) => setState(() => _porte = porte),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _Selecao(
                    rotulo: 'Sexo',
                    opcoes: sexosDaDenuncia,
                    valor: _sexo,
                    comErro: semSexo,
                    aoEscolher: (sexo) => setState(() => _sexo = sexo),
                  ),
                  const SizedBox(height: 14),
                  SelecaoComBusca(
                    // A chave recria o campo quando a espécie muda
                    key: ValueKey(_especie),
                    rotulo: 'Raça',
                    dica: _especie == null
                        ? 'Escolha a espécie primeiro'
                        : 'Digite para buscar a raça',
                    habilitada: _especie != null,
                    controlador: _buscaDaRaca,
                    opcoes: (digitado) => filtrarRacas(_especie, digitado),
                    daLista: (texto) => racaDaLista(_especie, texto),
                    rodape: const [
                      (valor: semRacaDefinida, texto: semRacaDefinida),
                    ],
                    limpavel: true,
                    aoEscolher: (raca) => setState(() => _raca = raca),
                  ),
                  const _Recado(
                    'Raça opcional. Se não souber o porte ou o sexo, escolha '
                    '"Não sei".',
                  ),
                ],
              ),
            ),
            _Cartao(
              icone: Icons.report_outlined,
              titulo: 'O que aconteceu',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Rotulo('Tipo'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<TipoDeDenuncia>(
                    initialValue: _tipo,
                    isDense: true,
                    decoration: _caixa(context, null, comErro: semTipo),
                    hint: Text(
                      'Escolher',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.cores.textoFraco,
                      ),
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: context.cores.textoFraco,
                    ),
                    dropdownColor: context.cores.cartao,
                    style: TextStyle(fontSize: 15, color: context.cores.texto),
                    items: [
                      for (final tipo in TipoDeDenuncia.values)
                        DropdownMenuItem(value: tipo, child: Text(tipo.rotulo)),
                    ],
                    onChanged: (tipo) => setState(() => _tipo = tipo),
                  ),
                  if (semTipo) const _Recado('Campo obrigatório', erro: true),
                  const SizedBox(height: 14),
                  const _Rotulo('Descrição'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descricao,
                    minLines: 4,
                    maxLines: null,
                    maxLength: 1000,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 15),
                    decoration: _caixa(
                      context,
                      'Conte o que você viu: o animal, o estado dele e '
                      'há quanto tempo isso acontece.',
                      comErro: semDescricao,
                    ),
                  ),
                  if (semDescricao)
                    const _Recado('Campo obrigatório', erro: true),
                ],
              ),
            ),
            _Cartao(
              icone: Icons.location_on_outlined,
              titulo: 'Onde',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SeletorDeLocal(
                    aoMudar: (local) => setState(() => _local = local),
                  ),
                  if (semLocal)
                    const _Recado(
                      'Marque no mapa onde fica, com rua e bairro.',
                      erro: true,
                    ),
                ],
              ),
            ),
            _Cartao(
              icone: Icons.event_outlined,
              titulo: 'Quando',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: _escolherData,
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(
                      _data == null
                          ? 'Escolher a data'
                          : '${_data!.day.toString().padLeft(2, '0')}/'
                                '${_data!.month.toString().padLeft(2, '0')}/'
                                '${_data!.year}',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.cores.principal,
                      side: BorderSide(color: context.cores.principal),
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const _Recado('Opcional: deixe em branco se não souber.'),
                ],
              ),
            ),
            _Cartao(
              icone: Icons.photo_camera_outlined,
              titulo: 'Fotos',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 92,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (var i = 0; i < _fotos.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: _Miniatura(
                              caminho: _fotos[i].path,
                              aoRemover: () =>
                                  setState(() => _fotos.removeAt(i)),
                            ),
                          ),
                        if (_fotos.length < _maximoDeFotos)
                          _AdicionarFoto(
                            aoTocar: _adicionarFotos,
                            comErro: semFoto,
                          ),
                      ],
                    ),
                  ),
                  _Recado(
                    semFoto
                        ? 'Adicione pelo menos uma foto.'
                        : 'De 1 a $_maximoDeFotos fotos. Fotografe só se for '
                              'seguro.',
                    erro: semFoto,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            FilledButton.icon(
              onPressed: _enviando ? null : _enviar,
              icon: _enviando
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.sobrePrincipal,
                      ),
                    )
                  : const Icon(Icons.send_outlined, size: 18),
              label: Text(_enviando ? 'Registrando…' : 'Registrar denúncia'),
              style: FilledButton.styleFrom(
                backgroundColor: context.cores.principal,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        // Reportar é uma das abas da barra inferior, por isso a barra fica
        // visível aqui como nas outras abas
        bottomNavigationBar: const BarraInferior(atual: 2),
      ),
    );
  }
}

// Quadro inicial: explica o que é maus-tratos, cita o art. 32 da Lei
// 9.605/1998 (com a barra lateral usada nas citações) e a pena para cães e
// gatos, e orienta a ligar 190 em caso de perigo imediato
class _OQueDizALei extends StatelessWidget {
  const _OQueDizALei();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cores.principalClara,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Maus-tratos a animais é crime',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.cores.principal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Abandono, agressão, ferimentos e falta de cuidados básicos podem '
            'configurar maus-tratos. Sua denúncia ajuda a proteger o animal.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: context.cores.texto,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: context.cores.principal, width: 3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"Praticar ato de abuso, maus-tratos, ferir ou mutilar '
                  'animais silvestres, domésticos ou domesticados, nativos ou '
                  'exóticos."',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    fontStyle: FontStyle.italic,
                    color: context.cores.texto,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lei nº 9.605/1998, art. 32',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.cores.principal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Quando se trata de cão ou gato, a pena é de reclusão de 2 a 5 '
            'anos, multa e proibição da guarda (Lei nº 14.064/2020).',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: context.cores.textoFraco,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Relate apenas o que você viu. Se o animal ou alguém correr '
            'perigo agora, ligue 190.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: context.cores.texto,
            ),
          ),
        ],
      ),
    );
  }
}

// Abre o compartilhamento do sistema com o texto da denúncia e as fotos.
// A pessoa escolhe o WhatsApp e a conversa do canal de denúncia
Future<void> encaminharDenuncia(Denuncia denuncia) async {
  await SharePlus.instance.share(
    ShareParams(
      text: denuncia.mensagemParaOCanal,
      files: [for (final foto in denuncia.fotos) XFile(foto)],
    ),
  );
}

// Folha exibida após o registro: confirma que a denúncia chegou à
// organização pelo app, mostra o protocolo com o botão de copiar, diz se a
// denúncia foi anônima e oferece, de forma discreta, o envio também pelo
// WhatsApp da organização, com as fotos
class _DenunciaRegistrada extends StatelessWidget {
  const _DenunciaRegistrada({
    required this.denuncia,
    required this.organizacao,
  });

  final Denuncia denuncia;
  final Ong organizacao;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 44,
              color: context.cores.principal,
            ),
            const SizedBox(height: 8),
            const Text(
              'Denúncia enviada',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '${organizacao.nome} já recebeu a denúncia pelo app. Acompanhe '
              'a situação em Minhas denúncias.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: context.cores.textoFraco),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 6, 10),
              decoration: BoxDecoration(
                color: context.cores.principalClara,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PROTOCOLO',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: context.cores.principal,
                          ),
                        ),
                        Text(
                          denuncia.protocolo,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: context.cores.texto,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final mensageiro = ScaffoldMessenger.of(context);
                      await Clipboard.setData(
                        ClipboardData(text: denuncia.protocolo),
                      );
                      mensageiro
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(content: Text('Protocolo copiado.')),
                        );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copiar'),
                    style: TextButton.styleFrom(
                      foregroundColor: context.cores.principal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Se a organização recebeu ou não os dados de quem denunciou
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 2, 4, 2),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: context.cores.principal, width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        denuncia.anonima
                            ? Icons.shield_outlined
                            : Icons.person_outline,
                        size: 16,
                        color: context.cores.principal,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        denuncia.anonima
                            ? 'Denúncia anônima'
                            : 'Denúncia identificada',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.cores.texto,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    denuncia.anonima
                        ? '${organizacao.nome} não recebeu seu nome nem seu '
                              'telefone.'
                        : '${organizacao.nome} recebeu seu nome e seu '
                              'telefone para falar com você.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: context.cores.textoFraco,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Envio opcional também pelo WhatsApp da organização
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              decoration: BoxDecoration(
                color: context.cores.fundo,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prefere falar também pelo WhatsApp?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.cores.texto,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${organizacao.nome}: '
                    '${formatarTelefone(organizacao.telefone)}. '
                    'Pelo WhatsApp, a organização vê o número utilizado.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: context.cores.textoFraco,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => encaminharDenuncia(denuncia),
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('Enviar pelo WhatsApp com as fotos'),
                    style: TextButton.styleFrom(
                      foregroundColor: context.cores.principal,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: context.cores.principal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Concluir'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Seção do formulário: cartão com ícone e título acima do conteúdo
class _Cartao extends StatelessWidget {
  const _Cartao({
    required this.icone,
    required this.titulo,
    required this.child,
  });

  final IconData icone;
  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cores.cartao,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icone, size: 18, color: context.cores.principal),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: TextStyle(
                  color: context.cores.principal,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// Rótulo de campo, em maiúsculas
class _Rotulo extends StatelessWidget {
  const _Rotulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Text(
    texto.toUpperCase(),
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: context.cores.textoFraco,
    ),
  );
}

// Texto de ajuda abaixo de um campo; em vermelho quando indica erro
class _Recado extends StatelessWidget {
  const _Recado(this.texto, {this.erro = false});

  final String texto;
  final bool erro;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6, left: 2),
    child: Text(
      texto,
      style: TextStyle(
        fontSize: 12,
        color: erro ? context.cores.destaque : context.cores.textoFraco,
      ),
    ),
  );
}

// Decoração padrão dos campos de texto, igual à do cadastro de animal. Com
// [comErro], a borda fica na cor de destaque
// Campo de escolha com rótulo em cima, no visual dos campos do formulário.
// As opções aparecem com a primeira letra maiúscula
class _Selecao extends StatelessWidget {
  const _Selecao({
    required this.rotulo,
    required this.opcoes,
    required this.valor,
    required this.aoEscolher,
    this.comErro = false,
  });

  final String rotulo;
  final List<String> opcoes;
  final String? valor;
  final bool comErro;
  final ValueChanged<String?> aoEscolher;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Rotulo(rotulo),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: valor,
          isDense: true,
          isExpanded: true,
          decoration: _caixa(context, null, comErro: comErro),
          hint: Text(
            'Escolher',
            style: TextStyle(fontSize: 14, color: context.cores.textoFraco),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: context.cores.textoFraco,
          ),
          dropdownColor: context.cores.cartao,
          style: TextStyle(fontSize: 15, color: context.cores.texto),
          items: [
            for (final opcao in opcoes)
              DropdownMenuItem(value: opcao, child: Text(comMaiuscula(opcao))),
          ],
          onChanged: aoEscolher,
        ),
        if (comErro) const _Recado('Campo obrigatório', erro: true),
      ],
    );
  }
}

InputDecoration _caixa(
  BuildContext context,
  String? dica, {
  bool comErro = false,
}) => InputDecoration(
  isDense: true,
  filled: true,
  fillColor: context.cores.fundo,
  hintText: dica,
  hintMaxLines: 3,
  counterText: '',
  hintStyle: TextStyle(fontSize: 14, color: context.cores.textoFraco),
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(
      color: comErro ? context.cores.destaque : context.cores.borda,
      width: comErro ? 1.5 : 1,
    ),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(
      color: comErro ? context.cores.destaque : context.cores.principal,
      width: 1.5,
    ),
  ),
);

// Miniatura de uma foto escolhida, com botão para removê-la
class _Miniatura extends StatelessWidget {
  const _Miniatura({required this.caminho, required this.aoRemover});

  final String caminho;
  final VoidCallback aoRemover;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: Stack(
        children: [
          FotoAnimal(caminho: caminho, altura: 92),
          // O círculo visível é pequeno, mas a área de toque tem 48 x 48,
          // o mínimo recomendado para acessibilidade
          Positioned(
            top: 0,
            right: 0,
            child: Semantics(
              button: true,
              label: 'Remover foto',
              excludeSemantics: true,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: aoRemover,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.cores.cartao,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: context.cores.texto,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Botão para adicionar fotos; ganha borda de erro se nenhuma foi escolhida
class _AdicionarFoto extends StatelessWidget {
  const _AdicionarFoto({required this.aoTocar, required this.comErro});

  final VoidCallback aoTocar;
  final bool comErro;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cores.principalClara,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: comErro
            ? BorderSide(color: context.cores.destaque, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 92,
          height: 92,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, color: context.cores.principal),
              const SizedBox(height: 4),
              Text(
                'Adicionar',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.cores.principal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
