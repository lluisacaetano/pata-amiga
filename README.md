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
porte, idade e cidade, e pode ser estreitado por porte, raça e cor até sobrar
apenas o que interessa a quem procura. Tocar em um animal abre a ficha completa,
onde estão a situação de saúde, as observações de quem cuida dele e o contato do
responsável.

O feed de perdidos funciona pela mesma lógica, mas serve a outra urgência: quem
perdeu o animal publica, quem o avistou registra onde e quando, e o dono
acompanha os avistamentos sem depender de um post ser compartilhado a tempo.
Quando um animal é reportado como perdido, quem está por perto recebe uma
notificação, porque a informação só tem valor enquanto o animal ainda está na
região.

A denúncia de maus-tratos é o terceiro fluxo, e é o que mais depende de
permanência. O denunciante anexa foto, observação e endereço, e recebe um
protocolo que permite acompanhar em que situação o caso está. O aplicativo não
resolve a denúncia, mas garante que ela deixe de ser uma mensagem perdida e passe
a ser um registro com histórico.

Sobre esses três fluxos se apoiam o mapa, que mostra em camadas os avistamentos,
os pontos de resgate e os comedouros públicos, e o painel de denúncias, por onde
o poder público tria os casos recebidos e registra as providências tomadas.

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
registra a denúncia, entrega o caso ao responsável e guarda a situação que este
informar de volta, seja ela recebida, em apuração ou encerrada.

Resta dizer quem é esse responsável, e aqui o squad trabalha com uma hipótese, não
com um acordo firmado. Supõe-se que a prefeitura de Formiga assuma o papel e
direcione cada caso conforme a natureza da ocorrência, encaminhando as denúncias
de maus-tratos à Polícia Civil ou ao órgão municipal competente, e os animais
perdidos ou abandonados às ONGs que atuam no resgate. Enquanto essa parceria não
for firmada, a denúncia fica registrada no aplicativo e é encaminhada por correio
eletrônico ao endereço cadastrado como responsável.

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
risco, registrar um avistamento ou denunciar maus-tratos. E os administradores do
aplicativo e o poder público municipal acessam o painel de denúncias, onde triam
os casos recebidos e registram as providências tomadas.

## Backlog

O backlog inicial tem dezoito User Stories, escritas na Sprint 0 no formato
"como [persona], quero [ação], para [benefício]", cada uma com prioridade e
tamanho estimado. Doze são de prioridade alta, cinco médias e uma baixa. A
história completa e o critério de aceite de cada uma estão no documento da
Sprint 0, e todas são cadastradas como Issues no Issue Board deste repositório.

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

## O squad

Patinhas Gals Dev. Os papéis são rotativos e revisados a cada sprint, de modo que
todas as integrantes passem por todas as funções ao longo do semestre. A divisão
registrada abaixo é a da Sprint 0.

| Integrante | Papel na Sprint 0 | GitLab |
|---|---|---|
| Yasmim Stefane Faria | Tech Lead | @yasmimstefane |
| Maria Eduarda Siqueira Silva | Product Owner | @Mariyaduarda |
| Júlia Cristina Martins | QA | @Julia_Nakano |
| Luisa Caetano Araujo | Dev 1 | @luisacaetano |
| Maria Luzia Sanches | Dev 2 | @marialuziademoura |

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

## Como rodar

O projeto Flutter entra no repositório pela Sprint 1. A partir daí:

```
flutter pub get
flutter run
```

Para escolher onde rodar, use `flutter devices` e depois
`flutter run -d <dispositivo>`. Além do emulador Android, o projeto roda em
`chrome` e `macos`, o que ajuda quem ainda está terminando de configurar o SDK.
Os testes rodam com `flutter test`.

## Como trabalhamos

Nenhum código entra na `main` direto. Cada integrante trabalha em uma branch
própria, nomeada pela funcionalidade em que está mexendo, e abre um Merge Request
explicando o que fez.

A QA da sprint é a revisora padrão de todo Merge Request e testa a tela na
prática antes de aprovar. Se estiver ocupada, qualquer outra integrante pode
cobrir. A regra que não muda é que ninguém aprova o próprio Merge Request. Depois
da aprovação, quem faz o merge é a própria autora, que escolhe o momento certo.

O andamento fica registrado em uma Issue fixa por sprint, onde cada integrante
comenta, a cada dia de aula, o que fez, o que vai fazer em seguida e se está
travada em alguma coisa. Isso substitui a daily presencial de uma squad remota.

## Sprints

| Sprint | Entrega | Situação |
|---|---|---|
| 0 | Kickoff: formação do squad, conceito do produto, backlog e wireframes | Entregue |
| 1 | Primeiras telas do MVP, backlog no Issue Board e fluxo de Merge Request | Em andamento |
