import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/features/settings/data/models/sub_branch_model.dart';

void main() {
  test('fromJson parses string fields as documented', () {
    final model = SubBranchModel.fromJson({
      'subbranchCode': 'CPX-DT',
      'subbranchName': 'Rangnam Complex Downtown',
      'BranchNo': '03',
      'ConfigSC': 'SC1',
      'CutOffTime': '18:00',
    });

    expect(model.subbranchCode, 'CPX-DT');
    expect(model.subbranchName, 'Rangnam Complex Downtown');
    expect(model.branchNo, '03');
    expect(model.configSC, 'SC1');
    expect(model.cutOffTime, '18:00');
  });

  test(
    'fromJson coerces a numeric BranchNo instead of throwing a cast error',
    () {
      final model = SubBranchModel.fromJson({
        'subbranchCode': 'CPX-DT',
        'subbranchName': 'Rangnam Complex Downtown',
        'BranchNo': 3,
        'ConfigSC': 'SC1',
        'CutOffTime': '18:00',
      });

      expect(model.branchNo, '3');
    },
  );

  test('fromJson defaults missing fields to empty strings', () {
    final model = SubBranchModel.fromJson(const {});

    expect(model.subbranchCode, '');
    expect(model.subbranchName, '');
    expect(model.branchNo, '');
    expect(model.configSC, '');
    expect(model.cutOffTime, '');
  });
}
