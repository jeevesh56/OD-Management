import '../entities/od_request.dart';

abstract class OdRequestRepository {
  Future<OdRequest?> getById(String requestId);
  Stream<OdRequest?> watchById(String requestId);
  Future<List<OdRequest>> getByStudent(String studentId);
  Stream<List<OdRequest>> watchByStudent(String studentId);
  Future<List<OdRequest>> getPendingForRole(String roleScope);
  Stream<List<OdRequest>> watchPendingForRole(String roleScope);
  Future<void> create(OdRequest request);
  Future<void> update(OdRequest request);
}
