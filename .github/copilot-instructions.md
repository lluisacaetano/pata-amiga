# Instruções do Copilot — Pata Amiga (Sprint 4)

## Contexto e limites

- Este é um aplicativo Flutter/Dart para adoção e registros de animais. Use o código atual como referência para o que está implementado.
- Não presuma que funcionalidades descritas no README, backlog, wireframes ou documentos de sprints estejam prontas. Confira a implementação antes de propor mudanças.
- Não introduza camadas, serviços, funcionalidades ou dependências sem necessidade para a tarefa. Evite refatorações amplas fora do escopo solicitado.
- Mantenha o idioma e o estilo existentes: nomes e comentários em português quando apropriado, e interface em português.
- Não altere arquivos além dos necessários para a tarefa.

## Organização do código

- `lib/main.dart`: inicialização do app, configuração de provedores, tema, escopo de curtidas e `MaterialApp`.
- `lib/main_cadastro.dart`: entrada alternativa existente para iniciar o fluxo de cadastro.
- `lib/auth/`: roteamento e telas de boas-vindas, login, cadastro e recuperação de senha.
- `lib/telas/`: telas do aplicativo, como feed, cadastro de animal, detalhes, perfil, mapa, onboarding e home.
- `lib/widgets/`: widgets compartilhados de interface, formulários e cartões.
- `lib/routes/`: nomes e configuração centralizada de rotas.
- `lib/modelos/`: modelos de domínio, incluindo `Animal`, `Dono` e `Usuario`.
- `lib/services/`: acesso à API de animais e cache local.
- `lib/estado/`: estado compartilhado das curtidas.
- `lib/provider/`: `UsuarioProvider`, usado para o estado do perfil.
- `lib/dados/`: dados mockados existentes; não os trate como fonte do feed atual sem confirmar o fluxo da tela.
- `lib/tema/`: cores e configuração visual.
- `assets/`: imagens, ilustrações, marca e fontes.
- `test/`: testes automatizados; os testes de rotas ficam em `test/routes/`.
- `api/db.json`: dados locais de referência da API. Não confunda esse arquivo com um serviço integrado ao app.
- `documentacao/`: documentação e wireframes; confirme discrepâncias com o código atual.

## Estado e navegação

- O estado não é centralizado em um único gerenciador:
	- `UsuarioProvider` usa `ChangeNotifier` e o pacote `provider` para disponibilizar dados do perfil.
	- `EstadoPataAmiga` usa `ChangeNotifier`, exposto por `PataAmigaScope` (`InheritedNotifier`), para as curtidas.
	- Telas `StatefulWidget` mantêm estado local quando apropriado, como busca, seleção e carregamento do feed.
- Preserve os mecanismos existentes e evite migrar o app inteiro para outra arquitetura de estado sem requisito explícito.
- Centralize nomes e builders de rotas em `lib/routes/`.
- A rota de detalhes espera um `Animal` nos argumentos; preserve a validação e o contrato de retorno ao feed.
- Verifique o destino real das ações na navegação antes de alterar testes ou textos: uma tela implementada pode não corresponder a documentação antiga.

## Serviços e persistência

- `AnimalService` faz chamadas HTTP para a API de animais; seu endereço atual é de desenvolvimento. Não assuma que ele seleciona automaticamente um host por plataforma.
- Chamadas HTTP devem permanecer na camada de serviços (`lib/services/`). Não implemente novas requisições diretamente em widgets ou telas; faça a tela consumir o serviço existente ou proponha a menor extensão necessária à camada de serviços.
- `CacheService` serializa animais no `SharedPreferences`; preserve a leitura, gravação e tratamento de cache inválido.
- O feed diferencia carregamento, cache, atualização e erro. Não remova esses estados nem mude o comportamento offline para simplificar testes.
- Curtidas também são persistidas no `SharedPreferences`.
- O estado de `UsuarioProvider` é mantido em memória; não presuma persistência do perfil.
- Para testes de dependências externas, use dados controlados e evite chamadas à API real. Se faltar um ponto de substituição, prefira uma injeção pequena e local à tarefa; não crie repositório, service locator ou camada genérica sem necessidade.

## Modelos e serialização

- Preserve os modelos existentes em `lib/modelos/`.
- `Animal` tem conversão JSON usada pela API e pelo cache. Ao mudar campos, confira `fromJson`, `toJson` e os testes relevantes.
- `TipoRegistro` atualmente contempla adoção, perdido e resgate; não adicione valores ou comportamentos sem requisito.
- `Dono` contém dados de contato. Trate telefone e demais dados pessoais com cuidado.
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
- `flutter_map` e `latlong2` para o mapa.
- `flutter_native_splash` para configuração da tela de abertura.

`firebase_core`, `firebase_auth` e `google_sign_in` também aparecem declarados, mas não presuma que autenticação Firebase ou Google esteja integrada: confirme o uso no código antes de depender deles. Não adicione ou atualize dependências sem necessidade; após mudanças no `pubspec.yaml`, obtenha as dependências e valide o projeto.

## Segurança e privacidade

- Não inclua tokens, senhas, chaves ou outros segredos no código, em logs, testes ou arquivos versionados.
- Não armazene senhas ou credenciais em texto simples, inclusive em `SharedPreferences`.
- Trate telefone, endereço, fotos e coordenadas como dados pessoais. Colete e exponha somente o necessário para a tarefa.
- Preserve pedidos de permissão e alternativas já disponíveis, como digitação manual do endereço. Não solicite localização sem ação ou necessidade pertinente.
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
