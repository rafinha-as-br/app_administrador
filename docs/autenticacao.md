# Autenticação — App Administrador (Flutter Web)

> Escopo: implementação **front-end** do módulo de autenticação no `app_administrador`, consumido pelos servidores/administradores da Prefeitura de Gaspar.
> Fonte de verdade das regras de negócio e segurança (não duplicar, apenas referenciar): Confluence — *Arquitetura da Solução*, *Módulo Autenticação - Segurança de acesso para servidores*, *Especificação técnica (backend): access token de 15min e revogação de sessão — Administrador*.
> Status: **planejamento pré-implementação** — não há código de autenticação no repositório ainda (`lib/` contém apenas o `main.dart` padrão do `flutter create`).

---

## 1. Contexto e papel deste app no sistema

O `app_administrador` é um **cliente magro (thin client)**: por decisão de arquitetura registrada em *Arquitetura da Solução*, nenhum front-end do GeoPrag processa regras de negócio ou de segurança localmente. Ele apenas:

1. Coleta as credenciais do usuário (login e senha).
2. Envia essas credenciais para a API central (`geoprag_api`).
3. Reage às respostas (sucesso, erro, sessão expirada).

Isso significa que este documento **não define** a lógica de expiração, revogação ou geração de token — isso é comportamento do backend, já especificado no Confluence. O que este documento define é: *como o front-end Flutter Web deve se comportar diante dessas regras já definidas*, e *quais endpoints ele precisa que a API exponha* para funcionar.

## 2. Modelo de sessão adotado e por que ele muda o desenho do front-end

A decisão de arquitetura (já tomada, não é escolha do front-end) é:

- O token de acesso é um **JWT de 15 minutos**, carregado em **cookie HttpOnly, `Secure`, `SameSite=Strict`**.
- A sessão é do tipo **sliding session**: a cada requisição autenticada válida, o backend renova o token automaticamente (novo `exp` +15min) e devolve um novo cookie na resposta.

Duas consequências diretas para o front-end, e o motivo de cada uma:

| Consequência | Por quê |
|---|---|
| O front-end **nunca lê nem escreve o token diretamente** (nem em variável Dart, nem em `localStorage`/`sessionStorage`/IndexedDB). | Cookie `HttpOnly` é, por definição, inacessível a JavaScript/Dart rodando no browser. Essa é a mitigação escolhida contra roubo de token via XSS. Tentar guardar uma cópia do token em algum storage do app quebraria essa proteção e contraria a arquitetura de segurança já definida. |
| O front-end **não implementa lógica própria de refresh/expiração** (ex.: contador de 15 minutos no client). | O relógio de referência é sempre o servidor. Qualquer contagem local ficaria dessincronizada e é redundante: a cada resposta HTTP o backend já informa (via 401 ou via novo cookie) o estado real da sessão. |

Alternativa descartada: armazenar um `Bearer token` em memória/`localStorage` e enviá-lo via header `Authorization`. Essa era uma opção arquitetural válida em outros projetos, mas **já foi descartada** pela decisão de usar cookies HttpOnly (ver *Arquitetura de Segurança* → Segurança do Painel Administrativo). O front-end deve seguir essa decisão, não reabri-la.

## 3. Implicação técnica: requisições HTTP em Flutter Web precisam enviar cookies

Como o cookie é a única forma de transportar a sessão, todo cliente HTTP do app precisa ser configurado para **enviar e receber cookies em requisições cross-origin** (a não ser que `app_administrador` e `geoprag_api` sejam servidos do mesmo domínio, o que reduz a complexidade de CORS).

Pontos a validar antes de codar (dependem de definição de infraestrutura, fora do escopo deste front-end):

- Se API e app estiverem em domínios/subdomínios diferentes, o backend precisa responder com `Access-Control-Allow-Credentials: true` e `Access-Control-Allow-Origin` explícito (não `*`), e o cliente HTTP do Flutter Web precisa habilitar envio de credenciais (equivalente a `credentials: 'include'` no `fetch` do browser).
- `SameSite=Strict` só permite o cookie em requisições originadas do próprio domínio — isso restringe, por exemplo, abrir a aplicação a partir de um link externo e já chegar autenticado. Vale confirmar que esse comportamento é aceitável para o fluxo de uso real dos servidores da prefeitura.

Pacotes candidatos para a camada HTTP: `dio` (com `BaseOptions(extra: {'withCredentials': true})` no adapter web) ou `package:http`. Recomenda-se `dio`, pela facilidade de configurar interceptors (necessário no item 5).

## 4. Fluxo de login (client-side)

1. Tela de login coleta `login` e `senha` (validação client-side limitada a formato — não substitui validação do backend, conforme *Arquitetura da Solução*: "abrindo-se exceção apenas para validações básicas de formato de campos de formulário").
2. `POST` para o endpoint de login (ver seção 6).
3. Backend responde `Set-Cookie` (invisível ao Dart) + corpo da resposta (ex.: dados do usuário autenticado).
4. Sucesso → navega para a área autenticada. Erro (401/422) → exibe mensagem, sem detalhar se foi "login incorreto" ou "senha incorreta" (evitar enumeração de usuários).

**Como o app sabe que está autenticado ao abrir/recarregar a página?** Como o token não é legível pelo Dart, o estado de "sessão ativa" não pode vir de um valor guardado localmente — precisa ser perguntado à API a cada boot do app (ver `GET /auth/me` na seção 6).

## 5. Tratamento de sessão expirada ou revogada

Centralizar em **um único interceptor HTTP** (não espalhar tratamento de 401 pelas telas):

- Qualquer resposta `401` de qualquer endpoint → limpar estado de autenticação em memória (provider/bloc/state notifier, o que for adotado no app) e redirecionar para a tela de login.
- Não tentar retry automático nem lógica de refresh manual — a renovação por atividade já é feita pelo backend a cada requisição válida; um 401 aqui significa que a sessão realmente expirou por inatividade ou foi revogada por um administrador.

## 6. Definição da API — endpoints

> ⚠️ **Atenção:** a página *API - Autenticação* no Confluence hoje descreve apenas o **comportamento** do servidor (emissão/validação de sessão, políticas de acesso), mas **não define o contrato formal** (rotas, métodos, payloads). A proposta abaixo é o ponto de partida para alinhar com quem for implementar o `geoprag_api`, **antes** de começar a codificar as chamadas no front. Itens marcados como "a confirmar" são bloqueantes para o início da implementação.

| Endpoint | Método | Request | Response (sucesso) | Observações |
|---|---|---|---|---|
| `/auth/login` | POST | `{ "login": string, "senha": string }` | `200` + `Set-Cookie` (access token) + corpo com dados do usuário | Erro esperado: `401` credenciais inválidas |
| `/auth/logout` | POST | — (usa cookie da sessão) | `200` | Invalida o `sid` no backend (registro de sessão) |
| `/auth/me` | GET | — (usa cookie da sessão) | `200` com dados do usuário, ou `401` | Usado no boot do app para checar se a sessão segue ativa |
| Revogação manual de sessão (admin revoga sessão de outro usuário) | **a confirmar** | — | — | O Confluence menciona a capacidade ("administradores podem revogar sessões"), mas não há rota definida. Necessário para a tela de "gestão de sessões ativas", se ela existir no escopo do app_administrador. |

## 7. Estrutura sugerida no projeto

Seguindo o padrão **Feature-First** já adotado no ecossistema (ver *Arquitetura da Solução*):

```
lib/
  features/
    auth/
      data/         # AuthRemoteDataSource (chamadas HTTP), DTOs de request/response
      domain/        # AuthRepository (interface), entidades (Usuario)
      presentation/  # LoginPage, AuthState/Controller, widgets da tela de login
  core/
    http/            # cliente HTTP configurado (dio + interceptor de 401)
```

Observação sobre `geoprag_modules`: os fluxos de autenticação do `app_administrador` (cookie) e do `app_aplicador` (token + biometria + chaves assimétricas) são **suficientemente diferentes** para não justificar lógica compartilhada no pacote `geoprag_modules`. Recomenda-se implementar o módulo de autenticação **separadamente em cada app**, reaproveitando de `geoprag_modules` no máximo componentes visuais genéricos (campos de formulário, botões), se já existirem.

## 8. Dependências e riscos em aberto

Lista do que precisa ser resolvido — com quem, antes de travar a implementação:

1. **Contrato formal dos endpoints de auth** (seção 6) — depende de definição junto ao time/pessoa responsável pelo `geoprag_api`.
2. **Topologia de domínio** (mesmo domínio vs subdomínios entre `app_administrador` e `geoprag_api`) — impacta diretamente se `SameSite=Strict` funciona sem fricção e a configuração de CORS.
3. **Formato padronizado de erro da API** (ainda não documentado) — necessário para exibir mensagens de erro consistentes na UI.
4. **Rota de revogação manual de sessão** — só é bloqueante se o `app_administrador` tiver uma tela de "gestão de sessões" no escopo atual; validar se esse recurso está no escopo do MVP.

## 9. Checklist de boas práticas para a implementação

- Nunca armazenar o token em `localStorage`, `sessionStorage`, ou variável Dart persistida — o cookie HttpOnly já é a única fonte de verdade.
- Toda chamada HTTP autenticada deve ir pelo cliente HTTP central configurado com envio de credenciais.
- Tratamento de `401` centralizado em um único interceptor, não replicado em cada tela.
- Não implementar contagem de tempo de sessão no client.
- Auditoria de acessos é responsabilidade do backend — o front não precisa (nem deve) logar tentativas de login localmente além do necessário para UX.
