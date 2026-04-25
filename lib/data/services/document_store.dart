abstract class DocumentStore {
  Future<Map<String, dynamic>?> get({
    required String collection,
    required String id,
  });

  Future<void> set({
    required String collection,
    required String id,
    required Map<String, dynamic> data,
    bool merge = true,
  });

  Future<List<Map<String, dynamic>>> query({
    required String collection,
    required String field,
    required dynamic isEqualTo,
  });
}
