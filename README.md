# app_administrador

Aplicativo **Flutter Web** do Geoprag destinado aos **administradores/servidores da Prefeitura de Gaspar**, responsável pela gestão, monitoramento e controle das ações do programa de combate à dengue.

## O que é

O `app_administrador` é o portal web usado pela equipe administrativa para acompanhar em tempo real o trabalho dos aplicadores de campo, gerenciar estoque e distribuição de insumos, monitorar focos de dengue via mapa e tratar denúncias enviadas pela população ou pelos aplicadores.

Este repositório contém apenas a **aplicação Flutter Web** (o "shell" do app: navegação, integração com a API e composição das telas). As telas, widgets e regras de cada módulo funcional vêm do pacote compartilhado [`geoprag_modules`](../geoprag_modules), consumido via dependência git (branch `develop`) — ver [Desenvolvimento local com `geoprag_modules`](#desenvolvimento-local-com-geoprag_modules) abaixo.

## Funcionalidades (via `geoprag_modules/portal_administrador`)

- **Autenticação** — login de servidores/administradores.
- **Dashboard geral** — visão consolidada das operações.
- **Monitoramento por mapa** — acompanhamento hidrológico/geográfico de córregos e bairros.
- **Gestão de aplicadores** — cadastro e acompanhamento da equipe de campo.
- **Controle de estoque e licitação** — cadastro de produtos, fórmulas de dosagem e processos de licitação.
- **Distribuições** — registro e visualização de saídas de insumos.
- **Gestão de denúncias** — listagem e tratamento de focos denunciados.

## Arquitetura e decisões relevantes

- O app é um **cliente magro (thin client)**: nenhuma regra de negócio ou segurança é processada no front-end — tudo é validado pela API central (`geoprag_api`).
- **Sessão via cookie HttpOnly** (JWT de 15 min, sliding session renovada a cada requisição autenticada). Detalhes completos do fluxo de autenticação, endpoints propostos e riscos em aberto estão documentados em [`docs/autenticacao.md`](docs/autenticacao.md).
- Status atual: **planejamento pré-implementação** — o `lib/` contém apenas o `main.dart` padrão gerado pelo `flutter create`; a lógica de autenticação e integração com a API ainda não foi implementada.

## Estrutura

```
app_administrador/
  app_administrador/     # projeto Flutter (lib/, android/, ios/, web/, etc.)
  docs/
    autenticacao.md      # especificação do módulo de autenticação
```

## Dependências principais

- Flutter (SDK `^3.9.2`)
- `geoprag_modules` (git dependency, apontando pra `develop` — pacote compartilhado de UI e regras de módulos)

## Como rodar

```bash
cd app_administrador
flutter pub get
flutter run -d chrome
```

## Desenvolvimento local com `geoprag_modules`

O `pubspec.yaml` aponta `geoprag_modules` como dependência git (`ref: develop`), não path local — isso garante que CI e todo mundo no time sempre resolvem a mesma versão de verdade, publicada no repositório.

Se você está desenvolvendo uma mudança em `geoprag_modules` em paralelo e precisa testá-la aqui **antes de commitar/subir** essa mudança, troque temporariamente a entrada no `pubspec.yaml`:

```yaml
dependencies:
  geoprag_modules:
    path: ../../geoprag_modules/geoprag_modules_project
```

**Nunca commite essa troca.** A pipeline de CI falha (job `guard`) se detectar `path:` na entrada de `geoprag_modules` — desfaça antes de dar push.
