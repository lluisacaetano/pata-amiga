# Sprint Review e Retrospectiva Técnica do MVP

**Data do registro:** 28/09/2026  
**Escopo:** navegação e fluxo de adoção do MVP  
**Status:** roteiro e registro técnico preparados para apresentação e ratificação pela squad.

## Sprint Review

### Roteiro de demonstração

1. Iniciar o app e mostrar a tela de boas-vindas.
2. Abrir **Entrar**, informar um e-mail válido e uma senha não vazia. O app abre o feed. A autenticação ainda é demonstrativa e não consulta uma API.
3. No feed, alternar entre **Adoção**, **Perdidos** e **Resgate**, pesquisar um animal e abrir um card.
4. Na ficha, marcar o animal como curtido e voltar. O feed confirma o retorno e mantém o coração selecionado.
5. Usar **Publicar** ou o botão `+`, preencher os dados do animal e publicar. O registro retornado aparece no feed durante a sessão atual.
6. Mostrar a alternativa **Criar conta** e o retorno da recuperação de senha ao login.

### Evidências

- As telas implementadas usam a tabela central de rotas em `lib/routes/app_router.dart`.
- O teste `flutter test test/routes/animal_navigation_test.dart` percorre feed → detalhes → feed, valida o animal devolvido e verifica a curtida compartilhada.
- O estado de curtidas é compartilhado via `InheritedNotifier` e persistido em `SharedPreferences`.

### Limites demonstrados

- Login e cadastro ainda não autenticam nem gravam usuários em uma API.
- Novos animais ficam no estado do feed até o app ser encerrado; ainda não são enviados para backend.
- Recuperação de senha e login Google são pontos de interface sem integração.
- Mapa, denúncia e perfil não são apresentados como telas prontas; foram removidos da navegação inferior até sua implementação.

## Retrospectiva Técnica

Este registro foi elaborado por inspeção e teste do fluxo no repositório. Ele não substitui a conversa síncrona da squad; participantes, percepções e decisões coletivas devem ser confirmados na cerimônia.

### Manter

- Nomes de rotas e navegação concentrados, com argumentos de rota verificados para detalhes.
- Estado de curtidas acessível pelas telas consumidoras sem encaminhar o valor por propriedades intermediárias.
- Testes de widget cobrindo um percurso de ida e volta do usuário.

### Melhorar

- Substituir os dados mockados e a autenticação demonstrativa por integração com a API.
- Persistir publicações de animais e definir como fotos serão anexadas.
- Manter na navegação apenas destinos que já possam concluir uma tarefa.

### Ações propostas

| Ação | Critério de conclusão |
|---|---|
| Integrar cadastro e login à API | Usuário criado e sessão validada pela API, com erros apresentados no formulário |
| Persistir animais publicados | Novo registro continua disponível após reiniciar o app |
| Priorizar mapa, denúncia e perfil | Histórias selecionadas no backlog e respectivas telas com fluxo verificável |
| Ratificar esta retrospectiva | Squad registra participantes, decisões e responsáveis pela próxima sprint |

## Critérios do fluxo

| Critério | Situação |
|---|---|
| Telas implementadas do MVP navegáveis no fluxo | Atendido |
| Rotas centralizadas | Atendido |
| Estado compartilhado via `InheritedNotifier` | Atendido |
| Estado de curtidas sem prop drilling | Atendido |
| Passagem e retorno de dados testados | Atendido pelo teste widget |
| Sprint Review | Roteiro reproduzível e evidência automatizada; apresentação ao vivo pendente |
| Sprint Retro | Registro técnico criado; ratificação pela squad pendente |