import 'package:geoprag_modules/geoprag_modules.dart';
import 'package:go_router/go_router.dart';

/// Implementação de [AdminNavigator] usando `go_router`.
///
/// **Padrão único de navegação (GEOPRAG-72):** toda tela pós-login do
/// Portal Administrador — dashboards de módulo e as sub-rotas de
/// detalhe/cadastro dentro de cada um — é alcançada por [pushReplacement],
/// nunca [push]. A pilha interna do `Navigator` fica sempre com 1 nível,
/// então nenhuma tela pós-login depende de um botão de voltar in-app
/// (`BackButton`/`AppBar` não o exibe quando não há o que popar) — só do
/// botão voltar do navegador, que continua funcionando porque o `go_router`
/// atualiza a URL a cada `pushReplacement`. Consequência direta: uma tela
/// alcançada assim nunca deve chamar [back] para "retornar" — ela navega
/// explicitamente para o destino pretendido (ex.: `toAplicadores()`), já
/// que não há mais frame anterior para popar (era exatamente esse
/// descompasso — rota de cadastro com `push` porém `AdminNavigator.back()`
/// no retorno de sucesso — que causava pilha duplicada; ver
/// `toCriarAplicador`/`toCriarAdministrador`, primeiros casos corrigidos
/// nas GEOPRAG-65/68, e o mesmo fix agora replicado em todas as demais
/// sub-rotas do Portal Administrador).
///
/// Exceção deliberada: o fluxo de recuperação de senha (`/senha/*`), que
/// roda **antes** do login, continua usando `push`/[back] — é um wizard
/// linear de passos onde voltar de verdade (não só reiniciar do zero) é o
/// comportamento esperado, e não faz parte de nenhum módulo do Portal
/// Administrador propriamente dito.
class AdminGoRouterNavigator implements AdminNavigator {
  AdminGoRouterNavigator(this._router);

  final GoRouter _router;

  @override
  void toEsqueciSenha() => _router.push('/senha/esqueci');
  @override
  void toAguardandoAutorizacao() => _router.push('/senha/aguardando');
  @override
  void toAutorizarRedefinicao() => _router.push('/senha/autorizar');
  @override
  void toVerificarCodigoSubAdmin() => _router.push('/senha/codigo-subadmin');
  @override
  void toVerificarCodigoAdmin() => _router.push('/senha/codigo-admin');
  @override
  void toRecriarSenha() => _router.pushReplacement('/senha/recriar');

  @override
  void toDashboard() => _router.pushReplacement('/dashboard');

  @override
  void toMapa() => _router.pushReplacement('/mapa');
  @override
  void toMapaBairro(String bairroId) => _router.pushReplacement(
    Uri(path: '/mapa/bairro', queryParameters: {'id': bairroId}).toString(),
  );

  @override
  void toAplicadores() => _router.pushReplacement('/aplicadores');
  @override
  void toAplicadorDetalhes(String aplicadorId) => _router.pushReplacement(
    Uri(
      path: '/aplicadores/detalhes',
      queryParameters: {'id': aplicadorId},
    ).toString(),
  );
  // GEOPRAG-65 (review Rafinha, 2026-08-02): pushReplacement, não push — a
  // tela de cadastro é um destino de topo alcançado a partir do dashboard,
  // não uma sub-rota aninhada. Usar push aqui quebrava a invariante de pilha
  // plana das demais rotas de menu (todas pushReplacement): ao navegar pelo
  // sidebar a partir da tela de cadastro e depois voltar para "aplicadores",
  // sobrava um frame duplicado do dashboard na pilha, fazendo a AppBar
  // exibir um botão de voltar espúrio.
  @override
  void toCriarAplicador() => _router.pushReplacement('/aplicadores/novo');

  @override
  void toGerenciamentoAdministradores() =>
      _router.pushReplacement('/administradores');
  @override
  Future<void> toCriarAdministrador() async =>
      await _router.pushReplacement('/administradores/novo');
  @override
  Future<void> toSolicitacoesPromocaoAdministrador() async =>
      await _router.pushReplacement('/administradores/solicitacoes');

  @override
  void toEstoque() => _router.pushReplacement('/estoque');
  @override
  void toEstoqueFormula() => _router.pushReplacement('/estoque/formula');
  @override
  void toEstoqueLicitacao() => _router.pushReplacement('/estoque/licitacao');
  @override
  void toEstoqueProduto() => _router.pushReplacement('/estoque/produto');
  @override
  void toEstoqueVisualizacao(String produtoId) => _router.pushReplacement(
    Uri(
      path: '/estoque/visualizacao',
      queryParameters: {'id': produtoId},
    ).toString(),
  );

  @override
  void toDistribuicoes() => _router.pushReplacement('/distribuicoes');
  @override
  void toDistribuicaoCadastro() =>
      _router.pushReplacement('/distribuicoes/cadastro');
  @override
  void toDistribuicaoVisualizacao(String distribuicaoId) =>
      _router.pushReplacement(
        Uri(
          path: '/distribuicoes/visualizacao',
          queryParameters: {'id': distribuicaoId},
        ).toString(),
      );

  @override
  void toDenunciasAdmin() => _router.pushReplacement('/denuncias_admin');
  @override
  void toDenunciaAdminDetalhes(String denunciaId) => _router.pushReplacement(
    Uri(
      path: '/denuncias_admin/detalhes',
      queryParameters: {'id': denunciaId},
    ).toString(),
  );

  @override
  void toLogout() => _router.pushReplacement('/');
  @override
  void toLoginResetStack() => _router.go('/');

  @override
  void back() => _router.pop();
}
