import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_remote_app/domains/discovery/models/connection_issue_type.dart';
import 'package:universal_remote_app/presentation/shared/widgets/connection_issue_page.dart';
import 'package:universal_remote_app/presentation/views/discovery/widgets/discovery_issue.dart';

void main() {
  testWidgets('renders the network issue and retries', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiscoveryIssue(
            type: ConnectionIssueType.networkUnavailable,
            retry: () => retries++,
            dismiss: () {},
          ),
        ),
      ),
    );
    expect(find.byType(ConnectionIssuePage), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retries, 1);
  });

  testWidgets('catalog issue can be dismissed independently', (tester) async {
    var dismissed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiscoveryIssue(
            type: ConnectionIssueType.internetUnavailable,
            retry: () {},
            dismiss: () => dismissed = true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Continue offline'));
    expect(dismissed, isTrue);
  });
}
