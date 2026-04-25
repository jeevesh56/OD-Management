import '../entities/od_request.dart';

abstract class OdRequestRepository {
  Future<OdRequest?> getById(String requestId);
  Future<List<OdRequest>> getByStudent(String studentId);
  Future<List<OdRequest>> getPendingForRole(String roleScope);
  Future<void> create(OdRequest request);
  Future<void> update(OdRequest request);
}
