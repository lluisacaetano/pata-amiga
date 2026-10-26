# Instruções do Copilot — Pata Amiga (Sprint 4)

## Contexto e limites

- Este é um aplicativo Flutter/Dart para adoção e registros de animais. Use o código atual como referência para o que está implementado.
- Não presuma que funcionalidades descritas no README, backlog, wireframes ou documentos de sprints estejam prontas. Confira a implementação antes de propor mudanças.
- Não introduza camadas, serviços, funcionalidades ou dependências sem necessidade para a tarefa. Evite refatorações amplas fora do escopo solicitado.
- Mantenha o idioma e o estilo existentes: nomes e comentários em português quando apropriado, e interface em português.
- Não altere arquivos além dos necessários para a tarefa.

## Organização do código

- `lib/main.dart`: inicialização do app, configuração de provedores, tema, escopo do estado compartilhado (`PataAmigaScope`) e `MaterialApp`.
- `lib/auth/`: roteamento e telas de boas-vindas, login, cadastro e recuperação de senha.
- `lib/telas/`: telas do aplicativo, como feed, cadastro e edição de animal, detalhes, perfil, mapa, registro de avistamento, cadastro de ponto de alimentação, registro de abastecimento, ONGs (lista, perfil público e cadastro), denúncia de maus-tratos (formulário, "Minhas denúncias" e detalhes), e onboarding.
- `lib/widgets/`: widgets compartilhados de interface, formulários e cartões. Reutilize os existentes antes de criar outro: `SelecaoComBusca` (select com busca, usado para bairro e raça), `SeletorDeLocal` e `MapaDeLocal` (marcar um lugar no mapa), `PainelDeFiltros` (filtros do feed), `acoes_do_registro.dart` (mudar status, editar, publicar para adoção e transferir para a ONG), `ProtegerAlteracoes` (pergunta antes de sair de um formulário com algo não salvo), `AvatarDaOng`, `sino_de_notificacoes.dart` (o sino de notificações: pedidos e avisos das ONGs, animais perdidos na região e avistamentos dos animais do usuário), `CamadaDaMinhaPosicao` (`minha_posicao.dart`, o ponto azul com a posição do usuário, presente em todos os mapas), `PainelDeConfirmacao` (painel inferior de confirmar ou cancelar), `CartaoDeSecao` (cartão com título dos formulários de ponto, abastecimento e avistamento), `CampoDeBusca` (busca das listas), `PinoDaPatinha` (pino dos mapas) e `IconeDeOsso`. Validação de e-mail (`validarEmail`) e máscaras de telefone ficam em `mascaras.dart`.
- `lib/routes/`: nomes e configuração centralizada de rotas.
- `lib/modelos/`: modelos de domínio, incluindo `Animal`, `Dono`, `Usuario`, `Avistamento`, `PontoDeAlimentacao`, `Abastecimento`, `Ong`, `Denuncia`, as regras das camadas do mapa (`camadas_do_mapa.dart`) e dos filtros do feed (`filtros_do_feed.dart`), a leitura dos ids da API (`json_da_api.dart`) e as funções de texto comuns (`texto.dart`: `comMaiuscula`, `semAcento` e `haQuantosDias`). Use essas funções em vez de reescrever a remoção de acentos ou o "há N dias".
- `lib/services/`: acesso à API (`AnimalService`, `AvistamentoService`, `AlimentacaoService`, `OngService`, `DenunciaService`), cache local (`CacheService`), localização do aparelho (`LocalizacaoService`, que concentra permissão, prazo e mensagens; todas as telas que pedem a posição passam por ele, e `posicaoSemPedir` lê a posição sem abrir o pedido de permissão), bairro pelo CEP ou pela rua via ViaCEP (`BairroService`) e o endereço da API (`endereco_da_api.dart`).
- `lib/estado/`: estado compartilhado do app (`EstadoPataAmiga`).
- `lib/provider/`: `UsuarioProvider`, usado para o estado do perfil e para o login, e `PreferenciasAplicativoProvider` (aparência e acessibilidade).
- `lib/dados/`: dados mockados existentes, que não são a fonte do feed atual (o feed lê da API), além das listas de referência: os bairros de Formiga (`bairros_formiga.dart`) e as raças de cachorro e de gato (`racas.dart`, com as fontes no próprio arquivo), além do canal que recebe as denúncias (`canais_de_denuncia.dart`, nome e WhatsApp da APAF, num lugar só para trocar quando houver um canal oficial). Use essas listas em vez de texto livre.
- `lib/tema/`: cores e configuração visual.
- `assets/`: imagens, ilustrações, marca e fontes.
- `test/`: testes automatizados. O arquivo versionado é `test/routes/animal_navigation_test.dart`, que usa versões falsas da API, do GPS e do serviço de endereços; siga esse padrão.
- `api/db.json`: banco da API local usada pelo app, servido pelo `json-server` na porta 3000. O `json-server` 1.x devolve os ids em texto e o 0.17 em número: os modelos guardam o id como `String?` e leem pelos helpers de `json_da_api.dart` (`idDaApi`, `idParaApi`); um item com defeito é descartado sem derrubar a lista (`itensValidos`) (coleções `animais`, `avistamentos`, `pontosAlimentacao`, `abastecimentos`, `ongs` e `denuncias`). Os animais de exemplo têm endereços reais de Formiga e dados conferidos com as fotos; ao mudar esse arquivo, mantenha os dois. A ONG de exemplo é fictícia ("Abrigo Focinhos (exemplo)", e-mail e chave Pix em `example.org`); não use nome, telefone ou Pix de organização real.
- `documentacao/`: documentação e wireframes; confirme discrepâncias com o código atual.

## Estado e navegação

- O estado não é centralizado em um único gerenciador:
	- `UsuarioProvider` usa `ChangeNotifier` e o pacote `provider` para disponibilizar o usuário logado e o perfil.
	- `EstadoPataAmiga` usa `ChangeNotifier`, exposto por `PataAmigaScope` (`InheritedNotifier`), para os animais do feed, as curtidas, os cadastros do usuário, os avistamentos, os pontos de alimentação, as ONGs, a última posição do aparelho e as notificações de animais dispensadas. As notificações de animais (`alertasPara`) são calculadas no aparelho pelas regras de `alertas_de_animais.dart`: perdido de outra pessoa a até 3 km e publicado nos últimos 7 dias, e avistamento de um animal do usuário feito por outra pessoa. O feed busca ONGs, animais, avistamentos e posição a cada 30 segundos com o app aberto e vibra quando surge uma notificação nova; não há notificação push. Não é um `Provider`: leia com `PataAmigaScope.of(context)`, ou `PataAmigaScope.talvez(context)` quando ele puder não existir, e nunca com `context.read`.
	- Telas `StatefulWidget` mantêm estado local quando apropriado, como busca, seleção e carregamento do feed.
- Preserve os mecanismos existentes e evite migrar o app inteiro para outra arquitetura de estado sem requisito explícito.
- Centralize nomes e builders de rotas em `lib/routes/`.
- A rota de detalhes espera um `Animal` nos argumentos; preserve a validação e o contrato de retorno ao feed. A rota de detalhes da denúncia espera uma `Denuncia`.
- Verifique o destino real das ações na navegação antes de alterar testes ou textos: uma tela implementada pode não corresponder a documentação antiga.

## Serviços e persistência

- `AnimalService`, `AvistamentoService`, `AlimentacaoService`, `OngService` e `DenunciaService` fazem chamadas HTTP para a API local, no endereço de `lib/services/endereco_da_api.dart` (`10.0.2.2:3000`, o computador visto pelo emulador Android). Ele é de desenvolvimento e não seleciona o host por plataforma.
- Chamadas HTTP devem permanecer na camada de serviços (`lib/services/`). Não implemente novas requisições diretamente em widgets ou telas; faça a tela consumir o serviço existente ou proponha a menor extensão necessária à camada de serviços.
- `CacheService` serializa animais no `SharedPreferences`; preserve a leitura, gravação e tratamento de cache inválido.
- O feed diferencia carregamento, cache, atualização e erro. Não remova esses estados nem mude o comportamento offline para simplificar testes.
- Curtidas, os cadastros feitos no aparelho e os protocolos das denúncias feitas no aparelho (que alimentam "Minhas denúncias") também são persistidos no `SharedPreferences`.
- `UsuarioProvider` grava no `SharedPreferences` o e-mail da sessão e o perfil (nome, e-mail, telefone e foto). A senha nunca é gravada: só um resumo SHA-256 com sal (pacote `crypto`), conferido em `entrar`, que devolve `ResultadoDoLogin`. O e-mail é normalizado (minúsculas) no registro, no login e nas chaves. A conta existe só no aparelho, então não há recuperação de senha por e-mail. `registrarUsuario` devolve `false`, sem alterar nada, quando o e-mail já tem conta, e a tela de cadastro mostra o erro no campo de e-mail. A senha esquecida é redefinida em `redefinirSenha`, que confere o e-mail e o telefone do perfil e devolve `ResultadoDaRedefinicao`.
- Curtidas e cadastros locais são identificados por `animal.chave`, nunca pelo nome do animal.
- Os serviços externos são o OpenStreetMap (blocos do mapa, com o crédito obrigatório na tela), o serviço de endereços do aparelho (`geocoding`) e o ViaCEP. Toda chamada a eles tem prazo (`timeout`), para a tela não travar sem internet.
- Para testes de dependências externas, use dados controlados e evite chamadas à API real. Se faltar um ponto de substituição, prefira uma injeção pequena e local à tarefa; não crie repositório, service locator ou camada genérica sem necessidade.

## Modelos e serialização

- Preserve os modelos existentes em `lib/modelos/`.
- `Animal` tem conversão JSON usada pela API e pelo cache. Ao mudar campos, confira `fromJson`, `toJson` e os testes relevantes. Campos ligados à API: `id` (texto), `rua`, `latitude` e `longitude`, e `responsavelEmail` (quem cadastrou, que é quem pode editar e mudar o status).
- `StatusAnimal` tem `disponivel` e um desfecho por tipo: adoção vira `adotado`, perdido vira `encontrado` e resgate vira `resgatado`. Animal com desfecho sai do feed e do mapa.
- `Animal.ongId` diz em nome de qual ONG o animal foi publicado (null quando foi em nome da própria pessoa). O perfil da ONG e o filtro por ONG usam o `ongId`, nunca o e-mail; "Meus registros" mostra só os animais sem `ongId`. Qualquer pessoa da ONG muda o status e edita os animais dela.
- `Ong` tem uma admin (`responsavelEmail`), os membros e os pedidos para entrar (`PessoaDaOng`). Cada conta faz parte de no máximo uma ONG; só a admin edita o perfil e a chave Pix, responde aos pedidos e remove membros. O nome da ONG é único, sem diferenciar maiúsculas e acentos. Pedidos e respostas partem da versão da API (`OngService.buscarOng`), não da cópia do app. A chave Pix só é exibida: o app não processa doações.
- `Denuncia` é sempre anônima: o formulário não pede identificação, e o nome, o telefone e o e-mail de quem denuncia não vão para a API nem para a mensagem. Não reintroduza a opção de se identificar sem requisito. O protocolo é gerado no aparelho no formato `PA-AAAAMMDD-NNNN` e conferido na API antes de gravar (sorteia outro se já existir); "Minhas denúncias" busca só os protocolos guardados no aparelho, a foto é obrigatória (de 1 a 5, gravadas como caminho local, como no cadastro de animal) e a situação (`recebida`, `emApuracao`, `encerrada`) só muda pela API.
- O encaminhamento da denúncia é feito pela própria pessoa, pelo compartilhar do celular (`share_plus`), com o texto e as fotos juntos. Não troque por link do WhatsApp (`wa.me`): o link não leva fotos e a APAF não acessa o app. Não há envio por e-mail.
- A raça é escolhida da lista de `lib/dados/racas.dart`; `racaPadrao` (em `filtros_do_feed.dart`) traz para o nome da lista as raças antigas escritas à mão.
- `TipoRegistro` atualmente contempla adoção, perdido e resgate; não adicione valores ou comportamentos sem requisito.
- `Dono` contém dados de contato. Trate telefone e demais dados pessoais com cuidado. Ao salvar o perfil, `EstadoPataAmiga.trocarTelefoneDosCadastros` leva o telefone novo a todos os cadastros do e-mail, e o Editar perfil grava esses animais na API.
- `Usuario` contém um campo de senha; não grave credenciais em texto simples nem adicione persistência de senha insegura.

## Convenções de implementação

- Siga `analysis_options.yaml`, que inclui `flutter_lints`.
- Use `const` quando aplicável, mantenha nulabilidade explícita e respeite os padrões de formatação Dart existentes.
- Mantenha widgets de apresentação reutilizáveis em `lib/widgets/` quando isso reduzir duplicação real; não extraia abstrações apenas por convenção.
- Preserve verificações de `mounted` após operações assíncronas antes de atualizar estado ou usar o contexto.
- Em alterações de UI, respeite tema, componentes existentes, acessibilidade e os wireframes pertinentes, validando divergências com o código atual.
- Atualize testes para verificar comportamento, não apenas detalhes de implementação. Não remova asserções para fazer uma suíte passar.

## Dependências

Dependências declaradas no `pubspec.yaml` e usadas pelo código atual incluem:

- `provider` para `UsuarioProvider`.
- `shared_preferences` para curtidas e cache local.
- `http` para chamadas à API.
- `share_plus` e `url_launcher` para compartilhamento e abertura de links externos.
- `image_picker` para seleção de imagens.
- `geolocator` e `geocoding` para localização e conversão de coordenadas.
- `flutter_map` e `latlong2` para o mapa, com os blocos do OpenStreetMap.
- `flutter_native_splash` para configuração da tela de abertura.

Não há Firebase nem login com Google no projeto. Não adicione ou atualize dependências sem necessidade; após mudanças no `pubspec.yaml`, obtenha as dependências e valide o projeto.

## Segurança e privacidade

- Não inclua tokens, senhas, chaves ou outros segredos no código, em logs, testes ou arquivos versionados.
- Não armazene senhas ou credenciais em texto simples, inclusive em `SharedPreferences`.
- Trate telefone, endereço, fotos e coordenadas como dados pessoais. Colete e exponha somente o necessário para a tarefa.
- Preserve pedidos de permissão e alternativas já disponíveis, como digitação manual do endereço. Não solicite localização sem ação ou necessidade pertinente. A única exceção é o painel "Usar sua localização?", mostrado uma vez ao abrir o feed, que explica o uso antes do pedido do sistema.
- O endereço HTTP atualmente configurado para a API é de desenvolvimento. Não o trate como configuração de produção nem introduza tráfego inseguro em uma entrega de produção.
- Evite requisições reais e dados pessoais reais em testes automatizados.

## Fluxo Git e revisão

- Trabalhe em uma branch específica para a funcionalidade, correção ou tarefa; não faça alterações de trabalho diretamente na branch principal (`main`).
- Envie as alterações por Merge Request com descrição do objetivo, escopo, validações executadas e eventuais limitações.
- Todo Merge Request exige revisão e aprovação humana antes do merge. O autor não aprova o próprio Merge Request.
- Não faça commit direto na branch principal, nem faça merge sem aprovação humana. Não execute commit, push ou merge a menos que isso seja explicitamente solicitado.

## Validação obrigatória

Antes de concluir alterações Dart/Flutter:

- Use as ferramentas MCP Dart/Flutter disponíveis e pertinentes à tarefa para inspeção ou validação adicional do código/app; não as trate como substitutas da análise estática ou da suíte de testes.
- Execute na raiz do projeto `flutter analyze` e `flutter test`.
- Corrija problemas introduzidos pela alteração. Diferencie erros novos de avisos preexistentes e informe os resultados de ambos os comandos.
- Na resposta final, registre os comandos executados e os resultados, além dos nomes exatos das ferramentas MCP efetivamente utilizadas. Se nenhuma ferramenta MCP foi usada, informe isso; não atribua ao MCP verificações executadas por outro meio.
- Não declare validação concluída se algum comando obrigatório não tiver sido executado; informe claramente qualquer impedimento.
