import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_yolo/core/detection/interpreter_factory.dart';

void main() {
  group('delegateAttemptOrder', () {
    test('auto tries NNAPI, then GPU, then CPU', () {
      expect(delegateAttemptOrder(AcceleratorPreference.auto), <DelegateKind>[
        DelegateKind.nnapi,
        DelegateKind.gpu,
        DelegateKind.cpu,
      ]);
    });

    test('cpu runs on CPU only', () {
      expect(delegateAttemptOrder(AcceleratorPreference.cpu), <DelegateKind>[
        DelegateKind.cpu,
      ]);
    });

    test('an explicit accelerator still falls back to CPU', () {
      expect(delegateAttemptOrder(AcceleratorPreference.gpu), <DelegateKind>[
        DelegateKind.gpu,
        DelegateKind.cpu,
      ]);
      expect(delegateAttemptOrder(AcceleratorPreference.nnapi), <DelegateKind>[
        DelegateKind.nnapi,
        DelegateKind.cpu,
      ]);
    });

    test('every preference ends with CPU', () {
      for (final p in AcceleratorPreference.values) {
        expect(delegateAttemptOrder(p).last, DelegateKind.cpu);
      }
    });
  });
}
