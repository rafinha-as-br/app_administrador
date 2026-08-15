import 'package:geoprag_modules/geoprag_modules.dart';
import 'package:go_router/go_router.dart';

/// Implementação de [AdminNavigator] usando `go_router`. Reproduz a
/// semântica (push vs. replace vs. limpar pilha) das chamadas
/// `Navigator.push*`/`pop` que existiam hardcoded nas telas antes da
/// extração para a interface de navegação (GEOPRAG-24 Fase 1).
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
  void toMapaBairro(String bairroId) => _router.push(
    Uri(path: '/mapa/bairro', queryParameters: {'id': bairroId}).toString(),
  );

  @override
  void toAplicadores() => _router.pushReplacement('/aplicadores');
  @override
  void toAplicadorDetalhes(String aplicadorId) => _router.push(
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
      await _router.push('/administradores/novo');
  @override
  Future<void> toSolicitacoesPromocaoAdministrador() async =>
      await _router.push('/administradores/solicitacoes');

  @override
  void toEstoque() => _router.pushReplacement('/estoque');
  @override
  void toEstoqueFormula() => _router.push('/estoque/formula');
  @override
  void toEstoqueLicitacao() => _router.push('/estoque/licitacao');
  @override
  void toEstoqueProduto() => _router.push('/estoque/produto');
  @override
  void toEstoqueVisualizacao(String produtoId) => _router.push(
    Uri(
      path: '/estoque/visualizacao',
      queryParameters: {'id': produtoId},
    ).toString(),
  );

  @override
  void toDistribuicoes() => _router.pushReplacement('/distribuicoes');
  @override
  void toDistribuicaoCadastro() => _router.push('/distribuicoes/cadastro');
  @override
  void toDistribuicaoVisualizacao(String distribuicaoId) => _router.push(
    Uri(
      path: '/distribuicoes/visualizacao',
      queryParameters: {'id': distribuicaoId},
    ).toString(),
  );

  @override
  void toDenunciasAdmin() => _router.pushReplacement('/denuncias_admin');
  @override
  void toDenunciaAdminDetalhes(String denunciaId) => _router.push(
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
