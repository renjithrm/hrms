import 'package:rebs_hrms/models/employee.dart';
import 'package:rebs_hrms/models/office_location.dart';
import 'package:rebs_hrms/models/shift.dart';

/// The mock server's preconfigured employee.
const testEmployee = Employee(
  id: 'EMP-1042',
  name: 'Anjali Nair',
  department: 'Engineering',
  office: OfficeLocation(
    name: 'Infopark Phase 1',
    latitude: 10.0159,
    longitude: 76.3419,
    radiusMetres: 200,
  ),
  shift: Shift(startMinutes: 9 * 60, endMinutes: 18 * 60),
  timezone: 'Asia/Kolkata',
);
