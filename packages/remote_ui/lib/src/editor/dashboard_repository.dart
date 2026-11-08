abstract interface class DashboardRepository {
  Future<Map<String, String>> load();
  Future<void> save(Map<String, String> dashboards);
}
