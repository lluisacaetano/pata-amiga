# Pata Amiga

> Ajudar é um ato de amor.

O Pata Amiga é um aplicativo hiperlocal de adoção, busca de animais perdidos e
denúncia de maus-tratos, voltado à cidade de Formiga (MG). É desenvolvido pelo
squad Patinhas Gals Dev na disciplina Programação para Dispositivos Móveis do
IFMG Campus Formiga, ao longo do semestre 2026/2.

## O problema

Formiga conta desde 5 de outubro de 2011 com a APAF, a Associação Protetora dos
Animais de Formiga, que realiza mutirões de castração, resgates, tratamentos
veterinários, feiras de adoção responsável e a instalação de comedouros públicos
pela cidade. As denúncias de maus-tratos, por sua vez, seguem por canais próprios
mantidos fora desse espaço: o Disque-Denúncia 181, a Polícia Civil e o
atendimento da prefeitura.

O problema, portanto, não é a ausência de iniciativa, e sim a forma como ela está
distribuída. Não existe um registro comum: a associação mantém o seu, o poder
público mantém o dele e cada protetor independente divulga onde consegue, no
próprio perfil de rede social ou em grupos de bairro. Nenhum desses registros
conversa com os demais.

O canal usado para divulgar agrava essa dispersão, porque a informação não
permanece. Um post circula por algumas horas e depois desce no feed, ainda que o
animal siga disponível; nos grupos de mensagem, a foto se perde entre assuntos
que nada têm a ver com ela. O resultado é que quem procura um animal para adotar
não tem onde procurar, quem tem um animal para oferecer não tem onde publicar de
modo duradouro, e ninguém consegue dizer quantos animais estão à espera de um lar
na cidade neste momento.

Entre esses dois lados está quem apenas esbarra em um cachorro solto na rua. Essa
pessoa não sabe se o animal fugiu de casa ou foi abandonado, e não tem um lugar
único onde publicar a foto de modo a alcançar ao mesmo tempo um possível tutor e
quem faz resgate na cidade. Na prática, o registro não acontece.

## Por que um aplicativo próprio

Convém dizer com clareza: os canais que existem hoje funcionam. O perfil da APAF
tem alcance real na cidade e viabiliza adoções, e os canais públicos de denúncia
cumprem o papel de receber os relatos. A proposta deste trabalho não parte de uma
crítica a eles, e sim da constatação de que são canais de propósito geral sendo
usados para uma tarefa específica.

A diferença está na intenção de quem chega. Uma pessoa abre uma rede social para
ver o que aparecer, e é o próprio aplicativo que decide o que ela vai encontrar.
Ninguém abre uma rede social com a tarefa de adotar um cão de porte pequeno e
consegue concluí-la ali. Do outro lado, quem quer denunciar precisa saber de
antemão qual é o canal certo e sair do ambiente onde estava. Em ambos os casos, a
intenção se dissolve no caminho.

O Pata Amiga existe para dar destino a essas intenções. Quem abre o aplicativo já
chega com uma delas: quer ver os animais disponíveis para adoção, quer denunciar
um caso de maus-tratos ou quer publicar um animal que acabou de encontrar na rua.
Cada uma dessas três tarefas tem, dentro do aplicativo, um lugar próprio e um
começo e um fim, sem que o percurso dependa de algoritmo, de horário de
publicação ou de a pessoa saber para quem ligar.

Reunir os três fluxos em um só lugar produz um efeito que nenhum dos canais
atuais alcança: os registros deixam de ser mensagens e passam a ser dados. Cada
denúncia recebe um protocolo com situação acompanhável, o que devolve ao
denunciante a resposta que hoje não existe; e o conjunto, por ser estruturado e
georreferenciado, torna visíveis a reincidência e a concentração geográfica dos
casos, informação que interessa diretamente ao poder público e às próprias ONGs.

O aplicativo se posiciona, portanto, como complemento e não como substituto da
APAF ou dos canais da prefeitura. Ao permitir que qualquer protetor independente
cadastre e acompanhe os próprios animais, ele também distribui uma capacidade que
hoje se concentra em uma única organização, mantida por doações e com limites
naturais de alcance.

## O que o aplicativo faz

O feed de adoção reúne os animais disponíveis em rolagem contínua, com foto,
porte, idade e cidade, e pode ser estreitado por espécie, porte, sexo, raça,
bairro, ONG e cuidados de saúde até sobrar apenas o que interessa a quem procura. Tocar em um animal abre a ficha completa,
onde estão a situação de saúde, as observações de quem cuida dele e o contato do
responsável.

O feed de perdidos funciona pela mesma lógica, mas serve a outra urgência: quem
perdeu o animal publica, quem o avistou registra onde e quando, e o dono
acompanha os avistamentos sem depender de um post ser compartilhado a tempo.
Quando um animal é reportado como perdido, quem está a até 3 km recebe uma
notificação no próprio aplicativo, porque a informação só tem valor enquanto o
animal ainda está na região; o dono, por sua vez, é avisado a cada novo
avistamento.

A denúncia de maus-tratos é o terceiro fluxo, e é o que mais depende de
permanência. O denunciante escolhe a organização que vai receber o caso, decide
se quer se identificar, descreve o animal e anexa foto, relato e endereço; em
troca, recebe um protocolo que permite acompanhar em que situação o caso está.
A organização vê as denúncias recebidas no próprio aplicativo e muda a situação
sempre com uma observação, que chega ao denunciante como notificação. O
aplicativo não resolve a denúncia, mas garante que ela deixe de ser uma mensagem
perdida e passe a ser um registro com histórico.

Sobre esses três fluxos se apoiam o mapa, que mostra em camadas o último
avistamento dos perdidos, os resgates e os comedouros públicos, e o perfil das
ONGs, com o que cada uma faz, a chave Pix, a política de adoção e os animais
publicados por ela.

## O que o aplicativo não faz

Algumas ausências são deliberadas e foram decididas na Sprint 0, não são
funcionalidades pendentes.

Não haverá conversa interna entre usuários. A tela do animal exibe os dados de
contato do responsável e leva a conversa para o telefone ou para o WhatsApp, fora
do aplicativo. A decisão tem motivo: uma conversa própria exigiria infraestrutura
de tempo real, moderação de conteúdo e tratamento de denúncias de abuso, esforço
incompatível com o prazo do semestre e sem ganho perceptível para um usuário que
já usa o WhatsApp todos os dias.

O aplicativo também não processa pagamentos nem doações. No perfil da ONG a chave
Pix é apenas exibida, para que a doação aconteça pelo aplicativo bancário do
próprio doador. Como a APAF depende de doações para se manter, o processamento
interno fica registrado como possibilidade futura, fora do escopo deste semestre.

Do mesmo modo, o aplicativo não gerencia o processo interno das instituições. Ele
registra a denúncia, entrega o caso à organização escolhida e guarda a situação
que ela informar de volta, seja ela recebida, em apuração ou encerrada.

Resta dizer quem é esse responsável, e aqui o squad trabalha com uma hipótese, não
com um acordo firmado. Supõe-se que a prefeitura de Formiga assuma o papel e
direcione cada caso conforme a natureza da ocorrência, encaminhando as denúncias
de maus-tratos à Polícia Civil ou ao órgão municipal competente, e os animais
perdidos ou abandonados às ONGs que atuam no resgate. Enquanto essa parceria não
for firmada, a denúncia fica registrada no aplicativo e vai para uma das
organizações cadastradas que recebem denúncias, escolhida por quem denuncia; nos
dados de exemplo, a APAF Formiga. Pelo mesmo motivo, o painel de denúncias do
administrador previsto na Sprint 0 (US 15) foi encerrado na Sprint 4: a triagem
pela prefeitura depende de uma parceria que ainda não existe.

Por fim, o Pata Amiga é desenvolvido como aplicativo independente, conforme o
escopo da disciplina. O squad reconhece que, em um cenário real, o destino natural
desta solução seria a integração ao aplicativo já mantido pela prefeitura, e o
produto construído aqui funciona, nesse sentido, como prova de conceito dessa
integração.

## Para quem

O produto atende cinco perfis. Os tutores e adotantes procuram um animal para
adotar ou perderam o próprio. As ONGs e órgãos de proteção animal fazem resgate,
acolhimento e encaminhamento para adoção, e precisam de um lugar onde o que
publicam permaneça. Os protetores independentes resgatam e cuidam por conta
própria, sem vínculo com nenhuma instituição, e hoje são justamente os que menos
alcance têm. A comunidade em geral entra quando alguém quer reportar um animal em
risco, registrar um avistamento ou denunciar maus-tratos. E as organizações que
recebem denúncias acompanham os casos enviados a elas e registram as
providências tomadas; na Sprint 0, esse papel era do poder público municipal,
que continua sendo o destino previsto caso a parceria com a prefeitura se
confirme.

## Backlog

O backlog inicial tem dezoito User Stories, escritas na Sprint 0 no formato
"como [persona], quero [ação], para [benefício]", cada uma com prioridade e
tamanho estimado. Doze são de prioridade alta, cinco médias e uma baixa. A
história completa e o critério de aceite de cada uma estão no documento da
Sprint 0, e todas são cadastradas como Issues no Issue Board deste repositório.

Ao longo do semestre, o backlog ganhou três histórias. A US 19 e a US 20 entraram
na Sprint 2, para as rotas centralizadas e o estado do usuário logado, e a US 21
entrou na Sprint 4, para as denúncias chegarem à organização responsável dentro
do aplicativo. Na mesma sprint, a US 15 foi encerrada sem implementação, porque a
US 21 atendeu à necessidade dela.

| # | História | Prioridade | Tamanho |
|---|---|---|---|
| 01 | Feed de animais para adoção | Alta | Grande |
| 02 | Cadastro e login de usuário | Alta | Média |
| 03 | Atualização do status do animal | Alta | Pequena |
| 04 | Notificação de animal perdido na região | Alta | Média |
| 05 | Cadastro de animal com anexos | Alta | Grande |
| 06 | Filtros de busca | Alta | Média |
| 07 | Feed de animais perdidos | Alta | Média |
| 08 | Mapa com camadas | Média | Grande |
| 09 | Gerenciamento dos meus registros | Alta | Média |
| 10 | Contato com o responsável pelo animal | Alta | Pequena |
| 11 | Denúncia de maus-tratos | Alta | Grande |
| 12 | Registro de avistamento | Alta | Média |
| 13 | Perfil de ONG ou abrigo | Média | Média |
| 14 | Mapa de comedouros e bebedouros | Baixa | Média |
| 15 | Painel de denúncias do administrador | Média | Grande |
| 16 | Tela de detalhes do animal | Alta | Média |
| 17 | Perfil do usuário | Média | Média |
| 18 | Meus curtidos | Média | Pequena |
| 19 | Rotas centralizadas do aplicativo | Alta | Pequena |
| 20 | Estado compartilhado do usuário logado | Alta | Média |
| 21 | Denúncias no perfil da ONG responsável | Média | Grande |

## O squad

Patinhas Gals Dev. Os papéis são rotativos e revisados a cada sprint, de modo que
todas as integrantes passem por todas as funções ao longo do semestre. A divisão
das Sprints 0 e 1 foi a mesma; a partir da Sprint 2, cada uma teve a sua.

| Integrante | GitLab | Sprints 0 e 1 | Sprint 2 | Sprint 3 | Sprint 4 |
|---|---|---|---|---|---|
| Yasmim Stefane Faria | @yasmimstefane | Tech Lead | Dev | Product Owner | Tech Lead |
| Maria Eduarda Siqueira Silva | @Mariyaduarda | Product Owner | Dev | Tech Lead | Dev |
| Júlia Cristina Martins | @Julia_Nakano | QA | Tech Lead | Dev | Product Owner |
| Luisa Caetano Araujo | @luisacaetano | Dev | Product Owner | QA | Dev |
| Maria Luzia Sanches | @marialuziademoura | Dev | QA | Dev | QA |

## Documentação

A pasta `documentacao/` guarda o material produzido nas sprints anteriores. O
documento de entrega da Sprint 0 traz a ata de formação do squad, o conceito do
produto, o elevator pitch, o backlog completo com os critérios de aceite e o
levantamento do ambiente de cada integrante. Os wireframes de baixa fidelidade
estão em `documentacao/wireframes/`, uma imagem por tela, e são a referência
visual que as telas implementadas devem seguir.

## Tecnologia

O aplicativo é escrito em Flutter 3.47 com Dart 3.13, o que permite atender
Android e iOS a partir de uma base única. A API de referência do projeto é a
[Pata Amiga API](https://github.com/PET-foundation/Pata-Amiga-API), escrita em
Java com Spring.

Enquanto o aplicativo não se conecta a ela, os dados vêm de uma API local
servida pelo [json-server](https://github.com/typicode/json-server) a partir do
arquivo `api/db.json`: animais, avistamentos, pontos de alimentação,
abastecimentos, ONGs e denúncias. As chamadas ficam nos serviços de
`lib/services/`, e o feed guarda uma cópia dos animais no aparelho com
`shared_preferences`, por meio de `lib/services/cache_service.dart`, o que
permite continuar mostrando os animais sem internet e avisar na tela se o dado
veio do cache ou acabou de ser atualizado.

O estado compartilhado fica em dois `ChangeNotifier`: o do usuário logado,
exposto pelo `provider`, e o `EstadoPataAmiga`, com os animais, as curtidas, as
ONGs e as notificações, exposto por um `InheritedNotifier`. A navegação passa
por um arquivo único de rotas, em `lib/routes/`. O mapa usa o `flutter_map` com
os mapas públicos do OpenStreetMap, a localização do aparelho vem do
`geolocator`, e o encaminhamento de uma denúncia com as fotos, pelo
compartilhar do celular, usa o `share_plus`.

Na Sprint 4, o agente de código oficial do squad é o GitHub Copilot. As regras
que descrevem a arquitetura real do app para o agente estão em
`.github/copilot-instructions.md`, e o MCP server do Dart e Flutter, que permite
ao agente rodar o `flutter analyze` e os testes por conta própria, está
configurado em `.github/mcp.json`. Parte das entregas também foi feita com o
Claude Code, e cada Merge Request informa qual agente foi usado.

## Como rodar

O feed depende da API local, então ela precisa estar no ar antes do aplicativo.
Em um terminal, na raiz do projeto:

```
npx json-server api/db.json --port 3000
```

O app funciona com o `json-server` 0.17 e com o 1.x. A versão 1.x devolve os
ids em texto (por exemplo `"id": "1"`), e o app aceita os dois formatos.

Com a API respondendo em `http://localhost:3000/animais`, em outro terminal:

```
flutter pub get
flutter run
```

O endereço da API está em `lib/services/endereco_da_api.dart` e já muda conforme
onde o aplicativo roda: `10.0.2.2` no emulador Android, que é como ele enxerga o
computador, e `localhost` no Chrome e no desktop. Em um celular de verdade, troque
pelo IP do computador na rede. Sem a API no ar, o feed mostra o que estiver em cache ou um aviso de que
não conseguiu buscar os dados.

Para escolher onde rodar, use `flutter devices` e depois
`flutter run -d <dispositivo>`. Antes de abrir um Merge Request, rode
`flutter analyze` e `flutter test`.

## Como trabalhamos

Nenhum código entra na `main` direto. Cada integrante trabalha em uma branch
própria, nomeada pela funcionalidade em que está mexendo, e abre um Merge Request
explicando o que fez.

A QA da sprint é a revisora padrão de todo Merge Request e testa a tela na
prática antes de aprovar. Se estiver ocupada, qualquer outra integrante pode
cobrir. A regra que não muda é que ninguém aprova o próprio Merge Request. Depois
da aprovação, quem faz o merge é a própria autora, que escolhe o momento certo.

O andamento fica registrado na Issue fixa "Daily Sprint", a mesma em todas as
sprints, onde cada integrante comenta, a cada dia de aula, o que fez, o que vai
fazer em seguida e se está travada em alguma coisa. Isso substitui a daily
presencial de uma squad remota. Ao fim de cada sprint, a retrospectiva fica em uma
Issue própria, "Retro Sprint N".

A partir da Sprint 4, parte do código é escrita com ajuda de um agente de IA, e a
regra do Merge Request vale para ele também: nenhum código gerado por IA entra na
`main` sem revisão de outra integrante, e o agente não faz commit nem push direto
nela. Cada Merge Request feito com IA traz o pedido enviado ao agente, o plano
aprovado pelo squad e a lista do que precisou ser corrigido no código gerado, e o
uso da semana fica registrado na Issue fixa "Diário de IA" da
Sprint 4, com pelo menos uma entrada de cada integrante.

## Sprints

| Sprint | Entrega | Situação |
|---|---|---|
| 0 | Kickoff: formação do squad, conceito do produto, backlog e wireframes | Entregue |
| 1 | Primeiras Telas: telas do MVP, backlog no Issue Board e fluxo de Merge Request | Entregue |
| 2 | Produto Conectado: rotas centralizadas, estado compartilhado, cadastro, login e perfil | Entregue |
| 3 | Produto Resiliente: cache local, estados de conectividade na tela e preferência salva | Entregue |
| 4 | Squad com IA: agente com o MCP do Flutter, arquivo de rules, funcionalidade e testes com IA | Em andamento |
