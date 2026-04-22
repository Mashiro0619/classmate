import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/timetable_models.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({
    super.key,
    this.showConsentActions = false,
    this.onAccept,
    this.onDecline,
  });

  final bool showConsentActions;
  final Future<void> Function()? onAccept;
  final Future<void> Function()? onDecline;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sections = [
      (
        title: l10n.privacyPolicyLocalStorageTitle,
        body: l10n.privacyPolicyLocalStorageBody,
      ),
      (
        title: l10n.privacyPolicyImportExportTitle,
        body: l10n.privacyPolicyImportExportBody,
      ),
      (
        title: l10n.privacyPolicySharingTitle,
        body: l10n.privacyPolicySharingBody,
      ),
      (
        title: l10n.privacyPolicyExternalLinksTitle,
        body: l10n.privacyPolicyExternalLinksBody,
      ),
      (
        title: l10n.privacyPolicyNoCollectionTitle,
        body: l10n.privacyPolicyNoCollectionBody,
      ),
      (
        title: l10n.privacyPolicyFutureFeatureTitle,
        body: l10n.privacyPolicyFutureFeatureBody,
      ),
      (
        title: l10n.privacyPolicyUpdatesTitle,
        body: l10n.privacyPolicyUpdatesBody(currentPrivacyPolicyVersion),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyPolicyTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Text(
                    l10n.privacyPolicyIntro,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  for (final section in sections) ...[
                    Text(
                      section.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      section.body,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
            if (showConsentActions)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onDecline == null
                              ? null
                              : () async => onDecline!(),
                          child: Text(l10n.privacyDecline),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: onAccept == null
                              ? null
                              : () async => onAccept!(),
                          child: Text(l10n.privacyAgreeAndContinue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
