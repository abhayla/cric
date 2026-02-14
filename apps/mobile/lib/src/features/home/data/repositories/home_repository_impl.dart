import '../../domain/entities/match_list_item.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';
import '../models/match_list_item_model.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({required this.remoteDatasource});

  final HomeRemoteDatasource remoteDatasource;

  @override
  Future<MatchListResult> getMatches({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final data = await remoteDatasource.getMatches(
      status: status,
      page: page,
      limit: limit,
    );

    final matchModels = (data['matches'] as List)
        .map((m) => MatchListItemModel.fromJson(m as Map<String, dynamic>))
        .toList();

    return MatchListResult(
      matches: matchModels.map((m) => m.toEntity()).toList(),
      total: data['total'] as int,
      page: data['page'] as int,
    );
  }
}
