import '../../domain/entities/od_request.dart';
import '../../domain/enums/od_status.dart';
import '../../domain/repositories/od_request_repository.dart';

class InMemoryOdRequestRepository implements OdRequestRepository {
  final Map<String, OdRequest> _requests = {};

  @override
  Future<void> create(OdRequest request) async {
    _requests[request.id] = request;
  }

  @override
  Future<OdRequest?> getById(String requestId) async => _requests[requestId];

  @override
  Stream<OdRequest?> watchById(String requestId) async* {
    yield _requests[requestId];
  }

  @override
  Future<List<OdRequest>> getByStudent(String studentId) async {
    return _requests.values.where((item) => item.studentId == studentId).toList();
  }

  @override
  Stream<List<OdRequest>> watchByStudent(String studentId) async* {
    yield await getByStudent(studentId);
  }

  @override
  Future<List<OdRequest>> getPendingForRole(String roleScope) async {
    return _requests.values
        .where((item) => item.status == OdStatus.pending)
        .toList();
  }

  @override
  Stream<List<OdRequest>> watchPendingForRole(String roleScope) async* {
    yield await getPendingForRole(roleScope);
  }

  @override
  Future<void> update(OdRequest request) async {
    _requests[request.id] = request;
  }
}
