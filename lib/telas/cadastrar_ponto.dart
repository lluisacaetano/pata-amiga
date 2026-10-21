import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../estado/estado_pata_amiga.dart';
import '../modelos/ponto_de_alimentacao.dart';
import '../provider/usuario_provider.dart';
import '../services/alimentacao_service.dart';
import '../services/localizacao_service.dart';
import '../tema/cores.dart';
import '../widgets/escolha_de_tipo.dart';
import '../widgets/mapa_de_local.dart';
import '../widgets/seletor_de_local.dart';

// Qualquer pessoa logada cadastra um comedouro ou bebedouro público e, se
// acabou de abastecê-lo, já registra o abastecimento junto
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

  Future<void> _cadastrar() async {
    setState(() => _tentou = true);
    if (_tipo == null || _salvando) return;
    setState(() {
      _salvando = true;
      _recusa = null;
    });
    final estado = PataAmigaScope.of(context);
    final usuario = context.read<UsuarioProvider?>()?.usuario;
    final nome = usuario?.nome.trim() ?? '';
    final email = usuario?.email ?? '';
    final agora = DateTime.now();
    // Quem diz que abasteceu precisa estar no ponto que acabou de marcar
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
        backgroundColor: Cores.fundo,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Voltar',
            color: Cores.principal,
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'NOVO PONTO DE ALIMENTAÇÃO',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: Cores.principal,
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
                    style: estiloDasAbas(Cores.fundo),
                  ),
                ),
                if (semTipo)
                  const Padding(
                    padding: EdgeInsets.only(top: 5, left: 2),
                    child: Text(
                      'Escolha se é comedouro, bebedouro ou os dois.',
                      style: TextStyle(fontSize: 12, color: Cores.destaque),
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
                    fillColor: Cores.fundo,
                    hintText: 'Ponto de referência (opcional)',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: Cores.textoFraco,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Cores.borda),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Cores.principal,
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
          // Material, e não Container com cor, para o toque aparecer
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Material(
              color: Cores.cartao,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Cores.borda),
              ),
              clipBehavior: Clip.antiAlias,
              child: CheckboxListTile(
                value: _abasteciHoje,
                onChanged: (marcado) =>
                    setState(() => _abasteciHoje = marcado ?? false),
                activeColor: Cores.principal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  'Abasteci este ponto hoje',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Conferimos se você está no ponto, a até 150 m.',
                  style: TextStyle(fontSize: 13, color: Cores.textoFraco),
                ),
              ),
            ),
          ),
          if (_recusa != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 2),
              child: Text(
                _recusa!,
                style: const TextStyle(fontSize: 13, color: Cores.destaque),
              ),
            ),
          const SizedBox(height: 4),
          FilledButton.icon(
            onPressed: _salvando ? null : _cadastrar,
            icon: _salvando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.add_location_alt_outlined, size: 18),
            label: Text(_salvando ? 'Cadastrando…' : 'Cadastrar ponto'),
            style: FilledButton.styleFrom(
              backgroundColor: Cores.principal,
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

// O mesmo cartão do cadastro de animal: branco, borda clara e título verde
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
        color: Cores.cartao,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Cores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icone, size: 18, color: Cores.principal),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                  color: Cores.principal,
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
