import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/employees_repository.dart';
import '../domain/employee_models.dart';

/// قائمة الموظفين (سائق/معبئ/موظف).
final employeesListProvider = FutureProvider<List<StaffMember>>(
  (ref) => ref.watch(employeesRepositoryProvider).fetchEmployees(),
);

/// إحصاءات أداء الموظفين.
final employeeStatsProvider = FutureProvider<List<EmployeeStats>>(
  (ref) => ref.watch(employeesRepositoryProvider).fetchEmployeeStats(),
);

/// آخر طلبات موظف معيّن (عائلة حسب المعرّف).
final employeeOrdersProvider = FutureProvider.family<List<EmployeeOrder>, String>(
  (ref, String userId) => ref.watch(employeesRepositoryProvider).fetchEmployeeOrders(userId),
);
