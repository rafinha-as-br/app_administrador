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
  void toMapaBairro() => _router.push('/mapa/bairro');

  @override
  void toAplicadores() => _router.pushReplacement('/aplicadores');
  @override
  void toAplicadorDetalhes() => _router.push('/aplicadores/detalhes');

  @override
  void toGerenciamentoAdministradores() =>
      _router.pushReplacement('/administradores');

  @override
  void toEstoque() => _router.pushReplacement('/estoque');
  @override
  void toEstoqueFormula() => _router.push('/estoque/formula');
  @override
  void toEstoqueLicitacao() => _router.push('/estoque/licitacao');
  @override
  void toEstoqueProduto() => _router.push('/estoque/produto');
  @override
  void toEstoqueVisualizacao() => _router.push('/estoque/visualizacao');

  @override
  void toDistribuicoes() => _router.pushReplacement('/distribuicoes');
  @override
  void toDistribuicaoCadastro() => _router.push('/distribuicoes/cadastro');
  @override
  void toDistribuicaoVisualizacao() =>
      _router.push('/distribuicoes/visualizacao');

  @override
  void toDenunciasAdmin() => _router.pushReplacement('/denuncias_admin');
  @override
  void toDenunciaAdminDetalhes() => _router.push('/denuncias_admin/detalhes');

  @override
  void toLogout() => _router.pushReplacement('/');
  @override
  void toLoginResetStack() => _router.go('/');

  @override
  void back() => _router.pop();
}
