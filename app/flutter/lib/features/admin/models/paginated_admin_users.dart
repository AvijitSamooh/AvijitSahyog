import 'admin_user.dart';

class PaginatedAdminUsers {
  const PaginatedAdminUsers({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<AdminUser> items;
  final int page;
  final int pageSize;
  final int total;

  int get totalPages => total == 0 ? 1 : (total + pageSize - 1) ~/ pageSize;
  bool get hasPreviousPage => page > 1;
  bool get hasNextPage => page < totalPages;
}
