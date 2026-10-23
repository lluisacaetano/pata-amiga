// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote provider: compartilha estado entre as telas e as reconstrói.
import 'package:provider/provider.dart';

// Arquivo estado_pata_amiga.dart: estado compartilhado do app.
import '../estado/estado_pata_amiga.dart';
// Arquivo ponto_de_alimentacao.dart: ponto de alimentação e suas regras.
import '../modelos/ponto_de_alimentacao.dart';
// Arquivo usuario_provider.dart: dados do usuário logado.
import '../provider/usuario_provider.dart';
// Arquivo alimentacao_service.dart: acesso à API dos pontos de alimentação.
import '../services/alimentacao_service.dart';
// Arquivo localizacao_service.dart: leitura da posição atual do aparelho.
import '../services/localizacao_service.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';
// Arquivo escolha_de_tipo.dart: estilo das abas de escolha (estiloDasAbas).
import '../widgets/escolha_de_tipo.dart';
// Arquivo mapa_de_local.dart: coordenada do centro de Formiga.
import '../widgets/mapa_de_local.dart';
// Arquivo seletor_de_local.dart: seletor de local com busca, mira e mapa.
import '../widgets/seletor_de_local.dart';

// Tela de cadastro de um comedouro ou bebedouro público. Quem está logado
// marca o tipo e o local no mapa e, se acabou de abastecer o ponto, registra
// o primeiro abastecimento junto com o cadastro
class CadastrarPonto extends StatefulWidget {
  final AlimentacaoService? servico;
  final LocalizacaoService? localizacao;

  const CadastrarPonto({super.key, this.servico, this.localizacao});

  @override
  State<CadastrarPonto> createState() => _CadastrarPontoState();
}

class _CadastrarPontoState extends State<CadastrarPonto> {
  late final _servico = widget.servico ?? AlimentacaoService();
  late final _localizacao = widget.localizacao ?? LocalizacaoService();
  String? _recusa;
  final _referencia = TextEditingController();
  TipoDePonto? _tipo;
  LocalEscolhido _local = (ponto: centroDeFormiga, rua: '', bairro: '');
  bool _abasteciHoje = true;
  bool _tentou = false;
  bool _salvando = false;

  @override
  void dispose() {
    _referencia.dispose();
    super.dispose();
  }

  // Valida o tipo e o endereço, confere a localização de quem diz ter
  // abastecido e grava o ponto (e o abastecimento) na API e no estado do app
  Future<void> _cadastrar() async {
    setState(() => _tentou = true);
    if (_tipo == null || _salvando) return;
    // Rua e bairro são obrigatórios: é por eles que o ponto é encontrado
    if (_local.rua.trim().isEmpty || _local.bairro.trim().isEmpty) {
      setState(
        () => _recusa =
            'Marque no mapa onde fica o ponto, com rua e bairro, antes de '
            'cadastrar.',
      );
      return;
    }
    setState(() {
      _salvando = true;
      _recusa = null;
    });
    final estado = PataAmigaScope.of(context);
    final usuario = context.read<UsuarioProvider?>()?.usuario;
    final nome = usuario?.nome.trim() ?? '';
    final email = usuario?.email ?? '';
    final agora = DateTime.now();
    // Para registrar o abastecimento, a pessoa precisa estar perto do ponto
    // marcado; sem isso, só o ponto pode ser cadastrado
    if (_abasteciHoje) {
      try {
        final onde = await _localizacao.posicaoAtual();
        final motivo = verificarAbastecimento(
          latitudeDoPonto: _local.ponto.latitude,
          longitudeDoPonto: _local.ponto.longitude,
          idDoPonto: null,
          latitudeDaPessoa: onde.latitude,
          longitudeDaPessoa: onde.longitude,
          email: email,
          abastecimentos: const [],
          agora: agora,
        );
        if (motivo != null) {
          setState(() {
            _salvando = false;
            _recusa =
                '${motivo.texto} Desmarque a opção para cadastrar só o ponto.';
          });
          return;
        }
      } on ErroDeLocalizacao catch (erro) {
        if (!mounted) return;
        setState(() {
          _salvando = false;
          _recusa = erro.texto;
        });
        return;
      }
    }
    if (!mounted) return;
    try {
      final ponto = await _servico.cadastrarPonto(
        PontoDeAlimentacao(
          tipo: _tipo!,
          referencia: _referencia.text.trim(),
          rua: _local.rua,
          bairro: _local.bairro,
          latitude: _local.ponto.latitude,
          longitude: _local.ponto.longitude,
          cadastradoPor: nome,
          cadastradoEm: agora,
        ),
      );
      estado.adicionarPonto(ponto);
      if (_abasteciHoje && ponto.id != null) {
        estado.adicionarAbastecimento(
          await _servico.registrarAbastecimento(
            Abastecimento(
              ponto: ponto.id!,
              data: agora,
              registradoPor: nome,
              email: email,
            ),
          ),
        );
      }
      if (!mounted) return;
      Navigator.pop(context, ponto);
    } on Exception {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Não foi possível cadastrar agora. Tente de novo.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final semTipo = _tentou && _tipo == null;
    return Scaffold(
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
          'NOVO PONTO DE ALIMENTAÇÃO',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: context.cores.principal,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _Cartao(
            icone: Icons.place_outlined,
            titulo: 'O ponto',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<TipoDePonto>(
                    segments: [
                      for (final tipo in TipoDePonto.values)
                        ButtonSegment(
                          value: tipo,
                          label: Text(tipo.rotuloCurto),
                        ),
                    ],
                    selected: _tipo == null ? const {} : {_tipo!},
                    emptySelectionAllowed: true,
                    showSelectedIcon: false,
                    onSelectionChanged: (escolha) => setState(
                      () => _tipo = escolha.isEmpty ? null : escolha.first,
                    ),
                    style: estiloDasAbas(context, context.cores.fundo),
                  ),
                ),
                if (semTipo)
                  Padding(
                    padding: EdgeInsets.only(top: 5, left: 2),
                    child: Text(
                      'Escolha se é comedouro, bebedouro ou os dois.',
                      style: TextStyle(fontSize: 12, color: context.cores.destaque),
                    ),
                  ),
                const SizedBox(height: 14),
                TextField(
                  controller: _referencia,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: context.cores.fundo,
                    hintText: 'Ponto de referência (opcional)',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: context.cores.textoFraco,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.cores.borda),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: context.cores.principal,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _Cartao(
            icone: Icons.location_on_outlined,
            titulo: 'Onde fica',
            child: SeletorDeLocal(aoMudar: (local) => _local = local),
          ),
          // Material em vez de Container para o efeito de toque aparecer
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Material(
              color: context.cores.cartao,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: context.cores.borda),
              ),
              clipBehavior: Clip.antiAlias,
              child: CheckboxListTile(
                value: _abasteciHoje,
                onChanged: (marcado) =>
                    setState(() => _abasteciHoje = marcado ?? false),
                activeColor: context.cores.principal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  'Abasteci este ponto hoje',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Conferimos se você está no ponto, a até 150 m.',
                  style: TextStyle(fontSize: 13, color: context.cores.textoFraco),
                ),
              ),
            ),
          ),
          if (_recusa != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 2),
              child: Text(
                _recusa!,
                style: TextStyle(fontSize: 13, color: context.cores.destaque),
              ),
            ),
          const SizedBox(height: 4),
          FilledButton.icon(
            onPressed: _salvando ? null : _cadastrar,
            icon: _salvando
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.sobrePrincipal,
                    ),
                  )
                : const Icon(Icons.add_location_alt_outlined, size: 18),
            label: Text(_salvando ? 'Cadastrando…' : 'Cadastrar ponto'),
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
    );
  }
}

// Cartão de seção do formulário: fundo de cartão, borda e título com ícone
// na cor principal, no mesmo padrão do cadastro de animal
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
